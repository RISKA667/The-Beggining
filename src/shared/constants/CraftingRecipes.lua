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
    
    -- NOUVELLES RECETTES AJOUTÉES --
    
    -- Outils et armes de base supplémentaires
    ["stone_hammer"] = {
        name = "Marteau en pierre",
        description = "Un outil basique pour la construction.",
        ingredients = {
            ["stone"] = 3,
            ["wood"] = 1,
            ["fiber"] = 2
        },
        result = {
            id = "stone_hammer",
            quantity = 1
        },
        craftTime = 6,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["bone_knife"] = {
        name = "Couteau en os",
        description = "Un outil tranchant fait à partir d'os.",
        ingredients = {
            ["bone"] = 2,
            ["fiber"] = 1
        },
        result = {
            id = "bone_knife",
            quantity = 1
        },
        craftTime = 5,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["fishing_rod"] = {
        name = "Canne à pêche",
        description = "Pour attraper des poissons.",
        ingredients = {
            ["wood"] = 3,
            ["fiber"] = 5
        },
        result = {
            id = "fishing_rod",
            quantity = 1
        },
        craftTime = 7,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["wooden_bow"] = {
        name = "Arc en bois",
        description = "Une arme à distance pour la chasse.",
        ingredients = {
            ["wood"] = 4,
            ["fiber"] = 3
        },
        result = {
            id = "wooden_bow",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["arrow"] = {
        name = "Flèche",
        description = "Munition pour l'arc.",
        ingredients = {
            ["wood"] = 1,
            ["stone"] = 1,
            ["fiber"] = 1
        },
        result = {
            id = "arrow",
            quantity = 4
        },
        craftTime = 5,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Vêtements et équipement
    ["leather"] = {
        name = "Cuir",
        description = "Du cuir tanné pour fabriquer des vêtements.",
        ingredients = {
            ["animal_hide"] = 1,
            ["fiber"] = 2
        },
        result = {
            id = "leather",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["leather_clothes"] = {
        name = "Vêtements en cuir",
        description = "Des vêtements plus résistants que ceux en fibre.",
        ingredients = {
            ["leather"] = 5
        },
        result = {
            id = "leather_clothes",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "stone",
        requiredStation = "loom"
    },
    
    ["fur_hat"] = {
        name = "Chapeau en fourrure",
        description = "Protège du froid.",
        ingredients = {
            ["fur"] = 3,
            ["leather"] = 1
        },
        result = {
            id = "fur_hat",
            quantity = 1
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = "loom"
    },
    
    ["fur_coat"] = {
        name = "Manteau en fourrure",
        description = "Offre une excellente protection contre le froid.",
        ingredients = {
            ["fur"] = 8,
            ["leather"] = 3,
            ["fiber"] = 5
        },
        result = {
            id = "fur_coat",
            quantity = 1
        },
        craftTime = 25,
        techLevel = "stone",
        requiredStation = "loom"
    },
    
    ["leather_backpack"] = {
        name = "Sac à dos en cuir",
        description = "Augmente la capacité d'inventaire.",
        ingredients = {
            ["leather"] = 6,
            ["fiber"] = 4
        },
        result = {
            id = "leather_backpack",
            quantity = 1
        },
        craftTime = 18,
        techLevel = "stone",
        requiredStation = "loom"
    },
    
    ["water_pouch"] = {
        name = "Outre d'eau",
        description = "Pour transporter et boire de l'eau.",
        ingredients = {
            ["leather"] = 3
        },
        result = {
            id = "water_pouch",
            quantity = 1
        },
        craftTime = 6,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Matériaux de construction avancés
    ["rope"] = {
        name = "Corde",
        description = "Utile pour diverses constructions et outils.",
        ingredients = {
            ["fiber"] = 5
        },
        result = {
            id = "rope",
            quantity = 1
        },
        craftTime = 5,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["clay_pot"] = {
        name = "Pot en argile",
        description = "Pour stocker de la nourriture et des liquides.",
        ingredients = {
            ["clay"] = 3
        },
        result = {
            id = "clay_pot",
            quantity = 1
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = "furnace"
    },
    
    ["stone_wall"] = {
        name = "Mur en pierre",
        description = "Plus solide qu'un mur en bois.",
        ingredients = {
            ["stone"] = 15
        },
        result = {
            id = "stone_wall",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["stone_floor"] = {
        name = "Sol en pierre",
        description = "Un sol solide et durable.",
        ingredients = {
            ["stone"] = 10
        },
        result = {
            id = "stone_floor",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["brick_wall"] = {
        name = "Mur en briques",
        description = "Un mur élégant et très résistant.",
        ingredients = {
            ["brick"] = 10
        },
        result = {
            id = "brick_wall",
            quantity = 1
        },
        craftTime = 18,
        techLevel = "bronze",
        requiredStation = nil
    },
    
    ["wooden_window"] = {
        name = "Fenêtre en bois",
        description = "Pour laisser entrer la lumière.",
        ingredients = {
            ["wooden_plank"] = 5
        },
        result = {
            id = "wooden_window",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["wooden_roof"] = {
        name = "Toit en bois",
        description = "Protège de la pluie.",
        ingredients = {
            ["wooden_plank"] = 8
        },
        result = {
            id = "wooden_roof",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Mobilier supplémentaire
    ["wooden_chest"] = {
        name = "Coffre en bois",
        description = "Pour stocker des objets.",
        ingredients = {
            ["wooden_plank"] = 8,
            ["iron"] = 1
        },
        result = {
            id = "wooden_chest",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "iron",
        requiredStation = nil
    },
    
    ["wooden_shelf"] = {
        name = "Étagère en bois",
        description = "Pour afficher et ranger des objets.",
        ingredients = {
            ["wooden_plank"] = 6
        },
        result = {
            id = "wooden_shelf",
            quantity = 1
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["stone_fireplace"] = {
        name = "Cheminée en pierre",
        description = "Un foyer plus élaboré, offre plus de chaleur qu'un feu de camp.",
        ingredients = {
            ["stone"] = 15,
            ["clay"] = 5
        },
        result = {
            id = "stone_fireplace",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["wooden_fence"] = {
        name = "Clôture en bois",
        description = "Pour délimiter un espace.",
        ingredients = {
            ["wooden_plank"] = 3,
            ["rope"] = 1
        },
        result = {
            id = "wooden_fence",
            quantity = 2
        },
        craftTime = 6,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["cooking_pot"] = {
        name = "Marmite",
        description = "Pour des recettes de cuisine plus élaborées.",
        ingredients = {
            ["clay_pot"] = 1,
            ["iron"] = 2
        },
        result = {
            id = "cooking_pot",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "iron",
        requiredStation = "furnace"
    },
    
    ["wooden_bench"] = {
        name = "Banc en bois",
        description = "Peut accueillir plusieurs personnes.",
        ingredients = {
            ["wooden_plank"] = 5
        },
        result = {
            id = "wooden_bench",
            quantity = 1
        },
        craftTime = 7,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Nourriture et Boissons
    ["berry_juice"] = {
        name = "Jus de baies",
        description = "Désaltérant et énergisant.",
        ingredients = {
            ["berries"] = 5,
            ["water_container"] = 1
        },
        result = {
            id = "berry_juice",
            quantity = 1
        },
        craftTime = 5,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["dried_meat"] = {
        name = "Viande séchée",
        description = "De la viande conservée qui se garde longtemps.",
        ingredients = {
            ["raw_meat"] = 1
        },
        result = {
            id = "dried_meat",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "stone",
        requiredStation = "campfire"
    },
    
    ["fish_stew"] = {
        name = "Ragoût de poisson",
        description = "Un repas complet et nourrissant.",
        ingredients = {
            ["fish"] = 2,
            ["root_vegetable"] = 1,
            ["water_container"] = 1
        },
        result = {
            id = "fish_stew",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "stone",
        requiredStation = "cooking_pot"
    },
    
    ["vegetable_soup"] = {
        name = "Soupe de légumes",
        description = "Bon pour la santé et le moral.",
        ingredients = {
            ["root_vegetable"] = 2,
            ["berries"] = 1,
            ["water_container"] = 1
        },
        result = {
            id = "vegetable_soup",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "stone",
        requiredStation = "cooking_pot"
    },
    
    -- Outils avancés en fer et bronze
    ["bronze_sword"] = {
        name = "Épée en bronze",
        description = "Une arme tranchante efficace.",
        ingredients = {
            ["bronze"] = 5,
            ["wood"] = 1
        },
        result = {
            id = "bronze_sword",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "bronze",
        requiredStation = "anvil"
    },
    
    ["iron_sword"] = {
        name = "Épée en fer",
        description = "Une arme redoutable, plus puissante que l'épée en bronze.",
        ingredients = {
            ["iron"] = 5,
            ["wood"] = 1,
            ["leather"] = 1
        },
        result = {
            id = "iron_sword",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    ["bronze_shield"] = {
        name = "Bouclier en bronze",
        description = "Protection efficace contre les attaques.",
        ingredients = {
            ["bronze"] = 3,
            ["wood"] = 4,
            ["leather"] = 2
        },
        result = {
            id = "bronze_shield",
            quantity = 1
        },
        craftTime = 18,
        techLevel = "bronze",
        requiredStation = "anvil"
    },
    
    ["iron_armor"] = {
        name = "Armure en fer",
        description = "Offre une excellente protection.",
        ingredients = {
            ["iron"] = 8,
            ["leather"] = 5
        },
        result = {
            id = "iron_armor",
            quantity = 1
        },
        craftTime = 30,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    ["bronze_hoe"] = {
        name = "Houe en bronze",
        description = "Pour cultiver la terre.",
        ingredients = {
            ["bronze"] = 2,
            ["wood"] = 3
        },
        result = {
            id = "bronze_hoe",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "bronze",
        requiredStation = "anvil"
    },
    
    ["iron_hoe"] = {
        name = "Houe en fer",
        description = "Une version améliorée de la houe en bronze.",
        ingredients = {
            ["iron"] = 2,
            ["wood"] = 3
        },
        result = {
            id = "iron_hoe",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    -- Stations avancées
    ["pottery_wheel"] = {
        name = "Tour de potier",
        description = "Permet de fabriquer des poteries plus efficacement.",
        ingredients = {
            ["wood"] = 6,
            ["stone"] = 4,
            ["clay"] = 3
        },
        result = {
            id = "pottery_wheel",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["tanning_rack"] = {
        name = "Cadre de tannage",
        description = "Pour transformer les peaux en cuir plus efficacement.",
        ingredients = {
            ["wood"] = 8,
            ["rope"] = 3,
            ["stone"] = 2
        },
        result = {
            id = "tanning_rack",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["forge"] = {
        name = "Forge",
        description = "Une version améliorée du four, permettant de travailler les métaux plus rapidement.",
        ingredients = {
            ["furnace"] = 1,
            ["brick"] = 15,
            ["iron"] = 5
        },
        result = {
            id = "forge",
            quantity = 1
        },
        craftTime = 45,
        techLevel = "iron",
        requiredStation = nil
    },
    
    ["grinding_stone"] = {
        name = "Meule",
        description = "Pour moudre les grains en farine.",
        ingredients = {
            ["stone"] = 10
        },
        result = {
            id = "grinding_stone",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["flour"] = {
        name = "Farine",
        description = "Moulue à partir de grains, nécessaire pour faire du pain.",
        ingredients = {
            ["grain"] = 3
        },
        result = {
            id = "flour",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "stone",
        requiredStation = "grinding_stone"
    },
    
    ["brewery"] = {
        name = "Brasserie",
        description = "Pour fabriquer des boissons fermentées.",
        ingredients = {
            ["wooden_plank"] = 10,
            ["clay_pot"] = 3,
            ["copper_ore"] = 2
        },
        result = {
            id = "brewery",
            quantity = 1
        },
        craftTime = 35,
        techLevel = "bronze",
        requiredStation = nil
    },
    
    -- Items de l'âge d'or
    ["gold"] = {
        name = "Or",
        description = "Un métal précieux et malléable.",
        ingredients = {
            ["gold_ore"] = 2
        },
        result = {
            id = "gold",
            quantity = 1
        },
        craftTime = 25,
        techLevel = "gold",
        requiredStation = "furnace"
    },
    
    ["gold_necklace"] = {
        name = "Collier en or",
        description = "Un bijou précieux et prestigieux.",
        ingredients = {
            ["gold"] = 2
        },
        result = {
            id = "gold_necklace",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "gold",
        requiredStation = "anvil"
    },
    
    ["gold_crown"] = {
        name = "Couronne en or",
        description = "Symbole de pouvoir et d'autorité.",
        ingredients = {
            ["gold"] = 5,
            ["gem"] = 1
        },
        result = {
            id = "gold_crown",
            quantity = 1
        },
        craftTime = 30,
        techLevel = "gold",
        requiredStation = "anvil"
    },
    
    ["gem"] = {
        name = "Gemme",
        description = "Une pierre précieuse polie.",
        ingredients = {
            ["raw_gem"] = 1
        },
        result = {
            id = "gem",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "gold",
        requiredStation = "grinding_stone"
    },
    
    ["golden_chalice"] = {
        name = "Calice en or",
        description = "Un récipient pour boisson de grande valeur.",
        ingredients = {
            ["gold"] = 3
        },
        result = {
            id = "golden_chalice",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "gold",
        requiredStation = "anvil"
    }
    
    -- Autres recettes pourront être ajoutées ici...
    -- Environ 250 recettes sont mentionnées dans le cahier des charges
}

return CraftingRecipes