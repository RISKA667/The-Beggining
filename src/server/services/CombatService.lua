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
        deaths = 0
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
    
    -- Vérifier si c'est un allié (même tribu)
    if self.tribeService and self.tribeService:ArePlayersInSameTribe(attacker, target) then
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
        -- Sortir du combat après 10 secondes sans activité
        if combatData.isInCombat and (currentTime - combatData.lastCombatTime) > 10 then
            combatData.isInCombat = false
            combatData.combatTarget = nil
            
            local player = Players:GetPlayerByUserId(userId)
            if player then
                self:UpdateClientCombatData(player)
            end
        end
        
        -- Régénération de santé hors combat
        if not combatData.isInCombat and combatData.currentHealth < combatData.maxHealth then
            combatData.currentHealth = math.min(combatData.maxHealth, combatData.currentHealth + 0.5)
            
            local player = Players:GetPlayerByUserId(userId)
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
