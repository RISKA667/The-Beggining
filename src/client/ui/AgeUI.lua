-- src/client/ui/AgeUI.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local AgeUI = {}
AgeUI.__index = AgeUI

function AgeUI.new()
    local self = setmetatable({}, AgeUI)
    
    -- Référence au joueur local
    self.player = Players.LocalPlayer
    
    -- Âge actuel
    self.age = 16
    
    -- Interface ScreenGui
    self.gui = nil
    
    return self
end

function AgeUI:Initialize()
    -- Créer l'interface ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "AgeUI"
    self.gui.ResetOnSpawn = false
    
    -- Cadre pour l'affichage de l'âge
    local ageFrame = Instance.new("Frame")
    ageFrame.Name = "AgeFrame"
    ageFrame.Size = UDim2.new(0, 160, 0, 35)
    ageFrame.Position = UDim2.new(1, -170, 0, 10)
    ageFrame.BackgroundTransparency = 0.5
    ageFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    ageFrame.BorderSizePixel = 0
    ageFrame.Parent = self.gui
    
    -- Arrondir les coins
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = ageFrame
    
    -- Icône pour représenter l'âge (une horloge ou un sablier)
    local ageIcon = Instance.new("ImageLabel")
    ageIcon.Name = "AgeIcon"
    ageIcon.Size = UDim2.new(0, 25, 0, 25)
    ageIcon.Position = UDim2.new(0, 5, 0.5, -12.5)
    ageIcon.BackgroundTransparency = 1
    ageIcon.Image = "rbxassetid://12345710" -- À remplacer par un ID réel
    ageIcon.Parent = ageFrame
    
    -- Étiquette "Âge:"
    local ageLabel = Instance.new("TextLabel")
    ageLabel.Name = "AgeLabel"
    ageLabel.Size = UDim2.new(0, 40, 0, 25)
    ageLabel.Position = UDim2.new(0, 35, 0.5, -12.5)
    ageLabel.BackgroundTransparency = 1
    ageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ageLabel.Text = "Âge:"
    ageLabel.TextSize = 16
    ageLabel.Font = Enum.Font.SourceSansBold
    ageLabel.TextXAlignment = Enum.TextXAlignment.Left
    ageLabel.Parent = ageFrame
    
    -- Valeur de l'âge
    local ageValue = Instance.new("TextLabel")
    ageValue.Name = "AgeValue"
    ageValue.Size = UDim2.new(0, 70, 0, 25)
    ageValue.Position = UDim2.new(0, 80, 0.5, -12.5)
    ageValue.BackgroundTransparency = 1
    ageValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    ageValue.Text = "16 ans"
    ageValue.TextSize = 16
    ageValue.Font = Enum.Font.SourceSans
    ageValue.TextXAlignment = Enum.TextXAlignment.Left
    ageValue.Parent = ageFrame
    
    -- Date et heure en jeu
    local dateTimeFrame = Instance.new("Frame")
    dateTimeFrame.Name = "DateTimeFrame"
    dateTimeFrame.Size = UDim2.new(0, 160, 0, 35)
    dateTimeFrame.Position = UDim2.new(1, -170, 0, 50)
    dateTimeFrame.BackgroundTransparency = 0.5
    dateTimeFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    dateTimeFrame.BorderSizePixel = 0
    dateTimeFrame.Parent = self.gui
    
    -- Arrondir les coins
    local dateTimeCorner = Instance.new("UICorner")
    dateTimeCorner.CornerRadius = UDim.new(0, 8)
    dateTimeCorner.Parent = dateTimeFrame
    
    -- Icône pour l'horloge
    local clockIcon = Instance.new("ImageLabel")
    clockIcon.Name = "ClockIcon"
    clockIcon.Size = UDim2.new(0, 25, 0, 25)
    clockIcon.Position = UDim2.new(0, 5, 0.5, -12.5)
    clockIcon.BackgroundTransparency = 1
    clockIcon.Image = "rbxassetid://12345711" -- À remplacer par un ID réel
    clockIcon.Parent = dateTimeFrame
    
    -- Heure en jeu
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TimeLabel"
    timeLabel.Size = UDim2.new(0, 70, 0, 25)
    timeLabel.Position = UDim2.new(0, 35, 0, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    timeLabel.Text = "12:00"
    timeLabel.TextSize = 14
    timeLabel.Font = Enum.Font.SourceSans
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Parent = dateTimeFrame
    
    -- Date en jeu
    local dateLabel = Instance.new("TextLabel")
    dateLabel.Name = "DateLabel"
    dateLabel.Size = UDim2.new(0, 70, 0, 25)
    dateLabel.Position = UDim2.new(0, 35, 0, 15)
    dateLabel.BackgroundTransparency = 1
    dateLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    dateLabel.Text = "Jour 1, An 1"
    dateLabel.TextSize = 12
    dateLabel.Font = Enum.Font.SourceSans
    dateLabel.TextXAlignment = Enum.TextXAlignment.Left
    dateLabel.Parent = dateTimeFrame
    
    -- Stocker les références importantes
    self.ageValue = ageValue
    self.timeLabel = timeLabel
    self.dateLabel = dateLabel
    
    -- Ajouter l'interface au joueur
    self.gui.Parent = self.player.PlayerGui
    
    -- Mettre à jour l'interface avec les valeurs initiales
    self:UpdateAge(self.age)
    
    -- Se connecter aux événements de mise à jour du temps
    self:ConnectToTimeEvents()
    
    return self
end

-- Mettre à jour l'affichage de l'âge
function AgeUI:UpdateAge(age)
    self.age = age
    
    if self.ageValue then
        self.ageValue.Text = tostring(math.floor(age)) .. " ans"
        
        -- Changer la couleur selon l'âge
        if age >= 50 then
            -- Rouge pour les âges élevés (proche de la mort naturelle)
            self.ageValue.TextColor3 = Color3.fromRGB(255, 100, 100)
        elseif age >= 30 then
            -- Orange pour l'âge adulte avancé
            self.ageValue.TextColor3 = Color3.fromRGB(255, 180, 100)
        elseif age >= 18 then
            -- Blanc pour l'âge adulte
            self.ageValue.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            -- Vert pour l'enfance
            self.ageValue.TextColor3 = Color3.fromRGB(100, 255, 100)
        end
    end
end

-- Mettre à jour l'affichage de l'heure
function AgeUI:UpdateTime(timeInfo)
    if not timeInfo then return end
    
    if self.timeLabel then
        self.timeLabel.Text = timeInfo.timeString or "00:00"
    end
    
    if self.dateLabel then
        self.dateLabel.Text = "Jour " .. (timeInfo.gameDay or 1) .. ", An " .. (timeInfo.gameYear or 1)
    end
    
    -- Mettre à jour l'apparence en fonction du moment de la journée
    if timeInfo.isDay and not timeInfo.isDawnOrDusk then
        -- Jour
        self.timeLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
    elseif timeInfo.isDawnOrDusk then
        -- Aube ou crépuscule
        self.timeLabel.TextColor3 = Color3.fromRGB(255, 180, 100)
    else
        -- Nuit
        self.timeLabel.TextColor3 = Color3.fromRGB(150, 150, 255)
    end
end

-- Se connecter aux événements de mise à jour du temps
function AgeUI:ConnectToTimeEvents()
    local events = ReplicatedStorage:FindFirstChild("Events")
    
    if events then
        local timeUpdateEvent = events:FindFirstChild("TimeUpdate")
        if timeUpdateEvent then
            timeUpdateEvent.OnClientEvent:Connect(function(timeInfo)
                self:UpdateTime(timeInfo)
            end)
        end
    end
end

-- Afficher une notification de mise à jour d'âge (lors d'un anniversaire)
function AgeUI:ShowAgeNotification(newAge)
    -- Créer une notification qui disparaît automatiquement
    local notification = Instance.new("Frame")
    notification.Name = "AgeNotification"
    notification.Size = UDim2.new(0, 200, 0, 50)
    notification.Position = UDim2.new(0.5, -100, 0.3, 0)
    notification.BackgroundTransparency = 0.3
    notification.BackgroundColor3 = Color3.fromRGB(40, 40, 100)
    notification.BorderSizePixel = 0
    notification.Parent = self.gui
    
    -- Arrondir les coins
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = notification
    
    -- Texte de la notification
    local notifText = Instance.new("TextLabel")
    notifText.Name = "NotifText"
    notifText.Size = UDim2.new(1, 0, 1, 0)
    notifText.BackgroundTransparency = 1
    notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifText.Text = "Joyeux anniversaire!\nVous avez maintenant " .. newAge .. " ans!"
    notifText.TextSize = 16
    notifText.Font = Enum.Font.SourceSansBold
    notifText.Parent = notification
    
    -- Animation d'apparition
    notification.Position = UDim2.new(0.5, -100, 0, -50)
    notification:TweenPosition(UDim2.new(0.5, -100, 0.3, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Bounce, 0.5, true)
    
    -- Auto-destruction après 5 secondes
    delay(5, function()
        notification:TweenPosition(UDim2.new(0.5, -100, 0, -50), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5, true, function()
            notification:Destroy()
        end)
    end)
end

return AgeUI