-- src/server/services/TribeService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared.constants.GameSettings)

-- Services
local Server = ServerScriptService:WaitForChild("Server")
local Services = Server:WaitForChild("services")
local PlayerService -- Sera initialisé dans Start()
local InventoryService -- Sera initialisé dans Start()

-- DataStore pour sauvegarder les données des tribus
local TribesDataStore = DataStoreService:GetDataStore("Tribes_v1")

local TribeService = {}
TribeService.__index = TribeService

-- Définir les rôles dans une tribu
local TRIBE_ROLES = {
    LEADER = "leader",      -- Fondateur, peut tout faire
    ELDER = "elder",        -- Peut ajouter/retirer des membres, construire
    MEMBER = "member",      -- Peut construire dans le territoire
    NOVICE = "novice"       -- Nouveau membre, accès limité
}

function TribeService.new()
    local self = setmetatable({}, TribeService)
    
    -- Liste des tribus
    self.tribes = {}
    
    -- Associations joueur-tribu
    self.playerTribes = {}  -- [userId] = tribeId
    
    -- Constantes
    self.maxTribesPerPlayer = 1  -- Un joueur ne peut créer/diriger qu'une tribu
    self.maxMembersPerTribe = GameSettings.Tribe.maxMembers or 20
    self.minTribeName = 3
    self.maxTribeName = 20
    self.territoryRadius = 100  -- Rayon du territoire d'une tribu en unités
    
    return self
end

-- Rétrograder un membre de la tribu
function TribeService:DemoteMember(player, targetUserId)
    local userId = player.UserId
    
    -- Vérifier si le joueur est dans une tribu
    local tribeId = self.playerTribes[userId]
    if not tribeId then
        self:SendTribeActionResponse(player, "demote_member", false, "Vous n'êtes pas membre d'une tribu")
        return
    end
    
    local tribe = self.tribes[tribeId]
    if not tribe then
        self:SendTribeActionResponse(player, "demote_member", false, "Votre tribu est introuvable")
        return
    end
    
    -- Vérifier si le joueur est le chef de la tribu
    local isLeader = false
    for _, member in ipairs(tribe.members) do
        if member.userId == userId and member.role == TRIBE_ROLES.LEADER then
            isLeader = true
            break
        end
    end
    
    if not isLeader then
        self:SendTribeActionResponse(player, "demote_member", false, "Seul le chef de la tribu peut rétrograder des membres")
        return
    end
    
    -- Vérifier si la cible est membre de la tribu
    local targetMemberIndex = nil
    local targetMemberRole = nil
    local targetMemberName = nil
    for i, member in ipairs(tribe.members) do
        if member.userId == targetUserId then
            targetMemberIndex = i
            targetMemberRole = member.role
            targetMemberName = member.name
            break
        end
    end
    
    if not targetMemberIndex then
        self:SendTribeActionResponse(player, "demote_member", false, "Ce joueur n'est pas membre de votre tribu")
        return
    end
    
    -- Ne pas pouvoir rétrograder le chef (soi-même)
    if targetMemberRole == TRIBE_ROLES.LEADER then
        self:SendTribeActionResponse(player, "demote_member", false, "Vous ne pouvez pas rétrograder le chef de la tribu")
        return
    end
    
    -- Gérer la rétrogradation selon le rôle actuel
    if targetMemberRole == TRIBE_ROLES.ELDER then
        -- Rétrograder d'ancien à membre
        tribe.members[targetMemberIndex].role = TRIBE_ROLES.MEMBER
        
        -- Ajouter un événement au journal
        table.insert(tribe.log, {
            type = "member_demoted",
            time = os.time(),
            demoter = userId,
            target = targetUserId,
            fromRole = TRIBE_ROLES.ELDER,
            toRole = TRIBE_ROLES.MEMBER,
            description = player.Name .. " a rétrogradé " .. targetMemberName .. " au rang de Membre"
        })
        
    elseif targetMemberRole == TRIBE_ROLES.MEMBER then
        -- Rétrograder de membre à novice
        tribe.members[targetMemberIndex].role = TRIBE_ROLES.NOVICE
        
        -- Ajouter un événement au journal
        table.insert(tribe.log, {
            type = "member_demoted",
            time = os.time(),
            demoter = userId,
            target = targetUserId,
            fromRole = TRIBE_ROLES.MEMBER,
            toRole = TRIBE_ROLES.NOVICE,
            description = player.Name .. " a rétrogradé " .. targetMemberName .. " au rang de Novice"
        })
        
    elseif targetMemberRole == TRIBE_ROLES.NOVICE then
        -- Ne peut pas rétrograder davantage un novice
        self:SendTribeActionResponse(player, "demote_member", false, "Ce membre est déjà un Novice et ne peut pas être rétrogradé davantage")
        return
    end
    
    -- Sauvegarder les données
    self:SaveTribeData(tribeId)
    
    -- Envoyer une réponse au joueur
    self:SendTribeActionResponse(player, "demote_member", true, "Vous avez rétrogradé " .. targetMemberName)
    
    -- Notifier le joueur cible s'il est en ligne
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if targetPlayer then
        self:SendTribeActionResponse(targetPlayer, "demoted", true, "Vous avez été rétrogradé dans votre tribu")
    end
    
    -- Notifier tous les membres de la tribu
    self:NotifyTribeUpdate(tribeId)
    
    print("TribeService: " .. player.Name .. " a rétrogradé " .. targetMemberName)
end

-- Modifier la description de la tribu
function TribeService:SetTribeDescription(player, newDescription)
    local userId = player.UserId
    
    -- Vérifier si le joueur est dans une tribu
    local tribeId = self.playerTribes[userId]
    if not tribeId then
        self:SendTribeActionResponse(player, "set_tribe_description", false, "Vous n'êtes pas membre d'une tribu")
        return
    end
    
    local tribe = self.tribes[tribeId]
    if not tribe then
        self:SendTribeActionResponse(player, "set_tribe_description", false, "Votre tribu est introuvable")
        return
    end
    
    -- Vérifier si le joueur a les permissions (chef ou ancien)
    local hasPermission = false
    for _, member in ipairs(tribe.members) do
        if member.userId == userId and (member.role == TRIBE_ROLES.LEADER or member.role == TRIBE_ROLES.ELDER) then
            hasPermission = true
            break
        end
    end
    
    if not hasPermission then
        self:SendTribeActionResponse(player, "set_tribe_description", false, "Vous n'avez pas la permission de modifier la description de la tribu")
        return
    end
    
    -- Nettoyer et valider la description
    newDescription = newDescription or ""
    if type(newDescription) ~= "string" then
        newDescription = ""
    end
    
    -- Limiter la taille de la description
    if #newDescription > 500 then
        newDescription = string.sub(newDescription, 1, 500)
    end
    
    -- Sauvegarder l'ancienne description pour le journal
    local oldDescription = tribe.description
    
    -- Mettre à jour la description
    tribe.description = newDescription
    
    -- Ajouter un événement au journal
    table.insert(tribe.log, {
        type = "description_changed",
        time = os.time(),
        userId = userId,
        description = player.Name .. " a modifié la description de la tribu"
    })
    
    -- Sauvegarder les données
    self:SaveTribeData(tribeId)
    
    -- Envoyer une réponse au joueur
    self:SendTribeActionResponse(player, "set_tribe_description", true, "Description de la tribu mise à jour")
    
    -- Notifier tous les membres de la tribu
    self:NotifyTribeUpdate(tribeId)
    
    print("TribeService: " .. player.Name .. " a modifié la description de la tribu " .. tribe.name)
end

-- Définir le territoire de la tribu
function TribeService:SetTribeTerritory(player, centerPosition)
    local userId = player.UserId
    
    -- Vérifier si le joueur est dans une tribu
    local tribeId = self.playerTribes[userId]
    if not tribeId then
        self:SendTribeActionResponse(player, "set_tribe_territory", false, "Vous n'êtes pas membre d'une tribu")
        return
    end
    
    local tribe = self.tribes[tribeId]
    if not tribe then
        self:SendTribeActionResponse(player, "set_tribe_territory", false, "Votre tribu est introuvable")
        return
    end
    
    -- Vérifier si le joueur est le chef de la tribu
    local isLeader = false
    for _, member in ipairs(tribe.members) do
        if member.userId == userId and member.role == TRIBE_ROLES.LEADER then
            isLeader = true
            break
        end
    end
    
    if not isLeader then
        self:SendTribeActionResponse(player, "set_tribe_territory", false, "Seul le chef de la tribu peut définir le territoire")
        return
    end
    
    -- Vérifier si la position est valide
    if typeof(centerPosition) ~= "Vector3" then
        self:SendTribeActionResponse(player, "set_tribe_territory", false, "Position invalide")
        return
    end
    
    -- Vérifier si le joueur est proche de la position
    local character = player.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        self:SendTribeActionResponse(player, "set_tribe_territory", false, "Impossible de déterminer votre position")
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local distance = (rootPart.Position - centerPosition).Magnitude
    
    if distance > 10 then  -- Le joueur doit être à moins de 10 unités de la position
        self:SendTribeActionResponse(player, "set_tribe_territory", false, "Vous devez être proche de l'emplacement choisi")
        return
    end
    
    -- Vérifier si le territoire n'est pas trop proche d'un autre territoire de tribu
    local minDistanceBetweenTerritories = 200  -- 200 unités de distance minimale
    
    for otherTribeId, otherTribe in pairs(self.tribes) do
        if otherTribeId ~= tribeId and otherTribe.territory and otherTribe.territory.center then
            local otherCenter = otherTribe.territory.center
            local distanceBetweenTerritories = (Vector3.new(otherCenter.x, otherCenter.y, otherCenter.z) - centerPosition).Magnitude
            
            if distanceBetweenTerritories < minDistanceBetweenTerritories then
                self:SendTribeActionResponse(player, "set_tribe_territory", false, "Cet emplacement est trop proche du territoire d'une autre tribu")
                return
            end
        end
    end
    
    -- Mettre à jour le territoire de la tribu
    tribe.territory.center = {
        x = centerPosition.X,
        y = centerPosition.Y,
        z = centerPosition.Z
    }
    
    -- Ajouter un événement au journal
    table.insert(tribe.log, {
        type = "territory_set",
        time = os.time(),
        userId = userId,
        description = player.Name .. " a défini le territoire de la tribu"
    })
    
    -- Sauvegarder les données
    self:SaveTribeData(tribeId)
    
    -- Envoyer une réponse au joueur
    self:SendTribeActionResponse(player, "set_tribe_territory", true, "Territoire de la tribu défini")
    
    -- Notifier tous les membres de la tribu
    self:NotifyTribeUpdate(tribeId)
    
    print("TribeService: " .. player.Name .. " a défini le territoire de la tribu " .. tribe.name)
end

-- Obtenir les données d'une tribu
function TribeService:GetTribeData(tribeId)
    return self.tribes[tribeId]
end

-- Obtenir l'ID de la tribu d'un joueur
function TribeService:GetPlayerTribeId(player)
    local userId = typeof(player) == "number" and player or player.UserId
    return self.playerTribes[userId]
end

-- Obtenir le rôle d'un joueur dans sa tribu
function TribeService:GetPlayerRole(player)
    local userId = typeof(player) == "number" and player or player.UserId
    local tribeId = self.playerTribes[userId]
    
    if not tribeId or not self.tribes[tribeId] then
        return nil
    end
    
    for _, member in ipairs(self.tribes[tribeId].members) do
        if member.userId == userId then
            return member.role
        end
    end
    
    return nil
end

-- Vérifier si un joueur est dans la même tribu qu'un autre
function TribeService:ArePlayersInSameTribe(player1, player2)
    local userId1 = typeof(player1) == "number" and player1 or player1.UserId
    local userId2 = typeof(player2) == "number" and player2 or player2.UserId
    
    local tribeId1 = self.playerTribes[userId1]
    local tribeId2 = self.playerTribes[userId2]
    
    return tribeId1 and tribeId2 and tribeId1 == tribeId2
end

-- Notifier un joueur des informations de sa tribu
function TribeService:NotifyPlayerTribeUpdate(player)
    local userId = player.UserId
    local tribeId = self.playerTribes[userId]
    
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then return end
    
    local tribeUpdateEvent = events:FindFirstChild("TribeUpdate")
    if not tribeUpdateEvent then return end
    
    -- Préparer les données à envoyer
    local updateData = nil
    
    if tribeId and self.tribes[tribeId] then
        -- Le joueur est dans une tribu, envoyer les infos basiques
        updateData = {
            inTribe = true,
            tribeId = tribeId,
            tribeName = self.tribes[tribeId].name,
            tribeDescription = self.tribes[tribeId].description,
            memberCount = #self.tribes[tribeId].members,
            role = self:GetPlayerRole(player)
        }
    else
        -- Le joueur n'est pas dans une tribu
        updateData = {
            inTribe = false
        }
    end
    
    -- Envoyer les données au client
    tribeUpdateEvent:FireClient(player, "player_tribe_update", updateData)
end

-- Notifier tous les membres d'une tribu
function TribeService:NotifyTribeUpdate(tribeId)
    local tribe = self.tribes[tribeId]
    if not tribe then return end
    
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then return end
    
    local tribeUpdateEvent = events:FindFirstChild("TribeUpdate")
    if not tribeUpdateEvent then return end
    
    -- Préparer les données détaillées
    local detailedData = {
        id = tribeId,
        name = tribe.name,
        description = tribe.description,
        founder = tribe.founder,
        creationTime = tribe.creationTime,
        territory = tribe.territory,
        members = {},
        log = tribe.log
    }
    
    -- N'inclure que les informations pertinentes sur les membres
    for _, member in ipairs(tribe.members) do
        table.insert(detailedData.members, {
            userId = member.userId,
            name = member.name,
            role = member.role,
            joinTime = member.joinTime,
            online = member.online
        })
    end
    
    -- Envoyer les données à tous les membres
    for _, member in ipairs(tribe.members) do
        local memberPlayer = Players:GetPlayerByUserId(member.userId)
        if memberPlayer then
            -- Informations basiques pour tous les membres
            self:NotifyPlayerTribeUpdate(memberPlayer)
            
            -- Informations détaillées
            tribeUpdateEvent:FireClient(memberPlayer, "tribe_details_update", detailedData)
        end
    end
end

-- Envoyer une invitation de tribu à un joueur
function TribeService:SendTribeInvitation(player, tribe, inviterName)
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then return end
    
    local tribeUpdateEvent = events:FindFirstChild("TribeUpdate")
    if not tribeUpdateEvent then return end
    
    -- Préparer les données d'invitation
    local invitationData = {
        tribeId = tribe.id,
        tribeName = tribe.name,
        inviter = inviterName,
        expires = os.time() + 300  -- 5 minutes
    }
    
    -- Envoyer l'invitation
    tribeUpdateEvent:FireClient(player, "invitation", invitationData)
    
    -- Envoyer également une notification
    local notificationEvent = events:FindFirstChild("Notification")
    if notificationEvent then
        notificationEvent:FireClient(player, inviterName .. " vous a invité à rejoindre la tribu " .. tribe.name, "info")
    end
end

-- Envoyer une réponse d'action de tribu à un joueur
function TribeService:SendTribeActionResponse(player, action, success, message, data)
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then return end
    
    local tribeUpdateEvent = events:FindFirstChild("TribeUpdate")
    if not tribeUpdateEvent then return end
    
    -- Préparer la réponse
    local response = {
        action = action,
        success = success,
        message = message,
        data = data
    }
    
    -- Envoyer la réponse
    tribeUpdateEvent:FireClient(player, "action_response", response)
    
    -- Envoyer également une notification
    local notificationEvent = events:FindFirstChild("Notification")
    if notificationEvent then
        notificationEvent:FireClient(player, message, success and "success" or "error")
    end
end

-- Gérer un joueur qui se déconnecte
function TribeService:HandlePlayerRemoving(player)
    local userId = player.UserId
    local tribeId = self.playerTribes[userId]
    
    if not tribeId or not self.tribes[tribeId] then return end
    
    -- Mettre à jour le statut en ligne du membre
    for i, member in ipairs(self.tribes[tribeId].members) do
        if member.userId == userId then
            member.online = false
            break
        end
    end
    
    -- Sauvegarder les données
    self:SaveTribeData(tribeId)
    
    -- Notifier les autres membres de la tribu
    self:NotifyTribeUpdate(tribeId)
end

return TribeService

-- Initialiser le service
function TribeService:Start(services)
    print("TribeService: Démarrage...")
    
    -- Récupérer les références aux autres services
    PlayerService = services.PlayerService
    InventoryService = services.InventoryService
    
    -- Configurer les événements RemoteEvent pour les tribus
    self:SetupRemoteEvents()
    
    -- Écouter les événements de joueur
    Players.PlayerAdded:Connect(function(player)
        self:LoadPlayerTribeData(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
    
    print("TribeService: Démarré avec succès")
    return self
end

-- Configurer les événements RemoteEvent pour les tribus
function TribeService:SetupRemoteEvents()
    local events = ReplicatedStorage:FindFirstChild("Events")
    
    if not events then
        events = Instance.new("Folder")
        events.Name = "Events"
        events.Parent = ReplicatedStorage
    end
    
    -- Créer l'événement pour les actions de tribu
    local tribeActionEvent = events:FindFirstChild("TribeAction")
    if not tribeActionEvent then
        tribeActionEvent = Instance.new("RemoteEvent")
        tribeActionEvent.Name = "TribeAction"
        tribeActionEvent.Parent = events
    end
    
    -- Connecter l'événement aux fonctions de traitement
    tribeActionEvent.OnServerEvent:Connect(function(player, action, ...)
        self:HandleTribeAction(player, action, ...)
    end)
    
    -- Créer l'événement pour notifier les clients des changements de tribu
    local tribeUpdateEvent = events:FindFirstChild("TribeUpdate")
    if not tribeUpdateEvent then
        tribeUpdateEvent = Instance.new("RemoteEvent")
        tribeUpdateEvent.Name = "TribeUpdate"
        tribeUpdateEvent.Parent = events
    end
end

-- Charger les données de tribu pour un joueur
function TribeService:LoadPlayerTribeData(player)
    local userId = player.UserId
    
    -- Vérifier si le joueur est déjà dans une tribu
    spawn(function()
        local success, tribeId = pcall(function()
            return TribesDataStore:GetAsync("Player_" .. userId)
        end)
        
        if success and tribeId then
            -- Vérifier si la tribu existe dans la mémoire
            if not self.tribes[tribeId] then
                -- Charger les données de la tribu
                self:LoadTribeData(tribeId)
            end
            
            -- Associer le joueur à sa tribu
            self.playerTribes[userId] = tribeId
            
            -- Mettre à jour le statut "en ligne" du membre
            if self.tribes[tribeId] then
                for i, member in ipairs(self.tribes[tribeId].members) do
                    if member.userId == userId then
                        member.online = true
                        break
                    end
                end
                
                -- Notifier tous les membres de la tribu
                self:NotifyTribeUpdate(tribeId)
            end
        end
    end)
end

-- Charger les données d'une tribu
function TribeService:LoadTribeData(tribeId)
    spawn(function()
        local success, tribeData = pcall(function()
            return TribesDataStore:GetAsync("Tribe_" .. tribeId)
        end)
        
        if success and tribeData then
            -- Créer la structure de données de la tribu en mémoire
            self.tribes[tribeId] = tribeData
            
            -- Mettre à jour le statut en ligne des membres
            for i, member in ipairs(tribeData.members) do
                local memberPlayer = Players:GetPlayerByUserId(member.userId)
                member.online = memberPlayer ~= nil
            end
            
            print("TribeService: Tribu chargée - " .. tribeData.name)
        else
            warn("TribeService: Échec du chargement de la tribu " .. tribeId)
        end
    end)
end

-- Sauvegarder les données d'une tribu
function TribeService:SaveTribeData(tribeId)
    local tribeData = self.tribes[tribeId]
    if not tribeData then return end
    
    spawn(function()
        local success, err = pcall(function()
            TribesDataStore:SetAsync("Tribe_" .. tribeId, tribeData)
        end)
        
        if not success then
            warn("TribeService: Échec de la sauvegarde de la tribu " .. tribeId .. " - " .. tostring(err))
        end
    end)
end

-- Sauvegarder l'association joueur-tribu
function TribeService:SavePlayerTribeAssociation(userId, tribeId)
    spawn(function()
        local success, err = pcall(function()
            if tribeId then
                TribesDataStore:SetAsync("Player_" .. userId, tribeId)
            else
                TribesDataStore:RemoveAsync("Player_" .. userId)
            end
        end)
        
        if not success then
            warn("TribeService: Échec de la sauvegarde de l'association joueur-tribu pour " .. userId .. " - " .. tostring(err))
        end
    end)
end

-- Gérer les actions de tribu
function TribeService:HandleTribeAction(player, action, ...)
    local args = {...}
    
    if action == "create_tribe" then
        self:CreateTribe(player, args[1], args[2])  -- Nom, description
    elseif action == "join_tribe" then
        self:JoinTribe(player, args[1])  -- ID de la tribu
    elseif action == "leave_tribe" then
        self:LeaveTribe(player)
    elseif action == "invite_player" then
        self:InvitePlayerToTribe(player, args[1])  -- UserId du joueur à inviter
    elseif action == "kick_member" then
        self:KickMemberFromTribe(player, args[1])  -- UserId du membre à expulser
    elseif action == "promote_member" then
        self:PromoteMember(player, args[1])  -- UserId du membre à promouvoir
    elseif action == "demote_member" then
        self:DemoteMember(player, args[1])  -- UserId du membre à rétrograder
    elseif action == "set_tribe_description" then
        self:SetTribeDescription(player, args[1])  -- Nouvelle description
    elseif action == "set_tribe_territory" then
        self:SetTribeTerritory(player, args[1])  -- Position du centre du territoire
    end
end

-- Créer une nouvelle tribu
function TribeService:CreateTribe(player, tribeName, description)
    local userId = player.UserId
    
    -- Vérifier si le joueur est déjà dans une tribu
    if self.playerTribes[userId] then
        self:SendTribeActionResponse(player, "create_tribe", false, "Vous êtes déjà membre d'une tribu")
        return
    end
    
    -- Vérifier le nom de la tribu
    if not tribeName or type(tribeName) ~= "string" then
        self:SendTribeActionResponse(player, "create_tribe", false, "Nom de tribu invalide")
        return
    end
    
    tribeName = string.gsub(tribeName, "^%s*(.-)%s*$", "%1")  -- Trim
    
    if #tribeName < self.minTribeName or #tribeName > self.maxTribeName then
        self:SendTribeActionResponse(player, "create_tribe", false, "Le nom de la tribu doit contenir entre " .. self.minTribeName .. " et " .. self.maxTribeName .. " caractères")
        return
    end
    
    -- Vérifier la description
    description = description or ""
    if type(description) ~= "string" then
        description = ""
    end
    
    -- Vérifier si le joueur a les ressources nécessaires pour créer une tribu
    local creationCost = GameSettings.Tribe.creationCost
    if creationCost then
        for itemId, quantity in pairs(creationCost) do
            if not InventoryService:HasItemInInventory(player, itemId, quantity) then
                self:SendTribeActionResponse(player, "create_tribe", false, "Ressources insuffisantes pour créer une tribu")
                return
            end
        end
        
        -- Retirer les ressources
        for itemId, quantity in pairs(creationCost) do
            InventoryService:RemoveItemFromInventory(player, itemId, quantity)
        end
    end
    
    -- Créer un ID unique pour la tribu
    local tribeId = "tribe_" .. game:GetService("HttpService"):GenerateGUID(false)
    
    -- Créer la tribu
    local newTribe = {
        id = tribeId,
        name = tribeName,
        description = description,
        founder = userId,
        creationTime = os.time(),
        members = {
            {
                userId = userId,
                name = player.Name,
                role = TRIBE_ROLES.LEADER,
                joinTime = os.time(),
                online = true
            }
        },
        territory = {
            center = nil,  -- Sera défini plus tard
            radius = self.territoryRadius
        },
        buildings = {},  -- Liste des bâtiments de la tribu
        log = {  -- Journal des événements de la tribu
            {
                type = "creation",
                time = os.time(),
                description = "Tribu créée par " .. player.Name
            }
        },
        invites = {}  -- Liste des invitations envoyées
    }
    
    -- Ajouter la tribu à la liste
    self.tribes[tribeId] = newTribe
    
    -- Associer le joueur à la tribu
    self.playerTribes[userId] = tribeId
    
    -- Sauvegarder les données
    self:SaveTribeData(tribeId)
    self:SavePlayerTribeAssociation(userId, tribeId)
    
    -- Envoyer une réponse au joueur
    self:SendTribeActionResponse(player, "create_tribe", true, "Tribu créée avec succès", {
        tribeId = tribeId,
        tribeName = tribeName
    })
    
    print("TribeService: Nouvelle tribu créée - " .. tribeName .. " (" .. tribeId .. ")")
    
    -- Notifier le joueur du changement de tribu
    self:NotifyPlayerTribeUpdate(player)
    
    return tribeId
end

-- Rejoindre une tribu (sur invitation)
function TribeService:JoinTribe(player, tribeId)
    local userId = player.UserId
    
    -- Vérifier si le joueur est déjà dans une tribu
    if self.playerTribes[userId] then
        self:SendTribeActionResponse(player, "join_tribe", false, "Vous êtes déjà membre d'une tribu")
        return
    end
    
    -- Vérifier si la tribu existe
    if not self.tribes[tribeId] then
        self:SendTribeActionResponse(player, "join_tribe", false, "Tribu introuvable")
        return
    end
    
    local tribe = self.tribes[tribeId]
    
    -- Vérifier si le joueur est invité
    local isInvited = false
    for i, invite in ipairs(tribe.invites or {}) do
        if invite.userId == userId and invite.expires > os.time() then
            isInvited = true
            table.remove(tribe.invites, i)
            break
        end
    end
    
    if not isInvited then
        self:SendTribeActionResponse(player, "join_tribe", false, "Vous n'avez pas été invité à rejoindre cette tribu")
        return
    end
    
    -- Vérifier si la tribu n'est pas pleine
    if #tribe.members >= self.maxMembersPerTribe then
        self:SendTribeActionResponse(player, "join_tribe", false, "La tribu a atteint son nombre maximum de membres")
        return
    end
    
    -- Ajouter le joueur à la tribu
    table.insert(tribe.members, {
        userId = userId,
        name = player.Name,
        role = TRIBE_ROLES.NOVICE,
        joinTime = os.time(),
        online = true
    })
    
    -- Ajouter un événement au journal
    table.insert(tribe.log, {
        type = "member_join",
        time = os.time(),
        userId = userId,
        description = player.Name .. " a rejoint la tribu"
    })
    
    -- Associer le joueur à la tribu
    self.playerTribes[userId] = tribeId
    
    -- Sauvegarder les données
    self:SaveTribeData(tribeId)
    self:SavePlayerTribeAssociation(userId, tribeId)
    
    -- Envoyer une réponse au joueur
    self:SendTribeActionResponse(player, "join_tribe", true, "Vous avez rejoint la tribu " .. tribe.name)
    
    -- Notifier tous les membres de la tribu
    self:NotifyTribeUpdate(tribeId)
    
    print("TribeService: " .. player.Name .. " a rejoint la tribu " .. tribe.name)
end

-- Quitter une tribu
function TribeService:LeaveTribe(player)
    local userId = player.UserId
    
    -- Vérifier si le joueur est dans une tribu
    local tribeId = self.playerTribes[userId]
    if not tribeId then
        self:SendTribeActionResponse(player, "leave_tribe", false, "Vous n'êtes pas membre d'une tribu")
        return
    end
    
    local tribe = self.tribes[tribeId]
    if not tribe then
        -- Tribu introuvable, nettoyer l'association
        self.playerTribes[userId] = nil
        self:SavePlayerTribeAssociation(userId, nil)
        self:SendTribeActionResponse(player, "leave_tribe", true, "Vous avez quitté la tribu")
        return
    end
    
    -- Vérifier si le joueur est le fondateur
    local isFounder = (tribe.founder == userId)
    
    -- Trouver l'index du membre
    local memberIndex = nil
    for i, member in ipairs(tribe.members) do
        if member.userId == userId then
            memberIndex = i
            break
        end
    end
    
    if not memberIndex then
        -- Le joueur n'est pas membre, nettoyer l'association
        self.playerTribes[userId] = nil
        self:SavePlayerTribeAssociation(userId, nil)
        self:SendTribeActionResponse(player, "leave_tribe", true, "Vous avez quitté la tribu")
        return
    end
    
    -- Si le joueur est le fondateur et qu'il est le seul membre, dissoudre la tribu
    if isFounder and #tribe.members == 1 then
        -- Dissoudre la tribu
        self:DissolveTribe(tribeId)
        self:SendTribeActionResponse(player, "leave_tribe", true, "Vous avez dissout la tribu " .. tribe.name)
        return
    end
    
    -- Si le joueur est le fondateur, transférer le leadership
    if isFounder then
        -- Trouver le membre ayant le rôle le plus élevé et l'ancienneté la plus grande
        local nextLeaderIndex = nil
        local highestRoleValue = 0
        local longestTime = 0
        
        for i, member in ipairs(tribe.members) do
            if i ~= memberIndex then
                local roleValue = 0
                if member.role == TRIBE_ROLES.ELDER then
                    roleValue = 2
                elseif member.role == TRIBE_ROLES.MEMBER then
                    roleValue = 1
                end
                
                if roleValue > highestRoleValue or (roleValue == highestRoleValue and member.joinTime < longestTime) then
                    highestRoleValue = roleValue
                    longestTime = member.joinTime
                    nextLeaderIndex = i
                end
            end
        end
        
        if nextLeaderIndex then
            -- Transférer le leadership
            tribe.members[nextLeaderIndex].role = TRIBE_ROLES.LEADER
            tribe.founder = tribe.members[nextLeaderIndex].userId
            
            -- Ajouter un événement au journal
            table.insert(tribe.log, {
                type = "leadership_transfer",
                time = os.time(),
                from = userId,
                to = tribe.members[nextLeaderIndex].userId,
                description = player.Name .. " a transféré le leadership à " .. tribe.members[nextLeaderIndex].name
            })
        end
    end
    
    -- Retirer le membre de la tribu
    table.remove(tribe.members, memberIndex)
    
    -- Ajouter un événement au journal
    table.insert(tribe.log, {
        type = "member_leave",
        time = os.time(),
        userId = userId,
        description = player.Name .. " a quitté la tribu"
    })
    
    -- Supprimer l'association du joueur
    self.playerTribes[userId] = nil
    
    -- Sauvegarder les données
    self:SaveTribeData(tribeId)
    self:SavePlayerTribeAssociation(userId, nil)
    
    -- Envoyer une réponse au joueur
    self:SendTribeActionResponse(player, "leave_tribe", true, "Vous avez quitté la tribu " .. tribe.name)
    
    -- Notifier tous les membres de la tribu
    self:NotifyTribeUpdate(tribeId)
    
    -- Notifier le joueur qu'il n'a plus de tribu
    self:NotifyPlayerTribeUpdate(player)
    
    print("TribeService: " .. player.Name .. " a quitté la tribu " .. tribe.name)
end

-- Dissoudre une tribu complètement
function TribeService:DissolveTribe(tribeId)
    local tribe = self.tribes[tribeId]
    if not tribe then return end
    
    -- Retirer tous les membres
    for _, member in ipairs(tribe.members) do
        -- Supprimer l'association du joueur
        self.playerTribes[member.userId] = nil
        
        -- Sauvegarder l'association (ou plutôt la supprimer)
        self:SavePlayerTribeAssociation(member.userId, nil)
        
        -- Notifier le joueur s'il est en ligne
        local memberPlayer = Players:GetPlayerByUserId(member.userId)
        if memberPlayer then
            self:NotifyPlayerTribeUpdate(memberPlayer)
            self:SendTribeActionResponse(memberPlayer, "tribe_dissolved", true, "La tribu " .. tribe.name .. " a été dissoute")
        end
    end
    
    -- Supprimer les données de la tribu
    self.tribes[tribeId] = nil
    
    -- Supprimer du DataStore
    spawn(function()
        pcall(function()
            TribesDataStore:RemoveAsync("Tribe_" .. tribeId)
        end)
    end)
    
    print("TribeService: La tribu " .. tribe.name .. " a été dissoute")
end

-- Inviter un joueur à rejoindre la tribu
function TribeService:InvitePlayerToTribe(player, targetUserId)
    local userId = player.UserId
    
    -- Vérifier si le joueur est dans une tribu
    local tribeId = self.playerTribes[userId]
    if not tribeId then
        self:SendTribeActionResponse(player, "invite_player", false, "Vous n'êtes pas membre d'une tribu")
        return
    end
    
    local tribe = self.tribes[tribeId]
    if not tribe then
        self:SendTribeActionResponse(player, "invite_player", false, "Votre tribu est introuvable")
        return
    end
    
    -- Vérifier si le joueur a le droit d'inviter
    local hasPermission = false
    for _, member in ipairs(tribe.members) do
        if member.userId == userId and (member.role == TRIBE_ROLES.LEADER or member.role == TRIBE_ROLES.ELDER) then
            hasPermission = true
            break
        end
    end
    
    if not hasPermission then
        self:SendTribeActionResponse(player, "invite_player", false, "Vous n'avez pas la permission d'inviter des joueurs")
        return
    end
    
    -- Vérifier si la tribu n'est pas pleine
    if #tribe.members >= self.maxMembersPerTribe then
        self:SendTribeActionResponse(player, "invite_player", false, "La tribu a atteint son nombre maximum de membres")
        return
    end
    
    -- Vérifier si la cible est déjà dans une tribu
    if self.playerTribes[targetUserId] then
        self:SendTribeActionResponse(player, "invite_player", false, "Ce joueur est déjà membre d'une tribu")
        return
    end
    
    -- Vérifier si le joueur cible est en ligne
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if not targetPlayer then
        self:SendTribeActionResponse(player, "invite_player", false, "Le joueur cible n'est pas en ligne")
        return
    end
    
    -- Créer l'invitation
    if not tribe.invites then
        tribe.invites = {}
    end
    
    -- Vérifier si une invitation existe déjà
    for i, invite in ipairs(tribe.invites) do
        if invite.userId == targetUserId then
            -- Mettre à jour l'expiration
            invite.expires = os.time() + 300  -- 5 minutes
            invite.inviter = userId
            
            -- Sauvegarder les données
            self:SaveTribeData(tribeId)
            
            -- Envoyer une notification au joueur cible
            self:SendTribeInvitation(targetPlayer, tribe, player.Name)
            
            -- Envoyer une réponse au joueur
            self:SendTribeActionResponse(player, "invite_player", true, "Invitation envoyée à " .. targetPlayer.Name)
            return
        end
    end
    
    -- Ajouter une nouvelle invitation
    table.insert(tribe.invites, {
        userId = targetUserId,
        inviter = userId,
        time = os.time(),
        expires = os.time() + 300  -- 5 minutes
    })
    
    -- Ajouter un événement au journal
    table.insert(tribe.log, {
        type = "player_invited",
        time = os.time(),
        inviter = userId,
        target = targetUserId,
        description = player.Name .. " a invité " .. targetPlayer.Name .. " à rejoindre la tribu"
    })
    
    -- Sauvegarder les données
    self:SaveTribeData(tribeId)
    
    -- Envoyer une notification au joueur cible
    self:SendTribeInvitation(targetPlayer, tribe, player.Name)
    
    -- Envoyer une réponse au joueur
    self:SendTribeActionResponse(player, "invite_player", true, "Invitation envoyée à " .. targetPlayer.Name)
    
    print("TribeService: " .. player.Name .. " a invité " .. targetPlayer.Name .. " à rejoindre la tribu " .. tribe.name)
end

-- Expulser un membre de la tribu
function TribeService:KickMemberFromTribe(player, targetUserId)
    local userId = player.UserId
    
    -- Vérifier si le joueur est dans une tribu
    local tribeId = self.playerTribes[userId]
    if not tribeId then
        self:SendTribeActionResponse(player, "kick_member", false, "Vous n'êtes pas membre d'une tribu")
        return
    end
    
    local tribe = self.tribes[tribeId]
    if not tribe then
        self:SendTribeActionResponse(player, "kick_member", false, "Votre tribu est introuvable")
        return
    end
    
    -- Vérifier si le joueur a le droit d'expulser
    local hasPermission = false
    local playerRole = nil
    for _, member in ipairs(tribe.members) do
        if member.userId == userId then
            playerRole = member.role
            if member.role == TRIBE_ROLES.LEADER or member.role == TRIBE_ROLES.ELDER then
                hasPermission = true
            end
            break
        end
    end
    
    if not hasPermission then
        self:SendTribeActionResponse(player, "kick_member", false, "Vous n'avez pas la permission d'expulser des membres")
        return
    end
    
    -- Vérifier si la cible est membre de la tribu
    local targetMemberIndex = nil
    local targetMemberRole = nil
    local targetMemberName = nil
    for i, member in ipairs(tribe.members) do
        if member.userId == targetUserId then
            targetMemberIndex = i
            targetMemberRole = member.role
            targetMemberName = member.name
            break
        end
    end
    
    if not targetMemberIndex then
        self:SendTribeActionResponse(player, "kick_member", false, "Ce joueur n'est pas membre de votre tribu")
        return
    end
    
    -- Vérifier la hiérarchie
    if playerRole == TRIBE_ROLES.ELDER and (targetMemberRole == TRIBE_ROLES.LEADER or targetMemberRole == TRIBE_ROLES.ELDER) then
        self:SendTribeActionResponse(player, "kick_member", false, "Vous ne pouvez pas expulser un membre de rang égal ou supérieur")
        return
    end
    
    -- Ne pas pouvoir s'expulser soi-même
    if targetUserId == userId then
        self:SendTribeActionResponse(player, "kick_member", false, "Vous ne pouvez pas vous expulser vous-même")
        return
    end
    
    -- Retirer le membre de la tribu
    table.remove(tribe.members, targetMemberIndex)
    
    -- Ajouter un événement au journal
    table.insert(tribe.log, {
        type = "member_kicked",
        time = os.time(),
        kicker = userId,
        target = targetUserId,
        description = player.Name .. " a expulsé " .. targetMemberName .. " de la tribu"
    })
    
    -- Supprimer l'association du joueur cible
    self.playerTribes[targetUserId] = nil
    
    -- Sauvegarder les données
    self:SaveTribeData(tribeId)
    self:SavePlayerTribeAssociation(targetUserId, nil)
    
    -- Notifier le joueur cible s'il est en ligne
    local targetPlayer = Players:GetPlayerByUserId(targetUserId)
    if targetPlayer then
        self:NotifyPlayerTribeUpdate(targetPlayer)
        self:SendTribeActionResponse(targetPlayer, "kicked_from_tribe", true, "Vous avez été expulsé de la tribu " .. tribe.name)
    end
    
    -- Envoyer une réponse au joueur
    self:SendTribeActionResponse(player, "kick_member", true, "Vous avez expulsé " .. targetMemberName .. " de la tribu")
    
    -- Notifier tous les membres de la tribu
    self:NotifyTribeUpdate(tribeId)
    
    print("TribeService: " .. player.Name .. " a expulsé " .. targetMemberName .. " de la tribu " .. tribe.name)
end

-- Promouvoir un membre de la tribu
function TribeService:PromoteMember(player, targetUserId)
    local userId = player.UserId
    
    -- Vérifier si le joueur est dans une tribu
    local tribeId = self.playerTribes[userId]
    if not tribeId then
        self:SendTribeActionResponse(player, "promote_member", false, "Vous n'êtes pas membre d'une tribu")
        return
    end
    
    local tribe = self.tribes[tribeId]
    if not tribe then
        self:SendTribeActionResponse(player, "promote_member", false, "Votre tribu est introuvable")
        return
    end
    
    -- Vérifier si le joueur est le chef de la tribu
    local isLeader = false
    for _, member in ipairs(tribe.members) do
        if member.userId == userId and member.role == TRIBE_ROLES.LEADER then
            isLeader = true
            break
        end
    end
    
    if not isLeader then
        self:SendTribeActionResponse(player, "promote_member", false, "Seul le chef de la tribu peut promouvoir des membres")
        return
    end
    
    -- Vérifier si la cible est membre de la tribu
    local targetMemberIndex = nil
    local targetMemberRole = nil
    local targetMemberName = nil
    for i, member in ipairs(tribe.members) do
        if member.userId == targetUserId then
            targetMemberIndex = i
            targetMemberRole = member.role
            targetMemberName = member.name
            break
        end
    end
    
    if not targetMemberIndex then
        self:SendTribeActionResponse(player, "promote_member", false, "Ce joueur n'est pas membre de votre tribu")
        return
    end
    
    -- Gérer la promotion selon le rôle actuel
    if targetMemberRole == TRIBE_ROLES.NOVICE then
        -- Promouvoir de novice à membre
        tribe.members[targetMemberIndex].role = TRIBE_ROLES.MEMBER
        
        -- Ajouter un événement au journal
        table.insert(tribe.log, {
            type = "member_promoted",
            time = os.time(),
            promoter = userId,
            target = targetUserId,
            fromRole = TRIBE_ROLES.NOVICE,
            toRole = TRIBE_ROLES.MEMBER,
            description = player.Name .. " a promu " .. targetMemberName .. " au rang de Membre"
        })
        
        -- Sauvegarder les données
        self:SaveTribeData(tribeId)
        
        -- Envoyer une réponse au joueur
        self:SendTribeActionResponse(player, "promote_member", true, "Vous avez promu " .. targetMemberName .. " au rang de Membre")
        
        -- Notifier le joueur cible s'il est en ligne
        local targetPlayer = Players:GetPlayerByUserId(targetUserId)
        if targetPlayer then
            self:SendTribeActionResponse(targetPlayer, "promoted", true, "Vous avez été promu au rang de Membre dans votre tribu")
        end
        
        -- Notifier tous les membres de la tribu
        self:NotifyTribeUpdate(tribeId)
        
        print("TribeService: " .. player.Name .. " a promu " .. targetMemberName .. " au rang de Membre")
        
    elseif targetMemberRole == TRIBE_ROLES.MEMBER then
        -- Promouvoir de membre à ancien
        tribe.members[targetMemberIndex].role = TRIBE_ROLES.ELDER
        
        -- Ajouter un événement au journal
        table.insert(tribe.log, {
            type = "member_promoted",
            time = os.time(),
            promoter = userId,
            target = targetUserId,
            fromRole = TRIBE_ROLES.MEMBER,
            toRole = TRIBE_ROLES.ELDER,
            description = player.Name .. " a promu " .. targetMemberName .. " au rang d'Ancien"
        })
        
        -- Sauvegarder les données
        self:SaveTribeData(tribeId)
        
        -- Envoyer une réponse au joueur
        self:SendTribeActionResponse(player, "promote_member", true, "Vous avez promu " .. targetMemberName .. " au rang d'Ancien")
        
        -- Notifier le joueur cible s'il est en ligne
        local targetPlayer = Players:GetPlayerByUserId(targetUserId)
        if targetPlayer then
            self:SendTribeActionResponse(targetPlayer, "promoted", true, "Vous avez été promu au rang d'Ancien dans votre tribu")
        end
        
        -- Notifier tous les membres de la tribu
        self:NotifyTribeUpdate(tribeId)
        
        print("TribeService: " .. player.Name .. " a promu " .. targetMemberName .. " au rang d'Ancien")
        
    elseif targetMemberRole == TRIBE_ROLES.ELDER then
        -- Ne peut pas promouvoir un ancien plus haut
        self:SendTribeActionResponse(player, "promote_member", false, "Ce membre est déjà un Ancien et ne peut pas être promu davantage")
        
    elseif targetMemberRole == TRIBE_ROLES.LEADER then
        -- Ne peut pas promouvoir le chef
        self:SendTribeActionResponse(player, "promote_member", false, "Vous ne pouvez pas promouvoir le chef de la tribu")
    end
end

-- Initialiser le service
function TribeService:Start(services)
    print("TribeService: Démarrage...")
    
    -- Récupérer les références aux autres services
    PlayerService = services.PlayerService
    InventoryService = services.InventoryService
    
    -- Configurer les événements RemoteEvent pour les tribus
    self:SetupRemoteEvents()
    
    -- Écouter les événements de joueur
    Players.PlayerAdded:Connect(function(player)
        self:LoadPlayerTribeData(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        self:HandlePlayerRemoving(player)
    end)
    
    print("TribeService: Démarré avec succès")
    return self
end

-- Configurer les événements RemoteEvent pour les tribus
function TribeService:SetupRemoteEvents()
    local events = ReplicatedStorage:FindFirstChild("Events")
    
    if not events then
        events = Instance.new("Folder")
        events.Name = "Events"
        events.Parent = ReplicatedStorage
    end
    
    -- Créer l'événement pour les actions de tribu
    local tribeActionEvent = events:FindFirstChild("TribeAction")
    if not tribeActionEvent then
        tribeActionEvent = Instance.new("RemoteEvent")
        tribeActionEvent.Name = "TribeAction"
        tribeActionEvent.Parent = events
    end
    
    -- Connecter l'événement aux fonctions de traitement
    tribeActionEvent.OnServerEvent:Connect(function(player, action, ...)
        self:HandleTribeAction(player, action, ...)
    end)
    
    -- Créer l'événement pour notifier les clients des changements de tribu
    local tribeUpdateEvent = events:FindFirstChild("TribeUpdate")
    if not tribeUpdateEvent then
        tribeUpdateEvent = Instance.new("RemoteEvent")
        tribeUpdateEvent.Name = "TribeUpdate"
        tribeUpdateEvent.Parent = events
    end
end

-- Charger les données de tribu pour un joueur
function TribeService:LoadPlayerTribeData(player)
    local userId = player.UserId
    
    -- Vérifier si le joueur est déjà dans une tribu
    spawn(function()
        local success, tribeId = pcall(function()
            return TribesDataStore:GetAsync("Player_" .. userId)
        end)
        
        if success and tribeId then
            -- Vérifier si la tribu existe dans la mémoire
            if not self.tribes[tribeId] then
                -- Charger les données de la tribu
                self:LoadTribeData(tribeId)
            end
            
            -- Associer le joueur à sa tribu
            self.playerTribes[userId] = tribeId
            
            -- Mettre à jour le statut "en ligne" du membre
            if self.tribes[tribeId] then
                for i, member in ipairs(self.tribes[tribeId].members) do
                    if member.userId == userId then
                        member.online = true
                        break
                    end
                end
                
                -- Notifier tous les membres de la tribu
                self:NotifyTribeUpdate(tribeId)
            end
        end
    end)
end

-- Charger les données d'une tribu
function TribeService:LoadTribeData(tribeId)
    spawn(function()
        local success, tribeData = pcall(function()
            return TribesDataStore:GetAsync("Tribe_" .. tribeId)
        end)
        
        if success and tribeData then
            -- Créer la structure de données de la tribu en mémoire
            self.tribes[tribeId] = tribeData
            
            -- Mettre à jour le statut en ligne des membres
            for i, member in ipairs(tribeData.members) do
                local memberPlayer = Players:GetPlayerByUserId(member.userId)
                member.online = memberPlayer ~= nil
            end
            
            print("TribeService: Tribu chargée - " .. tribeData.name)
        else
            warn("TribeService: Échec du chargement de la tribu " .. tribeId)
        end
    end)
end

-- Sauvegarder les données d'une tribu
function TribeService:SaveTribeData(tribeId)
    local tribeData = self.tribes[tribeId]
    if not tribeData then return end
    
    spawn(function()
        local success, err = pcall(function()
            TribesDataStore:SetAsync("Tribe_" .. tribeId, tribeData)
        end)
        
        if not success then
            warn("TribeService: Échec de la sauvegarde de la tribu " .. tribeId .. " - " .. tostring(err))
        end
    end)
end

-- Sauvegarder l'association joueur-tribu
function TribeService:SavePlayerTribeAssociation(userId, tribeId)
    spawn(function()
        local success, err = pcall(function()
            if tribeId then
                TribesDataStore:SetAsync("Player_" .. userId, tribeId)
            else
                TribesDataStore:RemoveAsync("Player_" .. userId)
            end
        end)
        
        if not success then
            warn("TribeService: Échec de la sauvegarde de l'association joueur-tribu pour " .. userId .. " - " .. tostring(err))
        end
    end)
end

-- Gérer les actions de tribu
function TribeService:HandleTribeAction(player, action, ...)
    local args = {...}
    
    if action == "create_tribe" then
        self:CreateTribe(player, args[1], args[2])  -- Nom, description
    elseif action == "join_tribe" then
        self:JoinTribe(player, args[1])  -- ID de la tribu
    elseif action == "leave_tribe" then
        self:LeaveTribe(player)
    elseif action == "invite_player" then
        self:InvitePlayerToTribe(player, args[1])  -- UserId du joueur à inviter
    elseif action == "kick_member" then
        self:KickMemberFromTribe(player, args[1])  -- UserId du membre à expulser
    elseif action == "promote_member" then
        self:PromoteMember(player, args[1])  -- UserId du membre à promouvoir
    elseif action == "demote_member" then
        self:DemoteMember(player, args[1])  -- UserId du membre à rétrograder
    elseif action == "set_tribe_description" then
        self:SetTribeDescription(player, args[1])  -- Nouvelle description
    elseif action == "set_tribe_territory" then
        self:SetTribeTerritory(player, args[1])  -- Position du centre du territoire
    end
end

return TribeService
