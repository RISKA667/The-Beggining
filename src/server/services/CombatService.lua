-- src/server/services/CombatService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemTypes = require(Shared.constants.ItemTypes)
local GameSettings = require(Shared.constants.GameSettings)

local CombatService = {}
CombatService.__index = CombatService

-- Créer une instance du service
function CombatService.new()
    local self = setmetatable({}, CombatService)
    
    -- Données de combat des joueurs
    self.playerCombatData = {}  -- [userId] = {health, maxHealth, armor, etc.}
    
    -- Suivi des attaques pour éviter le spam
    self.lastAttackTime = {}  -- [userId] = timestamp
    self.attackCooldown = 0.5  -- 0.5 seconde entre chaque attaque
    
    -- Suivi des projectiles
    self.activeProjectiles = {}
    self.nextProjectileId = 1
    
    -- Références aux services
    self.inventoryService = nil
    self.playerService = nil
    self.tribeService = nil
    self.buildingService = nil
    self.survivalService = nil
    
    -- RemoteEvents
    self.remoteEvents = {}
    
    return self
end

-- Initialiser les données de combat d'un joueur
function CombatService:InitializePlayerCombat(player)
    if not player or not player:IsA("Player") then return end
    
    local userId = player.UserId
    
    if self.playerCombatData[userId] then return end
    
    -- Créer les données de combat
    self.playerCombatData[userId] = {
        maxHealth = 100,
        currentHealth = 100,
        armor = 0,  -- Points d'armure
        isInCombat = false,
        lastCombatTime = 0,
        combatTarget = nil,
        damageDealt = 0,
        damageTaken = 0,
        kills = 0,
        deaths = 0,
        statusEffects = {}, -- Effets de statut actifs
        isBlocking = false, -- État de blocage
        lastBlockTime = 0, -- Dernier blocage
        comboCount = 0, -- Compteur de combo
        lastAttackTime = 0 -- Dernière attaque pour combos
    }
    
    -- Configurer le personnage si disponible
    if player.Character then
        self:SetupCharacterCombat(player.Character)
    end
    
    -- Mettre à jour le client
    self:UpdateClientCombatData(player)
    
    print("CombatService: Combat initialisé pour " .. player.Name)
end

-- Configurer le combat pour un personnage
function CombatService:SetupCharacterCombat(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Désactiver la santé par défaut de Roblox (on gère notre propre système)
    humanoid.MaxHealth = 100
    humanoid.Health = 100
    
    -- Connecter l'événement de dégâts
    humanoid.HealthChanged:Connect(function(health)
        -- On ignore les changements de santé automatiques
        -- Notre système gère tout via TakeDamage
    end)
end

-- Attaquer un joueur ou une entité
function CombatService:AttackTarget(attacker, target, attackType)
    if not attacker or not attacker:IsA("Player") then return false end
    if not target or not target:IsA("Player") then return false end
    
    local attackerId = attacker.UserId
    local targetId = target.UserId
    
    -- Vérifier le cooldown d'attaque
    local currentTime = tick()
    local lastAttack = self.lastAttackTime[attackerId] or 0
    
    if currentTime - lastAttack < self.attackCooldown then
        return false, "Attaque trop rapide"
    end
    
    -- Vérifier que l'attaquant n'est pas lui-même
    if attackerId == targetId then
        return false, "Vous ne pouvez pas vous attaquer vous-même"
    end
    
    -- Vérifier que les deux joueurs sont vivants
    if not self.playerCombatData[attackerId] or not self.playerCombatData[targetId] then
        return false, "Données de combat invalides"
    end
    
    -- Vérifier la distance
    local attackerChar = attacker.Character
    local targetChar = target.Character
    
    if not attackerChar or not targetChar then
        return false, "Personnage invalide"
    end
    
    local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not attackerRoot or not targetRoot then
        return false, "Position invalide"
    end
    
    local distance = (attackerRoot.Position - targetRoot.Position).Magnitude
    
    -- Obtenir l'arme équipée
    local weapon = self:GetEquippedWeapon(attacker)
    local weaponData = weapon and ItemTypes[weapon.id]
    
    -- Déterminer la portée d'attaque
    local attackRange = 5  -- Portée par défaut (mêlée)
    
    if weaponData then
        if weaponData.toolType == "bow" then
            attackRange = 50  -- Portée pour arc
        elseif weaponData.toolType == "weapon" then
            attackRange = 7  -- Portée pour armes de mêlée
        end
    end
    
    if distance > attackRange then
        self:SendNotification(attacker, "Cible trop éloignée", "warning")
        return false, "Cible trop éloignée"
    end
    
    -- Vérifier si l'un des joueurs est dans une zone de sécurité
    if self:IsInSafeZone(attacker) or self:IsInSafeZone(target) then
        self:SendNotification(attacker, "Combat impossible dans une zone de sécurité", "error")
        return false, "Zone de sécurité"
    end
    
    -- Vérifier si c'est un allié (même tribu) - sauf en duel
    local inDuel = self:ArePlayersInDuel(attacker, target)
    if not inDuel and self.tribeService and self.tribeService:ArePlayersInSameTribe(attacker, target) then
        self:SendNotification(attacker, "Vous ne pouvez pas attaquer un membre de votre tribu", "error")
        return false, "Allié"
    end
    
    -- Calculer les dégâts
    local baseDamage = 5  -- Dégâts à mains nues
    
    if weaponData and weaponData.damage then
        baseDamage = weaponData.damage
    end
    
    -- Appliquer les modificateurs
    local finalDamage = baseDamage
    
    -- Bonus de combo
    local comboMultiplier = self:GetComboMultiplier(attacker)
    finalDamage = finalDamage * comboMultiplier
    
    -- Mettre à jour le combo
    self:UpdateComboCount(attacker)
    
    -- Si c'est une arme à distance (arc), créer un projectile
    if weaponData and weaponData.toolType == "bow" then
        -- Vérifier les munitions
        if weaponData.ammo and self.inventoryService then
            if not self.inventoryService:HasItemInInventory(attacker, weaponData.ammo, 1) then
                self:SendNotification(attacker, "Vous n'avez plus de munitions", "error")
                return false, "Pas de munitions"
            end
            
            -- Retirer une munition
            self.inventoryService:RemoveItemFromInventory(attacker, weaponData.ammo, 1)
            
            -- Créer le projectile
            self:CreateProjectile(attacker, target, finalDamage)
            
            -- Mettre à jour le cooldown
            self.lastAttackTime[attackerId] = currentTime
            
            return true, "Projectile tiré"
        end
    else
        -- Attaque de mêlée directe
        self:DealDamage(attacker, target, finalDamage, "melee")
        
        -- Mettre à jour le cooldown
        self.lastAttackTime[attackerId] = currentTime
        
        return true, "Attaque réussie"
    end
    
    return false, "Erreur d'attaque"
end

-- Créer un projectile (flèche, etc.)
function CombatService:CreateProjectile(attacker, target, damage)
    local attackerChar = attacker.Character
    local targetChar = target.Character
    
    if not attackerChar or not targetChar then return end
    
    local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not attackerRoot or not targetRoot then return end
    
    -- Créer le projectile visuel
    local projectile = Instance.new("Part")
    projectile.Name = "Projectile"
    projectile.Size = Vector3.new(0.2, 0.2, 1)
    projectile.Material = Enum.Material.Wood
    projectile.Color = Color3.fromRGB(139, 69, 19)
    projectile.CanCollide = false
    projectile.Anchored = false
    
    -- Position de départ (devant l'attaquant)
    local startPos = attackerRoot.Position + attackerRoot.CFrame.LookVector * 2
    projectile.Position = startPos
    
    -- Orienter vers la cible
    local direction = (targetRoot.Position - startPos).Unit
    projectile.CFrame = CFrame.lookAt(startPos, targetRoot.Position)
    
    -- Ajouter une vélocité
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = direction * 80  -- Vitesse de la flèche
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Parent = projectile
    
    projectile.Parent = Workspace
    
    -- Stocker les données du projectile
    local projectileId = "projectile_" .. self.nextProjectileId
    self.nextProjectileId = self.nextProjectileId + 1
    
    self.activeProjectiles[projectileId] = {
        instance = projectile,
        attacker = attacker,
        damage = damage,
        startTime = tick(),
        hasHit = false
    }
    
    -- Détection de collision
    projectile.Touched:Connect(function(hit)
        local projectileData = self.activeProjectiles[projectileId]
        if not projectileData or projectileData.hasHit then return end
        
        -- Vérifier si c'est un joueur
        local hitPlayer = Players:GetPlayerFromCharacter(hit.Parent)
        
        if hitPlayer and hitPlayer ~= attacker then
            -- Touché!
            projectileData.hasHit = true
            self:DealDamage(attacker, hitPlayer, damage, "ranged")
            
            -- Détruire le projectile
            projectile:Destroy()
            self.activeProjectiles[projectileId] = nil
        elseif hit:IsDescendantOf(Workspace) and not hit:IsDescendantOf(attackerChar) then
            -- Touché un objet du décor
            projectileData.hasHit = true
            projectile:Destroy()
            self.activeProjectiles[projectileId] = nil
        end
    end)
    
    -- Nettoyer après 5 secondes si pas de collision
    Debris:AddItem(projectile, 5)
    
    delay(5, function()
        self.activeProjectiles[projectileId] = nil
    end)
end

-- Infliger des dégâts à un joueur
function CombatService:DealDamage(attacker, victim, damage, damageType)
    if not attacker or not victim then return end
    if not victim:IsA("Player") then return end
    
    local victimId = victim.UserId
    local victimData = self.playerCombatData[victimId]
    
    if not victimData then return end
    
    -- Vérifier si la victime bloque
    if victimData.isBlocking then
        -- Réduire les dégâts de 70% en bloquant
        damage = damage * 0.3
        self:SendNotification(victim, "Attaque bloquée!", "info")
        if attacker and attacker:IsA("Player") then
            self:SendNotification(attacker, "Attaque bloquée par " .. victim.Name, "warning")
        end
    end
    
    -- Vérifier si la victime a paré
    if victimData.parryWindow and tick() <= victimData.parryWindow then
        -- Parade réussie : annuler l'attaque et étourdir l'attaquant
        victimData.parryWindow = nil
        self:SendNotification(victim, "Parade réussie!", "success")
        if attacker and attacker:IsA("Player") then
            self:SendNotification(attacker, "Vous avez été paré!", "error")
            self:ApplyStatusEffect(attacker, "stunned", 2, 1)
        end
        return
    end
    
    -- Calculer les dégâts finaux avec l'armure
    local armorReduction = victimData.armor * 0.5  -- Chaque point d'armure réduit de 0.5 point de dégâts
    local finalDamage = math.max(1, damage - armorReduction)  -- Minimum 1 dégât
    
    -- Appliquer les dégâts
    victimData.currentHealth = math.max(0, victimData.currentHealth - finalDamage)
    victimData.damageTaken = victimData.damageTaken + finalDamage
    victimData.isInCombat = true
    victimData.lastCombatTime = tick()
    
    -- Mettre à jour les statistiques de l'attaquant
    if attacker:IsA("Player") then
        local attackerId = attacker.UserId
        local attackerData = self.playerCombatData[attackerId]
        
        if attackerData then
            attackerData.damageDealt = attackerData.damageDealt + finalDamage
            attackerData.isInCombat = true
            attackerData.lastCombatTime = tick()
            attackerData.combatTarget = victimId
        end
    end
    
    -- Mettre à jour le client de la victime
    self:UpdateClientCombatData(victim)
    
    -- Envoyer un événement de dégâts
    if self.remoteEvents.TakeDamage then
        self.remoteEvents.TakeDamage:FireClient(victim, finalDamage, damageType, attacker.Name)
    end
    
    -- Effet visuel de dégâts
    self:ShowDamageIndicator(victim, finalDamage)
    
    -- Vérifier si le joueur est mort
    if victimData.currentHealth <= 0 then
        self:HandlePlayerDeath(victim, attacker)
    end
end

-- Afficher un indicateur de dégâts
function CombatService:ShowDamageIndicator(player, damage)
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Créer un BillboardGui pour afficher les dégâts
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = humanoidRootPart
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "-" .. math.floor(damage)
    textLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = billboard
    
    -- Animer et détruire
    Debris:AddItem(billboard, 1)
end

-- Attaquer une structure
function CombatService:AttackStructure(attacker, structureId, hitPart)
    if not attacker or not attacker:IsA("Player") then return false end
    if not self.buildingService then return false end
    
    local attackerId = attacker.UserId
    
    -- Vérifier le cooldown d'attaque
    local currentTime = tick()
    local lastAttack = self.lastAttackTime[attackerId] or 0
    
    if currentTime - lastAttack < self.attackCooldown then
        return false, "Attaque trop rapide"
    end
    
    -- Vérifier que la structure existe
    local structureData = self.buildingService.structuresById[structureId]
    if not structureData then
        return false, "Structure introuvable"
    end
    
    -- Vérifier la distance
    local attackerChar = attacker.Character
    if not attackerChar then return false, "Personnage invalide" end
    
    local attackerRoot = attackerChar:FindFirstChild("HumanoidRootPart")
    if not attackerRoot then return false, "Position invalide" end
    
    -- Calculer la distance jusqu'à la structure
    local structurePos = hitPart and hitPart.Position or structureData.position
    if not structurePos then return false, "Position de structure invalide" end
    
    local distance = (attackerRoot.Position - structurePos).Magnitude
    
    -- Obtenir l'arme équipée
    local weapon = self:GetEquippedWeapon(attacker)
    local weaponData = weapon and ItemTypes[weapon.id]
    
    -- Déterminer la portée d'attaque
    local attackRange = 7  -- Portée par défaut (mêlée)
    
    if weaponData then
        if weaponData.toolType == "bow" then
            attackRange = 50  -- Portée pour arc
        elseif weaponData.toolType == "weapon" or weaponData.toolType == "tool" then
            attackRange = 10  -- Portée pour armes/outils de mêlée
        end
    end
    
    if distance > attackRange then
        self:SendNotification(attacker, "Structure trop éloignée", "warning")
        return false, "Structure trop éloignée"
    end
    
    -- Vérifier si le joueur peut endommager cette structure
    -- Le propriétaire peut endommager sa propre structure
    -- Les autres joueurs peuvent attaquer les structures ennemies
    local canDamage = true
    
    if structureData.owner == attackerId then
        -- Le propriétaire peut toujours endommager sa structure (par exemple pour la détruire)
        canDamage = true
    elseif self.tribeService and self.tribeService:ArePlayersInSameTribe then
        -- Vérifier si c'est une structure d'un allié
        local ownerPlayer = Players:GetPlayerByUserId(structureData.owner)
        if ownerPlayer and self.tribeService:ArePlayersInSameTribe(attacker, ownerPlayer) then
            self:SendNotification(attacker, "Vous ne pouvez pas attaquer les structures de votre tribu", "error")
            return false, "Structure alliée"
        end
    end
    
    if not canDamage then
        return false, "Vous ne pouvez pas endommager cette structure"
    end
    
    -- Calculer les dégâts
    local baseDamage = 2  -- Dégâts à mains nues sur structure (réduit)
    
    if weaponData then
        if weaponData.damage then
            baseDamage = weaponData.damage * 0.5  -- Les structures prennent 50% des dégâts d'arme
        end
        if weaponData.toolType == "tool" then
            -- Les outils font plus de dégâts aux structures
            baseDamage = weaponData.damage or 5
        end
    end
    
    -- Appliquer les dégâts à la structure
    local success = self.buildingService:DamageStructure(structureId, baseDamage, "player_attack")
    
    if success then
        -- Mettre à jour le cooldown
        self.lastAttackTime[attackerId] = currentTime
        
        -- Notifier le joueur
        local structureName = ItemTypes[structureData.type] and ItemTypes[structureData.type].name or structureData.type
        self:SendNotification(attacker, string.format("Vous avez endommagé %s (-%.0f durabilité)", structureName, baseDamage), "info")
        
        -- Mettre l'attaquant en combat
        if self.playerCombatData[attackerId] then
            self.playerCombatData[attackerId].isInCombat = true
            self.playerCombatData[attackerId].lastCombatTime = currentTime
            self:UpdateClientCombatData(attacker)
        end
        
        return true, "Structure endommagée"
    end
    
    return false, "Erreur lors de l'endommagement de la structure"
end

-- Gérer la mort d'un joueur en combat
function CombatService:HandlePlayerDeath(victim, killer)
    local victimId = victim.UserId
    local victimData = self.playerCombatData[victimId]
    
    if not victimData then return end
    
    -- Mettre à jour les statistiques
    victimData.deaths = victimData.deaths + 1
    victimData.currentHealth = 0
    
    if killer and killer:IsA("Player") then
        local killerId = killer.UserId
        local killerData = self.playerCombatData[killerId]
        
        if killerData then
            killerData.kills = killerData.kills + 1
        end
        
        -- Notifier le tueur
        self:SendNotification(killer, "Vous avez éliminé " .. victim.Name, "success")
    end
    
    -- Notifier la victime
    self:SendNotification(victim, "Vous avez été éliminé", "error")
    
    -- Appeler le service de joueur pour gérer la mort
    if self.playerService then
        self.playerService:HandlePlayerDeath(victim, "killed")
    end
    
    -- Réinitialiser la santé après respawn
    delay(5, function()
        self:ResetPlayerHealth(victim)
    end)
end

-- Réinitialiser la santé d'un joueur
function CombatService:ResetPlayerHealth(player)
    local userId = player.UserId
    local combatData = self.playerCombatData[userId]
    
    if not combatData then return end
    
    combatData.currentHealth = combatData.maxHealth
    combatData.isInCombat = false
    combatData.combatTarget = nil
    
    self:UpdateClientCombatData(player)
end

-- Soigner un joueur
function CombatService:HealPlayer(player, amount)
    local userId = player.UserId
    local combatData = self.playerCombatData[userId]
    
    if not combatData then return false end
    
    local oldHealth = combatData.currentHealth
    combatData.currentHealth = math.min(combatData.maxHealth, combatData.currentHealth + amount)
    
    local actualHealing = combatData.currentHealth - oldHealth
    
    if actualHealing > 0 then
        self:UpdateClientCombatData(player)
        self:SendNotification(player, "+" .. math.floor(actualHealing) .. " PV", "success")
        return true
    end
    
    return false
end

-- Obtenir l'arme équipée d'un joueur
function CombatService:GetEquippedWeapon(player)
    if not self.inventoryService then return nil end
    
    local userId = player.UserId
    local inventory = self.inventoryService.playerInventories[userId]
    
    if not inventory or not inventory.equipped then return nil end
    
    local toolSlot = inventory.equipped["tool"]
    if not toolSlot then return nil end
    
    return inventory.items[toolSlot]
end

-- Calculer l'armure totale d'un joueur
function CombatService:CalculatePlayerArmor(player)
    if not self.inventoryService then return 0 end
    
    local userId = player.UserId
    local inventory = self.inventoryService.playerInventories[userId]
    
    if not inventory or not inventory.equipped then return 0 end
    
    local totalArmor = 0
    
    -- Parcourir tous les équipements
    for slot, itemSlot in pairs(inventory.equipped) do
        local item = inventory.items[itemSlot]
        if item then
            local itemType = ItemTypes[item.id]
            if itemType and itemType.defenseBonus then
                totalArmor = totalArmor + itemType.defenseBonus
            end
        end
    end
    
    return totalArmor
end

-- Mettre à jour régulièrement les données de combat
function CombatService:UpdateCombatStates()
    local currentTime = tick()
    
    for userId, combatData in pairs(self.playerCombatData) do
        local player = Players:GetPlayerByUserId(userId)
        
        -- Mettre à jour les effets de statut
        if player then
            self:UpdateStatusEffects(player)
        end
        
        -- Sortir du combat après 10 secondes sans activité
        if combatData.isInCombat and (currentTime - combatData.lastCombatTime) > 10 then
            combatData.isInCombat = false
            combatData.combatTarget = nil
            
            if player then
                self:UpdateClientCombatData(player)
            end
        end
        
        -- Régénération de santé hors combat (liée à la survie)
        if not combatData.isInCombat and combatData.currentHealth < combatData.maxHealth then
            local regenRate = 0.5 -- Taux de base
            
            -- Modifier selon la survie
            local player = Players:GetPlayerByUserId(userId)
            if player and self.survivalService then
                local survivalData = self.survivalService.playerSurvivalData[userId]
                if survivalData then
                    -- Bonus si bien nourri et hydraté
                    if survivalData.hunger >= 70 and survivalData.thirst >= 70 then
                        regenRate = regenRate * 1.5
                    -- Ralentir si faim < 30%
                    elseif survivalData.hunger < 30 then
                        regenRate = regenRate * 0.3
                    end
                    
                    -- Arrêter si soif critique < 20%
                    if survivalData.thirst < 20 then
                        regenRate = 0
                    end
                    
                    -- Bonus si bien reposé
                    if survivalData.energy >= 80 then
                        regenRate = regenRate * 1.2
                    end
                end
            end
            
            combatData.currentHealth = math.min(combatData.maxHealth, combatData.currentHealth + regenRate)
            
            if player then
                self:UpdateClientCombatData(player)
            end
        end
        
        -- Mettre à jour l'armure
        local player = Players:GetPlayerByUserId(userId)
        if player then
            combatData.armor = self:CalculatePlayerArmor(player)
        end
    end
end

-- Mettre à jour les données de combat pour le client
function CombatService:UpdateClientCombatData(player)
    if not player or not player:IsA("Player") then return end
    
    local userId = player.UserId
    local combatData = self.playerCombatData[userId]
    
    if not combatData then return end
    
    -- Envoyer les données au client
    if self.remoteEvents.UpdateHealth then
        self.remoteEvents.UpdateHealth:FireClient(player, {
            currentHealth = combatData.currentHealth,
            maxHealth = combatData.maxHealth,
            armor = combatData.armor,
            isInCombat = combatData.isInCombat
        })
    end
end

-- Système d'effets de statut
function CombatService:ApplyStatusEffect(player, effectType, duration, intensity)
    if not player or not player:IsA("Player") then return false end
    
    local userId = player.UserId
    local combatData = self.playerCombatData[userId]
    if not combatData then return false end
    
    -- Créer l'effet
    local effect = {
        type = effectType,
        startTime = tick(),
        duration = duration,
        intensity = intensity or 1,
        lastTick = tick()
    }
    
    table.insert(combatData.statusEffects, effect)
    
    -- Notifier le joueur
    local effectNames = {
        poison = "Empoisonnement",
        bleeding = "Saignement",
        burning = "Brûlure",
        frozen = "Gelé",
        stunned = "Étourdi"
    }
    
    local effectName = effectNames[effectType] or effectType
    self:SendNotification(player, "Vous subissez: " .. effectName, "warning")
    
    return true
end

-- Mettre à jour les effets de statut
function CombatService:UpdateStatusEffects(player)
    if not player or not player:IsA("Player") then return end
    
    local userId = player.UserId
    local combatData = self.playerCombatData[userId]
    if not combatData then return end
    
    local currentTime = tick()
    local effectsToRemove = {}
    
    for i, effect in ipairs(combatData.statusEffects) do
        -- Vérifier si l'effet a expiré
        if currentTime - effect.startTime >= effect.duration then
            table.insert(effectsToRemove, i)
        else
            -- Appliquer l'effet périodiquement (toutes les secondes)
            if currentTime - effect.lastTick >= 1 then
                effect.lastTick = currentTime
                
                if effect.type == "poison" then
                    -- Poison : 2 dégâts par seconde
                    self:DealDamage(nil, player, 2 * effect.intensity, "poison")
                elseif effect.type == "bleeding" then
                    -- Saignement : 3 dégâts par seconde
                    self:DealDamage(nil, player, 3 * effect.intensity, "bleeding")
                elseif effect.type == "burning" then
                    -- Brûlure : 4 dégâts par seconde
                    self:DealDamage(nil, player, 4 * effect.intensity, "burning")
                elseif effect.type == "frozen" then
                    -- Gelé : ralentissement
                    local character = player.Character
                    if character and character:FindFirstChild("Humanoid") then
                        character.Humanoid.WalkSpeed = 8
                    end
                elseif effect.type == "stunned" then
                    -- Étourdi : impossible de bouger
                    local character = player.Character
                    if character and character:FindFirstChild("Humanoid") then
                        character.Humanoid.WalkSpeed = 0
                    end
                end
            end
        end
    end
    
    -- Retirer les effets expirés
    for i = #effectsToRemove, 1, -1 do
        local effectIndex = effectsToRemove[i]
        local removedEffect = table.remove(combatData.statusEffects, effectIndex)
        
        -- Réinitialiser la vitesse si nécessaire
        if removedEffect.type == "frozen" or removedEffect.type == "stunned" then
            local character = player.Character
            if character and character:FindFirstChild("Humanoid") then
                character.Humanoid.WalkSpeed = 16
            end
        end
    end
end

-- Système de blocage
function CombatService:StartBlocking(player)
    if not player or not player:IsA("Player") then return false end
    
    local userId = player.UserId
    local combatData = self.playerCombatData[userId]
    if not combatData then return false end
    
    -- Vérifier le cooldown de blocage (2 secondes)
    local currentTime = tick()
    if currentTime - combatData.lastBlockTime < 2 then
        self:SendNotification(player, "Blocage en cooldown", "warning")
        return false
    end
    
    combatData.isBlocking = true
    combatData.lastBlockTime = currentTime
    
    -- Ralentir le joueur pendant le blocage
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = 8
    end
    
    self:SendNotification(player, "Blocage activé", "info")
    
    return true
end

-- Arrêter le blocage
function CombatService:StopBlocking(player)
    if not player or not player:IsA("Player") then return false end
    
    local userId = player.UserId
    local combatData = self.playerCombatData[userId]
    if not combatData then return false end
    
    combatData.isBlocking = false
    
    -- Restaurer la vitesse normale
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        character.Humanoid.WalkSpeed = 16
    end
    
    return true
end

-- Système de parade (parry)
function CombatService:AttemptParry(player)
    if not player or not player:IsA("Player") then return false end
    
    local userId = player.UserId
    local combatData = self.playerCombatData[userId]
    if not combatData then return false end
    
    -- La parade doit être activée juste avant de recevoir une attaque
    -- On marque un temps de parade de 0.5 secondes
    combatData.parryWindow = tick() + 0.5
    
    self:SendNotification(player, "Tentative de parade", "info")
    
    return true
end

-- Système de combos
function CombatService:UpdateComboCount(player)
    if not player or not player:IsA("Player") then return end
    
    local userId = player.UserId
    local combatData = self.playerCombatData[userId]
    if not combatData then return end
    
    local currentTime = tick()
    
    -- Réinitialiser le combo si plus de 3 secondes depuis la dernière attaque
    if currentTime - combatData.lastAttackTime > 3 then
        combatData.comboCount = 0
    end
    
    combatData.lastAttackTime = currentTime
    combatData.comboCount = combatData.comboCount + 1
    
    -- Bonus de dégâts pour les combos
    if combatData.comboCount >= 3 then
        self:SendNotification(player, "Combo x" .. combatData.comboCount .. "!", "success")
    end
end

-- Obtenir le multiplicateur de combo
function CombatService:GetComboMultiplier(player)
    if not player or not player:IsA("Player") then return 1 end
    
    local userId = player.UserId
    local combatData = self.playerCombatData[userId]
    if not combatData then return 1 end
    
    -- Bonus de 10% par attaque dans le combo (max 50%)
    local bonus = math.min(0.5, (combatData.comboCount - 1) * 0.1)
    return 1 + bonus
end

-- Zones de sécurité (safe zones)
function CombatService:IsInSafeZone(player)
    if not player or not player:IsA("Player") then return false end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    
    local position = character.HumanoidRootPart.Position
    
    -- Vérifier les zones de sécurité dans le workspace
    local safeZonesFolder = game:GetService("Workspace"):FindFirstChild("SafeZones")
    if safeZonesFolder then
        for _, zone in ipairs(safeZonesFolder:GetChildren()) do
            if zone:IsA("BasePart") or (zone:IsA("Model") and zone.PrimaryPart) then
                local zonePart = zone:IsA("BasePart") and zone or zone.PrimaryPart
                local distance = (zonePart.Position - position).Magnitude
                local radius = zone:GetAttribute("SafeRadius") or zonePart.Size.Magnitude
                
                if distance <= radius then
                    return true
                end
            end
        end
    end
    
    -- Vérifier si le joueur est dans un spawn point
    local spawnLocations = game:GetService("Workspace"):FindFirstChild("SpawnLocations")
    if spawnLocations then
        for _, spawn in ipairs(spawnLocations:GetChildren()) do
            if spawn:IsA("SpawnLocation") then
                local distance = (spawn.Position - position).Magnitude
                if distance <= 20 then -- Rayon de 20 studs autour du spawn
                    return true
                end
            end
        end
    end
    
    return false
end

-- Système de duels
function CombatService:ChallengeToDuel(challenger, target)
    if not challenger or not target then return false end
    if not challenger:IsA("Player") or not target:IsA("Player") then return false end
    
    -- Ne pas permettre de duel contre soi-même
    if challenger.UserId == target.UserId then
        self:SendNotification(challenger, "Vous ne pouvez pas vous défier vous-même", "error")
        return false
    end
    
    -- Vérifier que les deux joueurs ne sont pas déjà en duel
    if self.activeDuels then
        for _, duel in pairs(self.activeDuels) do
            if duel.player1 == challenger.UserId or duel.player2 == challenger.UserId then
                self:SendNotification(challenger, "Vous êtes déjà en duel", "error")
                return false
            end
            if duel.player1 == target.UserId or duel.player2 == target.UserId then
                self:SendNotification(challenger, target.Name .. " est déjà en duel", "error")
                return false
            end
        end
    else
        self.activeDuels = {}
        self.duelChallenges = {}
        self.nextDuelId = 1
    end
    
    -- Créer une invitation de duel
    local challengeId = "challenge_" .. challenger.UserId .. "_" .. target.UserId
    
    self.duelChallenges[challengeId] = {
        challenger = challenger.UserId,
        target = target.UserId,
        timestamp = tick()
    }
    
    -- Notifier les joueurs
    self:SendNotification(challenger, "Invitation de duel envoyée à " .. target.Name, "info")
    self:SendNotification(target, challenger.Name .. " vous défie en duel! Acceptez ou refusez.", "warning")
    
    -- Auto-expiration après 30 secondes
    delay(30, function()
        if self.duelChallenges[challengeId] then
            self.duelChallenges[challengeId] = nil
            self:SendNotification(challenger, "L'invitation de duel a expiré", "info")
        end
    end)
    
    return true
end

-- Accepter un duel
function CombatService:AcceptDuel(target, challengerId)
    if not target or not target:IsA("Player") then return false end
    
    local challengeId = "challenge_" .. challengerId .. "_" .. target.UserId
    local challenge = self.duelChallenges[challengeId]
    
    if not challenge then
        self:SendNotification(target, "Aucune invitation de duel trouvée", "error")
        return false
    end
    
    local challenger = Players:GetPlayerByUserId(challengerId)
    if not challenger then
        self:SendNotification(target, "Le challenger n'est plus connecté", "error")
        self.duelChallenges[challengeId] = nil
        return false
    end
    
    -- Créer le duel
    local duelId = "duel_" .. self.nextDuelId
    self.nextDuelId = self.nextDuelId + 1
    
    self.activeDuels[duelId] = {
        player1 = challengerId,
        player2 = target.UserId,
        startTime = tick(),
        winner = nil
    }
    
    -- Retirer l'invitation
    self.duelChallenges[challengeId] = nil
    
    -- Notifier les joueurs
    self:SendNotification(challenger, "Duel accepté! Combat contre " .. target.Name, "success")
    self:SendNotification(target, "Duel commencé contre " .. challenger.Name, "success")
    
    -- Téléporter les joueurs dans une arène de duel (optionnel)
    -- Pour l'instant, ils se battent là où ils sont
    
    return true
end

-- Refuser un duel
function CombatService:DeclineDuel(target, challengerId)
    if not target or not target:IsA("Player") then return false end
    
    local challengeId = "challenge_" .. challengerId .. "_" .. target.UserId
    local challenge = self.duelChallenges[challengeId]
    
    if not challenge then
        return false
    end
    
    local challenger = Players:GetPlayerByUserId(challengerId)
    if challenger then
        self:SendNotification(challenger, target.Name .. " a refusé votre duel", "warning")
    end
    
    self:SendNotification(target, "Vous avez refusé le duel", "info")
    self.duelChallenges[challengeId] = nil
    
    return true
end

-- Vérifier si deux joueurs sont en duel
function CombatService:ArePlayersInDuel(player1, player2)
    if not self.activeDuels then return false end
    
    local userId1 = player1.UserId
    local userId2 = player2.UserId
    
    for _, duel in pairs(self.activeDuels) do
        if (duel.player1 == userId1 and duel.player2 == userId2) or
           (duel.player1 == userId2 and duel.player2 == userId1) then
            return true, duel
        end
    end
    
    return false
end

-- Terminer un duel
function CombatService:EndDuel(duelId, winnerId)
    local duel = self.activeDuels[duelId]
    if not duel then return false end
    
    duel.winner = winnerId
    duel.endTime = tick()
    
    local winner = Players:GetPlayerByUserId(winnerId)
    local loserId = (duel.player1 == winnerId) and duel.player2 or duel.player1
    local loser = Players:GetPlayerByUserId(loserId)
    
    if winner then
        self:SendNotification(winner, "Vous avez gagné le duel!", "success")
    end
    
    if loser then
        self:SendNotification(loser, "Vous avez perdu le duel", "error")
    end
    
    -- Retirer le duel actif
    self.activeDuels[duelId] = nil
    
    return true
end

-- Envoyer une notification
function CombatService:SendNotification(player, message, messageType)
    if self.remoteEvents.Notification then
        self.remoteEvents.Notification:FireClient(player, message, messageType or "info")
    else
        print("Notification pour " .. player.Name .. ": " .. message)
    end
end

-- Gérer la déconnexion d'un joueur
function CombatService:HandlePlayerRemoving(player)
    local userId = player.UserId
    
    if self.playerCombatData[userId] then
        -- Sauvegarder les statistiques de combat si nécessaire
        self.playerCombatData[userId] = nil
    end
    
    self.lastAttackTime[userId] = nil
end

-- Démarrer le service
function CombatService:Start(services)
    print("CombatService: Démarrage...")
    
    -- Récupérer les références aux autres services
    self.inventoryService = services.InventoryService
    self.playerService = services.PlayerService
    self.tribeService = services.TribeService
    self.buildingService = services.BuildingService
    self.survivalService = services.SurvivalService
    
    -- Récupérer les références aux RemoteEvents
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if Events then
        self.remoteEvents = {
            AttackPlayer = Events:FindFirstChild("AttackPlayer"),
            AttackStructure = Events:FindFirstChild("AttackStructure"),
            TakeDamage = Events:FindFirstChild("TakeDamage"),
            UpdateHealth = Events:FindFirstChild("UpdateHealth"),
            EquipWeapon = Events:FindFirstChild("EquipWeapon"),
            Notification = Events:FindFirstChild("Notification")
        }
        
        -- Créer l'événement AttackStructure s'il n'existe pas
        if not self.remoteEvents.AttackStructure then
            local attackStructureEvent = Instance.new("RemoteEvent")
            attackStructureEvent.Name = "AttackStructure"
            attackStructureEvent.Parent = Events
            self.remoteEvents.AttackStructure = attackStructureEvent
            print("CombatService: RemoteEvent AttackStructure créé")
        end
        
        -- Connecter les événements
        if self.remoteEvents.AttackPlayer then
            self.remoteEvents.AttackPlayer.OnServerEvent:Connect(function(player, target, attackType)
                self:AttackTarget(player, target, attackType)
            end)
        end
        
        if self.remoteEvents.AttackStructure then
            self.remoteEvents.AttackStructure.OnServerEvent:Connect(function(player, structureId, hitPart)
                self:AttackStructure(player, structureId, hitPart)
            end)
        end
    else
        warn("CombatService: Dossier Events non trouvé dans ReplicatedStorage")
    end
    
    -- Initialiser les joueurs existants
    for _, player in pairs(Players:GetPlayers()) do
        self:InitializePlayerCombat(player)
    end
    
    -- Gérer les nouveaux joueurs
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerCombat(player)
        
        player.CharacterAdded:Connect(function(character)
            self:SetupCharacterCombat(character)
            self:ResetPlayerHealth(player)
        end)
    end)
    
    -- Gérer les déconnexions
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
    
    -- Démarrer la boucle de mise à jour
    spawn(function()
        while true do
            wait(1)  -- Mettre à jour chaque seconde
            pcall(function()
                self:UpdateCombatStates()
            end)
        end
    end)
    
    print("CombatService: Démarré avec succès")
    return self
end

return CombatService
