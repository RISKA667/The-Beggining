-- src/client/init.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Importer les contrôleurs
local controllers = {}
controllers.PlayerController = require(script.controllers.PlayerController)
controllers.UIController = require(script.controllers.UIController)
controllers.CameraController = require(script.controllers.CameraController)

-- Importer les modules UI
local ui = {}
ui.StatsUI = require(script.ui.StatsUI)
ui.InventoryUI = require(script.ui.InventoryUI)
ui.CraftingUI = require(script.ui.CraftingUI)
ui.AgeUI = require(script.ui.AgeUI)
ui.NotificationUI = require(script.ui.NotificationUI)

local Client = {}

-- Initialiser les contrôleurs
function Client:InitializeControllers()
    -- Créer et initialiser les contrôleurs
    self.controllers = {}

    -- Initialiser le contrôleur de caméra en premier
    self.controllers.CameraController = controllers.CameraController.new()
    self.controllers.CameraController:Initialize()

    -- Initialiser le contrôleur d'interface utilisateur avec accès aux autres contrôleurs
    self.controllers.UIController = controllers.UIController.new()
    self.controllers.UIController:Initialize(ui, {
        CameraController = self.controllers.CameraController
    })

    -- Initialiser le contrôleur de joueur avec accès au contrôleur UI
    self.controllers.PlayerController = controllers.PlayerController.new()
    self.controllers.PlayerController:Initialize(self.controllers.UIController, {
        CameraController = self.controllers.CameraController
    })

    print("Client: Contrôleurs initialisés")
end

-- Connecter aux événements du serveur
function Client:ConnectToServerEvents()
    -- Dans une implémentation réelle, vous utiliseriez RemoteEvent/RemoteFunction
    -- Ces connexions sont maintenant gérées dans les contrôleurs individuels

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

    -- Précharger en arrière-plan
    spawn(function()
        for _, assetId in ipairs(assetIds) do
            game:GetService("ContentProvider"):PreloadAsync({assetId})
            wait() -- Petit délai pour ne pas surcharger
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
    if self.controllers.UIController and self.controllers.UIController.interfaces.notificationUI then
        self.controllers.UIController:DisplayMessage("Bienvenue dans The Beginning", "info", 8)
    end

    print("Client: Démarré avec succès")
end

Client:Start()

return Client