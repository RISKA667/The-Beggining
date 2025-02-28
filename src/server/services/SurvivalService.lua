-- src/server/services/SurvivalService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
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
    
    -- Constantes
    self.maxHunger = GameSettings.Survival.maxHunger or 100
    self.maxThirst = GameSettings.Survival.maxThirst or 100
    self.maxTemperature = 100
    self.maxEnergy = GameSettings.Survival.maxEnergy or 100
    
    -- Taux de décroissance (par seconde)
    self.hungerDecayRate = GameSettings.Survival.hungerDecayRate or 0.05
    self.thirstDecayRate = GameSettings.Survival.thirstDecayRate or 0.08
    self.energyDecayRate = GameSettings.Survival.energyDecayRate or 0.03
    
    -- Seuils critiques
    self.criticalHunger = GameSettings.Survival.criticalHungerThreshold or 15
    self.criticalThirst = GameSettings.Survival.criticalThirstThreshold or 10
    self.criticalEnergy = GameSettings.Survival.criticalEnergyThreshold or 10
    self.criticalColdTemperature = GameSettings.Survival.criticalColdThreshold or 20
    self.criticalHotTemperature = GameSettings.Survival.criticalHeatThreshold or 80
    
    -- Timers de mise à jour
    self.updateInterval = 1  -- Intervalle en secondes
    
    -- Références aux services (seront injectés dans Start)
    self.playerService = nil
    self.inventoryService = nil
    
    -- Events RemoteEvent
    self.remoteEvents = {}
    
    return self
end

-- Initialiser les données de survie pour un joueur
function SurvivalService:InitializePlayerSurvival(player)
    if self.playerSurvivalData[player.UserId] then return end
    
    -- Créer un nouvel ensemble de données de survie
    self.playerSurvivalData[player.UserId] = {
        hunger = self.maxHunger,       -- 100 = rassasié, 0 = affamé
        thirst = self.maxThirst,       -- 100 = hydraté, 0 = assoiffé
        temperature = 50,              -- 0 = gelé, 100 = brûlant, 50 = idéal
        energy = self.maxEnergy,       -- 100 = plein d'énergie, 0 = épuisé
        isSleeping = false,            -- Si le joueur est en train de dormir
        lastUpdateTime = os.time(),    -- Dernière mise à jour des stats
        effects = {}                   -- Effets temporaires (maladies, etc.)
    }
    
    -- Mettre à jour le client avec les données de survie
    self:UpdateClientSurvivalData(player)
    
    print("SurvivalService: Données de survie initialisées pour " .. player.Name)
end

-- Mettre à jour périodiquement les données de survie
function SurvivalService:UpdateSurvivalData(player)
    local data = self.playerSurvivalData[player.UserId]
    if not data then return end
    
    local currentTime = os.time()
    local timeDelta = currentTime - data.lastUpdateTime
    
    -- Mettre à jour la faim
    data.hunger = math.max(0, data.hunger - (self.hungerDecayRate * timeDelta))
    
    -- Mettre à jour la soif
    data.thirst = math.max(0, data.thirst - (self.thirstDecayRate * timeDelta))
    
    -- Mettre à jour l'énergie (diminue pendant l'éveil, récupère pendant le sommeil)
    if not data.isSleeping then
        data.energy = math.max(0, data.energy - (self.energyDecayRate * timeDelta))
    else
        data.energy = math.min(self.maxEnergy, data.energy + (GameSettings.Survival.energyRecoveryRate * timeDelta))
        
        -- Si l'énergie est complètement récupérée, réveiller automatiquement le joueur
        if data.energy >= self.maxEnergy then
            self:StopSleeping(player)
            
            -- Notification de réveil
            self:SendNotification(player, "Vous vous êtes réveillé, complètement reposé!", "info")
        end
    end
    
    -- Mettre à jour la température en fonction de l'environnement
    local newTemperature = self:CalculateEnvironmentTemperature(player)
    data.temperature = data.temperature + (newTemperature - data.temperature) * 0.1 -- Changement progressif
    
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
    local data = self.playerSurvivalData[player.UserId]
    if not data then return end
    
    local character = player.Character
    if not character or not character:FindFirstChild("Humanoid") then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Vérifier la faim
    if data.hunger <= 0 then
        -- Le joueur meurt de faim
        humanoid.Health = 0
        if self.playerService then
            self.playerService:HandlePlayerDeath(player, "hunger")
        end
        return
    elseif data.hunger <= self.criticalHunger then
        -- Faim critique - appliquer des effets (ralentissement, etc.)
        humanoid.WalkSpeed = humanoid.WalkSpeed * 0.7
        
        -- Envoyer une notification au joueur
        if math.random(1, 60) == 1 then -- Une fois par minute en moyenne
            self:SendNotification(player, "Vous êtes affamé! Trouvez de la nourriture rapidement.", "warning")
        end
    end
    
    -- Vérifier la soif
    if data.thirst <= 0 then
        -- Le joueur meurt de soif
        humanoid.Health = 0
        if self.playerService then
            self.playerService:HandlePlayerDeath(player, "thirst")
        end
        return
    elseif data.thirst <= self.criticalThirst then
        -- Soif critique - appliquer des effets
        humanoid.WalkSpeed = humanoid.WalkSpeed * 0.7
        
        -- Envoyer une notification au joueur
        if math.random(1, 60) == 1 then -- Une fois par minute en moyenne
            self:SendNotification(player, "Vous êtes déshydraté! Trouvez de l'eau rapidement.", "warning")
        end
    end
    
    -- Vérifier l'énergie
    if data.energy <= self.criticalEnergy then
        -- Fatigue critique - appliquer des effets
        humanoid.WalkSpeed = humanoid.WalkSpeed * 0.8
        
        -- Envoyer une notification au joueur
        if math.random(1, 60) == 1 then -- Une fois par minute en moyenne
            self:SendNotification(player, "Vous êtes épuisé! Trouvez un endroit pour dormir.", "warning")
        end
    end
    
    -- Vérifier la température
    if data.temperature <= self.criticalColdTemperature then
        -- Trop froid - appliquer des dégâts progressifs
        humanoid.Health = humanoid.Health - GameSettings.Survival.temperatureDamageAmount
        
        -- Envoyer une notification au joueur
        if math.random(1, 60) == 1 then -- Une fois par minute en moyenne
            self:SendNotification(player, "Vous avez froid! Cherchez un feu ou un abri.", "warning")
        end
    elseif data.temperature >= self.criticalHotTemperature then
        -- Trop chaud - appliquer des dégâts progressifs
        humanoid.Health = humanoid.Health - GameSettings.Survival.temperatureDamageAmount
        
        -- Envoyer une notification au joueur
        if math.random(1, 60) == 1 then -- Une fois par minute en moyenne
            self:SendNotification(player, "Vous avez trop chaud! Trouvez de l'ombre.", "warning")
        end
    end
    
    -- Vérifier si le joueur est mort d'une cause environnementale
    if humanoid.Health <= 0 then
        if data.temperature <= self.criticalColdTemperature then
            if self.playerService then
                self.playerService:HandlePlayerDeath(player, "cold")
            end
        elseif data.temperature >= self.criticalHotTemperature then
            if self.playerService then
                self.playerService:HandlePlayerDeath(player, "heat")
            end
        end
    end
end

-- Manger un aliment
function SurvivalService:ConsumeFood(player, foodItemId)
    local data = self.playerSurvivalData[player.UserId]
    if not data then return false end
    
    -- Vérifier que le joueur a l'aliment dans son inventaire
    if self.inventoryService and not self.inventoryService:HasItemInInventory(player, foodItemId, 1) then
        self:SendNotification(player, "Vous n'avez pas cet aliment dans votre inventaire", "error")
        return false
    end
    
    -- Récupérer les valeurs nutritives de l'aliment
    local ItemTypes = require(Shared.constants.ItemTypes)
    local foodItem = ItemTypes[foodItemId]
    
    if not foodItem then return false end
    
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
    local data = self.playerSurvivalData[player.UserId]
    if not data then return false end
    
    -- Vérifier que le joueur a la boisson dans son inventaire
    if self.inventoryService and not self.inventoryService:HasItemInInventory(player, drinkItemId, 1) then
        self:SendNotification(player, "Vous n'avez pas cette boisson dans votre inventaire", "error")
        return false
    end
    
    -- Récupérer les valeurs de la boisson
    local ItemTypes = require(Shared.constants.ItemTypes)
    local drinkItem = ItemTypes[drinkItemId]
    
    if not drinkItem then return false end
    
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
function SurvivalService:StartSleeping(player)
    local data = self.playerSurvivalData[player.UserId]
    if not data then return false end
    
    -- Vérifier si le joueur est déjà en train de dormir
    if data.isSleeping then return true end
    
    -- Marquer comme dormant
    data.isSleeping = true
    
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
    
    return true
end

-- Arrêter de dormir
function SurvivalService:StopSleeping(player)
    local data = self.playerSurvivalData[player.UserId]
    if not data then return false end
    
    -- Vérifier si le joueur est en train de dormir
    if not data.isSleeping then return true end
    
    -- Marquer comme ne dormant plus
    data.isSleeping = false
    
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
    
    return true
end

-- Mettre à jour les données de survie pour le client
function SurvivalService:UpdateClientSurvivalData(player)
    local data = self.playerSurvivalData[player.UserId]
    if not data then return end
    
    -- Préparer les données à envoyer
    local statsData = {
        hunger = data.hunger,
        thirst = data.thirst,
        energy = data.energy,
        temperature = data.temperature,
        isSleeping = data.isSleeping
    }
    
    -- Envoyer les données au client
    if self.remoteEvents.UpdateStats then
        self.remoteEvents.UpdateStats:FireClient(player, statsData)
    end
end

-- Gérer la déconnexion d'un joueur
function SurvivalService:HandlePlayerRemoving(player)
    -- Sauvegarder l'état et libérer les ressources
    self.playerSurvivalData[player.UserId] = nil
    
    print("SurvivalService: Données de survie nettoyées pour " .. player.Name)
end

-- Calculer la température en fonction de l'environnement
function SurvivalService:CalculateEnvironmentTemperature(player)
    local character = player.Character
    if not character then return 50 end -- Température par défaut
    
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
    -- Dans une implémentation complète, vérifier les RayOcclusion ou les Zones
    -- Pour l'instant, utilisons une approximation simple
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    
    local position = character.HumanoidRootPart.Position
    
    -- Lancer un rayon vers le haut pour vérifier s'il y a un toit
    local rayOrigin = position
    local rayDirection = Vector3.new(0, 20, 0) -- Vers le haut
    
    local ray = Ray.new(rayOrigin, rayDirection)
    local hitPart = workspace:FindPartOnRay(ray, character)
    
    -- Si un toit est détecté, le joueur est probablement à l'intérieur
    return hitPart ~= nil
end

-- Vérifier si le joueur est près d'une source de chaleur
function SurvivalService:IsNearHeatSource(player)
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false, 0 end
    
    local position = character.HumanoidRootPart.Position
    
    -- Obtenir toutes les sources de chaleur (feux de camp, fours, etc.)
    local heatSources = workspace:FindFirstChild("Structures") and workspace.Structures:GetChildren() or {}
    
    for _, structure in ipairs(heatSources) do
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
    -- Pour l'instant, utilisons l'éclairage intégré
    local currentTime = game:GetService("Lighting").ClockTime
    
    -- Considérer la nuit de 19h à 6h
    return currentTime >= 19 or currentTime < 6
end

-- Obtenir les modificateurs de température des équipements
function SurvivalService:GetTemperatureModifierFromEquipment(player)
    local modifier = 0
    
    -- Vérifier les vêtements équipés
    if self.inventoryService then
        local inventory = self.inventoryService.playerInventories[player.UserId]
        if inventory and inventory.equipped then
            local ItemTypes = require(Shared.constants.ItemTypes)
            
            -- Vérifier chaque type d'équipement
            for slot, itemId in pairs(inventory.equipped) do
                local item = ItemTypes[itemId]
                if item and item.temperatureModifier then
                    modifier = modifier + item.temperatureModifier
                end
            end
        end
    end
    
    return modifier
end

-- Appliquer les effets de l'environnement sur le joueur
function SurvivalService:ApplyEnvironmentalEffects(player)
    -- Fonction pour gérer les effets d'environnement supplémentaires
    -- Par exemple: pluie, tempêtes, désert chaud, etc.
    
    -- Pour l'instant, simplement mettre à jour la température
    local data = self.playerSurvivalData[player.UserId]
    if not data then return end
    
    local environmentTemperature = self:CalculateEnvironmentTemperature(player)
    data.temperature = data.temperature + (environmentTemperature - data.temperature) * 0.1
end

-- Envoyer une notification au joueur
function SurvivalService:SendNotification(player, message, messageType)
    if self.remoteEvents.Notification then
        self.remoteEvents.Notification:FireClient(player, message, messageType or "info")
    else
        -- Fallback si l'événement n'est pas disponible
        print("Notification pour " .. player.Name .. ": " .. message)
    end
end

-- Jouer une animation côté client
function SurvivalService:PlayClientAnimation(player, animationType)
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
    
    -- Obtenir les références aux RemoteEvents
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if Events then
        self.remoteEvents = {
            UpdateStats = Events:FindFirstChild("UpdateStats"),
            Notification = Events:FindFirstChild("Notification"),
            PlayAnimation = Events:FindFirstChild("PlayAnimation"),
            Sleep = Events:FindFirstChild("Sleep")
        }
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
    
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
    
    -- Démarrer la boucle de mise à jour
    spawn(function()
        while true do
            wait(self.updateInterval)
            
            -- Mettre à jour les données de survie pour tous les joueurs
            for _, player in pairs(Players:GetPlayers()) do
                if self.playerSurvivalData[player.UserId] then
                    self:UpdateSurvivalData(player)
                end
            end
        end
    end)
    
    print("SurvivalService: Démarré avec succès")
    return self
end

return SurvivalService
