-- src/client/ui/InventoryUI.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemTypes = require(Shared.constants.ItemTypes)

local InventoryUI = {}
InventoryUI.__index = InventoryUI

function InventoryUI.new()
    local self = setmetatable({}, InventoryUI)
    
    -- Référence au joueur local
    self.player = Players.LocalPlayer
    
    -- Données d'inventaire
    self.inventory = {}
    self.equippedItems = {}
    self.maxSlots = 20
    
    -- Interface ScreenGui
    self.gui = nil
    self.inventoryFrame = nil
    self.slotFrames = {}
    self.isOpen = false
    
    -- Glisser-déposer
    self.draggedItem = nil
    self.draggedSlot = nil
    self.dragIcon = nil
    
    return self
end

function InventoryUI:Initialize()
    -- Créer l'interface ScreenGui
    self.gui = Instance.new("ScreenGui")
    self.gui.Name = "InventoryUI"
    self.gui.ResetOnSpawn = false
    self.gui.Enabled = false
    
    -- Cadre principal pour l'inventaire
    self.inventoryFrame = Instance.new("Frame")
    self.inventoryFrame.Name = "InventoryFrame"
    self.inventoryFrame.Size = UDim2.new(0, 550, 0, 380)
    self.inventoryFrame.Position = UDim2.new(0.5, -275, 0.5, -190)
    self.inventoryFrame.BackgroundTransparency = 0.15
    self.inventoryFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    self.inventoryFrame.BorderSizePixel = 0
    self.inventoryFrame.Parent = self.gui
    
    -- Arrondir les coins
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 12)
    uiCorner.Parent = self.inventoryFrame
    
    -- Effet de brillance subtil
    local mainGradient = Instance.new("UIGradient")
    mainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 45, 45)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(35, 35, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 45))
    })
    mainGradient.Rotation = 90
    mainGradient.Parent = self.inventoryFrame
    
    -- Titre de l'inventaire
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, 0, 0, 45)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 0.3
    titleLabel.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleLabel.BorderSizePixel = 0
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Text = "🎒 Inventaire"
    titleLabel.TextSize = 18
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = self.inventoryFrame
    
    -- Arrondir les coins du titre
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleLabel
    
    -- Bouton de fermeture
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 35, 0, 35)
    closeButton.Position = UDim2.new(1, -40, 0, 5)
    closeButton.BackgroundTransparency = 0.3
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeButton.BorderSizePixel = 0
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "✕"
    closeButton.TextSize = 18
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleLabel
    
    -- Arrondir les coins du bouton
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = closeButton
    
    -- Effet hover pour le bouton
    closeButton.MouseEnter:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    end)
    closeButton.MouseLeave:Connect(function()
        closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    end)
    
    -- Grille d'emplacements d'inventaire
    local slotsFrame = Instance.new("Frame")
    slotsFrame.Name = "SlotsFrame"
    slotsFrame.Size = UDim2.new(0, 420, 0, 270)
    slotsFrame.Position = UDim2.new(0.5, -210, 0, 65)
    slotsFrame.BackgroundTransparency = 1
    slotsFrame.Parent = self.inventoryFrame
    
    -- Créer les emplacements d'inventaire
    local slotSize = 48
    local padding = 6
    local slotsPerRow = 8
    
    for i = 1, self.maxSlots do
        local row = math.floor((i - 1) / slotsPerRow)
        local col = (i - 1) % slotsPerRow
        
        local xPos = col * (slotSize + padding)
        local yPos = row * (slotSize + padding)
        
        self:CreateInventorySlot(i, slotsFrame, UDim2.new(0, xPos, 0, yPos), UDim2.new(0, slotSize, 0, slotSize))
    end
    
    -- Équipement
    local equipmentFrame = Instance.new("Frame")
    equipmentFrame.Name = "EquipmentFrame"
    equipmentFrame.Size = UDim2.new(0, 90, 0, 270)
    equipmentFrame.Position = UDim2.new(0, 15, 0, 65)
    equipmentFrame.BackgroundTransparency = 0.5
    equipmentFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    equipmentFrame.BorderSizePixel = 0
    equipmentFrame.Parent = self.inventoryFrame
    
    local equipmentCorner = Instance.new("UICorner")
    equipmentCorner.CornerRadius = UDim.new(0, 10)
    equipmentCorner.Parent = equipmentFrame
    
    -- Titre du panneau d'équipement
    local equipTitle = Instance.new("TextLabel")
    equipTitle.Name = "EquipTitle"
    equipTitle.Size = UDim2.new(1, 0, 0, 25)
    equipTitle.BackgroundTransparency = 0.3
    equipTitle.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
    equipTitle.BorderSizePixel = 0
    equipTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    equipTitle.TextSize = 12
    equipTitle.Font = Enum.Font.GothamBold
    equipTitle.Text = "⚔️ Équipement"
    equipTitle.Parent = equipmentFrame
    
    local equipTitleCorner = Instance.new("UICorner")
    equipTitleCorner.CornerRadius = UDim.new(0, 10)
    equipTitleCorner.Parent = equipTitle
    
    -- Emplacements d'équipement
    self:CreateEquipmentSlot("tool", equipmentFrame, UDim2.new(0, 15, 0, 35), "🔨 Outil")
    self:CreateEquipmentSlot("body", equipmentFrame, UDim2.new(0, 15, 0, 115), "👚 Corps")
    self:CreateEquipmentSlot("head", equipmentFrame, UDim2.new(0, 15, 0, 195), "🎩 Tête")
    
    -- Ajouter l'interface au joueur
    self.gui.Parent = self.player.PlayerGui
    
    -- Connecter les événements
    closeButton.MouseButton1Click:Connect(function()
        self:ToggleInventory(false)
    end)
    
    -- Connexion pour le touche d'ouverture d'inventaire (E)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.E then
            self:ToggleInventory(not self.isOpen)
        end
    end)
    
    -- Connexion pour le glisser-déposer
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if self.draggedItem and (input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.Touch) then
            self:EndDrag()
        end
    end)
    
    -- Connexion pour le mouvement de la souris
    UserInputService.InputChanged:Connect(function(input, gameProcessed)
        if self.draggedItem and input.UserInputType == Enum.UserInputType.MouseMovement then
            if self.dragIcon then
                self.dragIcon.Position = UDim2.new(0, input.Position.X, 0, input.Position.Y)
            end
        end
    end)
    
    return self
end

function InventoryUI:CreateInventorySlot(slotNumber, parent, position, size)
    -- Créer le cadre de l'emplacement
    local slotFrame = Instance.new("Frame")
    slotFrame.Name = "Slot" .. slotNumber
    slotFrame.Size = size
    slotFrame.Position = position
    slotFrame.BackgroundTransparency = 0.4
    slotFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    slotFrame.BorderSizePixel = 0
    slotFrame.Parent = parent
    
    -- Arrondir les coins
    local slotCorner = Instance.new("UICorner")
    slotCorner.CornerRadius = UDim.new(0, 8)
    slotCorner.Parent = slotFrame
    
    -- Bordure subtile
    local slotStroke = Instance.new("UIStroke")
    slotStroke.Color = Color3.fromRGB(70, 70, 70)
    slotStroke.Thickness = 1
    slotStroke.Transparency = 0.6
    slotStroke.Parent = slotFrame
    
    -- Image de l'objet
    local itemImage = Instance.new("ImageLabel")
    itemImage.Name = "ItemImage"
    itemImage.Size = UDim2.new(0.8, 0, 0.8, 0)
    itemImage.Position = UDim2.new(0.1, 0, 0.1, 0)
    itemImage.BackgroundTransparency = 1
    itemImage.Image = ""
    itemImage.Visible = false
    itemImage.Parent = slotFrame
    
    -- Quantité
    local quantityLabel = Instance.new("TextLabel")
    quantityLabel.Name = "QuantityLabel"
    quantityLabel.Size = UDim2.new(0, 22, 0, 18)
    quantityLabel.Position = UDim2.new(1, -24, 1, -20)
    quantityLabel.BackgroundTransparency = 0.3
    quantityLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    quantityLabel.BorderSizePixel = 0
    quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    quantityLabel.Text = ""
    quantityLabel.TextSize = 12
    quantityLabel.Font = Enum.Font.GothamBold
    quantityLabel.Visible = false
    quantityLabel.ZIndex = 3
    quantityLabel.Parent = slotFrame
    
    -- Arrondir les coins de l'étiquette
    local quantityCorner = Instance.new("UICorner")
    quantityCorner.CornerRadius = UDim.new(0, 6)
    quantityCorner.Parent = quantityLabel
    
    -- Bouton pour l'interaction
    local slotButton = Instance.new("TextButton")
    slotButton.Name = "SlotButton"
    slotButton.Size = UDim2.new(1, 0, 1, 0)
    slotButton.BackgroundTransparency = 1
    slotButton.Text = ""
    slotButton.Parent = slotFrame
    
    -- Connecter les événements du bouton
    slotButton.MouseButton1Down:Connect(function()
        self:StartDrag(slotNumber)
    end)
    
    slotButton.MouseButton1Up:Connect(function()
        if self.draggedItem then
            self:DropOnSlot(slotNumber)
        end
    end)
    
    slotButton.MouseButton2Click:Connect(function()
        self:UseItem(slotNumber)
    end)
    
    -- Info-bulle
    local tooltipFrame = Instance.new("Frame")
    tooltipFrame.Name = "TooltipFrame"
    tooltipFrame.Size = UDim2.new(0, 200, 0, 100)
    tooltipFrame.BackgroundTransparency = 0.2
    tooltipFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tooltipFrame.BorderSizePixel = 0
    tooltipFrame.Visible = false
    tooltipFrame.ZIndex = 10
    tooltipFrame.Parent = slotFrame
    
    -- Arrondir les coins de l'info-bulle
    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 5)
    tooltipCorner.Parent = tooltipFrame
    
    -- Titre de l'info-bulle
    local tooltipTitle = Instance.new("TextLabel")
    tooltipTitle.Name = "Title"
    tooltipTitle.Size = UDim2.new(1, 0, 0, 25)
    tooltipTitle.BackgroundTransparency = 1
    tooltipTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    tooltipTitle.TextSize = 16
    tooltipTitle.Font = Enum.Font.SourceSansBold
    tooltipTitle.TextXAlignment = Enum.TextXAlignment.Left
    tooltipTitle.TextYAlignment = Enum.TextYAlignment.Center
    tooltipTitle.Text = ""
    tooltipTitle.ZIndex = 11
    tooltipTitle.Parent = tooltipFrame
    
    -- Description de l'info-bulle
    local tooltipDesc = Instance.new("TextLabel")
    tooltipDesc.Name = "Description"
    tooltipDesc.Size = UDim2.new(1, 0, 1, -25)
    tooltipDesc.Position = UDim2.new(0, 0, 0, 25)
    tooltipDesc.BackgroundTransparency = 1
    tooltipDesc.TextColor3 = Color3.fromRGB(200, 200, 200)
    tooltipDesc.TextSize = 14
    tooltipDesc.Font = Enum.Font.SourceSans
    tooltipDesc.TextXAlignment = Enum.TextXAlignment.Left
    tooltipDesc.TextYAlignment = Enum.TextYAlignment.Top
    tooltipDesc.TextWrapped = true
    tooltipDesc.Text = ""
    tooltipDesc.ZIndex = 11
    tooltipDesc.Parent = tooltipFrame
    
    -- Événements pour l'info-bulle
    slotButton.MouseEnter:Connect(function()
        self:ShowTooltip(slotNumber)
    end)
    
    slotButton.MouseLeave:Connect(function()
        self:HideTooltip(slotNumber)
    end)
    
    -- Stocker la référence
    self.slotFrames[slotNumber] = slotFrame
end

function InventoryUI:CreateEquipmentSlot(equipType, parent, position, label)
    -- Créer le cadre de l'emplacement
    local slotFrame = Instance.new("Frame")
    slotFrame.Name = equipType .. "Slot"
    slotFrame.Size = UDim2.new(0, 60, 0, 60)
    slotFrame.Position = position
    slotFrame.BackgroundTransparency = 0.4
    slotFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    slotFrame.BorderSizePixel = 0
    slotFrame.Parent = parent
    
    -- Arrondir les coins
    local slotCorner = Instance.new("UICorner")
    slotCorner.CornerRadius = UDim.new(0, 10)
    slotCorner.Parent = slotFrame
    
    -- Bordure
    local slotStroke = Instance.new("UIStroke")
    slotStroke.Color = Color3.fromRGB(90, 90, 90)
    slotStroke.Thickness = 2
    slotStroke.Transparency = 0.5
    slotStroke.Parent = slotFrame
    
    -- Étiquette du type d'équipement
    local typeLabel = Instance.new("TextLabel")
    typeLabel.Name = "TypeLabel"
    typeLabel.Size = UDim2.new(1, 0, 0, 18)
    typeLabel.Position = UDim2.new(0, 0, 1, 3)
    typeLabel.BackgroundTransparency = 1
    typeLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    typeLabel.Text = label
    typeLabel.TextSize = 11
    typeLabel.Font = Enum.Font.GothamBold
    typeLabel.Parent = slotFrame
    
    -- Image de l'objet
    local itemImage = Instance.new("ImageLabel")
    itemImage.Name = "ItemImage"
    itemImage.Size = UDim2.new(0.8, 0, 0.8, 0)
    itemImage.Position = UDim2.new(0.1, 0, 0.1, 0)
    itemImage.BackgroundTransparency = 1
    itemImage.Image = ""
    itemImage.Visible = false
    itemImage.Parent = slotFrame
    
    -- Bouton pour l'interaction
    local slotButton = Instance.new("TextButton")
    slotButton.Name = "SlotButton"
    slotButton.Size = UDim2.new(1, 0, 1, 0)
    slotButton.BackgroundTransparency = 1
    slotButton.Text = ""
    slotButton.Parent = slotFrame
    
    -- Connecter les événements
    slotButton.MouseButton1Up:Connect(function()
        if self.draggedItem then
            self:EquipItem(equipType)
        else
            self:UnequipItem(equipType)
        end
    end)
    
    -- Stocker la référence
    self.slotFrames["equip_" .. equipType] = slotFrame
end

function InventoryUI:UpdateSlot(slotNumber, item)
    local slotFrame = self.slotFrames[slotNumber]
    if not slotFrame then return end
    
    local itemImage = slotFrame:FindFirstChild("ItemImage")
    local quantityLabel = slotFrame:FindFirstChild("QuantityLabel")
    
    if not item then
        -- Slot vide
        if itemImage then itemImage.Visible = false end
        if quantityLabel then quantityLabel.Visible = false end
    else
        -- Mettre à jour l'image
        if itemImage then
            local itemType = ItemTypes[item.id]
            if itemType then
                itemImage.Image = itemType.model
                itemImage.Visible = true
            end
        end
        
        -- Mettre à jour la quantité
        if quantityLabel then
            if item.quantity and item.quantity > 1 then
                quantityLabel.Text = tostring(item.quantity)
                quantityLabel.Visible = true
            else
                quantityLabel.Visible = false
            end
        end
    end
end

function InventoryUI:UpdateEquipmentSlot(equipType, itemId)
    local slotFrame = self.slotFrames["equip_" .. equipType]
    if not slotFrame then return end
    
    local itemImage = slotFrame:FindFirstChild("ItemImage")
    
    if not itemId then
        -- Slot vide
        if itemImage then itemImage.Visible = false end
    else
        -- Mettre à jour l'image
        if itemImage then
            local itemType = ItemTypes[itemId]
            if itemType then
                itemImage.Image = itemType.model
                itemImage.Visible = true
            end
        end
    end
end

function InventoryUI:UpdateInventory(inventoryData)
    self.inventory = inventoryData.items or {}
    self.equippedItems = inventoryData.equipped or {}
    
    -- Mettre à jour les emplacements d'inventaire
    for i = 1, self.maxSlots do
        self:UpdateSlot(i, self.inventory[i])
    end
    
    -- Mettre à jour les emplacements d'équipement
    for equipType, itemId in pairs(self.equippedItems) do
        self:UpdateEquipmentSlot(equipType, itemId)
    end
end

function InventoryUI:ToggleInventory(open)
    self.isOpen = open
    self.gui.Enabled = open
    
    -- Informer le contrôleur du changement d'état
    -- Dans une implémentation réelle, ça serait un signal ou événement
    print("Inventaire " .. (open and "ouvert" or "fermé"))
end

function InventoryUI:ShowTooltip(slotNumber)
    local slotFrame = self.slotFrames[slotNumber]
    if not slotFrame then return end
    
    local item = self.inventory[slotNumber]
    if not item then return end
    
    local tooltipFrame = slotFrame:FindFirstChild("TooltipFrame")
    if not tooltipFrame then return end
    
    local itemType = ItemTypes[item.id]
    if not itemType then return end
    
    -- Mettre à jour le contenu
    local titleLabel = tooltipFrame:FindFirstChild("Title")
    local descLabel = tooltipFrame:FindFirstChild("Description")
    
    if titleLabel then titleLabel.Text = itemType.name end
    if descLabel then descLabel.Text = itemType.description end
    
    -- Positionner et afficher l'info-bulle
    tooltipFrame.Position = UDim2.new(1, 10, 0, 0)
    tooltipFrame.Visible = true
end

function InventoryUI:HideTooltip(slotNumber)
    local slotFrame = self.slotFrames[slotNumber]
    if not slotFrame then return end
    
    local tooltipFrame = slotFrame:FindFirstChild("TooltipFrame")
    if tooltipFrame then
        tooltipFrame.Visible = false
    end
end

function InventoryUI:StartDrag(slotNumber)
    local item = self.inventory[slotNumber]
    if not item then return end
    
    self.draggedItem = item
    self.draggedSlot = slotNumber
    
    -- Créer une icône pour le glisser-déposer
    local itemType = ItemTypes[item.id]
    if not itemType then return end
    
    -- Créer l'icône si elle n'existe pas
    if not self.dragIcon then
        self.dragIcon = Instance.new("ImageLabel")
        self.dragIcon.Size = UDim2.new(0, 40, 0, 40)
        self.dragIcon.BackgroundTransparency = 1
        self.dragIcon.Parent = self.gui
    end
    
    -- Mettre à jour l'icône
    self.dragIcon.Image = itemType.model
    self.dragIcon.Position = UDim2.new(0, UserInputService:GetMouseLocation().X, 0, UserInputService:GetMouseLocation().Y)
    self.dragIcon.Visible = true
end

function InventoryUI:EndDrag()
    -- Cacher l'icône de glisser-déposer
    if self.dragIcon then
        self.dragIcon.Visible = false
    end
    
    self.draggedItem = nil
    self.draggedSlot = nil
end

function InventoryUI:DropOnSlot(slotNumber)
    if not self.draggedItem or self.draggedSlot == slotNumber then
        self:EndDrag()
        return
    end
    
    -- Vérifier si l'emplacement cible est vide ou contient le même type d'objet
    local targetItem = self.inventory[slotNumber]
    
    if not targetItem then
        -- Emplacement vide, déplacer l'objet
        self.inventory[slotNumber] = self.draggedItem
        self.inventory[self.draggedSlot] = nil
    else
        -- Si c'est le même type d'objet et qu'il est empilable
        local itemType = ItemTypes[self.draggedItem.id]
        if targetItem.id == self.draggedItem.id and itemType and itemType.stackable then
            -- Ajouter à la pile
            targetItem.quantity = targetItem.quantity + self.draggedItem.quantity
            self.inventory[self.draggedSlot] = nil
        else
            -- Échanger les objets
            self.inventory[slotNumber] = self.draggedItem
            self.inventory[self.draggedSlot] = targetItem
        end
    end
    
    -- Mettre à jour l'affichage
    self:UpdateSlot(slotNumber, self.inventory[slotNumber])
    self:UpdateSlot(self.draggedSlot, self.inventory[self.draggedSlot])
    
    -- Dans une implémentation réelle, envoyer la modification au serveur
    -- SendInventoryUpdateToServer()
    
    self:EndDrag()
end

function InventoryUI:EquipItem(equipType)
    if not self.draggedItem then return end
    
    local itemType = ItemTypes[self.draggedItem.id]
    if not itemType or not itemType.equipable or itemType.equipSlot ~= equipType then
        -- L'objet ne peut pas être équipé dans cet emplacement
        self:EndDrag()
        return
    end
    
    -- Déséquiper l'objet actuel s'il y en a un
    if self.equippedItems[equipType] then
        self:UnequipItem(equipType)
    end
    
    -- Équiper le nouvel objet
    self.equippedItems[equipType] = self.draggedItem.id
    
    -- Retirer l'objet de l'inventaire
    self.inventory[self.draggedSlot] = nil
    
    -- Mettre à jour l'affichage
    self:UpdateEquipmentSlot(equipType, self.draggedItem.id)
    self:UpdateSlot(self.draggedSlot, nil)
    
    -- Dans une implémentation réelle, envoyer la modification au serveur
    -- SendEquipUpdateToServer()
    
    self:EndDrag()
end

function InventoryUI:UnequipItem(equipType)
    local equippedItemId = self.equippedItems[equipType]
    if not equippedItemId then return end
    
    -- Trouver un emplacement vide
    local emptySlot = nil
    for i = 1, self.maxSlots do
        if not self.inventory[i] then
            emptySlot = i
            break
        end
    end
    
    if not emptySlot then
        -- Inventaire plein, ne rien faire
        return
    end
    
    -- Créer un nouvel objet à partir de l'ID
    local newItem = {
        id = equippedItemId,
        quantity = 1,
        data = {}  -- Données supplémentaires (durabilité, etc.)
    }
    
    -- Ajouter l'objet à l'inventaire
    self.inventory[emptySlot] = newItem
    
    -- Retirer l'objet de l'équipement
    self.equippedItems[equipType] = nil
    
    -- Mettre à jour l'affichage
    self:UpdateEquipmentSlot(equipType, nil)
    self:UpdateSlot(emptySlot, newItem)
    
    -- Dans une implémentation réelle, envoyer la modification au serveur
    -- SendUnequipUpdateToServer()
end

function InventoryUI:UseItem(slotNumber)
    local item = self.inventory[slotNumber]
    if not item then return end
    
    local itemType = ItemTypes[item.id]
    if not itemType then return end
    
    -- Actions spécifiques selon le type d'objet
    if itemType.category == "food" then
        -- Consommer de la nourriture
        print("Consommation de nourriture: " .. itemType.name)
        -- Dans une implémentation réelle, envoyer au serveur
        -- SendUseItemToServer(slotNumber)
    elseif itemType.category == "drink" then
        -- Boire
        print("Consommation de boisson: " .. itemType.name)
        -- SendUseItemToServer(slotNumber)
    elseif itemType.equipable then
        -- Équiper directement l'objet
        if itemType.equipSlot then
            self:StartDrag(slotNumber)
            self:EquipItem(itemType.equipSlot)
        end
    elseif itemType.category == "building" or itemType.category == "furniture" then
        -- Entrer en mode construction
        print("Mode construction: " .. itemType.name)
        -- SendStartBuildingToServer(slotNumber)
    end
end

return InventoryUI