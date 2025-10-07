-- src/client/ui/CraftingStationUI.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CraftingStationUI = {}
CraftingStationUI.__index = CraftingStationUI

function CraftingStationUI.new()
    local self = setmetatable({}, CraftingStationUI)
    
    -- Type de station (cooking, smelting, forging)
    self.stationType = nil
    self.structureId = nil
    
    -- Références UI
    self.screenGui = nil
    self.mainFrame = nil
    self.inputSlots = {}
    self.outputSlot = nil
    self.progressBar = nil
    
    -- Données de crafting
    self.currentRecipe = nil
    self.craftingProgress = 0
    
    -- RemoteEvents
    self.remoteEvents = {}
    
    return self
end

-- Créer l'interface utilisateur
function CraftingStationUI:CreateUI(stationType, structureId)
    self.stationType = stationType
    self.structureId = structureId
    
    -- ScreenGui principal
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "CraftingStationUI"
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Fond sombre
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 0.5
    background.BorderSizePixel = 0
    background.Parent = self.screenGui
    
    -- Frame principale
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MainFrame"
    self.mainFrame.Size = UDim2.new(0, 500, 0, 400)
    self.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    self.mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    self.mainFrame.BorderSizePixel = 2
    self.mainFrame.BorderColor3 = Color3.fromRGB(100, 100, 100)
    self.mainFrame.Parent = self.screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = self.mainFrame
    
    -- Titre
    self:CreateTitle()
    
    -- Bouton de fermeture
    self:CreateCloseButton()
    
    -- Slots d'entrée
    self:CreateInputSlots()
    
    -- Barre de progression
    self:CreateProgressBar()
    
    -- Slot de sortie
    self:CreateOutputSlot()
    
    -- Bouton de crafting
    self:CreateCraftButton()
    
    -- Liste de recettes (selon le type)
    self:CreateRecipeList()
    
    self.screenGui.Parent = playerGui
    
    -- Animation d'ouverture
    self:AnimateOpen()
end

-- Créer le titre
function CraftingStationUI:CreateTitle()
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -60, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    
    -- Titre selon le type
    local titles = {
        cooking = "🔥 Feu de camp - Cuisson",
        smelting = "⚗️ Four - Fonte",
        forging = "🔨 Enclume - Forge"
    }
    
    title.Text = titles[self.stationType] or "Station de craft"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 24
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = self.mainFrame
end

-- Créer le bouton de fermeture
function CraftingStationUI:CreateCloseButton()
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 40, 0, 40)
    closeButton.Position = UDim2.new(1, -45, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "✕"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 24
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Parent = self.mainFrame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        self:Close()
    end)
end

-- Créer les slots d'entrée
function CraftingStationUI:CreateInputSlots()
    local slotsFrame = Instance.new("Frame")
    slotsFrame.Name = "InputSlots"
    slotsFrame.Size = UDim2.new(1, -20, 0, 100)
    slotsFrame.Position = UDim2.new(0, 10, 0, 55)
    slotsFrame.BackgroundTransparency = 1
    slotsFrame.Parent = self.mainFrame
    
    local slotsLayout = Instance.new("UIListLayout")
    slotsLayout.FillDirection = Enum.FillDirection.Horizontal
    slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    slotsLayout.Padding = UDim.new(0, 20)
    slotsLayout.Parent = slotsFrame
    
    -- Créer 2-3 slots selon le type
    local numSlots = (self.stationType == "forging") and 3 or 2
    
    for i = 1, numSlots do
        local slot = self:CreateSlot("Input" .. i, "Ingrédient " .. i)
        slot.Parent = slotsFrame
        table.insert(self.inputSlots, slot)
    end
end

-- Créer un slot
function CraftingStationUI:CreateSlot(name, labelText)
    local slot = Instance.new("Frame")
    slot.Name = name
    slot.Size = UDim2.new(0, 80, 0, 80)
    slot.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    slot.BorderSizePixel = 2
    slot.BorderColor3 = Color3.fromRGB(100, 100, 100)
    
    local slotCorner = Instance.new("UICorner")
    slotCorner.CornerRadius = UDim.new(0, 8)
    slotCorner.Parent = slot
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 1, 5)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(200, 200, 200)
    label.TextSize = 12
    label.Font = Enum.Font.SourceSans
    label.Parent = slot
    
    local itemIcon = Instance.new("TextLabel")
    itemIcon.Name = "ItemIcon"
    itemIcon.Size = UDim2.new(1, 0, 1, 0)
    itemIcon.BackgroundTransparency = 1
    itemIcon.Text = ""
    itemIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    itemIcon.TextSize = 36
    itemIcon.Font = Enum.Font.SourceSansBold
    itemIcon.Parent = slot
    
    return slot
end

-- Créer la barre de progression
function CraftingStationUI:CreateProgressBar()
    local progressFrame = Instance.new("Frame")
    progressFrame.Name = "ProgressFrame"
    progressFrame.Size = UDim2.new(1, -20, 0, 40)
    progressFrame.Position = UDim2.new(0, 10, 0, 170)
    progressFrame.BackgroundTransparency = 1
    progressFrame.Parent = self.mainFrame
    
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Size = UDim2.new(1, 0, 0, 15)
    progressLabel.BackgroundTransparency = 1
    progressLabel.Text = "Progression"
    progressLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    progressLabel.TextSize = 12
    progressLabel.Font = Enum.Font.SourceSans
    progressLabel.Parent = progressFrame
    
    local progressBarBg = Instance.new("Frame")
    progressBarBg.Name = "ProgressBarBg"
    progressBarBg.Size = UDim2.new(1, 0, 0, 20)
    progressBarBg.Position = UDim2.new(0, 0, 0, 20)
    progressBarBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    progressBarBg.BorderSizePixel = 0
    progressBarBg.Parent = progressFrame
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 4)
    bgCorner.Parent = progressBarBg
    
    self.progressBar = Instance.new("Frame")
    self.progressBar.Name = "ProgressBar"
    self.progressBar.Size = UDim2.new(0, 0, 1, 0)
    self.progressBar.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    self.progressBar.BorderSizePixel = 0
    self.progressBar.Parent = progressBarBg
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = self.progressBar
end

-- Créer le slot de sortie
function CraftingStationUI:CreateOutputSlot()
    local outputFrame = Instance.new("Frame")
    outputFrame.Name = "OutputFrame"
    outputFrame.Size = UDim2.new(0, 100, 0, 100)
    outputFrame.Position = UDim2.new(0.5, -50, 0, 230)
    outputFrame.BackgroundTransparency = 1
    outputFrame.Parent = self.mainFrame
    
    self.outputSlot = self:CreateSlot("Output", "Résultat")
    self.outputSlot.Size = UDim2.new(0, 100, 0, 100)
    self.outputSlot.Parent = outputFrame
end

-- Créer le bouton de crafting
function CraftingStationUI:CreateCraftButton()
    local craftButton = Instance.new("TextButton")
    craftButton.Name = "CraftButton"
    craftButton.Size = UDim2.new(0, 200, 0, 40)
    craftButton.Position = UDim2.new(0.5, -100, 1, -50)
    craftButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    craftButton.BorderSizePixel = 0
    craftButton.Text = "Démarrer"
    craftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    craftButton.TextSize = 18
    craftButton.Font = Enum.Font.SourceSansBold
    craftButton.Parent = self.mainFrame
    
    local craftCorner = Instance.new("UICorner")
    craftCorner.CornerRadius = UDim.new(0, 8)
    craftCorner.Parent = craftButton
    
    craftButton.MouseButton1Click:Connect(function()
        self:StartCrafting()
    end)
    
    -- Hover effect
    craftButton.MouseEnter:Connect(function()
        craftButton.BackgroundColor3 = Color3.fromRGB(56, 142, 60)
    end)
    
    craftButton.MouseLeave:Connect(function()
        craftButton.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
    end)
end

-- Créer la liste de recettes
function CraftingStationUI:CreateRecipeList()
    -- TODO: Implémenter la liste des recettes disponibles selon le type de station
    -- Pour l'instant, c'est un placeholder
end

-- Animation d'ouverture
function CraftingStationUI:AnimateOpen()
    self.mainFrame.Size = UDim2.new(0, 0, 0, 0)
    
    local tween = TweenService:Create(
        self.mainFrame,
        TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 500, 0, 400)}
    )
    
    tween:Play()
end

-- Démarrer le crafting
function CraftingStationUI:StartCrafting()
    -- TODO: Envoyer une requête au serveur pour démarrer le crafting
    print("Démarrage du crafting...")
    
    -- Simuler la progression
    self:SimulateProgress()
end

-- Simuler la progression
function CraftingStationUI:SimulateProgress()
    local duration = 5 -- 5 secondes
    local startTime = tick()
    
    spawn(function()
        while tick() - startTime < duration do
            local progress = (tick() - startTime) / duration
            self.progressBar.Size = UDim2.new(progress, 0, 1, 0)
            wait(0.1)
        end
        
        self.progressBar.Size = UDim2.new(1, 0, 1, 0)
        print("Crafting terminé!")
    end)
end

-- Fermer l'interface
function CraftingStationUI:Close()
    if self.screenGui then
        self.screenGui:Destroy()
        self.screenGui = nil
    end
end

-- Ouvrir l'interface
function CraftingStationUI:Open(stationType, structureId)
    -- Fermer l'interface existante si elle existe
    if self.screenGui then
        self:Close()
    end
    
    -- Créer une nouvelle interface
    self:CreateUI(stationType, structureId)
end

-- Démarrer le service
function CraftingStationUI:Start()
    print("CraftingStationUI: Démarrage...")
    
    -- Récupérer les RemoteEvents
    local Events = ReplicatedStorage:WaitForChild("Events")
    
    -- Créer le RemoteEvent pour ouvrir les stations si pas existant
    local openStationEvent = Events:FindFirstChild("OpenCraftingStation")
    if not openStationEvent then
        -- Le serveur devrait créer cet événement
        warn("CraftingStationUI: RemoteEvent OpenCraftingStation non trouvé")
    else
        self.remoteEvents.OpenCraftingStation = openStationEvent
        
        -- Écouter les demandes d'ouverture
        openStationEvent.OnClientEvent:Connect(function(stationType, structureId)
            self:Open(stationType, structureId)
        end)
    end
    
    print("CraftingStationUI: Démarré avec succès")
    return self
end

return CraftingStationUI