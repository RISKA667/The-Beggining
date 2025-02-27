-- src/client/ui/TribeUI.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local TribeUI = {}
TribeUI.__index = TribeUI

-- Définir les rôles dans une tribu
local TRIBE_ROLES = {
    LEADER = "leader",      -- Fondateur, peut tout faire
    ELDER = "elder",        -- Peut ajouter/retirer des membres, construire
    MEMBER = "member",      -- Peut construire dans le territoire
    NOVICE = "novice"       -- Nouveau membre, accès limité
}

local ROLE_NAMES = {
    [TRIBE_ROLES.LEADER] = "Chef",
    [TRIBE_ROLES.ELDER] = "Ancien",
    [TRIBE_ROLES.MEMBER] = "Membre",
    [TRIBE_ROLES.NOVICE] = "Novice"
}

local ROLE_COLORS = {
    [TRIBE_ROLES.LEADER] = Color3.fromRGB(255, 215, 0),    -- Or
    [TRIBE_ROLES.ELDER] = Color3.fromRGB(180, 180, 180),   -- Argent
    [TRIBE_ROLES.MEMBER] = Color3.fromRGB(100, 200, 100),  -- Vert
    [TRIBE_ROLES.NOVICE] = Color3.fromRGB(150, 150, 255)   -- Bleu
}

function TribeUI.new()
    local self = setmetatable({}, TribeUI)
    
    -- Référence au joueur local
    self.player = Players.LocalPlayer
    
    -- Interface ScreenGui
    self.gui = nil
    
    -- État de l'interface
    self.isOpen = false
    
    -- Données de la tribu
    self.tribeInfo = nil
    self.tribeDetails = nil
    self.invitations = {}
    
    -- Onglet actif
    self.activeTab = "info"  -- "info", "members", "territory", "log"
    
    -- Callbacks externes
    self.callbacks = {
        onCreateTribe = nil,
        onJoinTribe = nil,
        onLeaveTribe = nil,
        onInvitePlayer = nil,
        onKickMember = nil,
        onPromoteMember = nil,
        onDemoteMember = nil,
        onSetDescription = nil,
        onSetTerritory = nil
    }
    
    return self
end

function TribeUI:Initialize()
    -- Créer l'interface ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "TribeUI"
    self.gui.ResetOnSpawn = false
    self.gui.Enabled = false
    
    -- Cadre principal
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MainFrame"
    self.mainFrame.Size = UDim2.new(0, 700, 0, 500)
    self.mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
    self.mainFrame.BackgroundTransparency = 0.2
    self.mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Parent = self.gui
    
    -- Arrondir les coins
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = self.mainFrame
    
    -- Titre de l'interface
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundTransparency = 0.5
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = self.mainFrame
    
    -- Arrondir les coins du titre
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    -- Titre
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -100, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 20
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = "Gestion de Tribu"
    titleLabel.Parent = titleBar
    
    -- Bouton de fermeture
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.Position = UDim2.new(1, -35, 0, 5)
    closeButton.BackgroundTransparency = 0.5
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.Text = "X"
    closeButton.Parent = titleBar
    
    -- Arrondir les coins du bouton
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeButton
    
    -- Créer le contenu principal qui change selon que le joueur est dans une tribu ou non
    self.contentFrame = Instance.new("Frame")
    self.contentFrame.Name = "ContentFrame"
    self.contentFrame.Size = UDim2.new(1, -20, 1, -50)
    self.contentFrame.Position = UDim2.new(0, 10, 0, 45)
    self.contentFrame.BackgroundTransparency = 1
    self.contentFrame.Parent = self.mainFrame
    
    -- Créer les différentes vues
    self:CreateNoTribeView()
    self:CreateTribeView()
    self:CreateInvitationView()
    
    -- Ajouter à l'interface du joueur
    self.gui.Parent = self.player.PlayerGui
    
    -- Connecter les événements
    closeButton.MouseButton1Click:Connect(function()
        self:ToggleTribeUI(false)
    end)
    
    -- Connecter à la touche T pour ouvrir/fermer l'interface
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.T then
            self:ToggleTribeUI(not self.isOpen)
        end
    end)
    
    -- Connecter aux événements de tribu
    self:ConnectToTribeEvents()
    
    return self
end

-- Connecter aux événements de tribu venant du serveur
function TribeUI:ConnectToTribeEvents()
    local events = ReplicatedStorage:FindFirstChild("Events")
    
    if events then
        local tribeUpdateEvent = events:FindFirstChild("TribeUpdate")
        if tribeUpdateEvent then
            tribeUpdateEvent.OnClientEvent:Connect(function(updateType, updateData)
                self:HandleTribeUpdate(updateType, updateData)
            end)
        end
    end
end

-- Gérer les mises à jour de tribu venant du serveur
function TribeUI:HandleTribeUpdate(updateType, updateData)
    if updateType == "player_tribe_update" then
        -- Mise à jour des informations de base de la tribu
        self.tribeInfo = updateData
        self:UpdateView()
    elseif updateType == "tribe_details_update" then
        -- Mise à jour détaillée de la tribu
        self.tribeDetails = updateData
        self:UpdateTribeDetails()
    elseif updateType == "invitation" then
        -- Nouvelle invitation à une tribu
        table.insert(self.invitations, updateData)
        self:ShowInvitationNotification(updateData)
        self:UpdateView()
    elseif updateType == "action_response" then
        -- Réponse à une action de tribu
        self:HandleActionResponse(updateData)
    end
end

-- Gérer les réponses aux actions de tribu
function TribeUI:HandleActionResponse(response)
    -- Afficher un message selon le résultat
    if response.success then
        self:ShowNotification(response.message, "success")
    else
        self:ShowNotification(response.message, "error")
    end
    
    -- Actions spécifiques selon la réponse
    if response.action == "create_tribe" and response.success then
        -- Actualiser après création de tribu
        if response.data and response.data.tribeId then
            -- La mise à jour viendra du serveur
        end
    elseif response.action == "join_tribe" and response.success then
        -- Actualiser après avoir rejoint une tribu
        self:ToggleTribeUI(true)
    elseif response.action == "leave_tribe" and response.success then
        -- Actualiser après avoir quitté une tribu
        self.tribeInfo = nil
        self.tribeDetails = nil
        self:UpdateView()
    elseif response.action == "kicked_from_tribe" then
        -- Le joueur a été expulsé de sa tribu
        self.tribeInfo = nil
        self.tribeDetails = nil
        self:UpdateView()
    elseif response.action == "tribe_dissolved" then
        -- La tribu a été dissoute
        self.tribeInfo = nil
        self.tribeDetails = nil
        self:UpdateView()
    end
end

-- Mettre à jour la vue active selon l'état du joueur
function TribeUI:UpdateView()
    -- Nettoyer le contenu
    self.contentFrame:ClearAllChildren()
    
    if self.tribeInfo then
        -- Afficher la vue de tribu
        self.noTribeView.Visible = false
        self.tribeView.Visible = true
        self.invitationView.Visible = false
        self.tribeView.Parent = self.contentFrame
        
        -- Mettre à jour les informations de la tribu
        self:UpdateTribeInfo()
    elseif #self.invitations > 0 then
        -- Afficher la vue d'invitation
        self.noTribeView.Visible = false
        self.tribeView.Visible = false
        self.invitationView.Visible = true
        self.invitationView.Parent = self.contentFrame
        
        -- Mettre à jour les invitations
        self:UpdateInvitationList()
    else
        -- Afficher la vue "pas de tribu"
        self.noTribeView.Visible = true
        self.tribeView.Visible = false
        self.invitationView.Visible = false
        self.noTribeView.Parent = self.contentFrame
    end
end

-- Créer la vue quand le joueur n'a pas de tribu
function TribeUI:CreateNoTribeView()
    self.noTribeView = Instance.new("Frame")
    self.noTribeView.Name = "NoTribeView"
    self.noTribeView.Size = UDim2.new(1, 0, 1, 0)
    self.noTribeView.BackgroundTransparency = 1
    self.noTribeView.Visible = false
    
    -- Message informatif
    local infoLabel = Instance.new("TextLabel")
    infoLabel.Name = "InfoLabel"
    infoLabel.Size = UDim2.new(1, 0, 0, 50)
    infoLabel.Position = UDim2.new(0, 0, 0, 50)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    infoLabel.TextSize = 18
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.Text = "Vous ne faites partie d'aucune tribu.\nCréez la vôtre ou rejoignez-en une existante !"
    infoLabel.Parent = self.noTribeView
    
    -- Cadre pour le formulaire de création
    local createFrame = Instance.new("Frame")
    createFrame.Name = "CreateFrame"
    createFrame.Size = UDim2.new(0, 400, 0, 200)
    createFrame.Position = UDim2.new(0.5, -200, 0, 120)
    createFrame.BackgroundTransparency = 0.7
    createFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    createFrame.BorderSizePixel = 0
    createFrame.Parent = self.noTribeView
    
    -- Titre du formulaire
    local createTitle = Instance.new("TextLabel")
    createTitle.Name = "CreateTitle"
    createTitle.Size = UDim2.new(1, 0, 0, 30)
    createTitle.BackgroundTransparency = 0.5
    createTitle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    createTitle.BorderSizePixel = 0
    createTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    createTitle.TextSize = 16
    createTitle.Font = Enum.Font.SourceSansBold
    createTitle.Text = "Créer une tribu"
    createTitle.Parent = createFrame
    
    -- Champ pour le nom de la tribu
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0, 100, 0, 30)
    nameLabel.Position = UDim2.new(0, 10, 0, 40)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.SourceSans
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Text = "Nom:"
    nameLabel.Parent = createFrame
    
    local nameInput = Instance.new("TextBox")
    nameInput.Name = "NameInput"
    nameInput.Size = UDim2.new(1, -120, 0, 30)
    nameInput.Position = UDim2.new(0, 110, 0, 40)
    nameInput.BackgroundTransparency = 0.5
    nameInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    nameInput.BorderSizePixel = 0
    nameInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameInput.TextSize = 16
    nameInput.Font = Enum.Font.SourceSans
    nameInput.PlaceholderText = "Entrez le nom de votre tribu"
    nameInput.Text = ""
    nameInput.ClearTextOnFocus = false
    nameInput.Parent = createFrame
    
    -- Champ pour la description de la tribu
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "DescLabel"
    descLabel.Size = UDim2.new(0, 100, 0, 30)
    descLabel.Position = UDim2.new(0, 10, 0, 80)
    descLabel.BackgroundTransparency = 1
    descLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    descLabel.TextSize = 16
    descLabel.Font = Enum.Font.SourceSans
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Text = "Description:"
    descLabel.Parent = createFrame
    
    local descInput = Instance.new("TextBox")
    descInput.Name = "DescInput"
    descInput.Size = UDim2.new(1, -120, 0, 60)
    descInput.Position = UDim2.new(0, 110, 0, 80)
    descInput.BackgroundTransparency = 0.5
    descInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    descInput.BorderSizePixel = 0
    descInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    descInput.TextSize = 16
    descInput.Font = Enum.Font.SourceSans
    descInput.TextXAlignment = Enum.TextXAlignment.Left
    descInput.TextYAlignment = Enum.TextYAlignment.Top
    descInput.PlaceholderText = "Décrivez votre tribu (optionnel)"
    descInput.Text = ""
    descInput.ClearTextOnFocus = false
    descInput.TextWrapped = true
    descInput.MultiLine = true
    descInput.Parent = createFrame
    
    -- Bouton pour créer la tribu
    local createButton = Instance.new("TextButton")
    createButton.Name = "CreateButton"
    createButton.Size = UDim2.new(0, 150, 0, 35)
    createButton.Position = UDim2.new(0.5, -75, 1, -45)
    createButton.BackgroundTransparency = 0.5
    createButton.BackgroundColor3 = Color3.fromRGB(0, 120, 0)
    createButton.BorderSizePixel = 0
    createButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    createButton.TextSize = 16
    createButton.Font = Enum.Font.SourceSansBold
    createButton.Text = "Créer la tribu"
    createButton.Parent = createFrame
    
    -- Arrondir les coins du bouton
    local createButtonCorner = Instance.new("UICorner")
    createButtonCorner.CornerRadius = UDim.new(0, 8)
    createButtonCorner.Parent = createButton
    
    -- Connecter le bouton
    createButton.MouseButton1Click:Connect(function()
        local tribeName = nameInput.Text
        local description = descInput.Text
        
        if tribeName and #tribeName >= 3 and #tribeName <= 20 then
            self:CreateTribe(tribeName, description)
        else
            self:ShowNotification("Le nom de la tribu doit comporter entre 3 et 20 caractères", "error")
        end
    end)
end

-- Créer la vue quand le joueur a une tribu
function TribeUI:CreateTribeView()
    self.tribeView = Instance.new("Frame")
    self.tribeView.Name = "TribeView"
    self.tribeView.Size = UDim2.new(1, 0, 1, 0)
    self.tribeView.BackgroundTransparency = 1
    self.tribeView.Visible = false
    
    -- Créer les onglets
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "TabsFrame"
    tabsFrame.Size = UDim2.new(1, 0, 0, 40)
    tabsFrame.BackgroundTransparency = 0.7
    tabsFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tabsFrame.BorderSizePixel = 0
    tabsFrame.Parent = self.tribeView
    
    -- Créer les boutons d'onglets
    local tabWidth = 150
    local tabPadding = 10
    local tabButtons = {}
    
    local tabs = {
        {id = "info", text = "Informations"},
        {id = "members", text = "Membres"},
        {id = "territory", text = "Territoire"},
        {id = "log", text = "Journal"}
    }
    
    for i, tab in ipairs(tabs) do
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tab.id .. "Tab"
        tabButton.Size = UDim2.new(0, tabWidth, 0, 35)
        tabButton.Position = UDim2.new(0, 10 + (i-1) * (tabWidth + tabPadding), 0, 2)
        tabButton.BackgroundTransparency = 0.5
        tabButton.BackgroundColor3 = tab.id == "info" and Color3.fromRGB(60, 60, 120) or Color3.fromRGB(60, 60, 60)
        tabButton.BorderSizePixel = 0
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.TextSize = 16
        tabButton.Font = Enum.Font.SourceSansBold
        tabButton.Text = tab.text
        tabButton.Parent = tabsFrame
        
        -- Arrondir les coins
        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 8)
        tabCorner.Parent = tabButton
        
        -- Connecter l'événement
        tabButton.MouseButton1Click:Connect(function()
            self:SwitchTab(tab.id)
        end)
        
        tabButtons[tab.id] = tabButton
    end
    
    self.tabButtons = tabButtons
    
    -- Contenu des onglets
    local contentFrame = Instance.new("Frame")
    contentFrame.Name = "TabContent"
    contentFrame.Size = UDim2.new(1, 0, 1, -50)
    contentFrame.Position = UDim2.new(0, 0, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = self.tribeView
    
    -- Créer les contenus de chaque onglet
    self:CreateInfoTab(contentFrame)
    self:CreateMembersTab(contentFrame)
    self:CreateTerritoryTab(contentFrame)
    self:CreateLogTab(contentFrame)
    
    -- Activer l'onglet info par défaut
    self:SwitchTab("info")
}

-- Créer l'onglet d'informations
function TribeUI:CreateInfoTab(parent)
    local infoFrame = Instance.new("Frame")
    infoFrame.Name = "InfoTab"
    infoFrame.Size = UDim2.new(1, 0, 1, 0)
    infoFrame.BackgroundTransparency = 1
    infoFrame.Visible = false
    infoFrame.Parent = parent
    
    -- Nom de la tribu
    local nameFrame = Instance.new("Frame")
    nameFrame.Name = "NameFrame"
    nameFrame.Size = UDim2.new(0, 600, 0, 50)
    nameFrame.Position = UDim2.new(0, 30, 0, 20)
    nameFrame.BackgroundTransparency = 0.7
    nameFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    nameFrame.BorderSizePixel = 0
    nameFrame.Parent = infoFrame
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.Size = UDim2.new(0, 120, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextSize = 16
    nameLabel.Font = Enum.Font.SourceSansBold
    nameLabel.Text = "Nom de la tribu:"
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Position = UDim2.new(0, 10, 0, 0)
    nameLabel.Parent = nameFrame
    
    local nameValue = Instance.new("TextLabel")
    nameValue.Name = "NameValue"
    nameValue.Size = UDim2.new(1, -140, 1, 0)
    nameValue.Position = UDim2.new(0, 130, 0, 0)
    nameValue.BackgroundTransparency = 1
    nameValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameValue.TextSize = 18
    nameValue.Font = Enum.Font.SourceSans
    nameValue.Text = ""
    nameValue.TextXAlignment = Enum.TextXAlignment.Left
    nameValue.Parent = nameFrame
    
    -- Description de la tribu
    local descFrame = Instance.new("Frame")
    descFrame.Name = "DescFrame"
    descFrame.Size = UDim2.new(0, 600, 0, 150)
    descFrame.Position = UDim2.new(0, 30, 0, 80)
    descFrame.BackgroundTransparency = 0.7
    descFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    descFrame.BorderSizePixel = 0
    descFrame.Parent = infoFrame
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Name = "DescLabel"
    descLabel.Size = UDim2.new(1, -20, 0, 30)
    descLabel.Position = UDim2.new(0, 10, 0, 5)
    descLabel.BackgroundTransparency = 1
    descLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    descLabel.TextSize = 16
    descLabel.Font = Enum.Font.SourceSansBold
    descLabel.Text = "Description:"
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = descFrame
    
    local descScrollFrame = Instance.new("ScrollingFrame")
    descScrollFrame.Name = "DescScrollFrame"
    descScrollFrame.Size = UDim2.new(1, -20, 1, -40)
    descScrollFrame.Position = UDim2.new(0, 10, 0, 35)
    descScrollFrame.BackgroundTransparency = 0.9
    descScrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    descScrollFrame.BorderSizePixel = 0
    descScrollFrame.ScrollBarThickness = 6
    descScrollFrame.Parent = descFrame
    
    local descText = Instance.new("TextLabel")
    descText.Name = "DescText"
    descText.Size = UDim2.new(1, -10, 1, 0)
    descText.BackgroundTransparency = 1
    descText.TextColor3 = Color3.fromRGB(255, 255, 255)
    descText.TextSize = 15
    descText.Font = Enum.Font.SourceSans
    descText.Text = ""
    descText.TextWrapped = true
    descText.TextXAlignment = Enum.TextXAlignment.Left
    descText.TextYAlignment = Enum.TextYAlignment.Top
    descText.Parent = descScrollFrame
    
    -- Section d'édition de description (visible uniquement pour leader/elder)
    local editDescFrame = Instance.new("Frame")
    editDescFrame.Name = "EditDescFrame"
    editDescFrame.Size = UDim2.new(0, 600, 0, 150)
    editDescFrame.Position = UDim2.new(0, 30, 0, 240)
    editDescFrame.BackgroundTransparency = 0.7
    editDescFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    editDescFrame.BorderSizePixel = 0
    editDescFrame.Visible = false
    editDescFrame.Parent = infoFrame
    
    local editDescLabel = Instance.new("TextLabel")
    editDescLabel.Name = "EditDescLabel"
    editDescLabel.Size = UDim2.new(1, -20, 0, 30)
    editDescLabel.Position = UDim2.new(0, 10, 0, 5)
    editDescLabel.BackgroundTransparency = 1
    editDescLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    editDescLabel.TextSize = 16
    editDescLabel.Font = Enum.Font.SourceSansBold
    editDescLabel.Text = "Modifier la description:"
    editDescLabel.TextXAlignment = Enum.TextXAlignment.Left
    editDescLabel.Parent = editDescFrame
    
    local editDescInput = Instance.new("TextBox")
    editDescInput.Name = "EditDescInput"
    editDescInput.Size = UDim2.new(1, -20, 1, -80)
    editDescInput.Position = UDim2.new(0, 10, 0, 35)
    editDescInput.BackgroundTransparency = 0.5
    editDescInput.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    editDescInput.BorderSizePixel = 0
    editDescInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    editDescInput.TextSize = 15
    editDescInput.Font = Enum.Font.SourceSans
    editDescInput.Text = ""
    editDescInput.PlaceholderText = "Entrez une nouvelle description pour votre tribu"
    editDescInput.TextWrapped = true
    editDescInput.TextXAlignment = Enum.TextXAlignment.Left
    editDescInput.TextYAlignment = Enum.TextYAlignment.Top
    editDescInput.ClearTextOnFocus = false
    editDescInput.MultiLine = true
    editDescInput.Parent = editDescFrame
    
    local saveDescButton = Instance.new("TextButton")
    saveDescButton.Name = "SaveDescButton"
    saveDescButton.Size = UDim2.new(0, 150, 0, 30)
    saveDescButton.Position = UDim2.new(0.5, -75, 1, -35)
    saveDescButton.BackgroundTransparency = 0.5
    saveDescButton.BackgroundColor3 = Color3