-- src/server/services/TimeService.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local GameSettings = require(Shared.constants.GameSettings)

local TimeService = {}
TimeService.__index = TimeService

-- Créer une instance du service
function TimeService.new()
    local self = setmetatable({}, TimeService)
    
    -- Constantes de temps
    self.dayLength = GameSettings.Time.dayLength             -- Durée du jour en secondes
    self.nightLength = GameSettings.Time.nightLength         -- Durée de la nuit en secondes
    self.dawnDuskLength = GameSettings.Time.dawnDuskLength   -- Durée de l'aube/crépuscule en secondes
    self.dayNightCycle = GameSettings.Time.dayNightCycle     -- Durée totale du cycle jour/nuit
    self.yearInSeconds = GameSettings.Time.yearInSeconds     -- Durée d'une année dans le jeu
    
    -- État du temps
    self.gameTime = 0           -- Temps total écoulé depuis le début (en secondes)
    self.currentDay = 1         -- Jour actuel
    self.currentYear = 1        -- Année actuelle
    self.isDaytime = true       -- Si c'est actuellement le jour
    self.isDawnOrDusk = false   -- Si c'est l'aube ou le crépuscule
    self.timeString = "06:00"   -- Heure actuelle (format HH:MM)
    self.clockTime = 6          -- Heure actuelle (format 0-24)
    
    -- Références aux RemoteEvents
    self.remoteEvents = {}
    
    -- Références aux services
    self.playerService = nil
    
    return self
end

-- Initialiser le service
function TimeService:Start(services)
    print("TimeService: Démarrage...")
    
    -- Récupérer les références aux autres services
    self.playerService = services.PlayerService
    
    -- Récupérer les références aux RemoteEvents
    local Events = ReplicatedStorage:FindFirstChild("Events")
    if Events then
        self.remoteEvents = {
            TimeUpdate = Events:FindFirstChild("TimeUpdate")
        }
    else
        warn("TimeService: Dossier Events non trouvé dans ReplicatedStorage")
    end
    
    -- Configurer l'éclairage initial
    self:SetInitialLighting()
    
    -- Démarrer la boucle de mise à jour du temps
    self:StartTimeLoop()
    
    -- Démarrer la boucle pour le vieillissement des joueurs
    self:StartAgingLoop()
    
    print("TimeService: Démarré avec succès")
    return self
end

-- Configurer l'éclairage initial
function TimeService:SetInitialLighting()
    -- Régler le temps initial à 6h du matin (aube)
    Lighting.ClockTime = 6
    Lighting.TimeOfDay = "06:00:00"
    
    -- Configurer les propriétés d'éclairage de base
    Lighting.Ambient = Color3.fromRGB(70, 70, 70)
    Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
    Lighting.Brightness = 2
    Lighting.GlobalShadows = true
    Lighting.Technology = Enum.Technology.ShadowMap
    Lighting.ExposureCompensation = 0.2
    
    -- Créer un effet de brouillard pour l'aube/crépuscule
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Density = 0.3
    atmosphere.Offset = 0
    atmosphere.Color = Color3.fromRGB(200, 170, 150)
    atmosphere.Decay = Color3.fromRGB(100, 100, 100)
    atmosphere.Glare = 0
    atmosphere.Haze = 0
    atmosphere.Parent = Lighting
    
    -- Effets de ciel
    local sky = Instance.new("Sky")
    sky.SkyboxBk = "rbxassetid://1012890"
    sky.SkyboxDn = "rbxassetid://1012895"
    sky.SkyboxFt = "rbxassetid://1012887"
    sky.SkyboxLf = "rbxassetid://1012889"
    sky.SkyboxRt = "rbxassetid://1012888"
    sky.SkyboxUp = "rbxassetid://1014435"
    sky.CelestialBodiesShown = true
    sky.StarCount = 3000
    sky.SunTextureId = "rbxassetid://1084351190"
    sky.SunAngularSize = 21
    sky.MoonTextureId = "rbxassetid://1088195518"
    sky.MoonAngularSize = 11
    sky.Parent = Lighting
end

-- Démarrer la boucle de mise à jour du temps
function TimeService:StartTimeLoop()
    -- Utiliser RunService.Heartbeat pour une mise à jour fluide
    local lastUpdateTime = os.clock()
    
    RunService.Heartbeat:Connect(function()
        local currentTime = os.clock()
        local deltaTime = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        -- Mettre à jour le temps du jeu
        self:UpdateGameTime(deltaTime)
        
        -- Mettre à jour l'éclairage du jeu
        self:UpdateLighting()
        
        -- Notifier les clients du changement d'heure toutes les 5 secondes
        if math.floor(self.gameTime) % 5 == 0 then
            self:NotifyClientsOfTimeChange()
        end
    end)
    
    print("TimeService: Boucle de temps démarrée")
end

-- Mettre à jour le temps du jeu
function TimeService:UpdateGameTime(deltaTime)
    -- Incrémenter le temps total
    self.gameTime = self.gameTime + deltaTime
    
    -- Calculer la position dans le cycle jour/nuit (0 à 1)
    local cycleProgress = (self.gameTime % self.dayNightCycle) / self.dayNightCycle
    
    -- Convertir en heures (0 à 24)
    self.clockTime = cycleProgress * 24
    
    -- Déterminer si c'est le jour ou la nuit
    local dayStart = self.dawnDuskLength / self.dayNightCycle
    local dayEnd = (self.dawnDuskLength + self.dayLength) / self.dayNightCycle
    local nightStart = (2 * self.dawnDuskLength + self.dayLength) / self.dayNightCycle
    
    -- Vérifier si c'est l'aube ou le crépuscule
    self.isDawnOrDusk = (cycleProgress < dayStart) or 
                        (cycleProgress > dayEnd and cycleProgress < nightStart)
    
    -- Vérifier si c'est le jour
    self.isDaytime = cycleProgress >= dayStart and cycleProgress <= nightStart
    
    -- Mettre à jour l'heure au format HH:MM
    local hours = math.floor(self.clockTime)
    local minutes = math.floor((self.clockTime - hours) * 60)
    self.timeString = string.format("%02d:%02d", hours, minutes)
    
    -- Mettre à jour le jour et l'année
    local totalDays = math.floor(self.gameTime / self.dayNightCycle)
    if totalDays + 1 ~= self.currentDay then
        self.currentDay = totalDays + 1
        print("TimeService: Nouveau jour - " .. self.currentDay)
    end
    
    local totalYears = math.floor(self.gameTime / self.yearInSeconds)
    if totalYears + 1 ~= self.currentYear then
        self.currentYear = totalYears + 1
        print("TimeService: Nouvelle année - " .. self.currentYear)
    end
end

-- Mettre à jour l'éclairage du monde
function TimeService:UpdateLighting()
    -- Mettre à jour l'heure dans Lighting
    Lighting.ClockTime = self.clockTime
    
    -- Heures formatées pour TimeOfDay (HH:MM:SS)
    local hours = math.floor(self.clockTime)
    local minutes = math.floor((self.clockTime - hours) * 60)
    local seconds = math.floor(((self.clockTime - hours) * 60 - minutes) * 60)
    Lighting.TimeOfDay = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    
    -- Ajuster l'atmosphère en fonction du moment de la journée
    local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then
        if self.isDawnOrDusk then
            -- Aube/crépuscule: brouillard orangé
            atmosphere.Density = 0.35
            atmosphere.Color = Color3.fromRGB(255, 180, 150)
        elseif self.isDaytime then
            -- Jour: atmosphère claire
            atmosphere.Density = 0.2
            atmosphere.Color = Color3.fromRGB(200, 200, 220)
        else
            -- Nuit: brouillard bleuté
            atmosphere.Density = 0.4
            atmosphere.Color = Color3.fromRGB(150, 170, 255)
        end
    end
    
    -- Ajuster la luminosité globale
    if self.isDaytime and not self.isDawnOrDusk then
        Lighting.Brightness = 2.0
        Lighting.ExposureCompensation = 0.2
        Lighting.Ambient = Color3.fromRGB(70, 70, 70)
        Lighting.OutdoorAmbient = Color3.fromRGB(110, 110, 110)
    elseif self.isDawnOrDusk then
        Lighting.Brightness = 1.5
        Lighting.ExposureCompensation = 0.1
        Lighting.Ambient = Color3.fromRGB(90, 70, 60)
        Lighting.OutdoorAmbient = Color3.fromRGB(120, 90, 80)
    else
        Lighting.Brightness = 0.8
        Lighting.ExposureCompensation = 0.05
        Lighting.Ambient = Color3.fromRGB(40, 40, 60)
        Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 80)
    end
end

-- Notifier les clients du changement d'heure
function TimeService:NotifyClientsOfTimeChange()
    if not self.remoteEvents.TimeUpdate then return end
    
    -- Préparer les informations de temps à envoyer
    local timeInfo = {
        gameTime = self.gameTime,
        clockTime = self.clockTime,
        timeString = self.timeString,
        isDaytime = self.isDaytime,
        isDawnOrDusk = self.isDawnOrDusk,
        gameDay = self.currentDay,
        gameYear = self.currentYear
    }
    
    -- Envoyer à tous les joueurs
    for _, player in ipairs(Players:GetPlayers()) do
        self.remoteEvents.TimeUpdate:FireClient(player, timeInfo)
    end
end

-- Démarrer la boucle pour le vieillissement des joueurs
function TimeService:StartAgingLoop()
    -- Cette boucle s'exécute toutes les minutes pour mettre à jour l'âge des joueurs
    local agingInterval = 60 -- Vérifier toutes les minutes
    
    spawn(function()
        while true do
            wait(agingInterval)
            self:UpdatePlayerAges()
        end
    end)
    
    print("TimeService: Boucle de vieillissement démarrée")
end

-- Mettre à jour l'âge des joueurs
function TimeService:UpdatePlayerAges()
    -- Si le service de joueur n'est pas disponible, ne rien faire
    if not self.playerService then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        -- Calculer l'âge du joueur basé sur le temps dans le jeu
        if self.playerService.playerData and self.playerService.playerData[player.UserId] then
            local playerData = self.playerService.playerData[player.UserId]
            
            -- Si le joueur est vivant, mettre à jour son âge
            if not playerData.isDead then
                -- Calculer l'âge basé sur le temps écoulé depuis le début de l'âge
                local timeElapsed = self.gameTime - playerData.ageStartTime
                local ageInYears = playerData.age + (timeElapsed / self.yearInSeconds)
                
                -- Mettre à jour l'âge si une année entière est passée
                local newAge = math.floor(ageInYears)
                if newAge > playerData.age then
                    playerData.age = newAge
                    self.playerService:UpdateClientPlayerData(player)
                    print("TimeService: Joueur " .. player.Name .. " atteint l'âge de " .. newAge .. " ans")
                    
                    -- Vérifier si le joueur peut mourir de vieillesse
                    self.playerService:CheckNaturalDeath(player)
                end
            end
        end
    end
end

-- Obtenir l'heure actuelle du jeu
function TimeService:GetCurrentTime()
    return {
        gameTime = self.gameTime,
        clockTime = self.clockTime,
        timeString = self.timeString,
        isDaytime = self.isDaytime,
        isDawnOrDusk = self.isDawnOrDusk,
        gameDay = self.currentDay,
        gameYear = self.currentYear
    }
end

-- Forcer une mise à jour du temps pour un joueur spécifique
function TimeService:ForceTimeUpdateForPlayer(player)
    if not player or not self.remoteEvents.TimeUpdate then return end
    
    local timeInfo = self:GetCurrentTime()
    self.remoteEvents.TimeUpdate:FireClient(player, timeInfo)
end

-- Gérer un nouveau joueur qui se connecte
function TimeService:HandlePlayerAdded(player)
    -- Forcer une mise à jour du temps pour le nouveau joueur
    self:ForceTimeUpdateForPlayer(player)
end

return TimeService
