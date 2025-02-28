-- src/client/controllers/CameraController.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local CameraController = {}
CameraController.__index = CameraController

-- Définition des modes de caméra
local CAMERA_MODES = {
    FOLLOW = "follow",     -- Caméra qui suit le joueur (standard)
    FIRST_PERSON = "first", -- Vue à la première personne
    BUILDING = "building", -- Mode construction (plus éloigné et plus haut)
    ORBIT = "orbit"        -- Mode orbite pour les menus et interfaces
}

function CameraController.new()
    local self = setmetatable({}, CameraController)
    
    -- Référence au joueur et à la caméra
    self.player = Players.LocalPlayer
    self.camera = workspace.CurrentCamera
    
    -- Paramètres de la caméra
    self.mode = CAMERA_MODES.FOLLOW
    self.previousMode = nil       -- Pour retourner au mode précédent
    self.distance = 12            -- Distance standard en mode suivi
    self.height = 2               -- Hauteur standard en mode suivi
    self.angle = 0                -- Angle horizontal de la caméra
    self.verticalAngle = 0.3      -- Angle vertical (en radians)
    self.sensitivity = 0.005      -- Sensibilité de rotation de la caméra
    self.smoothness = 0.2         -- Facteur de lissage des mouvements
    self.isRotating = false       -- Si la caméra est en rotation (clic droit)
    self.zoomSpeed = 1            -- Vitesse de zoom avec la molette
    self.minZoomDistance = 2      -- Distance minimale de zoom
    self.maxZoomDistance = 30     -- Distance maximale de zoom
    self.isControlEnabled = true  -- Si les contrôles de caméra sont activés
    
    -- Paramètres d'orbite
    self.orbitTarget = nil        -- Cible pour le mode orbite (Vector3)
    self.orbitDistance = 20       -- Distance en mode orbite
    self.orbitAngle = 0           -- Angle horizontal en mode orbite
    self.orbitVerticalAngle = 0.5 -- Angle vertical en mode orbite
    
    -- Paramètres de collision
    self.checkCollisions = true   -- Vérifier les collisions avec les objets
    self.collisionOffset = 0.5    -- Décalage pour éviter les problèmes de collision
    
    -- Différentes configurations par mode
    self.modeSettings = {
        [CAMERA_MODES.FOLLOW] = {
            distance = 12,
            height = 2,
            verticalAngle = 0.3,
            minZoomDistance = 2,
            maxZoomDistance = 30
        },
        [CAMERA_MODES.FIRST_PERSON] = {
            distance = 0,
            height = 1.6,
            verticalAngle = 0,
            minZoomDistance = 0,
            maxZoomDistance = 0
        },
        [CAMERA_MODES.BUILDING] = {
            distance = 20,
            height = 10,
            verticalAngle = 0.6,
            minZoomDistance = 5,
            maxZoomDistance = 40
        },
        [CAMERA_MODES.ORBIT] = {
            distance = 20,
            height = 5,
            verticalAngle = 0.5,
            minZoomDistance = 5,
            maxZoomDistance = 50
        }
    }
    
    -- État des touches
    self.keyStates = {}
    
    -- Référence au controller d'UI pour synchroniser les états
    self.uiController = nil
    
    return self
end

function CameraController:Initialize(uiController)
    -- Stocker la référence au contrôleur d'interface utilisateur
    self.uiController = uiController
    
    -- Définir le type de caméra
    self.camera.CameraType = Enum.CameraType.Scriptable
    
    -- Initialiser la position et rotation de la caméra
    local character = self.player.Character or self.player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    
    if rootPart then
        -- Position initiale basée sur le personnage
        self.angle = rootPart.Orientation.Y * math.pi / 180
    end
    
    -- Connecter les événements
    self:ConnectEvents()
    
    -- Démarrer la boucle de mise à jour
    self:StartUpdateLoop()
    
    print("CameraController: Initialisé")
end

function CameraController:ConnectEvents()
    -- Gérer les événements de Character
    self.player.CharacterAdded:Connect(function(character)
        -- Attendre que le personnage soit prêt
        local humanoid = character:WaitForChild("Humanoid", 5)
        local rootPart = character:WaitForChild("HumanoidRootPart", 5)
        
        if humanoid and rootPart then
            -- Réinitialiser certains paramètres lorsqu'un nouveau personnage apparaît
            if self.mode == CAMERA_MODES.FIRST_PERSON then
                -- Rendre le personnage transparent en mode première personne
                self:SetCharacterTransparency(0.7)
            elseif self.mode == CAMERA_MODES.FOLLOW then
                -- Initialiser l'angle pour qu'il corresponde à la direction du personnage
                self.angle = rootPart.Orientation.Y * math.pi / 180
            end
        end
    end)
    
    -- Rotation avec clic droit
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not self.isControlEnabled then return end
        
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            self.isRotating = true
        elseif input.KeyCode == Enum.KeyCode.Tab then
            -- Changer de mode de caméra avec Tab
            self:CycleCamera()
        end
        
        -- Mémoriser l'état des touches
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self.keyStates[input.KeyCode] = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            self.isRotating = false
        end
        
        -- Mémoriser l'état des touches
        if input.UserInputType == Enum.UserInputType.Keyboard then
            self.keyStates[input.KeyCode] = false
        end
    end)
    
    -- Rotation de la caméra avec le mouvement de la souris
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed or not self.isControlEnabled then return end
        
        if self.isRotating and input.UserInputType == Enum.UserInputType.MouseMovement then
            -- Calculer la nouvelle rotation
            self.angle = self.angle - input.Delta.X * self.sensitivity
            
            -- Limiter l'angle vertical pour éviter les rotations complètes
            local newVertAngle = self.verticalAngle - input.Delta.Y * self.sensitivity
            self.verticalAngle = math.clamp(newVertAngle, -1.2, 1.2)
        end
    end)
    
    -- Zoom avec la molette de la souris
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed or not self.isControlEnabled then return end
        
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local modeSettings = self.modeSettings[self.mode]
            local delta = input.Position.Z * self.zoomSpeed
            
            if self.mode ~= CAMERA_MODES.FIRST_PERSON then
                local newDistance = self.distance - delta
                self.distance = math.clamp(newDistance, modeSettings.minZoomDistance, modeSettings.maxZoomDistance)
            end
        end
    end)
    
    -- Gérer les touches de fonction pour les raccourcis caméra
    -- Raccourci pour la vue première personne (F1)
    ContextActionService:BindAction("ToggleFirstPerson", function(_, state)
        if state == Enum.UserInputState.Begin then
            if self.mode == CAMERA_MODES.FIRST_PERSON then
                self:SetMode(CAMERA_MODES.FOLLOW)
            else
                self:SetMode(CAMERA_MODES.FIRST_PERSON)
            end
        end
    end, false, Enum.KeyCode.F1)
    
    -- Raccourci pour la vue construction (F2)
    ContextActionService:BindAction("ToggleBuildingView", function(_, state)
        if state == Enum.UserInputState.Begin then
            if self.mode == CAMERA_MODES.BUILDING then
                self:SetMode(CAMERA_MODES.FOLLOW)
            else
                self:SetMode(CAMERA_MODES.BUILDING)
            end
        end
    end, false, Enum.KeyCode.F2)
    
    -- Raccourci pour reset la caméra (R)
    ContextActionService:BindAction("ResetCamera", function(_, state)
        if state == Enum.UserInputState.Begin then
            self:ResetCamera()
        end
    end, false, Enum.KeyCode.R)
end

function CameraController:StartUpdateLoop()
    -- Mettre à jour la caméra à chaque frame
    RunService:BindToRenderStep("CameraUpdate", Enum.RenderPriority.Camera.Value + 1, function(dt)
        self:Update(dt)
    end)
end

function CameraController:Update(dt)
    -- Vérifier si le personnage et le HumanoidRootPart existent
    local character = self.player.Character
    if not character then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Gérer différents modes de caméra
    if self.mode == CAMERA_MODES.FOLLOW then
        self:UpdateFollowCamera(rootPart, dt)
    elseif self.mode == CAMERA_MODES.FIRST_PERSON then
        self:UpdateFirstPersonCamera(rootPart, humanoid, dt)
    elseif self.mode == CAMERA_MODES.BUILDING then
        self:UpdateBuildingCamera(rootPart, dt)
    elseif self.mode == CAMERA_MODES.ORBIT then
        self:UpdateOrbitCamera(dt)
    end
end

function CameraController:UpdateFollowCamera(rootPart, dt)
    -- Calculer la position idéale de la caméra (derrière le joueur)
    local targetPosition = rootPart.Position +
                          Vector3.new(0, self.height, 0) -
                          (CFrame.Angles(0, self.angle, 0).LookVector * self.distance * math.cos(self.verticalAngle)) +
                          Vector3.new(0, self.distance * math.sin(self.verticalAngle), 0)
    
    -- Vérifier les collisions avec l'environnement
    if self.checkCollisions then
        targetPosition = self:AdjustCameraForCollisions(rootPart.Position + Vector3.new(0, self.height, 0), targetPosition)
    end
    
    -- Calculer la position de visée (la tête du joueur)
    local lookPosition = rootPart.Position + Vector3.new(0, self.height, 0)
    
    -- Appliquer un lissage aux mouvements de la caméra
    self.camera.CFrame = self.camera.CFrame:Lerp(CFrame.new(targetPosition, lookPosition), self.smoothness)
end

function CameraController:UpdateFirstPersonCamera(rootPart, humanoid, dt)
    -- Position de la tête du joueur
    local headPosition = rootPart.Position + Vector3.new(0, self.modeSettings[self.mode].height, 0)
    
    -- Direction de regard
    local lookDirection = CFrame.Angles(0, self.angle, 0) * CFrame.Angles(self.verticalAngle, 0, 0)
    
    -- Définir la caméra
    self.camera.CFrame = CFrame.new(headPosition) * lookDirection
    
    -- En mode première personne, la direction du regard influence la direction du personnage
    if humanoid and humanoid.MoveDirection.Magnitude > 0 then
        humanoid.AutoRotate = false
        rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, self.angle, 0)
    else
        humanoid.AutoRotate = true
    end
end

function CameraController:UpdateBuildingCamera(rootPart, dt)
    -- En mode construction, la caméra est plus haute et plus éloignée
    local targetPosition = rootPart.Position +
                          Vector3.new(0, self.height, 0) -
                          (CFrame.Angles(0, self.angle, 0).LookVector * self.distance * math.cos(self.verticalAngle)) +
                          Vector3.new(0, self.distance * math.sin(self.verticalAngle), 0)
    
    -- Vérifier les collisions avec l'environnement
    if self.checkCollisions then
        targetPosition = self:AdjustCameraForCollisions(rootPart.Position + Vector3.new(0, self.height, 0), targetPosition)
    end
    
    -- La caméra regarde vers le sol devant le joueur
    local lookPosition = rootPart.Position + CFrame.Angles(0, self.angle, 0).LookVector * 10
    
    -- Appliquer un lissage aux mouvements de la caméra
    self.camera.CFrame = self.camera.CFrame:Lerp(CFrame.new(targetPosition, lookPosition), self.smoothness)
end

function CameraController:UpdateOrbitCamera(dt)
    -- En mode orbite, la caméra tourne autour d'un point fixe
    if not self.orbitTarget then
        -- Si aucune cible n'est définie, utiliser la position du joueur
        local character = self.player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            self.orbitTarget = character.HumanoidRootPart.Position
        else
            self.orbitTarget = Vector3.new(0, 0, 0)
        end
    end
    
    -- Calculer la position de la caméra
    local targetPosition = self.orbitTarget +
                          (CFrame.Angles(0, self.orbitAngle, 0).LookVector * -self.orbitDistance * math.cos(self.orbitVerticalAngle)) +
                          Vector3.new(0, self.orbitDistance * math.sin(self.orbitVerticalAngle), 0)
    
    -- La caméra regarde vers la cible
    local lookPosition = self.orbitTarget
    
    -- Appliquer un lissage aux mouvements de la caméra
    self.camera.CFrame = self.camera.CFrame:Lerp(CFrame.new(targetPosition, lookPosition), self.smoothness)
    
    -- Faire tourner lentement la caméra autour de la cible (effet ambiance)
    self.orbitAngle = self.orbitAngle + 0.0005
end

-- Ajuster la position de la caméra pour éviter les collisions
function CameraController:AdjustCameraForCollisions(origin, desiredCameraPos)
    local direction = (desiredCameraPos - origin).Unit
    local distance = (desiredCameraPos - origin).Magnitude
    
    local ray = Ray.new(origin, direction * distance)
    local hitPart, hitPosition = workspace:FindPartOnRayWithIgnoreList(ray, {self.player.Character})
    
    if hitPart then
        -- Ajouter un petit décalage pour éviter les problèmes de clipping
        return hitPosition + (origin - hitPosition).Unit * self.collisionOffset
    end
    
    return desiredCameraPos
end

function CameraController:SetMode(mode)
    if not self.modeSettings[mode] then
        warn("CameraController: Mode de caméra invalide - " .. tostring(mode))
        return
    end
    
    -- Sauvegarder le mode précédent
    self.previousMode = self.mode
    
    -- Mettre à jour le mode
    self.mode = mode
    
    -- Appliquer les paramètres du mode
    local settings = self.modeSettings[mode]
    self.distance = settings.distance
    self.height = settings.height
    self.verticalAngle = settings.verticalAngle
    
    -- Réinitialiser certains paramètres selon le mode
    if mode == CAMERA_MODES.FIRST_PERSON then
        -- Rendre le personnage transparent en première personne
        self:SetCharacterTransparency(0.7)
    else
        -- Restaurer la visibilité du personnage
        self:SetCharacterTransparency(0)
    end
    
    print("CameraController: Mode changé pour " .. mode)
end

-- Modifier la transparence du personnage (utile en mode première personne)
function CameraController:SetCharacterTransparency(transparency)
    local character = self.player.Character
    if not character then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            -- Utiliser LocalTransparencyModifier au lieu de Transparency 
            -- car il n'affecte que le client local
            part.LocalTransparencyModifier = transparency
        end
    end
end

-- Passer au mode de caméra suivant
function CameraController:CycleCamera()
    local modes = {
        CAMERA_MODES.FOLLOW,
        CAMERA_MODES.FIRST_PERSON,
        CAMERA_MODES.BUILDING
    }
    
    local currentIndex = table.find(modes, self.mode) or 1
    local nextIndex = (currentIndex % #modes) + 1
    
    self:SetMode(modes[nextIndex])
end

-- Réinitialiser la caméra à sa position par défaut
function CameraController:ResetCamera()
    local character = self.player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    -- Réinitialiser l'angle pour qu'il corresponde à la direction du personnage
    self.angle = rootPart.Orientation.Y * math.pi / 180
    
    -- Réinitialiser l'angle vertical
    self.verticalAngle = self.modeSettings[self.mode].verticalAngle
    
    -- Réinitialiser la distance
    self.distance = self.modeSettings[self.mode].distance
    
    print("CameraController: Caméra réinitialisée")
end

-- Passer temporairement en mode construction
function CameraController:EnterBuildingMode()
    if self.mode ~= CAMERA_MODES.BUILDING then
        self.previousMode = self.mode
        self:SetMode(CAMERA_MODES.BUILDING)
    end
end

-- Quitter le mode construction
function CameraController:ExitBuildingMode()
    if self.mode == CAMERA_MODES.BUILDING and self.previousMode then
        self:SetMode(self.previousMode)
    end
end

-- Entrer en mode orbite (pour les menus et interfaces)
function CameraController:EnterOrbitMode(target)
    if self.mode ~= CAMERA_MODES.ORBIT then
        self.previousMode = self.mode
        
        -- Si une cible est spécifiée, l'utiliser
        if target then
            self.orbitTarget = target
        else
            -- Sinon, utiliser la position du joueur
            local character = self.player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                self.orbitTarget = character.HumanoidRootPart.Position
            end
        end
        
        self:SetMode(CAMERA_MODES.ORBIT)
    end
end

-- Quitter le mode orbite
function CameraController:ExitOrbitMode()
    if self.mode == CAMERA_MODES.ORBIT and self.previousMode then
        self:SetMode(self.previousMode)
    end
end

-- Activer/désactiver les contrôles de caméra
function CameraController:SetControlsEnabled(enabled)
    self.isControlEnabled = enabled
end

-- Verrouiller la caméra sur une cible
function CameraController:LockOnTarget(target)
    if not target then return end
    
    -- Sauvegarder les paramètres actuels
    local origSmoothness = self.smoothness
    self.smoothness = 0.1 -- Plus lisse pour le mouvement vers la cible
    
    -- Déplacer la caméra vers la cible
    local targetPosition = target.Position
    local character = self.player.Character
    
    if character and character:FindFirstChild("HumanoidRootPart") then
        local rootPosition = character.HumanoidRootPart.Position
        
        -- Calculer l'angle pour faire face à la cible
        local direction = (targetPosition - rootPosition).Unit
        self.angle = math.atan2(-direction.X, -direction.Z)
        
        -- Forcer une mise à jour immédiate
        self:Update(0)
    end
    
    -- Restaurer les paramètres originaux
    self.smoothness = origSmoothness
end

return CameraController
