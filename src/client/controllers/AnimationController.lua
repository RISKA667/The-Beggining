-- src/client/controllers/AnimationController.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MiningAnimation = require(Shared.animations.MiningAnimation)

local AnimationController = {}
AnimationController.__index = AnimationController

function AnimationController.new()
    local self = setmetatable({}, AnimationController)
    
    -- Référence au joueur local
    self.player = Players.LocalPlayer
    
    -- Stockage des animations pré-chargées
    self.loadedAnimations = {}
    
    -- Animation en cours
    self.currentAnimation = nil
    
    return self
end

function AnimationController:Initialize()
    print("AnimationController: Initialisation...")
    
    -- Attendre que le personnage du joueur soit chargé
    if not self.player.Character then
        self.player.CharacterAdded:Wait()
    end
    
    -- Charger les animations de base
    self:PreloadAnimations()
    
    -- Configurer les événements
    self:SetupEvents()
    
    print("AnimationController: Initialisé avec succès")
end

-- Préchargement des animations courantes
function AnimationController:PreloadAnimations()
    local character = self.player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    
    -- Créer une animation de minage
    local miningAnimation = Instance.new("Animation")
    
    -- Note: Dans une implémentation réelle, vous utiliseriez un AnimationId d'une animation préenregistrée
    -- Pour cet exemple, nous utiliserons un ID fictif
    miningAnimation.AnimationId = "rbxassetid://156466309" -- Remplacer par un ID réel
    
    -- Charger l'animation
    self.loadedAnimations.mining = animator:LoadAnimation(miningAnimation)
    
    -- Configurer les propriétés
    self.loadedAnimations.mining.Priority = Enum.AnimationPriority.Action
    self.loadedAnimations.mining.Looped = false
    
    print("AnimationController: Animations préchargées")
end

-- Configurer les événements pour réagir aux actions du joueur
function AnimationController:SetupEvents()
    -- Se reconnecter quand le joueur change de personnage
    self.player.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(character)
    end)
    
    -- Écouter les événements liés aux outils
    local character = self.player.Character
    if character then
        character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                self:SetupToolAnimations(child)
            end
        end)
    end
    
    -- Écouter les événements d'action du joueur envoyés par le serveur
    local events = ReplicatedStorage:FindFirstChild("Events")
    if events then
        local animEvent = events:FindFirstChild("PlayAnimation")
        if animEvent then
            animEvent.OnClientEvent:Connect(function(animationType, options)
                self:PlayAnimation(animationType, options)
            end)
        end
    end
end

-- Gérer un nouveau personnage
function AnimationController:OnCharacterAdded(character)
    -- Réinitialiser les animations stockées
    self.loadedAnimations = {}
    
    -- Recharger les animations de base
    wait(1) -- Attendre que le personnage soit complètement chargé
    self:PreloadAnimations()
    
    -- Configurer les événements des outils
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            self:SetupToolAnimations(child)
        end
    end)
end

-- Configurer les animations pour un outil spécifique
function AnimationController:SetupToolAnimations(tool)
    -- Vérifier si l'outil a déjà un script d'animation
    if tool:FindFirstChild("MiningAnimationController") then return end
    
    -- Vérifier le type d'outil
    local toolType = tool:GetAttribute("ToolType")
    
    if toolType == "pickaxe" then
        -- Utiliser l'animation de minage pour les pioches
        MiningAnimation.SetupToolAnimation(tool)
    elseif toolType == "axe" then
        -- On pourrait avoir une animation similaire ou différente pour la hache
        MiningAnimation.SetupToolAnimation(tool)
    end
end

-- Jouer une animation par son type
function AnimationController:PlayAnimation(animationType, options)
    options = options or {}
    
    -- Arrêter l'animation courante si nécessaire
    if self.currentAnimation and self.currentAnimation.IsPlaying then
        if options.forceStop or not options.blendAnimation then
            self.currentAnimation:Stop()
        end
    end
    
    -- Sélectionner l'animation à jouer
    local animation = self.loadedAnimations[animationType]
    
    if animation then
        -- Configurer les options de l'animation
        if options.speed then
            animation:AdjustSpeed(options.speed)
        else
            animation:AdjustSpeed(1) -- Vitesse normale par défaut
        end
        
        if options.fadeTime then
            animation:Play(options.fadeTime)
        else
            animation:Play()
        end
        
        -- Stocker l'animation courante
        self.currentAnimation = animation
        
        -- Connecter l'événement de fin si une fonction de rappel est fournie
        if options.onFinished then
            local connection
            connection = animation.Stopped:Connect(function()
                options.onFinished()
                connection:Disconnect()
            end)
        end
        
        return animation
    else
        warn("AnimationController: Animation non trouvée -", animationType)
        return nil
    end
end

-- Jouer directement l'animation de minage
function AnimationController:PlayMiningAnimation()
    local character = self.player.Character
    if not character then return nil end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return nil end
    
    -- Créer et jouer l'animation programmatiquement
    return MiningAnimation.Play(humanoid)
end

-- Arrêter toutes les animations
function AnimationController:StopAllAnimations()
    for _, animation in pairs(self.loadedAnimations) do
        if animation.IsPlaying then
            animation:Stop()
        end
    end
    
    self.currentAnimation = nil
end

return AnimationController