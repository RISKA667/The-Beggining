-- src/client/ui/CraftingUI.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemTypes = require(Shared.constants.ItemTypes)
local CraftingRecipes = require(Shared.constants.CraftingRecipes)

local CraftingUI = {}
CraftingUI.__index = CraftingUI

function CraftingUI.new()
    local self = setmetatable({}, CraftingUI)
    
    -- Référence au joueur local
    self.player = Players.LocalPlayer
    
    -- Recettes débloquées
    self.unlockedRecipes = {}
    
    -- Recette sélectionnée
    self.selectedRecipe = nil
    
    -- Interface ScreenGui
    self.gui = nil
    self.recipeListFrames = {}
    self.isOpen = false
    
    -- Catégories de recettes
    self.categories = {
        "tools",      -- Outils
        "weapons",    -- Armes
        "clothing",   -- Vêtements
        "building",   -- Construction
        "furniture",  -- Mobilier
        "food",       -- Nourriture
        "stations"    -- Stations d'artisanat
    }
    
    -- Catégorie sélectionnée
    self.selectedCategory = "tools"
    
    -- Référence à l'inventaire (pour vérifier les ressources disponibles)
    self.inventoryData = {
        items = {}
    }
    
    return self
end

function CraftingUI:Initialize()
    -- Créer l'interface ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "CraftingUI"
    self.gui.ResetOnSpawn = false
    self.gui.Enabled = false
    
    -- Cadre principal pour le craft
    self.craftingFrame = Instance.new("Frame")
    self.craftingFrame.Name = "CraftingFrame"
    self.craftingFrame.Size = UDim2.new(0, 700, 0, 500)
    self.craftingFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    self.craftingFrame.BackgroundTransparency = 0.2
    self.craftingFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    self.craftingFrame.BorderSizePixel = 0
    self.craftingFrame.Parent = self.gui
    
    -- Arrondir les coins
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 10)
    uiCorner.Parent = self.craftingFrame
    
    -- Titre de l'interface
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 0.5
    titleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleLabel.BorderSizePixel = 0
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = "Artisanat"
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.Parent = self.craftingFrame
    
    -- Arrondir les coins du titre
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleLabel
    
    -- Bouton de fermeture
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundTransparency = 0.5
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "X"
    closeButton.TextSize = 20
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = titleLabel
    
    -- Arrondir les coins du bouton
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = closeButton
    
    -- Onglets de catégories
    self:CreateCategoryTabs()
    
    -- Panneau de liste des recettes
    local recipeListFrame = Instance.new("ScrollingFrame")
    recipeListFrame.Name = "RecipeListFrame"
    recipeListFrame.Size = UDim2.new(0, 250, 0, 410)
    recipeListFrame.Position = UDim2.new(0, 10, 0, 80)
    recipeListFrame.BackgroundTransparency = 0.7
    recipeListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    recipeListFrame.BorderSizePixel = 0
    recipeListFrame.ScrollBarThickness = 6
    recipeListFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- Sera ajusté dynamiquement
    recipeListFrame.TopImage = "rbxassetid://7123458627"
    recipeListFrame.MidImage = "rbxassetid://7123458627"
    recipeListFrame.BottomImage = "rbxassetid://7123458627"
    recipeListFrame.Parent = self.craftingFrame
    
    -- Panneau de détail de recette
    local recipeDetailFrame = Instance.new("Frame")
    recipeDetailFrame.Name = "RecipeDetailFrame"
    recipeDetailFrame.Size = UDim2.new(0, 420, 0, 410)
    recipeDetailFrame.Position = UDim2.new(0, 270, 0, 80)
    recipeDetailFrame.BackgroundTransparency = 0.7
    recipeDetailFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    recipeDetailFrame.BorderSizePixel = 0
    recipeDetailFrame.Parent = self.craftingFrame
    
    -- Nom de la recette
    local recipeName = Instance.new("TextLabel")
    recipeName.Name = "RecipeName"
    recipeName.Size = UDim2.new(1, 0, 0, 40)
    recipeName.Position = UDim2.new(0, 0, 0, 0)
    recipeName.BackgroundTransparency = 0.7
    recipeName.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    recipeName.BorderSizePixel = 0
    recipeName.TextColor3 = Color3.fromRGB(255, 255, 255)
    recipeName.Text = "Sélectionnez une recette"
    recipeName.TextSize = 18
    recipeName.Font = Enum.Font.SourceSansBold
    recipeName.Parent = recipeDetailFrame
    
    -- Description de la recette
    local recipeDescription = Instance.new("TextLabel")
    recipeDescription.Name = "RecipeDescription"
    recipeDescription.Size = UDim2.new(1, 0, 0, 60)
    recipeDescription.Position = UDim2.new(0, 0, 0, 50)
    recipeDescription.BackgroundTransparency = 1
    recipeDescription.TextColor3 = Color3.fromRGB(220, 220, 220)
    recipeDescription.Text = ""
    recipeDescription.TextSize = 14
    recipeDescription.TextWrapped = true
    recipeDescription.TextXAlignment = Enum.TextXAlignment.Left
    recipeDescription.TextYAlignment = Enum.TextYAlignment.Top
    recipeDescription.Font = Enum.Font.SourceSans
    recipeDescription.Parent = recipeDetailFrame
    
    -- Image de l'objet résultat
    local resultImage = Instance.new("ImageLabel")
    resultImage.Name = "ResultImage"
    resultImage.Size = UDim2.new(0, 100, 0, 100)
    resultImage.Position = UDim2.new(0.5, -50, 0, 120)
    resultImage.BackgroundTransparency = 1
    resultImage.Image = ""
    resultImage.Parent = recipeDetailFrame
    
    -- Titre pour les ingrédients
    local ingredientsTitle = Instance.new("TextLabel")
    ingredientsTitle.Name = "IngredientsTitle"
    ingredientsTitle.Size = UDim2.new(1, 0, 0, 30)
    ingredientsTitle.Position = UDim2.new(0, 0, 0, 230)
    ingredientsTitle.BackgroundTransparency = 0.7
    ingredientsTitle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    ingredientsTitle.BorderSizePixel = 0
    ingredientsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    ingredientsTitle.Text = "Ingrédients requis:"
    ingredientsTitle.TextSize = 16
    ingredientsTitle.Font = Enum.Font.SourceSansBold
    ingredientsTitle.Parent = recipeDetailFrame
    
    -- Liste des ingrédients
    local ingredientsList = Instance.new("Frame")
    ingredientsList.Name = "IngredientsList"
    ingredientsList.Size = UDim2.new(1, 0, 0, 120)
    ingredientsList.Position = UDim2.new(0, 0, 0, 260)
    ingredientsList.BackgroundTransparency = 1
    ingredientsList.Parent = recipeDetailFrame
    
    -- Bouton de fabrication
    local craftButton = Instance.new("TextButton")
    craftButton.Name = "CraftButton"
    craftButton.Size = UDim2.new(0, 200, 0, 40)
    craftButton.Position = UDim2.new(0.5, -100, 1, -50)
    craftButton.BackgroundTransparency = 0.5
    craftButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    craftButton.BorderSizePixel = 0
    craftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    craftButton.Text = "Fabriquer"
    craftButton.TextSize = 18
    craftButton.Font = Enum.Font.SourceSansBold
    craftButton.Parent = recipeDetailFrame
    
    -- Arrondir les coins du bouton
    local craftButtonCorner = Instance.new("UICorner")
    craftButtonCorner.CornerRadius = UDim.new(0, 8)
    craftButtonCorner.Parent = craftButton
    
    -- Stocker les références importantes
    self.recipeListFrame = recipeListFrame
    self.recipeDetailFrame = recipeDetailFrame
    self.recipeName = recipeName
    self.recipeDescription = recipeDescription
    self.resultImage = resultImage
    self.ingredientsList = ingredientsList
    self.craftButton = craftButton
    
    -- Ajouter l'interface au joueur
    self.gui.Parent = self.player.PlayerGui
    
    -- Connecter les événements
    closeButton.MouseButton1Click:Connect(function()
        self:ToggleCrafting(false)
    end)
    
    -- Connexion pour la touche d'ouverture de craft (C)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.C then
            self:ToggleCrafting(not self.isOpen)
        end
    end)
    
    -- Connexion pour le bouton de fabrication
    craftButton.MouseButton1Click:Connect(function()
        self:CraftSelectedRecipe()
    end)
    
    return self
end

-- Créer les onglets de catégories
function CraftingUI:CreateCategoryTabs()
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.Size = UDim2.new(1, 0, 0, 30)
    tabsFrame.Position = UDim2.new(0, 0, 0, 45)
    tabsFrame.BackgroundTransparency = 0.7
    tabsFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    tabsFrame.BorderSizePixel = 0
    tabsFrame.Parent = self.craftingFrame
    
    local tabWidth = 100
    local tabPadding = 2
    local startX = 10
    
    -- Créer un bouton pour chaque catégorie
    for i, category in ipairs(self.categories) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = category .. "Tab"
        tabButton.Size = UDim2.new(0, tabWidth, 0, 25)
        tabButton.Position = UDim2.new(0, startX + (i-1) * (tabWidth + tabPadding), 0, 2)
        tabButton.BackgroundTransparency = 0.5
        tabButton.BackgroundColor3 = category == self.selectedCategory and 
                                     Color3.fromRGB(60, 60, 120) or 
                                     Color3.fromRGB(60, 60, 60)
        tabButton.BorderSizePixel = 0
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.Text = self:GetCategoryDisplayName(category)
        tabButton.TextSize = 14
        tabButton.Font = Enum.Font.SourceSansBold
        tabButton.Parent = tabsFrame
        
        -- Arrondir les coins du bouton
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 5)
        tabCorner.Parent = tabButton
        
        -- Connecter l'événement de clic
        tabButton.MouseButton1Click:Connect(function()
            self:SelectCategory(category)
        end)
        
        -- Stocker la référence
        self["tab" .. category] = tabButton
    end
end

-- Obtenir le nom d'affichage d'une catégorie
function CraftingUI:GetCategoryDisplayName(category)
    local displayNames = {
        tools = "Outils",
        weapons = "Armes",
        clothing = "Vêtements",
        building = "Construction",
        furniture = "Mobilier",
        food = "Nourriture",
        stations = "Stations"
    }
    
    return displayNames[category] or category
end

-- Sélectionner une catégorie
function CraftingUI:SelectCategory(category)
    if category == self.selectedCategory then return end
    
    -- Mettre à jour l'apparence des onglets
    for _, cat in ipairs(self.categories) do
        local tabButton = self["tab" .. cat]
        if tabButton then
            tabButton.BackgroundColor3 = cat == category and 
                                        Color3.fromRGB(60, 60, 120) or 
                                        Color3.fromRGB(60, 60, 60)
        end
    end
    
    -- Mettre à jour la catégorie sélectionnée
    self.selectedCategory = category
    
    -- Mettre à jour la liste des recettes
    self:UpdateRecipeList()
end

-- Mettre à jour la liste des recettes
function CraftingUI:UpdateRecipeList()
    -- Effacer la liste existante
    self.recipeListFrame:ClearAllChildren()
    self.recipeListFrames = {}
    
    -- Récupérer les recettes dans la catégorie sélectionnée
    local categoryRecipes = self:GetRecipesByCategory(self.selectedCategory)
    
    -- Créer un élément pour chaque recette
    local yPosition = 5
    local itemHeight = 40
    local padding = 5
    
    for i, recipeData in ipairs(categoryRecipes) do
        local recipeId = recipeData.id
        local recipe = CraftingRecipes[recipeId]
        
        -- Créer un cadre pour la recette
        local recipeFrame = Instance.new("Frame")
        recipeFrame.Name = "Recipe_" .. recipeId
        recipeFrame.Size = UDim2.new(1, -10, 0, itemHeight)
        recipeFrame.Position = UDim2.new(0, 5, 0, yPosition)
        recipeFrame.BackgroundTransparency = 0.5
        recipeFrame.BackgroundColor3 = self:IsRecipeUnlocked(recipeId) and 
                                    Color3.fromRGB(50, 50, 50) or 
                                    Color3.fromRGB(80, 50, 50)
        recipeFrame.BorderSizePixel = 0
        recipeFrame.Parent = self.recipeListFrame
        
        -- Arrondir les coins
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 5)
        frameCorner.Parent = recipeFrame
        
        -- Nom de la recette
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, -10, 1, 0)
        nameLabel.Position = UDim2.new(0, 10, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.Text = recipe.name
        nameLabel.TextSize = 14
        nameLabel.Font = Enum.Font.SourceSansBold
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = recipeFrame
        
        -- Bouton pour sélectionner la recette
        local recipeButton = Instance.new("TextButton")
        recipeButton.Name = "RecipeButton"
        recipeButton.Size = UDim2.new(1, 0, 1, 0)
        recipeButton.BackgroundTransparency = 1
        recipeButton.Text = ""
        recipeButton.Parent = recipeFrame
        
        -- Connecter l'événement du bouton
        recipeButton.MouseButton1Click:Connect(function()
            self:SelectRecipe(recipeId)
        end)
        
        -- Stocker la référence
        self.recipeListFrames[recipeId] = recipeFrame
        
        -- Mettre à jour la position pour le prochain élément
        yPosition = yPosition + itemHeight + padding
    end
    
    -- Mettre à jour la taille du canvas
    self.recipeListFrame.CanvasSize = UDim2.new(0, 0, 0, yPosition)
    
    -- Sélectionner la première recette si disponible
    if #categoryRecipes > 0 then
        self:SelectRecipe(categoryRecipes[1].id)
    else
        self:ClearRecipeDetail()
    end
end

-- Obtenir les recettes par catégorie
function CraftingUI:GetRecipesByCategory(category)
    local result = {}
    
    -- Correspondance entre catégories d'interface et types d'objets
    local categoryMapping = {
        tools = {"tool"},
        weapons = {"weapon"},
        clothing = {"clothing"},
        building = {"building"},
        furniture = {"furniture"},
        food = {"food"},
        stations = {"station"}
    }
    
    local targetCategories = categoryMapping[category] or {}
    
    -- Parcourir toutes les recettes
    for recipeId, recipe in pairs(CraftingRecipes) do
        local resultItemId = recipe.result.id
        local itemType = ItemTypes[resultItemId]
        
        if itemType then
            local itemCategory = itemType.category
            
            -- Vérifier si l'objet correspond à la catégorie sélectionnée
            local matchesCategory = false
            
            for _, targetCategory in ipairs(targetCategories) do
                if itemCategory == targetCategory or 
                   (itemType.toolType and targetCategory == "tool") or
                   (itemType.equipSlot == "weapon" and targetCategory == "weapon") or
                   ((itemType.forgingStation or itemType.smeltingStation or itemType.cookingStation) and targetCategory == "station") then
                    matchesCategory = true
                    break
                end
            end
            
            if matchesCategory or category == "all" then
                table.insert(result, {
                    id = recipeId,
                    name = recipe.name,
                    techLevel = recipe.techLevel
                })
            end
        end
    end
    
    -- Trier par nom
    table.sort(result, function(a, b)
        return a.name < b.name
    end)
    
    return result
end

-- Vérifier si une recette est débloquée
function CraftingUI:IsRecipeUnlocked(recipeId)
    -- Dans l'interface, on affiche toutes les recettes, même celles non débloquées
    -- pour informer le joueur de ce qui est disponible
    if self.unlockedRecipes[recipeId] then
        return true
    end
    
    local recipe = CraftingRecipes[recipeId]
    if not recipe then return false end
    
    -- Les recettes de niveau Stone sont toujours disponibles au début
    return recipe.techLevel == "stone"
end

-- Sélectionner une recette
function CraftingUI:SelectRecipe(recipeId)
    local recipe = CraftingRecipes[recipeId]
    if not recipe then return end
    
    -- Mettre à jour la recette sélectionnée
    self.selectedRecipe = recipeId
    
    -- Mettre à jour l'apparence des éléments de la liste
    for id, frame in pairs(self.recipeListFrames) do
        frame.BackgroundColor3 = id == recipeId and 
                                Color3.fromRGB(60, 60, 120) or 
                                (self:IsRecipeUnlocked(id) and 
                                Color3.fromRGB(50, 50, 50) or 
                                Color3.fromRGB(80, 50, 50))
    end
    
    -- Mettre à jour les détails de la recette
    self:UpdateRecipeDetail(recipeId)
end

-- Mettre à jour les détails d'une recette
function CraftingUI:UpdateRecipeDetail(recipeId)
    local recipe = CraftingRecipes[recipeId]
    if not recipe then return end
    
    -- Mettre à jour le nom
    self.recipeName.Text = recipe.name
    
    -- Mettre à jour la description
    self.recipeDescription.Text = recipe.description or ""
    
    -- Mettre à jour l'image du résultat
    local resultItemId = recipe.result.id
    local itemType = ItemTypes[resultItemId]
    
    if itemType and itemType.model then
        self.resultImage.Image = itemType.model
    else
        self.resultImage.Image = ""
    end
    
    -- Effacer la liste d'ingrédients existante
    for _, child in pairs(self.ingredientsList:GetChildren()) do
        child:Destroy()
    end
    
    -- Créer la liste des ingrédients
    local yPosition = 5
    local itemHeight = 25
    local padding = 5
    
    for itemId, quantity in pairs(recipe.ingredients) do
        local ingredient = ItemTypes[itemId]
        if ingredient then
            -- Cadre pour l'ingrédient
            local ingredientFrame = Instance.new("Frame")
            ingredientFrame.Name = "Ingredient_" .. itemId
            ingredientFrame.Size = UDim2.new(1, -10, 0, itemHeight)
            ingredientFrame.Position = UDim2.new(0, 5, 0, yPosition)
            ingredientFrame.BackgroundTransparency = 0.7
            ingredientFrame.BackgroundColor3 = self:HasEnoughItems(itemId, quantity) and 
                                            Color3.fromRGB(40, 80, 40) or 
                                            Color3.fromRGB(80, 40, 40)
            ingredientFrame.BorderSizePixel = 0
            ingredientFrame.Parent = self.ingredientsList
            
            -- Arrondir les coins
            local frameCorner = Instance.new("UICorner")
            frameCorner.CornerRadius = UDim.new(0, 5)
            frameCorner.Parent = ingredientFrame
            
            -- Icône de l'ingrédient
            local icon = Instance.new("ImageLabel")
            icon.Name = "Icon"
            icon.Size = UDim2.new(0, 20, 0, 20)
            icon.Position = UDim2.new(0, 5, 0.5, -10)
            icon.BackgroundTransparency = 1
            icon.Image = ingredient.model or ""
            icon.Parent = ingredientFrame
            
            -- Nom de l'ingrédient
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.Size = UDim2.new(0.7, -30, 1, 0)
            nameLabel.Position = UDim2.new(0, 30, 0, 0)
            nameLabel.BackgroundTransparency = 1
            nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameLabel.Text = ingredient.name
            nameLabel.TextSize = 14
            nameLabel.Font = Enum.Font.SourceSans
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Parent = ingredientFrame
            
            -- Quantité requise / disponible
            local available = self:CountItemsInInventory(itemId)
            local quantityLabel = Instance.new("TextLabel")
            quantityLabel.Name = "QuantityLabel"
            quantityLabel.Size = UDim2.new(0.3, 0, 1, 0)
            quantityLabel.Position = UDim2.new(0.7, 0, 0, 0)
            quantityLabel.BackgroundTransparency = 1
            quantityLabel.TextColor3 = available >= quantity and 
                                     Color3.fromRGB(150, 255, 150) or 
                                     Color3.fromRGB(255, 150, 150)
            quantityLabel.Text = available .. "/" .. quantity
            quantityLabel.TextSize = 14
            quantityLabel.Font = Enum.Font.SourceSans
            quantityLabel.Parent = ingredientFrame
            
            -- Mettre à jour la position pour le prochain élément
            yPosition = yPosition + itemHeight + padding
        end
    end
    
    -- Mettre à jour l'état du bouton de fabrication
    self:UpdateCraftButton()
end

-- Mettre à jour l'état du bouton de fabrication
function CraftingUI:UpdateCraftButton()
    local recipeId = self.selectedRecipe
    local recipe = CraftingRecipes[recipeId]
    
    if not recipe then
        self.craftButton.Active = false
        self.craftButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        self.craftButton.Text = "Fabriquer"
        return
    end
    
    -- Vérifier si la recette est débloquée
    local isUnlocked = self:IsRecipeUnlocked(recipeId)
    
    -- Vérifier si le joueur a tous les ingrédients nécessaires
    local hasAllIngredients = true
    
    for itemId, quantity in pairs(recipe.ingredients) do
        if not self:HasEnoughItems(itemId, quantity) then
            hasAllIngredients = false
            break
        end
    end
    
    -- Mettre à jour l'apparence et l'état du bouton
    if isUnlocked and hasAllIngredients then
        self.craftButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
        self.craftButton.Active = true
        self.craftButton.Text = "Fabriquer"
    elseif not isUnlocked then
        self.craftButton.BackgroundColor3 = Color3.fromRGB(120, 60, 0)
        self.craftButton.Active = false
        self.craftButton.Text = "Recette verrouillée"
    else
        self.craftButton.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
        self.craftButton.Active = false
        self.craftButton.Text = "Ingrédients insuffisants"
    end
end

-- Effacer les détails de la recette
function CraftingUI:ClearRecipeDetail()
    self.recipeName.Text = "Sélectionnez une recette"
    self.recipeDescription.Text = ""
    self.resultImage.Image = ""
    
    -- Effacer la liste d'ingrédients
    for _, child in pairs(self.ingredientsList:GetChildren()) do
        child:Destroy()
    end
    
    -- Désactiver le bouton de fabrication
    self.craftButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
    self.craftButton.Active = false
    self.craftButton.Text = "Fabriquer"
end

-- Compter le nombre d'un item donné dans l'inventaire
function CraftingUI:CountItemsInInventory(itemId)
    local count = 0
    
    for _, item in pairs(self.inventoryData.items) do
        if item and item.id == itemId then
            count = count + (item.quantity or 1)
        end
    end
    
    return count
end

-- Vérifier si le joueur a assez d'un item donné
function CraftingUI:HasEnoughItems(itemId, quantity)
    return self:CountItemsInInventory(itemId) >= quantity
end

-- Fabriquer la recette sélectionnée
function CraftingUI:CraftSelectedRecipe()
    local recipeId = self.selectedRecipe
    
    if not recipeId or not self.craftButton.Active then return end
    
    -- Dans une implémentation réelle, envoyer une demande au serveur
    -- en utilisant un RemoteEvent
    local events = ReplicatedStorage:FindFirstChild("Events")
    
    if events then
        local playerActionEvent = events:FindFirstChild("PlayerAction")
        if playerActionEvent then
            playerActionEvent:FireServer("craft", recipeId)
            
            -- Jouer un son de fabrication
            local craftSound = Instance.new("Sound")
            craftSound.SoundId = "rbxassetid://12345"  -- À remplacer par un ID réel
            craftSound.Volume = 0.5
            craftSound.Parent = self.player.PlayerGui
            craftSound:Play()
            
            -- Auto-destruction après la lecture
            craftSound.Ended:Connect(function()
                craftSound:Destroy()
            end)
        end
    end
end

-- Mettre à jour les recettes débloquées
function CraftingUI:UpdateRecipes(recipesData)
    self.unlockedRecipes = recipesData or {}
    
    -- Si l'interface est ouverte, mettre à jour la liste des recettes
    if self.isOpen then
        self:UpdateRecipeList()
    end
end

-- Mettre à jour les données d'inventaire
function CraftingUI:UpdateInventory(inventoryData)
    self.inventoryData = inventoryData or { items = {} }
    
    -- Si l'interface est ouverte et qu'une recette est sélectionnée,
    -- mettre à jour les détails de la recette pour refléter les ressources disponibles
    if self.isOpen and self.selectedRecipe then
        self:UpdateRecipeDetail(self.selectedRecipe)
    end
end

-- Ouvrir/fermer l'interface de craft
function CraftingUI:ToggleCrafting(open)
    if open == nil then
        -- Si aucune valeur n'est fournie, basculer l'état actuel
        open = not self.isOpen
    end
    
    self.isOpen = open
    self.gui.Enabled = open
    
    -- Si on ouvre l'interface, mettre à jour la liste des recettes
    if open then
        self:UpdateRecipeList()
    end
end

return CraftingUI
