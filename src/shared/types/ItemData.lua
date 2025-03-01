--[[
    ItemData.lua
    
    Module définissant tous les types d'objets et leurs propriétés dans le jeu The Beginning.
    Ce module centralise les informations sur les objets pour une consistance à travers le jeu.
    
    Structure:
    - Propriétés par défaut pour tous les objets
    - Catégories d'objets
    - Rareté des objets
    - Fonctions utilitaires pour accéder aux données
    - Définition complète de tous les objets du jeu
]]

local ItemData = {}

-- Constantes globales
ItemData.MAX_STACK_SIZE = 64
ItemData.MAX_DURABILITY = 1000

-- Structure de base pour tous les types d'items
-- Ces valeurs sont les valeurs par défaut si non spécifiées
ItemData.DefaultProperties = {
    stackable = false,       -- Si l'objet peut être empilé
    maxStack = 1,            -- Quantité max par pile si stackable
    equipable = false,       -- Si l'objet peut être équipé
    equipSlot = nil,         -- Emplacement d'équipement ("tool", "head", "body", etc.)
    durability = nil,        -- Points de durabilité (nil = indestructible)
    consumable = false,      -- Si l'objet peut être consommé
    placeable = false,       -- Si l'objet peut être placé dans le monde
    weight = 1,              -- Poids en unités d'inventaire
    rarity = "common",       -- Rareté de l'objet
    value = 1,               -- Valeur de base pour commerce/vente
    techLevel = "stone",     -- Niveau technologique minimal requis
    model = "",              -- Chemin vers le modèle 3D
    icon = "",               -- Chemin vers l'icône 2D
    animations = {},         -- Animations associées (utilisation, équipement, etc.)
    sounds = {}              -- Sons associés (utilisation, équipement, etc.)
}

-- Catégories d'objets (pour filtrage et organisation)
ItemData.Categories = {
    MATERIAL = "material",       -- Matières premières
    TOOL = "tool",               -- Outils
    WEAPON = "weapon",           -- Armes
    ARMOR = "armor",             -- Équipement de protection
    CLOTHING = "clothing",       -- Vêtements
    FOOD = "food",               -- Nourriture
    DRINK = "drink",             -- Boissons
    BUILDING = "building",       -- Éléments de construction
    FURNITURE = "furniture",     -- Mobilier
    CONTAINER = "container",     -- Conteneurs
    STATION = "station",         -- Stations d'artisanat
    SEED = "seed",               -- Graines
    RESOURCE = "resource",       -- Ressources naturelles
    JEWELRY = "jewelry",         -- Bijoux et objets précieux
    MEDICINE = "medicine",       -- Remèdes et médicaments
    TRIBAL = "tribal"            -- Objets tribaux et cérémoniels
}

-- Niveaux de rareté
ItemData.Rarity = {
    COMMON = {
        id = "common",
        name = "Commun",
        color = Color3.fromRGB(255, 255, 255),
        value_multiplier = 1
    },
    UNCOMMON = {
        id = "uncommon",
        name = "Peu commun",
        color = Color3.fromRGB(100, 255, 100),
        value_multiplier = 2
    },
    RARE = {
        id = "rare",
        name = "Rare",
        color = Color3.fromRGB(100, 100, 255),
        value_multiplier = 5
    },
    EPIC = {
        id = "epic",
        name = "Épique",
        color = Color3.fromRGB(200, 100, 255),
        value_multiplier = 10
    },
    LEGENDARY = {
        id = "legendary",
        name = "Légendaire",
        color = Color3.fromRGB(255, 200, 0),
        value_multiplier = 25
    },
    ARTIFACT = {
        id = "artifact",
        name = "Artéfact",
        color = Color3.fromRGB(255, 100, 100),
        value_multiplier = 50
    }
}

-- Niveaux technologiques
ItemData.TechLevels = {
    STONE = {
        id = "stone",
        name = "Âge de pierre",
        order = 1
    },
    BRONZE = {
        id = "bronze",
        name = "Âge du bronze",
        order = 2
    },
    IRON = {
        id = "iron",
        name = "Âge du fer",
        order = 3
    },
    GOLD = {
        id = "gold",
        name = "Âge d'or",
        order = 4
    }
}

-- Cache pour les données d'objets calculées
local calculatedItemDataCache = {}

-- Fonction pour obtenir les données d'un item par son ID
function ItemData:GetItemData(itemId)
    -- Vérifier si les données calculées sont déjà en cache
    if calculatedItemDataCache[itemId] then
        return calculatedItemDataCache[itemId]
    end
    
    local itemData = self.Items[itemId]
    
    if not itemData then
        warn("ItemData: Item non trouvé - " .. tostring(itemId))
        return nil
    end
    
    -- Créer une copie profonde pour éviter de modifier l'original
    local resultData = {}
    for key, value in pairs(itemData) do
        if type(value) == "table" then
            resultData[key] = table.clone(value)
        else
            resultData[key] = value
        end
    end
    
    -- Appliquer les propriétés par défaut si non spécifiées
    for prop, defaultValue in pairs(self.DefaultProperties) do
        if resultData[prop] == nil then
            resultData[prop] = defaultValue
        end
    end
    
    -- Ajouter l'ID de l'objet aux données
    resultData.id = itemId
    
    -- Mettre en cache pour les futurs accès
    calculatedItemDataCache[itemId] = resultData
    
    return resultData
end

-- Fonction pour obtenir tous les items d'une catégorie
function ItemData:GetItemsByCategory(category)
    local result = {}
    
    for itemId, itemData in pairs(self.Items) do
        if itemData.category == category then
            result[itemId] = self:GetItemData(itemId)
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
            result[itemId] = self:GetItemData(itemId)
        end
    end
    
    return result
end

-- Fonction pour obtenir la couleur de rareté d'un objet
function ItemData:GetRarityColor(itemId)
    local itemData = self:GetItemData(itemId)
    if not itemData then return Color3.fromRGB(255, 255, 255) end
    
    local rarityInfo = self.Rarity[string.upper(itemData.rarity)] or self.Rarity.COMMON
    return rarityInfo.color
end

-- Fonction pour obtenir la valeur marchande d'un objet
function ItemData:GetItemValue(itemId, quality)
    local itemData = self:GetItemData(itemId)
    if not itemData then return 1 end
    
    local baseValue = itemData.value or 1
    local rarityMultiplier = 1
    
    if itemData.rarity then
        local rarityInfo = self.Rarity[string.upper(itemData.rarity)] or self.Rarity.COMMON
        rarityMultiplier = rarityInfo.value_multiplier
    end
    
    -- Facteur de qualité (optionnel, pour les objets avec différentes qualités)
    quality = quality or 1
    
    return math.floor(baseValue * rarityMultiplier * quality)
end

-- Fonction pour calculer la durabilité réelle en tenant compte du matériau
function ItemData:CalculateMaxDurability(itemId)
    local itemData = self:GetItemData(itemId)
    if not itemData or not itemData.durability then return nil end
    
    local baseDurability = itemData.durability
    local materialMultiplier = 1
    
    -- Modificateurs selon le niveau technologique
    if itemData.techLevel == "bronze" then
        materialMultiplier = 2
    elseif itemData.techLevel == "iron" then
        materialMultiplier = 3
    elseif itemData.techLevel == "gold" then
        materialMultiplier = 1.5  -- L'or est plus précieux mais moins durable
    end
    
    return math.floor(baseDurability * materialMultiplier)
end

-- Fonction pour vérifier si un objet peut être utilisé à un niveau technologique donné
function ItemData:CanUseAtTechLevel(itemId, playerTechLevel)
    local itemData = self:GetItemData(itemId)
    if not itemData then return false end
    
    local techLevelOrder = {
        stone = 1,
        bronze = 2,
        iron = 3,
        gold = 4
    }
    
    local itemTechLevel = itemData.techLevel or "stone"
    local playerLevel = techLevelOrder[playerTechLevel] or 1
    local requiredLevel = techLevelOrder[itemTechLevel] or 1
    
    return playerLevel >= requiredLevel
end

-- Fonction pour nettoyer le cache (utile après des modifications de données)
function ItemData:ClearCache()
    calculatedItemDataCache = {}
end

-- Définition complète de tous les objets du jeu
ItemData.Items = {
    -- ============================
    -- MATÉRIAUX DE BASE
    -- ============================
    
    ["stone"] = {
        name = "Pierre",
        description = "Une pierre ordinaire, utile pour des outils basiques.",
        category = "material",
        stackable = true,
        maxStack = 64,
        icon = "rbxassetid://12345600",
        model = "rbxassetid://12345650",
        weight = 2
    },
    
    ["wood"] = {
        name = "Bois",
        description = "Un morceau de bois, utilisé pour l'artisanat.",
        category = "material",
        stackable = true,
        maxStack = 64,
        icon = "rbxassetid://12345601",
        model = "rbxassetid://12345651",
        weight = 1
    },
    
    ["fiber"] = {
        name = "Fibre",
        description = "Des fibres végétales, utilisées pour tisser des cordes.",
        category = "material",
        stackable = true,
        maxStack = 64,
        icon = "rbxassetid://12345602",
        model = "rbxassetid://12345652",
        weight = 0.5
    },
    
    ["clay"] = {
        name = "Argile",
        description = "De l'argile utilisée pour fabriquer de la poterie.",
        category = "material",
        stackable = true,
        maxStack = 64,
        icon = "rbxassetid://12345603",
        model = "rbxassetid://12345653",
        weight = 1.5
    },
    
    ["bone"] = {
        name = "Os",
        description = "Des os qui peuvent être utilisés pour fabriquer des outils.",
        category = "material",
        stackable = true,
        maxStack = 32,
        icon = "rbxassetid://12345604",
        model = "rbxassetid://12345654",
        weight = 0.8
    },
    
    ["flint"] = {
        name = "Silex",
        description = "Une pierre dure utilisée pour faire du feu ou des outils tranchants.",
        category = "material",
        stackable = true,
        maxStack = 32,
        icon = "rbxassetid://12345605",
        model = "rbxassetid://12345655",
        weight = 0.5
    },
    
    ["leather"] = {
        name = "Cuir",
        description = "Du cuir tanné à partir de peaux d'animaux.",
        category = "material",
        stackable = true,
        maxStack = 16,
        icon = "rbxassetid://12345606",
        model = "rbxassetid://12345656",
        weight = 0.7,
        value = 5
    },
    
    ["animal_hide"] = {
        name = "Peau d'animal",
        description = "Une peau brute qui peut être tannée pour faire du cuir.",
        category = "material",
        stackable = true,
        maxStack = 16,
        icon = "rbxassetid://12345607",
        model = "rbxassetid://12345657",
        weight = 1,
        value = 3
    },
    
    ["fur"] = {
        name = "Fourrure",
        description = "Une fourrure douce et chaude provenant d'animaux.",
        category = "material",
        stackable = true,
        maxStack = 16,
        icon = "rbxassetid://12345608",
        model = "rbxassetid://12345658",
        weight = 0.8,
        value = 6
    },
    
    ["rope"] = {
        name = "Corde",
        description = "Une corde solide fabriquée à partir de fibres.",
        category = "material",
        stackable = true,
        maxStack = 16,
        icon = "rbxassetid://12345609",
        model = "rbxassetid://12345659",
        weight = 0.6,
        value = 3
    },
    
    ["charcoal"] = {
        name = "Charbon de bois",
        description = "Utilisé comme combustible ou pour la purification.",
        category = "material",
        stackable = true,
        maxStack = 32,
        icon = "rbxassetid://12345610",
        model = "rbxassetid://12345660",
        weight = 0.5,
        value = 2
    },
    
    -- ============================
    -- MINERAIS
    -- ============================
    
    ["copper_ore"] = {
        name = "Minerai de cuivre",
        description = "Peut être fondu pour obtenir du bronze avec de l'étain.",
        category = "material",
        stackable = true,
        maxStack = 32,
        icon = "rbxassetid://12345611",
        model = "rbxassetid://12345661",
        weight = 3,
        value = 5,
        techLevel = "stone"
    },
    
    ["tin_ore"] = {
        name = "Minerai d'étain",
        description = "Mélangé au cuivre pour faire du bronze.",
        category = "material",
        stackable = true,
        maxStack = 32,
        icon = "rbxassetid://12345612",
        model = "rbxassetid://12345662",
        weight = 3,
        value = 5,
        techLevel = "stone"
    },
    
    ["iron_ore"] = {
        name = "Minerai de fer",
        description = "Peut être fondu pour obtenir du fer.",
        category = "material",
        stackable = true,
        maxStack = 32,
        icon = "rbxassetid://12345613",
        model = "rbxassetid://12345663",
        weight = 4,
        value = 8,
        techLevel = "bronze"
    },
    
    ["gold_ore"] = {
        name = "Minerai d'or",
        description = "Un métal précieux et malléable.",
        category = "material",
        stackable = true,
        maxStack = 16,
        icon = "rbxassetid://12345614",
        model = "rbxassetid://12345664",
        weight = 5,
        value = 20,
        rarity = "uncommon",
        techLevel = "iron"
    },
    
    -- ============================
    -- MÉTAUX RAFFINÉS
    -- ============================
    
    ["bronze"] = {
        name = "Bronze",
        description = "Un alliage de cuivre et d'étain.",
        category = "material",
        stackable = true,
        maxStack = 16,
        icon = "rbxassetid://12345615",
        model = "rbxassetid://12345665",
        weight = 2,
        value = 12,
        techLevel = "bronze"
    },
    
    ["iron"] = {
        name = "Fer",
        description = "Un métal solide pour fabriquer des outils et armes.",
        category = "material",
        stackable = true,
        maxStack = 16,
        icon = "rbxassetid://12345616",
        model = "rbxassetid://12345666",
        weight = 3,
        value = 15,
        techLevel = "iron"
    },
    
    ["gold"] = {
        name = "Or",
        description = "Un métal précieux utilisé pour la décoration et les bijoux.",
        category = "material",
        stackable = true,
        maxStack = 16,
        icon = "rbxassetid://12345617",
        model = "rbxassetid://12345667",
        weight = 4,
        value = 40,
        rarity = "uncommon",
        techLevel = "gold"
    },
    
    -- ============================
    -- OUTILS DE L'ÂGE DE PIERRE
    -- ============================
    
    ["stone_axe"] = {
        name = "Hache en pierre",
        description = "Un outil primitif pour couper du bois.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "axe",
        durability = 100,
        damage = 5,
        icon = "rbxassetid://12345618",
        model = "rbxassetid://12345668",
        weight = 3,
        value = 10,
        techLevel = "stone",
        gatherMultiplier = {
            ["wood"] = 2 -- Récolte 2x plus de bois
        }
    },
    
    ["stone_pickaxe"] = {
        name = "Pioche en pierre",
        description = "Un outil pour miner des minerais.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "pickaxe",
        durability = 100,
        damage = 4,
        icon = "rbxassetid://12345619",
        model = "rbxassetid://12345669",
        weight = 3,
        value = 10,
        techLevel = "stone",
        gatherMultiplier = {
            ["stone"] = 2,
            ["copper_ore"] = 1.5,
            ["tin_ore"] = 1.5
        }
    },
    
    ["stone_spear"] = {
        name = "Lance en pierre",
        description = "Une arme primitive pour chasser.",
        category = "weapon",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "weapon",
        durability = 80,
        damage = 8,
        icon = "rbxassetid://12345620",
        model = "rbxassetid://12345670",
        weight = 2,
        value = 15,
        techLevel = "stone"
    },
    
    ["stone_hammer"] = {
        name = "Marteau en pierre",
        description = "Un outil basique pour la construction.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "hammer",
        durability = 120,
        damage = 5,
        icon = "rbxassetid://12345621",
        model = "rbxassetid://12345671",
        weight = 3,
        value = 12,
        techLevel = "stone"
    },
    
    ["bone_knife"] = {
        name = "Couteau en os",
        description = "Un outil tranchant fait à partir d'os.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "knife",
        durability = 80,
        damage = 4,
        icon = "rbxassetid://12345622",
        model = "rbxassetid://12345672",
        weight = 1,
        value = 8,
        techLevel = "stone"
    },
    
    ["fishing_rod"] = {
        name = "Canne à pêche",
        description = "Pour attraper des poissons dans l'eau.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "fishing",
        durability = 100,
        icon = "rbxassetid://12345623",
        model = "rbxassetid://12345673",
        weight = 2,
        value = 15,
        techLevel = "stone"
    },
    
    ["wooden_bow"] = {
        name = "Arc en bois",
        description = "Une arme de chasse à distance.",
        category = "weapon",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "bow",
        durability = 120,
        damage = 6,
        icon = "rbxassetid://12345624",
        model = "rbxassetid://12345674",
        weight = 2,
        value = 18,
        techLevel = "stone",
        ammo = "arrow"
    },
    
    ["arrow"] = {
        name = "Flèche",
        description = "Munition pour l'arc.",
        category = "ammo",
        stackable = true,
        maxStack = 24,
        damage = 4,
        icon = "rbxassetid://12345625",
        model = "rbxassetid://12345675",
        weight = 0.1,
        value = 1,
        techLevel = "stone"
    },
    
    -- ============================
    -- OUTILS EN BRONZE
    -- ============================
    
    ["bronze_axe"] = {
        name = "Hache en bronze",
        description = "Une hache efficace en bronze.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "axe",
        durability = 200,
        damage = 8,
        icon = "rbxassetid://12345626",
        model = "rbxassetid://12345676",
        weight = 4,
        value = 25,
        techLevel = "bronze",
        gatherMultiplier = {
            ["wood"] = 3
        }
    },
    
    ["bronze_pickaxe"] = {
        name = "Pioche en bronze",
        description = "Une pioche solide pour miner.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "pickaxe",
        durability = 200,
        damage = 7,
        icon = "rbxassetid://12345627",
        model = "rbxassetid://12345677",
        weight = 4,
        value = 25,
        techLevel = "bronze",
        gatherMultiplier = {
            ["stone"] = 3,
            ["copper_ore"] = 2,
            ["tin_ore"] = 2,
            ["iron_ore"] = 1.5
        }
    },
    
    ["bronze_sword"] = {
        name = "Épée en bronze",
        description = "Une arme tranchante efficace.",
        category = "weapon",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "weapon",
        durability = 200,
        damage = 12,
        icon = "rbxassetid://12345628",
        model = "rbxassetid://12345678",
        weight = 3,
        value = 35,
        techLevel = "bronze"
    },
    
    ["bronze_shield"] = {
        name = "Bouclier en bronze",
        description = "Protection efficace contre les attaques.",
        category = "armor",
        stackable = false,
        equipable = true,
        equipSlot = "offhand",
        durability = 250,
        defenseBonus = 10,
        icon = "rbxassetid://12345629",
        model = "rbxassetid://12345679",
        weight = 5,
        value = 30,
        techLevel = "bronze"
    },
    
    ["bronze_hoe"] = {
        name = "Houe en bronze",
        description = "Pour cultiver la terre.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "hoe",
        durability = 150,
        icon = "rbxassetid://12345630",
        model = "rbxassetid://12345680",
        weight = 3,
        value = 20,
        techLevel = "bronze"
    },
    
    -- ============================
    -- OUTILS EN FER
    -- ============================
    
    ["iron_axe"] = {
        name = "Hache en fer",
        description = "Une hache puissante pour couper du bois rapidement.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "axe",
        durability = 400,
        damage = 12,
        icon = "rbxassetid://12345631",
        model = "rbxassetid://12345681",
        weight = 5,
        value = 40,
        techLevel = "iron",
        gatherMultiplier = {
            ["wood"] = 4
        }
    },
    
    ["iron_pickaxe"] = {
        name = "Pioche en fer",
        description = "Une pioche robuste qui peut miner tous les types de minerais.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "pickaxe",
        durability = 400,
        damage = 10,
        icon = "rbxassetid://12345632",
        model = "rbxassetid://12345682",
        weight = 5,
        value = 40,
        techLevel = "iron",
        gatherMultiplier = {
            ["stone"] = 4,
            ["copper_ore"] = 3,
            ["tin_ore"] = 3,
            ["iron_ore"] = 2,
            ["gold_ore"] = 2
        }
    },
    
    ["iron_sword"] = {
        name = "Épée en fer",
        description = "Une arme redoutable, plus puissante que l'épée en bronze.",
        category = "weapon",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "weapon",
        durability = 400,
        damage = 16,
        icon = "rbxassetid://12345633",
        model = "rbxassetid://12345683",
        weight = 4,
        value = 50,
        techLevel = "iron"
    },
    
    ["iron_shield"] = {
        name = "Bouclier en fer",
        description = "Offre une excellente protection contre les attaques.",
        category = "armor",
        stackable = false,
        equipable = true,
        equipSlot = "offhand",
        durability = 450,
        defenseBonus = 15,
        icon = "rbxassetid://12345634",
        model = "rbxassetid://12345684",
        weight = 6,
        value = 45,
        techLevel = "iron"
    },
    
    ["iron_helmet"] = {
        name = "Casque en fer",
        description = "Protège efficacement la tête.",
        category = "armor",
        stackable = false,
        equipable = true,
        equipSlot = "head",
        durability = 300,
        defenseBonus = 10,
        temperatureModifier = 5,
        icon = "rbxassetid://12345635",
        model = "rbxassetid://12345685",
        weight = 4,
        value = 35,
        techLevel = "iron"
    },
    
    ["iron_chestplate"] = {
        name = "Plastron en fer",
        description = "Protège efficacement le torse.",
        category = "armor",
        stackable = false,
        equipable = true,
        equipSlot = "body",
        durability = 400,
        defenseBonus = 20,
        temperatureModifier = 8,
        icon = "rbxassetid://12345636",
        model = "rbxassetid://12345686",
        weight = 8,
        value = 50,
        techLevel = "iron"
    },
    
    ["iron_leggings"] = {
        name = "Jambières en fer",
        description = "Protège efficacement les jambes.",
        category = "armor",
        stackable = false,
        equipable = true,
        equipSlot = "legs",
        durability = 350,
        defenseBonus = 15,
        temperatureModifier = 6,
        icon = "rbxassetid://12345637",
        model = "rbxassetid://12345687",
        weight = 6,
        value = 40,
        techLevel = "iron"
    },
    
    ["iron_boots"] = {
        name = "Bottes en fer",
        description = "Protège efficacement les pieds.",
        category = "armor",
        stackable = false,
        equipable = true,
        equipSlot = "feet",
        durability
