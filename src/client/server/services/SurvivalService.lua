-- src/server/services/SurvivalService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared.constants.GameSettings)

-- Services
local Server = ServerScriptService:WaitForChild("Server")
local Services = Server:WaitForChild("services")
local PlayerService -- Sera initialisé dans Start()

local SurvivalService = {}
SurvivalService.__index = SurvivalService

-- Créer une instance du service
function SurvivalService.new()
    local self = setmetatable({}, SurvivalService)
    
    -- Données de survie des joueurs
    self.playerSurvivalData = {}
    
    -- Constantes
    self.maxHunger = 100
    self.maxThirst = 100
    self.maxTemperature = 100
    self.maxEnergy = 100
    
    -- Taux de décroissance (par seconde)
    self.hungerDecayRate = 0.05
    self.thirstDecayRate = 0.08
    self.energyDecayRate = 0.03
    
    -- Seuils critiques
    self.criticalHunger = 15
    self.criticalThirst = 10
    self.criticalEnergy = 10
    self.criticalColdTemperature = 20
    self.criticalHotTemperature = 80
    
    -- Timers de mise à jour
    self.updateInterval = 1  -- Intervalle en secondes
    
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
        lastUpdateTime = os.time()
    }
    
    -- Mettre à jour le client avec les données de survie
    self:UpdateClientSurvivalData(player)
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
    
    -- Mettre à jour l'énergie (diminue pendant la journée, récupère pendant le sommeil)
    if not data.isSleeping then
        data.energy = math.max(0, data.energy - (self.energyDecayRate * timeDelta))
    else
        data.energy = math.min(self.maxEnergy, data.energy + (0.1 * timeDelta))
    end
    
    -- Mettre à jour la température en fonction de l'environnement (à implémenter)
    -- data.temperature = self:CalculateEnvironmentTemperature(player)
    
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
    
    -- Vérifier la faim
    if data.hunger <= 0 then
        -- Le joueur meurt de faim
        humanoid.Health = 0
        PlayerService:HandlePlayerDeath(player, "hunger")
        return
    elseif data.hunger <= self.criticalHunger then
        -- Faim critique - appliquer des effets (ralentissement, etc.)
        humanoid.WalkSpeed = humanoid.WalkSpeed * 0.7
    end
    
    -- Vérifier la soif
    if data.thirst <= 0 then
        -- Le joueur meurt de soif
        humanoid.Health = 0
        PlayerService:HandlePlayerDeath(player, "thirst")
        return
    elseif data.thirst <= self.criticalThirst then
        -- Soif critique - appliquer des effets
        humanoid.WalkSpeed = humanoid.WalkSpeed * 0.7
    end
    
    -- Vérifier l'énergie
    if data.energy <= self.criticalEnergy then
        -- Fatigue critique - appliquer des effets
        humanoid.WalkSpeed = humanoid.WalkSpeed * 0.8
    end
    
    -- Vérifier la température
    if data.temperature <= self.criticalColdTemperature then
        -- Trop froid - appliquer des dégâts progressifs
        humanoid.Health = humanoid.Health - 1
    elseif data.temperature >= self.criticalHotTemperature then
        -- Trop chaud - appliquer des dégâts progressifs
        humanoid.Health = humanoid.Health - 1
    end
end

-- Manger un aliment
function SurvivalService:ConsumeFood(player, foodItemId)
    local data = self.playerSurvivalData[player.UserId]
    if not data then return false end
    
    -- Dans une implémentation complète, récupérer les valeurs de l'aliment depuis ItemTypes
    local foodValue = 25  -- Valeur par défaut
    
    -- Augmenter la faim
    data.hunger = math.min(self.maxHunger, data.hunger + foodValue)
    
    -- Mettre à jour le client
    self:UpdateClientSurvivalData(player)
    return true
end

-- Boire
function SurvivalService:ConsumeDrink(player, drinkItemId)
    local data = self.playerSurvivalData[player.UserId]
    if not data then return false end
    
    -- Dans une implémentation complète, récupérer les valeurs de la boisson depuis ItemTypes
    local drinkValue = 30  -- Valeur par défaut
    
    -- Augmenter la soif
    data.thirst = math.min(self.maxThirst, data.thirst + drinkValue)
    
    -- Mettre à jour le client
    self:UpdateClientSurvivalData(player)
    return true
end

-- Commencer à dormir
function SurvivalService:StartSleeping(player)
    local data = self.playerSurvivalData[player.UserId]
    if not data then return false end
    
    data.isSleeping = true
    
    -- Animation de sommeil du personnage (à implémenter)
    
    return true
end

-- Arrêter de dormir
function SurvivalService:StopSleeping(player)
    local data = self.playerSurvivalData[player.UserId]
    if not data then return false end
    
    data.isSleeping = false
    
    -- Arrêter l'animation de sommeil (à implémenter)
    
    return true
end

-- Mettre à jour les données de survie pour le client
function SurvivalService:UpdateClientSurvivalData(player)
    -- Dans une implémentation réelle, utilisez RemoteEvent pour synchroniser avec le client
    local data = self.playerSurvivalData[player.UserId]
    if not data then return end
    
    print("Mise à jour des données de survie pour " .. player.Name .. ":")
    print("  Faim: " .. data.hunger)
    print("  Soif: " .. data.thirst)
    print("  Énergie: " .. data.energy)
    print("  Température: " .. data.temperature)
end

-- Gérer la déconnexion d'un joueur
function SurvivalService:HandlePlayerRemoving(player)
    self.playerSurvivalData[player.UserId] = nil
end

function SurvivalService:Start(services)
    -- Récupérer les références aux autres services
    PlayerService = services.PlayerService
    
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
end

-- Calculer la température en fonction de l'environnement
function SurvivalService:CalculateEnvironmentTemperature(player)
    local character = player.Character
    if not character then return 50 end -- Température par défaut
    
    local position = character:GetPrimaryPartCFrame().Position
    
    -- Vérifier si le joueur est à l'intérieur d'un bâtiment
    local isIndoors = false -- À implémenter avec le système de construction
    
    -- Vérifier la proximité avec des sources de chaleur (feu, forge, etc.)
    local nearHeatSource = false -- À implémenter
    local heatSourceIntensity = 0
    
    -- Température de base (peut varier en fonction du temps, du biome, etc.)
    local baseTemperature = 45
    
    -- Adapter la température en fonction de l'environnement
    if isIndoors then
        baseTemperature = baseTemperature + 10 -- Plus chaud à l'intérieur
    end
    
    if nearHeatSource then
        baseTemperature = baseTemperature + heatSourceIntensity
    end
    
    -- Limiter la température entre 0 et 100
    return math.clamp(baseTemperature, 0, 100)
end

-- Gérer les effets de l'environnement sur la température du joueur
function SurvivalService:ApplyEnvironmentalEffects(player)
    local data = self.playerSurvivalData[player.UserId]
    if not data then return end
    
    -- Obtenir la température environnementale
    local envTemperature = self:CalculateEnvironmentTemperature(player)
    
    -- Adapter progressivement la température du joueur vers celle de l'environnement
    local tempDifference = envTemperature - data.temperature
    data.temperature = data.temperature + (tempDifference * 0.1) -- Ajustement progressif
    
    -- Vérifier l'équipement pour la protection contre le froid/chaud
    local inventory = game:GetService("ServerScriptService").Server.services.InventoryService.playerInventories[player.UserId]
    if inventory and inventory.equipped then
        -- Adapter la température en fonction des vêtements (à implémenter)
        -- Exemple: manteau de fourrure = +15 résistance au froid
    end
end

return SurvivalService