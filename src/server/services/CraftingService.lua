-- src/server/services/CraftingService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Références aux ressources partagées
local Shared = ReplicatedStorage:FindFirstChild("Shared")
if not Shared then
    error("Dossier Shared non trouvé dans ReplicatedStorage")
    return nil
end

local CraftingRecipes = require(Shared.constants.CraftingRecipes)

local CraftingService = {}
CraftingService.__index = CraftingService

-- Créer une instance du service
function CraftingService.new()
    local self = setmetatable({}, CraftingService)
    
    -- Recettes débloquées par niveau technologique
    self.unlockedTechLevels = {
        ["stone"] = true,       -- Niveau initial: Pierre
        ["wood"] = true,        -- Bois (débloqué au début)
        ["bronze"] = false,     -- Bronze (à débloquer)
        ["iron"] = false,       -- Fer (à débloquer)
        ["gold"] = false        -- Or (à débloquer)
    }
    
    -- Recettes débloquées pour chaque joueur
    self.playerUnlockedRecipes = {}
    
    -- Références aux autres services (seront injectées via Start)
    self.inventoryService = nil
    
    -- RemoteEvents (seront référencés dans Start)
    self.remoteEvents = {}
    
    return self
end

-- Initialiser les recettes débloquées pour un joueur
function CraftingService:InitializePlayerRecipes(player)
    local userId = player.UserId
    if self.playerUnlockedRecipes[userId] then return end
    
    -- Initialiser avec les recettes du niveau technologique de base
    self.playerUnlockedRecipes[userId] = {}
    
    -- Débloquer les recettes initiales
    for recipeId, recipe in pairs(CraftingRecipes) do
        if self.unlockedTechLevels[recipe.techLevel] then
            self.playerUnlockedRecipes[userId][recipeId] = true
        end
    end
    
    -- Mettre à jour le client avec les recettes débloquées
    self:UpdateClientRecipes(player)
end

-- Débloquer un niveau technologique (pour tous les joueurs)
function CraftingService:UnlockTechLevel(techLevel)
    if not self.unlockedTechLevels[techLevel] then
        self.unlockedTechLevels[techLevel] = true
        
        -- Débloquer les recettes associées pour tous les joueurs
        for userId, playerRecipes in pairs(self.playerUnlockedRecipes) do
            for recipeId, recipe in pairs(CraftingRecipes) do
                if recipe.techLevel == techLevel then
                    playerRecipes[recipeId] = true
                end
            end
            
            -- Mettre à jour le client
            local player = Players:GetPlayerByUserId(userId)
            if player then
                self:UpdateClientRecipes(player)
            end
        end
        
        -- Journal de débogage
        print("CraftingService: Niveau technologique débloqué - " .. techLevel)
        return true
    end
    
    return false
end

-- Débloquer une recette spécifique pour un joueur
function CraftingService:UnlockRecipeForPlayer(player, recipeId)
    local userId = player.UserId
    if not self.playerUnlockedRecipes[userId] then
        self:InitializePlayerRecipes(player)
    end
    
    if CraftingRecipes[recipeId] and not self.playerUnlockedRecipes[userId][recipeId] then
        self.playerUnlockedRecipes[userId][recipeId] = true
        self:UpdateClientRecipes(player)
        
        -- Journal de débogage
        print("CraftingService: Recette débloquée pour " .. player.Name .. " - " .. recipeId)
        return true
    end
    
    return false
end

-- Vérifier si un joueur a les ressources nécessaires pour un craft
function CraftingService:HasResourcesForCraft(player, recipeId)
    if not self.inventoryService then
        warn("CraftingService: InventoryService non initialisé")
        return false
    end
    
    local recipe = CraftingRecipes[recipeId]
    if not recipe then 
        warn("CraftingService: Recette invalide - " .. tostring(recipeId))
        return false 
    end
    
    -- Vérifier chaque ingrédient requis
    for itemId, requiredQuantity in pairs(recipe.ingredients) do
        local hasEnough = self.inventoryService:HasItemInInventory(player, itemId, requiredQuantity)
        
        if not hasEnough then
            return false
        end
    end
    
    return true
end

-- Fabriquer un objet
function CraftingService:CraftItem(player, recipeId)
    local userId = player.UserId
    
    -- Vérification de sécurité
    if not player or not player:IsA("Player") or not recipeId then
        return false, "Paramètres invalides"
    end
    
    local recipe = CraftingRecipes[recipeId]
    
    -- Vérifier si la recette existe et est débloquée
    if not recipe then
        return false, "Recette invalide"
    end
    
    if not self.playerUnlockedRecipes[userId] or not self.playerUnlockedRecipes[userId][recipeId] then
        return false, "Recette non débloquée"
    end
    
    -- Vérifier si nous avons accès au service d'inventaire
    if not self.inventoryService then
        warn("CraftingService: InventoryService non disponible")
        return false, "Service temporairement indisponible"
    end
    
    -- Vérifier si le joueur a les ressources nécessaires
    if not self:HasResourcesForCraft(player, recipeId) then
        return false, "Ressources insuffisantes"
    end
    
    -- Vérifier si une station est requise
    if recipe.requiredStation then
        -- Vérifier si le joueur est près d'une station appropriée
        -- Cette vérification serait plus complexe dans une implémentation complète
        local hasStation = true -- Temporairement mis à true pour simplifier
        
        if not hasStation then
            return false, "Station de craft requise: " .. recipe.requiredStation
        end
    end
    
    -- Retirer les ingrédients de l'inventaire
    local ingredientsRemoved = {}
    local success = true
    
    for itemId, quantity in pairs(recipe.ingredients) do
        local removed = self.inventoryService:RemoveItemFromInventory(player, itemId, quantity)
        if not removed then
            success = false
            break
        end
        
        ingredientsRemoved[itemId] = quantity
    end
    
    -- Si un ingrédient n'a pas pu être retiré, restaurer tous les ingrédients déjà retirés
    if not success then
        for itemId, quantity in pairs(ingredientsRemoved) do
            self.inventoryService:AddItemToInventory(player, itemId, quantity)
        end
        return false, "Erreur lors de la récupération des ingrédients"
    end
    
    -- Ajouter le résultat à l'inventaire du joueur
    local resultAdded = self.inventoryService:AddItemToInventory(
        player, 
        recipe.result.id, 
        recipe.result.quantity
    )
    
    -- Si l'ajout échoue (inventaire plein), remettre les ingrédients
    if not resultAdded then
        for itemId, quantity in pairs(ingredientsRemoved) do
            self.inventoryService:AddItemToInventory(player, itemId, quantity)
        end
        return false, "Inventaire plein"
    end
    
    -- Envoyer un événement de succès au client
    if self.remoteEvents.CraftComplete then
        self.remoteEvents.CraftComplete:FireClient(player, recipeId, true, "Fabrication réussie")
    end
    
    -- Journal de débogage
    print("CraftingService: " .. player.Name .. " a fabriqué " .. recipe.name)
    
    return true, "Fabrication réussie"
end

-- Mettre à jour les recettes débloquées pour le client
function CraftingService:UpdateClientRecipes(player)
    local userId = player.UserId
    
    -- S'assurer que le joueur a des données de recettes
    if not self.playerUnlockedRecipes[userId] then
        self:InitializePlayerRecipes(player)
        return
    end
    
    -- Préparer les données à envoyer au client
    local recipesData = {
        unlockedRecipes = {},
        techLevels = {}
    }
    
    -- Ajouter les recettes débloquées
    for recipeId, isUnlocked in pairs(self.playerUnlockedRecipes[userId]) do
        if isUnlocked then
            recipesData.unlockedRecipes[recipeId] = true
        end
    end
    
    -- Ajouter les niveaux technologiques débloqués
    for techLevel, isUnlocked in pairs(self.unlockedTechLevels) do
        recipesData.techLevels[techLevel] = isUnlocked
    end
    
    -- Envoyer les données au client
    if self.remoteEvents.UpdateRecipes then
        self.remoteEvents.UpdateRecipes:FireClient(player, recipesData)
    else
        warn("CraftingService: RemoteEvent UpdateRecipes non disponible")
    end
end

-- Gérer la déconnexion d'un joueur
function CraftingService:HandlePlayerRemoving(player)
    local userId = player.UserId
    if self.playerUnlockedRecipes[userId] then
        -- Ici, on pourrait sauvegarder les données dans DataStore si nécessaire
        self.playerUnlockedRecipes[userId] = nil
    end
end

-- Initialiser le service
function CraftingService:Start(services)
    -- Récupérer les références aux autres services
    self.inventoryService = services.InventoryService
    
    if not self.inventoryService then
        warn("CraftingService: InventoryService non disponible. Certaines fonctionnalités seront limitées.")
    end
    
    -- Récupérer les références aux RemoteEvents
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if Events then
        self.remoteEvents = {
            UpdateRecipes = Events:FindFirstChild("UpdateRecipes"),
            CraftComplete = Events:FindFirstChild("CraftComplete"),
            Notification = Events:FindFirstChild("Notification")
        }
    else
        warn("CraftingService: Dossier Events non trouvé dans ReplicatedStorage")
    end
    
    -- Gérer les événements de joueur
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerRecipes(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
    
    -- Initialiser les joueurs déjà connectés
    for _, player in ipairs(Players:GetPlayers()) do
        self:InitializePlayerRecipes(player)
    end
    
    print("CraftingService: Démarré avec succès")
    return self
end

return CraftingService
