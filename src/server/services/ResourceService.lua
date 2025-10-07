-- src/server/services/ResourceService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared.constants.GameSettings)
local ItemTypes = require(Shared.constants.ItemTypes)

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
            minHarvestAmount = GameSettings.Resources.harvestAmount.wood.min or 1,
            maxHarvestAmount = GameSettings.Resources.harvestAmount.wood.max or 3,
            respawnTime = GameSettings.Resources.respawnTime.wood or 300, -- 5 minutes
            techLevel = "stone"
        },
        ["stone"] = {
            name = "Pierre",
            model = "rbxassetid://12345681", -- À remplacer par un ID réel
            harvestTool = "pickaxe",
            minHarvestAmount = GameSettings.Resources.harvestAmount.stone.min or 1,
            maxHarvestAmount = GameSettings.Resources.harvestAmount.stone.max or 2,
            respawnTime = GameSettings.Resources.respawnTime.stone or 600, -- 10 minutes
            techLevel = "stone"
        },
        ["fiber"] = {
            name = "Plantes fibreuses",
            model = "rbxassetid://12345682", -- À remplacer par un ID réel
            harvestTool = nil, -- Pas d'outil requis
            minHarvestAmount = GameSettings.Resources.harvestAmount.fiber.min or 1,
            maxHarvestAmount = GameSettings.Resources.harvestAmount.fiber.max or 4,
            respawnTime = GameSettings.Resources.respawnTime.fiber or 180, -- 3 minutes
            techLevel = "stone"
        },
        ["clay"] = {
            name = "Argile",
            model = "rbxassetid://12345683", -- À remplacer par un ID réel
            harvestTool = nil, -- Pas d'outil requis
            minHarvestAmount = GameSettings.Resources.harvestAmount.clay.min or 1,
            maxHarvestAmount = GameSettings.Resources.harvestAmount.clay.max or 3,
            respawnTime = GameSettings.Resources.respawnTime.clay or 480, -- 8 minutes
            techLevel = "stone"
        },
        ["berry_bush"] = {
            name = "Buisson de baies",
            model = "rbxassetid://12345684", -- À remplacer par un ID réel
            harvestTool = nil, -- Pas d'outil requis
            minHarvestAmount = GameSettings.Resources.harvestAmount.berries.min or 2,
            maxHarvestAmount = GameSettings.Resources.harvestAmount.berries.max or 5,
            respawnTime = GameSettings.Resources.respawnTime.berry_bush or 240, -- 4 minutes
            techLevel = "stone",
            yieldType = "berries" -- Type d'objet à donner (différent du nom de la ressource)
        },
        ["copper_ore"] = {
            name = "Minerai de cuivre",
            model = "rbxassetid://12345685", -- À remplacer par un ID réel
            harvestTool = "pickaxe",
            minHarvestAmount = GameSettings.Resources.harvestAmount.copper_ore.min or 1,
            maxHarvestAmount = GameSettings.Resources.harvestAmount.copper_ore.max or 2,
            respawnTime = GameSettings.Resources.respawnTime.copper_ore or 900, -- 15 minutes
            techLevel = "stone"
        },
        ["tin_ore"] = {
            name = "Minerai d'étain",
            model = "rbxassetid://12345686", -- À remplacer par un ID réel
            harvestTool = "pickaxe",
            minHarvestAmount = GameSettings.Resources.harvestAmount.tin_ore.min or 1,
            maxHarvestAmount = GameSettings.Resources.harvestAmount.tin_ore.max or 2,
            respawnTime = GameSettings.Resources.respawnTime.tin_ore or 900, -- 15 minutes
            techLevel = "stone"
        },
        ["iron_ore"] = {
            name = "Minerai de fer",
            model = "rbxassetid://12345687", -- À remplacer par un ID réel
            harvestTool = "pickaxe",
            minHarvestAmount = GameSettings.Resources.harvestAmount.iron_ore.min or 1,
            maxHarvestAmount = GameSettings.Resources.harvestAmount.iron_ore.max or 2,
            respawnTime = GameSettings.Resources.respawnTime.iron_ore or 1200, -- 20 minutes
            techLevel = "bronze"
        },
        ["gold_ore"] = {
            name = "Minerai d'or",
            model = "rbxassetid://12345688", -- À remplacer par un ID réel
            harvestTool = "pickaxe",
            minHarvestAmount = GameSettings.Resources.harvestAmount.gold_ore.min or 1,
            maxHarvestAmount = GameSettings.Resources.harvestAmount.gold_ore.max or 1,
            respawnTime = GameSettings.Resources.respawnTime.gold_ore or 1800, -- 30 minutes
            techLevel = "iron"
        }
    }
    
    -- Références aux services
    self.inventoryService = nil
    self.playerService = nil
    
    -- Références aux RemoteEvents
    self.remoteEvents = {}
    
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
    
    -- Générer des ressources de test
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
        
        -- Générer les ressources avec retry si position invalide
        local attempts = 0
        local maxAttempts = count * 3  -- Permettre 3x plus de tentatives
        local generated = 0
        
        while generated < count and attempts < maxAttempts do
            attempts = attempts + 1
            
            local position = Vector3.new(
                math.random(minX, maxX),
                0, -- La hauteur sera ajustée par RayCast
                math.random(minZ, maxZ)
            )
            
            local resource = self:CreateResourceInstance(resourceType, typeFolder, position)
            if resource then
                generated = generated + 1
            end
        end
        
        if generated < count then
            warn(string.format("ResourceService: Seulement %d/%d %s générés (certaines positions étaient occupées)", 
                generated, count, resourceType))
        end
    end
end

-- Vérifier si une position est valide pour spawner une ressource
function ResourceService:IsValidResourcePosition(position, resourceType)
    -- Vérifier qu'il n'y a pas de construction à cet endroit
    local structuresFolder = Workspace:FindFirstChild("Structures")
    if structuresFolder then
        -- Vérifier la distance avec toutes les structures
        for _, structure in ipairs(structuresFolder:GetDescendants()) do
            if structure:IsA("BasePart") then
                local distance = (structure.Position - position).Magnitude
                -- Exiger une distance minimale de 8 studs des structures
                if distance < 8 then
                    return false
                end
            end
        end
    end
    
    -- Vérifier qu'il n'y a pas déjà une autre ressource trop proche
    local resourcesFolder = Workspace:FindFirstChild("Map") and Workspace.Map:FindFirstChild("Resources")
    if resourcesFolder then
        for _, typeFolder in ipairs(resourcesFolder:GetChildren()) do
            for _, existingResource in ipairs(typeFolder:GetChildren()) do
                if existingResource:IsA("Model") and existingResource.PrimaryPart then
                    local distance = (existingResource.PrimaryPart.Position - position).Magnitude
                    -- Distance minimale entre ressources : 5 studs
                    if distance < 5 then
                        return false
                    end
                end
            end
        end
    end
    
    return true
end

-- Créer une instance de ressource dans le monde
function ResourceService:CreateResourceInstance(resourceType, parent, position)
    local resourceInfo = self.resourceTypes[resourceType]
    if not resourceInfo then return end
    
    -- Vérifier que la position est valide (pas sur une construction)
    if not self:IsValidResourcePosition(position, resourceType) then
        return nil
    end
    
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
        primaryPart.Color = Color3.fromRGB(121, 85, 58) -- Couleur bois
        primaryPart.Material = Enum.Material.Wood
    elseif resourceType == "stone" or resourceType:find("_ore") then
        primaryPart.Size = Vector3.new(4, 3, 4)
        primaryPart.Color = Color3.fromRGB(150, 150, 150) -- Couleur pierre
        primaryPart.Material = Enum.Material.Rock
        
        -- Couleurs spécifiques pour les minerais
        if resourceType == "copper_ore" then
            primaryPart.Color = Color3.fromRGB(184, 115, 51) -- Couleur cuivre
        elseif resourceType == "tin_ore" then
            primaryPart.Color = Color3.fromRGB(200, 200, 200) -- Couleur étain
        elseif resourceType == "iron_ore" then
            primaryPart.Color = Color3.fromRGB(165, 150, 140) -- Couleur fer
        elseif resourceType == "gold_ore" then
            primaryPart.Color = Color3.fromRGB(212, 175, 55) -- Couleur or
        end
    elseif resourceType == "berry_bush" then
        primaryPart.Size = Vector3.new(2, 2, 2)
        primaryPart.Color = Color3.fromRGB(30, 100, 30) -- Couleur buisson
        primaryPart.Material = Enum.Material.Grass
        
        -- Ajouter des baies visibles
        local berries = Instance.new("Part")
        berries.Name = "Berries"
        berries.Size = Vector3.new(1, 1, 1)
        berries.Position = primaryPart.Position + Vector3.new(0, 0.5, 0)
        berries.Anchored = true
        berries.CanCollide = false
        berries.Color = Color3.fromRGB(200, 30, 30) -- Couleur baies rouges
        berries.Material = Enum.Material.Plastic
        berries.Shape = Enum.PartType.Ball
        berries.Transparency = 0
        berries.Parent = resource
        
        -- Weld pour les baies
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = primaryPart
        weld.Part1 = berries
        weld.Parent = resource
    elseif resourceType == "fiber" then
        primaryPart.Size = Vector3.new(2, 1, 2)
        primaryPart.Color = Color3.fromRGB(120, 190, 80) -- Couleur plante
        primaryPart.Material = Enum.Material.Grass
    elseif resourceType == "clay" then
        primaryPart.Size = Vector3.new(3, 1, 3)
        primaryPart.Color = Color3.fromRGB(180, 150, 130) -- Couleur argile
        primaryPart.Material = Enum.Material.Sand
    else
        primaryPart.Size = Vector3.new(2, 2, 2)
        primaryPart.Material = Enum.Material.Plastic
    end
    
    -- Effectuer un RayCast pour placer la ressource sur le sol
    local rayStart = position + Vector3.new(0, 100, 0)
    local rayDirection = Vector3.new(0, -200, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {resource}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = Workspace:Raycast(rayStart, rayDirection, raycastParams)
    local hitPart, hitPoint, hitNormal
    if raycastResult then
        hitPart = raycastResult.Instance
        hitPoint = raycastResult.Position
        hitNormal = raycastResult.Normal
    end
    
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
    
    -- Générer un ID unique pour cette ressource
    local resourceId = resourceType .. "_" .. tostring(resource.Name) .. "_" .. tostring(resource:GetDebugId())
    
    -- Ajouter l'instance au parent
    resource.Parent = parent
    
    -- Stocker la référence pour une utilisation ultérieure
    self.resources[resourceId] = {
        instance = resource,
        type = resourceType,
        harvestable = true,
        respawnTime = resourceInfo.respawnTime,
        position = primaryPart.Position
    }
    
    return resource
end

-- Gérer le clic sur une ressource
function ResourceService:HandleResourceClick(player, resourceInstance)
    local resourceType = resourceInstance:GetAttribute("ResourceType")
    if not resourceType then return end
    
    local resourceId = resourceType .. "_" .. tostring(resourceInstance.Name) .. "_" .. tostring(resourceInstance:GetDebugId())
    local resourceData = self.resources[resourceId]
    
    if not resourceData or not resourceData.harvestable then
        -- La ressource n'est pas récoltable (peut-être en cours de réapparition)
        self:SendNotification(player, "Cette ressource n'est pas disponible actuellement", "info")
        return
    end
    
    -- Vérifier si le joueur a l'outil approprié
    local canHarvest, toolMultiplier = self:CheckHarvestRequirements(player, resourceType)
    
    if canHarvest then
        -- Récolter la ressource
        self:HarvestResource(player, resourceId, toolMultiplier)
    else
        -- Informer le joueur qu'il a besoin de l'outil approprié
        local toolRequired = self.resourceTypes[resourceType].harvestTool
        if toolRequired then
            self:SendNotification(player, "Vous avez besoin d'un(e) " .. toolRequired .. " pour récolter cette ressource", "warning")
        else
            -- Tenter quand même de récolter mais avec un multiplicateur de 1
            self:HarvestResource(player, resourceId, 1)
        end
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
    if self.playerService and resourceInfo.techLevel then
        local playerTechLevel = self:GetPlayerTechLevel(player)
        
        -- Vérifier si le joueur a le niveau technologique requis
        local techLevels = {
            ["stone"] = 1,
            ["bronze"] = 2,
            ["iron"] = 3,
            ["gold"] = 4
        }
        
        local requiredLevel = techLevels[resourceInfo.techLevel] or 1
        local playerLevel = techLevels[playerTechLevel] or 1
        
        if playerLevel < requiredLevel then
            self:SendNotification(player, "Vous n'avez pas le niveau technologique requis pour cette ressource", "error")
            return false, 1
        end
    end
    
    -- Vérifier si le joueur a l'outil approprié équipé
    if not self.inventoryService then
        return true, 1  -- Si InventoryService n'est pas disponible, autoriser par défaut
    end
    
    local inventory = self.inventoryService.playerInventories[player.UserId]
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

-- Obtenir le niveau technologique d'un joueur
function ResourceService:GetPlayerTechLevel(player)
    if self.playerService and self.playerService.playerData and self.playerService.playerData[player.UserId] then
        return self.playerService.playerData[player.UserId].techLevel or "stone"
    end
    
    -- Par défaut, retourner le niveau de base
    return "stone"
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
    local success = false
    if self.inventoryService then
        success = self.inventoryService:AddItemToInventory(player, itemType, amount)
    else
        -- Si InventoryService n'est pas disponible, considérer comme réussi
        success = true
    end
    
    if success then
        -- Informer le joueur
        self:SendNotification(player, "Vous avez récolté " .. amount .. " " .. (ItemTypes[itemType] and ItemTypes[itemType].name or itemType), "success")
        
        -- Envoyer un événement au client pour les effets visuels et les animations
        if self.remoteEvents.ResourceHarvest then
            self.remoteEvents.ResourceHarvest:FireClient(player, itemType, amount)
        end
        
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
        self:SendNotification(player, "Votre inventaire est plein", "error")
    end
    
    return success, amount
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
    
    -- Vérifier si la position est toujours valide (pas de construction construite entre temps)
    if not self:IsValidResourcePosition(resourceData.position, resourceData.type) then
        warn("ResourceService: Impossible de faire réapparaître " .. resourceId .. " - position occupée par une construction")
        
        -- Détruire complètement cette ressource et ne pas la faire réapparaître
        if resourceData.instance then
            resourceData.instance:Destroy()
        end
        self.resources[resourceId] = nil
        return
    end
    
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

-- Envoi d'une notification au joueur
function ResourceService:SendNotification(player, message, messageType)
    if self.remoteEvents.Notification then
        self.remoteEvents.Notification:FireClient(player, message, messageType or "info")
    else
        -- Fallback si RemoteEvent n'est pas disponible
        print("Notification pour " .. player.Name .. ": " .. message)
    end
end

-- Démarrer le service
function ResourceService:Start(services)
    print("ResourceService: Démarrage...")
    
    -- Récupérer les références aux autres services
    self.inventoryService = services.InventoryService
    self.playerService = services.PlayerService
    
    -- Récupérer les références aux RemoteEvents
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if Events then
        self.remoteEvents = {
            ResourceHarvest = Events:FindFirstChild("ResourceHarvest"),
            Notification = Events:FindFirstChild("Notification")
        }
    else
        warn("ResourceService: Dossier Events non trouvé dans ReplicatedStorage")
    end
    
    -- Générer les ressources initiales
    self:GenerateResources()
    
    print("ResourceService: Démarré avec succès")
    return self
end

return ResourceService
