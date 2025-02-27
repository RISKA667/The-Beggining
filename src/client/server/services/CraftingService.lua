-- src/server/services/CraftingService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CraftingRecipes = require(Shared.constants.CraftingRecipes)

-- Services
local Server = ServerScriptService:WaitForChild("Server")
local Services = Server:WaitForChild("services")
local InventoryService -- Sera initialisé dans Start()

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
    
    return self
end

-- Initialiser les recettes débloquées pour un joueur
function CraftingService:InitializePlayerRecipes(player)
    if self.playerUnlockedRecipes[player.UserId] then return end
    
    -- Initialiser avec les recettes du niveau technologique de base
    self.playerUnlockedRecipes[player.UserId] = {}
    
    -- Débloquer les recettes initiales
    for recipeId, recipe in pairs(CraftingRecipes) do
        if self.unlockedTechLevels[recipe.techLevel] then
            self.playerUnlockedRecipes[player.UserId][recipeId] = true
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
            local player = game.Players:GetPlayerByUserId(userId)
            if player then
                self:UpdateClientRecipes(player)
            end
        end
    end
end

-- Débloquer une recette spécifique pour un joueur
function CraftingService:UnlockRecipeForPlayer(player, recipeId)
    if not self.playerUnlockedRecipes[player.UserId] then
        self:InitializePlayerRecipes(player)
    end
    
    if CraftingRecipes[recipeId] and not self.playerUnlockedRecipes[player.UserId][recipeId] then
        self.playerUnlockedRecipes[player.UserId][recipeId] = true
        self:UpdateClientRecipes(player)
    end
end

-- Vérifier si un joueur a les ressources nécessaires pour un craft
function CraftingService:HasResourcesForCraft(player, recipeId)
    local recipe = CraftingRecipes[recipeId]
    if not recipe then return false end
    
    -- Vérifier chaque ingrédient requis
    for itemId, requiredQuantity in pairs(recipe.ingredients) do
        local hasEnough = false
        local inventory = InventoryService.playerInventories[player.UserId]
        
        if not inventory then return false end
        
        -- Compter combien le joueur a de cet objet
        local playerQuantity = 0
        for _, item in pairs(inventory.items) do
            if item.id == itemId then
                playerQuantity = playerQuantity + item.quantity
            end
        end
        
        if playerQuantity < requiredQuantity then
            return false
        end
    end
    
    return true
end

-- Fabriquer un objet
function CraftingService:CraftItem(player, recipeId)
    local recipe = CraftingRecipes[recipeId]
    
    -- Vérifier si la recette existe et est débloquée
    if not recipe or not self.playerUnlockedRecipes[player.UserId] or 
       not self.playerUnlockedRecipes[player.UserId][recipeId] then
        return false, "Recipe not unlocked"
    end
    
    -- Vérifier si le joueur a les ressources nécessaires
    if not self:HasResourcesForCraft(player, recipeId) then
        return false, "Not enough resources"
    end
    
    -- Retirer les ingrédients de l'inventaire
    for itemId, quantity in pairs(recipe.ingredients) do
        local success = InventoryService:RemoveItemFromInventory(player, itemId, quantity)
        if not success then
            return false, "Failed to remove ingredients"
        end
    end
    
    -- Ajouter le résultat à l'inventaire
    local success = InventoryService:AddItemToInventory(player, recipe.result.id, recipe.result.quantity)
    if not success then
        -- Si l'ajout échoue (inventaire plein), remettre les ingrédients
        for itemId, quantity in pairs(recipe.ingredients) do
            InventoryService:AddItemToInventory(player, itemId, quantity)
        end
        return false, "Inventory full"
    end
    
    return true, "Crafting successful"
end

-- Mettre à jour les recettes débloquées pour le client
function CraftingService:UpdateClientRecipes(player)
    -- Dans une implémentation réelle, utilisez RemoteEvent pour synchroniser avec le client
    print("Mise à jour des recettes pour le joueur: " .. player.Name)
end

-- Gérer la déconnexion d'un joueur
function CraftingService:HandlePlayerRemoving(player)
    self.playerUnlockedRecipes[player.UserId] = nil
end

function CraftingService:Start(services)
    -- Récupérer les références aux autres services
    InventoryService = services.InventoryService
    
    -- Gérer les événements de joueur
    game.Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerRecipes(player)
    end)
    
    game.Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
end

return CraftingService