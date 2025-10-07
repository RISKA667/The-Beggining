-- src/server/services/FarmingService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemTypes = require(Shared.constants.ItemTypes)
local GameSettings = require(Shared.constants.GameSettings)

local FarmingService = {}
FarmingService.__index = FarmingService

-- Créer une instance du service
function FarmingService.new()
    local self = setmetatable({}, FarmingService)
    
    -- Cultures plantées
    self.plantedCrops = {}  -- [cropId] = {crop data}
    self.nextCropId = 1
    
    -- Cultures par joueur
    self.playerCrops = {}  -- [userId] = {cropId1, cropId2, ...}
    
    -- Références aux services
    self.inventoryService = nil
    self.tribeService = nil
    
    -- RemoteEvents
    self.remoteEvents = {}
    
    -- Stades de croissance
    self.growthStages = {
        [1] = {name = "Graine", scale = 0.1, color = Color3.fromRGB(139, 69, 19)},
        [2] = {name = "Pousse", scale = 0.3, color = Color3.fromRGB(34, 139, 34)},
        [3] = {name = "Jeune plante", scale = 0.5, color = Color3.fromRGB(50, 205, 50)},
        [4] = {name = "Plante mature", scale = 0.8, color = Color3.fromRGB(34, 139, 34)},
        [5] = {name = "Prêt à récolter", scale = 1.0, color = Color3.fromRGB(255, 215, 0)}
    }
    
    return self
end

-- Planter une graine
function FarmingService:PlantSeed(player, seedItemId, position)
    if not player or not player:IsA("Player") then
        return false, "Joueur invalide"
    end
    
    local userId = player.UserId
    
    -- Vérifier que la graine existe et est plantable
    local seedType = ItemTypes[seedItemId]
    if not seedType or seedType.category ~= "seed" or not seedType.plantable then
        self:SendNotification(player, "Cet objet ne peut pas être planté", "error")
        return false, "Objet non plantable"
    end
    
    -- Vérifier que le joueur a la graine dans son inventaire
    if not self.inventoryService or not self.inventoryService:HasItemInInventory(player, seedItemId, 1) then
        self:SendNotification(player, "Vous n'avez pas cette graine dans votre inventaire", "error")
        return false, "Graine manquante"
    end
    
    -- Vérifier la position de plantation
    if not self:IsValidPlantingPosition(player, position) then
        self:SendNotification(player, "Vous ne pouvez pas planter ici", "error")
        return false, "Position invalide"
    end
    
    -- Vérifier qu'il n'y a pas déjà une culture à cet endroit
    if self:GetCropAtPosition(position) then
        self:SendNotification(player, "Une plante pousse déjà ici", "error")
        return false, "Emplacement occupé"
    end
    
    -- Retirer la graine de l'inventaire
    if not self.inventoryService:RemoveItemFromInventory(player, seedItemId, 1) then
        self:SendNotification(player, "Impossible de retirer la graine de l'inventaire", "error")
        return false, "Erreur d'inventaire"
    end
    
    -- Créer la culture
    local cropId = "crop_" .. self.nextCropId
    self.nextCropId = self.nextCropId + 1
    
    local cropData = {
        id = cropId,
        seedId = seedItemId,
        growsInto = seedType.growsInto,
        owner = userId,
        plantTime = os.time(),
        growthTime = seedType.growthTime or 1200,  -- 20 minutes par défaut
        stage = 1,  -- Stade de croissance (1-5)
        position = position,
        instance = nil,
        health = 100,
        watered = false,
        lastWaterTime = 0
    }
    
    -- Créer l'instance visuelle de la culture
    local cropInstance = self:CreateCropInstance(cropData)
    if cropInstance then
        cropData.instance = cropInstance
        
        -- Stocker la culture
        self.plantedCrops[cropId] = cropData
        
        -- Associer à ce joueur
        if not self.playerCrops[userId] then
            self.playerCrops[userId] = {}
        end
        table.insert(self.playerCrops[userId], cropId)
        
        -- Notifier le joueur
        self:SendNotification(player, "Graine plantée avec succès", "success")
        
        -- Démarrer la croissance
        self:StartGrowth(cropId)
        
        return true, "Plantation réussie"
    else
        -- Remettre la graine si la création échoue
        self.inventoryService:AddItemToInventory(player, seedItemId, 1)
        return false, "Erreur de création"
    end
end

-- Vérifier si une position est valide pour planter
function FarmingService:IsValidPlantingPosition(player, position)
    -- Vérifier que la position n'est pas nil
    if not position or typeof(position) ~= "Vector3" then
        return false
    end
    
    -- Vérifier que le joueur est à proximité
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local distance = (character.HumanoidRootPart.Position - position).Magnitude
    if distance > 10 then  -- Maximum 10 studs
        return false
    end
    
    -- Vérifier qu'il y a du sol sous la position
    local rayOrigin = position + Vector3.new(0, 5, 0)
    local rayDirection = Vector3.new(0, -10, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    local hitPart = raycastResult and raycastResult.Instance
    local hitPoint = raycastResult and raycastResult.Position
    
    if not hitPart then
        return false
    end
    
    -- Vérifier que c'est du terrain ou une surface appropriée
    -- (Dans une version plus avancée, on pourrait vérifier le type de matériau)
    
    return true
end

-- Obtenir une culture à une position donnée
function FarmingService:GetCropAtPosition(position)
    for cropId, cropData in pairs(self.plantedCrops) do
        if cropData.position and (cropData.position - position).Magnitude < 2 then
            return cropId, cropData
        end
    end
    return nil
end

-- Créer l'instance visuelle d'une culture
function FarmingService:CreateCropInstance(cropData)
    -- Créer un modèle pour la culture
    local cropModel = Instance.new("Model")
    cropModel.Name = "Crop"
    
    -- Partie principale
    local primaryPart = Instance.new("Part")
    primaryPart.Name = "PrimaryPart"
    primaryPart.Anchored = true
    primaryPart.CanCollide = false
    primaryPart.Material = Enum.Material.Grass
    
    -- Taille et couleur selon le stade
    local stage = self.growthStages[cropData.stage]
    primaryPart.Size = Vector3.new(1, 2, 1) * stage.scale
    primaryPart.Color = stage.color
    
    -- Positionner
    primaryPart.Position = cropData.position + Vector3.new(0, primaryPart.Size.Y / 2, 0)
    primaryPart.Parent = cropModel
    cropModel.PrimaryPart = primaryPart
    
    -- Ajouter des attributs
    cropModel:SetAttribute("CropId", cropData.id)
    cropModel:SetAttribute("Stage", cropData.stage)
    cropModel:SetAttribute("Owner", cropData.owner)
    
    -- Ajouter un ClickDetector pour l'interaction
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.MaxActivationDistance = 10
    clickDetector.Parent = primaryPart
    
    -- Connecter l'événement de clic
    clickDetector.MouseClick:Connect(function(player)
        self:HandleCropClick(player, cropData.id)
    end)
    
    -- Créer le dossier de cultures s'il n'existe pas
    local cropsFolder = Workspace:FindFirstChild("Crops")
    if not cropsFolder then
        cropsFolder = Instance.new("Folder")
        cropsFolder.Name = "Crops"
        cropsFolder.Parent = Workspace
    end
    
    cropModel.Parent = cropsFolder
    
    return cropModel
end

-- Gérer le clic sur une culture
function FarmingService:HandleCropClick(player, cropId)
    local cropData = self.plantedCrops[cropId]
    if not cropData then return end
    
    -- Si la culture est prête à récolter (stade 5)
    if cropData.stage >= 5 then
        self:HarvestCrop(player, cropId)
    else
        -- Afficher l'état de la culture
        local remainingTime = self:GetRemainingGrowthTime(cropId)
        local minutesLeft = math.ceil(remainingTime / 60)
        
        local stageName = self.growthStages[cropData.stage].name
        self:SendNotification(player, "État: " .. stageName .. " - Prête dans ~" .. minutesLeft .. " min", "info")
    end
end

-- Récolter une culture
function FarmingService:HarvestCrop(player, cropId)
    local cropData = self.plantedCrops[cropId]
    if not cropData then
        self:SendNotification(player, "Culture introuvable", "error")
        return false
    end
    
    -- Vérifier que la culture est prête
    if cropData.stage < 5 then
        self:SendNotification(player, "Cette plante n'est pas encore prête à être récoltée", "warning")
        return false
    end
    
    -- Vérifier que le joueur est à proximité
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        return false
    end
    
    local distance = (character.HumanoidRootPart.Position - cropData.position).Magnitude
    if distance > 10 then
        self:SendNotification(player, "Vous êtes trop loin de cette plante", "error")
        return false
    end
    
    -- Déterminer le rendement
    local cropType = ItemTypes[cropData.growsInto]
    if not cropType then
        warn("FarmingService: Type de culture invalide - " .. tostring(cropData.growsInto))
        return false
    end
    
    -- Quantité récoltée (2-4 pour une récolte normale)
    local baseYield = math.random(2, 4)
    local bonusYield = 0
    
    -- Bonus si la plante était arrosée
    if cropData.watered then
        bonusYield = bonusYield + 1
    end
    
    local totalYield = baseYield + bonusYield
    
    -- Ajouter les produits à l'inventaire
    if self.inventoryService then
        local success = self.inventoryService:AddItemToInventory(player, cropData.growsInto, totalYield)
        
        if success then
            -- Notifier le joueur
            self:SendNotification(player, "Vous avez récolté " .. totalYield .. " " .. cropType.name, "success")
            
            -- Envoyer un événement au client
            if self.remoteEvents.HarvestCrop then
                self.remoteEvents.HarvestCrop:FireClient(player, cropData.growsInto, totalYield)
            end
            
            -- Détruire la culture
            self:DestroyCrop(cropId)
            
            return true
        else
            self:SendNotification(player, "Inventaire plein", "error")
            return false
        end
    end
    
    return false
end

-- Arroser une culture
function FarmingService:WaterCrop(player, cropId)
    local cropData = self.plantedCrops[cropId]
    if not cropData then return false end
    
    -- Vérifier que le joueur a de l'eau
    if not self.inventoryService or not self.inventoryService:HasItemInInventory(player, "water_container", 1) then
        self:SendNotification(player, "Vous avez besoin d'eau pour arroser", "warning")
        return false
    end
    
    -- Vérifier qu'elle n'est pas déjà arrosée récemment
    local timeSinceWater = os.time() - cropData.lastWaterTime
    if timeSinceWater < 300 then  -- 5 minutes
        self:SendNotification(player, "Cette plante a été arrosée récemment", "info")
        return false
    end
    
    -- Arroser
    cropData.watered = true
    cropData.lastWaterTime = os.time()
    
    -- Accélérer légèrement la croissance (10% plus rapide)
    cropData.growthTime = math.floor(cropData.growthTime * 0.9)
    
    self:SendNotification(player, "Plante arrosée", "success")
    
    return true
end

-- Démarrer la croissance d'une culture
function FarmingService:StartGrowth(cropId)
    local cropData = self.plantedCrops[cropId]
    if not cropData then return end
    
    -- La croissance sera gérée par la boucle de mise à jour
    -- Nous n'avons pas besoin de créer un nouveau thread pour chaque culture
end

-- Calculer le temps de croissance restant
function FarmingService:GetRemainingGrowthTime(cropId)
    local cropData = self.plantedCrops[cropId]
    if not cropData then return 0 end
    
    local elapsedTime = os.time() - cropData.plantTime
    local timePerStage = cropData.growthTime / 5  -- 5 stades
    local timeForCurrentStage = timePerStage * cropData.stage
    
    return math.max(0, cropData.growthTime - elapsedTime)
end

-- Mettre à jour la croissance d'une culture
function FarmingService:UpdateCropGrowth(cropId)
    local cropData = self.plantedCrops[cropId]
    if not cropData then return end
    
    -- Calculer le stade actuel basé sur le temps écoulé
    local elapsedTime = os.time() - cropData.plantTime
    local timePerStage = cropData.growthTime / 5
    local newStage = math.min(5, math.floor(elapsedTime / timePerStage) + 1)
    
    -- Mettre à jour le stade si changé
    if newStage ~= cropData.stage then
        cropData.stage = newStage
        
        -- Mettre à jour l'apparence
        self:UpdateCropAppearance(cropId)
        
        -- Notifier le propriétaire si connecté
        local owner = Players:GetPlayerByUserId(cropData.owner)
        if owner and newStage == 5 then
            self:SendNotification(owner, "Une de vos plantes est prête à être récoltée!", "success")
        end
    end
end

-- Mettre à jour l'apparence d'une culture
function FarmingService:UpdateCropAppearance(cropId)
    local cropData = self.plantedCrops[cropId]
    if not cropData or not cropData.instance then return end
    
    local primaryPart = cropData.instance.PrimaryPart
    if not primaryPart then return end
    
    local stage = self.growthStages[cropData.stage]
    if not stage then return end
    
    -- Mettre à jour la taille et la couleur
    local targetSize = Vector3.new(1, 2, 1) * stage.scale
    primaryPart.Size = targetSize
    primaryPart.Color = stage.color
    
    -- Repositionner pour que la base reste au sol
    local position = cropData.position + Vector3.new(0, targetSize.Y / 2, 0)
    primaryPart.Position = position
    
    -- Mettre à jour l'attribut du stade
    cropData.instance:SetAttribute("Stage", cropData.stage)
end

-- Détruire une culture
function FarmingService:DestroyCrop(cropId)
    local cropData = self.plantedCrops[cropId]
    if not cropData then return end
    
    -- Détruire l'instance visuelle
    if cropData.instance then
        cropData.instance:Destroy()
    end
    
    -- Retirer des données
    self.plantedCrops[cropId] = nil
    
    -- Retirer de la liste du joueur
    if self.playerCrops[cropData.owner] then
        for i, cId in ipairs(self.playerCrops[cropData.owner]) do
            if cId == cropId then
                table.remove(self.playerCrops[cropData.owner], i)
                break
            end
        end
    end
end

-- Nettoyer les cultures d'un joueur qui se déconnecte
function FarmingService:HandlePlayerRemoving(player)
    local userId = player.UserId
    
    -- Sauvegarder les cultures du joueur (dans une implémentation complète)
    -- Pour l'instant, on les laisse pousser
    
    -- Les cultures continuent de pousser même si le joueur se déconnecte
    -- Elles seront disponibles à son retour
end

-- Envoyer une notification
function FarmingService:SendNotification(player, message, messageType)
    if self.remoteEvents.Notification then
        self.remoteEvents.Notification:FireClient(player, message, messageType or "info")
    else
        print("Notification pour " .. player.Name .. ": " .. message)
    end
end

-- Démarrer le service
function FarmingService:Start(services)
    print("FarmingService: Démarrage...")
    
    -- Récupérer les références aux autres services
    self.inventoryService = services.InventoryService
    self.tribeService = services.TribeService
    
    -- Récupérer les références aux RemoteEvents
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if Events then
        self.remoteEvents = {
            PlantSeed = Events:FindFirstChild("PlantSeed"),
            HarvestCrop = Events:FindFirstChild("HarvestCrop"),
            UpdateCrop = Events:FindFirstChild("UpdateCrop"),
            Notification = Events:FindFirstChild("Notification")
        }
        
        -- Connecter les événements
        if self.remoteEvents.PlantSeed then
            self.remoteEvents.PlantSeed.OnServerEvent:Connect(function(player, seedId, position)
                self:PlantSeed(player, seedId, position)
            end)
        end
        
        if self.remoteEvents.HarvestCrop then
            self.remoteEvents.HarvestCrop.OnServerEvent:Connect(function(player, cropId)
                self:HarvestCrop(player, cropId)
            end)
        end
    else
        warn("FarmingService: Dossier Events non trouvé dans ReplicatedStorage")
    end
    
    -- Démarrer la boucle de mise à jour des cultures
    spawn(function()
        while true do
            wait(30)  -- Mettre à jour toutes les 30 secondes
            
            for cropId, _ in pairs(self.plantedCrops) do
                pcall(function()
                    self:UpdateCropGrowth(cropId)
                end)
            end
        end
    end)
    
    -- Gérer les déconnexions de joueurs
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
    
    print("FarmingService: Démarré avec succès")
    return self
end

return FarmingService
