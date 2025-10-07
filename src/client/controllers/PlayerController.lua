-- src/client/controllers/PlayerController.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared.constants.GameSettings)
local ItemTypes = require(Shared.constants.ItemTypes)

local PlayerController = {}
PlayerController.__index = PlayerController

function PlayerController.new()
    local self = setmetatable({}, PlayerController)

    -- Référence au joueur local
    self.player = Players.LocalPlayer

    -- Référence au contrôleur UI (sera initialisé dans Initialize)
    self.uiController = nil

    -- État actuel du personnage
    self.characterState = {
        isWalking = false,
        isRunning = false,
        isSleeping = false,
        isBuilding = false,
        isHarvesting = false,
        targetResource = nil,
        buildingPreview = nil,
        equippedTool = nil
    }

    -- Constantes
    self.walkSpeed = GameSettings.Player.walkSpeed
    self.runSpeed = GameSettings.Player.runSpeed
    self.interactionDistance = GameSettings.Player.interactionDistance

    return self
end

function PlayerController:Initialize(uiController)
    self.uiController = uiController

    -- Attendre que le personnage soit chargé
    if not self.player.Character then
        self.player.CharacterAdded:Wait()
    end

    -- Configurer les actions et contrôles
    self:SetupControls()

    -- Configurer les événements du personnage
    self:SetupCharacterEvents()

    -- Configurer les événements du serveur
    self:SetupServerEvents()

    print("PlayerController: Initialisé")
end

-- Configurer les contrôles du joueur
function PlayerController:SetupControls()
    -- Course (Shift)
    ContextActionService:BindAction("Sprint", function(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            self:StartSprinting()
        elseif inputState == Enum.UserInputState.End then
            self:StopSprinting()
        end
    end, false, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift)

    -- Interaction (F)
    ContextActionService:BindAction("Interact", function(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            self:TryInteract()
        end
    end, false, Enum.KeyCode.F)

    -- Inventaire (E)
    ContextActionService:BindAction("Inventory", function(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            if self.uiController then
                self.uiController:ToggleInventory()
            end
        end
    end, false, Enum.KeyCode.E)

    -- Artisanat (C)
    ContextActionService:BindAction("Crafting", function(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            if self.uiController then
                self.uiController:ToggleCrafting()
            end
        end
    end, false, Enum.KeyCode.C)

    -- Touche d'annulation (Échap) - Pour annuler la construction, etc.
    ContextActionService:BindAction("Cancel", function(actionName, inputState, inputObject)
        if inputState == Enum.UserInputState.Begin then
            self:CancelCurrentAction()
        end
    end, false, Enum.KeyCode.Escape)

    -- Touches d'action rapide pour outils (1-5)
    for i = 1, 5 do
        local keyCode = Enum.KeyCode["Number" .. i]
        ContextActionService:BindAction("QuickSlot" .. i, function(actionName, inputState, inputObject)
            if inputState == Enum.UserInputState.Begin then
                self:SelectQuickSlot(i)
            end
        end, false, keyCode)
    end

    -- Clic pour attaquer ou placer un bâtiment
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.characterState.isBuilding then
                self:TryPlaceBuilding()
            else
                self:TryAttackOrHarvest()
            end
        end

        -- Clic droit pour rotation lors de construction
        if input.UserInputType == Enum.UserInputType.MouseButton2 and self.characterState.isBuilding then
            self:RotateBuildingPreview()
        end
    end)

    -- Mouvement de souris pour mettre à jour la position du prévisualisation de construction
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if self.characterState.isBuilding and self.characterState.buildingPreview then
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                self:UpdateBuildingPreviewPosition()
            end
        end
    end)

    print("PlayerController: Contrôles configurés")
end

-- Configurer les événements liés au personnage
function PlayerController:SetupCharacterEvents()
    -- Gérer les personnages existants et futurs
    if self.player.Character then
        self:SetupCharacter(self.player.Character)
    end

    self.player.CharacterAdded:Connect(function(character)
        self:SetupCharacter(character)
    end)

    print("PlayerController: Événements du personnage configurés")
end

-- Configurer un personnage spécifique
function PlayerController:SetupCharacter(character)
    -- Référence à l'humanoid
    local humanoid = character:WaitForChild("Humanoid")

    -- Configurer la vitesse initiale
    humanoid.WalkSpeed = self.walkSpeed

    -- Réinitialiser l'état du personnage
    self.characterState = {
        isWalking = false,
        isRunning = false,
        isSleeping = false,
        isBuilding = false,
        isHarvesting = false,
        targetResource = nil,
        buildingPreview = nil,
        equippedTool = nil
    }

    -- Événement de mouvement
    humanoid.Running:Connect(function(speed)
        self.characterState.isWalking = speed > 0.1
    end)

    -- Événement de mort
    humanoid.Died:Connect(function()
        self:HandleCharacterDied()
    end)

    -- Événement de changement d'état
    humanoid.StateChanged:Connect(function(oldState, newState)
        self:HandleStateChanged(oldState, newState)
    end)
end

-- Configurer les événements du serveur
function PlayerController:SetupServerEvents()
    local events = ReplicatedStorage:FindFirstChild("Events")

    if events then
        -- Mise à jour de l'inventaire
        local updateInventoryEvent = events:FindFirstChild("UpdateInventory")
        if updateInventoryEvent then
            updateInventoryEvent.OnClientEvent:Connect(function(inventoryData)
                self:HandleInventoryUpdate(inventoryData)
            end)
        end

        -- Notification de début de construction
        local buildingStartEvent = events:FindFirstChild("BuildingStart")
        if buildingStartEvent then
            buildingStartEvent.OnClientEvent:Connect(function(itemId, previewInstance)
                self:StartBuilding(itemId, previewInstance)
            end)
        end

        -- Notification de sommeil
        local sleepEvent = events:FindFirstChild("Sleep")
        if sleepEvent then
            sleepEvent.OnClientEvent:Connect(function(isSleeping)
                self:SetSleepingState(isSleeping)
            end)
        end

        -- Notification générale
        local notificationEvent = events:FindFirstChild("Notification")
        if notificationEvent then
            notificationEvent.OnClientEvent:Connect(function(message, messageType, duration)
                if self.uiController then
                    self.uiController:DisplayMessage(message, messageType, duration)
                end
            end)
        end

        -- Notification de mort
        local deathEvent = events:FindFirstChild("Death")
        if deathEvent then
            deathEvent.OnClientEvent:Connect(function(causeOfDeath)
                if self.uiController then
                    self.uiController:DisplayDeathMessage(causeOfDeath)
                end
            end)
        end

        -- Notification de naissance/réapparition
        local birthEvent = events:FindFirstChild("Birth")
        if birthEvent then
            birthEvent.OnClientEvent:Connect(function(parentName)
                if self.uiController then
                    self.uiController:DisplayBirthMessage(parentName)
                end
            end)
        end
    end

    print("PlayerController: Événements du serveur configurés")
end

-- Gérer la mise à jour de l'inventaire
function PlayerController:HandleInventoryUpdate(inventoryData)
    -- Mettre à jour l'interface d'inventaire
    if self.uiController then
        self.uiController:UpdateInventory(inventoryData)
    end

    -- Mettre à jour l'outil équipé
    if inventoryData.equipped and inventoryData.equipped.tool then
        local slotNumber = inventoryData.equipped.tool
        local item = inventoryData.items[slotNumber]

        if item then
            self.characterState.equippedTool = {
                id = item.id,
                type = ItemTypes[item.id] and ItemTypes[item.id].toolType or nil
            }
        else
            self.characterState.equippedTool = nil
        end
    else
        self.characterState.equippedTool = nil
    end
end

-- Commencer à sprinter
function PlayerController:StartSprinting()
    local character = self.player.Character
    if not character or not character:FindFirstChild("Humanoid") then return end

    local humanoid = character.Humanoid
    humanoid.WalkSpeed = self.runSpeed
    self.characterState.isRunning = true

    -- Dans une implémentation réelle, envoyer un événement au serveur
    -- pour augmenter la consommation d'énergie pendant la course
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events then
        local playerActionEvent = events:FindFirstChild("PlayerAction")
        if playerActionEvent then
            playerActionEvent:FireServer("sprint_start")
        end
    end

    print("PlayerController: Début du sprint")
end

-- Arrêter de sprinter
function PlayerController:StopSprinting()
    local character = self.player.Character
    if not character or not character:FindFirstChild("Humanoid") then return end

    local humanoid = character.Humanoid
    humanoid.WalkSpeed = self.walkSpeed
    self.characterState.isRunning = false

    -- Dans une implémentation réelle, envoyer un événement au serveur
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events then
        local playerActionEvent = events:FindFirstChild("PlayerAction")
        if playerActionEvent then
            playerActionEvent:FireServer("sprint_stop")
        end
    end

    print("PlayerController: Fin du sprint")
end

-- Essayer d'interagir avec un objet dans le monde
function PlayerController:TryInteract()
    -- Si le joueur est en train de dormir, l'arrêter
    if self.characterState.isSleeping then
        self:SetSleepingState(false)
        return
    end

    local character = self.player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local rootPart = character.HumanoidRootPart

    -- Lancer un rayon à partir de la caméra
    local mouse = self.player:GetMouse()
    local camera = workspace.CurrentCamera

    local rayOrigin = camera.CFrame.Position
    local rayDirection = (mouse.Hit.Position - rayOrigin).Unit * self.interactionDistance

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    local hitPart = raycastResult and raycastResult.Instance
    local hitPosition = raycastResult and raycastResult.Position

    if hitPart then
        local model = hitPart:FindFirstAncestorOfClass("Model")

        if model then
            -- Vérifier le type de modèle pour déterminer l'interaction
            local resourceType = model:GetAttribute("ResourceType")
            local buildingType = model:GetAttribute("BuildingType")

            if resourceType then
                -- Interagir avec une ressource
                self:InteractWithResource(model, resourceType)
            elseif buildingType then
                -- Interagir avec un bâtiment
                self:InteractWithBuilding(model, buildingType)
            else
                print("PlayerController: Interaction avec un objet inconnu")
            end
        end
    end
end

-- Interagir avec une ressource
function PlayerController:InteractWithResource(resourceModel, resourceType)
    -- Dans une implémentation réelle, envoyer un événement au serveur
    local events = ReplicatedStorage:FindFirstChild("Events")

    if events then
        local playerActionEvent = events:FindFirstChild("PlayerAction")
        if playerActionEvent then
            self:PlayHarvestAnimation(resourceType)

            playerActionEvent:FireServer("gather_resource", resourceType, resourceModel)

            -- Mettre à jour l'état du personnage
            self.characterState.isHarvesting = true
            self.characterState.targetResource = resourceModel

            -- Après un délai, remettre l'état à normal
            delay(2, function()
                self.characterState.isHarvesting = false
                self.characterState.targetResource = nil
            end)

            print("PlayerController: Récolte de ressource - " .. resourceType)
        end
    end
end

-- Jouer une animation de récolte selon le type de ressource
function PlayerController:PlayHarvestAnimation(resourceType)
    local character = self.player.Character
    if not character or not character:FindFirstChild("Humanoid") then return end

    local humanoid = character.Humanoid
    local animator = humanoid:FindFirstChildOfClass("Animator")

    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    -- Animation selon le type d'outil nécessaire
    local animationId = "rbxassetid://507768375" -- Animation par défaut

    -- Dans une implémentation réelle, charger les animations appropriées
    if resourceType == "wood" then
        animationId = "rbxassetid://12345720" -- Animation de hache
    elseif resourceType == "stone" or resourceType:find("_ore") then
        animationId = "rbxassetid://12345721" -- Animation de pioche
    elseif resourceType == "berry_bush" or resourceType == "fiber" then
        animationId = "rbxassetid://12345722" -- Animation de cueillette
    end

    -- Dans ce prototype, utiliser une animation de remplacement
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId

    local animTrack = animator:LoadAnimation(animation)
    animTrack:Play()

    -- Auto-destruction de l'objet Animation après lecture
    animTrack.Stopped:Connect(function()
        animation:Destroy()
    end)
end

-- Interagir avec un bâtiment
function PlayerController:InteractWithBuilding(buildingModel, buildingType)
    -- Dans une implémentation réelle, envoyer un événement au serveur
    local events = ReplicatedStorage:FindFirstChild("Events")

    if events then
        local playerActionEvent = events:FindFirstChild("PlayerAction")
        if playerActionEvent then
            local structureId = buildingModel:GetAttribute("StructureId")

            if structureId then
                playerActionEvent:FireServer("interact_building", structureId, "use")

                print("PlayerController: Utilisation du bâtiment - " .. buildingType)

                -- Cas spéciaux pour certains types de bâtiments
                if buildingType == "wooden_bed" then
                    self:SetSleepingState(true)
                end
            end
        end
    end
end

-- Définir l'état de sommeil
function PlayerController:SetSleepingState(isSleeping)
    local character = self.player.Character
    if not character or not character:FindFirstChild("Humanoid") then return end

    local humanoid = character.Humanoid

    self.characterState.isSleeping = isSleeping

    if isSleeping then
        -- Mettre le joueur en position allongée
        humanoid.Sit = true
        humanoid.WalkSpeed = 0
        humanoid.JumpPower = 0

        -- Envoyer un événement au serveur
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events then
            local playerActionEvent = events:FindFirstChild("PlayerAction")
            if playerActionEvent then
                playerActionEvent:FireServer("sleep")
            end
        end

        print("PlayerController: Début du sommeil")
    else
        -- Remettre le joueur debout
        humanoid.Sit = false
        humanoid.WalkSpeed = self.walkSpeed
        humanoid.JumpPower = 50

        -- Envoyer un événement au serveur
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events then
            local playerActionEvent = events:FindFirstChild("PlayerAction")
            if playerActionEvent then
                playerActionEvent:FireServer("wake_up")
            end
        end

        print("PlayerController: Fin du sommeil")
    end
end

-- Commencer la construction
function PlayerController:StartBuilding(itemId, previewInstance)
    self.characterState.isBuilding = true
    self.characterState.buildingPreview = previewInstance

    -- Dans une implémentation réelle, le prévisualisation serait créé ici
    if not previewInstance then
        -- Code pour créer le prévisualisation côté client
        -- Cet exemple est simplifié; une implémentation complète créerait
        -- un modèle basé sur itemId et le positionnerait devant le joueur
        self.characterState.buildingPreview = Instance.new("Part")
        self.characterState.buildingPreview.Name = "BuildingPreview"
        self.characterState.buildingPreview.Transparency = 0.5
        self.characterState.buildingPreview.CanCollide = false
        self.characterState.buildingPreview.Anchored = true
        self.characterState.buildingPreview.Material = Enum.Material.Plastic

        -- Définir la taille en fonction du type d'objet
        if itemId == "wooden_wall" then
            self.characterState.buildingPreview.Size = Vector3.new(0.2, 3, 4)
        elseif itemId == "wooden_floor" then
            self.characterState.buildingPreview.Size = Vector3.new(4, 0.2, 4)
        elseif itemId == "wooden_door" then
            self.characterState.buildingPreview.Size = Vector3.new(0.2, 3, 1.5)
        elseif itemId == "wooden_bed" then
            self.characterState.buildingPreview.Size = Vector3.new(2, 0.5, 4)
        elseif itemId == "wooden_table" then
            self.characterState.buildingPreview.Size = Vector3.new(3, 1, 1.5)
        elseif itemId == "wooden_chair" then
            self.characterState.buildingPreview.Size = Vector3.new(1, 1.5, 1)
        elseif itemId == "campfire" or itemId == "furnace" then
            self.characterState.buildingPreview.Size = Vector3.new(2, 1, 2)
        elseif itemId == "anvil" then
            self.characterState.buildingPreview.Size = Vector3.new(1, 1, 2)
        else
            self.characterState.buildingPreview.Size = Vector3.new(1, 1, 1)
        end

        self.characterState.buildingPreview.Parent = workspace
    end

    -- Mettre à jour la position du prévisualisation
    self:UpdateBuildingPreviewPosition()

    print("PlayerController: Début de la construction - " .. itemId)
end

-- Mettre à jour la position du prévisualisation de construction
function PlayerController:UpdateBuildingPreviewPosition()
    if not self.characterState.isBuilding or not self.characterState.buildingPreview then return end

    local character = self.player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local rootPart = character.HumanoidRootPart

    -- Obtenir la position à partir du raycast de la souris
    local mouse = self.player:GetMouse()
    local hitPosition = mouse.Hit.Position

    -- Ajuster la hauteur en fonction du type d'objet
    local previewCFrame = CFrame.new(hitPosition)

    -- Dans une implémentation réelle, on ajusterait aussi la rotation
    -- en fonction de la direction du personnage ou d'autres facteurs

    -- Définir la position du prévisualisation
    self.characterState.buildingPreview.CFrame = previewCFrame

    -- Vérifier si l'emplacement est valide et mettre à jour l'apparence
    local isValid = self:CheckBuildingPlacementValidity()
    self.characterState.buildingPreview.Color = isValid and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
end

-- Vérifier si l'emplacement est valide pour placer un bâtiment
function PlayerController:CheckBuildingPlacementValidity()
    if not self.characterState.isBuilding or not self.characterState.buildingPreview then return false end

    local character = self.player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return false end

    local rootPart = character.HumanoidRootPart
    local previewPosition = self.characterState.buildingPreview.Position

    -- Vérifier la distance
    local distance = (rootPart.Position - previewPosition).Magnitude
    if distance > self.interactionDistance then
        return false
    end

    -- Vérifier les collisions
    -- Dans une implémentation réelle, on vérifierait aussi les collisions avec d'autres bâtiments,
    -- les restrictions de zone de construction, etc.

    return true
end

-- Faire pivoter le prévisualisation de construction
function PlayerController:RotateBuildingPreview()
    if not self.characterState.isBuilding or not self.characterState.buildingPreview then return end

    -- Faire pivoter de 90 degrés autour de l'axe Y
    local currentCFrame = self.characterState.buildingPreview.CFrame
    local newCFrame = currentCFrame * CFrame.Angles(0, math.rad(90), 0)

    self.characterState.buildingPreview.CFrame = newCFrame
end

-- Essayer de placer un bâtiment
function PlayerController:TryPlaceBuilding()
    if not self.characterState.isBuilding or not self.characterState.buildingPreview then return end

    -- Vérifier si l'emplacement est valide
    if not self:CheckBuildingPlacementValidity() then
        -- Afficher un message d'erreur
        if self.uiController then
            self.uiController:DisplayMessage("Emplacement invalide pour la construction", "error", 2)
        end
        return
    end

    -- Obtenir les données nécessaires
    local buildingPosition = self.characterState.buildingPreview.Position
    local buildingRotation = self.characterState.buildingPreview.CFrame - self.characterState.buildingPreview.Position

    -- Envoyer l'événement de placement au serveur
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events then
        local playerActionEvent = events:FindFirstChild("PlayerAction")
        if playerActionEvent then
            local itemId = self.characterState.buildingPreview:GetAttribute("BuildingType")

            playerActionEvent:FireServer("place_building", itemId, buildingPosition, buildingRotation)

            -- Terminer le mode construction
            self:EndBuilding()
        end
    end
end

-- Terminer le mode construction
function PlayerController:EndBuilding()
    if not self.characterState.isBuilding then return end

    -- Nettoyer le prévisualisation
    if self.characterState.buildingPreview then
        self.characterState.buildingPreview:Destroy()
        self.characterState.buildingPreview = nil
    end

    self.characterState.isBuilding = false

    print("PlayerController: Fin de la construction")
end

-- Annuler l'action en cours
function PlayerController:CancelCurrentAction()
    if self.characterState.isBuilding then
        self:EndBuilding()
    end

    if self.characterState.isSleeping then
        self:SetSleepingState(false)
    end

    if self.uiController then
        if self.uiController.interfaces.inventoryUI and self.uiController.interfaces.inventoryUI.isOpen then
            self.uiController:ToggleInventory(false)
        end

        if self.uiController.interfaces.craftingUI and self.uiController.interfaces.craftingUI.isOpen then
            self.uiController:ToggleCrafting(false)
        end
    end

    print("PlayerController: Annulation de l'action en cours")
end

-- Sélectionner un emplacement rapide (touches 1-5)
function PlayerController:SelectQuickSlot(slotNumber)
    -- Dans une implémentation réelle, on interagirait avec l'inventaire
    -- pour équiper l'objet dans l'emplacement spécifié
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events then
        local playerActionEvent = events:FindFirstChild("PlayerAction")
        if playerActionEvent then
            playerActionEvent:FireServer("equip_slot", slotNumber)
        end
    end

    print("PlayerController: Sélection de l'emplacement rapide " .. slotNumber)
end

-- Essayer d'attaquer ou de récolter avec l'outil équipé
function PlayerController:TryAttackOrHarvest()
    if self.characterState.isBuilding or self.characterState.isSleeping then return end

    local character = self.player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    -- Vérifier si un outil est équipé
    if not self.characterState.equippedTool then
        print("PlayerController: Aucun outil équipé")
        return
    end

    -- Lancer un rayon à partir de la caméra
    local mouse = self.player:GetMouse()
    local camera = workspace.CurrentCamera

    local rayOrigin = camera.CFrame.Position
    local rayDirection = (mouse.Hit.Position - rayOrigin).Unit * self.interactionDistance

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    local hitPart = raycastResult and raycastResult.Instance
    local hitPosition = raycastResult and raycastResult.Position

    if hitPart then
        local model = hitPart:FindFirstAncestorOfClass("Model")

        if model then
            -- Vérifier le type de modèle
            local resourceType = model:GetAttribute("ResourceType")
            local structureId = model:GetAttribute("StructureId")

            if resourceType then
                -- Récolter une ressource avec l'outil
                self:HarvestResourceWithTool(model, resourceType)
            elseif structureId then
                -- Attaquer une structure
                self:AttackStructure(structureId, hitPart)
            else
                -- Attaquer une cible
                self:AttackTarget(hitPart)
            end
        else
            -- Attaquer dans le vide
            self:PlayAttackAnimation()
        end
    else
        -- Attaquer dans le vide
        self:PlayAttackAnimation()
    end
end

-- Récolter une ressource avec l'outil équipé
function PlayerController:HarvestResourceWithTool(resourceModel, resourceType)
    if not self.characterState.equippedTool then return end

    -- Vérifier si l'outil est approprié pour ce type de ressource
    local toolType = self.characterState.equippedTool.type
    local isAppropriate = false

    if (resourceType == "wood" and toolType == "axe") or
       ((resourceType == "stone" or resourceType:find("_ore")) and toolType == "pickaxe") then
        isAppropriate = true
    end

    -- Jouer l'animation appropriée
    if isAppropriate then
        self:PlayHarvestAnimation(resourceType)
    else
        self:PlayAttackAnimation()
    end
end

-- Attaquer une cible
function PlayerController:AttackTarget(targetPart)
    -- Dans une implémentation réelle, envoyer un événement au serveur
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events then
        local playerActionEvent = events:FindFirstChild("PlayerAction")
        if playerActionEvent then
            playerActionEvent:FireServer("attack", targetPart)
        end
    end

    -- Jouer l'animation d'attaque
    self:PlayAttackAnimation()
end

-- Attaquer une structure
function PlayerController:AttackStructure(structureId, hitPart)
    -- Envoyer un événement au serveur pour attaquer la structure
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events then
        local attackStructureEvent = events:FindFirstChild("AttackStructure")
        if attackStructureEvent then
            attackStructureEvent:FireServer(structureId, hitPart)
        else
            warn("PlayerController: AttackStructure event non trouvé")
        end
    end

    -- Jouer l'animation d'attaque
    self:PlayAttackAnimation()
end

-- Jouer l'animation d'attaque
function PlayerController:PlayAttackAnimation()
    local character = self.player.Character
    if not character or not character:FindFirstChild("Humanoid") then return end

    local humanoid = character.Humanoid
    local animator = humanoid:FindFirstChildOfClass("Animator")

    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    -- Animation d'attaque par défaut
    local animationId = "rbxassetid://12345678" -- Remplacer par l'ID de l'animation d'attaque

    local animation = Instance.new("Animation")
    animation.AnimationId = animationId

    local animTrack = animator:LoadAnimation(animation)
    animTrack:Play()

    -- Auto-destruction de l'objet Animation après lecture
    animTrack.Stopped:Connect(function()
        animation:Destroy()
    end)
end

return PlayerController