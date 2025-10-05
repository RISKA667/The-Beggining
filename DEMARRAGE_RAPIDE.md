# 🚀 Guide de Démarrage Rapide - The Beginning

## Installation et Configuration

### 1. Structure du projet

Assurez-vous que votre projet a la structure suivante :

```
the-beginning/
├── src/
│   ├── server/
│   │   ├── init.lua              ← Point d'entrée serveur (NOUVEAU)
│   │   └── services/
│   │       ├── PlayerService.lua
│   │       ├── InventoryService.lua
│   │       ├── SurvivalService.lua
│   │       ├── CraftingService.lua
│   │       ├── ResourceService.lua
│   │       ├── BuildingService.lua
│   │       ├── TimeService.lua
│   │       ├── TribeService.lua
│   │       ├── FarmingService.lua      ← NOUVEAU
│   │       └── CombatService.lua       ← NOUVEAU
│   ├── client/
│   │   └── init.lua
│   └── shared/
│       └── constants/
│           ├── ItemTypes.lua
│           ├── CraftingRecipes.lua
│           └── GameSettings.lua
└── default.project.json
```

### 2. Configuration Rojo

Votre `default.project.json` devrait pointer vers `src/server/init.lua` comme point d'entrée :

```json
{
  "ServerScriptService": {
    "$className": "ServerScriptService",
    "Server": {
      "$path": "src/server"
    }
  }
}
```

### 3. Démarrage dans Roblox Studio

1. **Ouvrir Roblox Studio**
2. **Installer le plugin Rojo** (si pas déjà fait)
3. **Démarrer le serveur Rojo** dans votre terminal :
   ```bash
   cd the-beginning
   rojo serve
   ```
4. **Connecter Rojo** dans Roblox Studio (plugin Rojo → Connect)
5. **Appuyer sur Play** pour démarrer le jeu

### 4. Vérification du démarrage

Dans la console Output, vous devriez voir :

```
========================================
  THE BEGINNING - Serveur
========================================
Serveur: Initialisation des RemoteEvents...
  ✓ RemoteEvent créé: UpdateInventory
  ✓ RemoteEvent créé: AttackPlayer
  [... autres RemoteEvents ...]
Serveur: RemoteEvents initialisés avec succès
Serveur: Initialisation des services...
  ✓ Service démarré: PlayerService
  ✓ Service démarré: InventoryService
  ✓ Service démarré: FarmingService
  ✓ Service démarré: CombatService
  [... autres services ...]
========================================
  Serveur initialisé avec succès!
========================================
```

---

## 🌾 Utilisation du Système de Farming

### Planter une graine

**Depuis le code (serveur) :**
```lua
local FarmingService = services.FarmingService
local position = Vector3.new(100, 0, 100)  -- Position où planter
FarmingService:PlantSeed(player, "wheat_seeds", position)
```

**Depuis RemoteEvent (client) :**
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local PlantSeed = Events:WaitForChild("PlantSeed")

-- Planter à la position de la souris
PlantSeed:FireServer("wheat_seeds", targetPosition)
```

### Récolter une culture

**Clic sur la plante** : Le joueur peut simplement cliquer sur une plante mature (stade 5)

**Ou via code :**
```lua
FarmingService:HarvestCrop(player, cropId)
```

### Arroser une plante

```lua
FarmingService:WaterCrop(player, cropId)
```

---

## ⚔️ Utilisation du Système de Combat

### Attaquer un joueur

**Depuis le code (serveur) :**
```lua
local CombatService = services.CombatService
CombatService:AttackTarget(attacker, target, "melee")
```

**Depuis RemoteEvent (client) :**
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage:WaitForChild("Events")
local AttackPlayer = Events:WaitForChild("AttackPlayer")

-- Attaquer un joueur ciblé
AttackPlayer:FireServer(targetPlayer, "melee")
```

### Équiper une arme

1. Ajouter l'arme à l'inventaire :
   ```lua
   InventoryService:AddItemToInventory(player, "bronze_sword", 1)
   ```

2. Équiper l'arme :
   ```lua
   InventoryService:EquipItem(player, slotNumber)
   ```

3. L'arme est automatiquement détectée lors de l'attaque

### Équiper une armure

```lua
-- Ajouter une armure
InventoryService:AddItemToInventory(player, "iron_chestplate", 1)

-- Équiper l'armure
InventoryService:EquipItem(player, slotNumber)

-- L'armure est automatiquement calculée
```

---

## 🎮 Commandes de Test (à créer)

Créez un script de test dans `ServerScriptService` pour tester rapidement :

```lua
-- TestCommands.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Attendre que le serveur soit initialisé
local Server = require(game.ServerScriptService.Server.init)
local services = Server

-- Commandes de chat
Players.PlayerAdded:Connect(function(player)
    player.Chatted:Connect(function(message)
        local args = string.split(message, " ")
        local command = args[1]
        
        -- /give [item] [quantity]
        if command == "/give" then
            local itemId = args[2]
            local quantity = tonumber(args[3]) or 1
            
            if services.InventoryService then
                services.InventoryService:AddItemToInventory(player, itemId, quantity)
                print(player.Name .. " a reçu " .. quantity .. "x " .. itemId)
            end
        
        -- /plant [seed]
        elseif command == "/plant" then
            local seedId = args[2] or "wheat_seeds"
            local char = player.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local pos = char.HumanoidRootPart.Position + char.HumanoidRootPart.CFrame.LookVector * 5
                services.FarmingService:PlantSeed(player, seedId, pos)
            end
        
        -- /heal [amount]
        elseif command == "/heal" then
            local amount = tonumber(args[2]) or 100
            if services.CombatService then
                services.CombatService:HealPlayer(player, amount)
            end
        
        -- /health
        elseif command == "/health" then
            if services.CombatService then
                local data = services.CombatService.playerCombatData[player.UserId]
                if data then
                    print(player.Name .. " - HP: " .. data.currentHealth .. "/" .. data.maxHealth .. " | Armor: " .. data.armor)
                end
            end
        
        -- /crop [cropId]
        elseif command == "/crop" then
            if services.FarmingService then
                local cropCount = 0
                for _, _ in pairs(services.FarmingService.plantedCrops) do
                    cropCount = cropCount + 1
                end
                print("Cultures actives: " .. cropCount)
            end
        end
    end)
end)
```

---

## 🐛 Débogage

### Problème : Les RemoteEvents ne sont pas créés

**Solution :** Vérifiez que `src/server/init.lua` est bien le point d'entrée et qu'il s'exécute en premier.

### Problème : Service non initialisé

**Solution :** Vérifiez l'ordre de chargement dans `init.lua`. Les services doivent être créés avant d'être démarrés.

### Problème : Les cultures ne poussent pas

**Vérifications :**
1. Le FarmingService est-il démarré ? (vérifier la console)
2. La boucle de mise à jour s'exécute-t-elle ? (ajouter des `print()`)
3. Le temps de croissance est-il correct dans `ItemTypes` ?

### Problème : Les attaques ne fonctionnent pas

**Vérifications :**
1. Le CombatService est-il démarré ?
2. Le joueur a-t-il une arme équipée ?
3. La distance est-elle valide ?
4. Les joueurs sont-ils dans la même tribu (protection) ?

---

## 📊 Surveillance des performances

### Vérifier l'état des services

```lua
-- Dans la console serveur
print("Services actifs:")
for name, service in pairs(services) do
    print("  - " .. name)
end
```

### Vérifier les cultures actives

```lua
print("Cultures:", #services.FarmingService.plantedCrops)
```

### Vérifier les joueurs en combat

```lua
local inCombat = 0
for _, data in pairs(services.CombatService.playerCombatData) do
    if data.isInCombat then
        inCombat = inCombat + 1
    end
end
print("Joueurs en combat:", inCombat)
```

---

## 🎯 Prochaines étapes

1. **Tester les systèmes** avec plusieurs joueurs
2. **Créer les assets 3D** pour les cultures et armes
3. **Développer les interfaces utilisateur** pour le farming et le combat
4. **Équilibrer les valeurs** (dégâts, temps de croissance, coûts)
5. **Ajouter des animations** pour les actions

---

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez la **console Output** pour les erreurs
2. Vérifiez que tous les **services sont démarrés**
3. Vérifiez que les **RemoteEvents sont créés**
4. Consultez `SYSTEMES_AJOUTES.md` pour la documentation complète

---

## ✅ Checklist de vérification

- [ ] Rojo connecté et synchronisé
- [ ] Tous les services démarrés sans erreur
- [ ] RemoteEvents créés (24 events + 4 functions)
- [ ] Script de test créé et fonctionnel
- [ ] Test de plantation réussi
- [ ] Test de combat réussi
- [ ] Pas d'erreurs dans la console

**Bon jeu ! 🎮**
