-- src/client/ui/FarmingUI.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemTypes = require(Shared.constants.ItemTypes)

local FarmingUI = {}
FarmingUI.__index = FarmingUI

-- Noms des stades de croissance
local GROWTH_STAGE_NAMES = {
	[1] = "🌱 Graine",
	[2] = "🌿 Pousse",
	[3] = "🍃 Jeune plante",
	[4] = "🌾 Plante mature",
	[5] = "✨ Prêt à récolter"
}

-- Couleurs des stades de croissance
local GROWTH_STAGE_COLORS = {
	[1] = Color3.fromRGB(139, 69, 19),   -- Marron (graine)
	[2] = Color3.fromRGB(100, 180, 100), -- Vert clair (pousse)
	[3] = Color3.fromRGB(80, 160, 80),   -- Vert moyen
	[4] = Color3.fromRGB(60, 140, 60),   -- Vert foncé
	[5] = Color3.fromRGB(255, 215, 0)    -- Or (prêt)
}

function FarmingUI.new()
	local self = setmetatable({}, FarmingUI)
	
	-- Référence au joueur local
	self.player = Players.LocalPlayer
	
	-- Interface ScreenGui
	self.gui = nil
	
	-- Cultures suivies
	self.trackedCrops = {} -- [cropId] = cropData
	
	-- Frame des indicateurs de culture
	self.cropIndicators = {}
	
	return self
end

function FarmingUI:Initialize()
	-- Créer l'interface ScreenGui
	self.gui = Instance.new("ScreenGui")
	self.gui.Name = "FarmingUI"
	self.gui.ResetOnSpawn = false
	self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- === PANNEAU D'AIDE RAPIDE ===
	local helpPanel = Instance.new("Frame")
	helpPanel.Name = "HelpPanel"
	helpPanel.Size = UDim2.new(0, 250, 0, 140)
	helpPanel.Position = UDim2.new(1, -260, 0, 150)
	helpPanel.BackgroundTransparency = 0.2
	helpPanel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	helpPanel.BorderSizePixel = 0
	helpPanel.Visible = false
	helpPanel.Parent = self.gui
	
	local helpCorner = Instance.new("UICorner")
	helpCorner.CornerRadius = UDim.new(0, 12)
	helpCorner.Parent = helpPanel
	
	-- Titre du panneau
	local helpTitle = Instance.new("TextLabel")
	helpTitle.Name = "HelpTitle"
	helpTitle.Size = UDim2.new(1, 0, 0, 30)
	helpTitle.BackgroundTransparency = 0.3
	helpTitle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	helpTitle.BorderSizePixel = 0
	helpTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	helpTitle.TextSize = 16
	helpTitle.Font = Enum.Font.GothamBold
	helpTitle.Text = "🌾 Guide de culture"
	helpTitle.Parent = helpPanel
	
	local helpTitleCorner = Instance.new("UICorner")
	helpTitleCorner.CornerRadius = UDim.new(0, 12)
	helpTitleCorner.Parent = helpTitle
	
	-- Informations d'aide
	local helpText = Instance.new("TextLabel")
	helpText.Name = "HelpText"
	helpText.Size = UDim2.new(1, -20, 1, -40)
	helpText.Position = UDim2.new(0, 10, 0, 35)
	helpText.BackgroundTransparency = 1
	helpText.TextColor3 = Color3.fromRGB(220, 220, 220)
	helpText.TextSize = 13
	helpText.Font = Enum.Font.Gotham
	helpText.Text = "• Plantez des graines\n• Arrosez pour +10% croissance\n• Récoltez au stade 5\n• Surveillez vos cultures"
	helpText.TextWrapped = true
	helpText.TextXAlignment = Enum.TextXAlignment.Left
	helpText.TextYAlignment = Enum.TextYAlignment.Top
	helpText.Parent = helpPanel
	
	-- === INDICATEUR DE PROXIMITÉ ===
	-- Cet indicateur apparaît quand le joueur est proche d'une culture
	local proximityIndicator = Instance.new("Frame")
	proximityIndicator.Name = "ProximityIndicator"
	proximityIndicator.Size = UDim2.new(0, 300, 0, 100)
	proximityIndicator.Position = UDim2.new(0.5, -150, 0.5, -200)
	proximityIndicator.BackgroundTransparency = 0.15
	proximityIndicator.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	proximityIndicator.BorderSizePixel = 0
	proximityIndicator.Visible = false
	proximityIndicator.Parent = self.gui
	
	local proximityCorner = Instance.new("UICorner")
	proximityCorner.CornerRadius = UDim.new(0, 15)
	proximityCorner.Parent = proximityIndicator
	
	-- Icône de culture
	local cropIcon = Instance.new("TextLabel")
	cropIcon.Name = "CropIcon"
	cropIcon.Size = UDim2.new(0, 60, 0, 60)
	cropIcon.Position = UDim2.new(0, 10, 0.5, -30)
	cropIcon.BackgroundTransparency = 1
	cropIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
	cropIcon.TextSize = 40
	cropIcon.Font = Enum.Font.GothamBold
	cropIcon.Text = "🌱"
	cropIcon.Parent = proximityIndicator
	
	-- Nom de la culture
	local cropName = Instance.new("TextLabel")
	cropName.Name = "CropName"
	cropName.Size = UDim2.new(0, 220, 0, 25)
	cropName.Position = UDim2.new(0, 75, 0, 10)
	cropName.BackgroundTransparency = 1
	cropName.TextColor3 = Color3.fromRGB(255, 255, 255)
	cropName.TextSize = 16
	cropName.Font = Enum.Font.GothamBold
	cropName.Text = "Blé"
	cropName.TextXAlignment = Enum.TextXAlignment.Left
	cropName.Parent = proximityIndicator
	
	-- Stade de croissance
	local cropStage = Instance.new("TextLabel")
	cropStage.Name = "CropStage"
	cropStage.Size = UDim2.new(0, 220, 0, 20)
	cropStage.Position = UDim2.new(0, 75, 0, 35)
	cropStage.BackgroundTransparency = 1
	cropStage.TextColor3 = Color3.fromRGB(200, 200, 200)
	cropStage.TextSize = 13
	cropStage.Font = Enum.Font.Gotham
	cropStage.Text = "Stade: 1/5"
	cropStage.TextXAlignment = Enum.TextXAlignment.Left
	cropStage.Parent = proximityIndicator
	
	-- Barre de progression
	local progressContainer = Instance.new("Frame")
	progressContainer.Name = "ProgressContainer"
	progressContainer.Size = UDim2.new(0, 220, 0, 8)
	progressContainer.Position = UDim2.new(0, 75, 0, 60)
	progressContainer.BackgroundTransparency = 0.5
	progressContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	progressContainer.BorderSizePixel = 0
	progressContainer.Parent = proximityIndicator
	
	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 4)
	progressCorner.Parent = progressContainer
	
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0.5, 0, 1, -2)
	progressFill.Position = UDim2.new(0, 1, 0, 1)
	progressFill.BackgroundColor3 = Color3.fromRGB(100, 180, 100)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressContainer
	
	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0, 3)
	progressFillCorner.Parent = progressFill
	
	-- Temps restant
	local timeRemaining = Instance.new("TextLabel")
	timeRemaining.Name = "TimeRemaining"
	timeRemaining.Size = UDim2.new(0, 220, 0, 20)
	timeRemaining.Position = UDim2.new(0, 75, 0, 73)
	timeRemaining.BackgroundTransparency = 1
	timeRemaining.TextColor3 = Color3.fromRGB(180, 180, 180)
	timeRemaining.TextSize = 12
	timeRemaining.Font = Enum.Font.Gotham
	timeRemaining.Text = "Temps restant: 5m 30s"
	timeRemaining.TextXAlignment = Enum.TextXAlignment.Left
	timeRemaining.Parent = proximityIndicator
	
	-- === LISTE DES CULTURES ACTIVES ===
	local cropsListFrame = Instance.new("Frame")
	cropsListFrame.Name = "CropsListFrame"
	cropsListFrame.Size = UDim2.new(0, 280, 0, 250)
	cropsListFrame.Position = UDim2.new(1, -290, 0, 300)
	cropsListFrame.BackgroundTransparency = 0.2
	cropsListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	cropsListFrame.BorderSizePixel = 0
	cropsListFrame.Visible = false
	cropsListFrame.Parent = self.gui
	
	local cropsListCorner = Instance.new("UICorner")
	cropsListCorner.CornerRadius = UDim.new(0, 12)
	cropsListCorner.Parent = cropsListFrame
	
	-- Titre de la liste
	local cropsListTitle = Instance.new("TextLabel")
	cropsListTitle.Name = "CropsListTitle"
	cropsListTitle.Size = UDim2.new(1, 0, 0, 35)
	cropsListTitle.BackgroundTransparency = 0.3
	cropsListTitle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	cropsListTitle.BorderSizePixel = 0
	cropsListTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	cropsListTitle.TextSize = 16
	cropsListTitle.Font = Enum.Font.GothamBold
	cropsListTitle.Text = "📋 Mes Cultures (0)"
	cropsListTitle.Parent = cropsListFrame
	
	local cropsListTitleCorner = Instance.new("UICorner")
	cropsListTitleCorner.CornerRadius = UDim.new(0, 12)
	cropsListTitleCorner.Parent = cropsListTitle
	
	-- Bouton pour toggle la liste
	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(0, 25, 0, 25)
	toggleButton.Position = UDim2.new(1, -30, 0, 5)
	toggleButton.BackgroundTransparency = 0.4
	toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	toggleButton.BorderSizePixel = 0
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextSize = 14
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.Text = "−"
	toggleButton.Parent = cropsListTitle
	
	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 6)
	toggleCorner.Parent = toggleButton
	
	-- ScrollingFrame pour la liste
	local cropsScrollFrame = Instance.new("ScrollingFrame")
	cropsScrollFrame.Name = "CropsScrollFrame"
	cropsScrollFrame.Size = UDim2.new(1, -10, 1, -45)
	cropsScrollFrame.Position = UDim2.new(0, 5, 0, 40)
	cropsScrollFrame.BackgroundTransparency = 1
	cropsScrollFrame.BorderSizePixel = 0
	cropsScrollFrame.ScrollBarThickness = 4
	cropsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	cropsScrollFrame.Parent = cropsListFrame
	
	-- Stocker les références
	self.helpPanel = helpPanel
	self.proximityIndicator = proximityIndicator
	self.proximityCropIcon = cropIcon
	self.proximityCropName = cropName
	self.proximityCropStage = cropStage
	self.proximityProgressFill = progressFill
	self.proximityTimeRemaining = timeRemaining
	self.cropsListFrame = cropsListFrame
	self.cropsListTitle = cropsListTitle
	self.cropsScrollFrame = cropsScrollFrame
	self.toggleButton = toggleButton
	
	-- Ajouter l'interface au joueur
	self.gui.Parent = self.player.PlayerGui
	
	-- Connecter aux événements
	self:ConnectToEvents()
	
	-- Connecter le bouton toggle
	toggleButton.MouseButton1Click:Connect(function()
		self:ToggleCropsList()
	end)
	
	-- Afficher le panneau d'aide au début
	self:ShowHelpPanel()
	delay(5, function()
		self:HideHelpPanel()
	end)
	
	return self
end

-- Connecter aux événements du serveur
function FarmingUI:ConnectToEvents()
	local events = ReplicatedStorage:FindFirstChild("Events")
	
	if events then
		-- Mise à jour d'une culture
		local updateCropEvent = events:FindFirstChild("UpdateCrop")
		if updateCropEvent then
			updateCropEvent.OnClientEvent:Connect(function(cropData)
				self:UpdateCrop(cropData)
			end)
		end
	end
end

-- Afficher le panneau d'aide
function FarmingUI:ShowHelpPanel()
	self.helpPanel.Visible = true
	
	-- Animation d'entrée
	self.helpPanel.Position = UDim2.new(1, 0, 0, 150)
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local goal = {Position = UDim2.new(1, -260, 0, 150)}
	local tween = TweenService:Create(self.helpPanel, tweenInfo, goal)
	tween:Play()
end

-- Masquer le panneau d'aide
function FarmingUI:HideHelpPanel()
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local goal = {Position = UDim2.new(1, 0, 0, 150)}
	local tween = TweenService:Create(self.helpPanel, tweenInfo, goal)
	
	tween.Completed:Connect(function()
		self.helpPanel.Visible = false
	end)
	
	tween:Play()
end

-- Afficher l'indicateur de proximité
function FarmingUI:ShowProximityIndicator(cropData)
	-- Mettre à jour les informations
	local itemType = ItemTypes[cropData.cropType]
	local cropName = itemType and itemType.name or "Culture"
	
	self.proximityCropName.Text = cropName
	self.proximityCropStage.Text = GROWTH_STAGE_NAMES[cropData.stage] or ("Stade " .. cropData.stage .. "/5")
	self.proximityCropIcon.Text = self:GetCropEmoji(cropData.cropType, cropData.stage)
	
	-- Mettre à jour la barre de progression
	local stageProgress = (cropData.stage - 1) / 4
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {Size = UDim2.new(stageProgress, -2, 1, -2)}
	local tween = TweenService:Create(self.proximityProgressFill, tweenInfo, goal)
	tween:Play()
	
	-- Couleur de la barre selon le stade
	self.proximityProgressFill.BackgroundColor3 = GROWTH_STAGE_COLORS[cropData.stage] or Color3.fromRGB(100, 180, 100)
	
	-- Temps restant
	local timeRemaining = cropData.timeUntilNextStage or 0
	self.proximityTimeRemaining.Text = self:FormatTime(timeRemaining)
	
	-- Afficher l'indicateur
	if not self.proximityIndicator.Visible then
		self.proximityIndicator.Visible = true
		
		-- Animation d'entrée
		self.proximityIndicator.Position = UDim2.new(0.5, -150, 0.5, -250)
		local entryTween = TweenService:Create(self.proximityIndicator, tweenInfo, 
			{Position = UDim2.new(0.5, -150, 0.5, -200)})
		entryTween:Play()
	end
end

-- Masquer l'indicateur de proximité
function FarmingUI:HideProximityIndicator()
	if self.proximityIndicator.Visible then
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local goal = {Position = UDim2.new(0.5, -150, 0.5, -250)}
		local tween = TweenService:Create(self.proximityIndicator, tweenInfo, goal)
		
		tween.Completed:Connect(function()
			self.proximityIndicator.Visible = false
		end)
		
		tween:Play()
	end
end

-- Mettre à jour une culture
function FarmingUI:UpdateCrop(cropData)
	-- Ajouter ou mettre à jour dans la liste
	self.trackedCrops[cropData.id] = cropData
	
	-- Mettre à jour la liste des cultures
	self:UpdateCropsList()
end

-- Retirer une culture (récoltée ou détruite)
function FarmingUI:RemoveCrop(cropId)
	self.trackedCrops[cropId] = nil
	self:UpdateCropsList()
end

-- Mettre à jour la liste des cultures
function FarmingUI:UpdateCropsList()
	-- Effacer la liste existante
	for _, indicator in pairs(self.cropIndicators) do
		indicator:Destroy()
	end
	self.cropIndicators = {}
	
	-- Compter les cultures
	local cropCount = 0
	for _ in pairs(self.trackedCrops) do
		cropCount = cropCount + 1
	end
	
	-- Mettre à jour le titre
	self.cropsListTitle.Text = string.format("📋 Mes Cultures (%d)", cropCount)
	
	-- Si aucune culture, masquer la liste
	if cropCount == 0 then
		self.cropsListFrame.Visible = false
		return
	end
	
	-- Afficher la liste
	self.cropsListFrame.Visible = true
	
	-- Créer les indicateurs
	local yOffset = 5
	for cropId, cropData in pairs(self.trackedCrops) do
		local indicator = self:CreateCropIndicator(cropData)
		indicator.Position = UDim2.new(0, 5, 0, yOffset)
		indicator.Parent = self.cropsScrollFrame
		
		self.cropIndicators[cropId] = indicator
		yOffset = yOffset + 65
	end
	
	-- Mettre à jour la taille du canvas
	self.cropsScrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
end

-- Créer un indicateur de culture pour la liste
function FarmingUI:CreateCropIndicator(cropData)
	local indicator = Instance.new("Frame")
	indicator.Name = "CropIndicator_" .. cropData.id
	indicator.Size = UDim2.new(1, -10, 0, 60)
	indicator.BackgroundTransparency = 0.3
	indicator.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
	indicator.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = indicator
	
	-- Icône
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 45, 0, 45)
	icon.Position = UDim2.new(0, 8, 0.5, -22.5)
	icon.BackgroundTransparency = 1
	icon.TextColor3 = Color3.fromRGB(255, 255, 255)
	icon.TextSize = 30
	icon.Font = Enum.Font.GothamBold
	icon.Text = self:GetCropEmoji(cropData.cropType, cropData.stage)
	icon.Parent = indicator
	
	-- Nom et stade
	local itemType = ItemTypes[cropData.cropType]
	local cropName = itemType and itemType.name or "Culture"
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0, 200, 0, 18)
	nameLabel.Position = UDim2.new(0, 60, 0, 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = cropName
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = indicator
	
	local stageLabel = Instance.new("TextLabel")
	stageLabel.Name = "StageLabel"
	stageLabel.Size = UDim2.new(0, 200, 0, 15)
	stageLabel.Position = UDim2.new(0, 60, 0, 23)
	stageLabel.BackgroundTransparency = 1
	stageLabel.TextColor3 = GROWTH_STAGE_COLORS[cropData.stage] or Color3.fromRGB(200, 200, 200)
	stageLabel.TextSize = 12
	stageLabel.Font = Enum.Font.Gotham
	stageLabel.Text = GROWTH_STAGE_NAMES[cropData.stage] or ("Stade " .. cropData.stage)
	stageLabel.TextXAlignment = Enum.TextXAlignment.Left
	stageLabel.Parent = indicator
	
	-- Barre de progression
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(0, 200, 0, 6)
	progressBg.Position = UDim2.new(0, 60, 0, 42)
	progressBg.BackgroundTransparency = 0.5
	progressBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	progressBg.BorderSizePixel = 0
	progressBg.Parent = indicator
	
	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 3)
	progressCorner.Parent = progressBg
	
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new((cropData.stage - 1) / 4, 0, 1, -2)
	progressFill.Position = UDim2.new(0, 1, 0, 1)
	progressFill.BackgroundColor3 = GROWTH_STAGE_COLORS[cropData.stage] or Color3.fromRGB(100, 180, 100)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg
	
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 2)
	fillCorner.Parent = progressFill
	
	-- Temps restant
	local timeRemaining = cropData.timeUntilNextStage or 0
	local timeLabel = Instance.new("TextLabel")
	timeLabel.Name = "TimeLabel"
	timeLabel.Size = UDim2.new(0, 200, 0, 12)
	timeLabel.Position = UDim2.new(0, 60, 0, 50)
	timeLabel.BackgroundTransparency = 1
	timeLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	timeLabel.TextSize = 10
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.Text = cropData.stage >= 5 and "✨ Prêt à récolter!" or self:FormatTime(timeRemaining)
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.Parent = indicator
	
	return indicator
end

-- Toggle la liste des cultures
function FarmingUI:ToggleCropsList()
	local isExpanded = self.cropsScrollFrame.Visible
	
	if isExpanded then
		-- Réduire
		self.cropsScrollFrame.Visible = false
		self.cropsListFrame.Size = UDim2.new(0, 280, 0, 40)
		self.toggleButton.Text = "+"
	else
		-- Agrandir
		self.cropsScrollFrame.Visible = true
		self.cropsListFrame.Size = UDim2.new(0, 280, 0, 250)
		self.toggleButton.Text = "−"
	end
end

-- Obtenir l'emoji correspondant à une culture et son stade
function FarmingUI:GetCropEmoji(cropType, stage)
	if stage >= 5 then
		return "✨"
	elseif stage >= 4 then
		return "🌾"
	elseif stage >= 3 then
		return "🍃"
	elseif stage >= 2 then
		return "🌿"
	else
		return "🌱"
	end
end

-- Formater le temps en minutes et secondes
function FarmingUI:FormatTime(seconds)
	if seconds <= 0 then
		return "Prêt!"
	end
	
	local minutes = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	
	if minutes > 0 then
		return string.format("%dm %ds", minutes, secs)
	else
		return string.format("%ds", secs)
	end
end

return FarmingUI
