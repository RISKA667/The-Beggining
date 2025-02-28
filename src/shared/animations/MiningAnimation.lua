-- src/shared/animations/MiningAnimation.lua
-- Animation de minage créée programmatiquement

local MiningAnimation = {}

-- Crée une animation de minage basique
function MiningAnimation.Create()
    -- Créer une animation
    local animation = Instance.new("Animation")
    
    -- Créer la séquence d'animation
    local keyframeSequence = Instance.new("KeyframeSequence")
    keyframeSequence.Name = "MiningSequence"
    keyframeSequence.Priority = Enum.AnimationPriority.Action
    
    -- Keyframe 1: Position initiale
    local keyframe1 = Instance.new("Keyframe")
    keyframe1.Time = 0
    
    -- Position des bras pour la position initiale (légèrement en arrière)
    local rightShoulder1 = Instance.new("Pose")
    rightShoulder1.Name = "Right Shoulder"
    rightShoulder1.CFrame = CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(-30), math.rad(20), math.rad(0))
    rightShoulder1.Parent = keyframe1
    
    local leftShoulder1 = Instance.new("Pose")
    leftShoulder1.Name = "Left Shoulder"
    leftShoulder1.CFrame = CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(-30), math.rad(-20), math.rad(0))
    leftShoulder1.Parent = keyframe1
    
    local rightElbow1 = Instance.new("Pose")
    rightElbow1.Name = "Right Elbow"
    rightElbow1.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-80), math.rad(0), math.rad(0))
    rightElbow1.Parent = keyframe1
    
    local leftElbow1 = Instance.new("Pose")
    leftElbow1.Name = "Left Elbow"
    leftElbow1.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-80), math.rad(0), math.rad(0))
    leftElbow1.Parent = keyframe1
    
    keyframe1.Parent = keyframeSequence
    
    -- Keyframe 2: Balancement vers l'avant (impact)
    local keyframe2 = Instance.new("Keyframe")
    keyframe2.Time = 0.3
    
    local rightShoulder2 = Instance.new("Pose")
    rightShoulder2.Name = "Right Shoulder"
    rightShoulder2.CFrame = CFrame.new(1, 0.5, 0) * CFrame.Angles(math.rad(40), math.rad(20), math.rad(0))
    rightShoulder2.Parent = keyframe2
    
    local leftShoulder2 = Instance.new("Pose")
    leftShoulder2.Name = "Left Shoulder"
    leftShoulder2.CFrame = CFrame.new(-1, 0.5, 0) * CFrame.Angles(math.rad(40), math.rad(-20), math.rad(0))
    leftShoulder2.Parent = keyframe2
    
    local rightElbow2 = Instance.new("Pose")
    rightElbow2.Name = "Right Elbow"
    rightElbow2.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-40), math.rad(0), math.rad(0))
    rightElbow2.Parent = keyframe2
    
    local leftElbow2 = Instance.new("Pose")
    leftElbow2.Name = "Left Elbow"
    leftElbow2.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-40), math.rad(0), math.rad(0))
    leftElbow2.Parent = keyframe2
    
    -- Ajouter un léger mouvement de torse pour plus de réalisme
    local waist2 = Instance.new("Pose")
    waist2.Name = "Waist"
    waist2.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0))
    waist2.Parent = keyframe2
    
    keyframe2.Parent = keyframeSequence
    
    -- Keyframe 3: Retour à la position de départ
    local keyframe3 = Instance.new("Keyframe")
    keyframe3.Time = 0.6
    
    -- Copier les poses de la keyframe 1
    local rightShoulder3 = rightShoulder1:Clone()
    rightShoulder3.Parent = keyframe3
    
    local leftShoulder3 = leftShoulder1:Clone()
    leftShoulder3.Parent = keyframe3
    
    local rightElbow3 = rightElbow1:Clone()
    rightElbow3.Parent = keyframe3
    
    local leftElbow3 = leftElbow1:Clone()
    leftElbow3.Parent = keyframe3
    
    -- Retour du torse à la position normale
    local waist3 = Instance.new("Pose")
    waist3.Name = "Waist"
    waist3.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))
    waist3.Parent = keyframe3
    
    keyframe3.Parent = keyframeSequence
    
    -- Ajouter la séquence à l'animation
    keyframeSequence.Parent = animation
    
    -- Génération d'un AnimationId à partir de la séquence d'animation
    -- Note: Ce code ne fonctionnera pas tel quel car vous ne pouvez pas
    -- générer un AnimationId directement dans le code côté client
    -- Dans une implémentation réelle, vous devrez télécharger l'animation
    -- dans Roblox Studio et utiliser l'ID obtenu
    
    -- Simulation d'un ID pour cet exemple
    animation.AnimationId = "rbxassetid://0000000" -- À remplacer par un vrai ID
    
    return animation
end

-- Charge et joue l'animation de minage sur un Humanoid
function MiningAnimation.Play(humanoid)
    if not humanoid then
        warn("MiningAnimation.Play: Humanoid requis")
        return nil
    end
    
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end
    
    -- Créer l'animation
    local animationInstance = MiningAnimation.Create()
    
    -- Charger et jouer l'animation
    local animTrack = animator:LoadAnimation(animationInstance)
    animTrack:Play()
    
    return animTrack
end

-- Fonction auxiliaire pour jouer l'animation de minage depuis un outil
function MiningAnimation.SetupToolAnimation(tool)
    local animationScript = Instance.new("LocalScript")
    animationScript.Name = "MiningAnimationController"
    
    animationScript.Source = [[
    local tool = script.Parent
    local player = nil
    local character = nil
    local humanoid = nil
    local animTrack = nil
    
    -- Fonction pour préparer l'animation
    local function setupAnimation()
        if not character or not humanoid then return end
        
        -- Créer l'animation
        local animation = Instance.new("Animation")
        
        -- Note: Dans une implémentation réelle, vous devriez utiliser un ID d'animation préenregistré
        -- Cet ID est un placeholder
        animation.AnimationId = "rbxassetid://12345678"
        
        -- Charger l'animation
        animTrack = humanoid:LoadAnimation(animation)
        
        -- Configurer les propriétés de l'animation
        animTrack.Priority = Enum.AnimationPriority.Action
        animTrack.Looped = false
    end
    
    -- Quand l'outil est équipé
    tool.Equipped:Connect(function()
        player = game.Players.LocalPlayer
        character = player.Character
        if character then
            humanoid = character:FindFirstChild("Humanoid")
            setupAnimation()
        end
    end)
    
    -- Quand l'outil est activé (utilisé)
    tool.Activated:Connect(function()
        if animTrack then
            animTrack:Play()
            
            -- Jouer un son de minage
            local miningSound = Instance.new("Sound")
            miningSound.SoundId = "rbxassetid://156466309" -- Son de minage
            miningSound.Volume = 0.8
            miningSound.Parent = tool.Handle
            miningSound:Play()
            
            -- Détruire le son après lecture
            miningSound.Ended:Connect(function()
                miningSound:Destroy()
            end)
        end
    end)
    
    -- Quand l'outil est déséquipé
    tool.Unequipped:Connect(function()
        if animTrack and animTrack.IsPlaying then
            animTrack:Stop()
        end
        
        player = nil
        character = nil
        humanoid = nil
        animTrack = nil
    end)
    ]]
    
    animationScript.Parent = tool
    
    return animationScript
end

-- Fonction pour créer un KeyframeSequence et l'enregistrer
-- Cette fonction ne peut être utilisée qu'au niveau du serveur avec les bons droits
function MiningAnimation.SaveToRoblox()
    -- Ce code est fourni à titre d'exemple et ne fonctionnera pas tel quel
    -- car l'enregistrement d'animations requiert des autorisations spéciales
    
    local keyframeSequence = Instance.new("KeyframeSequence")
    keyframeSequence.Name = "MiningSequence"
    
    -- Ajouter les keyframes comme dans la fonction Create()
    -- ...
    
    -- Enregistrer dans Roblox
    -- Cette partie ne fonctionnera pas dans un environnement normal
    -- car elle nécessite des autorisations spéciales
    local success, animationId = pcall(function()
        return game:GetService("AnimationService"):SaveAnimation(keyframeSequence)
    end)
    
    if success then
        print("Animation enregistrée avec l'ID:", animationId)
        return animationId
    else
        warn("Échec de l'enregistrement de l'animation:", animationId)
        return nil
    end
end

return MiningAnimation