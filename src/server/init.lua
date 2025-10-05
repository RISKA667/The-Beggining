-- src/server/init.lua
-- Point d'entrée principal du serveur

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Server = ServerScriptService:WaitForChild("Server")
local Services = Server:WaitForChild("services")

-- Initialiser les RemoteEvents avant de démarrer les services
local function InitializeRemoteEvents()
    print("Serveur: Initialisation des RemoteEvents...")
    
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if not Events then
        Events = Instance.new("Folder")
        Events.Name = "Events"
        Events.Parent = ReplicatedStorage
    end
    
    -- Liste de tous les RemoteEvents nécessaires
    local requiredEvents = {
        -- Inventaire
        "UpdateInventory",
        "InventoryAction",
        
        -- Survie
        "UpdateStats",
        "Sleep",
        
        -- Artisanat
        "UpdateRecipes",
        "CraftComplete",
        "CraftRequest",
        
        -- Tribus
        "TribeAction",
        "TribeUpdate",
        
        -- Temps
        "TimeUpdate",
        
        -- Ressources
        "ResourceHarvest",
        "ResourceGenerate",
        
        -- Construction
        "BuildingStart",
        "BuildingPlacement",
        "BuildingAction",
        
        -- Combat
        "AttackPlayer",
        "TakeDamage",
        "UpdateHealth",
        "EquipWeapon",
        
        -- Farming
        "PlantSeed",
        "HarvestCrop",
        "UpdateCrop",
        
        -- Général
        "Notification",
        "PlayerAction",
        "PlayAnimation",
        "UpdatePlayerData"
    }
    
    -- Créer les RemoteEvents
    for _, eventName in ipairs(requiredEvents) do
        if not Events:FindFirstChild(eventName) then
            local remoteEvent = Instance.new("RemoteEvent")
            remoteEvent.Name = eventName
            remoteEvent.Parent = Events
            print("  ✓ RemoteEvent créé: " .. eventName)
        end
    end
    
    -- Liste des RemoteFunctions nécessaires
    local requiredFunctions = {
        "GetPlayerData",
        "GetInventory",
        "GetTribeData",
        "CanCraft"
    }
    
    -- Créer les RemoteFunctions
    for _, functionName in ipairs(requiredFunctions) do
        if not Events:FindFirstChild(functionName) then
            local remoteFunction = Instance.new("RemoteFunction")
            remoteFunction.Name = functionName
            remoteFunction.Parent = Events
            print("  ✓ RemoteFunction créée: " .. functionName)
        end
    end
    
    print("Serveur: RemoteEvents initialisés avec succès")
end

-- Initialiser les services
local function InitializeServices()
    print("Serveur: Initialisation des services...")
    
    -- Charger tous les services
    local PlayerService = require(Services.PlayerService).new()
    local InventoryService = require(Services.InventoryService).new()
    local SurvivalService = require(Services.SurvivalService).new()
    local CraftingService = require(Services.CraftingService).new()
    local ResourceService = require(Services.ResourceService).new()
    local BuildingService = require(Services.BuildingService).new()
    local TimeService = require(Services.TimeService).new()
    local TribeService = require(Services.TribeService).new()
    local CombatService = require(Services.CombatService).new()
    local FarmingService = require(Services.FarmingService).new()
    
    -- Créer la table de services
    local services = {
        PlayerService = PlayerService,
        InventoryService = InventoryService,
        SurvivalService = SurvivalService,
        CraftingService = CraftingService,
        ResourceService = ResourceService,
        BuildingService = BuildingService,
        TimeService = TimeService,
        TribeService = TribeService,
        CombatService = CombatService,
        FarmingService = FarmingService
    }
    
    -- Démarrer chaque service (en passant la table de services pour les dépendances)
    for name, service in pairs(services) do
        if service.Start then
            local success, error = pcall(function()
                service:Start(services)
            end)
            
            if success then
                print("  ✓ Service démarré: " .. name)
            else
                warn("  ✗ Erreur lors du démarrage de " .. name .. ": " .. tostring(error))
            end
        end
    end
    
    print("Serveur: Tous les services sont démarrés")
    return services
end

-- Point d'entrée principal
print("========================================")
print("  THE BEGINNING - Serveur")
print("========================================")

-- Initialiser les RemoteEvents
InitializeRemoteEvents()

-- Initialiser les services
local services = InitializeServices()

print("========================================")
print("  Serveur initialisé avec succès!")
print("========================================")

return services
