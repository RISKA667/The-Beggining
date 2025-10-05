-- src/server/services/BuildingService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:FindFirstChild("Shared")
if not Shared then
    error("Dossier Shared non trouvé dans ReplicatedStorage")
    return nil
end

local GameSettings = require(Shared.constants.GameSettings)
local ItemTypes = require(Shared.constants.ItemTypes)

local BuildingService = {}
BuildingService.__index = BuildingService

-- Créer une instance du service
function BuildingService.new()
    local self = setmetatable({}, BuildingService)
    
    -- Structures construites
    self.playerStructures = {}  -- [userId] = {structureId = structure}
    self.structuresById = {}    -- [structureId] = {owner = userId, instance = modelInstance, type = buildingType}
    
    -- Joueurs en mode construction
    self.buildingMode = {}      -- [userId] = {itemId = id, previewInstance = instance, slotNumber = slot}
    
    -- Types de bâtiments disponibles
    self.buildingTypes = {
        -- Bâtiments de base
        ["wooden_wall"] = {
            name = "Mur en bois",
            model = "", -- À remplacer par un ID réel
            durability = 100,
            techLevel = "stone",
            category = "building",
            buildTime = 5, -- Secondes pour construire
            isWall = true
        },
        ["wooden_floor"] = {
            name = "Sol en bois",
            model = "", -- À remplacer par un ID réel
            durability = 80,
            techLevel = "stone",
            category = "building",
            buildTime = 3
        },
        ["wooden_door"] = {
            name = "Porte en bois",
            model = "", -- À remplacer par un ID réel
            durability = 90,
            techLevel = "stone",
            category = "building",
            buildTime = 6,
            isDoor = true
        },
        
        -- Meubles
        ["wooden_bed"] = {
            name = "Lit en bois",
            model = "", -- À remplacer par un ID réel
            durability = 60,
            techLevel = "stone",
            category = "furniture",
            buildTime = 8,
            sleepQuality = 1 -- Multiplicateur de récupération d'énergie
        },
        ["wooden_table"] = {
            name = "Table en bois",
            model = "", -- À remplacer par un ID réel
            durability = 50,
            techLevel = "stone",
            category = "furniture",
            buildTime = 5
        },
        ["wooden_chair"] = {
            name = "Chaise en bois",
            model = "", -- À remplacer par un ID réel
            durability = 40,
            techLevel = "stone",
            category = "furniture",
            buildTime = 4
        },
        ["campfire"] = {
            name = "Feu de camp",
            model = "", -- À remplacer par un ID réel
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
            model = "", -- À remplacer par un ID réel
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
            model = "", -- À remplacer par un ID réel
            durability = 150,
            techLevel = "bronze",
            category = "furniture",
            buildTime = 12,
            forgingStation = true
        }
    }
    
    -- Compteur pour les IDs des structures
    self.nextStructureId = 1
    
    -- Références aux services (seront injectées dans Start)
    self.inventoryService = nil
    self.tribeService = nil
    
    -- RemoteEvents (seront référencés dans Start)
    self.remoteEvents = {}
    
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
        self:SendNotification(player, "Cet objet ne peut pas être construit", "error")
        return false
    end
    
    -- Vérifier si le joueur est déjà en mode construction
    if self.buildingMode[userId] then
        self:CancelPlacement(player)
    end
    
    -- Créer un aperçu du bâtiment
    local previewInstance = self:CreateBuildingPreview(itemId)
    if not previewInstance then
        self:SendNotification(player, "Impossible de créer l'aperçu du bâtiment", "error")
        return false
    end
    
    -- Mettre à jour l'état du mode construction
    self.buildingMode[userId] = {
        itemId = itemId,
        previewInstance = previewInstance,
        slotNumber = slotNumber
    }
    
    -- Positionner l'aperçu initialement devant le joueur
    self:UpdatePreviewPosition(player)
    
    -- Informer le client qu'il est en mode construction
    if self.remoteEvents.BuildingStart then
        self.remoteEvents.BuildingStart:FireClient(player, itemId, previewInstance)
    end
    
    self:SendNotification(player, "Mode construction activé. Cliquez pour placer " .. itemType.name, "info")
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
    local previewFolder = Workspace:FindFirstChild("BuildingPreviews")
    if not previewFolder then
        previewFolder = Instance.new("Folder")
        previewFolder.Name = "BuildingPreviews"
        previewFolder.Parent = Workspace
    end
    
    preview.Parent = previewFolder
    
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
    buildModeData.previewInstance:PivotTo(orientation)
    
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
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
    
    local rootPart = character.HumanoidRootPart
    local distance = (rootPart.Position - position).Magnitude
    
    -- Vérification 1: Distance maximale
    local maxDistance = GameSettings.Building.maxDistanceFromTribe or 50
    if distance > 10 then -- Distance pour le placement (plus court que la distance de tribu)
        return false
    end
    
    -- Vérification 2: Collision avec d'autres structures
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
    
    -- Filtrer pour ne vérifier que les structures déjà placées
    local structuresFolder = Workspace:FindFirstChild("Structures")
    if structuresFolder then
        overlapParams.FilterDescendantsInstances = {structuresFolder}
        
        -- Taille du modèle à vérifier
        local size = Vector3.new(4, 3, 4) -- Taille générique
        if itemId == "wooden_wall" then
            size = Vector3.new(0.5, 3, 4)
        elseif itemId == "wooden_floor" then
            size = Vector3.new(4, 0.5, 4)
        elseif itemId == "wooden_door" then
            size = Vector3.new(0.5, 3, 2)
        end
        
        -- Vérifier les collisions
        local parts = Workspace:GetPartBoundsInBox(CFrame.new(position), size, overlapParams)
        if #parts > 0 then
            return false
        end
    end
    
    -- Vérification 3: Zone de tribu (si le système de tribu est activé)
    if self.tribeService then
        local userId = player.UserId
        local tribeId = self.tribeService:GetPlayerTribeId(player)
        
        -- Si le joueur est dans une tribu, vérifier qu'il est dans le territoire
        if tribeId then
            local tribeData = self.tribeService:GetTribeData(tribeId)
            if tribeData and tribeData.territory and tribeData.territory.center then
                local tribeCenter = tribeData.territory.center
                local tribeCenterVec = Vector3.new(tribeCenter.x, tribeCenter.y, tribeCenter.z)
                local distanceFromTribes = (position - tribeCenterVec).Magnitude
                
                if distanceFromTribes > maxDistance then
                    return false
                end
            end
        else
            -- Si le joueur n'est pas dans une tribu, il ne peut construire que près de lui
            if distance > 15 then
                return false
            end
        end
    end
    
    -- Vérification 4: Le joueur a les permissions (si c'est dans une zone de tribu)
    -- À implémenter si nécessaire avec le système de tribu
    
    -- Si toutes les vérifications sont passées, l'emplacement est valide
    return true
end

-- Annuler le placement en cours
function BuildingService:CancelPlacement(player)
    local userId = player.UserId
    
    if not self.buildingMode[userId] then return end
    
    -- Supprimer l'aperçu
    if self.buildingMode[userId].previewInstance then
        self.buildingMode[userId].previewInstance:Destroy()
    end
    
    -- Réinitialiser l'état
    self.buildingMode[userId] = nil
    
    -- Informer le client
    self:SendNotification(player, "Mode construction annulé", "info")
end

-- Placer un bâtiment à la position actuelle
function BuildingService:PlaceBuilding(player, itemId, position, rotation)
    local userId = player.UserId
    
    -- Vérifier si le joueur est en mode construction ou si des données ont été fournies
    local buildModeData = self.buildingMode[userId]
    
    -- Si position et rotation sont fournis directement, utiliser ces valeurs
    if position and rotation then
        -- Vérifier si l'emplacement est valide
        if not self:CheckPlacementValidity(player, position, itemId) then
            self:SendNotification(player, "Emplacement invalide pour la construction", "error")
            return false, "Emplacement invalide"
        end
    else
        -- Sinon, utiliser les données du mode construction
        if not buildModeData or buildModeData.itemId ~= itemId then
            self:SendNotification(player, "Vous n'êtes pas en mode construction pour cet objet", "error")
            return false, "Mode construction non actif"
        end
        
        -- Vérifier si l'aperçu existe
        if not buildModeData.previewInstance then
            self:SendNotification(player, "Aperçu de construction invalide", "error")
            return false, "Aperçu invalide"
        end
        
        -- Récupérer la position et rotation de l'aperçu
        position = buildModeData.previewInstance:GetPrimaryPartCFrame().Position
        rotation = buildModeData.previewInstance.PrimaryPart.CFrame - buildModeData.previewInstance.PrimaryPart.Position
        
        -- Vérifier une dernière fois si l'emplacement est valide
        if not self:UpdatePreviewPosition(player) then
            self:SendNotification(player, "Emplacement invalide pour la construction", "error")
            return false, "Emplacement invalide"
        end
    end
    
    -- Vérifier si le joueur a l'objet dans son inventaire
    if not self.inventoryService:HasItemInInventory(player, itemId, 1) then
        self:SendNotification(player, "Vous n'avez pas cet objet dans votre inventaire", "error")
        return false, "Objet manquant dans l'inventaire"
    end
    
    -- Retirer l'objet de l'inventaire
    local success = self.inventoryService:RemoveItemFromInventory(player, itemId, 1)
    if not success then
        self:SendNotification(player, "Impossible de retirer l'objet de l'inventaire", "error")
        return false, "Erreur d'inventaire"
    end
    
    -- Créer la structure dans le monde
    local structureInstance = self:CreateStructureInstance(itemId, position, rotation)
    if not structureInstance then
        -- En cas d'erreur, remettre l'objet dans l'inventaire
        self.inventoryService:AddItemToInventory(player, itemId, 1)
        self:SendNotification(player, "Erreur lors de la création de la structure", "error")
        return false, "Erreur de création"
    end
    
    -- Générer un ID pour la structure
    local structureId = "structure_" .. self.nextStructureId
    self.nextStructureId = self.nextStructureId + 1
    
    -- Stocker les données de la structure
    self.structuresById[structureId] = {
        owner = userId,
        instance = structureInstance,
        type = itemId,
        creationTime = os.time(),
        durability = self.buildingTypes[itemId] and self.buildingTypes[itemId].durability or 100,
        position = position,
        rotation = rotation
    }
    
    -- Associer la structure au joueur
    if not self.playerStructures[userId] then
        self.playerStructures[userId] = {}
    end
    self.playerStructures[userId][structureId] = true
    
    -- Définir les attributs de la structure
    structureInstance:SetAttribute("StructureId", structureId)
    structureInstance:SetAttribute("Owner", userId)
    
    -- Si c'est un meuble interactif, ajouter un ClickDetector
    if self:IsInteractiveBuilding(itemId) then
        self:MakeBuildingInteractive(structureInstance, itemId)
    end
    
    -- Annuler le mode construction
    if buildModeData then
        self:CancelPlacement(player)
    end
    
    -- Notifier le joueur
    self:SendNotification(player, "Vous avez construit: " .. (ItemTypes[itemId] and ItemTypes[itemId].name or itemId), "success")
    
    -- Notifier les clients proches de la nouvelle structure
    self:NotifyNearbyPlayers(position, player.Name .. " a construit " .. (ItemTypes[itemId] and ItemTypes[itemId].name or itemId), 30)
    
    return true, "Construction réussie"
end

-- Créer une instance de structure dans le monde
function BuildingService:CreateStructureInstance(itemId, position, rotation)
    -- Dans une implémentation complète, charger le modèle depuis les ressources du jeu
    -- Pour cet exemple, créer un modèle simple
    
    local structureModel = Instance.new("Model")
    structureModel.Name = ItemTypes[itemId] and ItemTypes[itemId].name or itemId
    
    local primaryPart = Instance.new("Part")
    primaryPart.Name = "PrimaryPart"
    primaryPart.Anchored = true
    primaryPart.CanCollide = true
    
    -- Taille en fonction du type d'objet (même logique que pour l'aperçu)
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
    
    -- Définir l'apparence
    primaryPart.Material = Enum.Material.Wood
    if itemId:find("stone") then
        primaryPart.Material = Enum.Material.Slate
    elseif itemId:find("brick") then
        primaryPart.Material = Enum.Material.Brick
    elseif itemId == "anvil" then
        primaryPart.Material = Enum.Material.Metal
    elseif itemId == "campfire" then
        primaryPart.Material = Enum.Material.Neon
        primaryPart.Color = Color3.fromRGB(255, 100, 0)
    end
    
    -- Positionner la partie principale
    primaryPart.CFrame = CFrame.new(position) * rotation
    primaryPart.Parent = structureModel
    structureModel.PrimaryPart = primaryPart
    
    -- Créer le dossier de structures s'il n'existe pas
    local structuresFolder = Workspace:FindFirstChild("Structures")
    if not structuresFolder then
        structuresFolder = Instance.new("Folder")
        structuresFolder.Name = "Structures"
        structuresFolder.Parent = Workspace
    end
    
    -- Si c'est une porte, ajouter une fonction d'ouverture/fermeture
    if itemId == "wooden_door" then
        self:SetupDoor(structureModel)
    end
    
    -- Parenter au dossier de structures
    structureModel.Parent = structuresFolder
    
    return structureModel
end

-- Configurer une porte pour qu'elle puisse s'ouvrir et se fermer
function BuildingService:SetupDoor(doorModel)
    local primaryPart = doorModel.PrimaryPart
    if not primaryPart then return end
    
    -- Ajouter un attribut pour l'état de la porte
    doorModel:SetAttribute("DoorOpen", false)
    
    -- Ajouter un ClickDetector pour l'interaction
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 10
    clickDetector.Parent = primaryPart
    
    -- Gérer l'ouverture/fermeture
    clickDetector.MouseClick:Connect(function(player)
        local isOpen = doorModel:GetAttribute("DoorOpen")
        isOpen = not isOpen
        doorModel:SetAttribute("DoorOpen", isOpen)
        
        -- Tourner la porte
        local currentCFrame = primaryPart.CFrame
        local doorPivot = currentCFrame.Position - (currentCFrame.RightVector * primaryPart.Size.X/2)
        
        local targetRotation
        if isOpen then
            -- Ouvrir (tourner de 90 degrés)
            targetRotation = currentCFrame * CFrame.Angles(0, math.rad(90), 0)
        else
            -- Fermer (retourner à la position d'origine)
            targetRotation = CFrame.new(currentCFrame.Position) * (currentCFrame - currentCFrame.Position)
        end
        
        -- Animer l'ouverture/fermeture
        local duration = 0.5
        local startTime = tick()
        local initialCFrame = primaryPart.CFrame
        
        local connection
        connection = game:GetService("RunService").Heartbeat:Connect(function()
            local elapsed = tick() - startTime
            local alpha = math.min(elapsed / duration, 1)
            
            -- Interpolation pour une animation fluide
            primaryPart.CFrame = initialCFrame:Lerp(targetRotation, alpha)
            
            if alpha >= 1 then
                connection:Disconnect()
            end
        end)
    end)
end

-- Rendre un bâtiment interactif
function BuildingService:MakeBuildingInteractive(structureInstance, itemId)
    local primaryPart = structureInstance.PrimaryPart
    if not primaryPart then return end
    
    -- Ajouter un ClickDetector pour l'interaction
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 10
    clickDetector.Parent = primaryPart
    
    -- Fonction d'interaction basée sur le type de bâtiment
    clickDetector.MouseClick:Connect(function(player)
        -- Obtenir l'ID de la structure
        local structureId = structureInstance:GetAttribute("StructureId")
        if not structureId then return end
        
        -- Traiter différents types d'interactions
        if itemId == "wooden_bed" then
            -- Lit - permettre au joueur de dormir
            self:HandleBedInteraction(player, structureId)
        elseif itemId == "campfire" then
            -- Feu de camp - cuisson
            self:HandleCampfireInteraction(player, structureId)
        elseif itemId == "furnace" then
            -- Four - fonte
            self:HandleFurnaceInteraction(player, structureId)
        elseif itemId == "anvil" then
            -- Enclume - forge
            self:HandleAnvilInteraction(player, structureId)
        end
    end)
end

-- Gérer l'interaction avec un lit
function BuildingService:HandleBedInteraction(player, structureId)
    -- Vérifier si la structure existe
    local structureData = self.structuresById[structureId]
    if not structureData then return end
    
    -- Vérifier si le joueur a accès au lit
    if not self:CanPlayerInteractWithStructure(player, structureId) then
        self:SendNotification(player, "Vous n'avez pas accès à ce lit", "error")
        return
    end
    
    -- Déclencher l'action de sommeil
    if self.remoteEvents.PlayerAction then
        self.remoteEvents.PlayerAction:FireClient(player, "sleep")
    end
end

-- Gérer l'interaction avec un feu de camp
function BuildingService:HandleCampfireInteraction(player, structureId)
    -- Vérifier si la structure existe
    local structureData = self.structuresById[structureId]
    if not structureData then return end
    
    -- Vérifier si le joueur a accès au feu de camp
    if not self:CanPlayerInteractWithStructure(player, structureId) then
        self:SendNotification(player, "Vous n'avez pas accès à ce feu de camp", "error")
        return
    end
    
    -- Ouvrir l'interface de cuisson pour le joueur (à implémenter)
    self:SendNotification(player, "Ouverture de l'interface de cuisson", "info")
    -- Interface à implémenter
end

-- Gérer l'interaction avec un four
function BuildingService:HandleFurnaceInteraction(player, structureId)
    -- Vérifier si la structure existe
    local structureData = self.structuresById[structureId]
    if not structureData then return end
    
    -- Vérifier si le joueur a accès au four
    if not self:CanPlayerInteractWithStructure(player, structureId) then
        self:SendNotification(player, "Vous n'avez pas accès à ce four", "error")
        return
    end
    
    -- Ouvrir l'interface de fonte pour le joueur (à implémenter)
    self:SendNotification(player, "Ouverture de l'interface de fonte", "info")
    -- Interface à implémenter
end

-- Gérer l'interaction avec une enclume
function BuildingService:HandleAnvilInteraction(player, structureId)
    -- Vérifier si la structure existe
    local structureData = self.structuresById[structureId]
    if not structureData then return end
    
    -- Vérifier si le joueur a accès à l'enclume
    if not self:CanPlayerInteractWithStructure(player, structureId) then
        self:SendNotification(player, "Vous n'avez pas accès à cette enclume", "error")
        return
    end
    
    -- Ouvrir l'interface de forge pour le joueur (à implémenter)
    self:SendNotification(player, "Ouverture de l'interface de forge", "info")
    -- Interface à implémenter
end

-- Vérifier si un joueur peut interagir avec une structure
function BuildingService:CanPlayerInteractWithStructure(player, structureId)
    local userId = player.UserId
    local structureData = self.structuresById[structureId]
    
    if not structureData then return false end
    
    -- Le propriétaire peut toujours interagir avec sa structure
    if structureData.owner == userId then
        return true
    end
    
    -- Vérifier si le joueur est dans la même tribu que le propriétaire
    if self.tribeService then
        local playerTribeId = self.tribeService:GetPlayerTribeId(player)
        local ownerPlayer = Players:GetPlayerByUserId(structureData.owner)
        local ownerTribeId = ownerPlayer and self.tribeService:GetPlayerTribeId(ownerPlayer) or nil
        
        -- Si les deux joueurs sont dans la même tribu, permettre l'interaction
        if playerTribeId and ownerTribeId and playerTribeId == ownerTribeId then
            return true
        end
    end
    
    -- Par défaut, refuser l'accès
    return false
end

-- Vérifier si un bâtiment est interactif
function BuildingService:IsInteractiveBuilding(buildingType)
    -- Liste des bâtiments interactifs
    local interactiveTypes = {
        ["wooden_bed"] = true,
        ["campfire"] = true,
        ["furnace"] = true,
        ["anvil"] = true,
        ["wooden_door"] = true, -- Les portes sont interactives (ouverture/fermeture)
        ["wooden_chest"] = true -- Coffres pour stockage
    }
    
    return interactiveTypes[buildingType] or false
end

-- Détruire une structure
function BuildingService:DestroyStructure(structureId, byPlayer)
    local structureData = self.structuresById[structureId]
    if not structureData then return false, "Structure introuvable" end
    
    -- Vérifier si le joueur a le droit de détruire cette structure
    if byPlayer then
        if not self:CanPlayerModifyStructure(byPlayer, structureId) then
            self:SendNotification(byPlayer, "Vous n'avez pas le droit de détruire cette structure", "error")
            return false, "Permissions insuffisantes"
        end
    end
    
    -- Récupérer l'instance de la structure
    local structureInstance = structureData.instance
    
    -- Retourner une partie des matériaux au joueur qui détruit (si c'est un joueur)
    if byPlayer and self.inventoryService then
        local itemId = structureData.type
        local refundAmount = 1 -- Par défaut, retourner 1 unité
        
        -- Ajouter l'objet à l'inventaire du joueur
        self.inventoryService:AddItemToInventory(byPlayer, itemId, refundAmount)
        self:SendNotification(byPlayer, "Vous avez récupéré " .. refundAmount .. "x " .. (ItemTypes[itemId] and ItemTypes[itemId].name or itemId), "success")
    end
    
    -- Détruire l'instance physique
    if structureInstance then
        structureInstance:Destroy()
    end
    
    -- Supprimer les références à la structure
    if structureData.owner and self.playerStructures[structureData.owner] then
        self.playerStructures[structureData.owner][structureId] = nil
    end
    
    self.structuresById[structureId] = nil
    
    -- Informer les joueurs proches
    if structureData.position and byPlayer then
        self:NotifyNearbyPlayers(structureData.position, byPlayer.Name .. " a détruit " .. (ItemTypes[structureData.type] and ItemTypes[structureData.type].name or structureData.type), 30)
    end
    
    return true, "Structure détruite avec succès"
end

-- Vérifier si un joueur peut modifier une structure (détruire, réparer, etc.)
function BuildingService:CanPlayerModifyStructure(player, structureId)
    local userId = player.UserId
    local structureData = self.structuresById[structureId]
    
    if not structureData then return false end
    
    -- Le propriétaire peut toujours modifier sa structure
    if structureData.owner == userId then
        return true
    end
    
    -- Vérifier si le joueur a des permissions via la tribu
    if self.tribeService then
        local playerTribeId = self.tribeService:GetPlayerTribeId(player)
        local ownerPlayer = Players:GetPlayerByUserId(structureData.owner)
        local ownerTribeId = ownerPlayer and self.tribeService:GetPlayerTribeId(ownerPlayer) or nil
        
        -- Si les deux joueurs sont dans la même tribu, vérifier le rôle du joueur
        if playerTribeId and ownerTribeId and playerTribeId == ownerTribeId then
            local playerRole = self.tribeService:GetPlayerRole(player)
            -- Seuls les leaders et les anciens peuvent modifier les structures des autres
            if playerRole == "leader" or playerRole == "elder" then
                return true
            end
        end
    end
    
    -- Par défaut, refuser l'accès
    return false
end

-- Réparer une structure
function BuildingService:RepairStructure(player, structureId)
    local structureData = self.structuresById[structureId]
    if not structureData then 
        self:SendNotification(player, "Structure introuvable", "error")
        return false 
    end
    
    -- Vérifier si le joueur a le droit de réparer cette structure
    if not self:CanPlayerModifyStructure(player, structureId) then
        self:SendNotification(player, "Vous n'avez pas le droit de réparer cette structure", "error")
        return false
    end
    
    -- Vérifier si la structure a besoin de réparation
    local buildingType = structureData.type
    local maxDurability = self.buildingTypes[buildingType] and self.buildingTypes[buildingType].durability or 100
    
    if structureData.durability >= maxDurability then
        self:SendNotification(player, "Cette structure n'a pas besoin de réparation", "info")
        return false
    end
    
    -- Coût de réparation (matériaux nécessaires)
    local repairCost = {
        [buildingType] = 1 -- Par défaut, 1 unité du même type
    }
    
    -- Vérifier si le joueur a les matériaux nécessaires
    for itemId, amount in pairs(repairCost) do
        if not self.inventoryService:HasItemInInventory(player, itemId, amount) then
            self:SendNotification(player, "Matériaux insuffisants pour la réparation", "error")
            return false
        end
    end
    
    -- Retirer les matériaux
    for itemId, amount in pairs(repairCost) do
        self.inventoryService:RemoveItemFromInventory(player, itemId, amount)
    end
    
    -- Effectuer la réparation
    structureData.durability = maxDurability
    
    -- Mettre à jour l'apparence si nécessaire
    if structureData.instance and structureData.instance.PrimaryPart then
        structureData.instance.PrimaryPart.Color = Color3.fromRGB(255, 255, 255) -- Réinitialiser la couleur
    end
    
    self:SendNotification(player, "Structure réparée avec succès", "success")
    return true
end

-- Vérifier les structures endommagées qui pourraient s'effondrer
function BuildingService:CheckDamagedStructures()
    for structureId, structureData in pairs(self.structuresById) do
        -- Si la durabilité est nulle ou négative, la structure s'effondre
        if structureData.durability <= 0 then
            self:DestroyStructure(structureId)
        elseif structureData.durability < 30 then
            -- Avertir le propriétaire si la structure est très endommagée
            local owner = Players:GetPlayerByUserId(structureData.owner)
            if owner then
                self:SendNotification(owner, "Votre structure " .. (ItemTypes[structureData.type] and ItemTypes[structureData.type].name or structureData.type) .. " est gravement endommagée", "warning")
            end
        end
    end
end

-- Endommager une structure (par le temps, des attaques, etc.)
function BuildingService:DamageStructure(structureId, amount, cause)
    local structureData = self.structuresById[structureId]
    if not structureData then return false end
    
    -- Réduire la durabilité
    structureData.durability = math.max(0, structureData.durability - amount)
    
    -- Si la durabilité atteint 0, la structure sera détruite lors de la prochaine vérification
    if structureData.durability <= 0 then
        -- Destruction immédiate si configuré ainsi
        self:DestroyStructure(structureId)
        return true
    elseif structureData.durability < 30 then
        -- Changer l'apparence pour montrer qu'elle est endommagée
        if structureData.instance and structureData.instance.PrimaryPart then
            structureData.instance.PrimaryPart.Color = Color3.fromRGB(150, 150, 150) -- Grisé pour indiquer des dommages
        end
    end
    
    return true
end

-- Notifier les joueurs proches d'une position
function BuildingService:NotifyNearbyPlayers(position, message, radius)
    radius = radius or 50
    
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local distance = (character.HumanoidRootPart.Position - position).Magnitude
            
            if distance <= radius then
                self:SendNotification(player, message, "info")
            end
        end
    end
end

-- Envoyer une notification à un joueur
function BuildingService:SendNotification(player, message, messageType)
    if self.remoteEvents.Notification then
        self.remoteEvents.Notification:FireClient(player, message, messageType or "info")
    else
        -- Fallback si le RemoteEvent n'est pas disponible
        print("Notification pour " .. player.Name .. ": " .. message)
    end
end

-- Initialiser le service
function BuildingService:Start(services)
    print("BuildingService: Démarrage...")
    
    -- Récupérer les références aux autres services
    self.inventoryService = services.InventoryService
    self.tribeService = services.TribeService
    
    if not self.inventoryService then
        warn("BuildingService: InventoryService non disponible. Certaines fonctionnalités seront limitées.")
    end
    
    -- Récupérer les références aux RemoteEvents
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if Events then
        self.remoteEvents = {
            BuildingStart = Events:FindFirstChild("BuildingStart"),
            BuildingPlacement = Events:FindFirstChild("BuildingPlacement"),
            Notification = Events:FindFirstChild("Notification"),
            PlayerAction = Events:FindFirstChild("PlayerAction")
        }
    else
        warn("BuildingService: Dossier Events non trouvé dans ReplicatedStorage")
    end
    
    -- Initialiser les structures pour les joueurs déjà connectés
    for _, player in ipairs(Players:GetPlayers()) do
        self:InitializePlayerStructures(player)
    end
    
    -- Gérer les nouveaux joueurs
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerStructures(player)
    end)
    
    -- Gérer les déconnexions de joueurs
    Players.PlayerRemoving:Connect(function(player)
        local userId = player.UserId
        
        -- Annuler le mode construction si actif
        if self.buildingMode[userId] then
            self:CancelPlacement(player)
        end
        
        -- Sauvegarde des structures du joueur (dans une implémentation réelle)
        -- self:SavePlayerStructures(player)
    end)
    
    -- Démarrer la vérification périodique des structures endommagées
    spawn(function()
        while true do
            wait(60) -- Vérifier toutes les minutes
            pcall(function()
                self:CheckDamagedStructures()
            end)
        end
    end)
    
    print("BuildingService: Démarré avec succès")
    return self
end

return BuildingService
