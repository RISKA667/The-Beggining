-- assets/models/tools/stone/StonePickaxe.lua
-- Définition de base pour une pioche en pierre

local function CreateStonePickaxe()
    local tool = Instance.new("Tool")
    tool.Name = "StonePickaxe"
    tool.CanBeDropped = true
    tool.RequiresHandle = true
    tool.TextureId = "rbxassetid://12345689" -- À remplacer par un ID réel
    
    -- Créer le manche (Handle)
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.3, 4, 0.3)
    handle.Position = Vector3.new(0, 0, 0)
    handle.Orientation = Vector3.new(0, 0, 0)
    handle.Material = Enum.Material.Wood
    handle.Color = Color3.fromRGB(163, 102, 51) -- Couleur bois
    handle.Parent = tool
    
    -- Créer la tête de la pioche
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(0.8, 1.2, 0.4)
    head.Position = Vector3.new(0, 1.8, 0) -- Position relative au manche
    head.Material = Enum.Material.Slate
    head.Color = Color3.fromRGB(120, 120, 120) -- Couleur pierre
    head.Parent = tool
    
    -- Créer la soudure entre le manche et la tête
    local weld = Instance.new("WeldConstraint")
    weld.Name = "HeadWeld"
    weld.Part0 = handle
    weld.Part1 = head
    weld.Parent = tool
    
    -- Attributs de l'outil
    tool:SetAttribute("ToolType", "pickaxe")
    tool:SetAttribute("Durability", 100)
    tool:SetAttribute("MaxDurability", 100)
    tool:SetAttribute("Damage", 4)
    
    -- Ajouter des valeurs pour la logique du jeu
    local techLevelValue = Instance.new("StringValue")
    techLevelValue.Name = "TechLevel"
    techLevelValue.Value = "stone"
    techLevelValue.Parent = tool
    
    -- Valeur pour les ressources minables
    local minableValue = Instance.new("StringValue")
    minableValue.Name = "Minable"
    minableValue.Value = "stone,copper_ore,tin_ore"
    minableValue.Parent = tool
    
    -- Valeur pour le multiplicateur de récolte
    local multiplierValue = Instance.new("NumberValue")
    multiplierValue.Name = "GatherMultiplier"
    multiplierValue.Value = 2 -- 2x plus efficace qu'à la main
    multiplierValue.Parent = tool
    
    -- Script local pour les animations et effets
    local script = Instance.new("LocalScript")
    script.Name = "ToolController"
    script.Source = [[
    local tool = script.Parent
    local player = nil
    local character = nil
    local humanoid = nil
    local animation = nil
    
    -- Fonction pour charger l'animation
    local function loadAnimation()
        if humanoid and humanoid:FindFirstChild("Animator") then
            local animator = humanoid:FindFirstChild("Animator")
            
            -- Créer l'animation
            local animationInstance = Instance.new("Animation")
            animationInstance.AnimationId = "rbxassetid://12345720" -- ID d'animation de minage
            
            -- Charger l'animation
            animation = animator:LoadAnimation(animationInstance)
            animation.Priority = Enum.AnimationPriority.Action
            animation.Looped = false
        end
    end
    
    -- Quand l'outil est équipé
    tool.Equipped:Connect(function()
        player = game.Players.LocalPlayer
        character = player.Character
        humanoid = character:FindFirstChild("Humanoid")
        
        loadAnimation()
    end)
    
    -- Quand l'outil est déséquipé
    tool.Unequipped:Connect(function()
        if animation then
            animation:Stop()
        end
    end)
    
    -- Quand l'outil est utilisé
    tool.Activated:Connect(function()
        -- Jouer l'animation
        if animation then
            animation:Play()
        end
        
        -- Effet sonore de minage
        local sound = Instance.new("Sound")
        sound.SoundId = "rbxassetid://12345731" -- ID de son de minage
        sound.Volume = 0.7
        sound.Parent = tool.Handle
        sound:Play()
        
        -- Supprimer le son après lecture
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end)
    ]]
    script.Parent = tool
    
    -- Script serveur pour la logique de jeu
    local serverScript = Instance.new("Script")
    serverScript.Name = "ToolServerScript"
    serverScript.Source = [[
    local tool = script.Parent
    local durability = tool:GetAttribute("Durability")
    
    -- Quand l'outil frappe quelque chose
    tool.Activated:Connect(function()
        local player = game.Players:GetPlayerFromCharacter(tool.Parent)
        if not player then return end
        
        -- Logique pour réduire la durabilité
        if durability > 0 then
            durability = durability - 1
            tool:SetAttribute("Durability", durability)
            
            -- Vérifier si l'outil est cassé
            if durability <= 0 then
                -- Informer le joueur
                game.ReplicatedStorage.Events.Notification:FireClient(
                    player, 
                    "Votre pioche en pierre s'est cassée!", 
                    "warning", 
                    5
                )
                
                -- Détruire l'outil
                tool:Destroy()
            end
        end
    end)
    ]]
    serverScript.Parent = tool
    
    return tool
end

return CreateStonePickaxe