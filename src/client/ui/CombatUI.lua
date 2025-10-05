-- src/client/ui/CombatUI.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local CombatUI = {}
CombatUI.__index = CombatUI

function CombatUI.new()
	local self = setmetatable({}, CombatUI)
	
	-- Référence au joueur local
	self.player = Players.LocalPlayer
	
	-- Données de combat
	self.combatData = {
		currentHealth = 100,
		maxHealth = 100,
		armor = 0,
		isInCombat = false
	}
	
	-- Interface ScreenGui
	self.gui = nil
	
	-- Cooldown d'attaque
	self.lastAttackTime = 0
	self.attackCooldown = 0.5
	
	-- Animation
	self.damageFlashActive = false
	
	return self
end

function CombatUI:Initialize()
	-- Créer l'interface ScreenGui
	self.gui = Instance.new("ScreenGui")
	self.gui.Name = "CombatUI"
	self.gui.ResetOnSpawn = false
	self.gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	-- === BARRE DE VIE PRINCIPALE ===
	local healthBarFrame = Instance.new("Frame")
	healthBarFrame.Name = "HealthBarFrame"
	healthBarFrame.Size = UDim2.new(0, 350, 0, 50)
	healthBarFrame.Position = UDim2.new(0.5, -175, 1, -70)
	healthBarFrame.BackgroundTransparency = 0.3
	healthBarFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	healthBarFrame.BorderSizePixel = 0
	healthBarFrame.Parent = self.gui
	
	-- Arrondir les coins
	local healthCorner = Instance.new("UICorner")
	healthCorner.CornerRadius = UDim.new(0, 12)
	healthCorner.Parent = healthBarFrame
	
	-- Effet de brillance subtil
	local healthGradient = Instance.new("UIGradient")
	healthGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 35)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 25, 25)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 35, 35))
	})
	healthGradient.Rotation = 90
	healthGradient.Parent = healthBarFrame
	
	-- Conteneur pour la barre de vie
	local healthContainer = Instance.new("Frame")
	healthContainer.Name = "HealthContainer"
	healthContainer.Size = UDim2.new(1, -20, 0, 18)
	healthContainer.Position = UDim2.new(0, 10, 0, 8)
	healthContainer.BackgroundTransparency = 0.6
	healthContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	healthContainer.BorderSizePixel = 0
	healthContainer.Parent = healthBarFrame
	
	local healthContainerCorner = Instance.new("UICorner")
	healthContainerCorner.CornerRadius = UDim.new(0, 8)
	healthContainerCorner.Parent = healthContainer
	
	-- Barre de vie (remplissage)
	local healthFill = Instance.new("Frame")
	healthFill.Name = "HealthFill"
	healthFill.Size = UDim2.new(1, -4, 1, -4)
	healthFill.Position = UDim2.new(0, 2, 0, 2)
	healthFill.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	healthFill.BorderSizePixel = 0
	healthFill.Parent = healthContainer
	
	local healthFillCorner = Instance.new("UICorner")
	healthFillCorner.CornerRadius = UDim.new(0, 6)
	healthFillCorner.Parent = healthFill
	
	-- Gradient pour effet de profondeur
	local healthFillGradient = Instance.new("UIGradient")
	healthFillGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 70, 70)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 50, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 40, 40))
	})
	healthFillGradient.Rotation = 90
	healthFillGradient.Parent = healthFill
	
	-- Texte de santé
	local healthText = Instance.new("TextLabel")
	healthText.Name = "HealthText"
	healthText.Size = UDim2.new(1, 0, 1, 0)
	healthText.BackgroundTransparency = 1
	healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
	healthText.TextSize = 14
	healthText.Font = Enum.Font.GothamBold
	healthText.Text = "100 / 100"
	healthText.TextStrokeTransparency = 0.5
	healthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	healthText.ZIndex = 2
	healthText.Parent = healthContainer
	
	-- Icône de cœur
	local heartIcon = Instance.new("ImageLabel")
	heartIcon.Name = "HeartIcon"
	heartIcon.Size = UDim2.new(0, 24, 0, 24)
	heartIcon.Position = UDim2.new(0, -32, 0, -3)
	heartIcon.BackgroundTransparency = 1
	heartIcon.Image = "rbxassetid://6031068420" -- Icône de cœur
	heartIcon.ImageColor3 = Color3.fromRGB(220, 50, 50)
	heartIcon.Parent = healthContainer
	
	-- === BARRE D'ARMURE ===
	local armorContainer = Instance.new("Frame")
	armorContainer.Name = "ArmorContainer"
	armorContainer.Size = UDim2.new(1, -20, 0, 14)
	armorContainer.Position = UDim2.new(0, 10, 0, 30)
	armorContainer.BackgroundTransparency = 0.6
	armorContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	armorContainer.BorderSizePixel = 0
	armorContainer.Parent = healthBarFrame
	
	local armorContainerCorner = Instance.new("UICorner")
	armorContainerCorner.CornerRadius = UDim.new(0, 7)
	armorContainerCorner.Parent = armorContainer
	
	-- Barre d'armure (remplissage)
	local armorFill = Instance.new("Frame")
	armorFill.Name = "ArmorFill"
	armorFill.Size = UDim2.new(0, 0, 1, -4)
	armorFill.Position = UDim2.new(0, 2, 0, 2)
	armorFill.BackgroundColor3 = Color3.fromRGB(150, 180, 220)
	armorFill.BorderSizePixel = 0
	armorFill.Parent = armorContainer
	
	local armorFillCorner = Instance.new("UICorner")
	armorFillCorner.CornerRadius = UDim.new(0, 5)
	armorFillCorner.Parent = armorFill
	
	-- Gradient pour l'armure
	local armorFillGradient = Instance.new("UIGradient")
	armorFillGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 200, 230)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 180, 220)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 150, 200))
	})
	armorFillGradient.Rotation = 90
	armorFillGradient.Parent = armorFill
	
	-- Texte d'armure
	local armorText = Instance.new("TextLabel")
	armorText.Name = "ArmorText"
	armorText.Size = UDim2.new(1, 0, 1, 0)
	armorText.BackgroundTransparency = 1
	armorText.TextColor3 = Color3.fromRGB(255, 255, 255)
	armorText.TextSize = 12
	armorText.Font = Enum.Font.GothamBold
	armorText.Text = "Armure: 0"
	armorText.TextStrokeTransparency = 0.5
	armorText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	armorText.ZIndex = 2
	armorText.Parent = armorContainer
	
	-- Icône de bouclier
	local shieldIcon = Instance.new("ImageLabel")
	shieldIcon.Name = "ShieldIcon"
	shieldIcon.Size = UDim2.new(0, 20, 0, 20)
	shieldIcon.Position = UDim2.new(0, -28, 0, -3)
	shieldIcon.BackgroundTransparency = 1
	shieldIcon.Image = "rbxassetid://6031071053" -- Icône de bouclier
	shieldIcon.ImageColor3 = Color3.fromRGB(150, 180, 220)
	shieldIcon.Parent = armorContainer
	
	-- === INDICATEUR DE COMBAT ===
	local combatIndicator = Instance.new("Frame")
	combatIndicator.Name = "CombatIndicator"
	combatIndicator.Size = UDim2.new(0, 200, 0, 35)
	combatIndicator.Position = UDim2.new(0.5, -100, 0, 70)
	combatIndicator.BackgroundTransparency = 0.2
	combatIndicator.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	combatIndicator.BorderSizePixel = 0
	combatIndicator.Visible = false
	combatIndicator.Parent = self.gui
	
	local combatCorner = Instance.new("UICorner")
	combatCorner.CornerRadius = UDim.new(0, 10)
	combatCorner.Parent = combatIndicator
	
	-- Effet pulsant
	local combatGradient = Instance.new("UIGradient")
	combatGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(220, 70, 70)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 50, 50)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 70, 70))
	})
	combatGradient.Rotation = 0
	combatGradient.Parent = combatIndicator
	
	-- Texte de combat
	local combatText = Instance.new("TextLabel")
	combatText.Name = "CombatText"
	combatText.Size = UDim2.new(1, 0, 1, 0)
	combatText.BackgroundTransparency = 1
	combatText.TextColor3 = Color3.fromRGB(255, 255, 255)
	combatText.TextSize = 18
	combatText.Font = Enum.Font.GothamBold
	combatText.Text = "⚔️ EN COMBAT"
	combatText.TextStrokeTransparency = 0.3
	combatText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	combatText.Parent = combatIndicator
	
	-- === INDICATEUR DE COOLDOWN ===
	local cooldownIndicator = Instance.new("Frame")
	cooldownIndicator.Name = "CooldownIndicator"
	cooldownIndicator.Size = UDim2.new(0, 60, 0, 60)
	cooldownIndicator.Position = UDim2.new(0.5, 200, 1, -130)
	cooldownIndicator.BackgroundTransparency = 0.4
	cooldownIndicator.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	cooldownIndicator.BorderSizePixel = 0
	cooldownIndicator.Visible = false
	cooldownIndicator.Parent = self.gui
	
	local cooldownCorner = Instance.new("UICorner")
	cooldownCorner.CornerRadius = UDim.new(1, 0) -- Circulaire
	cooldownCorner.Parent = cooldownIndicator
	
	-- Overlay de cooldown
	local cooldownOverlay = Instance.new("Frame")
	cooldownOverlay.Name = "CooldownOverlay"
	cooldownOverlay.Size = UDim2.new(1, 0, 1, 0)
	cooldownOverlay.BackgroundTransparency = 0.3
	cooldownOverlay.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	cooldownOverlay.BorderSizePixel = 0
	cooldownOverlay.Parent = cooldownIndicator
	
	local cooldownOverlayCorner = Instance.new("UICorner")
	cooldownOverlayCorner.CornerRadius = UDim.new(1, 0)
	cooldownOverlayCorner.Parent = cooldownOverlay
	
	-- Texte de cooldown
	local cooldownText = Instance.new("TextLabel")
	cooldownText.Name = "CooldownText"
	cooldownText.Size = UDim2.new(1, 0, 1, 0)
	cooldownText.BackgroundTransparency = 1
	cooldownText.TextColor3 = Color3.fromRGB(255, 255, 255)
	cooldownText.TextSize = 20
	cooldownText.Font = Enum.Font.GothamBold
	cooldownText.Text = "0.5"
	cooldownText.TextStrokeTransparency = 0.5
	cooldownText.ZIndex = 2
	cooldownText.Parent = cooldownIndicator
	
	-- Stocker les références
	self.healthFill = healthFill
	self.healthText = healthText
	self.armorFill = armorFill
	self.armorText = armorText
	self.combatIndicator = combatIndicator
	self.cooldownIndicator = cooldownIndicator
	self.cooldownOverlay = cooldownOverlay
	self.cooldownText = cooldownText
	self.healthBarFrame = healthBarFrame
	
	-- Ajouter l'interface au joueur
	self.gui.Parent = self.player.PlayerGui
	
	-- Connecter aux événements
	self:ConnectToEvents()
	
	-- Animation de pulsation pour l'indicateur de combat
	self:StartCombatPulseAnimation()
	
	-- Mettre à jour le cooldown en continu
	RunService.RenderStepped:Connect(function()
		self:UpdateCooldownDisplay()
	end)
	
	return self
end

-- Connecter aux événements du serveur
function CombatUI:ConnectToEvents()
	local events = ReplicatedStorage:FindFirstChild("Events")
	
	if events then
		-- Mise à jour de la santé
		local updateHealthEvent = events:FindFirstChild("UpdateHealth")
		if updateHealthEvent then
			updateHealthEvent.OnClientEvent:Connect(function(healthData)
				self:UpdateCombatData(healthData)
			end)
		end
		
		-- Réception de dégâts
		local takeDamageEvent = events:FindFirstChild("TakeDamage")
		if takeDamageEvent then
			takeDamageEvent.OnClientEvent:Connect(function(damage, damageType, attackerName)
				self:ShowDamageFlash(damage)
			end)
		end
	end
end

-- Mettre à jour les données de combat
function CombatUI:UpdateCombatData(data)
	self.combatData.currentHealth = data.currentHealth or self.combatData.currentHealth
	self.combatData.maxHealth = data.maxHealth or self.combatData.maxHealth
	self.combatData.armor = data.armor or 0
	self.combatData.isInCombat = data.isInCombat or false
	
	-- Mettre à jour les barres
	self:UpdateHealthBar()
	self:UpdateArmorBar()
	self:UpdateCombatStatus()
end

-- Mettre à jour la barre de vie
function CombatUI:UpdateHealthBar()
	local healthPercent = self.combatData.currentHealth / self.combatData.maxHealth
	
	-- Animer la barre
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {Size = UDim2.new(healthPercent, -4, 1, -4)}
	local tween = TweenService:Create(self.healthFill, tweenInfo, goal)
	tween:Play()
	
	-- Mettre à jour le texte
	self.healthText.Text = string.format("%d / %d", 
		math.floor(self.combatData.currentHealth), 
		math.floor(self.combatData.maxHealth))
	
	-- Changer la couleur selon le niveau de vie
	local color
	if healthPercent > 0.6 then
		color = Color3.fromRGB(220, 50, 50) -- Rouge normal
	elseif healthPercent > 0.3 then
		color = Color3.fromRGB(220, 120, 50) -- Orange
	else
		color = Color3.fromRGB(180, 40, 40) -- Rouge foncé
	end
	
	local colorTween = TweenService:Create(self.healthFill, tweenInfo, {BackgroundColor3 = color})
	colorTween:Play()
end

-- Mettre à jour la barre d'armure
function CombatUI:UpdateArmorBar()
	local armor = self.combatData.armor
	local maxArmor = 100 -- Valeur max d'armure pour l'affichage
	local armorPercent = math.min(armor / maxArmor, 1)
	
	-- Animer la barre
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {Size = UDim2.new(armorPercent, -4, 1, -4)}
	local tween = TweenService:Create(self.armorFill, tweenInfo, goal)
	tween:Play()
	
	-- Mettre à jour le texte
	self.armorText.Text = string.format("Armure: %d", armor)
end

-- Mettre à jour le statut de combat
function CombatUI:UpdateCombatStatus()
	self.combatIndicator.Visible = self.combatData.isInCombat
end

-- Afficher un flash de dégâts
function CombatUI:ShowDamageFlash(damage)
	if self.damageFlashActive then return end
	
	self.damageFlashActive = true
	
	-- Flash rouge sur la barre de vie
	local originalTransparency = self.healthBarFrame.BackgroundTransparency
	
	local tweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
	local goal = {BackgroundTransparency = 0}
	local tween = TweenService:Create(self.healthBarFrame, tweenInfo, goal)
	
	tween.Completed:Connect(function()
		self.damageFlashActive = false
	end)
	
	tween:Play()
end

-- Animation de pulsation pour l'indicateur de combat
function CombatUI:StartCombatPulseAnimation()
	local indicator = self.combatIndicator
	
	spawn(function()
		while true do
			if indicator and indicator.Visible then
				local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
				local goal = {BackgroundTransparency = 0.4}
				local tween = TweenService:Create(indicator, tweenInfo, goal)
				tween:Play()
			end
			wait(1)
		end
	end)
end

-- Enregistrer une attaque
function CombatUI:RegisterAttack()
	self.lastAttackTime = tick()
	self.cooldownIndicator.Visible = true
end

-- Mettre à jour l'affichage du cooldown
function CombatUI:UpdateCooldownDisplay()
	local currentTime = tick()
	local timeSinceAttack = currentTime - self.lastAttackTime
	local cooldownRemaining = math.max(0, self.attackCooldown - timeSinceAttack)
	
	if cooldownRemaining > 0 then
		self.cooldownIndicator.Visible = true
		self.cooldownText.Text = string.format("%.1f", cooldownRemaining)
		
		-- Mettre à jour l'overlay visuel
		local cooldownPercent = cooldownRemaining / self.attackCooldown
		self.cooldownOverlay.Size = UDim2.new(1, 0, cooldownPercent, 0)
	else
		self.cooldownIndicator.Visible = false
	end
end

-- Obtenir les données de combat actuelles
function CombatUI:GetCombatData()
	return self.combatData
end

return CombatUI
