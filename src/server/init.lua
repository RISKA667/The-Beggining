-- src/server/init.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Assurez-vous que nous sommes sur le serveur
if not RunService:IsServer() then
    error("Le script serveur a été exécuté dans un contexte client!")
    return
end

-- Création du dossier Events dans ReplicatedStorage s'il n'existe pas
local Events = ReplicatedStorage:FindFirstChild("Events")
if not Events then
    Events = Instance.new("Folder")
    Events.Name = "Events"
    Events.Parent = ReplicatedStorage
end

-- Création du dossier Shared dans ReplicatedStorage s'il n'existe pas
local Shared = ReplicatedStorage:FindFirstChild("Shared")
if not Shared then
    warn("Dossier Shared non trouvé dans ReplicatedStorage. Certaines fonctionnalités pourraient ne pas fonctionner correctement.")
end

-- Définition des chemins d'accès relatifs
local services = {}

-- Structure du Server pour référencer plus tard
local Server = {
    services = {},        -- Services initialisés
    remoteEvents = {},    -- Références aux RemoteEvents
    isInitialized = false -- État d'initialisation du serveur
}

-- Import des services
local function LoadServices()
    -- Importation des modules de service en utilisant les chemins relatifs
    services.TimeService = require(script.services.TimeService)
    services.PlayerService = require(script.services.PlayerService)
    services.InventoryService = require(script.services.InventoryService)
    services.CraftingService = require(script.services.CraftingService)
    services.ResourceService = require(script.services.ResourceService)
    services.SurvivalService = require(script.services.SurvivalService)
    services.BuildingService = require(script.services.BuildingService)
    services.TribeService = require(script.services.TribeService)

    -- Initialisation des services
    print("Server: Initialisation des services...")
    
    Server.services.TimeService = services.TimeService.new()
    Server.services.PlayerService = services.PlayerService.new()
    Server.services.InventoryService = services.InventoryService.new()
    Server.services.ResourceService = services.ResourceService.new()
    Server.services.CraftingService = services.CraftingService.new()
    Server.services.SurvivalService = services.SurvivalService.new()
    Server.services.BuildingService = services.BuildingService.new()
    Server.services.TribeService = services.TribeService.new()
    
    print("Server: Services chargés avec succès")
end

-- Configuration des RemoteEvents
local function SetupRemoteEvents()
    print("Server: Configuration des RemoteEvents...")
    
    -- Tableau des RemoteEvents à créer
    local eventsToCreate = {
        "UpdateStats",        -- Mise à jour des statistiques du joueur
        "UpdateInventory",    -- Mise à jour de l'inventaire
        "UpdateRecipes",      -- Mise à jour des recettes débloquées
        "TimeUpdate",         -- Mise à jour du temps in-game
        "Death",              -- Notification de mort du joueur
        "Birth",              -- Notification de naissance/respawn
        "ResourceHarvest",    -- Notification de récolte de ressource
        "CraftComplete",      -- Notification de fabrication terminée
        "BuildingPlacement",  -- Notification de placement de bâtiment
        "Notification",       -- Système de notification générique
        "PlayerAction",       -- Actions générales du joueur
        "TribeAction",        -- Actions liées aux tribus
        "TribeUpdate"         -- Mise à jour des informations de tribu
    }
    
    -- Créer tous les RemoteEvents nécessaires
    for _, eventName in ipairs(eventsToCreate) do
        local event = Events:FindFirstChild(eventName)
        if not event then
            event = Instance.new("RemoteEvent")
            event.Name = eventName
            event.Parent = Events
        end
        
        -- Stocker la référence pour un accès facile
        Server.remoteEvents[eventName] = event
    end
    
    print("Server: RemoteEvents configurés avec succès")
end

-- Démarrage des services avec injection de dépendances
local function StartServices()
    print("Server: Démarrage des services...")
    
    -- Ordre de démarrage des services (pour gérer les dépendances)
    local startOrder = {
        "TimeService",
        "PlayerService",
        "InventoryService",
        "ResourceService", 
        "CraftingService",
        "SurvivalService",
        "BuildingService",
        "TribeService"
    }
    
    -- Démarrer les services dans l'ordre spécifié
    for _, serviceName in ipairs(startOrder) do
        local service = Server.services[serviceName]
        if service and type(service.Start) == "function" then
            -- Passer toutes les références de services pour l'injection de dépendances
            local success, errorMsg = pcall(function()
                service:Start(Server.services)
            end)
            
            if not success then
                warn("Erreur lors du démarrage du service " .. serviceName .. ": " .. tostring(errorMsg))
            else
                print("Server: " .. serviceName .. " démarré avec succès")
            end
        else
            warn("Service " .. serviceName .. " introuvable ou méthode Start manquante")
        end
    end
    
    print("Server: Tous les services démarrés")
end

-- Configuration des gestionnaires d'événements
local function SetupEventHandlers()
    -- Gestionnaire d'action joueur
    if Server.remoteEvents.PlayerAction then
        Server.remoteEvents.PlayerAction.OnServerEvent:Connect(function(player, actionType, ...)
            Server:HandlePlayerAction(player, actionType, ...)
        end)
    end
    
    -- Gestionnaire d'action tribu
    if Server.remoteEvents.TribeAction then
        Server.remoteEvents.TribeAction.OnServerEvent:Connect(function(player, action, ...)
            if Server.services.TribeService then
                Server.services.TribeService:HandleTribeAction(player, action, ...)
            end
        end)
    end
    
    -- Événements de joueur
    Players.PlayerAdded:Connect(function(player)
        print("Server: Nouveau joueur connecté - " .. player.Name)
        -- Les services individuels gèrent leur logique spécifique via leurs propres connexions
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        print("Server: Joueur déconnecté - " .. player.Name)
        -- Les services individuels gèrent leur logique spécifique via leurs propres connexions
    end)
end

-- Gestionnaire central d'actions de joueur
function Server:HandlePlayerAction(player, actionType, ...)
    local args = {...}
    
    -- Vérification de sécurité basique
    if not player or not player:IsA("Player") or not actionType then
        return
    end
    
    if actionType == "craft" then
        -- Fabrication d'objet
        local recipeId = args[1]
        if type(recipeId) ~= "string" then return end
        
        local success, message = self.services.CraftingService:CraftItem(player, recipeId)
        
        -- Informer le client du résultat
        if success ~= nil then
            if self.remoteEvents.Notification then
                self.remoteEvents.Notification:FireClient(player, message, success and "success" or "error")
            end
            
            if self.remoteEvents.CraftComplete then
                self.remoteEvents.CraftComplete:FireClient(player, recipeId, success, message)
            end
        end
    elseif actionType == "use_item" then
        -- Utilisation d'objet
        local slotNumber = args[1]
        local itemId = args[2]
        
        if type(slotNumber) ~= "number" or type(itemId) ~= "string" then return end
        
        -- Vérification de l'existence de l'item
        local itemExists = false
        if Shared then
            local ItemTypes = require(Shared.constants.ItemTypes)
            itemExists = ItemTypes[itemId] ~= nil
        end
        
        if not itemExists then return end
        
        -- Traiter selon la catégorie de l'item
        if Shared then
            local ItemTypes = require(Shared.constants.ItemTypes)
            local itemType = ItemTypes[itemId]
            
            if itemType.category == "food" then
                self.services.SurvivalService:ConsumeFood(player, itemId)
            elseif itemType.category == "drink" then
                self.services.SurvivalService:ConsumeDrink(player, itemId)
            elseif itemType.category == "building" or itemType.category == "furniture" then
                self.services.BuildingService:StartPlacement(player, itemId, slotNumber)
            end
        end
    elseif actionType == "place_building" then
        -- Placer un bâtiment
        local itemId = args[1]
        local position = args[2]
        local rotation = args[3]
        
        if type(itemId) ~= "string" or typeof(position) ~= "Vector3" then return end
        
        local success, message = self.services.BuildingService:PlaceBuilding(player, itemId, position, rotation)
        
        if self.remoteEvents.BuildingPlacement then
            self.remoteEvents.BuildingPlacement:FireClient(player, itemId, success, message)
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
        
        if type(resourceType) ~= "string" then return end
        
        local success, amount = self.services.ResourceService:HarvestResource(player, resourceType, resourceInstance)
        
        if success and self.remoteEvents.ResourceHarvest then
            self.remoteEvents.ResourceHarvest:FireClient(player, resourceType, amount)
        end
    elseif actionType == "equip_slot" then
        -- Équiper un objet
        local slotNumber = args[1]
        
        if type(slotNumber) ~= "number" then return end
        
        self.services.InventoryService:EquipItem(player, slotNumber)
    elseif actionType == "unequip_slot" then
        -- Déséquiper un objet
        local equipSlot = args[1]
        
        if type(equipSlot) ~= "string" then return end
        
        self.services.InventoryService:UnequipItem(player, equipSlot)
    end
end

-- Configuration de la gestion d'erreurs
local function SetupErrorHandling()
    -- Gestion de la fermeture du serveur
    game:BindToClose(function()
        print("Server: Sauvegarde des données avant fermeture...")
        
        local success, errorMsg = pcall(function()
            -- Sauvegarder les données critiques
            for _, player in ipairs(Players:GetPlayers()) do
                -- Sauvegarder les données de tribu
                if Server.services.TribeService then
                    Server.services.TribeService:HandlePlayerRemoving(player)
                end
                
                -- Sauvegarder les inventaires
                if Server.services.InventoryService then 
                    Server.services.InventoryService:HandlePlayerRemoving(player)
                end
                
                -- Autres sauvegardes si nécessaire...
            end
        end)
        
        if not success then
            warn("Erreur lors de la sauvegarde des données: " .. tostring(errorMsg))
        else
            print("Server: Sauvegarde effectuée avec succès")
        end
        
        print("Server: Fermeture du serveur")
    end)
    
    -- Autre gestion d'erreurs globale si nécessaire...
end

-- Point d'entrée principal
local function Start()
    print("Server: Démarrage...")
    
    -- Chargement des services
    LoadServices()
    
    -- Configuration des RemoteEvents
    SetupRemoteEvents()
    
    -- Démarrage des services avec injection des dépendances
    StartServices()
    
    -- Configuration des gestionnaires d'événements
    SetupEventHandlers()
    
    -- Configuration de la gestion d'erreurs
    SetupErrorHandling()
    
    -- Marquer le serveur comme initialisé
    Server.isInitialized = true
    
    print("Server: Démarré avec succès")
end

-- Démarrer le serveur
Start()

return Server
