-- src/client/ui/StatsUI.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared.constants.GameSettings)

local StatsUI = {}
StatsUI.__index = StatsUI

function StatsUI.new()
    local self = setmetatable({}, StatsUI)
    
    -- Référence au joueur local
    self.player = Players.LocalPlayer
    
    -- Valeurs actuelles des stats
    self.stats = {
        hunger = 100,
        thirst = 100,
        energy = 100,
        temperature = 50,
        age = 16,
    }
    
    -- Interface ScreenGui
    self.gui = nil
    self.barFrames = {}
    self.barFills = {}
    self.labels = {}
    
    return self
end

function StatsUI:Initialize()
    -- Créer l'interface ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "StatsUI"
    self.gui.ResetOnSpawn = false
    
    -- Cadre principal pour les barres de statistiques
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "StatsFrame"
    mainFrame.Size = UDim2.new(0, 200, 0, 130)
    mainFrame.Position = UDim2.new(0, 10, 0, 10)
    mainFrame.BackgroundTransparency = 0.5
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = self.gui
    
    -- Arrondir les coins
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = mainFrame
    
    -- Créer les barres de statistiques
    self:CreateStatBar(mainFrame, "Faim", Color3.fromRGB(255, 180, 0), UDim2.new(0, 0, 0, 0), "hunger")
    self:CreateStatBar(mainFrame, "Soif", Color3.fromRGB(0, 150, 255), UDim2.new(0, 0, 0, 25), "thirst")
    self:CreateStatBar(mainFrame, "Énergie", Color3.fromRGB(100, 255, 100), UDim2.new(0, 0, 0, 50), "energy")
    self:CreateStatBar(mainFrame, "Temp.", Color3.fromRGB(255, 100, 100), UDim2.new(0, 0, 0, 75), "temperature")
    
    -- Affichage de l'âge
    local ageFrame = Instance.new("Frame")
    ageFrame.Name = "AgeFrame"
    ageFrame.Size = UDim2.new(1, -20, 0, 20)
    ageFrame.Position = UDim2.new(0, 10, 0, 100)
    ageFrame.BackgroundTransparency = 0.7
    ageFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    ageFrame.BorderSizePixel = 0
    ageFrame.Parent = mainFrame
    
    local ageLabel = Instance.new("TextLabel")
    ageLabel.Name = "AgeLabel"
    ageLabel.Size = UDim2.new(0.4, 0, 1, 0)
    ageLabel.Position = UDim2.new(0, 5, 0, 0)
    ageLabel.BackgroundTransparency = 1
    ageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ageLabel.TextXAlignment = Enum.TextXAlignment.Left
    ageLabel.Text = "Âge:"
    ageLabel.TextSize = 14
    ageLabel.Font = Enum.Font.SourceSansBold
    ageLabel.Parent = ageFrame
    
    local ageValue = Instance.new("TextLabel")
    ageValue.Name = "AgeValue"
    ageValue.Size = UDim2.new(0.6, -10, 1, 0)
    ageValue.Position = UDim2.new(0.4, 5, 0, 0)
    ageValue.BackgroundTransparency = 1
    ageValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    ageValue.TextXAlignment = Enum.TextXAlignment.Left
    ageValue.Text = "16 ans"
    ageValue.TextSize = 14
    ageValue.Font = Enum.Font.SourceSans
    ageValue.Parent = ageFrame
    
    self.labels["age"] = ageValue
    
    -- Ajouter l'interface au joueur
    self.gui.Parent = self.player.PlayerGui
    
    -- Mettre à jour l'interface avec les valeurs initiales
    self:UpdateAllStats()
end

function StatsUI:CreateStatBar(parent, name, color, position, statKey)
    -- Cadre pour la barre
    local barFrame = Instance.new("Frame")
    barFrame.Name = name .. "Frame"
    barFrame.Size = UDim2.new(1, -20, 0, 20)
    barFrame.Position = position + UDim2.new(0, 10, 0, 0)
    barFrame.BackgroundTransparency = 0.7
    barFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    barFrame.BorderSizePixel = 0
    barFrame.Parent = parent
    
    -- Label pour le nom de la stat
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0.4, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 5, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = name .. ":"
    nameLabel.TextSize = 14
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Parent = barFrame
    
    -- Remplissage de la barre (indicateur de niveau)
    local barFill = Instance.new("Frame")
    barFill.Name = "BarFill"
    barFill.Size = UDim2.new(0.6, -10, 1, -6)
    barFill.Position = UDim2.new(0.4, 5, 0, 3)
    barFill.BackgroundColor3 = color
    barFill.BorderSizePixel = 0
    barFill.Parent = barFrame
    
    -- Stocker les références pour mise à jour
    self.barFrames[statKey] = barFrame
    self.barFills[statKey] = barFill
end

function StatsUI:UpdateStat(statKey, value)
    self.stats[statKey] = value
    
    -- Mettre à jour la barre de statistique correspondante
    if self.barFills[statKey] then
        local fraction = value / (statKey == "temperature" and 100 or GameSettings.Survival["max" .. string.upper(string.sub(statKey, 1, 1)) .. string.sub(statKey, 2)])
        self.barFills[statKey].Size = UDim2.new(0.6 * fraction, -10, 1, -6)
        
        -- Changer la couleur en fonction du niveau (critique ou non)
        if statKey == "temperature" then
            -- Pour la température, la couleur change selon si trop chaud ou trop froid
            if value < GameSettings.Survival.criticalColdThreshold then
                self.barFills[statKey].BackgroundColor3 = Color3.fromRGB(100, 100, 255) -- Bleu pour froid
            elseif value > GameSettings.Survival.criticalHeatThreshold then
                self.barFills[statKey].BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Rouge pour chaud
            else
                self.barFills[statKey].BackgroundColor3 = Color3.fromRGB(255, 100, 100) -- Normal
            end
        else
            -- Pour les autres stats, rouge si critique
            local criticalThreshold = GameSettings.Survival["critical" .. string.upper(string.sub(statKey, 1, 1)) .. string.sub(statKey, 2) .. "Threshold"]
            
            if value <= criticalThreshold then
                self.barFills[statKey].BackgroundColor3 = Color3.fromRGB(255, 50, 50) -- Rouge pour critique
            else
                -- Couleurs normales
                if statKey == "hunger" then
                    self.barFills[statKey].BackgroundColor3 = Color3.fromRGB(255, 180, 0)
                elseif statKey == "thirst" then
                    self.barFills[statKey].BackgroundColor3 = Color3.fromRGB(0, 150, 255)
                elseif statKey == "energy" then
                    self.barFills[statKey].BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                end
            end
        end
    end
    
    -- Mettre à jour le texte d'âge
    if statKey == "age" and self.labels["age"] then
        self.labels["age"].Text = tostring(value) .. " ans"
    end
end

function StatsUI:UpdateAllStats()
    for stat, value in pairs(self.stats) do
        self:UpdateStat(stat, value)
    end
end

-- Méthode pour recevoir les mises à jour du serveur
function StatsUI:HandleServerUpdate(statData)
    for stat, value in pairs(statData) do
        if self.stats[stat] ~= nil then
            self:UpdateStat(stat, value)
        end
    end
end

return StatsUI