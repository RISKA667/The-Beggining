-- src/shared/constants/CraftingRecipes.lua

local CraftingRecipes = {
    -- ============================================
    -- ÂGE DE PIERRE - SURVIE PRIMITIVE
    -- ============================================
    
    -- Outils de base en pierre
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
        craftTime = 5,
        techLevel = "stone",
        requiredStation = nil
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
    
    ["stone_hoe"] = {
        name = "Houe en pierre",
        description = "Outil primitif pour cultiver la terre.",
        ingredients = {
            ["stone"] = 2,
            ["wood"] = 2,
            ["fiber"] = 1
        },
        result = {
            id = "stone_hoe",
            quantity = 1
        },
        craftTime = 5,
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
    
    ["flint_knife"] = {
        name = "Couteau en silex",
        description = "Un couteau tranchant pour dépecer et couper.",
        ingredients = {
            ["flint"] = 2,
            ["wood"] = 1,
            ["fiber"] = 1
        },
        result = {
            id = "flint_knife",
            quantity = 1
        },
        craftTime = 4,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Armes primitives
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
    
    ["wooden_club"] = {
        name = "Massue en bois",
        description = "Une arme contondante primitive.",
        ingredients = {
            ["wood"] = 4,
            ["fiber"] = 1
        },
        result = {
            id = "wooden_club",
            quantity = 1
        },
        craftTime = 5,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["wooden_shield"] = {
        name = "Bouclier en bois",
        description = "Protection basique contre les attaques.",
        ingredients = {
            ["wooden_plank"] = 6,
            ["fiber"] = 3
        },
        result = {
            id = "wooden_shield",
            quantity = 1
        },
        craftTime = 10,
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
    
    ["slingshot"] = {
        name = "Fronde",
        description = "Arme à projectile simple et efficace.",
        ingredients = {
            ["leather"] = 1,
            ["fiber"] = 3
        },
        result = {
            id = "slingshot",
            quantity = 1
        },
        craftTime = 6,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Pêche et chasse
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
    
    ["fish_trap"] = {
        name = "Nasse à poissons",
        description = "Piège passif pour capturer des poissons.",
        ingredients = {
            ["wood"] = 6,
            ["fiber"] = 8
        },
        result = {
            id = "fish_trap",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["hunting_trap"] = {
        name = "Piège de chasse",
        description = "Pour capturer de petits animaux.",
        ingredients = {
            ["wood"] = 5,
            ["rope"] = 2,
            ["stone"] = 3
        },
        result = {
            id = "hunting_trap",
            quantity = 1
        },
        craftTime = 10,
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
    
    ["leather_boots"] = {
        name = "Bottes en cuir",
        description = "Protège les pieds et améliore le déplacement.",
        ingredients = {
            ["leather"] = 3,
            ["fiber"] = 2
        },
        result = {
            id = "leather_boots",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "stone",
        requiredStation = "loom"
    },
    
    -- Conteneurs et transport
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
    
    ["basket"] = {
        name = "Panier en fibres",
        description = "Pour transporter des objets.",
        ingredients = {
            ["fiber"] = 12,
            ["wood"] = 2
        },
        result = {
            id = "basket",
            quantity = 1
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = nil
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
    
    ["water_skin"] = {
        name = "Outre en peau",
        description = "Conteneur d'eau primitif.",
        ingredients = {
            ["animal_hide"] = 2,
            ["fiber"] = 3
        },
        result = {
            id = "water_container",
            quantity = 1
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["water_pouch"] = {
        name = "Outre d'eau en cuir",
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
    
    -- Éclairage primitif
    ["torch"] = {
        name = "Torche",
        description = "Fournit de la lumière dans l'obscurité.",
        ingredients = {
            ["wood"] = 1,
            ["fiber"] = 2
        },
        result = {
            id = "torch",
            quantity = 2
        },
        craftTime = 3,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Soins primitifs
    ["bandage"] = {
        name = "Bandage",
        description = "Soigne les blessures légères.",
        ingredients = {
            ["fiber"] = 3,
            ["plant_fiber"] = 2
        },
        result = {
            id = "bandage",
            quantity = 2
        },
        craftTime = 5,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["herbal_remedy"] = {
        name = "Remède aux herbes",
        description = "Soigne les maladies et infections.",
        ingredients = {
            ["medicinal_herb"] = 3,
            ["berries"] = 2,
            ["water_container"] = 1
        },
        result = {
            id = "herbal_remedy",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "stone",
        requiredStation = "campfire"
    },
    
    -- Matériaux de construction de base
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
    
    ["thatch"] = {
        name = "Chaume",
        description = "Matériau de toiture primitif.",
        ingredients = {
            ["fiber"] = 8
        },
        result = {
            id = "thatch",
            quantity = 4
        },
        craftTime = 3,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Structures en bois
    ["wooden_wall"] = {
        name = "Mur en bois",
        description = "Un mur simple en bois.",
        ingredients = {
            ["wooden_plank"] = 8,
            ["fiber"] = 2
        },
        result = {
            id = "wooden_wall",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["wooden_door"] = {
        name = "Porte en bois",
        description = "Une porte pour votre habitation.",
        ingredients = {
            ["wooden_plank"] = 6,
            ["fiber"] = 1
        },
        result = {
            id = "wooden_door",
            quantity = 1
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["wooden_floor"] = {
        name = "Plancher en bois",
        description = "Un sol en bois pour vos constructions.",
        ingredients = {
            ["wooden_plank"] = 6
        },
        result = {
            id = "wooden_floor",
            quantity = 1
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["wooden_foundation"] = {
        name = "Fondation en bois",
        description = "Base solide pour une construction.",
        ingredients = {
            ["wood"] = 10,
            ["stone"] = 4
        },
        result = {
            id = "wooden_foundation",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["thatch_roof"] = {
        name = "Toit en chaume",
        description = "Protection primitive contre la pluie.",
        ingredients = {
            ["thatch"] = 6,
            ["wood"] = 4
        },
        result = {
            id = "thatch_roof",
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
    
    ["wooden_stairs"] = {
        name = "Escalier en bois",
        description = "Pour accéder aux étages supérieurs.",
        ingredients = {
            ["wooden_plank"] = 6
        },
        result = {
            id = "wooden_stairs",
            quantity = 1
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["wooden_ladder"] = {
        name = "Échelle en bois",
        description = "Pour grimper verticalement.",
        ingredients = {
            ["wood"] = 6,
            ["rope"] = 2
        },
        result = {
            id = "wooden_ladder",
            quantity = 1
        },
        craftTime = 7,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Défenses primitives
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
    
    ["wooden_gate"] = {
        name = "Portail en bois",
        description = "Entrée sécurisée pour un enclos.",
        ingredients = {
            ["wooden_plank"] = 8,
            ["rope"] = 2
        },
        result = {
            id = "wooden_gate",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["wooden_palisade"] = {
        name = "Palissade en bois",
        description = "Défense périmétrique renforcée.",
        ingredients = {
            ["wood"] = 12,
            ["rope"] = 3
        },
        result = {
            id = "wooden_palisade",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["spike_trap"] = {
        name = "Piège à pointes",
        description = "Défense antipersonnel.",
        ingredients = {
            ["wood"] = 8,
            ["stone"] = 4,
            ["rope"] = 2
        },
        result = {
            id = "spike_trap",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- Mobilier primitif
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
    
    ["primitive_bed"] = {
        name = "Lit primitif",
        description = "Un lit simple fait de fibres et de feuilles.",
        ingredients = {
            ["fiber"] = 15,
            ["wood"] = 4
        },
        result = {
            id = "primitive_bed",
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
            ["fiber"] = 8
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
    
    ["wooden_chest"] = {
        name = "Coffre en bois",
        description = "Pour stocker des objets.",
        ingredients = {
            ["wooden_plank"] = 8,
            ["rope"] = 2
        },
        result = {
            id = "wooden_chest",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "stone",
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
    
    ["wooden_sign"] = {
        name = "Panneau en bois",
        description = "Pour écrire des messages.",
        ingredients = {
            ["wooden_plank"] = 2,
            ["charcoal"] = 1
        },
        result = {
            id = "wooden_sign",
            quantity = 1
        },
        craftTime = 5,
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
    
    -- Nourriture - Cuisson basique
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
    
    ["cooked_fish"] = {
        name = "Poisson cuit",
        description = "Un poisson cuit, prêt à être consommé.",
        ingredients = {
            ["fish"] = 1
        },
        result = {
            id = "cooked_fish",
            quantity = 1
        },
        craftTime = 6,
        techLevel = "stone",
        requiredStation = "campfire"
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
        requiredStation = "drying_rack"
    },
    
    ["smoked_fish"] = {
        name = "Poisson fumé",
        description = "Poisson conservé par fumage.",
        ingredients = {
            ["fish"] = 2,
            ["wood"] = 1
        },
        result = {
            id = "smoked_fish",
            quantity = 2
        },
        craftTime = 25,
        techLevel = "stone",
        requiredStation = "smokehouse"
    },
    
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
    
    ["roasted_berries"] = {
        name = "Baies grillées",
        description = "Plus nourrissantes que les baies crues.",
        ingredients = {
            ["berries"] = 3
        },
        result = {
            id = "roasted_berries",
            quantity = 3
        },
        craftTime = 5,
        techLevel = "stone",
        requiredStation = "campfire"
    },
    
    -- Stations de craft - Âge de pierre
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
    
    ["drying_rack"] = {
        name = "Séchoir",
        description = "Pour sécher et conserver la viande.",
        ingredients = {
            ["wood"] = 6,
            ["rope"] = 4
        },
        result = {
            id = "drying_rack",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["smokehouse"] = {
        name = "Fumoir",
        description = "Pour fumer et conserver les aliments.",
        ingredients = {
            ["wood"] = 15,
            ["stone"] = 8,
            ["clay"] = 4
        },
        result = {
            id = "smokehouse",
            quantity = 1
        },
        craftTime = 30,
        techLevel = "stone",
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
    
    ["workbench"] = {
        name = "Établi",
        description = "Pour créer des objets plus complexes.",
        ingredients = {
            ["wooden_plank"] = 10,
            ["stone"] = 5
        },
        result = {
            id = "workbench",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- ============================================
    -- ÂGE DE L'ARGILE - POTERIE ET CÉRAMIQUE
    -- ============================================
    
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
        requiredStation = "campfire"
    },
    
    ["water_jug"] = {
        name = "Cruche d'eau en argile",
        description = "Conteneur d'eau en argile cuite.",
        ingredients = {
            ["clay"] = 4
        },
        result = {
            id = "water_container",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "stone",
        requiredStation = "campfire"
    },
    
    ["clay_bowl"] = {
        name = "Bol en argile",
        description = "Pour manger et servir la nourriture.",
        ingredients = {
            ["clay"] = 2
        },
        result = {
            id = "clay_bowl",
            quantity = 2
        },
        craftTime = 5,
        techLevel = "stone",
        requiredStation = "campfire"
    },
    
    ["clay_plate"] = {
        name = "Assiette en argile",
        description = "Pour servir les repas.",
        ingredients = {
            ["clay"] = 2
        },
        result = {
            id = "clay_plate",
            quantity = 2
        },
        craftTime = 5,
        techLevel = "stone",
        requiredStation = "campfire"
    },
    
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
    
    -- ============================================
    -- ÂGE DU BRONZE - MÉTALLURGIE BASIQUE
    -- ============================================
    
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
    
    -- Outils en bronze
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
    
    ["bronze_hammer"] = {
        name = "Marteau en bronze",
        description = "Outil de construction plus résistant.",
        ingredients = {
            ["bronze"] = 3,
            ["wood"] = 2
        },
        result = {
            id = "bronze_hammer",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "bronze",
        requiredStation = "anvil"
    },
    
    -- Armes en bronze
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
    
    ["bronze_spear"] = {
        name = "Lance en bronze",
        description = "Une lance plus efficace qu'en pierre.",
        ingredients = {
            ["bronze"] = 3,
            ["wood"] = 3
        },
        result = {
            id = "bronze_spear",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "bronze",
        requiredStation = "anvil"
    },
    
    ["bronze_dagger"] = {
        name = "Dague en bronze",
        description = "Arme légère et rapide.",
        ingredients = {
            ["bronze"] = 2,
            ["wood"] = 1,
            ["leather"] = 1
        },
        result = {
            id = "bronze_dagger",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "bronze",
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
    
    -- Construction avancée
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
        techLevel = "bronze",
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
        techLevel = "bronze",
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
        techLevel = "bronze",
        requiredStation = nil
    },
    
    ["stone_foundation"] = {
        name = "Fondation en pierre",
        description = "Base très solide pour une construction.",
        ingredients = {
            ["stone"] = 20
        },
        result = {
            id = "stone_foundation",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "bronze",
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
    
    ["brick_floor"] = {
        name = "Sol en briques",
        description = "Un sol élégant et durable.",
        ingredients = {
            ["brick"] = 8
        },
        result = {
            id = "brick_floor",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "bronze",
        requiredStation = nil
    },
    
    -- Nourriture avancée
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
        techLevel = "bronze",
        requiredStation = "grinding_stone"
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
        techLevel = "bronze",
        requiredStation = "campfire"
    },
    
    ["meat_pie"] = {
        name = "Tourte à la viande",
        description = "Un repas copieux et nourrissant.",
        ingredients = {
            ["flour"] = 2,
            ["cooked_meat"] = 1,
            ["root_vegetable"] = 1
        },
        result = {
            id = "meat_pie",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "bronze",
        requiredStation = "campfire"
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
    
    ["ale"] = {
        name = "Bière",
        description = "Boisson fermentée à base de grains.",
        ingredients = {
            ["grain"] = 5,
            ["water_container"] = 2
        },
        result = {
            id = "ale",
            quantity = 2
        },
        craftTime = 60,
        techLevel = "bronze",
        requiredStation = "brewery"
    },
    
    -- ============================================
    -- ÂGE DU FER - MÉTALLURGIE AVANCÉE
    -- ============================================
    
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
    
    ["forge"] = {
        name = "Forge",
        description = "Une version améliorée du four, permettant de travailler les métaux plus rapidement.",
        ingredients = {
            ["brick"] = 15,
            ["iron"] = 5,
            ["stone"] = 10
        },
        result = {
            id = "forge",
            quantity = 1
        },
        craftTime = 45,
        techLevel = "iron",
        requiredStation = nil
    },
    
    ["steel"] = {
        name = "Acier",
        description = "Un métal plus résistant que le fer.",
        ingredients = {
            ["iron"] = 2,
            ["charcoal"] = 1
        },
        result = {
            id = "steel",
            quantity = 1
        },
        craftTime = 30,
        techLevel = "iron",
        requiredStation = "forge"
    },
    
    -- Outils en fer
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
    
    ["iron_hammer"] = {
        name = "Marteau en fer",
        description = "Outil de construction de qualité supérieure.",
        ingredients = {
            ["iron"] = 3,
            ["wood"] = 2
        },
        result = {
            id = "iron_hammer",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    -- Armes en fer
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
    
    ["iron_spear"] = {
        name = "Lance en fer",
        description = "Une lance puissante et durable.",
        ingredients = {
            ["iron"] = 3,
            ["wood"] = 3
        },
        result = {
            id = "iron_spear",
            quantity = 1
        },
        craftTime = 18,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    ["iron_mace"] = {
        name = "Masse en fer",
        description = "Arme contondante dévastatrice.",
        ingredients = {
            ["iron"] = 4,
            ["wood"] = 2
        },
        result = {
            id = "iron_mace",
            quantity = 1
        },
        craftTime = 18,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    ["crossbow"] = {
        name = "Arbalète",
        description = "Arme à distance puissante et précise.",
        ingredients = {
            ["iron"] = 4,
            ["wood"] = 6,
            ["rope"] = 3
        },
        result = {
            id = "crossbow",
            quantity = 1
        },
        craftTime = 25,
        techLevel = "iron",
        requiredStation = "workbench"
    },
    
    ["crossbow_bolt"] = {
        name = "Carreau d'arbalète",
        description = "Munition pour l'arbalète.",
        ingredients = {
            ["iron"] = 1,
            ["wood"] = 2
        },
        result = {
            id = "crossbow_bolt",
            quantity = 6
        },
        craftTime = 8,
        techLevel = "iron",
        requiredStation = "workbench"
    },
    
    -- Armures en fer
    ["iron_helmet"] = {
        name = "Casque en fer",
        description = "Protège efficacement la tête.",
        ingredients = {
            ["iron"] = 3,
            ["leather"] = 1
        },
        result = {
            id = "iron_helmet",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    ["iron_chestplate"] = {
        name = "Plastron en fer",
        description = "Protège efficacement le torse.",
        ingredients = {
            ["iron"] = 5,
            ["leather"] = 2
        },
        result = {
            id = "iron_chestplate",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    ["iron_leggings"] = {
        name = "Jambières en fer",
        description = "Protège efficacement les jambes.",
        ingredients = {
            ["iron"] = 4,
            ["leather"] = 2
        },
        result = {
            id = "iron_leggings",
            quantity = 1
        },
        craftTime = 18,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    ["iron_boots"] = {
        name = "Bottes en fer",
        description = "Protège efficacement les pieds.",
        ingredients = {
            ["iron"] = 3,
            ["leather"] = 1
        },
        result = {
            id = "iron_boots",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    ["iron_shield"] = {
        name = "Bouclier en fer",
        description = "Offre une excellente protection.",
        ingredients = {
            ["iron"] = 4,
            ["wood"] = 3,
            ["leather"] = 2
        },
        result = {
            id = "iron_shield",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    -- Mobilier avancé
    ["cooking_pot"] = {
        name = "Marmite",
        description = "Pour des recettes de cuisine plus élaborées.",
        ingredients = {
            ["iron"] = 3
        },
        result = {
            id = "cooking_pot",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "iron",
        requiredStation = "anvil"
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
        techLevel = "iron",
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
        techLevel = "iron",
        requiredStation = "cooking_pot"
    },
    
    ["meat_stew"] = {
        name = "Ragoût de viande",
        description = "Un repas très nourrissant.",
        ingredients = {
            ["cooked_meat"] = 2,
            ["root_vegetable"] = 2,
            ["water_container"] = 1
        },
        result = {
            id = "meat_stew",
            quantity = 1
        },
        craftTime = 18,
        techLevel = "iron",
        requiredStation = "cooking_pot"
    },
    
    ["iron_chest"] = {
        name = "Coffre en fer",
        description = "Coffre sécurisé pour objets précieux.",
        ingredients = {
            ["iron"] = 6,
            ["wooden_plank"] = 4
        },
        result = {
            id = "iron_chest",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    ["iron_door"] = {
        name = "Porte en fer",
        description = "Porte renforcée très sécurisée.",
        ingredients = {
            ["iron"] = 8
        },
        result = {
            id = "iron_door",
            quantity = 1
        },
        craftTime = 25,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    -- Infrastructure
    ["well"] = {
        name = "Puits",
        description = "Source d'eau permanente.",
        ingredients = {
            ["stone"] = 30,
            ["wood"] = 10,
            ["rope"] = 5
        },
        result = {
            id = "well",
            quantity = 1
        },
        craftTime = 60,
        techLevel = "iron",
        requiredStation = nil
    },
    
    ["wooden_bridge"] = {
        name = "Pont en bois",
        description = "Pour traverser des obstacles.",
        ingredients = {
            ["wooden_plank"] = 20,
            ["rope"] = 6
        },
        result = {
            id = "wooden_bridge",
            quantity = 1
        },
        craftTime = 30,
        techLevel = "iron",
        requiredStation = nil
    },
    
    ["windmill"] = {
        name = "Moulin à vent",
        description = "Pour moudre automatiquement les grains.",
        ingredients = {
            ["wood"] = 40,
            ["stone"] = 20,
            ["iron"] = 10
        },
        result = {
            id = "windmill",
            quantity = 1
        },
        craftTime = 120,
        techLevel = "iron",
        requiredStation = nil
    },
    
    ["water_wheel"] = {
        name = "Roue à eau",
        description = "Source d'énergie mécanique.",
        ingredients = {
            ["wood"] = 30,
            ["iron"] = 8,
            ["stone"] = 15
        },
        result = {
            id = "water_wheel",
            quantity = 1
        },
        craftTime = 90,
        techLevel = "iron",
        requiredStation = nil
    },
    
    -- ============================================
    -- ÂGE DE L'OR - LUXE ET PRESTIGE
    -- ============================================
    
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
    
    -- Bijoux
    ["gold_ring"] = {
        name = "Anneau en or",
        description = "Un bijou simple mais élégant.",
        ingredients = {
            ["gold"] = 1
        },
        result = {
            id = "gold_ring",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "gold",
        requiredStation = "anvil"
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
    
    ["gem_ring"] = {
        name = "Anneau serti de gemme",
        description = "Un bijou de grande valeur.",
        ingredients = {
            ["gold"] = 2,
            ["gem"] = 1
        },
        result = {
            id = "gem_ring",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "gold",
        requiredStation = "anvil"
    },
    
    ["gem_necklace"] = {
        name = "Collier serti de gemme",
        description = "Un bijou somptueux.",
        ingredients = {
            ["gold"] = 3,
            ["gem"] = 2
        },
        result = {
            id = "gem_necklace",
            quantity = 1
        },
        craftTime = 25,
        techLevel = "gold",
        requiredStation = "anvil"
    },
    
    -- Objets de luxe
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
    },
    
    ["golden_plate"] = {
        name = "Assiette en or",
        description = "Vaisselle de luxe pour les banquets.",
        ingredients = {
            ["gold"] = 2
        },
        result = {
            id = "golden_plate",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "gold",
        requiredStation = "anvil"
    },
    
    ["throne"] = {
        name = "Trône",
        description = "Siège majestueux pour un chef ou roi.",
        ingredients = {
            ["wooden_plank"] = 15,
            ["gold"] = 5,
            ["leather"] = 8,
            ["gem"] = 2
        },
        result = {
            id = "throne",
            quantity = 1
        },
        craftTime = 60,
        techLevel = "gold",
        requiredStation = "workbench"
    },
    
    ["gold_statue"] = {
        name = "Statue en or",
        description = "Monument de prestige pour votre civilisation.",
        ingredients = {
            ["gold"] = 10,
            ["stone"] = 20
        },
        result = {
            id = "gold_statue",
            quantity = 1
        },
        craftTime = 90,
        techLevel = "gold",
        requiredStation = nil
    },
    
    -- ============================================
    -- AGRICULTURE ET ÉLEVAGE
    -- ============================================
    
    ["scarecrow"] = {
        name = "Épouvantail",
        description = "Protège les cultures des oiseaux.",
        ingredients = {
            ["wood"] = 4,
            ["fiber_clothes"] = 1,
            ["fiber"] = 8
        },
        result = {
            id = "scarecrow",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["compost_bin"] = {
        name = "Composteur",
        description = "Produit de l'engrais naturel.",
        ingredients = {
            ["wooden_plank"] = 8
        },
        result = {
            id = "compost_bin",
            quantity = 1
        },
        craftTime = 10,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["fertilizer"] = {
        name = "Engrais",
        description = "Améliore la croissance des cultures.",
        ingredients = {
            ["plant_fiber"] = 5,
            ["bone"] = 2
        },
        result = {
            id = "fertilizer",
            quantity = 3
        },
        craftTime = 15,
        techLevel = "bronze",
        requiredStation = "compost_bin"
    },
    
    ["irrigation_channel"] = {
        name = "Canal d'irrigation",
        description = "Pour arroser automatiquement les cultures.",
        ingredients = {
            ["stone"] = 20,
            ["wood"] = 10
        },
        result = {
            id = "irrigation_channel",
            quantity = 1
        },
        craftTime = 30,
        techLevel = "bronze",
        requiredStation = nil
    },
    
    ["animal_pen"] = {
        name = "Enclos pour animaux",
        description = "Pour élever des animaux domestiques.",
        ingredients = {
            ["wooden_fence"] = 8,
            ["wooden_gate"] = 1
        },
        result = {
            id = "animal_pen",
            quantity = 1
        },
        craftTime = 25,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["feeding_trough"] = {
        name = "Auge",
        description = "Pour nourrir les animaux d'élevage.",
        ingredients = {
            ["wooden_plank"] = 6
        },
        result = {
            id = "feeding_trough",
            quantity = 1
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["beehive"] = {
        name = "Ruche",
        description = "Pour élever des abeilles et produire du miel.",
        ingredients = {
            ["wooden_plank"] = 8,
            ["fiber"] = 6
        },
        result = {
            id = "beehive",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "bronze",
        requiredStation = nil
    },
    
    -- ============================================
    -- OBJETS TRIBAUX ET CULTURELS
    -- ============================================
    
    ["wooden_totem"] = {
        name = "Totem en bois",
        description = "Symbole spirituel de la tribu.",
        ingredients = {
            ["wood"] = 10,
            ["stone"] = 5
        },
        result = {
            id = "wooden_totem",
            quantity = 1
        },
        craftTime = 30,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["tribal_drum"] = {
        name = "Tambour tribal",
        description = "Instrument pour les cérémonies.",
        ingredients = {
            ["wood"] = 6,
            ["animal_hide"] = 2,
            ["rope"] = 3
        },
        result = {
            id = "tribal_drum",
            quantity = 1
        },
        craftTime = 15,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["tribal_banner"] = {
        name = "Bannière tribale",
        description = "Étendard représentant votre tribu.",
        ingredients = {
            ["wood"] = 4,
            ["fiber_clothes"] = 1,
            ["rope"] = 2
        },
        result = {
            id = "tribal_banner",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["war_paint"] = {
        name = "Peinture de guerre",
        description = "Pour intimider les ennemis.",
        ingredients = {
            ["berries"] = 5,
            ["clay"] = 2,
            ["charcoal"] = 1
        },
        result = {
            id = "war_paint",
            quantity = 3
        },
        craftTime = 8,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["ceremonial_mask"] = {
        name = "Masque cérémoniel",
        description = "Pour les rituels tribaux.",
        ingredients = {
            ["wood"] = 3,
            ["feather"] = 5,
            ["leather"] = 2
        },
        result = {
            id = "ceremonial_mask",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "stone",
        requiredStation = nil
    },
    
    ["tribal_altar"] = {
        name = "Autel tribal",
        description = "Lieu sacré pour les cérémonies.",
        ingredients = {
            ["stone"] = 25,
            ["wood"] = 10,
            ["bone"] = 5
        },
        result = {
            id = "tribal_altar",
            quantity = 1
        },
        craftTime = 45,
        techLevel = "stone",
        requiredStation = nil
    },
    
    -- ============================================
    -- DÉCORATION ET CONFORT
    -- ============================================
    
    ["carpet"] = {
        name = "Tapis",
        description = "Décoration confortable pour le sol.",
        ingredients = {
            ["fiber"] = 20,
            ["fur"] = 3
        },
        result = {
            id = "carpet",
            quantity = 1
        },
        craftTime = 18,
        techLevel = "bronze",
        requiredStation = "loom"
    },
    
    ["tapestry"] = {
        name = "Tapisserie",
        description = "Décoration murale élégante.",
        ingredients = {
            ["fiber"] = 15,
            ["wood"] = 2
        },
        result = {
            id = "tapestry",
            quantity = 1
        },
        craftTime = 25,
        techLevel = "bronze",
        requiredStation = "loom"
    },
    
    ["painting"] = {
        name = "Peinture",
        description = "Œuvre d'art pour décorer les murs.",
        ingredients = {
            ["wooden_plank"] = 4,
            ["fiber"] = 2,
            ["berries"] = 3,
            ["charcoal"] = 2
        },
        result = {
            id = "painting",
            quantity = 1
        },
        craftTime = 30,
        techLevel = "bronze",
        requiredStation = nil
    },
    
    ["stone_statue"] = {
        name = "Statue en pierre",
        description = "Monument décoratif imposant.",
        ingredients = {
            ["stone"] = 30
        },
        result = {
            id = "stone_statue",
            quantity = 1
        },
        craftTime = 60,
        techLevel = "bronze",
        requiredStation = nil
    },
    
    ["fountain"] = {
        name = "Fontaine",
        description = "Élément décoratif avec de l'eau.",
        ingredients = {
            ["stone"] = 25,
            ["clay_pot"] = 2,
            ["iron"] = 3
        },
        result = {
            id = "fountain",
            quantity = 1
        },
        craftTime = 45,
        techLevel = "iron",
        requiredStation = nil
    },
    
    ["lantern"] = {
        name = "Lanterne",
        description = "Source de lumière portable améliorée.",
        ingredients = {
            ["iron"] = 2,
            ["glass"] = 1
        },
        result = {
            id = "lantern",
            quantity = 1
        },
        craftTime = 12,
        techLevel = "iron",
        requiredStation = "anvil"
    },
    
    ["chandelier"] = {
        name = "Lustre",
        description = "Éclairage élégant pour les grandes salles.",
        ingredients = {
            ["iron"] = 6,
            ["rope"] = 3
        },
        result = {
            id = "chandelier",
            quantity = 1
        },
        craftTime = 20,
        techLevel = "iron",
        requiredStation = "anvil"
    }
}

return CraftingRecipes
