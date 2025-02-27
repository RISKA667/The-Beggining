-- src/server/services/BuildingService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared.constants.GameSettings)
local ItemTypes = require(Shared.constants.ItemTypes)

-- Services
local Server = ServerScriptService:WaitForChild("Server")
local Services = Server:WaitForChild("services")
local InventoryService -- Sera initialisé dans Start()
local PlayerService -- Sera initialisé dans Start()

local BuildingService = {}
BuildingService.__index = BuildingService

-- Créer une instance du service
function BuildingService.new()
    local self = setmetatable({}, BuildingService)
    
    -- Structures construites
    self.playerStructures = {} -- [userId] = {structureId = structure}
    self.structuresById = {}   -- [structureId] = {owner = userId, instance = modelInstance, type = buildingType}
    
    -- Joueurs en mode construction
    self.buildingMode = {}     -- [userId] = {itemId = id, previewInstance = instance, slotNumber = slot}
    
    -- Types de bâtiments disponibles
    self.buildingTypes = {
        -- Bâtiments de base
        ["wooden_wall"] = {
            name = "Mur en bois",
            model = "rbxassetid://12345690", -- À remplacer par un ID réel
            durability = 100,
            techLevel = "stone",
            category = "building",
            buildTime = 5, -- Secondes pour construire
            isWall = true
        },
        ["wooden_floor"] = {
            name = "Sol en bois",
            model = "rbxassetid://12345691", -- À remplacer par un ID réel
            durability = 80,
            techLevel = "stone",
            category = "building",
            buildTime = 3
        },
        ["wooden_door"] = {
            name = "Porte en bois",
            model = "rbxassetid://12345692", -- À remplacer par un ID réel
            durability = 90,
            techLevel = "stone",
            category = "building",
            buildTime = 6,
            isDoor = true
        },
        
        -- Meubles
        ["wooden_bed"] = {
            name = "Lit en bois",
            model = "rbxassetid://12345693", -- À remplacer par un ID réel
            durability = 60,
            techLevel = "stone",
            category = "furniture",
            buildTime = 8,
            sleepQuality = 1 -- Multiplicateur de récupération d'énergie
        },
        ["wooden_table"] = {
            name = "Table en bois",
            model = "rbxassetid://12345694", -- À remplacer par un ID réel
            durability = 50,
            techLevel = "stone",
            category = "furniture",
            buildTime = 5
        },
        ["wooden_chair"] = {
            name = "Chaise en bois",
            model = "rbxassetid://12345695", -- À remplacer par un ID réel
            durability = 40,
            techLevel = "stone",
            category = "furniture",
            buildTime = 4
        },
        ["campfire"] = {
            name = "Feu de camp",
            model = "rbxassetid://12345696", -- À remplacer par un ID réel
            durability = 30,
            techLevel = "stone",
            category = "furniture",
            buildTime = 5,
            heatSource = true,
            heatRadius = 10,
            heatIntensity = 15,
            cookingStation = true
        },
        ["furnace"] = {
            name = "Four",
            model = "rbxassetid://12345697", -- À remplacer par un ID réel
            durability = 120,
            techLevel = "stone",
            category = "furniture",
            buildTime = 10,
            heatSource = true,
            heatRadius = 5,
            heatIntensity = 20,
            smeltingStation = true
        },
        ["anvil"] = {
            name = "Enclume",
            model = "rbxassetid://12345698", -- À remplacer par un ID réel
            durability = 150,
            techLevel = "bronze",
            category = "furniture",
            buildTime = 12,
            forgingStation = true
        }
    }
    
    -- Compteur pour les IDs des structures
    self.nextStructureId = 1
    
    return self
end

-- Initialiser les structures d'un joueur
function BuildingService:InitializePlayerStructures(player)
    local userId = player.UserId
    
    if not self.playerStructures[userId] then
        self.playerStructures[userId] = {}
    end
end

-- Commencer le placement d'un bâtiment
function BuildingService:StartPlacement(player, itemId, slotNumber)
    local userId = player.UserId
    
    -- Vérifier si l'objet est de type construction
    local itemType = ItemTypes[itemId]
    if not itemType or (itemType.category ~= "building" and itemType.category ~= "furniture") then
        return false, "Cet objet ne peut pas être construit"
    end
    
    -- Vérifier si le joueur est déjà en mode construction
    if self.buildingMode[userId] then
        self:CancelPlacement(player)
    end
    
    -- Créer un aperçu du bâtiment
    local previewInstance = self:CreateBuildingPreview(itemId)
    if not previewInstance then
        return false, "Impossible de créer l'aperçu du bâtiment"
    end
    
    -- Mettre à jour l'état du mode construction
    self.buildingMode[userId] = {
        itemId = itemId,
        previewInstance = previewInstance,
        slotNumber = slotNumber
    }
    
    -- Positionner l'aperçu initialement devant le joueur
    self:UpdatePreviewPosition(player)
    
    -- Dans une implémentation réelle, envoyer un RemoteEvent pour informer le client
    -- qu'il est en mode construction et activer les contrôles spécifiques
    print("BuildingService: " .. player.Name .. " a commencé à placer un " .. itemType.name)
    
    return true
end

-- Créer un aperçu de bâtiment
function BuildingService:CreateBuildingPreview(itemId)
    -- Dans une implémentation complète, charger le modèle depuis les ressources du jeu
    -- Pour cet exemple, créer un modèle simple
    
    local preview = Instance.new("Model")
    preview.Name = "BuildingPreview"
    
    local primaryPart = Instance.new("Part")
    primaryPart.Name = "PrimaryPart"
    primaryPart.Anchored = true
    primaryPart.CanCollide = false
    primaryPart.Transparency = 0.5
    primaryPart.Material = Enum.Material.Plastic
    
    -- Taille en fonction du type d'objet
    if itemId == "wooden_wall" then
        primaryPart.Size = Vector3.new(0.2, 3, 4)
    elseif itemId == "wooden_floor" then
        primaryPart.Size = Vector3.new(4, 0.2, 4)
    elseif itemId == "wooden_door" then
        primaryPart.Size = Vector3.new(0.2, 3, 1.5)
    elseif itemId == "wooden_bed" then
        primaryPart.Size = Vector3.new(2, 0.5, 4)
    elseif itemId == "wooden_table" then
        primaryPart.Size = Vector3.new(3, 1, 1.5)
    elseif itemId == "wooden_chair" then
        primaryPart.Size = Vector3.new(1, 1.5, 1)
    elseif itemId == "campfire" or itemId == "furnace" then
        primaryPart.Size = Vector3.new(2, 1, 2)
    elseif itemId == "anvil" then
        primaryPart.Size = Vector3.new(1, 1, 2)
    else
        primaryPart.Size = Vector3.new(1, 1, 1)
    end
    
    -- Définir la couleur en fonction de la validité (vert = valide, rouge = invalide)
    primaryPart.Color = Color3.fromRGB(0, 255, 0) -- Commence en vert
    
    primaryPart.Parent = preview
    preview.PrimaryPart = primaryPart
    
    -- Ajouter un attribut pour identifier le type de bâtiment
    preview:SetAttribute("BuildingType", itemId)
    
    -- Parenté à Workspace temporairement
    preview.Parent = Workspace
    
    return preview
end

-- Mettre à jour la position de l'aperçu du bâtiment
function BuildingService:UpdatePreviewPosition(player)
    local userId = player.UserId
    local buildModeData = self.buildingMode[userId]
    
    if not buildModeData or not buildModeData.previewInstance then return end
    
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = character.HumanoidRootPart
    local lookVector = rootPart.CFrame.LookVector
    
    -- Positionner devant le joueur
    local position = rootPart.Position + (lookVector * 5)
    
    -- Ajuster la hauteur selon le type d'objet
    local itemId = buildModeData.itemId
    if itemId == "wooden_floor" then
        position = position - Vector3.new(0, 1.5, 0) -- Positionner sous les pieds
    elseif itemId == "wooden_wall" or itemId == "wooden_door" then
        position = position + Vector3.new(0, 0.5, 0) -- Position légèrement plus élevée
    end
    
    -- Obtenir l'orientation de l'aperçu (alignée avec la direction du joueur)
    local orientation = CFrame.new(position, position + lookVector)
    
    -- Mettre à jour la position de l'aperçu
    buildModeData.previewInstance:SetPrimaryPartCFrame(orientation)
    
    -- Vérifier si l'emplacement est valide
    local isValid = self:CheckPlacementValidity(player, position, itemId)
    
    -- Mettre à jour la couleur de l'aperçu
    local primaryPart = buildModeData.previewInstance.PrimaryPart
    if primaryPart then
        primaryPart.Color = isValid and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end
    
    return isValid
end

-- Vérifier si l'emplacement est valide pour placer un bâtiment
function BuildingService:CheckPlacementValidity(player, position, itemId)
    -- TODO: Implémenter des vérifications plus avancées
    -- 1. Vérifier la collision avec d'autres structures
    -- 2. Vérifier si le joueur est assez proche de sa tribu/base
    -- 3. Vérifier les règles spécifiques (ex: mur doit être connecté à un sol)
    
    -- Vérification simple: pas trop loin du joueur
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    
    local rootPart = character.HumanoidRootPart
    local distance = (rootPart.Position - position).Magnitude
    
    local maxDistance = 10 -- Distance maximale pour construire