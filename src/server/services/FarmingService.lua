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
    -- Collision activée pour les plantes matures (stade 4 et 5)
    primaryPart.CanCollide = (cropData.stage >= 4)
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
    
    -- Bonus si la plante était fertilisée
    if cropData.fertilized then
        bonusYield = bonusYield + 2
    end
    
    -- Malus si la plante est en mauvaise santé
    if cropData.health < 50 then
        bonusYield = bonusYield - 1
    end
    
    local totalYield = math.max(1, baseYield + bonusYield)
    
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
            -- Inventaire plein : la plante reste récoltable
            self:SendNotification(player, "Inventaire plein, la plante reste prête à récolter", "warning")
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
    
    -- Consommer l'eau
    self.inventoryService:RemoveItemFromInventory(player, "water_container", 1)
    
    self:SendNotification(player, "Plante arrosée", "success")
    
    return true
end

-- Endommager une culture
function FarmingService:DamageCrop(cropId, damage, cause)
    local cropData = self.plantedCrops[cropId]
    if not cropData then return false end
    
    -- Réduire la santé
    cropData.health = math.max(0, cropData.health - damage)
    
    -- Mettre à jour l'apparence pour refléter la santé
    self:UpdateCropAppearance(cropId)
    
    -- Si la santé atteint 0, détruire la culture
    if cropData.health <= 0 then
        -- Notifier le propriétaire
        local owner = game:GetService("Players"):GetPlayerByUserId(cropData.owner)
        if owner then
            local causeName = cause or "inconnue"
            self:SendNotification(owner, "Une de vos plantes est morte (cause: " .. causeName .. ")", "error")
        end
        
        self:DestroyCrop(cropId)
        return true
    end
    
    return true
end

-- Soigner une culture (avec engrais ou soin)
function FarmingService:HealCrop(cropId, healAmount)
    local cropData = self.plantedCrops[cropId]
    if not cropData then return false end
    
    cropData.health = math.min(100, cropData.health + healAmount)
    
    -- Mettre à jour l'apparence
    self:UpdateCropAppearance(cropId)
    
    return true
end

-- Appliquer de l'engrais à une culture
function FarmingService:ApplyFertilizer(player, cropId, fertilizerType)
    local cropData = self.plantedCrops[cropId]
    if not cropData then
        self:SendNotification(player, "Culture introuvable", "error")
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
    
    -- Vérifier que le joueur a l'engrais
    local fertilizerItemId = fertilizerType or "fertilizer"
    if not self.inventoryService or not self.inventoryService:HasItemInInventory(player, fertilizerItemId, 1) then
        self:SendNotification(player, "Vous n'avez pas d'engrais", "error")
        return false
    end
    
    -- Retirer l'engrais de l'inventaire
    self.inventoryService:RemoveItemFromInventory(player, fertilizerItemId, 1)
    
    -- Effets de l'engrais
    -- 1. Accélérer la croissance (30% plus rapide)
    cropData.growthTime = math.floor(cropData.growthTime * 0.7)
    
    -- 2. Soigner la plante
    self:HealCrop(cropId, 20)
    
    -- 3. Augmenter le rendement potentiel (marqueur pour la récolte)
    cropData.fertilized = true
    
    self:SendNotification(player, "Engrais appliqué avec succès", "success")
    
    return true
end

-- Système de maladies et parasites
function FarmingService:CheckCropDiseases(cropId)
    local cropData = self.plantedCrops[cropId]
    if not cropData then return end
    
    -- Maladies possibles
    local diseases = {
        {id = "blight", name = "Mildiou", chance = 0.01, damage = 5},
        {id = "aphids", name = "Pucerons", chance = 0.015, damage = 3},
        {id = "rot", name = "Pourriture", chance = 0.008, damage = 10}
    }
    
    -- Vérifier si la plante n'est pas déjà malade
    if cropData.diseased then
        -- Appliquer les dégâts de la maladie existante
        for _, disease in ipairs(diseases) do
            if cropData.disease == disease.id then
                self:DamageCrop(cropId, disease.damage, disease.name)
                break
            end
        end
        return
    end
    
    -- Chance d'attraper une maladie
    -- Réduite si la plante est arrosée et en bonne santé
    local baseChance = 1
    if cropData.watered then
        baseChance = baseChance * 0.5
    end
    if cropData.health > 70 then
        baseChance = baseChance * 0.5
    end
    
    -- Vérifier chaque maladie
    for _, disease in ipairs(diseases) do
        if math.random() < (disease.chance * baseChance) then
            cropData.diseased = true
            cropData.disease = disease.id
            
            -- Notifier le propriétaire
            local owner = game:GetService("Players"):GetPlayerByUserId(cropData.owner)
            if owner then
                self:SendNotification(owner, "Une de vos plantes a attrapé: " .. disease.name, "warning")
            end
            
            break
        end
    end
end

-- Traiter une maladie de culture
function FarmingService:TreatCropDisease(player, cropId)
    local cropData = self.plantedCrops[cropId]
    if not cropData then
        self:SendNotification(player, "Culture introuvable", "error")
        return false
    end
    
    if not cropData.diseased then
        self:SendNotification(player, "Cette plante n'est pas malade", "info")
        return false
    end
    
    -- Vérifier que le joueur a un traitement
    local treatmentItemId = "plant_medicine"
    if not self.inventoryService or not self.inventoryService:HasItemInInventory(player, treatmentItemId, 1) then
        self:SendNotification(player, "Vous avez besoin d'un traitement pour plantes", "error")
        return false
    end
    
    -- Retirer le traitement
    self.inventoryService:RemoveItemFromInventory(player, treatmentItemId, 1)
    
    -- Guérir la plante
    cropData.diseased = false
    cropData.disease = nil
    
    -- Soigner un peu la plante
    self:HealCrop(cropId, 15)
    
    self:SendNotification(player, "Plante traitée avec succès", "success")
    
    return true
end

-- Système d'irrigation automatique
function FarmingService:CheckAutoIrrigation(cropId)
    local cropData = self.plantedCrops[cropId]
    if not cropData then return end
    
    -- Vérifier s'il y a un système d'irrigation à proximité
    local cropsFolder = game:GetService("Workspace"):FindFirstChild("Crops")
    if not cropsFolder then return end
    
    local structuresFolder = game:GetService("Workspace"):FindFirstChild("Structures")
    if not structuresFolder then return end
    
    -- Chercher un système d'irrigation dans un rayon de 15 studs
    for _, structure in ipairs(structuresFolder:GetChildren()) do
        if structure:GetAttribute("BuildingType") == "irrigation_system" and structure.PrimaryPart then
            local distance = (structure.PrimaryPart.Position - cropData.position).Magnitude
            
            if distance <= 15 then
                -- Arroser automatiquement si pas arrosée récemment
                local timeSinceWater = os.time() - cropData.lastWaterTime
                if timeSinceWater >= 600 then -- 10 minutes
                    cropData.watered = true
                    cropData.lastWaterTime = os.time()
                    cropData.growthTime = math.floor(cropData.growthTime * 0.95)
                    
                    -- Soigner légèrement la plante
                    self:HealCrop(cropId, 5)
                end
                break
            end
        end
    end
end

-- Système de saisons
function FarmingService:GetCurrentSeason()
    -- Obtenir le temps du jeu (cycle jour/nuit)
    local timeService = self.timeService
    if timeService and timeService.GetCurrentSeason then
        return timeService:GetCurrentSeason()
    end
    
    -- Fallback : utiliser le temps système
    local month = tonumber(os.date("%m"))
    
    if month >= 3 and month <= 5 then
        return "spring" -- Printemps
    elseif month >= 6 and month <= 8 then
        return "summer" -- Été
    elseif month >= 9 and month <= 11 then
        return "autumn" -- Automne
    else
        return "winter" -- Hiver
    end
end

-- Obtenir le modificateur de croissance selon la saison
function FarmingService:GetSeasonGrowthModifier(cropType)
    local season = self:GetCurrentSeason()
    
    -- Définir les saisons favorables pour chaque type de culture
    local seasonPreferences = {
        -- Légumes de printemps
        ["wheat_seed"] = {spring = 1.3, summer = 1.0, autumn = 0.8, winter = 0.5},
        ["carrot_seed"] = {spring = 1.2, summer = 0.9, autumn = 1.1, winter = 0.6},
        
        -- Légumes d'été
        ["tomato_seed"] = {spring = 0.8, summer = 1.4, autumn = 0.9, winter = 0.3},
        ["corn_seed"] = {spring = 0.7, summer = 1.3, autumn = 1.0, winter = 0.4},
        
        -- Légumes d'automne
        ["pumpkin_seed"] = {spring = 0.9, summer = 1.0, autumn = 1.3, winter = 0.5},
        
        -- Cultures hivernales (rares)
        ["winter_wheat_seed"] = {spring = 0.8, summer = 0.6, autumn = 1.1, winter = 1.2}
    }
    
    local preferences = seasonPreferences[cropType]
    if preferences and preferences[season] then
        return preferences[season]
    end
    
    -- Par défaut, toutes les saisons sauf l'hiver
    if season == "winter" then
        return 0.5 -- Croissance ralentie en hiver
    elseif season == "spring" then
        return 1.2 -- Croissance accélérée au printemps
    else
        return 1.0 -- Croissance normale
    end
end

-- Appliquer l'effet des saisons lors de la croissance
function FarmingService:ApplySeasonalEffects(cropId)
    local cropData = self.plantedCrops[cropId]
    if not cropData then return end
    
    local seasonModifier = self:GetSeasonGrowthModifier(cropData.seedId)
    
    -- Ajuster le temps de croissance selon la saison
    -- Plus le modificateur est élevé, plus la croissance est rapide
    if not cropData.originalGrowthTime then
        cropData.originalGrowthTime = cropData.growthTime
    end
    
    -- Recalculer le temps de croissance
    cropData.growthTime = math.floor(cropData.originalGrowthTime / seasonModifier)
    
    -- En hiver, les plantes peuvent perdre de la santé
    if self:GetCurrentSeason() == "winter" and math.random() < 0.05 then
        self:DamageCrop(cropId, 2, "froid")
    end
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
    
    -- Modifier la couleur en fonction de la santé
    if cropData.health < 30 then
        -- Plante en mauvaise santé : teinte brunâtre
        primaryPart.Color = Color3.fromRGB(139, 90, 43)
    elseif cropData.health < 60 then
        -- Plante en santé moyenne : teinte jaunâtre
        primaryPart.Color = Color3.new(
            stage.color.R * 0.9,
            stage.color.G * 0.8,
            stage.color.B * 0.5
        )
    else
        -- Plante en bonne santé : couleur normale
        primaryPart.Color = stage.color
    end
    
    -- Repositionner pour que la base reste au sol
    local position = cropData.position + Vector3.new(0, targetSize.Y / 2, 0)
    primaryPart.Position = position
    
    -- Activer la collision pour les plantes matures
    primaryPart.CanCollide = (cropData.stage >= 4)
    
    -- Mettre à jour l'attribut du stade
    cropData.instance:SetAttribute("Stage", cropData.stage)
    cropData.instance:SetAttribute("Health", cropData.health)
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
                    -- Vérifier les maladies toutes les 30 secondes
                    self:CheckCropDiseases(cropId)
                    -- Vérifier l'irrigation automatique
                    self:CheckAutoIrrigation(cropId)
                    -- Appliquer les effets saisonniers
                    self:ApplySeasonalEffects(cropId)
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
