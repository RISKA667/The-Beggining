-- src/server/services/InventoryService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemTypes = require(Shared.constants.ItemTypes)
local GameSettings = require(Shared.constants.GameSettings)

-- Création du DataStore avec gestion des erreurs
local InventoryDataStore
local success, errorMessage = pcall(function()
    InventoryDataStore = DataStoreService:GetDataStore("PlayerInventories_v1")
end)

if not success then
    warn("InventoryService: Échec d'initialisation du DataStore - " .. tostring(errorMessage))
    InventoryDataStore = nil
end

local InventoryService = {}
InventoryService.__index = InventoryService

-- Créer une instance du service
function InventoryService.new()
    local self = setmetatable({}, InventoryService)
    
    -- Stockage des inventaires de joueurs
    self.playerInventories = {}
    
    -- Constantes
    self.maxInventorySlots = GameSettings.Player.initialInventorySize or 20
    self.defaultMaxStackSize = 64
    
    -- Limites pour les sauvegardes DataStore
    self.saveInterval = 300 -- 5 minutes entre les sauvegardes automatiques
    self.saveRetryLimit = 3 -- Nombre de tentatives pour sauvegarder en cas d'échec
    
    -- Suivi des dernières sauvegardes
    self.lastSaveTime = {}
    
    -- Sauvegardes en attente
    self.pendingSaves = {}
    
    -- État du service
    self.isInitialized = false
    
    -- RemoteEvents
    self.remoteEvents = {}
    
    return self
end

-- Initialiser un inventaire pour un joueur
function InventoryService:InitializePlayerInventory(player)
    if not player or not player:IsA("Player") then
        warn("InventoryService: Tentative d'initialiser l'inventaire d'un joueur invalide")
        return false
    end
    
    local userId = player.UserId
    
    -- Éviter la double initialisation
    if self.playerInventories[userId] then
        return true
    end
    
    -- Essayer de charger les données sauvegardées
    local loadedData = self:LoadPlayerInventory(player)
    
    if loadedData then
        self.playerInventories[userId] = loadedData
        print("InventoryService: Inventaire chargé pour " .. player.Name)
    else
        -- Créer un inventaire vide si pas de données sauvegardées ou erreur
        self.playerInventories[userId] = {
            items = {},
            equipped = {},  -- Objets équipés actuellement
            maxSlots = self.maxInventorySlots
        }
        
        -- Donner les objets de départ à un nouveau joueur
        local startingItems = GameSettings.Player.spawnWithItems or {}
        for itemId, quantity in pairs(startingItems) do
            self:AddItemToInventory(player, itemId, quantity)
        end
        
        print("InventoryService: Nouvel inventaire créé pour " .. player.Name)
    end
    
    -- Envoyer les données d'inventaire au client
    self:UpdateClientInventory(player)
    
    return true
end

-- Charger l'inventaire d'un joueur depuis le DataStore
function InventoryService:LoadPlayerInventory(player)
    if not player or not player:IsA("Player") then return nil end
    
    local userId = player.UserId
    
    -- Vérifier si DataStore est disponible
    if not InventoryDataStore then
        warn("InventoryService: DataStore non disponible pour le chargement")
        return nil
    end
    
    -- Essayer de charger les données
    local success, result = pcall(function()
        return InventoryDataStore:GetAsync("inventory_" .. userId)
    end)
    
    if success and result then
        -- Vérifier l'intégrité des données
        if type(result) ~= "table" or not result.items then
            warn("InventoryService: Données d'inventaire corrompues pour " .. player.Name)
            return nil
        end
        
        -- Vérifier que les objets existent toujours (au cas où ItemTypes aurait changé)
        local validItems = {}
        
        for slot, item in pairs(result.items) do
            if ItemTypes[item.id] then
                validItems[tonumber(slot)] = item
            else
                warn("InventoryService: Objet inconnu ignoré - " .. tostring(item.id))
            end
        end
        
        result.items = validItems
        
        -- Valider les objets équipés
        local validEquipped = {}
        
        for slot, itemSlot in pairs(result.equipped or {}) do
            if type(itemSlot) == "number" and result.items[itemSlot] then
                validEquipped[slot] = itemSlot
            end
        end
        
        result.equipped = validEquipped
        
        -- S'assurer que maxSlots est défini
        result.maxSlots = result.maxSlots or self.maxInventorySlots
        
        return result
    else
        if not success then
            warn("InventoryService: Erreur lors du chargement des données - " .. tostring(result))
        end
        return nil
    end
end

-- Sauvegarder l'inventaire d'un joueur
function InventoryService:SavePlayerInventory(player, forceImmediate)
    local userId = type(player) == "number" and player or (player and player.UserId)
    
    if not userId then
        warn("InventoryService: ID utilisateur invalide pour la sauvegarde")
        return false
    end
    
    -- Vérifier si l'inventaire existe
    if not self.playerInventories[userId] then
        return false
    end
    
    -- Marquer comme en attente de sauvegarde
    self.pendingSaves[userId] = true
    
    -- Si forceImmediate est vrai ou DataStore n'est pas disponible, sauvegarder maintenant
    if forceImmediate or not InventoryDataStore then
        return self:ProcessSave(userId)
    end
    
    -- Sinon, laisser la sauvegarde planifiée s'exécuter
    return true
end

-- Traiter la sauvegarde effective
function InventoryService:ProcessSave(userId)
    -- Vérifier si DataStore est disponible
    if not InventoryDataStore then
        warn("InventoryService: DataStore non disponible pour la sauvegarde")
        return false
    end
    
    -- Vérifier si l'inventaire existe
    if not self.playerInventories[userId] then
        self.pendingSaves[userId] = nil
        return false
    end
    
    -- Créer une copie des données à sauvegarder
    local inventoryData = table.clone(self.playerInventories[userId])
    
    -- Tentatives de sauvegarde avec rétention
    local attempts = 0
    local success = false
    
    while not success and attempts < self.saveRetryLimit do
        attempts = attempts + 1
        
        success, errorMessage = pcall(function()
            InventoryDataStore:SetAsync("inventory_" .. userId, inventoryData)
        end)
        
        if not success then
            warn("InventoryService: Tentative de sauvegarde " .. attempts .. " échouée - " .. tostring(errorMessage))
            wait(1) -- Attendre avant de réessayer
        end
    end
    
    -- Nettoyer le marqueur de sauvegarde en attente
    self.pendingSaves[userId] = nil
    
    -- Mettre à jour le temps de dernière sauvegarde
    if success then
        self.lastSaveTime[userId] = os.time()
        return true
    else
        warn("InventoryService: Échec définitif de la sauvegarde pour l'utilisateur " .. userId .. " après " .. attempts .. " tentatives")
        return false
    end
end

-- Ajouter un objet à l'inventaire
function InventoryService:AddItemToInventory(player, itemId, quantity)
    if not player or not player:IsA("Player") then
        warn("InventoryService: Joueur invalide pour l'ajout d'objet")
        return false
    end
    
    local userId = player.UserId
    local inventory = self.playerInventories[userId]
    
    if not inventory then
        warn("InventoryService: Inventaire non initialisé pour " .. player.Name)
        return false
    end
    
    -- Vérifier si l'objet existe dans ItemTypes
    local itemType = ItemTypes[itemId]
    if not itemType then
        warn("InventoryService: Type d'objet invalide - " .. tostring(itemId))
        return false
    end
    
    -- Valider la quantité
    quantity = math.floor(tonumber(quantity) or 1)
    if quantity <= 0 then return false end
    
    -- Déterminer si l'objet est empilable et la taille max de pile
    local isStackable = itemType.stackable or false
    local maxStack = itemType.maxStack or self.defaultMaxStackSize
    
    -- Stratégie d'ajout
    if isStackable then
        -- Essayer d'abord d'empiler avec des objets existants du même type
        local remainingQuantity = quantity
        
        for slot, item in pairs(inventory.items) do
            if remainingQuantity <= 0 then break end
            
            if item.id == itemId and item.quantity < maxStack then
                local spaceInStack = maxStack - item.quantity
                local amountToAdd = math.min(spaceInStack, remainingQuantity)
                
                inventory.items[slot].quantity = item.quantity + amountToAdd
                remainingQuantity = remainingQuantity - amountToAdd
            end
        end
        
        -- S'il reste des objets à ajouter, chercher des emplacements vides
        while remainingQuantity > 0 do
            local emptySlot = self:FindEmptySlot(inventory)
            
            if not emptySlot then
                -- Inventaire plein, notifier le joueur
                self:SendNotification(player, "Inventaire plein!", "warning")
                
                -- Actualiser l'inventaire pour refléter ce qui a pu être ajouté
                self:UpdateClientInventory(player)
                
                return quantity > remainingQuantity -- True si au moins un objet a été ajouté
            end
            
            -- Ajouter une nouvelle pile
            local amountToAdd = math.min(remainingQuantity, maxStack)
            
            inventory.items[emptySlot] = {
                id = itemId,
                quantity = amountToAdd,
                data = {} -- Données supplémentaires (durabilité, etc.)
            }
            
            -- Si l'objet a une durabilité, l'initialiser
            if itemType.durability then
                inventory.items[emptySlot].data.durability = itemType.durability
            end
            
            remainingQuantity = remainingQuantity - amountToAdd
        end
    else
        -- Objets non empilables - un emplacement par objet
        for i = 1, quantity do
            local emptySlot = self:FindEmptySlot(inventory)
            
            if not emptySlot then
                -- Inventaire plein
                self:SendNotification(player, "Inventaire plein!", "warning")
                
                -- Actualiser l'inventaire pour refléter ce qui a pu être ajouté
                self:UpdateClientInventory(player)
                
                return i > 1 -- True si au moins un objet a été ajouté
            end
            
            -- Ajouter l'objet
            inventory.items[emptySlot] = {
                id = itemId,
                quantity = 1,
                data = {} -- Données supplémentaires
            }
            
            -- Si l'objet a une durabilité, l'initialiser
            if itemType.durability then
                inventory.items[emptySlot].data.durability = itemType.durability
            end
        end
    end
    
    -- Mettre à jour l'inventaire du client
    self:UpdateClientInventory(player)
    
    -- Marquer l'inventaire pour sauvegarde différée
    self:ScheduleInventorySave(userId)
    
    return true
end

-- Trouver un emplacement vide dans l'inventaire
function InventoryService:FindEmptySlot(inventory)
    for i = 1, inventory.maxSlots do
        if not inventory.items[i] then
            return i
        end
    end
    return nil
end

-- Retirer un objet de l'inventaire
function InventoryService:RemoveItemFromInventory(player, itemId, quantity)
    if not player or not player:IsA("Player") then return false end
    
    local userId = player.UserId
    local inventory = self.playerInventories[userId]
    
    if not inventory then return false end
    
    -- Valider la quantité
    quantity = math.floor(tonumber(quantity) or 1)
    if quantity <= 0 then return false end
    
    local remainingToRemove = quantity
    local removedSlots = {}
    
    -- Parcourir l'inventaire pour trouver des objets correspondants
    for slot, item in pairs(inventory.items) do
        if item.id == itemId and remainingToRemove > 0 then
            if item.quantity > remainingToRemove then
                -- Réduire la quantité
                inventory.items[slot].quantity = item.quantity - remainingToRemove
                remainingToRemove = 0
                break
            else
                -- Mémoriser l'emplacement pour le supprimer après
                remainingToRemove = remainingToRemove - item.quantity
                table.insert(removedSlots, slot)
            end
        end
    end
    
    -- Supprimer les emplacements identifiés
    for _, slot in ipairs(removedSlots) do
        inventory.items[slot] = nil
        
        -- Vérifier si c'était un objet équipé et le déséquiper
        for equipSlot, slotNumber in pairs(inventory.equipped) do
            if slotNumber == slot then
                inventory.equipped[equipSlot] = nil
            end
        end
    end
    
    -- Mise à jour du client seulement si des objets ont été retirés
    if remainingToRemove < quantity then
        self:UpdateClientInventory(player)
        
        -- Marquer l'inventaire pour sauvegarde différée
        self:ScheduleInventorySave(userId)
        
        return true
    end
    
    return false
end

-- Vérifier si un joueur a un certain objet
function InventoryService:HasItemInInventory(player, itemId, quantity)
    if not player or not player:IsA("Player") then return false end
    
    local userId = player.UserId
    local inventory = self.playerInventories[userId]
    
    if not inventory then return false end
    
    -- Valider la quantité
    quantity = math.floor(tonumber(quantity) or 1)
    if quantity <= 0 then return true end -- 0 requis = toujours vrai
    
    local totalFound = 0
    
    -- Compter tous les objets correspondants
    for _, item in pairs(inventory.items) do
        if item.id == itemId then
            totalFound = totalFound + (item.quantity or 1)
            if totalFound >= quantity then
                return true
            end
        end
    end
    
    return false
end

-- Compter le nombre d'un item donné dans l'inventaire
function InventoryService:CountItemsInInventory(player, itemId)
    if not player or not player:IsA("Player") then return 0 end
    
    local userId = player.UserId
    local inventory = self.playerInventories[userId]
    
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
    if not player or not player:IsA("Player") then return false end
    
    local userId = player.UserId
    local inventory = self.playerInventories[userId]
    
    if not inventory or not inventory.items[slotNumber] then
        return false
    end
    
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
    
    -- Mettre à jour le client
    self:UpdateClientInventory(player)
    
    -- Marquer l'inventaire pour sauvegarde différée
    self:ScheduleInventorySave(userId)
    
    return true
end

-- Déséquiper un objet
function InventoryService:UnequipItem(player, equipSlot)
    if not player or not player:IsA("Player") then return false end
    
    local userId = player.UserId
    local inventory = self.playerInventories[userId]
    
    if not inventory or not inventory.equipped[equipSlot] then
        return false
    end
    
    -- Supprimer la référence d'équipement
    inventory.equipped[equipSlot] = nil
    
    -- Mettre à jour le client
    self:UpdateClientInventory(player)
    
    -- Marquer l'inventaire pour sauvegarde différée
    self:ScheduleInventorySave(userId)
    
    return true
end

-- Déplacer un objet d'un emplacement à un autre
function InventoryService:MoveItem(player, fromSlot, toSlot)
    if not player or not player:IsA("Player") then return false end
    
    local userId = player.UserId
    local inventory = self.playerInventories[userId]
    
    if not inventory then return false end
    
    -- Vérifier que les emplacements sont valides
    if not fromSlot or not inventory.items[fromSlot] then return false end
    if not toSlot or toSlot < 1 or toSlot > inventory.maxSlots then return false end
    
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
    elseif fromItem.id == toItem.id and ItemTypes[fromItem.id] and ItemTypes[fromItem.id].stackable then
        local maxStack = ItemTypes[fromItem.id].maxStack or self.defaultMaxStackSize
        
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
    
    -- Mettre à jour le client
    self:UpdateClientInventory(player)
    
    -- Marquer l'inventaire pour sauvegarde différée
    self:ScheduleInventorySave(userId)
    
    return true
end

-- Utiliser un objet
function InventoryService:UseItem(player, slotNumber)
    if not player or not player:IsA("Player") then return false end
    
    local userId = player.UserId
    local inventory = self.playerInventories[userId]
    
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
        
        -- Envoyer l'action au serveur
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events then
            local playerActionEvent = events:FindFirstChild("PlayerAction")
            if playerActionEvent then
                -- Déclencher l'action de consommation
                playerActionEvent:FireServer("use_item", slotNumber, item.id)
                consumed = true
            end
        end
        
        -- Si consommé, réduire la quantité ou supprimer l'objet
        -- Note: La consommation effective et la mise à jour seront gérées par le serveur
        return consumed
    elseif itemType.placeable then
        -- Placer dans le monde (bâtiment, meuble, etc.)
        local events = ReplicatedStorage:FindFirstChild("Events")
        if events then
            local playerActionEvent = events:FindFirstChild("PlayerAction")
            if playerActionEvent then
                -- Déclencher l'action de placement
                playerActionEvent:FireServer("use_item", slotNumber, item.id)
                return true
            end
        end
    end
    
    return false
end

-- Augmenter la capacité de l'inventaire
function InventoryService:IncreaseInventoryCapacity(player, additionalSlots)
    if not player or not player:IsA("Player") then return false end
    
    local userId = player.UserId
    local inventory = self.playerInventories[userId]
    
    if not inventory then return false end
    
    -- Vérifier que l'augmentation est positive
    additionalSlots = math.floor(tonumber(additionalSlots) or 0)
    if additionalSlots <= 0 then return false end
    
    -- Mettre à jour la capacité maximale
    inventory.maxSlots = inventory.maxSlots + additionalSlots
    
    -- Mettre à jour le client
    self:UpdateClientInventory(player)
    
    -- Marquer l'inventaire pour sauvegarde différée
    self:ScheduleInventorySave(userId)
    
    return true
end

-- Mettre à jour l'inventaire du client
function InventoryService:UpdateClientInventory(player)
    if not player or not player:IsA("Player") then return end
    
    local userId = player.UserId
    local inventory = self.playerInventories[userId]
    
    if not inventory then return end
    
    -- Envoyer les données d'inventaire au client
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events and events:FindFirstChild("UpdateInventory") then
        events.UpdateInventory:FireClient(player, inventory)
    end
end

-- Envoyer une notification au joueur
function InventoryService:SendNotification(player, message, messageType)
    if not player or not player:IsA("Player") then return end
    
    -- Envoyer via RemoteEvent si disponible
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events and events:FindFirstChild("Notification") then
        events.Notification:FireClient(player, message, messageType or "info")
    else
        -- Fallback si le RemoteEvent n'est pas disponible
        print("Notification pour " .. player.Name .. ": " .. message)
    end
end

-- Programmer une sauvegarde différée de l'inventaire
function InventoryService:ScheduleInventorySave(userId)
    self.pendingSaves[userId] = true
end

-- Nettoyer les objets périmés
function InventoryService:CleanupExpiredItems()
    local currentTime = os.time()
    
    for userId, inventory in pairs(self.playerInventories) do
        local player = Players:GetPlayerByUserId(userId)
        if player then
            local itemsChanged = false
            
            -- Vérifier chaque objet pour voir s'il a expiré
            for slot, item in pairs(inventory.items) do
                if item.data and item.data.expiryTime and item.data.expiryTime < currentTime then
                    -- Supprimer l'objet expiré
                    inventory.items[slot] = nil
                    itemsChanged = true
                    
                    -- Vérifier si c'était un objet équipé et le déséquiper
                    for equipSlot, slotNumber in pairs(inventory.equipped) do
                        if slotNumber == slot then
                            inventory.equipped[equipSlot] = nil
                        end
                    end
                    
                    -- Notifier le joueur
                    self:SendNotification(player, "Un objet dans votre inventaire s'est dégradé.", "warning")
                end
            end
            
            -- Mettre à jour l'interface si des objets ont été supprimés
            if itemsChanged then
                self:UpdateClientInventory(player)
                
                -- Marquer l'inventaire pour sauvegarde différée
                self:ScheduleInventorySave(userId)
            end
        end
    end
end

-- Gérer la déconnexion d'un joueur
function InventoryService:HandlePlayerRemoving(player)
    if not player or not player:IsA("Player") then return end
    
    local userId = player.UserId
    
    -- Sauvegarder l'inventaire avant la déconnexion (forcer immédiat)
    self:SavePlayerInventory(player, true)
    
    -- Nettoyer les références
    self.playerInventories[userId] = nil
    self.lastSaveTime[userId] = nil
    self.pendingSaves[userId] = nil
    
    print("InventoryService: Données d'inventaire nettoyées pour " .. player.Name)
end

-- Démarrer le service
function InventoryService:Start(services)
    print("InventoryService: Démarrage...")
    
    -- Configurer les RemoteEvents
    self:SetupRemoteEvents()
    
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
    
    -- Démarrer la sauvegarde périodique des inventaires en attente
    spawn(function()
        while true do
            wait(30) -- Vérifier toutes les 30 secondes
            
            for userId, isPending in pairs(self.pendingSaves) do
                if isPending then
                    -- Vérifier le dernier temps de sauvegarde
                    local lastSave = self.lastSaveTime[userId] or 0
                    local currentTime = os.time()
                    
                    -- Sauvegarder si l'intervalle s'est écoulé
                    if currentTime - lastSave >= self.saveInterval then
                        pcall(function()
                            self:ProcessSave(userId)
                        end)
                    end
                end
            end
        end
    end)
    
    -- Marquer le service comme initialisé
    self.isInitialized = true
    
    print("InventoryService: Démarré avec succès")
    return self
end

-- Configurer les RemoteEvents
function InventoryService:SetupRemoteEvents()
    local events = ReplicatedStorage:FindFirstChild("Events")
    
    if not events then
        events = Instance.new("Folder")
        events.Name = "Events"
        events.Parent = ReplicatedStorage
        print("InventoryService: Dossier Events créé dans ReplicatedStorage")
    end
    
    -- Créer les RemoteEvents nécessaires s'ils n'existent pas
    local requiredEvents = {
        "UpdateInventory",
        "Notification",
        "PlayerAction"
    }
    
    for _, eventName in ipairs(requiredEvents) do
        if not events:FindFirstChild(eventName) then
            local event = Instance.new("RemoteEvent")
            event.Name = eventName
            event.Parent = events
            print("InventoryService: RemoteEvent créé - " .. eventName)
        end
    end
    
    -- Stocker les références
    self.remoteEvents = {
        UpdateInventory = events:FindFirstChild("UpdateInventory"),
        Notification = events:FindFirstChild("Notification"),
        PlayerAction = events:FindFirstChild("PlayerAction")
    }
end

return InventoryService
