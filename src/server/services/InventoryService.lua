-- src/server/services/InventoryService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemTypes = require(Shared.constants.ItemTypes)
local GameSettings = require(Shared.constants.GameSettings)

local InventoryDataStore = DataStoreService:GetDataStore("PlayerInventories_v1")

local InventoryService = {}
InventoryService.__index = InventoryService

-- Créer une instance du service
function InventoryService.new()
    local self = setmetatable({}, InventoryService)
    
    -- Stockage des inventaires de joueurs
    self.playerInventories = {}
    self.maxInventorySlots = GameSettings.Player.initialInventorySize or 20  -- Limite d'inventaire par défaut
    
    return self
end

-- Initialiser un inventaire pour un joueur
function InventoryService:InitializePlayerInventory(player)
    if self.playerInventories[player.UserId] then return end
    
    -- Essayer de charger les données sauvegardées
    local success, savedData = pcall(function()
        return InventoryDataStore:GetAsync("inventory_" .. player.UserId)
    end)
    
    -- Créer un nouvel inventaire
    if success and savedData then
        self.playerInventories[player.UserId] = savedData
        print("InventoryService: Chargement de l'inventaire pour " .. player.Name)
    else
        -- Créer un inventaire vide si pas de données sauvegardées ou erreur
        self.playerInventories[player.UserId] = {
            items = {},
            equipped = {}  -- Objets équipés actuellement
        }
        
        -- Donnez les objets de départ à un nouveau joueur
        local startingItems = GameSettings.Player.spawnWithItems or {}
        for itemId, quantity in pairs(startingItems) do
            self:AddItemToInventory(player, itemId, quantity)
        end
        
        print("InventoryService: Nouvel inventaire créé pour " .. player.Name)
    end
    
    -- Envoyer les données d'inventaire au client
    self:UpdateClientInventory(player)
end

-- Sauvegarder l'inventaire d'un joueur
function InventoryService:SavePlayerInventory(player)
    local userId = type(player) == "number" and player or player.UserId
    
    if not self.playerInventories[userId] then return false end
    
    local success, errorMessage = pcall(function()
        InventoryDataStore:SetAsync("inventory_" .. userId, self.playerInventories[userId])
    end)
    
    if not success then
        warn("InventoryService: Échec de la sauvegarde de l'inventaire - " .. errorMessage)
        return false
    end
    
    return true
end

-- Ajouter un objet à l'inventaire
function InventoryService:AddItemToInventory(player, itemId, quantity)
    local inventory = self.playerInventories[player.UserId]
    if not inventory then return false end
    
    -- Vérifier si l'objet existe dans ItemTypes
    if not ItemTypes[itemId] then
        warn("InventoryService: Type d'objet invalide - " .. tostring(itemId))
        return false
    end
    
    quantity = quantity or 1
    
    -- Vérifier si l'objet est empilable
    if ItemTypes[itemId].stackable then
        -- Essayer d'empiler avec des objets existants
        for slot, item in pairs(inventory.items) do
            if item.id == itemId and (not ItemTypes[itemId].maxStack or item.quantity < ItemTypes[itemId].maxStack) then
                local maxAdd = ItemTypes[itemId].maxStack and (ItemTypes[itemId].maxStack - item.quantity) or quantity
                local actualAdd = math.min(quantity, maxAdd)
                
                inventory.items[slot].quantity = item.quantity + actualAdd
                quantity = quantity - actualAdd
                
                if quantity <= 0 then
                    -- Tout a été ajouté
                    self:UpdateClientInventory(player)
                    return true
                end
            end
        end
    end
    
    -- S'il reste des objets à ajouter, chercher des emplacements vides
    while quantity > 0 do
        -- Trouver un emplacement vide
        local emptySlot = nil
        for i = 1, self.maxInventorySlots do
            if not inventory.items[i] then
                emptySlot = i
                break
            end
        end
        
        -- Si l'inventaire est plein
        if not emptySlot then
            -- Notifier le joueur
            local Events = ReplicatedStorage:FindFirstChild("Events")
            if Events and Events:FindFirstChild("Notification") then
                Events.Notification:FireClient(player, "Inventaire plein!", "warning")
            end
            return false
        end
        
        -- Ajouter le nouvel objet
        local addQuantity = 1
        if ItemTypes[itemId].stackable then
            addQuantity = math.min(quantity, ItemTypes[itemId].maxStack or quantity)
        end
        
        inventory.items[emptySlot] = {
            id = itemId,
            quantity = addQuantity,
            data = {}  -- Données supplémentaires (durabilité, etc.)
        }
        
        -- Si l'objet a une durabilité, l'initialiser
        if ItemTypes[itemId].durability then
            inventory.items[emptySlot].data.durability = ItemTypes[itemId].durability
        end
        
        quantity = quantity - addQuantity
    end
    
    self:UpdateClientInventory(player)
    return true
end

-- Retirer un objet de l'inventaire
function InventoryService:RemoveItemFromInventory(player, itemId, quantity)
    local inventory = self.playerInventories[player.UserId]
    if not inventory then return false end
    
    quantity = quantity or 1
    local remainingToRemove = quantity
    
    -- Parcourir l'inventaire pour trouver des objets correspondants
    for slot, item in pairs(inventory.items) do
        if item.id == itemId then
            if item.quantity > remainingToRemove then
                -- Réduire la quantité
                inventory.items[slot].quantity = item.quantity - remainingToRemove
                remainingToRemove = 0
                break
            else
                -- Supprimer l'objet et continuer si nécessaire
                remainingToRemove = remainingToRemove - item.quantity
                inventory.items[slot] = nil
                
                -- Vérifier si c'était un objet équipé et le déséquiper
                for equipSlot, slotNumber in pairs(inventory.equipped) do
                    if slotNumber == slot then
                        inventory.equipped[equipSlot] = nil
                    end
                end
                
                if remainingToRemove <= 0 then
                    break
                end
            end
        end
    end
    
    -- Mise à jour du client seulement si des objets ont été retirés
    if remainingToRemove < quantity then
        self:UpdateClientInventory(player)
        return true
    end
    
    return false
end

-- Vérifier si un joueur a un certain objet
function InventoryService:HasItemInInventory(player, itemId, quantity)
    local inventory = self.playerInventories[player.UserId]
    if not inventory then return false end
    
    quantity = quantity or 1
    local totalFound = 0
    
    -- Compter tous les objets correspondants
    for _, item in pairs(inventory.items) do
        if item.id == itemId then
            totalFound = totalFound + item.quantity
            if totalFound >= quantity then
                return true
            end
        end
    end
    
    return false
end

-- Compter le nombre d'un item donné dans l'inventaire
function InventoryService:CountItemsInInventory(player, itemId)
    local inventory = self.playerInventories[player.UserId]
    if not inventory then return 0 end
    
    local count = 0
    
    for _, item in pairs(inventory.items) do
        if item.id == itemId then
            count = count + (item.quantity or 1)
        end
    end
    
    return count
end

-- Équiper un objet
function InventoryService:EquipItem(player, slotNumber)
    local inventory = self.playerInventories[player.UserId]
    if not inventory or not inventory.items[slotNumber] then return false end
    
    local item = inventory.items[slotNumber]
    local itemType = ItemTypes[item.id]
    
    if not itemType or not itemType.equipable or not itemType.equipSlot then 
        return false 
    end
    
    -- Vérifier si un autre objet est déjà équipé dans cet emplacement
    local currentEquippedSlot = inventory.equipped[itemType.equipSlot]
    if currentEquippedSlot then
        -- Déséquiper l'objet actuel
        inventory.equipped[itemType.equipSlot] = nil
    end
    
    -- Équiper le nouvel objet
    inventory.equipped[itemType.equipSlot] = slotNumber
    
    self:UpdateClientInventory(player)
    return true
end

-- Déséquiper un objet
function InventoryService:UnequipItem(player, equipSlot)
    local inventory = self.playerInventories[player.UserId]
    if not inventory or not inventory.equipped[equipSlot] then return false end
    
    inventory.equipped[equipSlot] = nil
    self:UpdateClientInventory(player)
    return true
end

-- Déplacer un objet d'un emplacement à un autre
function InventoryService:MoveItem(player, fromSlot, toSlot)
    local inventory = self.playerInventories[player.UserId]
    if not inventory then return false end
    
    -- Vérifier que les emplacements sont valides
    if not fromSlot or not inventory.items[fromSlot] then return false end
    if not toSlot or toSlot < 1 or toSlot > self.maxInventorySlots then return false end
    
    local fromItem = inventory.items[fromSlot]
    local toItem = inventory.items[toSlot]
    
    -- Cas 1: destination vide - simplement déplacer
    if not toItem then
        inventory.items[toSlot] = fromItem
        inventory.items[fromSlot] = nil
        
        -- Mettre à jour les références d'équipement
        for equipSlot, slotNumber in pairs(inventory.equipped) do
            if slotNumber == fromSlot then
                inventory.equipped[equipSlot] = toSlot
            end
        end
    
    -- Cas 2: même type d'objet et empilable - combiner si possible
    elseif fromItem.id == toItem.id and ItemTypes[fromItem.id].stackable then
        local maxStack = ItemTypes[fromItem.id].maxStack or math.huge
        
        -- Calculer combien peuvent être transférés
        local transferAmount = math.min(fromItem.quantity, maxStack - toItem.quantity)
        
        if transferAmount > 0 then
            toItem.quantity = toItem.quantity + transferAmount
            fromItem.quantity = fromItem.quantity - transferAmount
            
            -- Supprimer l'emplacement source s'il est vide
            if fromItem.quantity <= 0 then
                inventory.items[fromSlot] = nil
                
                -- Mettre à jour les références d'équipement
                for equipSlot, slotNumber in pairs(inventory.equipped) do
                    if slotNumber == fromSlot then
                        inventory.equipped[equipSlot] = nil  -- Déséquiper
                    end
                end
            end
        end
        
    -- Cas 3: objets différents ou non empilables - échanger les positions
    else
        inventory.items[fromSlot] = toItem
        inventory.items[toSlot] = fromItem
        
        -- Mettre à jour les références d'équipement
        for equipSlot, slotNumber in pairs(inventory.equipped) do
            if slotNumber == fromSlot then
                inventory.equipped[equipSlot] = toSlot
            elseif slotNumber == toSlot then
                inventory.equipped[equipSlot] = fromSlot
            end
        end
    end
    
    self:UpdateClientInventory(player)
    return true
end

-- Utiliser un objet
function InventoryService:UseItem(player, slotNumber)
    local inventory = self.playerInventories[player.UserId]
    if not inventory or not inventory.items[slotNumber] then return false end
    
    local item = inventory.items[slotNumber]
    local itemType = ItemTypes[item.id]
    
    if not itemType then return false end
    
    -- Traiter selon le type d'objet
    if itemType.equipable then
        -- Équiper/déséquiper
        return self:EquipItem(player, slotNumber)
    elseif itemType.consumable then
        -- Consommer (nourriture, boisson, etc.)
        local consumed = false
        
        if itemType.category == "food" then
            -- Réduire la faim
            local Events = ReplicatedStorage:FindFirstChild("Events")
            if Events and Events:FindFirstChild("PlayerAction") then
                -- Déclencher l'action de consommation
                consumed = true
                Events.PlayerAction:FireServer("use_item", slotNumber, item.id)
            end
        elseif itemType.category == "drink" then
            -- Réduire la soif
            local Events = ReplicatedStorage:FindFirstChild("Events")
            if Events and Events:FindFirstChild("PlayerAction") then
                -- Déclencher l'action de consommation
                consumed = true
                Events.PlayerAction:FireServer("use_item", slotNumber, item.id)
            end
        end
        
        -- Si consommé, réduire la quantité ou supprimer l'objet
        if consumed then
            if item.quantity > 1 then
                item.quantity = item.quantity - 1
            else
                inventory.items[slotNumber] = nil
            end
            
            self:UpdateClientInventory(player)
            return true
        end
    elseif itemType.placeable then
        -- Placer dans le monde (bâtiment, meuble, etc.)
        local Events = ReplicatedStorage:FindFirstChild("Events")
        if Events and Events:FindFirstChild("PlayerAction") then
            -- Déclencher l'action de placement
            Events.PlayerAction:FireServer("use_item", slotNumber, item.id)
            return true
        end
    end
    
    return false
end

-- Mettre à jour l'inventaire du client
function InventoryService:UpdateClientInventory(player)
    local inventory = self.playerInventories[player.UserId]
    if not inventory then return end
    
    -- Envoyer les données d'inventaire au client
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if Events and Events:FindFirstChild("UpdateInventory") then
        Events.UpdateInventory:FireClient(player, inventory)
    end
end

-- Gérer la déconnexion d'un joueur
function InventoryService:HandlePlayerRemoving(player)
    -- Sauvegarder l'inventaire avant la déconnexion
    self:SavePlayerInventory(player)
    
    -- Nettoyer la mémoire
    self.playerInventories[player.UserId] = nil
end

-- Nettoyer les objets périmés
function InventoryService:CleanupExpiredItems()
    for userId, inventory in pairs(self.playerInventories) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            local itemsChanged = false
            
            -- Vérifier chaque objet pour voir s'il a expiré
            for slot, item in pairs(inventory.items) do
                if item.data and item.data.expiryTime and item.data.expiryTime < os.time() then
                    -- Supprimer l'objet expiré
                    inventory.items[slot] = nil
                    itemsChanged = true
                    
                    -- Notifier le joueur
                    local Events = ReplicatedStorage:FindFirstChild("Events")
                    if Events and Events:FindFirstChild("Notification") then
                        Events.Notification:FireClient(player, "Un objet dans votre inventaire s'est dégradé.", "warning")
                    end
                end
            end
            
            -- Mettre à jour l'interface si des objets ont été supprimés
            if itemsChanged then
                self:UpdateClientInventory(player)
            end
        end
    end
end

-- Démarrer le service
function InventoryService:Start(services)
    print("InventoryService: Démarrage...")
    
    -- Initialiser les inventaires des joueurs existants
    for _, player in pairs(Players:GetPlayers()) do
        self:InitializePlayerInventory(player)
    end
    
    -- Connecter aux événements de joueur
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerInventory(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
    
    -- Démarrer le nettoyage périodique des objets périmés
    spawn(function()
        while true do
            wait(60) -- Vérifier toutes les minutes
            pcall(function()
                self:CleanupExpiredItems()
            end)
        end
    end)
    
    -- Sauvegarde périodique des inventaires
    spawn(function()
        while true do
            wait(300) -- Sauvegarder toutes les 5 minutes
            pcall(function()
                for _, player in pairs(Players:GetPlayers()) do
                    self:SavePlayerInventory(player)
                end
            end)
        end
    end)
    
    print("InventoryService: Démarré avec succès")
    return self
end

return InventoryService