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
        model = "ReplicatedStorage.Assets.Models.Resources.Rocks.Stone",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.stone_icon"
    },
    
    ["wood"] = {
        name = "Bois",
        description = "Un morceau de bois, utilisé pour l'artisanat.",
        category = "material",
        stackable = true,
        maxStack = 64,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Trees.Wood",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.wood_icon"
    },
    
    ["fiber"] = {
        name = "Fibre",
        description = "Des fibres végétales, utilisées pour tisser des cordes.",
        category = "material",
        stackable = true,
        maxStack = 64,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Plants.Fiber",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.fiber_icon"
    },
    
    ["clay"] = {
        name = "Argile",
        description = "De l'argile utilisée pour fabriquer de la poterie.",
        category = "material",
        stackable = true,
        maxStack = 64,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Rocks.Clay",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.clay_icon"
    },
    
    -- Minerais
    ["copper_ore"] = {
        name = "Minerai de cuivre",
        description = "Peut être fondu pour obtenir du bronze.",
        category = "material",
        stackable = true,
        maxStack = 32,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Ores.CopperOre",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.copper_ore_icon"
    },
    
    ["tin_ore"] = {
        name = "Minerai d'étain",
        description = "Mélangé au cuivre pour faire du bronze.",
        category = "material",
        stackable = true,
        maxStack = 32,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Ores.TinOre",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.tin_ore_icon"
    },
    
    ["iron_ore"] = {
        name = "Minerai de fer",
        description = "Peut être fondu pour obtenir du fer.",
        category = "material",
        stackable = true,
        maxStack = 32,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Ores.IronOre",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.iron_ore_icon"
    },
    
    ["gold_ore"] = {
        name = "Minerai d'or",
        description = "Un métal précieux et malléable.",
        category = "material",
        stackable = true,
        maxStack = 16,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Ores.GoldOre",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.gold_ore_icon"
    },
    
    -- Métaux raffinés
    ["bronze"] = {
        name = "Bronze",
        description = "Un alliage de cuivre et d'étain.",
        category = "material",
        stackable = true,
        maxStack = 16,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Metals.Bronze",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.bronze_icon"
    },
    
    ["iron"] = {
        name = "Fer",
        description = "Un métal solide pour fabriquer des outils et armes.",
        category = "material",
        stackable = true,
        maxStack = 16,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Metals.Iron",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.iron_icon"
    },
    
    ["gold"] = {
        name = "Or",
        description = "Un métal précieux utilisé pour la décoration et les bijoux.",
        category = "material",
        stackable = true,
        maxStack = 16,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Metals.Gold",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.gold_icon"
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
        model = "ReplicatedStorage.Assets.Models.Tools.StoneTools.StoneAxe",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.stone_axe_icon"
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
        model = "ReplicatedStorage.Assets.Models.Tools.StoneTools.StonePickaxe",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.stone_pickaxe_icon"
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
        model = "ReplicatedStorage.Assets.Models.Tools.StoneTools.StoneSpear",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.stone_spear_icon"
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
        model = "ReplicatedStorage.Assets.Models.Tools.BronzeTools.BronzeAxe",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.bronze_axe_icon"
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
        model = "ReplicatedStorage.Assets.Models.Tools.BronzeTools.BronzePickaxe",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.bronze_pickaxe_icon"
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
        model = "ReplicatedStorage.Assets.Models.Tools.IronTools.IronAxe",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.iron_axe_icon"
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
        model = "ReplicatedStorage.Assets.Models.Tools.IronTools.IronPickaxe",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.iron_pickaxe_icon"
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
        model = "ReplicatedStorage.Assets.Models.Clothing.FiberClothes",
        icon = "ReplicatedStorage.Assets.UI.Icons.Clothing.fiber_clothes_icon"
    },
    
    ["leather_clothes"] = {
        name = "Vêtements en cuir",
        description = "Des vêtements robustes en cuir d'animal.",
        category = "clothing",
        stackable = false,
        equipable = true,
        equipSlot = "body",
        temperatureModifier = 10, -- +10 résistance au froid
        model = "ReplicatedStorage.Assets.Models.Clothing.LeatherClothes",
        icon = "ReplicatedStorage.Assets.UI.Icons.Clothing.leather_clothes_icon"
    },
    
    ["fur_coat"] = {
        name = "Manteau de fourrure",
        description = "Un manteau chaud pour les environnements froids.",
        category = "clothing",
        stackable = false,
        equipable = true,
        equipSlot = "body",
        temperatureModifier = 20, -- +20 résistance au froid
        model = "ReplicatedStorage.Assets.Models.Clothing.FurCoat",
        icon = "ReplicatedStorage.Assets.UI.Icons.Clothing.fur_coat_icon"
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
        model = "ReplicatedStorage.Assets.Models.Food.Berries",
        icon = "ReplicatedStorage.Assets.UI.Icons.Food.berries_icon"
    },
    
    ["cooked_meat"] = {
        name = "Viande cuite",
        description = "De la viande cuite sur un feu.",
        category = "food",
        stackable = true,
        maxStack = 8,
        foodValue = 30,
        spoilTime = 3600, -- 1 heure avant de pourrir
        model = "ReplicatedStorage.Assets.Models.Food.CookedMeat",
        icon = "ReplicatedStorage.Assets.UI.Icons.Food.cooked_meat_icon"
    },
    
    ["bread"] = {
        name = "Pain",
        description = "Du pain cuit à partir de graines récoltées.",
        category = "food",
        stackable = true,
        maxStack = 8,
        foodValue = 25,
        spoilTime = 7200, -- 2 heures avant de pourrir
        model = "ReplicatedStorage.Assets.Models.Food.Bread",
        icon = "ReplicatedStorage.Assets.UI.Icons.Food.bread_icon"
    },
    
    -- Boissons
    ["water_container"] = {
        name = "Eau",
        description = "Un conteneur rempli d'eau potable.",
        category = "drink",
        stackable = false,
        drinkValue = 40, -- Restaure 40 points de soif
        model = "ReplicatedStorage.Assets.Models.Food.WaterContainer",
        icon = "ReplicatedStorage.Assets.UI.Icons.Food.water_container_icon"
    },
    
    -- Matériaux de construction
    ["wooden_plank"] = {
        name = "Planche en bois",
        description = "Un matériau de base pour la construction.",
        category = "building",
        stackable = true,
        maxStack = 64,
        model = "ReplicatedStorage.Assets.Models.Buildings.Materials.WoodenPlank",
        icon = "ReplicatedStorage.Assets.UI.Icons.Building.wooden_plank_icon"
    },
    
    ["brick"] = {
        name = "Brique",
        description = "Une brique solide pour des constructions durables.",
        category = "building",
        stackable = true,
        maxStack = 64,
        model = "ReplicatedStorage.Assets.Models.Buildings.Materials.Brick",
        icon = "ReplicatedStorage.Assets.UI.Icons.Building.brick_icon"
    },
    
    -- Mobilier
    ["wooden_bed"] = {
        name = "Lit en bois",
        description = "Un lit simple pour dormir.",
        category = "furniture",
        stackable = false,
        sleepQuality = 1, -- Taux de récupération d'énergie
        model = "ReplicatedStorage.Assets.Models.Buildings.Furniture.WoodenBed",
        icon = "ReplicatedStorage.Assets.UI.Icons.Furniture.wooden_bed_icon"
    },
    
    ["wooden_table"] = {
        name = "Table en bois",
        description = "Une table simple.",
        category = "furniture",
        stackable = false,
        model = "ReplicatedStorage.Assets.Models.Buildings.Furniture.WoodenTable",
        icon = "ReplicatedStorage.Assets.UI.Icons.Furniture.wooden_table_icon"
    },
    
    ["wooden_chair"] = {
        name = "Chaise en bois",
        description = "Une chaise simple.",
        category = "furniture",
        stackable = false,
        model = "ReplicatedStorage.Assets.Models.Buildings.Furniture.WoodenChair",
        icon = "ReplicatedStorage.Assets.UI.Icons.Furniture.wooden_chair_icon"
    },
    
    ["campfire"] = {
        name = "Feu de camp",
        description = "Fournit chaleur et lumière, permet de cuire des aliments.",
        category = "furniture",
        stackable = false,
        heatSource = true,
        heatRadius = 10,
        heatIntensity = 15,
        model = "ReplicatedStorage.Assets.Models.Buildings.Furniture.Campfire",
        icon = "ReplicatedStorage.Assets.UI.Icons.Furniture.campfire_icon"
    },
    
    -- NOUVEAUX OBJETS AJOUTÉS
    
    -- Matériaux supplémentaires
    ["bone"] = {
        name = "Os",
        description = "Des os qui peuvent être utilisés pour fabriquer des outils.",
        category = "material",
        stackable = true,
        maxStack = 32,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Bones.Bone",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.bone_icon"
    },
    
    ["feather"] = {
        name = "Plume",
        description = "Des plumes d'oiseaux utiles pour fabriquer des flèches.",
        category = "material",
        stackable = true,
        maxStack = 64,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Feathers.Feather",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.feather_icon"
    },
    
    ["flint"] = {
        name = "Silex",
        description = "Une pierre dure utilisée pour faire du feu ou des outils tranchants.",
        category = "material",
        stackable = true,
        maxStack = 32,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Rocks.Flint",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.flint_icon"
    },
    
    ["animal_hide"] = {
        name = "Peau d'animal",
        description = "Une peau brute qui peut être tannée pour faire du cuir.",
        category = "material",
        stackable = true,
        maxStack = 16,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Skins.AnimalHide",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.animal_hide_icon"
    },
    
    ["fur"] = {
        name = "Fourrure",
        description = "Une fourrure douce et chaude provenant d'animaux.",
        category = "material",
        stackable = true,
        maxStack = 16,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Skins.Fur",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.fur_icon"
    },
    
    ["leather"] = {
        name = "Cuir",
        description = "Du cuir tanné à partir de peaux d'animaux.",
        category = "material",
        stackable = true,
        maxStack = 16,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Skins.Leather",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.leather_icon"
    },
    
    ["rope"] = {
        name = "Corde",
        description = "Une corde solide fabriquée à partir de fibres.",
        category = "material",
        stackable = true,
        maxStack = 16,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Materials.Rope",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.rope_icon"
    },
    
    ["charcoal"] = {
        name = "Charbon de bois",
        description = "Utilisé comme combustible ou pour la purification.",
        category = "material",
        stackable = true,
        maxStack = 32,
        equipable = false,
        model = "ReplicatedStorage.Assets.Models.Resources.Materials.Charcoal",
        icon = "ReplicatedStorage.Assets.UI.Icons.Materials.charcoal_icon"
    },
    
    -- Armes et outils supplémentaires
    ["wooden_bow"] = {
        name = "Arc en bois",
        description = "Une arme de chasse à distance.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "bow",
        durability = 120,
        damage = 6,
        model = "ReplicatedStorage.Assets.Models.Tools.StoneTools.WoodenBow",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.wooden_bow_icon",
        ammo = "arrow"
    },
    
    ["arrow"] = {
        name = "Flèche",
        description = "Munition pour l'arc.",
        category = "ammo",
        stackable = true,
        maxStack = 24,
        equipable = false,
        damage = 4,
        model = "ReplicatedStorage.Assets.Models.Tools.StoneTools.Arrow",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.arrow_icon"
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
        model = "ReplicatedStorage.Assets.Models.Tools.StoneTools.FishingRod",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.fishing_rod_icon"
    },
    
    ["stone_hammer"] = {
        name = "Marteau en pierre",
        description = "Un outil utile pour la construction.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "hammer",
        durability = 120,
        damage = 5,
        model = "ReplicatedStorage.Assets.Models.Tools.StoneTools.StoneHammer",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.stone_hammer_icon"
    },
    
    ["bone_knife"] = {
        name = "Couteau en os",
        description = "Un outil tranchant pour couper et tailler.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "knife",
        durability = 80,
        damage = 4,
        model = "ReplicatedStorage.Assets.Models.Tools.StoneTools.BoneKnife",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.bone_knife_icon"
    },
    
    ["bronze_sword"] = {
        name = "Épée en bronze",
        description = "Une arme redoutable en bronze.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "weapon",
        durability = 200,
        damage = 12,
        model = "ReplicatedStorage.Assets.Models.Tools.BronzeTools.BronzeSword",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.bronze_sword_icon"
    },
    
    ["iron_sword"] = {
        name = "Épée en fer",
        description = "Une arme puissante et tranchante.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "weapon",
        durability = 400,
        damage = 16,
        model = "ReplicatedStorage.Assets.Models.Tools.IronTools.IronSword",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.iron_sword_icon"
    },
    
    ["bronze_hoe"] = {
        name = "Houe en bronze",
        description = "Un outil pour cultiver la terre.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "hoe",
        durability = 150,
        model = "ReplicatedStorage.Assets.Models.Tools.BronzeTools.BronzeHoe",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.bronze_hoe_icon"
    },
    
    ["iron_hoe"] = {
        name = "Houe en fer",
        description = "Un outil agricole plus durable.",
        category = "tool",
        stackable = false,
        equipable = true,
        equipSlot = "tool",
        toolType = "hoe",
        durability = 300,
        model = "ReplicatedStorage.Assets.Models.Tools.IronTools.IronHoe",
        icon = "ReplicatedStorage.Assets.UI.Icons.Tools.iron_hoe_icon"
    },
    
    -- Nourriture et boissons supplémentaires
    ["raw_meat"] = {
        name = "Viande crue",
        description = "De la viande d'animal non cuite, à préparer avant de manger.",
        category = "food",
        stackable = true,
        maxStack = 8,
        foodValue = 15,
        spoilTime = 1200, -- 20 minutes avant de pourrir
        model = "ReplicatedStorage.Assets.Models.Food.RawMeat",
        icon = "ReplicatedStorage.Assets.UI.Icons.Food.raw_meat_icon"
    },
    
    ["fish"] = {
        name = "Poisson",
        description = "Un poisson frais, à préparer avant de manger.",
        category = "food",
        stackable = true,
        maxStack = 8,
        foodValue = 12,
        spoilTime = 1500, -- 25 minutes avant de pourrir
        model = "ReplicatedStorage.Assets.Models.Food.Fish",
        icon = "ReplicatedStorage.Assets.UI.Icons.Food.fish_icon"
    },
    
    ["cooked_fish"] = {
        name = "Poisson cuit",
        description = "Un poisson cuit, prêt à être consommé.",
        category = "food",
        stackable = true,
        maxStack = 8,
        foodValue = 25,
        spoilTime = 3000, -- 50 minutes avant de pourrir
        model = "ReplicatedStorage.Assets.Models.Food.CookedFish",
        icon = "ReplicatedStorage.Assets.UI.Icons.Food.cooked_fish_icon"
    },
    
    ["apple"] = {
        name = "Pomme",
        description = "Un fruit frais et juteux.",
        category = "food",
        stackable = true,
        maxStack = 16,
        foodValue = 8,
        drinkValue = 5,
        spoilTime = 2400, -- 40 minutes avant de pourrir
        model = "ReplicatedStorage.Assets.Models.Food.Apple",
        icon = "ReplicatedStorage.Assets.UI.Icons.Food.apple_icon"
    },
    
    ["mushroom"] = {
        name = "Champignon",
        description = "Un champignon comestible des forêts.",
        category = "food",
        stackable = true,
        maxStack = 16,
        foodValue = 6,
        spoilTime = 3600, -- 1 heure avant de pourrir
        model = "ReplicatedStorage.Assets.Models.Food.Mushroom",
        icon = "ReplicatedStorage.Assets.UI.Icons.Food.mushroom_icon"
    },
    
    ["grain"] = {
        name = "Grain",
        description = "Des céréales qui peuvent être transformées en farine.",
        category = "food",
        stackable = true,
        maxStack = 32,
        foodValue = 3,
        spoilTime = 14400, -- 4 heures avant de pourrir
        model = "ReplicatedStorage.Assets.Models.Food.Grain",
        icon = "ReplicatedStorage.Assets.UI.Icons.Food.grain_icon"
    },
    
    ["flour"] = {
        name = "Farine",
        description = "De la farine moulue, utilisée pour faire du pain.",
        category = "food",
        stackable = true,
        maxStack = 16,
        spoilTime = 28800, -- 8 heures avant de pourrir
        model = "ReplicatedStorage.Assets.Models.Food.Flour",
        icon = "ReplicatedStorage.Assets.UI.Icons.Food.flour_icon"
    },
    
    ["berry_juice"] = {
        name = "Jus de baies",
        description = "Une boisson rafraîchissante à base de baies.",
        category = "drink",
        stackable = false,
        drinkValue = 30,
        model = "ReplicatedStorage.Assets.Models.Food.BerryJuice",
        icon = "ReplicatedStorage.Assets.UI.Icons.Food.berry_juice_icon"
    },
    
    -- Vêtements et accessoires supplémentaires
    ["leather_backpack"] = {
        name = "Sac à dos en cuir",
        description = "Augmente la capacité d'inventaire.",
        category = "accessory",
        stackable = false,
        equipable = true,
        equipSlot = "back",
        inventoryBonus = 10, -- Ajoute 10 emplacements d'inventaire
        model = "ReplicatedStorage.Assets.Models.Clothing.LeatherBackpack",
        icon = "ReplicatedStorage.Assets.UI.Icons.Clothing.leather_backpack_icon"
    },
    
    ["leather_boots"] = {
        name = "Bottes en cuir",
        description = "Protège les pieds et augmente légèrement la vitesse.",
        category = "clothing",
        stackable = false,
        equipable = true,
        equipSlot = "feet",
        speedBonus = 0.1, -- +10% de vitesse de déplacement
        model = "ReplicatedStorage.Assets.Models.Clothing.LeatherBoots",
        icon = "ReplicatedStorage.Assets.UI.Icons.Clothing.leather_boots_icon"
    },
    
    ["fur_hat"] = {
        name = "Chapeau en fourrure",
        description = "Protège la tête du froid.",
        category = "clothing",
        stackable = false,
        equipable = true,
        equipSlot = "head",
        temperatureModifier = 8, -- +8 résistance au froid
        model = "ReplicatedStorage.Assets.Models.Clothing.FurHat",
        icon = "ReplicatedStorage.Assets.UI.Icons.Clothing.fur
    }
}
return ItemTypes