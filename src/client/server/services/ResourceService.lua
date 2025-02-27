-- src/server/services/ResourceService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared.constants.GameSettings)
local ItemTypes = require(Shared.constants.ItemTypes)

-- Services
local Server = ServerScriptService:WaitForChild("Server")
local Services = Server:WaitForChild("services")
local InventoryService -- Sera initialisé dans Start()

local ResourceService = {}
ResourceService.__index = ResourceService

-- Créer une instance du service
function ResourceService.new()
    local self = setmetatable({}, ResourceService)
    
    -- Stockage des ressources
    self.resources = {}
    
    -- Ressources pour test initial
    self.resourceTypes = {
        ["wood"] = {
            name = "Arbre",
            model = "rbxassetid://12345680", -- À remplacer par un ID réel
            harvestTool = "axe",
            minHarvestAmount = 1,
            maxHarvestAmount = 3,
            respawnTime = 300, -- 5 minutes
            techLevel = "stone"
        },
        ["stone"] = {
            name = "Pierre",
            model = "rbxassetid://12345681", -- À remplacer par un ID réel
            harvestTool = "pickaxe",
            minHarvestAmount = 1,
            maxHarvestAmount = 2,
            respawnTime = 600, -- 10 minutes
            techLevel = "stone"
        },
        ["fiber"] = {
            name = "Plantes fibreuses",
            model = "rbxassetid://12345682", -- À remplacer par un ID réel
            harvestTool = nil, -- Pas d'outil requis
            minHarvestAmount = 1,
            maxHarvestAmount = 4,
            respawnTime = 180, -- 3 minutes
            techLevel = "stone"
        },
        ["clay"] = {
            name = "Argile",
            model = "rbxassetid://12345683", -- À remplacer par un ID réel
            harvestTool = nil, -- Pas d'outil requis
            minHarvestAmount = 1,
            maxHarvestAmount = 3,
            respawnTime = 480, -- 8 minutes
            techLevel = "stone"
        },
        ["berry_bush"] = {
            name = "Buisson de baies",
            model = "rbxassetid://12345684", -- À remplacer par un ID réel
            harvestTool = nil, -- Pas d'outil requis
            minHarvestAmount = 2,
            maxHarvestAmount = 5,
            respawnTime = 240, -- 4 minutes
            techLevel = "stone",
            yieldType = "berries" -- Type d'objet à donner (différent du nom de la ressource)
        },
        ["copper_ore"] = {
            name = "Minerai de cuivre",
            model = "rbxassetid://12345685", -- À remplacer par un ID réel
            harvestTool = "pickaxe",
            minHarvestAmount = 1,
            maxHarvestAmount = 2,
            respawnTime = 900, -- 15 minutes
            techLevel = "stone"
        },
        ["tin_ore"] = {
            name = "Minerai d'étain",
            model = "rbxassetid://12345686", -- À remplacer par un ID réel
            harvestTool = "pickaxe",
            minHarvestAmount = 1,
            maxHarvestAmount = 2,
            respawnTime = 900, -- 15 minutes
            techLevel = "stone"
        },
        ["iron_ore"] = {
            name = "Minerai de fer",
            model = "rbxassetid://12345687", -- À remplacer par un ID réel
            harvestTool = "pickaxe",
            minHarvestAmount = 1,
            maxHarvestAmount = 2,
            respawnTime = 1200, -- 20 minutes
            techLevel = "bronze"
        },
        ["gold_ore"] = {
            name = "Minerai d'or",
            model = "rbxassetid://12345688", -- À remplacer par un ID réel
            harvestTool = "pickaxe",
            minHarvestAmount = 1,
            maxHarvestAmount = 1,
            respawnTime = 1800, -- 30 minutes
            techLevel = "iron"
        }
    }
    
    return self
end

-- Générer des ressources dans le monde
function ResourceService:GenerateResources()
    -- Obtenir le dossier des ressources dans l'espace de travail
    local resourcesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Resources")
    
    if not resourcesFolder then
        resourcesFolder = Instance.new("Folder")
        resourcesFolder.Name = "Resources"
        
        if Workspace:FindFirstChild("Map") then
            resourcesFolder.Parent = Workspace.Map
        else
            local mapFolder = Instance.new("Folder")
            mapFolder.Name = "Map"
            mapFolder.Parent = Workspace
            resourcesFolder.Parent = mapFolder
        end
    end
    
    -- Créer des dossiers pour chaque type de ressource
    for resourceType, _ in pairs(self.resourceTypes) do
        if not resourcesFolder:FindFirstChild(resourceType) then
            local typeFolder = Instance.new("Folder")
            typeFolder.Name = resourceType
            typeFolder.Parent = resourcesFolder
        end
    end
    
    -- Générer des ressources de test (dans une implémentation réelle, cela serait basé sur un algorithme de génération)
    self:GenerateTestResources(resourcesFolder)
    
    print("ResourceService: Ressources générées dans le monde")
end

-- Générer des ressources de test pour le développement
function ResourceService:GenerateTestResources(resourcesFolder)
    -- Configuration pour la génération de test
    local testResourceCounts = {
        ["wood"] = 50,        -- 50 arbres
        ["stone"] = 80,       -- 80 pierres
        ["fiber"] = 60,       -- 60 plantes fibreuses
        ["clay"] = 30,        -- 30 dépôts d'argile
        ["berry_bush"] = 40,  -- 40 buissons de baies
        ["copper_ore"] = 20,  -- 20 minerais de cuivre
        ["tin_ore"] = 15,     -- 15 minerais d'étain
        ["iron_ore"] = 10,    -- 10 minerais de fer
        ["gold_ore"] = 5      -- 5 minerais d'or
    }
    
    -- Dimensions de la zone de jeu pour la génération aléatoire
    local minX, maxX = -500, 500
    local minZ, maxZ = -500, 500
    
    -- Générer chaque type de ressource
    for resourceType, count in pairs(testResourceCounts) do
        local typeFolder = resourcesFolder:FindFirstChild(resourceType)
        
        -- Nettoyer le dossier existant
        typeFolder:ClearAllChildren()
        
        -- Générer les ressources
        for i = 1, count do
            self:CreateResourceInstance(resourceType, typeFolder, Vector3.new(
                math.random(minX, maxX),
                0, -- La hauteur sera ajustée par RayCast
                math.random(minZ, maxZ)
            ))
        end
    end
end

-- Créer une instance de ressource dans le monde
function ResourceService:CreateResourceInstance(resourceType, parent, position)
    local resourceInfo = self.resourceTypes[resourceType]
    if not resourceInfo then return end
    
    -- Créer un modèle de base pour la ressource
    local resource = Instance.new("Model")
    resource.Name = resourceInfo.name
    
    -- Ajouter une part principale
    local primaryPart = Instance.new("Part")
    primaryPart.Name = "PrimaryPart"
    primaryPart.Anchored = true
    primaryPart.CanCollide = true
    
    -- Définir la taille en fonction du type de ressource
    if resourceType == "wood" then
        primaryPart.Size = Vector3.new(2, 10, 2)
    elseif resourceType == "stone" or resourceType:find("_ore") then
        primaryPart.Size = Vector3.new(4, 3, 4)
    else
        primaryPart.Size = Vector3.new(2, 2, 2)
    end
    
    -- Effectuer un RayCast pour placer la ressource sur le sol
    local rayStart = position + Vector3.new(0, 100, 0)
    local rayEnd = position - Vector3.new(0, 100, 0)
    local ray = Ray.new(rayStart, rayEnd - rayStart)
    
    local hitPart, hitPoint, hitNormal = Workspace:FindPartOnRayWithIgnoreList(ray, {resource})
    
    if hitPart then
        -- Placer la ressource sur le sol
        local height = primaryPart.Size.Y / 2
        primaryPart.Position = hitPoint + Vector3.new(0, height, 0)
    else
        -- Position par défaut si le RayCast échoue
        primaryPart.Position = position
    end
    
    primaryPart.Parent = resource
    resource.PrimaryPart = primaryPart
    
    -- Ajouter un attribut pour identifier le type de ressource
    resource:SetAttribute("ResourceType", resourceType)
    
    -- Ajouter un ClickDetector pour l'interaction
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 10
    clickDetector.Parent = primaryPart
    
    -- Connecter l'événement de clic
    clickDetector.MouseClick:Connect(function(player)
        self:HandleResourceClick(player, resource)
    end)
    
    -- Ajouter l'instance au parent
    resource.Parent = parent
    
    -- Stocker la référence pour une utilisation ultérieure
    local resourceId = resourceType .. "_" .. tostring(resource:GetDebugId())
    self.resources[resourceId] = {
        instance = resource,
        type = resourceType,
        harvestable = true,
        respawnTime = resourceInfo.respawnTime
    }
    
    return resource
end

-- Gérer le clic sur une ressource
function ResourceService:HandleResourceClick(player, resourceInstance)
    local resourceType = resourceInstance:GetAttribute("ResourceType")
    if not resourceType then return end
    
    local resourceId = resourceType .. "_" .. tostring(resourceInstance:GetDebugId())
    local resourceData = self.resources[resourceId]
    
    if not resourceData or not resourceData.harvestable then
        -- La ressource n'est pas récoltable (peut-être en cours de réapparition)
        return
    end
    
    -- Vérifier si le joueur a l'outil approprié
    local canHarvest, toolMultiplier = self:CheckHarvestRequirements(player, resourceType)
    
    if canHarvest then
        -- Récolter la ressource
        self:HarvestResource(player, resourceId, toolMultiplier)
    else
        -- Informer le joueur qu'il a besoin de l'outil approprié
        -- Dans une implémentation réelle, utilisez RemoteEvent
        print("ResourceService: Le joueur " .. player.Name .. " a besoin de l'outil approprié pour récolter " .. resourceType)
    end
end

-- Vérifier si le joueur peut récolter une ressource
function ResourceService:CheckHarvestRequirements(player, resourceType)
    local resourceInfo = self.resourceTypes[resourceType]
    if not resourceInfo then return false, 1 end
    
    -- Si aucun outil n'est requis, permettre la récolte directe
    if not resourceInfo.harvestTool then
        return true, 1
    end
    
    -- Vérifier le niveau technologique requis
    local playerService = Services.PlayerService
    if playerService and resourceInfo.techLevel then
        local playerData = playerService.playerData[player.UserId]
        if playerData and playerData.techLevel then
            -- TODO: Implémenter un système de niveaux technologiques des joueurs
            -- Pour l'instant, considérons que tous les joueurs ont accès au niveau "stone"
        end
    end
    
    -- Vérifier si le joueur a l'outil approprié équipé
    local inventoryService = InventoryService
    if not inventoryService then return false, 1 end
    
    local inventory = inventoryService.playerInventories[player.UserId]
    if not inventory or not inventory.equipped then return false, 1 end
    
    -- Obtenir l'outil équipé
    local equippedToolSlot = inventory.equipped["tool"]
    if not equippedToolSlot or not inventory.items[equippedToolSlot] then return false, 1 end
    
    local equippedTool = inventory.items[equippedToolSlot]
    local toolType = ItemTypes[equippedTool.id]
    
    if not toolType or not toolType.toolType then return false, 1 end
    
    -- Vérifier si le type d'outil correspond
    if toolType.toolType == resourceInfo.harvestTool then
        -- L'outil est du bon type, retourner le multiplicateur de récolte
        local multiplier = 1
        if toolType.gatherMultiplier and toolType.gatherMultiplier[resourceType] then
            multiplier = toolType.gatherMultiplier[resourceType]
        end
        return true, multiplier
    end
    
    return false, 1
end

-- Récolter une ressource
function ResourceService:HarvestResource(player, resourceId, toolMultiplier)
    local resourceData = self.resources[resourceId]
    if not resourceData or not resourceData.harvestable then return end
    
    local resourceType = resourceData.type
    local resourceInfo = self.resourceTypes[resourceType]
    
    -- Marquer la ressource comme non récoltable
    resourceData.harvestable = false
    
    -- Déterminer la quantité récoltée
    local baseAmount = math.random(resourceInfo.minHarvestAmount, resourceInfo.maxHarvestAmount)
    local amount = math.floor(baseAmount * toolMultiplier)
    
    -- Déterminer le type d'objet à donner (peut être différent du type de ressource)
    local itemType = resourceInfo.yieldType or resourceType
    
    -- Ajouter les objets à l'inventaire du joueur
    local success = InventoryService:AddItemToInventory(player, itemType, amount)
    
    if success then
        -- Informer le joueur
        print("ResourceService: " .. player.Name .. " a récolté " .. amount .. " " .. itemType)
        
        -- Dans une implémentation réelle, utilisez RemoteEvent pour informer le client
        -- et pour jouer des animations/effets
        
        -- Cacher temporairement la ressource (apparence de "récolté")
        local resourceInstance = resourceData.instance
        if resourceInstance and resourceInstance.Parent then
            -- Réduire la transparence pour indiquer que la ressource a été récoltée
            for _, part in pairs(resourceInstance:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 0.8
                end
            end
            
            -- Désactiver le ClickDetector
            local clickDetector = resourceInstance.PrimaryPart:FindFirstChild("ClickDetector")
            if clickDetector then
                clickDetector.MaxActivationDistance = 0
            end
        end
        
        -- Programmer la réapparition de la ressource
        self:ScheduleResourceRespawn(resourceId)
    else
        -- L'inventaire est plein ou autre problème
        resourceData.harvestable = true -- Remettre la ressource comme récoltable
        print("ResourceService: L'inventaire de " .. player.Name .. " est plein")
    end
end

-- Programmer la réapparition d'une ressource
function ResourceService:ScheduleResourceRespawn(resourceId)
    local resourceData = self.resources[resourceId]
    if not resourceData then return end
    
    -- Utiliser la fonction delay pour programmer la réapparition
    delay(resourceData.respawnTime, function()
        self:RespawnResource(resourceId)
    end)
end

-- Faire réapparaître une ressource
function ResourceService:RespawnResource(resourceId)
    local resourceData = self.resources[resourceId]
    if not resourceData then return end
    
    -- Restaurer l'apparence de la ressource
    local resourceInstance = resourceData.instance
    if resourceInstance and resourceInstance.Parent then
        -- Restaurer la transparence
        for _, part in pairs(resourceInstance:GetDescendants()) do
            if part:IsA("BasePart") then
                part.Transparency = 0
            end
        end
        
        -- Réactiver le ClickDetector
        local clickDetector = resourceInstance.PrimaryPart:FindFirstChild("ClickDetector")
        if clickDetector then
            clickDetector.MaxActivationDistance = 10
        end
    end
    
    -- Marquer la ressource comme récoltable à nouveau
    resourceData.harvestable = true
    
    print("ResourceService: Ressource " .. resourceId .. " réapparue")
end

-- Démarrer le service
function ResourceService:Start()
    print("ResourceService: Démarrage...")
    
    -- Récupérer les références aux autres services
    InventoryService = Services.InventoryService
    
    -- Générer les ressources initiales
    self:GenerateResources()
    
    print("ResourceService: Démarré avec succès")
end

return ResourceService