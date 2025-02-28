-- src/shared/types/ItemData.lua
-- Définition des données des objets dans le jeu

local ItemData = {
    -- Structure de base pour tous les types d'items
    -- Ces valeurs sont les valeurs par défaut si non spécifiées
    DefaultProperties = {
        stackable = false,
        maxStack = 1,
        equipable = false,
        equipSlot = nil,
        durability = nil,
        consumable = false,
        placeable = false,
        techLevel = "stone",
        weight = 1
    },
    
    -- Catégories d'items (utile pour l'organisation dans l'inventaire)
    Categories = {
        MATERIAL = "material",
        TOOL = "tool",
        WEAPON = "weapon",
        ARMOR = "armor",
        FOOD = "food",
        DRINK = "drink",
        BUILDING = "building",
        FURNITURE = "furniture"
    },
    
    -- Définition de tous les items du jeu
    Items = {
        -- Matériaux de base
        stone = {
            name = "Pierre",
            description = "Une pierre ordinaire, utile pour des outils basiques.",
            category = "material",
            stackable = true,
            maxStack = 64,
            model = "", -- ID de l'asset Roblox
            icon = "", -- ID de l'icône 2D
            weight = 2
        },
        
        wood = {
            name = "Bois",
            description = "Un morceau de bois, utilisé pour l'artisanat.",
            category = "material",
            stackable = true,
            maxStack = 64,
            model = "",
            icon = "",
            weight = 1
        },
        
        -- Outils
        stone_pickaxe = {
            name = "Pioche en pierre",
            description = "Un outil pour miner des minerais.",
            category = "tool",
            equipable = true,
            equipSlot = "tool",
            toolType = "pickaxe",
            durability = 100,
            damage = 4,
            gatherMultiplier = {
                stone = 2,
                copper_ore = 1.5,
                tin_ore = 1.5
            },
            model = "",
            icon = "",
            weight = 5,
            techLevel = "stone"
        },
        
        -- Et tous les autres items...
    }
}

-- Fonction pour obtenir les données d'un item par son ID
function ItemData:GetItemData(itemId)
    local itemData = self.Items[itemId]
    
    if not itemData then
        warn("ItemData: Item non trouvé - " .. tostring(itemId))
        return nil
    end
    
    -- Appliquer les propriétés par défaut si non spécifiées
    for prop, defaultValue in pairs(self.DefaultProperties) do
        if itemData[prop] == nil then
            itemData[prop] = defaultValue
        end
    end
    
    return itemData
end

-- Fonction pour obtenir tous les items d'une catégorie
function ItemData:GetItemsByCategory(category)
    local result = {}
    
    for itemId, itemData in pairs(self.Items) do
        if itemData.category == category then
            result[itemId] = itemData
        end
    end
    
    return result
end

-- Fonction pour vérifier si un item est de type spécifique
function ItemData:IsItemOfType(itemId, typeCheck)
    local itemData = self:GetItemData(itemId)
    if not itemData then return false end
    
    return itemData.category == typeCheck
end

-- Fonction pour obtenir tous les items d'un certain niveau technologique
function ItemData:GetItemsByTechLevel(techLevel)
    local result = {}
    
    for itemId, itemData in pairs(self.Items) do
        if itemData.techLevel == techLevel then
            result[itemId] = itemData
        end
    end
    
    return result
end

return ItemData