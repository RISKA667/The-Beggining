# 🔍 Incohérences et Problèmes de Gameplay Détectés

*Analyse du code - 7 Octobre 2025*

---

## ✅ Problèmes Résolus

### 1. **API Roblox Obsolète** ✅ **RÉSOLU**
**Fichiers concernés:** `ResourceService.lua` (lignes 320-330), `FarmingService.lua` (ligne 156)

**Statut:** ✅ **CORRIGÉ**  
L'ancien système `Ray.new()` a été remplacé par le nouveau `Workspace:Raycast()` avec `RaycastParams`.

```lua
-- Code actuel (CORRECT)
local raycastParams = RaycastParams.new()
raycastParams.FilterDescendantsInstances = {resource}
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
local raycastResult = Workspace:Raycast(rayStart, rayDirection, raycastParams)
```

**Impact:** ✅ Compatible avec les futures versions de Roblox

---

### 2. **Constructions sur les Ressources** ✅ **RÉSOLU**
**Fichiers concernés:** `BuildingService.lua` (lignes 324-352)

**Statut:** ✅ **CORRIGÉ**  
La fonction `CheckPlacementValidity()` vérifie maintenant :
- ✅ Vérification 3: Distance minimale de 5 studs avec les ressources naturelles
- ✅ Vérification 4: Distance minimale de 3 studs avec les cultures
- ✅ Les joueurs ne peuvent plus construire sur ou trop près des ressources/cultures

---

### 3. **Ressources Bloquent les Constructions** ✅ **RÉSOLU**
**Fichiers concernés:** `ResourceService.lua` (lignes 205-238)

**Statut:** ✅ **CORRIGÉ**  
- ✅ Fonction `IsValidResourcePosition()` vérifie distance minimale de 8 studs avec les constructions
- ✅ Le respawn vérifie si une construction a été placée (lignes 558-568)
- ✅ Distance minimale entre ressources : 5 studs
- ✅ La ressource est définitivement retirée si position occupée

---

### 4. **Combat vs Structures** ✅ **IMPLÉMENTÉ**
**Fichiers concernés:** `CombatService.lua` (lignes 362-471), `BuildingService.lua` (lignes 923-944)

**Statut:** ✅ **IMPLÉMENTÉ**  
Le système de combat peut maintenant endommager les structures :
- ✅ Fonction `AttackStructure()` dans CombatService
- ✅ Fonction `DamageStructure()` dans BuildingService
- ✅ Vérification des permissions tribales
- ✅ Calcul des dégâts selon l'arme (structures prennent 50% des dégâts d'arme)
- ✅ Les outils font plus de dégâts aux structures
- ✅ RemoteEvent `AttackStructure` créé automatiquement

```lua
-- CombatService ligne 362-471
function CombatService:AttackStructure(attacker, structureId, hitPart)
    -- Vérification cooldown, distance, permissions
    -- Calcul des dégâts
    -- Appel à BuildingService:DamageStructure()
end
```

---

## 🔴 Problèmes Critiques Restants

### 5. **Arrosage sans Consommation d'Eau**
**Fichier:** `FarmingService.lua` (lignes 319-346)

**Problème:** Le système vérifie qu'on a `water_container` mais **ne le consomme jamais**

```lua
-- Ligne 320: Vérification
if not self.inventoryService:HasItemInInventory(player, "water_container", 1) then

-- MAIS aucun RemoveItemFromInventory après !
```

**Impact:** Eau infinie pour l'agriculture

**Solution:** Ajouter après la ligne 339 :
```lua
self.inventoryService:RemoveItemFromInventory(player, "water_container", 1)
```

**Temps estimé:** 15-30 minutes

---

### 6. **Multiplicateur d'Outils Non Appliqué Correctement**
**Fichier:** `ResourceService.lua` (ligne 491)

**Problème:** Le multiplicateur de récolte est appliqué avec `math.floor()`

```lua
local amount = math.floor(baseAmount * toolMultiplier)
```

**Incohérence:** 
- Si `baseAmount = 1` et `toolMultiplier = 1.5`
- Résultat = `floor(1.5)` = **1** (pas de bonus!)

**Solution:** Utiliser `math.ceil()` ou revoir la logique
```lua
local amount = math.ceil(baseAmount * toolMultiplier)
```

**Temps estimé:** 15 minutes

---

### 7. **Cultures Perdues si Inventaire Plein**
**Fichiers concernés:** `FarmingService.lua` (lignes 294-312)

**Problème:** Si l'inventaire est plein :
- **Ressources:** Restent récoltables (bon) ✅
- **Cultures:** Sont **détruites définitivement** (ligne 307) ❌

**Incohérence:** Les cultures devraient rester récoltables comme les ressources

**Solution:** Remplacer ligne 307-312 par :
```lua
if success then
    -- Détruire la culture
    self:DestroyCrop(cropId)
    return true
else
    self:SendNotification(player, "Inventaire plein, la plante reste prête à récolter", "warning")
    return false
end
```

**Temps estimé:** 20 minutes

---

## 🟡 Problèmes Majeurs

### 8. **Pas de Protection des Ressources Tribales**
**Fichiers concernés:** `ResourceService.lua`, `TribeService.lua`

**Problème:** Les ressources sur territoire tribal peuvent être récoltées par **n'importe qui**

**Incohérence:**
- Les constructions vérifient les permissions tribales (BuildingService ligne 354-377) ✅
- Les ressources ne vérifient **jamais** si on est sur un territoire tribal ❌
- N'importe quel joueur peut piller les ressources d'une tribu

**Solution:** Ajouter dans `ResourceService:HandleResourceClick()` après ligne 378 :
```lua
-- Vérifier la protection tribale
if self.tribeService then
    local resourcePosition = resourceInstance.PrimaryPart.Position
    local isOnTribalLand, tribeId = self.tribeService:IsPositionInTribeTerritory(resourcePosition)
    
    if isOnTribalLand then
        local playerTribeId = self.tribeService:GetPlayerTribeId(player)
        if playerTribeId ~= tribeId then
            self:SendNotification(player, "Cette ressource est sur un territoire tribal protégé", "error")
            return
        end
    end
end
```

**Temps estimé:** 2-3 heures (nécessite ajout de fonction dans TribeService)

---

### 9. **Cultures Invincibles**
**Fichier:** `FarmingService.lua` (ligne 97)

**Problème:** Les cultures ont un attribut `health = 100` mais **aucun système ne l'utilise**

**Incohérence:**
- Les cultures ne peuvent pas être endommagées
- Un ennemi ne peut pas détruire les cultures d'une tribu adverse
- Pas de système de piétinement ou de dégâts environnementaux

**Solution:** Implémenter dans `FarmingService` :
```lua
function FarmingService:DamageCrop(cropId, damage, cause)
    local cropData = self.plantedCrops[cropId]
    if not cropData then return false end
    
    cropData.health = math.max(0, cropData.health - damage)
    
    if cropData.health <= 0 then
        self:DestroyCrop(cropId)
        return true
    end
    
    return true
end
```

Et connecter avec `CombatService` pour permettre attaques sur cultures.

**Temps estimé:** 1-2 heures

---

### 10. **Système de Sommeil Non Implémenté**
**Fichiers concernés:** `BuildingService.lua` (lignes 664-679), `SurvivalService.lua` (lignes 556-618)

**Problème:** Les lits déclenchent un événement `PlayerAction:FireClient(player, "sleep")` mais :
- `SurvivalService` a des fonctions `StartSleeping` et `StopSleeping` ✅
- Elles sont présentes mais **pas connectées aux lits** ❌
- L'événement côté client n'est **pas géré** ❌
- Les lits ont un attribut `sleepQuality` inutilisé

**Solution:** Connecter `BuildingService:HandleBedInteraction()` avec `SurvivalService:StartSleeping()` :
```lua
-- Dans BuildingService ligne 677
function BuildingService:HandleBedInteraction(player, structureId)
    local structureData = self.structuresById[structureId]
    if not structureData then return end
    
    if not self:CanPlayerInteractWithStructure(player, structureId) then
        self:SendNotification(player, "Vous n'avez pas accès à ce lit", "error")
        return
    end
    
    -- Appeler le SurvivalService
    if self.survivalService then
        self.survivalService:StartSleeping(player, structureId)
    end
end
```

**Temps estimé:** 2-3 heures (inclut implémentation côté client)

---

## 🟢 Problèmes Mineurs

### 11. **Régénération de Santé Non Liée à la Survie**
**Fichier:** `CombatService.lua` (lignes 601-609)

**Problème:** Régénération hors combat : **0.5 HP/seconde** = récupération complète en **200 secondes (3min 20s)**

**Incohérence avec:** Le système de survie qui gère faim/soif/énergie devrait influencer la régénération

**Suggestion:** 
```lua
-- Dans CombatService:UpdateCombatStates() ligne 602
if not combatData.isInCombat and combatData.currentHealth < combatData.maxHealth then
    local regenRate = 0.5
    
    -- Modifier selon la survie
    if self.survivalService then
        local survivalData = self.survivalService.playerSurvivalData[userId]
        if survivalData then
            -- Ralentir si faim < 30%
            if survivalData.hunger < 30 then
                regenRate = regenRate * 0.5
            end
            -- Arrêter si soif < 20%
            if survivalData.thirst < 20 then
                regenRate = 0
            end
        end
    end
    
    combatData.currentHealth = math.min(combatData.maxHealth, combatData.currentHealth + regenRate)
end
```

**Temps estimé:** 1 heure

---

### 12. **Portes avec Animation Buggée**
**Fichier:** `BuildingService.lua` (lignes 579-628)

**Problème:** L'animation d'ouverture de porte utilise une interpolation qui peut causer des bugs si spam-clic

```lua
-- Ligne 617: Interpolation avec Lerp
connection = game:GetService("RunService").Heartbeat:Connect(function()
    -- Si le joueur spam-clique, plusieurs animations peuvent se chevaucher
end)
```

**Solution:** Ajouter un debounce :
```lua
-- Ajouter attribut
doorModel:SetAttribute("DoorAnimating", false)

-- Dans MouseClick
if doorModel:GetAttribute("DoorAnimating") then return end
doorModel:SetAttribute("DoorAnimating", true)

-- À la fin de l'animation
doorModel:SetAttribute("DoorAnimating", false)
```

**Temps estimé:** 30 minutes

---

### 13. **Pas de Limite de Constructions par Joueur**
**Fichier:** `BuildingService.lua`

**Problème:** Aucune limite sur le nombre de structures qu'un joueur peut construire

**Impact:**
- Spam de constructions possible
- Lag serveur si un joueur construit 1000+ structures
- Pas de gestion mémoire

**Solution:** Ajouter `maxStructuresPerPlayer = 100` dans `GameSettings` et vérifier dans `PlaceBuilding()`

**Temps estimé:** 1 heure

---

### 14. **Pas de Collision entre Joueurs et Cultures**
**Fichier:** `FarmingService.lua` (ligne 190)

```lua
primaryPart.CanCollide = false
```

**Problème:** Les joueurs traversent les cultures

**Suggestion:** Les plantes matures devraient avoir une collision légère
```lua
-- Adapter selon le stade
if cropData.stage >= 4 then
    primaryPart.CanCollide = true
else
    primaryPart.CanCollide = false
end
```

**Temps estimé:** 30 minutes

---

### 15. **Durabilité des Structures Jamais Dégradée Naturellement**
**Fichier:** `BuildingService.lua` (lignes 907-921)

**Problème:** La boucle `CheckDamagedStructures()` vérifie les structures endommagées mais **rien ne les endommage naturellement**

**Manque:**
- Pas de dégradation temporelle
- Pas de dégâts météorologiques
- Pas d'impact des saisons
- Seules les attaques de joueurs causent des dégâts

**Suggestion:** Ajouter dégradation progressive (optionnel pour alpha)
```lua
-- Dans BuildingService:CheckDamagedStructures()
for structureId, structureData in pairs(self.structuresById) do
    local age = os.time() - structureData.creationTime
    local daysOld = age / (24 * 60 * 60)
    
    -- Dégradation de 1 point par jour
    if daysOld > 1 then
        self:DamageStructure(structureId, 1, "natural_decay")
        structureData.creationTime = os.time() -- Réinitialiser
    end
end
```

**Temps estimé:** 2-3 heures

---

## 📊 Tableau Récapitulatif

| # | Problème | Sévérité | Statut | Temps Fix | Bloquant Alpha ? |
|---|----------|----------|--------|-----------|------------------|
| 1 | API Obsolète | 🟢 Résolu | ✅ | - | - |
| 2 | Construction sur ressources | 🟢 Résolu | ✅ | - | - |
| 3 | Respawn sur constructions | 🟢 Résolu | ✅ | - | - |
| 4 | Combat vs Structures | 🟢 Résolu | ✅ | - | - |
| 5 | Eau infinie arrosage | 🔴 Critique | ❌ | 30 min | ✅ OUI |
| 6 | Multiplicateur floor() | 🔴 Critique | ❌ | 15 min | ✅ OUI |
| 7 | Cultures perdues inventaire plein | 🔴 Critique | ❌ | 20 min | ✅ OUI |
| 8 | Pas de protection tribale | 🟡 Majeur | ❌ | 2-3h | ⚠️ Recommandé |
| 9 | Cultures invincibles | 🟡 Majeur | ❌ | 1-2h | ⚠️ Recommandé |
| 10 | Sommeil non implémenté | 🟡 Majeur | ⚠️ | 2-3h | ⚠️ Recommandé |
| 11 | Regen trop rapide | 🟢 Mineur | ❌ | 1h | ❌ NON |
| 12 | Animation portes | 🟢 Mineur | ❌ | 30 min | ❌ NON |
| 13 | Pas de limite constructions | 🟢 Mineur | ❌ | 1h | ❌ NON |
| 14 | Cultures sans collision | 🟢 Mineur | ❌ | 30 min | ❌ NON |
| 15 | Durabilité jamais dégradée | 🟢 Mineur | ❌ | 2-3h | ❌ NON |

---

## 🎯 Recommandations Prioritaires

### Court Terme (Alpha Jouable - OBLIGATOIRE)
1. ✅ ~~Corriger le spawn de ressources sur constructions~~ **FAIT**
2. ✅ ~~Empêcher les constructions sur les ressources existantes~~ **FAIT**
3. ✅ ~~Implémenter combat vs structures~~ **FAIT**
4. ❌ **Ajouter la consommation d'eau pour l'arrosage** (30 min)
5. ❌ **Corriger le multiplicateur d'outils** (15 min)
6. ❌ **Empêcher perte de cultures si inventaire plein** (20 min)

**Total temps : 1 heure 5 minutes** ⏰

### Moyen Terme (Alpha Jouable - RECOMMANDÉ)
7. ❌ Ajouter la protection territoriale des ressources (2-3h)
8. ❌ Permettre la destruction des cultures (1-2h)
9. ❌ Finaliser le système de sommeil (2-3h)
10. ❌ Lier régénération à la survie (1h)

**Total temps : 6-9 heures** ⏰

### Long Terme (Post-Alpha)
11. Système de dégradation naturelle des structures
12. Intégration complète combat-survie-farming
13. Limites et optimisations de performance
14. Système de saisons affectant tous les systèmes

---

## ✅ Progrès Réalisés

**4 problèmes critiques résolus depuis la dernière analyse :**
1. ✅ API Ray.new() remplacée par Raycast
2. ✅ Protection contre construction sur ressources
3. ✅ Protection contre respawn sur constructions
4. ✅ Combat peut endommager les structures

**Excellente progression ! Le code utilise maintenant les API modernes.**

---

*Document généré automatiquement suite à l'analyse du code*  
*Dernière analyse : 7 Octobre 2025*
