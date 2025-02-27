-- src/client/controllers/UIController.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIController = {}
UIController.__index = UIController

function UIController.new()
    local self = setmetatable({}, UIController)
    
    -- Interfaces
    self.interfaces = {}
    
    -- Données du joueur
    self.playerData = {
        stats = {
            hunger = 100,
            thirst = 100,
            energy = 100,
            temperature = 50,
            age = 16,
        },
        inventory = {
            items = {},
            equipped = {}
        },
        recipes = {}
    }
    
    -- Références aux autres contrôleurs
    self.cameraController = nil
    
    -- États des interfaces
    self.uiStates = {
        inventoryOpen = false,
        craftingOpen = false,
        anyMenuOpen = false
    }
    
    return self
end

function UIController:Initialize(uiModules, controllers)
    -- Stocker les références aux autres contrôleurs
    if controllers then
        self.cameraController = controllers.CameraController
    end
    
    -- Initialiser les interfaces utilisateur
    self.interfaces.statsUI = uiModules.StatsUI.new()
    self.interfaces.statsUI:Initialize()
    
    self.interfaces.inventoryUI = uiModules.InventoryUI.new()
    self.interfaces.inventoryUI:Initialize()
    
    self.interfaces.craftingUI = uiModules.CraftingUI.new()
    self.interfaces.craftingUI:Initialize()
    
    self.interfaces.ageUI = uiModules.AgeUI.new()
    self.interfaces.ageUI:Initialize()
    
    self.interfaces.notificationUI = uiModules.NotificationUI.new()
    self.interfaces.notificationUI:Initialize()
    
    -- Mettre à jour les interfaces avec les données initiales
    self:UpdateAllInterfaces()
    
    -- Connecter aux événements d'interface
    self:ConnectInterfaceEvents()
    
    -- Configurer les événements de serveur
    self:SetupRemoteEvents()
    
    print("UIController: Interfaces initialisées")
    
    -- Afficher un message de bienvenue
    self:DisplayMessage("Bienvenue dans The Beginning", "system", 8)
end

-- Connecter aux événements spécifiques des interfaces
function UIController:ConnectInterfaceEvents()
    -- Événements d'inventaire
    if self.interfaces.inventoryUI then
        -- Exemple: surcharger la méthode ToggleInventory pour gérer la caméra
        local originalToggleInventory = self.interfaces.inventoryUI.ToggleInventory
        self.interfaces.inventoryUI.ToggleInventory = function(this, open)
            originalToggleInventory(this, open)
            
            -- Mettre à jour l'état
            self.uiStates.inventoryOpen = this.isOpen
            self.uiStates.anyMenuOpen = self.uiStates.inventoryOpen or self.uiStates.craftingOpen
            
            -- Gérer la caméra
            if self.cameraController then
                if this.isOpen then
                    self.cameraController:EnterOrbitMode()
                else
                    -- Ne quitter le mode orbite que si aucun autre menu n'est ouvert
                    if not self.uiStates.anyMenuOpen then
                        self.cameraController:ExitOrbitMode()
                    end
                end
            end
        end
    end
    
    -- Événements de crafting
    if self.interfaces.craftingUI then
        -- Exemple: surcharger la méthode ToggleCrafting pour gérer la caméra
        local originalToggleCrafting = self.interfaces.craftingUI.ToggleCrafting
        self.interfaces.craftingUI.ToggleCrafting = function(this, open)
            originalToggleCrafting(this, open)
            
            -- Mettre à jour l'état
            self.uiStates.craftingOpen = this.isOpen
            self.uiStates.anyMenuOpen = self.uiStates.inventoryOpen or self.uiStates.craftingOpen
            
            -- Gérer la caméra
            if self.cameraController then
                if this.isOpen then
                    self.cameraController:EnterOrbitMode()
                else
                    -- Ne quitter le mode orbite que si aucun autre menu n'est ouvert
                    if not self.uiStates.anyMenuOpen then
                        self.cameraController:ExitOrbitMode()
                    end
                end
            end
        end
    end
end

-- Mettre à jour les statistiques du joueur
function UIController:UpdatePlayerStats(statsData)
    -- Mettre à jour les données locales
    for key, value in pairs(statsData) do
        self.playerData.stats[key] = value
    end
    
    -- Mettre à jour l'interface des statistiques
    if self.interfaces.statsUI then
        self.interfaces.statsUI:HandleServerUpdate(statsData)
    end
    
    -- Vérifier les conditions critiques pour les alertes
    self:CheckCriticalStats(statsData)
end

-- Vérifier les statistiques critiques
function UIController:CheckCriticalStats(statsData)
    -- Vérifier la faim
    if statsData.hunger and statsData.hunger <= 15 and statsData.hunger > 0 then
        self:DisplayMessage("Vous avez très faim, trouvez de la nourriture rapidement!", "warning", 5)
    end
    
    -- Vérifier la soif
    if statsData.thirst and statsData.thirst <= 10 and statsData.thirst > 0 then
        self:DisplayMessage("Vous êtes déshydraté, trouvez de l'eau rapidement!", "warning", 5)
    end
    
    -- Vérifier l'énergie
    if statsData.energy and statsData.energy <= 10 and statsData.energy > 0 then
        self:DisplayMessage("Vous êtes épuisé, trouvez un lit pour vous reposer!", "warning", 5)
    end
    
    -- Vérifier la température
    if statsData.temperature and statsData.temperature <= 20 then
        self:DisplayMessage("Vous avez froid, approchez-vous d'un feu!", "warning", 5)
    elseif statsData.temperature and statsData.temperature >= 80 then
        self:DisplayMessage("Vous avez trop chaud, éloignez-vous des sources de chaleur!", "warning", 5)
    end
end

-- Mettre à jour l'inventaire du joueur
function UIController:UpdateInventory(inventoryData)
    -- Mettre à jour les données locales
    self.playerData.inventory = inventoryData
    
    -- Mettre à jour l'interface d'inventaire
    if self.interfaces.inventoryUI then
        self.interfaces.inventoryUI:UpdateInventory(inventoryData)
    end
    
    -- Mettre à jour l'interface de craft pour refléter les matériaux disponibles
    if self.interfaces.craftingUI then
        self.interfaces.craftingUI:UpdateInventory(inventoryData)
    end
end

-- Mettre à jour les recettes débloquées
function UIController:UpdateRecipes(recipesData)
    -- Mettre à jour les données locales
    self.playerData.recipes = recipesData
    
    -- Mettre à jour l'interface de craft
    if self.interfaces.craftingUI then
        self.interfaces.craftingUI:UpdateRecipes(recipesData)
    end
    
    -- Si c'est la première fois qu'on débloque une recette de niveau bronze/fer/or, afficher une notification
    if recipesData.techLevels then
        if recipesData.techLevels.bronze and not self.playerData.recipes.techLevels.bronze then
            self:DisplayMessage("Vous avez débloqué l'âge du bronze!", "success", 8)
        end
        if recipesData.techLevels.iron and not self.playerData.recipes.techLevels.iron then
            self:DisplayMessage("Vous avez débloqué l'âge du fer!", "success", 8)
        end
        if recipesData.techLevels.gold and not self.playerData.recipes.techLevels.gold then
            self:DisplayMessage("Vous avez débloqué l'âge de l'or!", "success", 8)
        end
    end
end

-- Mettre à jour l'âge du joueur
function UIController:UpdateAge(age)
    -- Mettre à jour les données locales
    self.playerData.stats.age = age
    
    -- Mettre à jour l'interface des statistiques et de l'âge
    if self.interfaces.statsUI then
        self.interfaces.statsUI:UpdateStat("age", age)
    end
    
    if self.interfaces.ageUI then
        self.interfaces.ageUI:UpdateAge(age)
        
        -- Afficher une notification d'anniversaire à chaque année entière
        if math.floor(age) > math.floor(self.playerData.stats.age or 0) then
            self.interfaces.ageUI:ShowAgeNotification(math.floor(age))
        end
    end
end

-- Mettre à jour l'heure du jeu
function UIController:UpdateGameTime(timeInfo)
    if self.interfaces.ageUI then
        self.interfaces.ageUI:UpdateTime(timeInfo)
    end
    
    -- Afficher des messages pour les événements spéciaux
    if timeInfo.isDawnOrDusk and not timeInfo.isDay and not self.lastTimeDawnOrDusk then
        -- L'aube commence
        self:DisplayMessage("Le soleil se lève", "info", 3)
    elseif timeInfo.isDay and not timeInfo.isDawnOrDusk and not self.lastTimeIsDay then
        -- Le jour est pleinement là
        self:DisplayMessage("C'est maintenant le jour", "info", 3)
    elseif timeInfo.isDawnOrDusk and not timeInfo.isDay and self.lastTimeIsDay then
        -- Le crépuscule commence
        self:DisplayMessage("Le soleil se couche", "info", 3)
    elseif not timeInfo.isDay and not timeInfo.isDawnOrDusk and self.lastTimeDawnOrDusk then
        -- La nuit est complètement tombée
        self:DisplayMessage("La nuit est tombée, faites attention aux dangers", "warning", 5)
    end
    
    -- Mémoriser l'état actuel pour le prochain cycle
    self.lastTimeIsDay = timeInfo.isDay
    self.lastTimeDawnOrDusk = timeInfo.isDawnOrDusk
end

-- Mettre à jour toutes les interfaces
function UIController:UpdateAllInterfaces()
    -- Mettre à jour les statistiques
    if self.interfaces.statsUI then
        self.interfaces.statsUI:HandleServerUpdate(self.playerData.stats)
    end
    
    -- Mettre à jour l'inventaire
    if self.interfaces.inventoryUI then
        self.interfaces.inventoryUI:UpdateInventory(self.playerData.inventory)
    end
    
    -- Mettre à jour les recettes
    if self.interfaces.craftingUI then
        self.interfaces.craftingUI:UpdateRecipes(self.playerData.recipes)
    end
    
    -- Mettre à jour l'âge
    if self.interfaces.ageUI then
        self.interfaces.ageUI:UpdateAge(self.playerData.stats.age)
    end
end

-- Afficher un message à l'écran
function UIController:DisplayMessage(message, messageType, duration)
    if self.interfaces.notificationUI then
        self.interfaces.notificationUI:AddNotification(message, messageType, duration)
    else
        -- Fallback si l'interface de notification n'est pas disponible
        print("Message " .. (messageType or "info") .. ": " .. message)
    end
end

-- Afficher une alerte de mort
function UIController:DisplayDeathMessage(causeOfDeath)
    local deathMessages = {
        ["age"] = "Vous êtes mort de vieillesse à l'âge de " .. math.floor(self.playerData.stats.age or 0) .. " ans.",
        ["hunger"] = "Vous êtes mort de faim.",
        ["thirst"] = "Vous êtes mort de soif.",
        ["cold"] = "Vous êtes mort de froid.",
        ["heat"] = "Vous êtes mort de chaleur.",
        ["killed"] = "Vous avez été tué."
    }
    
    local message = deathMessages[causeOfDeath] or "Vous êtes mort."
    
    -- Afficher un écran de mort avec le message
    self:DisplayMessage(message, "error", 10)
    
    -- Cacher les interfaces de jeu pendant que le joueur est mort
    self:ToggleGameUI(false)
    
    -- Afficher une interface de mort
    -- Dans une implémentation complète, on créerait une interface spécifique pour la mort
    -- Pour l'instant, nous utilisons une simple notification
end

-- Afficher un message de naissance
function UIController:DisplayBirthMessage(parentName)
    local message = "Vous êtes né en tant qu'enfant de " .. (parentName or "un autre joueur") .. "."
    
    -- Afficher un écran de naissance avec le message
    self:DisplayMessage(message, "success", 10)
    
    -- Réafficher les interfaces de jeu
    self:ToggleGameUI(true)
end

-- Activer/désactiver les interfaces de jeu
function UIController:ToggleGameUI(visible)
    -- Interfaces à cacher/montrer lors de la mort/naissance
    if self.interfaces.statsUI then
        self.interfaces.statsUI.gui.Enabled = visible
    end
    
    if self.interfaces.ageUI then
        self.interfaces.ageUI.gui.Enabled = visible
    end
    
    -- L'inventaire et le crafting sont toujours désactivés par défaut
    -- Ils sont activés/désactivés par les touches de raccourci
end

-- Ouvrir/fermer l'inventaire
function UIController:ToggleInventory(open)
    if open == nil then
        -- Si aucune valeur n'est fournie, basculer l'état actuel
        open = not (self.interfaces.inventoryUI and self.interfaces.inventoryUI.isOpen)
    end
    
    if self.interfaces.inventoryUI then
        self.interfaces.inventoryUI:ToggleInventory(open)
    end
    
    -- Si l'inventaire est ouvert, fermer l'interface de craft
    if open and self.interfaces.craftingUI and self.interfaces.craftingUI.isOpen then
        self.interfaces.craftingUI:ToggleCrafting(false)
    end
end

-- Ouvrir/fermer l'interface de craft
function UIController:ToggleCrafting(open)
    if open == nil then
        -- Si aucune valeur n'est fournie, basculer l'état actuel
        open = not (self.interfaces.craftingUI and self.interfaces.craftingUI.isOpen)
    end
    
    if self.interfaces.craftingUI then
        self.interfaces.craftingUI:ToggleCrafting(open)
    end
    
    -- Si l'interface de craft est ouverte, fermer l'inventaire
    if open and self.interfaces.inventoryUI and self.interfaces.inventoryUI.isOpen then
        self.interfaces.inventoryUI:ToggleInventory(false)
    end
end

-- Gérer les événements de récolte de ressources
function UIController:HandleResourceHarvest(resourceType, amount)
    -- Afficher une notification
    local resourceNames = {
        ["wood"] = "bois",
        ["stone"] = "pierre",
        ["fiber"] = "fibre",
        ["clay"] = "argile",
        ["berries"] = "baies",
        ["copper_ore"] = "minerai de cuivre",
        ["tin_ore"] = "minerai d'étain",
        ["iron_ore"] = "minerai de fer",
        ["gold_ore"] = "minerai d'or"
    }
    
    local resourceName = resourceNames[resourceType] or resourceType
    self:DisplayMessage("Vous avez récolté " .. amount .. " " .. resourceName, "success", 3)
end

-- Gérer les événements de craft
function UIController:HandleCraftComplete(recipeId, success, message)
    if success then
        local recipe = require(ReplicatedStorage.Shared.constants.CraftingRecipes)[recipeId]
        if recipe then
            self:DisplayMessage("Vous avez fabriqué " .. recipe.name, "success", 3)
        else
            self:DisplayMessage("Fabrication réussie!", "success", 3)
        end
    else
        self:DisplayMessage(message or "Échec de la fabrication", "error", 3)
    end
end

-- Gérer les événements de construction
function UIController:HandleBuildingPlacement(buildingType, success, message)
    if success then
        local itemTypes = require(ReplicatedStorage.Shared.constants.ItemTypes)
        local buildingName = itemTypes[buildingType] and itemTypes[buildingType].name or buildingType
        self:DisplayMessage("Vous avez construit un(e) " .. buildingName, "success", 3)
    else
        self:DisplayMessage(message or "Impossible de construire ici", "error", 3)
    end
end

-- Gérer les événements RemoteEvent du serveur
function UIController:SetupRemoteEvents()
    -- Dans une implémentation réelle, connecter aux RemoteEvents
    local events = ReplicatedStorage:FindFirstChild("Events")
    
    if events then
        -- Connecter pour les statistiques
        local updateStatsEvent = events:FindFirstChild("UpdateStats")
        if updateStatsEvent then
            updateStatsEvent.OnClientEvent:Connect(function(statsData)
                self:UpdatePlayerStats(statsData)
            end)
        end
        
        -- Connecter pour l'inventaire
        local updateInventoryEvent = events:FindFirstChild("UpdateInventory")
        if updateInventoryEvent then
            updateInventoryEvent.OnClientEvent:Connect(function(inventoryData)
                self:UpdateInventory(inventoryData)
            end)
        end
        
                -- Connecter pour les recettes
        local updateRecipesEvent = events:FindFirstChild("UpdateRecipes")
        if updateRecipesEvent then
            updateRecipesEvent.OnClientEvent:Connect(function(recipesData)
                self:UpdateRecipes(recipesData)
            end)
        end
        
        -- Connecter pour l'heure du jeu
        local timeUpdateEvent = events:FindFirstChild("TimeUpdate")
        if timeUpdateEvent then
            timeUpdateEvent.OnClientEvent:Connect(function(timeInfo)
                self:UpdateGameTime(timeInfo)
            end)
        end
        
        -- Connecter pour les événements de mort
        local deathEvent = events:FindFirstChild("Death")
        if deathEvent then
            deathEvent.OnClientEvent:Connect(function(causeOfDeath)
                self:DisplayDeathMessage(causeOfDeath)
            end)
        end
        
        -- Connecter pour les événements de naissance
        local birthEvent = events:FindFirstChild("Birth")
        if birthEvent then
            birthEvent.OnClientEvent:Connect(function(parentName)
                self:DisplayBirthMessage(parentName)
            end)
        end
        
        -- Connecter pour les événements de récolte
        local resourceHarvestEvent = events:FindFirstChild("ResourceHarvest")
        if resourceHarvestEvent then
            resourceHarvestEvent.OnClientEvent:Connect(function(resourceType, amount)
                self:HandleResourceHarvest(resourceType, amount)
            end)
        end
        
        -- Connecter pour les événements de craft
        local craftCompleteEvent = events:FindFirstChild("CraftComplete")
        if craftCompleteEvent then
            craftCompleteEvent.OnClientEvent:Connect(function(recipeId, success, message)
                self:HandleCraftComplete(recipeId, success, message)
            end)
        end
        
        -- Connecter pour les événements de construction
        local buildingPlacementEvent = events:FindFirstChild("BuildingPlacement")
        if buildingPlacementEvent then
            buildingPlacementEvent.OnClientEvent:Connect(function(buildingType, success, message)
                self:HandleBuildingPlacement(buildingType, success, message)
            end)
        end
    else
        warn("UIController: Attention - Dossier Events non trouvé dans ReplicatedStorage")
    end
end

return UIController