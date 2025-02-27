-- src/shared/constants/CraftingRecipes.lua

local CraftingRecipes = {
    -- Outils de l'âge de pierre
    ["stone_axe"] = {
        name = "Hache en pierre",
        description = "Un outil primitif pour couper du bois.",
        ingredients = {
            ["stone"] = 3,
            ["wood"] = 2,
            ["fiber"] = 1
        },
        result = {
            id = "stone_axe",
            quantity = 1
        },
        craftTime = 5, -- Temps en secondes
        techLevel = "stone", -- Niveau technologique requis
        requiredStation = nil -- Peut être fabriqué partout
    },
    
    ["stone_pickaxe"] = {
        name = "Pioche en pierre",
        description = "Pour miner des pierres et minerais.",
        ingredients = {
            ["stone"] = 3,
            ["wood"] = 2,
            ["fiber"] = 1
        },
        result = {
            id = "stone_pickaxe",
            quantity = 1
        },
        craftTime = 5,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["stone_spear"] = {
        name = "Lance en pierre",
        description = "Une arme de chasse primitive.",
        ingredients = {
            ["stone"] = 2,
            ["wood"] = 3,
            ["fiber"] = 2
        },
        result = {
            id = "stone_spear",
            quantity = 1
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Vêtements primitifs
    ["fiber_clothes"] = {
        name = "Vêtements en fibre",
        description = "Des vêtements basiques faits de fibres.",
        ingredients = {
            ["fiber"] = 10
        },
        result = {
            id = "fiber_clothes",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Outils en bronze
    ["bronze"] = {
        name = "Bronze",
        description = "Un alliage de cuivre et d'étain.",
        ingredients = {
            ["copper_ore"] = 2,
            ["tin_ore"] = 1
        },
        result = {
            id = "bronze",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "bronze",
        requiredStation = "furnace"
    },
    
    ["bronze_axe"] = {
        name = "Hache en bronze",
        description = "Une hache plus efficace que celle en pierre.",
        ingredients = {
            ["bronze"] = 3,
            ["wood"] = 2
        },
        result = {
            id = "bronze_axe",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "bronze",
        requiredStation = "anvil"
    },
    
    ["bronze_pickaxe"] = {
        name = "Pioche en bronze",
        description = "Une pioche plus durable pour miner.",
        ingredients = {
            ["bronze"] = 3,
            ["wood"] = 2
        },
        result = {
            id = "bronze_pickaxe",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "bronze",
        requiredStation = "anvil"
    },
    
    -- Outils en fer
    ["iron"] = {
        name = "Fer",
        description = "Du minerai de fer raffiné.",
        ingredients = {
            ["iron_ore"] = 2
        },
        result = {
            id = "iron",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "iron",
        requiredStation = "furnace"
    },
    
    ["iron_axe"] = {
        name = "Hache en fer",
        description = "Une hache robuste et efficace.",
        ingredients = {
            ["iron"] = 3,
            ["wood"] = 2
        },
        result = {
            id = "iron_axe",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    ["iron_pickaxe"] = {
        name = "Pioche en fer",
        description = "Une pioche puissante pour miner tous types de minerais.",
        ingredients = {
            ["iron"] = 3,
            ["wood"] = 2
        },
        result = {
            id = "iron_pickaxe",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    -- Matériaux de construction
    ["wooden_plank"] = {
        name = "Planche en bois",
        description = "Un matériau de construction de base.",
        ingredients = {
            ["wood"] = 1
        },
        result = {
            id = "wooden_plank",
            quantity = 4
        },
        craftTime = 2,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["brick"] = {
        name = "Brique",
        description = "Un bloc de construction solide.",
        ingredients = {
            ["clay"] = 2
        },
        result = {
            id = "brick",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "stone",
        requiredStation = "furnace"
    },
    
    -- Mobilier
    ["campfire"] = {
        name = "Feu de camp",
        description = "Fournit chaleur et lumière, permet de cuire des aliments.",
        ingredients = {
            ["stone"] = 8,
            ["wood"] = 4
        },
        result = {
            id = "campfire",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["wooden_bed"] = {
        name = "Lit en bois",
        description = "Un lit simple pour dormir et récupérer de l'énergie.",
        ingredients = {
            ["wooden_plank"] = 6,
            ["fiber_clothes"] = 1
        },
        result = {
            id = "wooden_bed",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["wooden_table"] = {
        name = "Table en bois",
        description = "Une table simple.",
        ingredients = {
            ["wooden_plank"] = 4
        },
        result = {
            id = "wooden_table",
            quantity = 1
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["wooden_chair"] = {
        name = "Chaise en bois",
        description = "Une chaise simple.",
        ingredients = {
            ["wooden_plank"] = 3
        },
        result = {
            id = "wooden_chair",
            quantity = 1
        },
        craftTime = 6,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Nourriture
    ["cooked_meat"] = {
        name = "Viande cuite",
        description = "De la viande cuite, plus nourrissante que crue.",
        ingredients = {
            ["raw_meat"] = 1
        },
        result = {
            id = "cooked_meat",
            quantity = 1
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = "campfire"
    },
    
    ["bread"] = {
        name = "Pain",
        description = "Du pain fraîchement cuit.",
        ingredients = {
            ["flour"] = 2,
            ["water_container"] = 1
        },
        result = {
            id = "bread",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "stone",
        requiredStation = "campfire"
    },
    
    -- Stations de craft
    ["furnace"] = {
        name = "Four",
        description = "Permet de fondre des métaux et cuire des briques.",
        ingredients = {
            ["stone"] = 20,
            ["clay"] = 5
        },
        result = {
            id = "furnace",
            quantity = 1
        },
        craftTime = 30,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["anvil"] = {
        name = "Enclume",
        description = "Permet de forger des outils en métal.",
        ingredients = {
            ["stone"] = 10,
            ["bronze"] = 5
        },
        result = {
            id = "anvil",
            quantity = 1
        },
        craftTime = 40,
        techLevel = "bronze",
        requiredStation = nil
    },
    
    ["loom"] = {
        name = "Métier à tisser",
        description = "Permet de créer des vêtements plus élaborés.",
        ingredients = {
            ["wooden_plank"] = 10,
            ["fiber"] = 15
        },
        result = {
            id = "loom",
            quantity = 1
        },
        craftTime = 25,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Autres recettes pourront être ajoutées ici...
    -- Environ 250 recettes sont mentionnées dans le cahier des charges
}

return CraftingRecipes