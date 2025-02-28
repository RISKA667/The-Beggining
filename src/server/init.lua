-- src/server/init.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Créer le dossier Events s'il n'existe pas
local Events = ReplicatedStorage:FindFirstChild("Events")
if not Events then
    Events = Instance.new("Folder")
    Events.Name = "Events"
    Events.Parent = ReplicatedStorage
end

-- Importer les services
local services = {}
services.PlayerService = require(script.services.PlayerService)
services.InventoryService = require(script.services.InventoryService)
services.CraftingService = require(script.services.CraftingService)
services.ResourceService = require(script.services.ResourceService)
services.SurvivalService = require(script.services.SurvivalService)
services.TimeService = require(script.services.TimeService)
services.BuildingService = require(script.services.BuildingService)
services.TribeService = require(script.services.TribeService)

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
    self.services.TribeService = services.TribeService.new()
    
    -- Démarrer les services dans un ordre spécifique
    -- Certains services peuvent dépendre d'autres
    self.services.TimeService:Start(self.services)
    self.services.PlayerService:Start(self.services)
    self.services.InventoryService:Start(self.services)
    self.services.ResourceService:Start(self.services)
    self.services.CraftingService:Start(self.services)
    self.services.SurvivalService:Start(self.services)
    self.services.BuildingService:Start(self.services)
    self.services.TribeService:Start(self.services)
    
    print("Server: Services initialisés avec succès")
end

-- Configurer les événements de communication client-serveur
function Server:SetupRemoteEvents()
    print("Server: Configuration des événements RemoteEvent...")
    
    -- Créer les RemoteEvents nécessaires
    
    -- Mise à jour des statistiques
    local updateStatsEvent = Instance.new("RemoteEvent")
    updateStatsEvent.Name = "UpdateStats"
    updateStatsEvent.Parent = Events
    
    -- Mise à jour de l'inventaire
    local updateInventoryEvent = Instance.new("RemoteEvent")
    updateInventoryEvent.Name = "UpdateInventory"
    updateInventoryEvent.Parent = Events
    
    -- Mise à jour des recettes
    local updateRecipesEvent = Instance.new("RemoteEvent")
    updateRecipesEvent.Name = "UpdateRecipes"
    updateRecipesEvent.Parent = Events
    
    -- Mise à jour du temps in-game
    local timeUpdateEvent = Instance.new("RemoteEvent")
    timeUpdateEvent.Name = "TimeUpdate"
    timeUpdateEvent.Parent = Events
    
    -- Mort du joueur
    local deathEvent = Instance.new("RemoteEvent")
    deathEvent.Name = "Death"
    deathEvent.Parent = Events
    
    -- Naissance/Respawn
    local birthEvent = Instance.new("RemoteEvent")
    birthEvent.Name = "Birth"
    birthEvent.Parent = Events
    
    -- Récolte de ressource
    local resourceHarvestEvent = Instance.new("RemoteEvent")
    resourceHarvestEvent.Name = "ResourceHarvest"
    resourceHarvestEvent.Parent = Events
    
    -- Artisanat
    local craftCompleteEvent = Instance.new("RemoteEvent")
    craftCompleteEvent.Name = "CraftComplete"
    craftCompleteEvent.Parent = Events
    
    -- Construction
    local buildingPlacementEvent = Instance.new("RemoteEvent")
    buildingPlacementEvent.Name = "BuildingPlacement"
    buildingPlacementEvent.Parent = Events
    
    -- Notification
    local notificationEvent = Instance.new("RemoteEvent")
    notificationEvent.Name = "Notification"
    notificationEvent.Parent = Events
    
    -- Actions générales du joueur
    local playerActionEvent = Instance.new("RemoteEvent")
    playerActionEvent.Name = "PlayerAction"
    playerActionEvent.Parent = Events
    
    -- Événements de tribu
    local tribeActionEvent = Instance.new("RemoteEvent")
    tribeActionEvent.Name = "TribeAction"
    tribeActionEvent.Parent = Events
    
    local tribeUpdateEvent = Instance.new("RemoteEvent")
    tribeUpdateEvent.Name = "TribeUpdate"
    tribeUpdateEvent.Parent = Events
    
    -- Connexion pour les actions des joueurs
    playerActionEvent.OnServerEvent:Connect(function(player, actionType, ...)
        self:HandlePlayerAction(player, actionType, ...)
    end)
    
    -- Connexion pour les actions de tribu
    tribeActionEvent.OnServerEvent:Connect(function(player, action, ...)
        if self.services.TribeService then
            self.services.TribeService:HandleTribeAction(player, action, ...)
        end
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
            local craftCompleteEvent = events:FindFirstChild("CraftComplete")
            
            if notificationEvent then
                notificationEvent:FireClient(player, message, success and "success" or "error")
            end
            
            if craftCompleteEvent then
                craftCompleteEvent:FireClient(player, recipeId, success, message)
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
        
        local success, message = self.services.BuildingService:PlaceBuilding(player, itemId, position, rotation)
        
        -- Informer le client du résultat
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events then
            local buildingPlacementEvent = events:FindFirstChild("BuildingPlacement")
            if buildingPlacementEvent then
                buildingPlacementEvent:FireClient(player, itemId, success, message)
            end
        end
    elseif actionType == "sleep" then
        -- Commencer à dormir
        self.services.SurvivalService:StartSleeping(player)
    elseif actionType == "wake_up" then
        -- Arrêter de dormir
        self.services.SurvivalService:StopSleeping(player)
    elseif actionType == "gather_resource" then
        -- Récolter une ressource
        local resourceType = args[1]
        local resourceInstance = args[2]
        
        local success, amount = self.services.ResourceService:HarvestResource(player, resourceType, resourceInstance)
        
        -- Informer le client du résultat
        if success then
            local events = ReplicatedStorage:FindFirstChild("Events")
            if events then
                local resourceHarvestEvent = events:FindFirstChild("ResourceHarvest")
                if resourceHarvestEvent then
                    resourceHarvestEvent:FireClient(player, resourceType, amount)
                end
            end
        end
    elseif actionType == "equip_slot" then
        -- Équiper un objet
        local slotNumber = args[1]
        self.services.InventoryService:EquipItem(player, slotNumber)
    elseif actionType == "unequip_slot" then
        -- Déséquiper un objet
        local equipSlot = args[1]
        self.services.InventoryService:UnequipItem(player, equipSlot)
    elseif actionType == "sprint_start" then
        -- Commencer à courir
        -- Ajouter une logique supplémentaire si nécessaire
    elseif actionType == "sprint_stop" then
        -- Arrêter de courir
        -- Ajouter une logique supplémentaire si nécessaire
    end
end

-- Démarrer le serveur
function Server:Start()
    print("Server: Démarrage...")
    
    -- Initialiser les services
    self:InitializeServices()
    
    -- Configurer les événements
    self:SetupRemoteEvents()
    
    -- Configurer la gestion des erreurs
    self:SetupErrorHandling()
    
    -- Connecter les événements de joueur au niveau du serveur
    Players.PlayerAdded:Connect(function(player)
        print("Server: Nouveau joueur connecté - " .. player.Name)
        
        -- Les services individuels gèrent leur propre logique de joueur
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        print("Server: Joueur déconnecté - " .. player.Name)
        
        -- Les services individuels gèrent leur propre logique de déconnexion
    end)
    
    print("Server: Démarré avec succès")
end

-- Configurer une gestion robuste des erreurs
function Server:SetupErrorHandling()
    -- Gérer les erreurs de script et les journaliser correctement
    game:BindToClose(function()
        -- Sauvegarder les données critiques avant de fermer le serveur
        pcall(function()
            for _, player in ipairs(Players:GetPlayers()) do
                if self.services.TribeService then
                    self.services.TribeService:HandlePlayerRemoving(player)
                end
                
                if self.services.InventoryService then 
                    self.services.InventoryService:HandlePlayerRemoving(player)
                end
            end
            
            print("Server: Sauvegarde effectuée - Fermeture du serveur")
        end)
    end)
end

Server:Start()

return Server