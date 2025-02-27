-- src/client/controllers/CameraController.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local CameraController = {}
CameraController.__index = CameraController

-- Configuration des différents modes de caméra
local CAMERA_MODES = {
    FOLLOW = "follow",     -- Caméra qui suit le joueur (standard)
    FIRST_PERSON = "first", -- Vue à la première personne
    BUILDING = "building", -- Mode construction (plus éloigné et plus haut)
    ORBIT = "orbit"        -- Orbite autour du joueur (pour l'inventaire/craft)
}

function CameraController.new()
    local self = setmetatable({}, CameraController)
    
    -- Référence au joueur et à la caméra
    self.player = Players.LocalPlayer
    self.camera = workspace.CurrentCamera
    
    -- Paramètres de la caméra
    self.mode = CAMERA_MODES.FOLLOW
    self.distance = 12       -- Distance standard en mode suivi
    self.height = 2          -- Hauteur standard en mode suivi
    self.angle = 0           -- Angle horizontal de la caméra
    self.verticalAngle = 0.3 -- Angle vertical (en radians)
    self.sensitivity = 0.005 -- Sensibilité de rotation de la caméra
    self.smoothness = 0.2    -- Facteur de lissage des mouvements
    self.isRotating = false  -- Si la caméra est en rotation (clic droit)
    self.zoomSpeed = 1       -- Vitesse de zoom avec la molette
    
    -- Différentes configurations par mode
    self.modeSettings = {
        [CAMERA_MODES.FOLLOW] = {
            distance = 12,
            height = 2,
            verticalAngle = 0.3
        },
        [CAMERA_MODES.FIRST_PERSON] = {
            distance = 0,
            height = 1.6,
            verticalAngle = 0
        },
        [CAMERA_MODES.BUILDING] = {
            distance = 20,
            height = 10,
            verticalAngle = 0.6
        },
        [CAMERA_MODES.ORBIT] = {
            distance = 8,
            height = 2,
            verticalAngle = 0.3
        }
    }
    
    -- État des touches
    self.keyStates = {}
    
    return self
end

function CameraController:Initialize()
    -- Définir le type de caméra
    self.camera.CameraType = Enum.CameraType.Scriptable
    
    -- Connecter les événements
    self:ConnectEvents()
    
    -- Démarrer la boucle de mise à jour
    self:StartUpdateLoop()
    
    print("CameraController: Initialisé")
end

function CameraController:ConnectEvents()
    -- Rotation avec clic droit
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
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
        if not self.isRotating then return end
        
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            self.angle = self.angle - input.Delta.X * self.sensitivity
            
            -- Limiter l'angle vertical pour éviter les retournements
            local newVertAngle = self.verticalAngle - input.Delta.Y * self.sensitivity
            self.verticalAngle = math.clamp(newVertAngle, -1.2, 1.2)
        end
    end)
    
    -- Zoom avec la molette de la souris
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.UserInputType == Enum.UserInputType.MouseWheel then
            local delta = input.Position.Z * self.zoomSpeed
            local mode = self.modeSettings[self.mode]
            
            if self.mode == CAMERA_MODES.FOLLOW or self.mode == CAMERA_MODES.BUILDING or self.mode == CAMERA_MODES.ORBIT then
                local newDistance = self.distance - delta
                self.distance = math.clamp(newDistance, 2, 30)
            end
        end
    end)
    
    -- Gérer les événements de personnage
    self.player.CharacterAdded:Connect(function(character)
        -- S'assurer que la caméra suit le bon personnage
        wait(0.5) -- Petit délai pour s'assurer que le personnage est complètement chargé
        self:SetMode(CAMERA_MODES.FOLLOW)
    end)
end

function CameraController:StartUpdateLoop()
    -- Mettre à jour la caméra à chaque frame
    RunService:BindToRenderStep("CameraUpdate", Enum.RenderPriority.Camera.Value + 1, function(dt)
        self:Update(dt)
    end)
end

function CameraController:Update(dt)
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
        self:UpdateOrbitCamera(rootPart, dt)
    end
end

function CameraController:UpdateFollowCamera(rootPart, dt)
    -- Calculer la position cible de la caméra (derrière le joueur)
    local targetPosition = rootPart.Position +
                          Vector3.new(0, self.height, 0) -
                          (CFrame.Angles(0, self.angle, 0).LookVector * self.distance * math.cos(self.verticalAngle)) +
                          Vector3.new(0, self.distance * math.sin(self.verticalAngle), 0)
    
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
    
    -- La caméra regarde vers le sol devant le joueur
    local lookPosition = rootPart.Position + CFrame.Angles(0, self.angle, 0).LookVector * 10
    
    -- Appliquer un lissage aux mouvements de la caméra
    self.camera.CFrame = self.camera.CFrame:Lerp(CFrame.new(targetPosition, lookPosition), self.smoothness)
end

function CameraController:UpdateOrbitCamera(rootPart, dt)
    -- En mode orbite, la caméra tourne autour du joueur
    local center = rootPart.Position + Vector3.new(0, 1, 0)
    
    -- Faire tourner lentement la caméra
    self.angle = self.angle + dt * 0.5
    
    -- Calculer la position de la caméra
    local targetPosition = center +
                          Vector3.new(math.cos(self.angle) * self.distance, 
                                     self.distance * math.sin(self.verticalAngle), 
                                     math.sin(self.angle) * self.distance)
    
    -- Définir la caméra
    self.camera.CFrame = CFrame.new(targetPosition, center)
end

function CameraController:SetMode(mode)
    if not self.modeSettings[mode] then
        warn("CameraController: Mode de caméra invalide - " .. tostring(mode))
        return
    end
    
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
        self.previousMode = nil
    end
end

-- Passer temporairement en mode orbite (pour l'inventaire/craft)
function CameraController:EnterOrbitMode()
    if self.mode ~= CAMERA_MODES.ORBIT then
        self.previousMode = self.mode
        self:SetMode(CAMERA_MODES.ORBIT)
    end
end

-- Quitter le mode orbite
function CameraController:ExitOrbitMode()
    if self.mode == CAMERA_MODES.ORBIT and self.previousMode then
        self:SetMode(self.previousMode)
        self.previousMode = nil
    end
end

return CameraController