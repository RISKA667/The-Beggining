-- src/server/services/InventoryService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemTypes = require(Shared.constants.ItemTypes)

local InventoryService = {}
InventoryService.__index = InventoryService

-- Créer une instance du service
function InventoryService.new()
    local self = setmetatable({}, InventoryService)
    
    -- Stockage des inventaires de joueurs
    self.playerInventories = {}
    self.maxInventorySlots = 20  -- Limite d'inventaire par défaut
    
    return self
end

-- Initialiser un inventaire pour un joueur
function InventoryService:InitializePlayerInventory(player)
    if self.playerInventories[player.UserId] then return end
    
    -- Créer un nouvel inventaire vide
    self.playerInventories[player.UserId] = {
        items = {},
        equipped = {}  -- Objets équipés actuellement
    }
    
    -- Donnez les objets de départ à un nouveau joueur
    self:AddItemToInventory(player, "stone", 1)
    
    -- Événement de mise à jour de l'inventaire
    self:UpdateClientInventory(player)
end

-- Ajouter un objet à l'inventaire
function InventoryService:AddItemToInventory(player, itemId, quantity)
    local inventory = self.playerInventories[player.UserId]
    if not inventory then return false end
    
    quantity = quantity or 1
    
    -- Vérifier si l'objet existe déjà (pour empilage)
    for slot, item in pairs(inventory.items) do
        if item.id == itemId and ItemTypes[itemId].stackable then
            inventory.items[slot].quantity = item.quantity + quantity
            self:UpdateClientInventory(player)
            return true
        end
    end
    
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
        return false
    end
    
    -- Ajouter le nouvel objet
    inventory.items[emptySlot] = {
        id = itemId,
        quantity = quantity,
        data = {}  -- Données supplémentaires (durabilité, etc.)
    }
    
    self:UpdateClientInventory(player)
    return true
end

-- Retirer un objet de l'inventaire
function InventoryService:RemoveItemFromInventory(player, itemId, quantity)
    local inventory = self.playerInventories[player.UserId]
    if not inventory then return false end
    
    quantity = quantity or 1
    
    -- Trouver l'objet dans l'inventaire
    for slot, item in pairs(inventory.items) do
        if item.id == itemId then
            if item.quantity > quantity then
                -- Réduire la quantité
                inventory.items[slot].quantity = item.quantity - quantity
                self:UpdateClientInventory(player)
                return true
            elseif item.quantity == quantity then
                -- Supprimer l'objet
                inventory.items[slot] = nil
                self:UpdateClientInventory(player)
                return true
            else
                -- Pas assez d'objets
                return false
            end
        end
    end
    
    return false
end

-- Équiper un objet
function InventoryService:EquipItem(player, slotNumber)
    local inventory = self.playerInventories[player.UserId]
    if not inventory or not inventory.items[slotNumber] then return false end
    
    local item = inventory.items[slotNumber]
    local itemType = ItemTypes[item.id]
    
    if itemType.equipable then
        inventory.equipped[itemType.equipSlot] = slotNumber
        self:UpdateClientInventory(player)
        return true
    end
    
    return false
end

-- Déséquiper un objet
function InventoryService:UnequipItem(player, equipSlot)
    local inventory = self.playerInventories[player.UserId]
    if not inventory or not inventory.equipped[equipSlot] then return false end
    
    inventory.equipped[equipSlot] = nil
    self:UpdateClientInventory(player)
    return true
end

-- Mettre à jour l'inventaire du client
function InventoryService:UpdateClientInventory(player)
    -- Dans une implémentation réelle, utilisez RemoteEvent pour synchroniser avec le client
    print("Mise à jour de l'inventaire pour le joueur: " .. player.Name)
end

-- Gérer la déconnexion d'un joueur
function InventoryService:HandlePlayerRemoving(player)
    -- Sauvegarder l'inventaire dans DataStore si nécessaire
    self.playerInventories[player.UserId] = nil
end

function InventoryService:Start()
    -- Gérer les événements de joueur
    game.Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerInventory(player)
    end)
    
    game.Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
end

return InventoryService