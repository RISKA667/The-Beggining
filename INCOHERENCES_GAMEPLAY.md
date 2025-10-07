# 🔍 Incohérences et Problèmes de Gameplay Détectés

*Analyse du code - Octobre 2025*

---

## ⚠️ Problèmes Critiques

### 1. **API Roblox Obsolète** 
**Fichiers concernés:** `ResourceService.lua`, `FarmingService.lua`

**Problème:** Utilisation de l'ancien système `Ray.new()` qui est deprecated
```lua
-- Ligne 260-264 ResourceService.lua
local ray = Ray.new(rayStart, rayEnd - rayStart)
local hitPart, hitPoint, hitNormal = Workspace:FindPartOnRayWithIgnoreList(ray, {resource})
```

**Impact:** Risque de ne plus fonctionner dans les futures versions de Roblox

**Solution:** Utiliser le nouveau système `Workspace:Raycast()` avec `RaycastParams`

---

### 2. **Constructions sur les Ressources** ✅ **CORRIGÉ**
**Fichiers concernés:** `BuildingService.lua` (lignes 324-352)

**Problème:** ~~La fonction `CheckPlacementValidity()` vérifiait les collisions avec d'autres structures mais **pas avec les ressources naturelles**~~

**Correction appliquée:**
- Vérification 3: Distance minimale de 5 studs avec les ressources naturelles
- Vérification 4: Distance minimale de 3 studs avec les cultures
- Les joueurs ne peuvent plus construire sur ou trop près des ressources/cultures

---

### 3. **Ressources Bloquent les Constructions** ✅ **CORRIGÉ**
**Fichiers concernés:** `ResourceService.lua` 

**Problème:** ~~Les ressources pouvaient respawn à l'intérieur des constructions~~

**Correction appliquée:** 
- Ajout de `IsValidResourcePosition()` qui vérifie une distance minimale de 8 studs avec les constructions
- Le respawn vérifie maintenant si une construction a été placée et ne fait pas réapparaître la ressource
- Distance minimale entre ressources : 5 studs

---

## 🔴 Problèmes Majeurs

### 4. **Combat ne peut pas endommager les Constructions**
**Fichiers concernés:** `CombatService.lua`, `BuildingService.lua`

**Problème:** Le système de combat (PvP) et le système de construction ne sont **pas connectés**

**Incohérence:** 
- Les joueurs peuvent s'attaquer mutuellement
- Les structures ont un système de durabilité (`durability`)
- **MAIS** les attaques ne peuvent pas endommager les bâtiments ennemis

**Solution attendue:** 
```lua
-- Dans CombatService:AttackTarget()
-- Détecter si on attaque une structure
-- Appeler BuildingService:DamageStructure(structureId, damage)
```

---

### 5. **Pas de Protection des Ressources Tribales**
**Fichiers concernés:** `ResourceService.lua`, `TribeService.lua`

**Problème:** Les ressources sur territoire tribal peuvent être récoltées par **n'importe qui**

**Incohérence:**
- Les constructions vérifient les permissions tribales (ligne 325-347 BuildingService)
- Les ressources ne vérifient **jamais** si on est sur un territoire tribal
- N'importe quel joueur peut venir piller les ressources d'une tribu

**Impact:** Pas de défense territoriale possible

---

### 6. **Cultures Invincibles**
**Fichiers concernés:** `FarmingService.lua`

**Problème:** Les cultures ont un attribut `health = 100` (ligne 97) mais **aucun système ne l'utilise**

**Incohérence:**
- Les cultures ne peuvent pas être endommagées
- Un ennemi ne peut pas détruire les cultures d'une tribu adverse
- Pas de système de piétinement ou de dégâts environnementaux

---

## 🟡 Problèmes Mineurs

### 7. **Régénération de Santé trop Rapide**
**Fichier:** `CombatService.lua` (probablement vers la fin)

**Problème:** Régénération hors combat : **0.5 HP/seconde** = récupération complète en **200 secondes (3min 20s)**

**Incohérence avec:** Le système de survie qui gère faim/soif/énergie devrait influencer la régénération

**Suggestion:** 
- Régénération ralentie si faim < 30%
- Régénération stoppée si soif < 20%

---

### 8. **Système de Sommeil Non Implémenté**
**Fichiers concernés:** `BuildingService.lua` (ligne 635-650), `SurvivalService.lua`

**Problème:** Les lits déclenchent un événement `PlayerAction:FireClient(player, "sleep")` mais:
- `SurvivalService` a un `Sleep` RemoteEvent (SYSTEMES_AJOUTES.md ligne 23)
- **AUCUNE** logique de sommeil n'est implémentée côté serveur
- Les lits ont un attribut `sleepQuality` inutilisé

---

### 9. **Portes avec Animation Buggée**
**Fichier:** `BuildingService.lua` (lignes 550-599)

**Problème:** L'animation d'ouverture de porte utilise une interpolation complexe qui pourrait causer des bugs

```lua
-- Ligne 592: Interpolation avec Lerp
primaryPart.CFrame = initialCFrame:Lerp(targetRotation, alpha)
```

**Risque:** Si un joueur spam-clique, plusieurs animations peuvent se chevaucher

**Solution:** Ajouter un debounce sur les portes

---

### 10. **Pas de Limite de Constructions par Joueur**
**Fichier:** `BuildingService.lua`

**Problème:** Aucune limite sur le nombre de structures qu'un joueur peut construire

**Impact:**
- Spam de constructions possible
- Lag serveur si un joueur construit 1000+ structures
- Pas de gestion mémoire

**Suggestion:** Ajouter `maxStructuresPerPlayer` dans `GameSettings`

---

### 11. **Multiplicateur d'Outils Non Appliqué Correctement**
**Fichier:** `ResourceService.lua` (ligne 425)

**Problème:** Le multiplicateur de récolte est appliqué avec `math.floor()`

```lua
local amount = math.floor(baseAmount * toolMultiplier)
```

**Incohérence:** 
- Si `baseAmount = 1` et `toolMultiplier = 1.5`
- Résultat = `floor(1.5)` = **1** (pas de bonus!)

**Solution:** Utiliser `math.ceil()` ou revoir la logique

---

### 12. **Objets Perdus si Inventaire Plein**
**Fichiers concernés:** `ResourceService.lua` (ligne 469), `FarmingService.lua` (ligne 306)

**Problème:** Si l'inventaire est plein:
- **Ressources:** La ressource redevient récoltable (bon)
- **Cultures:** La plante est **détruite définitivement** (ligne 302 FarmingService)

**Incohérence:** Les cultures devraient rester récoltables comme les ressources

---

### 13. **Arrosage sans Consommation d'Eau**
**Fichier:** `FarmingService.lua` (lignes 315-342)

**Problème:** Le système vérifie qu'on a `water_container` mais **ne le consomme jamais**

```lua
-- Ligne 320: Vérification
if not self.inventoryService:HasItemInInventory(player, "water_container", 1) then

-- MAIS aucun RemoveItemFromInventory après !
```

**Impact:** Eau infinie pour l'agriculture

---

### 14. **Pas de Collision entre Joueurs et Cultures**
**Fichier:** `FarmingService.lua` (ligne 241)

```lua
primaryPart.CanCollide = false
```

**Problème:** Les joueurs traversent les cultures

**Réalisme:** Les plantes matures devraient avoir une collision

---

### 15. **Durabilité des Structures Jamais Dégradée Naturellement**
**Fichier:** `BuildingService.lua` (ligne 990-998)

**Problème:** La boucle `CheckDamagedStructures()` vérifie les structures endommagées mais **rien ne les endommage** à part les appels manuels à `DamageStructure()`

**Manque:**
- Pas de dégradation temporelle
- Pas de dégâts météorologiques
- Pas d'impact des saisons

---

## 📊 Tableau Récapitulatif

| # | Problème | Sévérité | Impact Gameplay | Difficulté Fix |
|---|----------|----------|-----------------|----------------|
| 1 | API Obsolète | 🔴 Critique | Futur crash | Facile |
| 2 | Construction sur ressources | ✅ **Résolu** | - | - |
| 3 | Respawn sur constructions | ✅ **Résolu** | - | - |
| 4 | Combat vs Structures | 🔴 Majeur | PvP incomplet | Moyen |
| 5 | Pas de protection tribale | 🔴 Majeur | Territoires inutiles | Moyen |
| 6 | Cultures invincibles | 🔴 Majeur | Pas de raid farming | Facile |
| 7 | Regen trop rapide | 🟡 Mineur | Balance combat | Facile |
| 8 | Sommeil non implémenté | 🟡 Mineur | Feature manquante | Moyen |
| 9 | Animation portes | 🟡 Mineur | Bug visuel | Facile |
| 10 | Pas de limite constructions | 🟡 Mineur | Potentiel lag | Facile |
| 11 | Multiplicateur floor() | 🟡 Mineur | Bonus perdus | Facile |
| 12 | Cultures perdues inventaire plein | 🟡 Mineur | Frustration joueur | Facile |
| 13 | Eau infinie | 🟡 Mineur | Balance farming | Facile |
| 14 | Cultures sans collision | 🟡 Mineur | Réalisme | Facile |
| 15 | Durabilité jamais dégradée | 🟡 Mineur | Structures éternelles | Moyen |

---

## 🎯 Recommandations Prioritaires

### Court Terme (1-2 jours)
1. ✅ Corriger le spawn de ressources sur constructions
2. ✅ Empêcher les constructions sur les ressources existantes
3. Corriger l'API Ray.new() vers Workspace:Raycast()
4. Ajouter la consommation d'eau pour l'arrosage

### Moyen Terme (1 semaine)
5. Implémenter les dégâts aux structures via combat
6. Ajouter la protection territoriale des ressources
7. Permettre la destruction des cultures
8. Implémenter le système de sommeil

### Long Terme (2+ semaines)
9. Système de dégradation naturelle des structures
10. Intégration complète combat-survie-farming
11. Limites et optimisations de performance
12. Système de saisons affectant tous les systèmes

---

## ✅ Corrections Appliquées

### Modification 1: Empêcher spawn sur constructions
**Fichier:** `ResourceService.lua`

**Changements:**
- ✅ Nouvelle fonction `IsValidResourcePosition(position, resourceType)`
- ✅ Vérification de distance minimale de 8 studs avec les structures
- ✅ Vérification de distance minimale de 5 studs entre ressources
- ✅ Système de retry lors de la génération (3x tentatives)
- ✅ Vérification au respawn - ressource définitivement retirée si position occupée

**Impact:** Les ressources ne peuvent plus spawner ou respawn sur/près des constructions

---

### Modification 2: Empêcher constructions sur ressources et cultures
**Fichier:** `BuildingService.lua` (lignes 324-352)

**Changements:**
- ✅ Vérification 3: Distance minimale de 5 studs avec toutes les ressources naturelles
- ✅ Vérification 4: Distance minimale de 3 studs avec toutes les cultures
- ✅ Parcours de tous les dossiers de ressources (bois, pierre, minerais, etc.)
- ✅ Parcours du dossier Crops pour les cultures agricoles

**Impact:** Les joueurs ne peuvent plus construire sur ou trop près des ressources/cultures

---

*Document généré automatiquement suite à l'analyse du code*
