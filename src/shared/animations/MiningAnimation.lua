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
    
    -- Dans une implémentation réelle, vous devrez télécharger l'animation
    -- dans Roblox Studio et utiliser l'ID obtenu
    animation.AnimationId = "" -- Sera rempli après avoir téléchargé l'animation dans Studio
    
    return animation
end

-- Charge et joue l'animation de minage sur un Humanoid
function MiningAnimation.Play(humanoid)
    if not humanoid then
        warn("MiningAnimation.Play: Humanoid requis")
        return nil
    end
    
    -- Vérifier si l'animateur existe déjà
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
    if not tool then
        warn("MiningAnimation.SetupToolAnimation: Tool requis")
        return nil
    end
    
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
        
        -- À remplacer par votre ID d'animation quand disponible
        animation.AnimationId = ""
        
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
            miningSound.SoundId = "" -- À remplacer par votre ID de son quand disponible
            miningSound.Volume = a0.8
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

-- Fonction pour créer un KeyframeSequence
function MiningAnimation.CreateKeyframeSequence()
    local keyframeSequence = Instance.new("KeyframeSequence")
    keyframeSequence.Name = "MiningSequence"
    
    -- Keyframe 1: Position initiale
    local keyframe1 = Instance.new("Keyframe")
    keyframe1.Time = 0
    
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
    
    local waist2 = Instance.new("Pose")
    waist2.Name = "Waist"
    waist2.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(10), math.rad(0), math.rad(0))
    waist2.Parent = keyframe2
    
    keyframe2.Parent = keyframeSequence
    
    -- Keyframe 3: Retour à la position de départ
    local keyframe3 = Instance.new("Keyframe")
    keyframe3.Time = 0.6
    
    local rightShoulder3 = rightShoulder1:Clone()
    rightShoulder3.Parent = keyframe3
    
    local leftShoulder3 = leftShoulder1:Clone()
    leftShoulder3.Parent = keyframe3
    
    local rightElbow3 = rightElbow1:Clone()
    rightElbow3.Parent = keyframe3
    
    local leftElbow3 = leftElbow1:Clone()
    leftElbow3.Parent = keyframe3
    
    local waist3 = Instance.new("Pose")
    waist3.Name = "Waist"
    waist3.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(0), math.rad(0), math.rad(0))
    waist3.Parent = keyframe3
    
    keyframe3.Parent = keyframeSequence
    
    return keyframeSequence
end

-- Fonction pour enregistrer l'animation (à utiliser uniquement dans Studio avec les permissions)
function MiningAnimation.SaveToRoblox()
    local keyframeSequence = MiningAnimation.CreateKeyframeSequence()
    
    -- Cette fonction ne fonctionnera que dans Roblox Studio avec les permissions appropriées
    local success, result = pcall(function()
        return game:GetService("AnimationService"):SaveAnimation(keyframeSequence)
    end)
    
    if success then
        print("Animation enregistrée avec succès. ID:", result)
        return result
    else
        warn("Échec de l'enregistrement de l'animation:", result)
        return nil
    end
end

-- Créer les animations de récolte pour différents types d'outils
function MiningAnimation.GetAnimationForTool(toolType)
    local animations = {
        ["axe"] = "", -- ID d'animation pour hache
        ["pickaxe"] = "", -- ID d'animation pour pioche
        ["shovel"] = "", -- ID d'animation pour pelle
        ["hammer"] = ""  -- ID d'animation pour marteau
    }
    
    -- Retourner l'ID d'animation approprié ou une animation générique
    return animations[toolType] or ""
end

return MiningAnimation
