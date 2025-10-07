-- assets/models/tools/stone/StonePickaxe.lua
-- Pioche en pierre fonctionnelle avec assets vérifiés

local function CreateStonePickaxe()
    local tool = Instance.new("Tool")
    tool.Name = "StonePickaxe"
    tool.CanBeDropped = true
    tool.RequiresHandle = true
    tool.ToolTip = "Pioche en pierre - Mine la pierre et les minerais"
    tool.Grip = CFrame.new(0, -1.5, 0) * CFrame.Angles(math.rad(90), 0, 0)
    
    -- ========================================
    -- PARTIE 1 : MANCHE (Handle obligatoire)
    -- ========================================
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.25, 3.5, 0.25)
    handle.Material = Enum.Material.Wood
    handle.Color = Color3.fromRGB(120, 81, 45) -- Bois foncé
    handle.CanCollide = false
    handle.Anchored = false
    handle.Parent = tool
    
    -- ========================================
    -- PARTIE 2 : TÊTE DE LA PIOCHE
    -- ========================================
    local head = Instance.new("Part")
    head.Name = "PickaxeHead"
    head.Size = Vector3.new(1.8, 0.6, 0.4)
    head.Material = Enum.Material.Slate
    head.Color = Color3.fromRGB(100, 100, 105) -- Gris pierre
    head.CanCollide = false
    head.Anchored = false
    head.Parent = handle -- Parent au Handle !
    
    -- Positionner la tête au sommet du manche
    local headWeld = Instance.new("Weld")
    headWeld.Name = "HeadToHandle"
    headWeld.Part0 = handle
    headWeld.Part1 = head
    -- Position : au sommet du manche (1.75 unités) + moitié de la tête (0.3)
    headWeld.C0 = CFrame.new(0, 1.75, 0) * CFrame.Angles(0, 0, 0)
    headWeld.C1 = CFrame.new(0, 0, 0)
    headWeld.Parent = head
    
    -- ========================================
    -- PARTIE 3 : DÉTAILS VISUELS (Optionnel)
    -- ========================================
    -- Pointe gauche de la pioche
    local leftPoint = Instance.new("WedgePart")
    leftPoint.Name = "LeftPoint"
    leftPoint.Size = Vector3.new(0.4, 0.6, 0.8)
    leftPoint.Material = Enum.Material.Slate
    leftPoint.Color = Color3.fromRGB(90, 90, 95)
    leftPoint.CanCollide = false
    leftPoint.Anchored = false
    leftPoint.Parent = handle
    
    local leftWeld = Instance.new("Weld")
    leftWeld.Part0 = head
    leftWeld.Part1 = leftPoint
    leftWeld.C0 = CFrame.new(-0.9, 0, 0.2) * CFrame.Angles(0, math.rad(90), math.rad(90))
    leftWeld.Parent = leftPoint
    
    -- Pointe droite de la pioche
    local rightPoint = Instance.new("WedgePart")
    rightPoint.Name = "RightPoint"
    rightPoint.Size = Vector3.new(0.4, 0.6, 0.8)
    rightPoint.Material = Enum.Material.Slate
    rightPoint.Color = Color3.fromRGB(90, 90, 95)
    rightPoint.CanCollide = false
    rightPoint.Anchored = false
    rightPoint.Parent = handle
    
    local rightWeld = Instance.new("Weld")
    rightWeld.Part0 = head
    rightWeld.Part1 = rightPoint
    rightWeld.C0 = CFrame.new(0.9, 0, 0.2) * CFrame.Angles(0, math.rad(-90), math.rad(-90))
    rightWeld.Parent = rightPoint
    
    -- Renfort au centre du manche
    local grip = Instance.new("Part")
    grip.Name = "Grip"
    grip.Size = Vector3.new(0.35, 0.8, 0.35)
    grip.Material = Enum.Material.Fabric
    grip.Color = Color3.fromRGB(80, 50, 30) -- Cuir/tissu brun
    grip.CanCollide = false
    grip.Anchored = false
    grip.Parent = handle
    
    local gripWeld = Instance.new("Weld")
    gripWeld.Part0 = handle
    gripWeld.Part1 = grip
    gripWeld.C0 = CFrame.new(0, 0, 0)
    gripWeld.Parent = grip
    
    -- ========================================
    -- PARTIE 4 : ATTRIBUTS ET STATISTIQUES
    -- ========================================
    tool:SetAttribute("ToolType", "pickaxe")
    tool:SetAttribute("Durability", 100)
    tool:SetAttribute("MaxDurability", 100)
    tool:SetAttribute("Damage", 4)
    tool:SetAttribute("MiningSpeed", 2.0) -- Multiplicateur de vitesse
    tool:SetAttribute("TechLevel", "stone")
    
    -- Ressources que cet outil peut miner
    local minableValue = Instance.new("StringValue")
    minableValue.Name = "Minable"
    minableValue.Value = "stone,copper_ore,tin_ore,coal"
    minableValue.Parent = tool
    
    -- Multiplicateur de récolte
    local multiplierValue = Instance.new("NumberValue")
    multiplierValue.Name = "GatherMultiplier"
    multiplierValue.Value = 2
    multiplierValue.Parent = tool
    
    -- ========================================
    -- PARTIE 5 : SONS RÉUTILISABLES (IDs vérifiés ✅)
    -- ========================================
    local miningSound = Instance.new("Sound")
    miningSound.Name = "MiningSound"
    miningSound.SoundId = "rbxassetid://1682469441" -- ✅ Pickaxe Hit [SOUND EFFECT]
    miningSound.Volume = 0.6
    miningSound.PlaybackSpeed = 1.1
    miningSound.Parent = handle
    
    local breakSound = Instance.new("Sound")
    breakSound.Name = "BreakSound"
    breakSound.SoundId = "rbxassetid://7108607217" -- ✅ Lego Break Sound Effect
    breakSound.Volume = 0.8
    breakSound.PlaybackSpeed = 0.9
    breakSound.Parent = handle
    
    -- ========================================
    -- PARTIE 6 : SCRIPT CLIENT (Animations)
    -- ========================================
    local clientScript = Instance.new("LocalScript")
    clientScript.Name = "ToolController"
    clientScript.Source = [[
        local tool = script.Parent
        local handle = tool:WaitForChild("Handle")
        local miningSound = handle:WaitForChild("MiningSound")
        
        local player = nil
        local character = nil
        local humanoid = nil
        local animator = nil
        local swingAnimation = nil
        
        local isSwinging = false
        local COOLDOWN = 0.8 -- Temps entre chaque coup
        
        -- Charger l'animation
        local function loadAnimation()
            if humanoid then
                animator = humanoid:FindFirstChildOfClass("Animator")
                if animator then
                    local animInstance = Instance.new("Animation")
                    animInstance.AnimationId = "rbxassetid://522635514" -- ✅ R15Slash (vérifié)
                    
                    swingAnimation = animator:LoadAnimation(animInstance)
                    swingAnimation.Priority = Enum.AnimationPriority.Action
                    swingAnimation.Looped = false
                end
            end
        end
        
        -- Équipement de l'outil
        tool.Equipped:Connect(function()
            player = game.Players.LocalPlayer
            character = player.Character or player.CharacterAdded:Wait()
            humanoid = character:WaitForChild("Humanoid")
            
            loadAnimation()
        end)
        
        -- Déséquipement
        tool.Unequipped:Connect(function()
            if swingAnimation then
                swingAnimation:Stop()
            end
            isSwinging = false
        end)
        
        -- Activation (clic gauche)
        tool.Activated:Connect(function()
            if isSwinging then return end
            
            isSwinging = true
            
            -- Jouer l'animation
            if swingAnimation then
                swingAnimation:Play()
            end
            
            -- Jouer le son
            if miningSound and not miningSound.IsPlaying then
                miningSound:Play()
            end
            
            -- Effet visuel de particules
            local particles = Instance.new("ParticleEmitter")
            particles.Texture = "rbxasset://textures/particles/smoke_main.dds"
            particles.Color = ColorSequence.new(Color3.fromRGB(150, 150, 150))
            particles.Size = NumberSequence.new(0.2, 0.5)
            particles.Lifetime = NumberRange.new(0.3, 0.6)
            particles.Rate = 20
            particles.Speed = NumberRange.new(3, 6)
            particles.SpreadAngle = Vector2.new(30, 30)
            particles.Parent = handle
            particles.Enabled = true
            
            -- Désactiver après un court instant
            task.wait(0.1)
            particles.Enabled = false
            game:GetService("Debris"):AddItem(particles, 1)
            
            -- Cooldown
            task.wait(COOLDOWN)
            isSwinging = false
        end)
    ]]
    clientScript.Parent = tool
    
    -- ========================================
    -- PARTIE 7 : SCRIPT SERVEUR (Logique)
    -- ========================================
    local serverScript = Instance.new("Script")
    serverScript.Name = "ToolServerScript"
    serverScript.Source = [[
        local tool = script.Parent
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        
        local durability = tool:GetAttribute("Durability")
        local maxDurability = tool:GetAttribute("MaxDurability")
        local damage = tool:GetAttribute("Damage")
        
        local lastUseTime = 0
        local USE_COOLDOWN = 0.8
        
        -- Fonction pour notifier le joueur (utilise ReplicatedStorage.Events.Notification)
        local function notifyPlayer(player, message, messageType, duration)
            local success, err = pcall(function()
                ReplicatedStorage.Events.Notification:FireClient(
                    player, 
                    message, 
                    messageType or "info", 
                    duration or 3
                )
            end)
            
            if not success then
                warn("[StonePickaxe] Erreur notification:", err)
            end
        end
        
        -- Fonction pour réduire la durabilité
        local function reduceDurability(player)
            if durability <= 0 then return false end
            
            durability = durability - 1
            tool:SetAttribute("Durability", durability)
            
            -- Avertissement à 20%
            if durability <= maxDurability * 0.2 and durability > 0 then
                notifyPlayer(
                    player, 
                    "Votre pioche est presque cassée ! (" .. durability .. "/" .. maxDurability .. ")", 
                    "warning", 
                    3
                )
            end
            
            -- Outil cassé
            if durability <= 0 then
                local breakSound = tool.Handle:FindFirstChild("BreakSound")
                if breakSound then
                    breakSound:Play()
                end
                
                notifyPlayer(
                    player, 
                    "Votre pioche en pierre s'est cassée !", 
                    "error", 
                    5
                )
                
                -- Détruire après le son
                task.wait(0.5)
                tool:Destroy()
                return false
            end
            
            return true
        end
        
        -- Activation de l'outil
        tool.Activated:Connect(function()
            local currentTime = tick()
            if currentTime - lastUseTime < USE_COOLDOWN then
                return
            end
            lastUseTime = currentTime
            
            local character = tool.Parent
            if not character or not character:IsA("Model") then return end
            
            local player = game.Players:GetPlayerFromCharacter(character)
            if not player then return end
            
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid or humanoid.Health <= 0 then return end
            
            -- Réduire la durabilité
            reduceDurability(player)
            
            -- Raycast pour détecter ce qui est frappé
            local handle = tool:FindFirstChild("Handle")
            if not handle then return end
            
            local rayOrigin = handle.Position
            local rayDirection = (handle.CFrame.LookVector * 6) -- 6 studs de portée
            
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {character, tool}
            
            local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
            
            if rayResult and rayResult.Instance then
                local hitPart = rayResult.Instance
                
                -- Logique de minage (à adapter selon votre jeu)
                if hitPart:FindFirstChild("Resource") or hitPart:GetAttribute("Mineable") then
                    -- Votre logique de récolte de ressources ici
                    print("[StonePickaxe] Minage de:", hitPart.Name)
                    
                    -- Exemple : infliger des dégâts à la ressource
                    local resourceHealth = hitPart:GetAttribute("Health")
                    if resourceHealth then
                        local newHealth = resourceHealth - damage
                        hitPart:SetAttribute("Health", newHealth)
                        
                        if newHealth <= 0 then
                            print("[StonePickaxe] Ressource détruite:", hitPart.Name)
                            -- Logique de drop de ressources
                        end
                    end
                end
            end
        end)
    ]]
    serverScript.Parent = tool
    
    return tool
end

return CreateStonePickaxe
