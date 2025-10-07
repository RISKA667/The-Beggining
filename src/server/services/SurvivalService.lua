-- src/server/services/SurvivalService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared.constants.GameSettings)

local SurvivalService = {}
SurvivalService.__index = SurvivalService

-- Créer une instance du service
function SurvivalService.new()
    local self = setmetatable({}, SurvivalService)
    
    -- Données de survie des joueurs
    self.playerSurvivalData = {}
    
    -- Constantes - Utilisation des valeurs de GameSettings avec fallbacks
    self.maxHunger = GameSettings.Survival.maxHunger or 100
    self.maxThirst = GameSettings.Survival.maxThirst or 100
    self.maxTemperature = 100 -- Valeur fixe car pas dans GameSettings
    self.maxEnergy = GameSettings.Survival.maxEnergy or 100
    
    -- Taux de décroissance (par seconde)
    self.hungerDecayRate = GameSettings.Survival.hungerDecayRate or 0.05
    self.thirstDecayRate = GameSettings.Survival.thirstDecayRate or 0.08
    self.energyDecayRate = GameSettings.Survival.energyDecayRate or 0.03
    self.energyRecoveryRate = GameSettings.Survival.energyRecoveryRate or 0.1
    
    -- Seuils critiques
    self.criticalHunger = GameSettings.Survival.criticalHungerThreshold or 15
    self.criticalThirst = GameSettings.Survival.criticalThirstThreshold or 10
    self.criticalEnergy = GameSettings.Survival.criticalEnergyThreshold or 10
    self.criticalColdTemperature = GameSettings.Survival.criticalColdThreshold or 20
    self.criticalHotTemperature = GameSettings.Survival.criticalHeatThreshold or 80
    
    -- Intervalles de temps
    self.updateInterval = 1  -- Intervalle de mise à jour en secondes
    self.notificationInterval = 60 -- Intervalle pour les notifications en secondes
    
    -- Gestion des timeouts et intervalles
    self.lastNotificationTimes = {} -- [userId][type] = timestamp
    
    -- Références aux services (seront injectés dans Start)
    self.playerService = nil
    self.inventoryService = nil
    
    -- Events RemoteEvent
    self.remoteEvents = {}
    
    return self
end

-- Initialiser les données de survie pour un joueur
function SurvivalService:InitializePlayerSurvival(player)
    if not player or not player:IsA("Player") then
        warn("SurvivalService:InitializePlayerSurvival - player argument invalide")
        return
    end
    
    local userId = player.UserId
    
    -- Vérifier si les données existent déjà
    if self.playerSurvivalData[userId] then 
        return 
    end
    
    -- Initialiser les données avec des valeurs par défaut
    self.playerSurvivalData[userId] = {
        hunger = self.maxHunger,       -- 100 = rassasié, 0 = affamé
        thirst = self.maxThirst,       -- 100 = hydraté, 0 = assoiffé
        temperature = 50,              -- 0 = gelé, 100 = brûlant, 50 = idéal
        energy = self.maxEnergy,       -- 100 = plein d'énergie, 0 = épuisé
        isSleeping = false,            -- Si le joueur est en train de dormir
        lastUpdateTime = os.time(),    -- Dernière mise à jour des stats
        effects = {},                  -- Effets temporaires (maladies, etc.)
        sleepingLocation = nil         -- Endroit où le joueur dort (pour bonus)
    }
    
    -- Initialiser le suivi des notifications
    self.lastNotificationTimes[userId] = {
        hunger = 0,
        thirst = 0,
        energy = 0,
        temperature = 0
    }
    
    -- Mettre à jour le client avec les données initiales
    self:UpdateClientSurvivalData(player)
    
    print("SurvivalService: Données de survie initialisées pour " .. player.Name)
end

-- Mettre à jour périodiquement les données de survie
function SurvivalService:UpdateSurvivalData(player)
    if not player or not player:IsA("Player") then return end
    
    local userId = player.UserId
    local data = self.playerSurvivalData[userId]
    
    if not data then 
        return 
    end
    
    local currentTime = os.time()
    local timeDelta = currentTime - data.lastUpdateTime
    
    -- Si le délai est anormalement long (plus de 5 minutes), limiter pour éviter une chute drastique
    if timeDelta > 300 then
        timeDelta = 300
        print("SurvivalService: Délai anormalement long pour " .. player.Name .. " - limité à 5 minutes")
    end
    
    -- Mettre à jour la faim - seulement si le joueur n'est pas endormi
    if not data.isSleeping then
        data.hunger = math.max(0, data.hunger - (self.hungerDecayRate * timeDelta))
    else
        -- Pendant le sommeil, la faim décroit plus lentement
        data.hunger = math.max(0, data.hunger - (self.hungerDecayRate * 0.5 * timeDelta))
    end
    
    -- Mettre à jour la soif - toujours active même pendant le sommeil
    data.thirst = math.max(0, data.thirst - (self.thirstDecayRate * timeDelta))
    
    -- Mettre à jour l'énergie
    if not data.isSleeping then
        -- Pendant l'éveil, l'énergie diminue
        data.energy = math.max(0, data.energy - (self.energyDecayRate * timeDelta))
    else
        -- Pendant le sommeil, l'énergie récupère
        -- Appliquer un bonus selon l'endroit où le joueur dort
        local recoveryMultiplier = 1
        
        if data.sleepingLocation == "wooden_bed" then
            recoveryMultiplier = 1.5
        elseif data.sleepingLocation == "comfortable_bed" then
            recoveryMultiplier = 2
        end
        
        data.energy = math.min(self.maxEnergy, data.energy + (self.energyRecoveryRate * recoveryMultiplier * timeDelta))
        
        -- Si l'énergie est complètement récupérée, réveiller automatiquement le joueur
        if data.energy >= self.maxEnergy then
            self:StopSleeping(player)
            self:SendNotification(player, "Vous vous êtes réveillé, complètement reposé!", "info")
        end
    end
    
    -- Mettre à jour la température en fonction de l'environnement
    local newTemperature = self:CalculateEnvironmentTemperature(player)
    data.temperature = data.temperature + (newTemperature - data.temperature) * 0.1 * timeDelta -- Changement progressif
    
    -- Appliquer les effets de l'environnement
    self:ApplyEnvironmentalEffects(player)
    
    -- Vérifier les conditions critiques
    self:CheckCriticalConditions(player)
    
    -- Mettre à jour le temps de dernière mise à jour
    data.lastUpdateTime = currentTime
    
    -- Mettre à jour le client
    self:UpdateClientSurvivalData(player)
end

-- Vérifier les conditions critiques de survie
function SurvivalService:CheckCriticalConditions(player)
    if not player or not player:IsA("Player") then return end
    
    local userId = player.UserId
    local data = self.playerSurvivalData[userId]
    
    if not data then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local currentTime = os.time()
    local isNotificationTimeoutExpired = function(type)
        return (currentTime - (self.lastNotificationTimes[userId][type] or 0)) >= self.notificationInterval
    end
    
    -- Réinitialiser la vitesse de marche à chaque vérification
    local baseWalkSpeed = humanoid.WalkSpeed
    local speedMultiplier = 1
    
    -- Vérifier la faim
    if data.hunger <= 0 then
        -- Le joueur meurt de faim
        if humanoid.Health > 0 then
            humanoid.Health = 0
            if self.playerService then
                self.playerService:HandlePlayerDeath(player, "hunger")
            end
        end
        return
    elseif data.hunger <= self.criticalHunger then
        -- Faim critique - appliquer des effets (ralentissement)
        speedMultiplier = speedMultiplier * 0.7
        
        -- Envoyer une notification périodique au joueur
        if isNotificationTimeoutExpired("hunger") then
            self:SendNotification(player, "Vous êtes affamé! Trouvez de la nourriture rapidement.", "warning")
            self.lastNotificationTimes[userId]["hunger"] = currentTime
        end
    end
    
    -- Vérifier la soif
    if data.thirst <= 0 then
        -- Le joueur meurt de soif
        if humanoid.Health > 0 then
            humanoid.Health = 0
            if self.playerService then
                self.playerService:HandlePlayerDeath(player, "thirst")
            end
        end
        return
    elseif data.thirst <= self.criticalThirst then
        -- Soif critique - appliquer des effets
        speedMultiplier = speedMultiplier * 0.7
        
        -- Envoyer une notification périodique au joueur
        if isNotificationTimeoutExpired("thirst") then
            self:SendNotification(player, "Vous êtes déshydraté! Trouvez de l'eau rapidement.", "warning")
            self.lastNotificationTimes[userId]["thirst"] = currentTime
        end
    end
    
    -- Vérifier l'énergie
    if data.energy <= self.criticalEnergy then
        -- Fatigue critique - appliquer des effets
        speedMultiplier = speedMultiplier * 0.8
        
        -- Envoyer une notification périodique au joueur
        if isNotificationTimeoutExpired("energy") then
            self:SendNotification(player, "Vous êtes épuisé! Trouvez un endroit pour dormir.", "warning")
            self.lastNotificationTimes[userId]["energy"] = currentTime
        end
    end
    
    -- Vérifier la température
    local tempDamage = GameSettings.Survival.temperatureDamageAmount or 1
    local tempDamageApplied = false
    
    if data.temperature <= self.criticalColdTemperature then
        -- Trop froid - appliquer des dégâts progressifs
        humanoid.Health = math.max(0, humanoid.Health - tempDamage)
        tempDamageApplied = true
        
        -- Envoyer une notification périodique au joueur
        if isNotificationTimeoutExpired("temperature") then
            self:SendNotification(player, "Vous avez froid! Cherchez un feu ou un abri.", "warning")
            self.lastNotificationTimes[userId]["temperature"] = currentTime
        end
        
        -- Si la santé atteint 0, gérer la mort par le froid
        if humanoid.Health <= 0 and self.playerService then
            self.playerService:HandlePlayerDeath(player, "cold")
            return
        end
    elseif data.temperature >= self.criticalHotTemperature then
        -- Trop chaud - appliquer des dégâts progressifs
        humanoid.Health = math.max(0, humanoid.Health - tempDamage)
        tempDamageApplied = true
        
        -- Envoyer une notification périodique au joueur
        if isNotificationTimeoutExpired("temperature") then
            self:SendNotification(player, "Vous avez trop chaud! Trouvez de l'ombre.", "warning")
            self.lastNotificationTimes[userId]["temperature"] = currentTime
        end
        
        -- Si la santé atteint 0, gérer la mort par la chaleur
        if humanoid.Health <= 0 and self.playerService then
            self.playerService:HandlePlayerDeath(player, "heat")
            return
        end
    end
    
    -- Appliquer le modificateur de vitesse
    humanoid.WalkSpeed = baseWalkSpeed * speedMultiplier
end

-- Calculer la température environnementale pour un joueur
function SurvivalService:CalculateEnvironmentTemperature(player)
    if not player or not player:IsA("Player") then 
        return 50 -- Valeur par défaut
    end
    
    local character = player.Character
    if not character then 
        return 50 
    end
    
    local position = character:GetPrimaryPartCFrame().Position
    
    -- Vérifier si le joueur est à l'intérieur d'un bâtiment (ou abri)
    local isIndoors = self:IsPlayerIndoors(player)
    
    -- Vérifier la proximité avec des sources de chaleur
    local nearHeatSource, heatSourceIntensity = self:IsNearHeatSource(player)
    
    -- Obtenir le temps actuel (heure de la journée)
    local isNight = self:IsNightTime()
    
    -- Température de base selon l'heure
    local baseTemperature = isNight and 35 or 50 -- Plus froid la nuit
    
    -- Adapter la température en fonction de l'environnement
    if isIndoors then
        baseTemperature = baseTemperature + 10 -- Plus chaud à l'intérieur
    end
    
    if nearHeatSource then
        baseTemperature = baseTemperature + heatSourceIntensity
    end
    
    -- Vérifier aussi l'équipement du joueur
    baseTemperature = baseTemperature + self:GetTemperatureModifierFromEquipment(player)
    
    -- Limiter la température entre 0 et 100
    return math.clamp(baseTemperature, 0, 100)
end

-- Vérifier si le joueur est à l'intérieur d'un bâtiment
function SurvivalService:IsPlayerIndoors(player)
    if not player or not player:IsA("Player") then 
        return false 
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then 
        return false 
    end
    
    local position = character.HumanoidRootPart.Position
    
    -- Lancer un rayon vers le haut pour vérifier s'il y a un toit
    local rayOrigin = position
    local rayDirection = Vector3.new(0, 20, 0) -- Vers le haut
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    local hitPart = raycastResult and raycastResult.Instance
    
    -- Si un toit est détecté, le joueur est probablement à l'intérieur
    return hitPart ~= nil
end

-- Vérifier si le joueur est près d'une source de chaleur
function SurvivalService:IsNearHeatSource(player)
    if not player or not player:IsA("Player") then 
        return false, 0 
    end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then 
        return false, 0 
    end
    
    local position = character.HumanoidRootPart.Position
    
    -- Obtenir toutes les sources de chaleur (feux de camp, fours, etc.)
    local heatSources = workspace:FindFirstChild("Structures")
    if not heatSources then
        return false, 0
    end
    
    -- Parcourir toutes les structures pour trouver des sources de chaleur
    for _, structure in ipairs(heatSources:GetChildren()) do
        -- Vérifier si c'est une source de chaleur
        if structure:GetAttribute("HeatSource") and structure:FindFirstChild("PrimaryPart") then
            local heatPosition = structure.PrimaryPart.Position
            local distance = (position - heatPosition).Magnitude
            
            -- Obtenir le rayon et l'intensité
            local heatRadius = structure:GetAttribute("HeatRadius") or 10
            local heatIntensity = structure:GetAttribute("HeatIntensity") or 15
            
            -- Calculer l'intensité en fonction de la distance
            if distance <= heatRadius then
                local distanceFactor = 1 - (distance / heatRadius)
                return true, heatIntensity * distanceFactor
            end
        end
    end
    
    return false, 0
end

-- Vérifier s'il fait nuit
function SurvivalService:IsNightTime()
    -- Dans une implémentation complète, vérifier avec TimeService
    local currentTime = game:GetService("Lighting").ClockTime
    
    -- Considérer la nuit de 19h à 6h
    return currentTime >= 19 or currentTime < 6
end

-- Obtenir les modificateurs de température des équipements
function SurvivalService:GetTemperatureModifierFromEquipment(player)
    if not player or not player:IsA("Player") then 
        return 0 
    end
    
    local modifier = 0
    
    -- Vérifier les vêtements équipés
    if self.inventoryService then
        local userId = player.UserId
        local inventory = self.inventoryService.playerInventories[userId]
        
        if inventory and inventory.equipped then
            local ItemTypes = require(Shared.constants.ItemTypes)
            
            -- Vérifier chaque type d'équipement
            for itemId, slotNumber in pairs(inventory.equipped) do
                local item = inventory.items[slotNumber]
                if item then
                    local itemType = ItemTypes[item.id]
                    if itemType and itemType.temperatureModifier then
                        modifier = modifier + itemType.temperatureModifier
                    end
                end
            end
        end
    end
    
    return modifier
end

-- Appliquer les effets de l'environnement sur le joueur
function SurvivalService:ApplyEnvironmentalEffects(player)
    if not player or not player:IsA("Player") then 
        return 
    end
    
    -- Fonction pour gérer les effets d'environnement supplémentaires
    -- Par exemple: pluie, tempêtes, désert chaud, etc.
    
    -- Pour l'instant, ces effets sont pris en compte dans CalculateEnvironmentTemperature
    -- Cette méthode pourrait être étendue pour d'autres effets comme:
    -- - Malus de vision dans le brouillard ou la tempête
    -- - Effets de statut comme "Trempé" ou "Gelé"
    -- - Effets visuels comme le givre à l'écran quand il fait très froid
end

-- Manger un aliment
function SurvivalService:ConsumeFood(player, foodItemId)
    if not player or not player:IsA("Player") then 
        return false 
    end
    
    local userId = player.UserId
    local data = self.playerSurvivalData[userId]
    
    if not data then 
        return false 
    end
    
    -- Vérifier que le joueur a l'aliment dans son inventaire
    if self.inventoryService and not self.inventoryService:HasItemInInventory(player, foodItemId, 1) then
        self:SendNotification(player, "Vous n'avez pas cet aliment dans votre inventaire", "error")
        return false
    end
    
    -- Récupérer les valeurs nutritives de l'aliment
    local ItemTypes = require(Shared.constants.ItemTypes)
    local foodItem = ItemTypes[foodItemId]
    
    if not foodItem then 
        return false 
    end
    
    local foodValue = foodItem.foodValue or 25  -- Valeur par défaut
    
    -- Augmenter la faim
    data.hunger = math.min(self.maxHunger, data.hunger + foodValue)
    
    -- Si l'aliment fournit également de l'hydratation (comme les fruits)
    if foodItem.drinkValue then
        data.thirst = math.min(self.maxThirst, data.thirst + foodItem.drinkValue)
    end
    
    -- Retirer l'aliment de l'inventaire
    if self.inventoryService then
        self.inventoryService:RemoveItemFromInventory(player, foodItemId, 1)
    end
    
    -- Mettre à jour le client
    self:UpdateClientSurvivalData(player)
    
    -- Envoyer une notification
    self:SendNotification(player, "Vous avez mangé " .. foodItem.name, "success")
    
    -- Jouer l'animation de manger (côté client)
    self:PlayClientAnimation(player, "eat")
    
    return true
end

-- Boire
function SurvivalService:ConsumeDrink(player, drinkItemId)
    if not player or not player:IsA("Player") then 
        return false 
    end
    
    local userId = player.UserId
    local data = self.playerSurvivalData[userId]
    
    if not data then 
        return false 
    end
    
    -- Vérifier que le joueur a la boisson dans son inventaire
    if self.inventoryService and not self.inventoryService:HasItemInInventory(player, drinkItemId, 1) then
        self:SendNotification(player, "Vous n'avez pas cette boisson dans votre inventaire", "error")
        return false
    end
    
    -- Récupérer les valeurs de la boisson
    local ItemTypes = require(Shared.constants.ItemTypes)
    local drinkItem = ItemTypes[drinkItemId]
    
    if not drinkItem then 
        return false 
    end
    
    local drinkValue = drinkItem.drinkValue or 30  -- Valeur par défaut
    
    -- Augmenter l'hydratation
    data.thirst = math.min(self.maxThirst, data.thirst + drinkValue)
    
    -- Retirer la boisson de l'inventaire
    if self.inventoryService then
        self.inventoryService:RemoveItemFromInventory(player, drinkItemId, 1)
    end
    
    -- Mettre à jour le client
    self:UpdateClientSurvivalData(player)
    
    -- Envoyer une notification
    self:SendNotification(player, "Vous avez bu " .. drinkItem.name, "success")
    
    -- Jouer l'animation de boire (côté client)
    self:PlayClientAnimation(player, "drink")
    
    return true
end

-- Commencer à dormir
function SurvivalService:StartSleeping(player, structureId)
    if not player or not player:IsA("Player") then 
        return false 
    end
    
    local userId = player.UserId
    local data = self.playerSurvivalData[userId]
    
    if not data then 
        return false 
    end
    
    -- Vérifier si le joueur est déjà en train de dormir
    if data.isSleeping then 
        return true 
    end
    
    -- Marquer comme dormant
    data.isSleeping = true
    
    -- Si un structureId est fourni, stocker l'emplacement de sommeil
    if structureId then
        local sleepingLocation = nil
        
        -- Déterminer le type de lit/endroit où le joueur dort
        if workspace:FindFirstChild("Structures") then
            local structure = workspace.Structures:FindFirstChild(structureId)
            if structure then
                sleepingLocation = structure:GetAttribute("BuildingType")
            end
        end
        
        data.sleepingLocation = sleepingLocation
    else
        data.sleepingLocation = nil -- Dormir sur le sol
    end
    
    -- Obtenir le personnage
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        -- Assis = état de sommeil basique
        character.Humanoid.Sit = true
        
        -- Positionner le joueur en position couchée
        -- Ceci est mieux réalisé côté client avec une animation
        self:PlayClientAnimation(player, "sleep")
    end
    
    -- Envoyer une notification
    self:SendNotification(player, "Vous vous êtes endormi", "info")
    
    -- Faire en sorte que le joueur ne puisse pas se déplacer
    -- Ceci est également mieux géré côté client
    if self.remoteEvents.Sleep then
        self.remoteEvents.Sleep:FireClient(player, true)
    end
    
    -- Mettre à jour les données côté client
    self:UpdateClientSurvivalData(player)
    
    return true
end

-- Arrêter de dormir
function SurvivalService:StopSleeping(player)
    if not player or not player:IsA("Player") then 
        return false 
    end
    
    local userId = player.UserId
    local data = self.playerSurvivalData[userId]
    
    if not data then 
        return false 
    end
    
    -- Vérifier si le joueur est en train de dormir
    if not data.isSleeping then 
        return true 
    end
    
    -- Marquer comme ne dormant plus
    data.isSleeping = false
    data.sleepingLocation = nil
    
    -- Obtenir le personnage
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        -- Annuler l'état assis
        character.Humanoid.Sit = false
        
        -- Arrêter l'animation de sommeil
        self:PlayClientAnimation(player, "wake_up")
    end
    
    -- Envoyer une notification
    self:SendNotification(player, "Vous vous êtes réveillé", "info")
    
    -- Permettre au joueur de se déplacer à nouveau
    if self.remoteEvents.Sleep then
        self.remoteEvents.Sleep:FireClient(player, false)
    end
    
    -- Mettre à jour les données côté client
    self:UpdateClientSurvivalData(player)
    
    return true
end

-- Mettre à jour les données de survie pour le client
function SurvivalService:UpdateClientSurvivalData(player)
    if not player or not player:IsA("Player") then 
        return 
    end
    
    local userId = player.UserId
    local data = self.playerSurvivalData[userId]
    
    if not data then 
        return 
    end
    
    -- Préparer les données à envoyer
    local statsData = {
        hunger = data.hunger,
        thirst = data.thirst,
        energy = data.energy,
        temperature = data.temperature,
        isSleeping = data.isSleeping,
        sleepingLocation = data.sleepingLocation
    }
    
    -- Envoyer les données au client
    if self.remoteEvents.UpdateStats then
        self.remoteEvents.UpdateStats:FireClient(player, statsData)
    end
end

-- Gérer la déconnexion d'un joueur
function SurvivalService:HandlePlayerRemoving(player)
    if not player or not player:IsA("Player") then 
        return 
    end
    
    local userId = player.UserId
    
    -- Sauvegarder l'état et libérer les ressources
    if self.playerSurvivalData[userId] then
        -- Ici, on pourrait implémenter une sauvegarde dans DataStore
        -- pour le moment, on se contente de nettoyer la mémoire
        self.playerSurvivalData[userId] = nil
        self.lastNotificationTimes[userId] = nil
    end
    
    print("SurvivalService: Données de survie nettoyées pour " .. player.Name)
end

-- Gérer la mort d'un joueur
function SurvivalService:HandlePlayerDeath(player, cause)
    if not player or not player:IsA("Player") then 
        return 
    end
    
    -- Cette fonction est un complément à PlayerService:HandlePlayerDeath
    -- Elle effectue les opérations spécifiques à la survie lors d'une mort
    
    local userId = player.UserId
    
    -- Réinitialiser certaines données de survie
    -- Lors de la réincarnation, le joueur aura des valeurs plus favorables
    if self.playerSurvivalData[userId] then
        -- Arrêter de dormir si le joueur était endormi
        if self.playerSurvivalData[userId].isSleeping then
            self.playerSurvivalData[userId].isSleeping = false
            self.playerSurvivalData[userId].sleepingLocation = nil
        end
    end
    
    -- Note: La réinitialisation complète des données se fait dans PlayerService
    -- après la réincarnation du joueur
end

-- Réinitialiser les données de survie (après réincarnation)
function SurvivalService:ResetPlayerSurvival(player)
    if not player or not player:IsA("Player") then 
        return 
    end
    
    local userId = player.UserId
    
    -- Créer des données fraîches avec des valeurs de départ favorables
    self.playerSurvivalData[userId] = {
        hunger = self.maxHunger * 0.7,      -- 70% de nourriture
        thirst = self.maxThirst * 0.8,      -- 80% d'eau
        temperature = 50,                   -- Température idéale
        energy = self.maxEnergy * 0.9,      -- 90% d'énergie
        isSleeping = false,                 -- Pas endormi au départ
        lastUpdateTime = os.time(),         -- Nouvelle référence temporelle
        effects = {},                       -- Aucun effet actif
        sleepingLocation = nil              -- Pas d'emplacement de sommeil
    }
    
    -- Réinitialiser les timers de notification
    self.lastNotificationTimes[userId] = {
        hunger = 0,
        thirst = 0,
        energy = 0,
        temperature = 0
    }
    
    -- Mettre à jour le client
    self:UpdateClientSurvivalData(player)
    
    print("SurvivalService: Données de survie réinitialisées pour " .. player.Name)
end

-- Envoyer une notification au joueur
function SurvivalService:SendNotification(player, message, messageType)
    if not player or not player:IsA("Player") then 
        return 
    end
    
    if self.remoteEvents.Notification then
        self.remoteEvents.Notification:FireClient(player, message, messageType or "info")
    else
        -- Fallback si l'événement n'est pas disponible
        print("Notification pour " .. player.Name .. ": " .. message)
    end
end

-- Jouer une animation côté client
function SurvivalService:PlayClientAnimation(player, animationType)
    if not player or not player:IsA("Player") then 
        return 
    end
    
    if self.remoteEvents.PlayAnimation then
        self.remoteEvents.PlayAnimation:FireClient(player, animationType)
    end
end

-- Démarrer le service
function SurvivalService:Start(services)
    print("SurvivalService: Démarrage...")
    
    -- Récupérer les références aux autres services
    self.playerService = services.PlayerService
    self.inventoryService = services.InventoryService
    
    -- Vérifier si les services requis sont disponibles
    if not self.playerService then
        warn("SurvivalService: PlayerService non disponible - certaines fonctionnalités seront limitées")
    end
    
    if not self.inventoryService then
        warn("SurvivalService: InventoryService non disponible - certaines fonctionnalités seront limitées")
    end
    
    -- Obtenir les références aux RemoteEvents
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if Events then
        self.remoteEvents = {
            UpdateStats = Events:FindFirstChild("UpdateStats"),
            Notification = Events:FindFirstChild("Notification"),
            PlayAnimation = Events:FindFirstChild("PlayAnimation"),
            Sleep = Events:FindFirstChild("Sleep")
        }
        
        -- Vérifier si tous les RemoteEvents requis sont disponibles
        local missingEvents = {}
        if not self.remoteEvents.UpdateStats then table.insert(missingEvents, "UpdateStats") end
        if not self.remoteEvents.Notification then table.insert(missingEvents, "Notification") end
        if not self.remoteEvents.PlayAnimation then table.insert(missingEvents, "PlayAnimation") end
        if not self.remoteEvents.Sleep then table.insert(missingEvents, "Sleep") end
        
        if #missingEvents > 0 then
            warn("SurvivalService: RemoteEvents manquants - " .. table.concat(missingEvents, ", "))
        end
    else
        warn("SurvivalService: Dossier Events non trouvé dans ReplicatedStorage")
    end
    
    -- Initialiser les joueurs actuels
    for _, player in pairs(Players:GetPlayers()) do
        self:InitializePlayerSurvival(player)
    end
    
    -- Gérer les nouveaux joueurs
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerSurvival(player)
    end)
    
    -- Gérer les joueurs qui quittent
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
    
    -- Démarrer la boucle de mise à jour
    spawn(function()
        while true do
            -- Utilisation de wait() avec actualisation du délai pour éviter les problèmes
            -- si le serveur est surchargé
            local startTime = tick()
            
            -- Mettre à jour les données de survie pour tous les joueurs
            for _, player in pairs(Players:GetPlayers()) do
                if self.playerSurvivalData[player.UserId] then
                    pcall(function()
                        self:UpdateSurvivalData(player)
                    end)
                end
            end
            
            -- Calculer le temps restant pour atteindre self.updateInterval
            local elapsed = tick() - startTime
            local waitTime = math.max(0.1, self.updateInterval - elapsed)
            wait(waitTime)
        end
    end)
    
    print("SurvivalService: Démarré avec succès")
    return self
end

return SurvivalService
