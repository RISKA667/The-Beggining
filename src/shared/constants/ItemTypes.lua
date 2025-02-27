-- src/shared/constants/ItemTypes.lua

local ItemTypes = {
    -- Matériaux de base
    ["stone"] = {
        name = "Pierre",
        description = "Une pierre ordinaire, utile pour des outils basiques.",
        category = "material",
        stackable = true,
        maxStack = 64,
        equipable = false,
        model = "rbxassetid://12345678" -- À remplacer par l'ID réel du modèle/image
    },
    
    ["wood"] = {
        name = "Bois",
        description = "Un morceau de bois, utilisé pour l'artisanat.",
        category = "material",
        stackable = true,
        maxStack = 64,
        equipable = false,
        model = "rbxassetid://12345679"
    },
    
    ["fiber"] = {
        name = "Fibre",
        description = "Des fibres végétales, utilisées pour tisser des cordes.",
        category = "material",
        stackable = true,
        maxStack = 64,
        equipable = false,
        model = "rbxassetid://12345680"
    },
    
    ["clay"] = {
        name = "Argile",
        description = "De l'argile utilisée pour fabriquer de la poterie.",
        category = "material",
        stackable = true,
        maxStack = 64,
        equipable = false,
        model = "rbxassetid://12345681"
    },
    
    -- Minerais
    ["copper_ore"] = {
        name = "Minerai de cuivre",
        description = "Peut être fondu pour obtenir du bronze.",
        category = "material",
        stackable = true,
        maxStack = 32,
        equipable = false,
        model = "rbxassetid://12345682"
    },
    
    ["tin_ore"] = {
        name = "Minerai d'étain",
        description = "Mélangé au cuivre pour faire du bronze.",
        category = "material",
        stackable = true,
        maxStack = 32,
        equipable = false,
        model = "rbxassetid://12345683"
    },
    
    ["iron_ore"] = {
        name = "Minerai de fer",
        description = "Peut être fondu pour obtenir du fer.",
        category = "material",
        stackable = true,
        maxStack = 32,
        equipable = false,
        model = "rbxassetid://12345684"
    },
    
    ["gold_ore"] = {
        name = "Minerai d'or",
        description = "Un métal précieux et malléable.",
        category = "material",
        stackable = true,
        maxStack = 16,
        equipable = false,
        model = "rbxassetid://12345685"
    },
    
    -- Métaux raffinés
    ["bronze"] = {
        name = "Bronze",
        description = "Un alliage de cuivre et d'étain.",
        category = "material",
        stackable = true,
        maxStack = 16,
        equipable = false,
        model = "rbxassetid://12345686"
    },
    
    ["iron"] = {
        name = "Fer",
        description = "Un métal solide pour fabriquer des outils et armes.",
        category = "material",
        stackable = true,
        maxStack = 16,
        equipable = false,
        model = "rbxassetid://12345687"
    },
    
    ["gold"] = {
        name = "Or",
        description = "Un métal précieux utilisé pour la décoration et les bijoux.",
        category = "material",
        stackable = true,
        maxStack = 16,
        equipable = false,
        model = "rbxassetid://12345688"
    },
    
    -- Outils de l'âge de pierre
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
        gatherMultiplier = {
            ["wood"] = 2 -- Récolte 2x plus de bois
        },
        model = "rbxassetid://12345689"
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
        gatherMultiplier = {
            ["stone"] = 2,
            ["copper_ore"] = 1.5,
            ["tin_ore"] = 1.5
        },
        model = "rbxassetid://12345690"
    },
    
    ["stone_spear"] = {
        name = "Lance en pierre",
        description = "Une arme primitive pour chasser.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "weapon",
        durability = 80,
        damage = 8,
        model = "rbxassetid://12345691"
    },
    
    -- Outils en bronze
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
        gatherMultiplier = {
            ["wood"] = 3
        },
        model = "rbxassetid://12345692"
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
        gatherMultiplier = {
            ["stone"] = 3,
            ["copper_ore"] = 2,
            ["tin_ore"] = 2,
            ["iron_ore"] = 1.5
        },
        model = "rbxassetid://12345693"
    },
    
    -- Outils en fer
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
        gatherMultiplier = {
            ["wood"] = 4
        },
        model = "rbxassetid://12345694"
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
        gatherMultiplier = {
            ["stone"] = 4,
            ["copper_ore"] = 3,
            ["tin_ore"] = 3,
            ["iron_ore"] = 2,
            ["gold_ore"] = 2
        },
        model = "rbxassetid://12345695"
    },
    
    -- Vêtements
    ["fiber_clothes"] = {
        name = "Vêtements en fibre",
        description = "Des vêtements primitifs faits de fibres végétales.",
        category = "clothing",
        stackable = false,
        equipable = true,
        equipSlot = "body",
        temperatureModifier = 5, -- +5 résistance au froid
        model = "rbxassetid://12345696"
    },
    
    ["leather_clothes"] = {
        name = "Vêtements en cuir",
        description = "Des vêtements robustes en cuir d'animal.",
        category = "clothing",
        stackable = false,
        equipable = true,
        equipSlot = "body",
        temperatureModifier = 10, -- +10 résistance au froid
        model = "rbxassetid://12345697"
    },
    
    ["fur_coat"] = {
        name = "Manteau de fourrure",
        description = "Un manteau chaud pour les environnements froids.",
        category = "clothing",
        stackable = false,
        equipable = true,
        equipSlot = "body",
        temperatureModifier = 20, -- +20 résistance au froid
        model = "rbxassetid://12345698"
    },
    
    -- Nourriture
    ["berries"] = {
        name = "Baies",
        description = "Des baies sauvages comestibles.",
        category = "food",
        stackable = true,
        maxStack = 16,
        foodValue = 10, -- Restaure 10 points de faim
        spoilTime = 1800, -- 30 minutes avant de pourrir
        model = "rbxassetid://12345699"
    },
    
    ["cooked_meat"] = {
        name = "Viande cuite",
        description = "De la viande cuite sur un feu.",
        category = "food",
        stackable = true,
        maxStack = 8,
        foodValue = 30,
        spoilTime = 3600, -- 1 heure avant de pourrir
        model = "rbxassetid://12345700"
    },
    
    ["bread"] = {
        name = "Pain",
        description = "Du pain cuit à partir de graines récoltées.",
        category = "food",
        stackable = true,
        maxStack = 8,
        foodValue = 25,
        spoilTime = 7200, -- 2 heures avant de pourrir
        model = "rbxassetid://12345701"
    },
    
    -- Boissons
    ["water_container"] = {
        name = "Eau",
        description = "Un conteneur rempli d'eau potable.",
        category = "drink",
        stackable = false,
        drinkValue = 40, -- Restaure 40 points de soif
        model = "rbxassetid://12345702"
    },
    
    -- Matériaux de construction
    ["wooden_plank"] = {
        name = "Planche en bois",
        description = "Un matériau de base pour la construction.",
        category = "building",
        stackable = true,
        maxStack = 64,
        model = "rbxassetid://12345703"
    },
    
    ["brick"] = {
        name = "Brique",
        description = "Une brique solide pour des constructions durables.",
        category = "building",
        stackable = true,
        maxStack = 64,
        model = "rbxassetid://12345704"
    },
    
    -- Mobilier
    ["wooden_bed"] = {
        name = "Lit en bois",
        description = "Un lit simple pour dormir.",
        category = "furniture",
        stackable = false,
        sleepQuality = 1, -- Taux de récupération d'énergie
        model = "rbxassetid://12345705"
    },
    
    ["wooden_table"] = {
        name = "Table en bois",
        description = "Une table simple.",
        category = "furniture",
        stackable = false,
        model = "rbxassetid://12345706"
    },
    
    ["wooden_chair"] = {
        name = "Chaise en bois",
        description = "Une chaise simple.",
        category = "furniture",
        stackable = false,
        model = "rbxassetid://12345707"
    },
    
    ["campfire"] = {
        name = "Feu de camp",
        description = "Fournit chaleur et lumière, permet de cuire des aliments.",
        category = "furniture",
        stackable = false,
        heatSource = true,
        heatRadius = 10,
        heatIntensity = 15,
        model = "rbxassetid://12345708"
    }
    
    -- D'autres objets peuvent être ajoutés ici...
}

return ItemTypes