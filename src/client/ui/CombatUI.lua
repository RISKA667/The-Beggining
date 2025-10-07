-- src/client/ui/CombatUI.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CombatUI = {}
CombatUI.__index = CombatUI

function CombatUI.new()
    local self = setmetatable({}, CombatUI)
    
    -- Données de combat
    self.combatData = {
        currentHealth = 100,
        maxHealth = 100,
        armor = 0,
        isInCombat = false,
        attackCooldown = 0,
        isBlocking = false,
        comboCount = 0,
        statusEffects = {}
    }
    
    -- Références UI
    self.screenGui = nil
    self.healthBar = nil
    self.armorBar = nil
    self.cooldownIndicator = nil
    self.comboIndicator = nil
    self.statusEffectsContainer = nil
    
    -- RemoteEvents
    self.remoteEvents = {}
    
    return self
end

-- Créer l'interface utilisateur
function CombatUI:CreateUI()
    -- ScreenGui principal
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "CombatUI"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Frame principale
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 150)
    mainFrame.Position = UDim2.new(0, 10, 1, -160)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.3
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = self.screenGui
    
    -- Coins arrondis
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent = mainFrame
    
    -- Barre de santé
    self:CreateHealthBar(mainFrame)
    
    -- Barre d'armure
    self:CreateArmorBar(mainFrame)
    
    -- Indicateur de cooldown
    self:CreateCooldownIndicator(mainFrame)
    
    -- Indicateur de combo
    self:CreateComboIndicator(mainFrame)
    
    -- Container d'effets de statut
    self:CreateStatusEffectsContainer(mainFrame)
    
    -- Indicateur de blocage
    self:CreateBlockingIndicator(mainFrame)
    
    self.screenGui.Parent = playerGui
end

-- Créer la barre de santé
function CombatUI:CreateHealthBar(parent)
    local healthLabel = Instance.new("TextLabel")
    healthLabel.Name = "HealthLabel"
    healthLabel.Size = UDim2.new(1, -20, 0, 20)
    healthLabel.Position = UDim2.new(0, 10, 0, 10)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Text = "Santé"
    healthLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthLabel.TextSize = 14
    healthLabel.Font = Enum.Font.SourceSansBold
    healthLabel.TextXAlignment = Enum.TextXAlignment.Left
    healthLabel.Parent = parent
    
    local healthBarBg = Instance.new("Frame")
    healthBarBg.Name = "HealthBarBackground"
    healthBarBg.Size = UDim2.new(1, -20, 0, 20)
    healthBarBg.Position = UDim2.new(0, 10, 0, 35)
    healthBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    healthBarBg.BorderSizePixel = 0
    healthBarBg.Parent = parent
    
    local healthBarCorner = Instance.new("UICorner")
    healthBarCorner.CornerRadius = UDim.new(0, 4)
    healthBarCorner.Parent = healthBarBg
    
    self.healthBar = Instance.new("Frame")
    self.healthBar.Name = "HealthBar"
    self.healthBar.Size = UDim2.new(1, 0, 1, 0)
    self.healthBar.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    self.healthBar.BorderSizePixel = 0
    self.healthBar.Parent = healthBarBg
    
    local healthBarFillCorner = Instance.new("UICorner")
    healthBarFillCorner.CornerRadius = UDim.new(0, 4)
    healthBarFillCorner.Parent = self.healthBar
    
    local healthText = Instance.new("TextLabel")
    healthText.Name = "HealthText"
    healthText.Size = UDim2.new(1, 0, 1, 0)
    healthText.BackgroundTransparency = 1
    healthText.Text = "100 / 100"
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextSize = 14
    healthText.Font = Enum.Font.SourceSansBold
    healthText.Parent = healthBarBg
    
    self.healthText = healthText
end

-- Créer la barre d'armure
function CombatUI:CreateArmorBar(parent)
    local armorLabel = Instance.new("TextLabel")
    armorLabel.Name = "ArmorLabel"
    armorLabel.Size = UDim2.new(1, -20, 0, 20)
    armorLabel.Position = UDim2.new(0, 10, 0, 60)
    armorLabel.BackgroundTransparency = 1
    armorLabel.Text = "Armure"
    armorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    armorLabel.TextSize = 14
    armorLabel.Font = Enum.Font.SourceSansBold
    armorLabel.TextXAlignment = Enum.TextXAlignment.Left
    armorLabel.Parent = parent
    
    local armorBarBg = Instance.new("Frame")
    armorBarBg.Name = "ArmorBarBackground"
    armorBarBg.Size = UDim2.new(1, -20, 0, 20)
    armorBarBg.Position = UDim2.new(0, 10, 0, 85)
    armorBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    armorBarBg.BorderSizePixel = 0
    armorBarBg.Parent = parent
    
    local armorBarCorner = Instance.new("UICorner")
    armorBarCorner.CornerRadius = UDim.new(0, 4)
    armorBarCorner.Parent = armorBarBg
    
    self.armorBar = Instance.new("Frame")
    self.armorBar.Name = "ArmorBar"
    self.armorBar.Size = UDim2.new(0, 0, 1, 0)
    self.armorBar.BackgroundColor3 = Color3.fromRGB(158, 158, 158)
    self.armorBar.BorderSizePixel = 0
    self.armorBar.Parent = armorBarBg
    
    local armorBarFillCorner = Instance.new("UICorner")
    armorBarFillCorner.CornerRadius = UDim.new(0, 4)
    armorBarFillCorner.Parent = self.armorBar
    
    local armorText = Instance.new("TextLabel")
    armorText.Name = "ArmorText"
    armorText.Size = UDim2.new(1, 0, 1, 0)
    armorText.BackgroundTransparency = 1
    armorText.Text = "0"
    armorText.TextColor3 = Color3.fromRGB(255, 255, 255)
    armorText.TextSize = 14
    armorText.Font = Enum.Font.SourceSansBold
    armorText.Parent = armorBarBg
    
    self.armorText = armorText
end

-- Créer l'indicateur de cooldown
function CombatUI:CreateCooldownIndicator(parent)
    self.cooldownIndicator = Instance.new("Frame")
    self.cooldownIndicator.Name = "CooldownIndicator"
    self.cooldownIndicator.Size = UDim2.new(0, 60, 0, 60)
    self.cooldownIndicator.Position = UDim2.new(1, -70, 0, 45)
    self.cooldownIndicator.BackgroundColor3 = Color3.fromRGB(255, 87, 34)
    self.cooldownIndicator.BackgroundTransparency = 0.5
    self.cooldownIndicator.BorderSizePixel = 0
    self.cooldownIndicator.Visible = false
    self.cooldownIndicator.Parent = parent
    
    local cooldownCorner = Instance.new("UICorner")
    cooldownCorner.CornerRadius = UDim.new(1, 0)
    cooldownCorner.Parent = self.cooldownIndicator
    
    local cooldownText = Instance.new("TextLabel")
    cooldownText.Name = "CooldownText"
    cooldownText.Size = UDim2.new(1, 0, 1, 0)
    cooldownText.BackgroundTransparency = 1
    cooldownText.Text = "0.0s"
    cooldownText.TextColor3 = Color3.fromRGB(255, 255, 255)
    cooldownText.TextSize = 18
    cooldownText.Font = Enum.Font.SourceSansBold
    cooldownText.Parent = self.cooldownIndicator
    
    self.cooldownText = cooldownText
end

-- Créer l'indicateur de combo
function CombatUI:CreateComboIndicator(parent)
    self.comboIndicator = Instance.new("TextLabel")
    self.comboIndicator.Name = "ComboIndicator"
    self.comboIndicator.Size = UDim2.new(0, 100, 0, 40)
    self.comboIndicator.Position = UDim2.new(0, 10, 0, 110)
    self.comboIndicator.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
    self.comboIndicator.BackgroundTransparency = 0.3
    self.comboIndicator.BorderSizePixel = 0
    self.comboIndicator.Text = "COMBO x3"
    self.comboIndicator.TextColor3 = Color3.fromRGB(255, 255, 255)
    self.comboIndicator.TextSize = 20
    self.comboIndicator.Font = Enum.Font.SourceSansBold
    self.comboIndicator.Visible = false
    self.comboIndicator.Parent = parent
    
    local comboCorner = Instance.new("UICorner")
    comboCorner.CornerRadius = UDim.new(0, 8)
    comboCorner.Parent = self.comboIndicator
end

-- Créer le container d'effets de statut
function CombatUI:CreateStatusEffectsContainer(parent)
    self.statusEffectsContainer = Instance.new("Frame")
    self.statusEffectsContainer.Name = "StatusEffects"
    self.statusEffectsContainer.Size = UDim2.new(0, 200, 0, 40)
    self.statusEffectsContainer.Position = UDim2.new(1, -210, 0, 5)
    self.statusEffectsContainer.BackgroundTransparency = 1
    self.statusEffectsContainer.Parent = parent
    
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.Padding = UDim.new(0, 5)
    layout.Parent = self.statusEffectsContainer
end

-- Créer l'indicateur de blocage
function CombatUI:CreateBlockingIndicator(parent)
    self.blockingIndicator = Instance.new("Frame")
    self.blockingIndicator.Name = "BlockingIndicator"
    self.blockingIndicator.Size = UDim2.new(0, 100, 0, 30)
    self.blockingIndicator.Position = UDim2.new(0.5, -50, 0, -40)
    self.blockingIndicator.AnchorPoint = Vector2.new(0.5, 0.5)
    self.blockingIndicator.BackgroundColor3 = Color3.fromRGB(33, 150, 243)
    self.blockingIndicator.BackgroundTransparency = 0.3
    self.blockingIndicator.BorderSizePixel = 0
    self.blockingIndicator.Visible = false
    self.blockingIndicator.Parent = parent
    
    local blockCorner = Instance.new("UICorner")
    blockCorner.CornerRadius = UDim.new(0, 6)
    blockCorner.Parent = self.blockingIndicator
    
    local blockText = Instance.new("TextLabel")
    blockText.Size = UDim2.new(1, 0, 1, 0)
    blockText.BackgroundTransparency = 1
    blockText.Text = "🛡️ BLOCAGE"
    blockText.TextColor3 = Color3.fromRGB(255, 255, 255)
    blockText.TextSize = 16
    blockText.Font = Enum.Font.SourceSansBold
    blockText.Parent = self.blockingIndicator
end

-- Mettre à jour les données de combat
function CombatUI:UpdateCombatData(data)
    if not data then return end
    
    -- Mettre à jour les données locales
    if data.currentHealth then self.combatData.currentHealth = data.currentHealth end
    if data.maxHealth then self.combatData.maxHealth = data.maxHealth end
    if data.armor then self.combatData.armor = data.armor end
    if data.isInCombat ~= nil then self.combatData.isInCombat = data.isInCombat end
    
    -- Mettre à jour la barre de santé
    self:UpdateHealthBar()
    
    -- Mettre à jour la barre d'armure
    self:UpdateArmorBar()
end

-- Mettre à jour la barre de santé
function CombatUI:UpdateHealthBar()
    if not self.healthBar then return end
    
    local healthPercent = self.combatData.currentHealth / self.combatData.maxHealth
    self.healthBar.Size = UDim2.new(healthPercent, 0, 1, 0)
    
    -- Changer la couleur selon la santé
    if healthPercent > 0.6 then
        self.healthBar.BackgroundColor3 = Color3.fromRGB(76, 175, 80) -- Vert
    elseif healthPercent > 0.3 then
        self.healthBar.BackgroundColor3 = Color3.fromRGB(255, 193, 7) -- Jaune
    else
        self.healthBar.BackgroundColor3 = Color3.fromRGB(244, 67, 54) -- Rouge
    end
    
    if self.healthText then
        self.healthText.Text = math.floor(self.combatData.currentHealth) .. " / " .. self.combatData.maxHealth
    end
end

-- Mettre à jour la barre d'armure
function CombatUI:UpdateArmorBar()
    if not self.armorBar then return end
    
    local maxArmor = 100
    local armorPercent = math.min(1, self.combatData.armor / maxArmor)
    self.armorBar.Size = UDim2.new(armorPercent, 0, 1, 0)
    
    if self.armorText then
        self.armorText.Text = math.floor(self.combatData.armor)
    end
end

-- Démarrer le service
function CombatUI:Start()
    print("CombatUI: Démarrage...")
    
    -- Créer l'UI
    self:CreateUI()
    
    -- Récupérer les RemoteEvents
    local Events = ReplicatedStorage:WaitForChild("Events")
    self.remoteEvents = {
        UpdateHealth = Events:WaitForChild("UpdateHealth"),
        AttackPlayer = Events:WaitForChild("AttackPlayer")
    }
    
    -- Écouter les mises à jour de santé
    if self.remoteEvents.UpdateHealth then
        self.remoteEvents.UpdateHealth.OnClientEvent:Connect(function(data)
            self:UpdateCombatData(data)
        end)
    end
    
    -- Gérer les contrôles de combat
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        -- Touche F pour bloquer
        if input.KeyCode == Enum.KeyCode.F then
            if self.blockingIndicator then
                self.blockingIndicator.Visible = true
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        -- Touche F relâchée
        if input.KeyCode == Enum.KeyCode.F then
            if self.blockingIndicator then
                self.blockingIndicator.Visible = false
            end
        end
    end)
    
    print("CombatUI: Démarré avec succès")
    return self
end

return CombatUI