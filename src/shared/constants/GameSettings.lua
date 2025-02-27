-- src/shared/constants/GameSettings.lua

local GameSettings = {
    -- Paramètres de temps
    Time = {
        yearInSeconds = 3600,       -- 1 heure réelle = 1 an dans le jeu
        dayNightCycle = 600,        -- 10 minutes pour un cycle jour/nuit complet
        dayLength = 420,            -- 7 minutes de jour
        nightLength = 180,          -- 3 minutes de nuit
        dawnDuskLength = 60,        -- 1 minute pour l'aube/crépuscule
    },
    
    -- Paramètres des joueurs
    Player = {
        startingAge = 16,           -- Âge de départ
        maxNaturalAge = 60,         -- Âge maximum naturel
        deathChanceStart = 50,      -- Âge où la mort naturelle devient possible
        initialInventorySize = 20,  -- Taille d'inventaire initiale
        spawnWithItems = {          -- Objets de départ
            ["stone"] = 1
        },
        walkSpeed = 16,             -- Vitesse de marche
        runSpeed = 24,              -- Vitesse de course
        interactionDistance = 5,    -- Distance d'interaction avec les objets
    },
    
    -- Paramètres de survie
    Survival = {
        -- Faim
        maxHunger = 100,            -- Valeur maximale de faim
        hungerDecayRate = 0.05,     -- Diminution par seconde
        criticalHungerThreshold = 15, -- Seuil critique
        hungerDamageAmount = 1,     -- Dégâts par tick quand affamé
        
        -- Soif
        maxThirst = 100,            -- Valeur maximale de soif
        thirstDecayRate = 0.08,     -- Diminution par seconde
        criticalThirstThreshold = 10, -- Seuil critique
        thirstDamageAmount = 2,     -- Dégâts par tick quand assoiffé
        
        -- Énergie
        maxEnergy = 100,            -- Valeur maximale d'énergie
        energyDecayRate = 0.03,     -- Diminution par seconde (éveil)
        energyRecoveryRate = 0.1,   -- Récupération par seconde (sommeil)
        criticalEnergyThreshold = 10, -- Seuil critique
        
        -- Température
        idealTemperature = 50,      -- Température idéale (0-100)
        criticalColdThreshold = 20, -- Seuil de froid critique
        criticalHeatThreshold = 80, -- Seuil de chaleur critique
        temperatureDamageAmount = 1, -- Dégâts par tick en température critique
    },
    
    -- Ressources
    Resources = {
        respawnTime = {
            ["wood"] = 300,         -- 5 minutes
            ["stone"] = 600,        -- 10 minutes
            ["fiber"] = 180,        -- 3 minutes
            ["berry_bush"] = 240,   -- 4 minutes
            ["clay"] = 480,         -- 8 minutes
            ["copper_ore"] = 900,   -- 15 minutes
            ["tin_ore"] = 900,      -- 15 minutes
            ["iron_ore"] = 1200,    -- 20 minutes
            ["gold_ore"] = 1800,    -- 30 minutes
        },
        
        harvestAmount = {
            ["wood"] = {min = 1, max = 3},
            ["stone"] = {min = 1, max = 2},
            ["fiber"] = {min = 1, max = 4},
            ["berries"] = {min = 2, max = 5},
            ["clay"] = {min = 1, max = 3},
            ["copper_ore"] = {min = 1, max = 2},
            ["tin_ore"] = {min = 1, max = 2},
            ["iron_ore"] = {min = 1, max = 2},
            ["gold_ore"] = {min = 1, max = 1},
        },
        
        toolRequirement = {
            ["wood"] = "axe",
            ["stone"] = "pickaxe",
            ["fiber"] = nil,         -- Pas d'outil requis
            ["berries"] = nil,       -- Pas d'outil requis
            ["clay"] = nil,          -- Pas d'outil requis
            ["copper_ore"] = "pickaxe",
            ["tin_ore"] = "pickaxe",
            ["iron_ore"] = "pickaxe",
            ["gold_ore"] = "pickaxe",
        },
        
        techLevelRequirement = {
            ["wood"] = "stone",
            ["stone"] = "stone",
            ["fiber"] = "stone",
            ["berries"] = "stone",
            ["clay"] = "stone",
            ["copper_ore"] = "stone",
            ["tin_ore"] = "stone",
            ["iron_ore"] = "bronze",
            ["gold_ore"] = "iron",
        },
    },
    
    -- Construction
    Building = {
        maxStructuresPerPlayer = 10,  -- Nombre max de structures par joueur
        maxDistanceFromTribe = 50,    -- Distance max de construction depuis le centre de la tribu
        structureDurability = {
            ["wooden"] = 100,         -- Points de durabilité pour structures en bois
            ["stone"] = 200,          -- Points de durabilité pour structures en pierre
            ["brick"] = 300,          -- Points de durabilité pour structures en brique
        },
    },
    
    -- Tribus
    Tribe = {
        maxMembers = 20,              -- Nombre max de membres par tribu
        creationCost = {              -- Coût pour créer une tribu
            ["wooden_totem"] = 1,
        },
    },
}

return GameSettings