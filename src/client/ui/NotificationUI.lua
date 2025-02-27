-- src/client/ui/NotificationUI.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local NotificationUI = {}
NotificationUI.__index = NotificationUI

function NotificationUI.new()
    local self = setmetatable({}, NotificationUI)
    
    -- Référence au joueur local
    self.player = Players.LocalPlayer
    
    -- Interface ScreenGui
    self.gui = nil
    
    -- File d'attente des notifications
    self.notificationQueue = {}
    
    -- Max notifications visibles simultanément
    self.maxVisibleNotifications = 5
    
    -- Compteur pour les IDs de notification
    self.nextNotificationId = 1
    
    -- Références aux notifications actives
    self.activeNotifications = {}
    
    -- Configuration des notifications
    self.config = {
        width = 300,
        height = 60,
        padding = 10,
        fadeTime = 0.3,
        defaultDuration = 5,
        startPosition = UDim2.new(1, 20, 0.15, 0),
        endPosition = UDim2.new(1, -330, 0.15, 0),
        defaultColor = {
            info = Color3.fromRGB(40, 80, 200),
            success = Color3.fromRGB(40, 180, 40),
            warning = Color3.fromRGB(220, 150, 40),
            error = Color3.fromRGB(220, 40, 40),
            system = Color3.fromRGB(100, 50, 150)
        }
    }
    
    return self
end

function NotificationUI:Initialize()
    -- Créer l'interface ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "NotificationUI"
    self.gui.ResetOnSpawn = false
    
    -- Rendre l'interface redimensionnable
    self.gui.IgnoreGuiInset = true
    
    -- Paramètre pour un bon rendu sur téléphone et autres appareils
    self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Conteneur pour les notifications
    self.notificationContainer = Instance.new("Frame")
    self.notificationContainer.Name = "NotificationContainer"
    self.notificationContainer.Size = UDim2.new(1, 0, 1, 0)
    self.notificationContainer.BackgroundTransparency = 1
    self.notificationContainer.Parent = self.gui
    
    -- Ajouter l'interface au joueur
    self.gui.Parent = self.player.PlayerGui
    
    -- Connecter aux événements du serveur
    self:ConnectToEvents()
    
    return self
end

function NotificationUI:ConnectToEvents()
    local events = ReplicatedStorage:FindFirstChild("Events")
    
    if events then
        local notificationEvent = events:FindFirstChild("Notification")
        if notificationEvent then
            notificationEvent.OnClientEvent:Connect(function(message, messageType, duration)
                self:AddNotification(message, messageType, duration)
            end)
        end
    end
end

function NotificationUI:AddNotification(message, messageType, duration)
    -- Valeurs par défaut
    messageType = messageType or "info"
    duration = duration or self.config.defaultDuration
    
    -- Créer l'ID pour cette notification
    local notificationId = self.nextNotificationId
    self.nextNotificationId = self.nextNotificationId + 1
    
    -- Ajouter à la file d'attente
    table.insert(self.notificationQueue, {
        id = notificationId,
        message = message,
        type = messageType,
        duration = duration
    })
    
    -- Traiter la file d'attente
    self:ProcessQueue()
end

function NotificationUI:ProcessQueue()
    -- Vérifier si on peut afficher plus de notifications
    if #self.activeNotifications >= self.maxVisibleNotifications then
        return
    end
    
    -- S'il y a des notifications en attente, les afficher
    if #self.notificationQueue > 0 then
        local notificationData = table.remove(self.notificationQueue, 1)
        self:ShowNotification(notificationData)
        
        -- Continuer à traiter la file si possible
        self:ProcessQueue()
    end
end

function NotificationUI:ShowNotification(data)
    -- Créer le cadre de notification
    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "Notification_" .. data.id
    notificationFrame.Size = UDim2.new(0, self.config.width, 0, self.config.height)
    notificationFrame.Position = self.config.startPosition
    notificationFrame.BackgroundColor3 = self.config.defaultColor[data.type] or self.config.defaultColor.info
    notificationFrame.BackgroundTransparency = 0.2
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Parent = self.notificationContainer
    
    -- Arrondir les coins
    local cornerRadius = Instance.new("UICorner")
    cornerRadius.CornerRadius = UDim.new(0, 8)
    cornerRadius.Parent = notificationFrame
    
    -- Icône pour le type de notification
    local iconImage = Instance.new("ImageLabel")
    iconImage.Name = "Icon"
    iconImage.Size = UDim2.new(0, 30, 0, 30)
    iconImage.Position = UDim2.new(0, 10, 0.5, -15)
    iconImage.BackgroundTransparency = 1
    
    -- Définir l'image en fonction du type
    if data.type == "info" then
        iconImage.Image = "rbxassetid://6031071053" -- Icône d'information
    elseif data.type == "success" then
        iconImage.Image = "rbxassetid://6031068420" -- Icône de succès
    elseif data.type == "warning" then
        iconImage.Image = "rbxassetid://6031071057" -- Icône d'avertissement
    elseif data.type == "error" then
        iconImage.Image = "rbxassetid://6031071054" -- Icône d'erreur
    elseif data.type == "system" then
        iconImage.Image = "rbxassetid://6026568240" -- Icône système
    end
    
    iconImage.Parent = notificationFrame
    
    -- Texte du message
    local messageText = Instance.new("TextLabel")
    messageText.Name = "Message"
    messageText.Size = UDim2.new(1, -60, 1, 0)
    messageText.Position = UDim2.new(0, 50, 0, 0)
    messageText.BackgroundTransparency = 1
    messageText.Font = Enum.Font.SourceSansSemibold
    messageText.TextSize = 14
    messageText.TextColor3 = Color3.fromRGB(255, 255, 255)
    messageText.TextXAlignment = Enum.TextXAlignment.Left
    messageText.TextYAlignment = Enum.TextYAlignment.Center
    messageText.TextWrapped = true
    messageText.Text = data.message
    messageText.Parent = notificationFrame
    
    -- Bouton de fermeture
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.BackgroundTransparency = 1
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.TextSize = 14
    closeButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    closeButton.Text = "×"
    closeButton.Parent = notificationFrame
    
    -- Connecter le bouton de fermeture
    closeButton.MouseButton1Click:Connect(function()
        self:CloseNotification(data.id)
    end)
    
    -- Indicateur de temps restant
    local timerBar = Instance.new("Frame")
    timerBar.Name = "TimerBar"
    timerBar.Size = UDim2.new(1, 0, 0, 3)
    timerBar.Position = UDim2.new(0, 0, 1, -3)
    timerBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    timerBar.BackgroundTransparency = 0.5
    timerBar.BorderSizePixel = 0
    timerBar.Parent = notificationFrame
    
    -- Animation d'entrée
    local tweenInfo = TweenInfo.new(
        self.config.fadeTime,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    local tweenGoal = {Position = self.config.endPosition}
    local tween = TweenService:Create(notificationFrame, tweenInfo, tweenGoal)
    tween:Play()
    
    -- Animer la barre de temps
    local timerTweenInfo = TweenInfo.new(
        data.duration,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )
    
    local timerTweenGoal = {Size = UDim2.new(0, 0, 0, 3)}
    local timerTween = TweenService:Create(timerBar, timerTweenInfo, timerTweenGoal)
    timerTween:Play()
    
    -- Ajouter à la liste des notifications actives
    self.activeNotifications[data.id] = {
        frame = notificationFrame,
        data = data
    }
    
    -- Réorganiser les notifications
    self:RepositionNotifications()
    
    -- Programmer la fermeture automatique
    delay(data.duration, function()
        self:CloseNotification(data.id)
    end)
end

function NotificationUI:CloseNotification(id)
    local notification = self.activeNotifications[id]
    if not notification then return end
    
    -- Animation de sortie
    local tweenInfo = TweenInfo.new(
        self.config.fadeTime,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.In
    )
    
    local tweenGoal = {Position = self.config.startPosition}
    local tween = TweenService:Create(notification.frame, tweenInfo, tweenGoal)
    
    tween.Completed:Connect(function(playbackState)
        if playbackState == Enum.PlaybackState.Completed then
            notification.frame:Destroy()
            self.activeNotifications[id] = nil
            
            -- Réorganiser les notifications restantes
            self:RepositionNotifications()
            
            -- Traiter la file d'attente si possible
            self:ProcessQueue()
        end
    end)
    
    tween:Play()
end

function NotificationUI:RepositionNotifications()
    local activeIds = {}
    
    -- Collecter les IDs actifs
    for id, _ in pairs(self.activeNotifications) do
        table.insert(activeIds, id)
    end
    
    -- Trier par ID (pour garder l'ordre chronologique)
    table.sort(activeIds)
    
    -- Repositionner chaque notification
    for index, id in ipairs(activeIds) do
        local notification = self.activeNotifications[id]
        if notification and notification.frame then
            local yOffset = (index - 1) * (self.config.height + self.config.padding)
            
            -- Animation de déplacement
            local tweenInfo = TweenInfo.new(
                0.2,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            )
            
            local newPosition = UDim2.new(
                self.config.endPosition.X.Scale,
                self.config.endPosition.X.Offset,
                self.config.endPosition.Y.Scale,
                self.config.endPosition.Y.Offset + yOffset
            )
            
            local tweenGoal = {Position = newPosition}
            local tween = TweenService:Create(notification.frame, tweenInfo, tweenGoal)
            tween:Play()
        end
    end
end

-- Afficher une notification d'information
function NotificationUI:Info(message, duration)
    self:AddNotification(message, "info", duration)
end

-- Afficher une notification de succès
function NotificationUI:Success(message, duration)
    self:AddNotification(message, "success", duration)
end

-- Afficher une notification d'avertissement
function NotificationUI:Warning(message, duration)
    self:AddNotification(message, "warning", duration)
end

-- Afficher une notification d'erreur
function NotificationUI:Error(message, duration)
    self:AddNotification(message, "error", duration)
end

-- Afficher une notification système
function NotificationUI:System(message, duration)
    self:AddNotification(message, "system", duration)
end

-- Effacer toutes les notifications
function NotificationUI:ClearAll()
    for id, _ in pairs(self.activeNotifications) do
        self:CloseNotification(id)
    end
    
    -- Vider également la file d'attente
    self.notificationQueue = {}
end

return NotificationUI