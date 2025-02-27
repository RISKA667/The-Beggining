-- src/server/services/PlayerService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameSettings = require(Shared.constants.GameSettings)

local PlayerService = {}
PlayerService.__index = PlayerService

-- Créer une instance du service
function PlayerService.new()
    local self = setmetatable({}, PlayerService)
    
    -- Données des joueurs
    self.playerData = {}
    
    -- Constantes
    self.maxAge = 60  -- Âge maximum (en années)
    self.yearInSeconds = 60 * 60  -- 1 heure réelle = 1 an dans le jeu
    self.naturalDeathChance = {
        -- Chances de mort naturelle par an
        [50] = 0.05,  -- 5% de chance de mourir à 50 ans
        [55] = 0.10,  -- 10% de chance à 55 ans
        [60] = 0.25   -- 25% de chance à 60 ans
    }
    
    return self
end

-- Initialiser les données d'un nouveau joueur
function PlayerService:InitializePlayerData(player)
    if self.playerData[player.UserId] then return end
    
    self.playerData[player.UserId] = {
        age = 16,  -- Âge de départ
        ageStartTime = os.time(),  -- Moment où l'âge a commencé
        tribe = nil,  -- Tribu (à implémenter)
        family = {},  -- Famille (parents, enfants)
        isDead = false
    }
    
    -- Mettre à jour le client
    self:UpdateClientPlayerData(player)
    
    -- Démarrer le vieillissement
    self:StartAging(player)
end

-- Gérer le vieillissement d'un joueur
function PlayerService:StartAging(player)
    spawn(function()
        while true do
            wait(10)  -- Vérifier l'âge toutes les 10 secondes
            
            local data = self.playerData[player.UserId]
            if not data or data.isDead then break end
            
            -- Calculer l'âge actuel
            local timeElapsed = os.time() - data.ageStartTime
            local ageInYears = data.age + (timeElapsed / self.yearInSeconds)
            
            -- Mettre à jour l'âge si une année entière est passée
            if math.floor(ageInYears) > data.age then
                data.age = math.floor(ageInYears)
                
                -- Mettre à jour le client
                self:UpdateClientPlayerData(player)
                
                -- Vérifier la mort naturelle
                self:CheckNaturalDeath(player)
            end
        end
    end)
end

-- Vérifier si le joueur meurt de vieillesse
function PlayerService:CheckNaturalDeath(player)
    local data = self.playerData[player.UserId]
    if not data or data.isDead then return end
    
    local currentAge = data.age
    
    -- Parcourir les seuils de probabilité
    for age, chance in pairs(self.naturalDeathChance) do
        if currentAge >= age and math.random() < chance then
            -- Le joueur meurt de vieillesse
            self:HandlePlayerDeath(player, "age")
            return
        end
    end
end

-- Gérer la mort d'un joueur
function PlayerService:HandlePlayerDeath(player, causeOfDeath)
    local data = self.playerData[player.UserId]
    if not data or data.isDead then return end
    
    data.isDead = true
    
    -- Afficher un message de mort
    local deathMessages = {
        ["age"] = "Vous êtes mort de vieillesse à l'âge de " .. data.age .. " ans.",
        ["hunger"] = "Vous êtes mort de faim.",
        ["thirst"] = "Vous êtes mort de soif.",
        ["cold"] = "Vous êtes mort de froid.",
        ["heat"] = "Vous êtes mort de chaleur.",
        ["killed"] = "Vous avez été tué."
    }
    
    local message = deathMessages[causeOfDeath] or "Vous êtes mort."
    
    -- Envoyer le message au joueur (à implémenter avec RemoteEvent)
    print(player.Name .. ": " .. message)
    
    -- Attendre quelques secondes avant la réincarnation
    wait(5)
    
    -- Réincarner le joueur comme enfant d'un autre joueur
    self:ReincarnatePlayer(player)
end

-- Réincarner le joueur comme enfant d'un autre joueur
function PlayerService:ReincarnatePlayer(player)
    -- Trouver un parent potentiel (joueur encore vivant)
    local potentialParents = {}
    
    for userId, data in pairs(self.playerData) do
        if not data.isDead and userId ~= player.UserId then
            table.insert(potentialParents, userId)
        end
    end
    
    -- S'il n'y a pas d'autres joueurs, réinitialiser normalement
    if #potentialParents == 0 then
        self:ResetPlayerData(player)
        return
    end
    
    -- Choisir un parent aléatoire
    local parentUserId = potentialParents[math.random(1, #potentialParents)]
    local parentPlayer = Players:GetPlayerByUserId(parentUserId)
    
    -- Réinitialiser les données du joueur
    self:ResetPlayerData(player, parentUserId)
    
    -- Si le parent est connecté, ajouter ce joueur à sa famille
    if parentPlayer then
        local parentData = self.playerData[parentUserId]
        table.insert(parentData.family, {
            type = "child",
            userId = player.UserId,
            name = player.Name
        })
        
        -- Informer le parent (à implémenter avec RemoteEvent)
        print(parentPlayer.Name .. ": Un nouvel enfant est né et s'appelle " .. player.Name)
    end
    
    -- Informer le joueur de sa nouvelle vie (à implémenter avec RemoteEvent)
    local parentName = parentPlayer and parentPlayer.Name or "un autre joueur"
    print(player.Name .. ": Vous êtes né en tant qu'enfant de " .. parentName)
    
    -- Faire réapparaître le joueur près de son parent
    if parentPlayer and parentPlayer.Character then
        local character = player.Character or player.CharacterAdded:Wait()
        local parentPos = parentPlayer.Character:GetPrimaryPartCFrame()
        
        -- Positionner le joueur près du parent
        character:SetPrimaryPartCFrame(parentPos * CFrame.new(0, 0, 3))
    end
end

-- Réinitialiser les données d'un joueur
function PlayerService:ResetPlayerData(player, parentUserId)
    self.playerData[player.UserId] = {
        age = 0,  -- Nouveau-né
        ageStartTime = os.time(),
        tribe = parentUserId and self.playerData[parentUserId].tribe or nil,
        family = parentUserId and {
            {
                type = "parent",
                userId = parentUserId,
                name = Players:GetNameFromUserIdAsync(parentUserId)
            }
        } or {},
        isDead = false
    }
    
    -- Réinitialiser l'aspect du personnage (taille plus petite pour un enfant)
    local character = player.Character
    if character and character:FindFirstChild("Humanoid") then
        character:ScaleTo(0.6)  -- 60% de la taille adulte
    end
    
    -- Mettre à jour le client
    self:UpdateClientPlayerData(player)
    
    -- Redémarrer le vieillissement
    self:StartAging(player)
    
    -- Réinitialiser d'autres services (à implémenter)
    -- Inventaire de base pour un nouveau-né, etc.
end

-- Mettre à jour les données du joueur pour le client
function PlayerService:UpdateClientPlayerData(player)
    -- Dans une implémentation réelle, utilisez RemoteEvent pour synchroniser avec le client
    local data = self.playerData[player.UserId]
    if not data then return end
    
    print("Mise à jour des données pour " .. player.Name .. ":")
    print("  Âge: " .. data.age .. " ans")
    print("  Tribu: " .. (data.tribe or "Aucune"))
    print("  Famille: " .. #data.family .. " membres")
end

-- Mettre à jour l'apparence du joueur en fonction de l'âge
function PlayerService:UpdateAppearanceByAge(player)
    local data = self.playerData[player.UserId]
    if not data then return end
    
    local character = player.Character
    if not character or not character:FindFirstChild("Humanoid") then return end
    
    -- Échelle basée sur l'âge (plus petit quand jeune, taille adulte à 16 ans)
    local scale = math.min(1, 0.6 + (data.age / 16) * 0.4)
    
    -- Appliquer l'échelle
    character:ScaleTo(scale)
    
    -- D'autres modifications d'apparence peuvent être ajoutées ici
    -- (cheveux gris pour les personnes âgées, etc.)
end

-- Gérer les événements de caractère
function PlayerService:SetupCharacterEvents(player)
    -- Quand le joueur obtient un nouveau personnage
    player.CharacterAdded:Connect(function(character)
        -- Mettre à jour l'apparence en fonction de l'âge
        self:UpdateAppearanceByAge(player)
        
        -- Gérer d'autres événements liés au personnage
        character.Humanoid.Died:Connect(function()
            -- Si la mort est causée par une réincarnation, ignorer
            local data = self.playerData[player.UserId]
            if data and not data.isDead then
                self:HandlePlayerDeath(player, "killed")
            end
        end)
    end)
end

function PlayerService:Start()
    -- Initialiser les joueurs actuels
    for _, player in pairs(Players:GetPlayers()) do
        self:InitializePlayerData(player)
        self:SetupCharacterEvents(player)
    end
    
    -- Gérer les événements de joueur
    Players.PlayerAdded:Connect(function(player)
        self:InitializePlayerData(player)
        self:SetupCharacterEvents(player)
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        -- Sauvegarder les données si nécessaire
        -- Dans une implémentation complète, utilisez DataStore
    end)
end

return PlayerService