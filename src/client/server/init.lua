-- src/server/init.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Importer les services
local services = {}
services.PlayerService = require(script.services.PlayerService)
services.InventoryService = require(script.services.InventoryService)
services.CraftingService = require(script.services.CraftingService)
services.ResourceService = require(script.services.ResourceService)
services.SurvivalService = require(script.services.SurvivalService)
services.TimeService = require(script.services.TimeService)
services.BuildingService = require(script.services.BuildingService)

local Server = {}

-- Initialiser les services
function Server:InitializeServices()
    print("Server: Initialisation des services...")
    
    -- Créer les instances de service
    self.services = {}
    self.services.TimeService = services.TimeService.new()
    self.services.PlayerService = services.PlayerService.new()
    self.services.InventoryService = services.InventoryService.new()
    self.services.CraftingService = services.CraftingService.new()
    self.services.ResourceService = services.ResourceService.new()
    self.services.SurvivalService = services.SurvivalService.new()
    self.services.BuildingService = services.BuildingService.new()
    
    -- Démarrer les services dans un ordre spécifique
    -- Certains services peuvent dépendre d'autres
    self.services.TimeService:Start()
    self.services.ResourceService:Start()
    self.services.PlayerService:Start()
    self.services.InventoryService:Start()
    self.services.CraftingService:Start(self.services)
    self.services.SurvivalService:Start(self.services)
    self.services.BuildingService:Start(self.services)
    
    print("Server: Services initialisés avec succès")
end

-- Configurer les événements de communication client-serveur
function Server:SetupRemoteEvents()
    print("Server: Configuration des événements RemoteEvent...")
    
    -- Créer un dossier pour les événements
    local events = Instance.new("Folder")
    events.Name = "Events"
    events.Parent = ReplicatedStorage
    
    -- Créer les RemoteEvents nécessaires
    
    -- Mise à jour des statistiques
    local updateStatsEvent = Instance.new("RemoteEvent")
    updateStatsEvent.Name = "UpdateStats"
    updateStatsEvent.Parent = events
    
    -- Mise à jour de l'inventaire
    local updateInventoryEvent = Instance.new("RemoteEvent")
    updateInventoryEvent.Name = "UpdateInventory"
    updateInventoryEvent.Parent = events
    
    -- Mise à jour des recettes
    local updateRecipesEvent = Instance.new("RemoteEvent")
    updateRecipesEvent.Name = "UpdateRecipes"
    updateRecipesEvent.Parent = events
    
    -- Actions du joueur
    local playerActionEvent = Instance.new("RemoteEvent")
    playerActionEvent.Name = "PlayerAction"
    playerActionEvent.Parent = events
    
    -- Connexion pour les actions des joueurs
    playerActionEvent.OnServerEvent:Connect(function(player, actionType, ...)
        self:HandlePlayerAction(player, actionType, ...)
    end)
    
    print("Server: RemoteEvents configurés avec succès")
end

-- Gérer les actions des joueurs
function Server:HandlePlayerAction(player, actionType, ...)
    local args = {...}
    
    if actionType == "craft" then
        -- Fabrication d'objet
        local recipeId = args[1]
        local success, message = self.services.CraftingService:CraftItem(player, recipeId)
        
        -- Informer le client du résultat
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events and success ~= nil then
            local notificationEvent = events:FindFirstChild("Notification")
            if notificationEvent then
                notificationEvent:FireClient(player, message, success and "success" or "error")
            end
        end
    elseif actionType == "use_item" then
        -- Utilisation d'objet
        local slotNumber = args[1]
        local itemId = args[2]
        
        -- Déterminer le type d'objet et l'action appropriée
        local itemType = require(ReplicatedStorage.Shared.constants.ItemTypes)[itemId]
        
        if not itemType then return end
        
        if itemType.category == "food" then
            self.services.SurvivalService:ConsumeFood(player, itemId)
        elseif itemType.category == "drink" then
            self.services.SurvivalService:ConsumeDrink(player, itemId)
        elseif itemType.category == "building" or itemType.category == "furniture" then
            self.services.BuildingService:StartPlacement(player, itemId, slotNumber)
        end
    elseif actionType == "place_building" then
        -- Placer un bâtiment ou un meuble
        local itemId = args[1]
        local position = args[2]
        local rotation = args[3]
        
        self.services.BuildingService:PlaceBuilding(player, itemId, position, rotation)
    elseif actionType == "sleep" then
        -- Commencer à dormir
        self.services.SurvivalService:StartSleeping(player)
    elseif actionType == "wake_up" then
        -- Arrêter de dormir
        self.services.SurvivalService:StopSleeping(player)
    elseif actionType == "gather_resource" then
        -- Récolter une ressource
        local resourceId = args[1]
        local resourceInstance = args[2]
        
        self.services.ResourceService:GatherResource(player, resourceId, resourceInstance)
    end
end

-- Démarrer le serveur
function Server:Start()
    print("Server: Démarrage...")
    
    -- Initialiser les services
    self:InitializeServices()
    
    -- Configurer les événements
    self:SetupRemoteEvents()
    
    print("Server: Démarré avec succès")
end

Server:Start()

return Server