-- src/client/init.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Importer les contrôleurs
local controllers = {}
controllers.PlayerController = require(script.controllers.PlayerController)
controllers.UIController = require(script.controllers.UIController)
controllers.CameraController = require(script.controllers.CameraController)
controllers.AnimationController = require(script.controllers.AnimationController)

-- Importer les modules UI
local ui = {}
ui.StatsUI = require(script.ui.StatsUI)
ui.InventoryUI = require(script.ui.InventoryUI)
ui.CraftingUI = require(script.ui.CraftingUI)
ui.CraftingStationUI = require(script.ui.CraftingStationUI)
ui.AgeUI = require(script.ui.AgeUI)
ui.NotificationUI = require(script.ui.NotificationUI)
ui.CombatUI = require(script.ui.CombatUI)
ui.TribeUI = require(script.ui.TribeUI)

local Client = {}

-- Initialiser les contrôleurs
function Client:InitializeControllers()
    -- Créer et initialiser les contrôleurs
    self.controllers = {}

    -- Initialiser le contrôleur de caméra en premier
    self.controllers.CameraController = controllers.CameraController.new()
    self.controllers.CameraController:Initialize()

    -- Initialiser le contrôleur d'animation
    self.controllers.AnimationController = controllers.AnimationController.new()
    self.controllers.AnimationController:Initialize()

    -- Initialiser le contrôleur d'interface utilisateur avec les références aux autres contrôleurs
    self.controllers.UIController = controllers.UIController.new()
    self.controllers.UIController:Initialize(ui, {
        CameraController = self.controllers.CameraController
    })

    -- Initialiser le contrôleur de joueur avec accès aux autres contrôleurs
    self.controllers.PlayerController = controllers.PlayerController.new()
    self.controllers.PlayerController:Initialize(self.controllers.UIController, {
        CameraController = self.controllers.CameraController,
        AnimationController = self.controllers.AnimationController
    })

    print("Client: Contrôleurs initialisés")
end

-- Connecter aux événements du serveur
function Client:ConnectToServerEvents()
    -- Dans une implémentation réelle, vous utiliseriez RemoteEvent/RemoteFunction
    -- Ces connexions sont maintenant gérées dans les contrôleurs individuels
    -- Ajout de vérifications pour s'assurer que les contrôleurs gèrent les connexions
    if self.controllers.PlayerController and self.controllers.PlayerController.ConnectToServerEvents then
        self.controllers.PlayerController:ConnectToServerEvents()
    end

    if self.controllers.UIController and self.controllers.UIController.ConnectToServerEvents then
        self.controllers.UIController:ConnectToServerEvents()
    end

    if self.controllers.CameraController and self.controllers.CameraController.ConnectToServerEvents then
        self.controllers.CameraController:ConnectToServerEvents()
    end

    if self.controllers.AnimationController and self.controllers.AnimationController.ConnectToServerEvents then
        self.controllers.AnimationController:ConnectToServerEvents()
    end

    print("Client: Connexion aux événements serveur établie")
end

-- Configurer le chargement des assets
function Client:PreloadAssets()
    -- Précharger les assets pour éviter les lags pendant le jeu
    -- Cela peut inclure des images, des sons, des animations, etc.

    local assetIds = {
        -- Icônes d'interface
        "rbxassetid://6031071053", -- Info icon
        "rbxassetid://6031068420", -- Success icon
        "rbxassetid://6031071057", -- Warning icon
        "rbxassetid://6031071054", -- Error icon

        -- Animations
        "rbxassetid://507768375", -- Animation par défaut pour la récolte

        -- Autres assets
    }

    -- Précharger en arrière-plan avec gestion des erreurs
    task.spawn(function()
        for _, assetId in ipairs(assetIds) do
            local success, errorMessage = pcall(function()
                game:GetService("ContentProvider"):PreloadAsync({assetId})
            end)
            if not success then
                warn("Erreur lors du préchargement de l'asset : " .. assetId .. " - " .. errorMessage)
            end
            task.wait() -- Petit délai pour ne pas surcharger
        end
        print("Client: Préchargement des assets terminé")
    end)
end

-- Démarrer le client
function Client:Start()
    print("Client: Démarrage...")

    -- Attendre que le personnage soit chargé
    if not player.Character then
        player.CharacterAdded:Wait()
    end

    -- Précharger les assets
    self:PreloadAssets()

    -- Initialiser les contrôleurs
    self:InitializeControllers()

    -- Connecter aux événements du serveur
    self:ConnectToServerEvents()

    -- Afficher un message de démarrage via le contrôleur UI
    if self.controllers.UIController and self.controllers.UIController.interfaces and self.controllers.UIController.interfaces.notificationUI then
        self.controllers.UIController:DisplayMessage("Bienvenue dans The Beginning", "info", 8)
    end

    print("Client: Démarré avec succès")
end

Client:Start()

return Client