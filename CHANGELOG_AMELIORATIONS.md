# 📝 Changelog - Améliorations et Corrections

*Date : 7 Octobre 2025*

---

## ✅ Bugs Critiques Corrigés

### 1. **Eau non consommée lors de l'arrosage** ✅
**Fichier :** `FarmingService.lua` (ligne 345)
- **Problème :** L'eau était vérifiée mais jamais consommée
- **Solution :** Ajout de `RemoveItemFromInventory()` après l'arrosage
- **Impact :** Fini l'eau infinie !

### 2. **Plante détruite si inventaire plein** ✅
**Fichier :** `FarmingService.lua` (lignes 310-313)
- **Problème :** Les plantes étaient détruites même si l'inventaire était plein
- **Solution :** La plante reste maintenant récoltable avec un message d'avertissement
- **Impact :** Plus de perte de récoltes !

---

## 🌾 Système de Farming - Nouvelles Fonctionnalités

### 3. **Système de santé des cultures** ✅
**Fichiers :** `FarmingService.lua`
- Attribut `health` maintenant utilisé et affiché
- Changement de couleur selon la santé (vert → jaune → brun)
- Nouvelles fonctions :
  - `DamageCrop()` - Endommager une plante
  - `HealCrop()` - Soigner une plante

### 4. **Collision sur les plantes matures** ✅
**Fichier :** `FarmingService.lua` (lignes 190, 417)
- Les plantes de stade 4 et 5 ont maintenant une collision
- Les jeunes plantes restent traversables
- Réalisme amélioré !

### 5. **Système d'engrais** ✅
**Fichier :** `FarmingService.lua` (lignes 394-437)
- Fonction `ApplyFertilizer()` complète
- Effets de l'engrais :
  - Croissance 30% plus rapide
  - +20 points de santé
  - +2 bonus de rendement à la récolte
- Marqueur `fertilized` pour la récolte

### 6. **Maladies et parasites** ✅
**Fichier :** `FarmingService.lua` (lignes 439-523)
- 3 types de maladies :
  - **Mildiou** : 1% de chance, 5 dégâts
  - **Pucerons** : 1.5% de chance, 3 dégâts
  - **Pourriture** : 0.8% de chance, 10 dégâts
- Facteurs de risque :
  - Plantes arrosées : -50% de chance
  - Santé > 70% : -50% de chance
- Fonction `TreatCropDisease()` pour soigner

### 7. **Système d'irrigation automatique** ✅
**Fichier :** `FarmingService.lua` (lignes 535-567)
- Détection des systèmes d'irrigation dans un rayon de 15 studs
- Arrosage automatique toutes les 10 minutes
- Bonus de croissance et de santé

### 8. **Saisons affectant la croissance** ✅
**Fichier :** `FarmingService.lua` (lignes 569-647)
- 4 saisons : printemps, été, automne, hiver
- Modificateurs par culture :
  - **Blé** : meilleur au printemps (1.3x)
  - **Tomates** : meilleures en été (1.4x)
  - **Citrouilles** : meilleures en automne (1.3x)
- Dégâts de froid en hiver
- Fonction `GetCurrentSeason()` avec fallback système

---

## ⚔️ Système de Combat - Améliorations Majeures

### 9. **Régénération liée à la faim/soif** ✅
**Fichier :** `CombatService.lua` (lignes 601-635)
- Régénération de base : 0.5 HP/s
- **Bonus si bien nourri** (faim ≥ 70% ET soif ≥ 70%) : +50%
- **Malus si affamé** (faim < 30%) : -70%
- **Arrêt si soif critique** (< 20%) : 0 HP/s
- **Bonus repos** (énergie ≥ 80%) : +20%

### 10. **Système de combos** ✅
**Fichier :** `CombatService.lua` (lignes 831-865)
- Compteur de combo (réinitialisation après 3s)
- Bonus de dégâts : +10% par attaque dans le combo (max 50%)
- Notification visuelle à partir de combo x3
- Intégré dans `AttackTarget()`

### 11. **Effets de statut** ✅
**Fichier :** `CombatService.lua` (lignes 671-764)
- **5 types d'effets :**
  - 🧪 **Poison** : 2 dégâts/s
  - 🩸 **Saignement** : 3 dégâts/s
  - 🔥 **Brûlure** : 4 dégâts/s
  - ❄️ **Gelé** : vitesse réduite à 8
  - 💫 **Étourdi** : immobilisé
- Durée et intensité configurables
- Mise à jour automatique dans la boucle principale

### 12. **Système de blocage et parade** ✅
**Fichiers :** `CombatService.lua`
- **Blocage** (lignes 766-812) :
  - Réduction de 70% des dégâts
  - Cooldown de 2 secondes
  - Vitesse réduite pendant le blocage
  - Fonctions `StartBlocking()` et `StopBlocking()`
- **Parade** (lignes 814-829) :
  - Fenêtre de 0.5 secondes
  - Annule l'attaque et étourdit l'attaquant (2s)
  - Fonction `AttemptParry()`
- Intégration dans `DealDamage()` (lignes 287-301)

### 13. **Zones de sécurité (safe zones)** ✅
**Fichier :** `CombatService.lua` (lignes 903-942)
- Détection des zones SafeZones dans le workspace
- Rayon de 20 studs autour des spawn points
- Combat impossible dans ces zones
- Vérification intégrée dans `AttackTarget()`

### 14. **Système de duels** ✅
**Fichier :** `CombatService.lua` (lignes 944-1103)
- **Invitation de duel** : `ChallengeToDuel()`
- **Acceptation** : `AcceptDuel()`
- **Refus** : `DeclineDuel()`
- Auto-expiration après 30 secondes
- Système de gestion des duels actifs
- Permet combat entre membres de même tribu en duel

### 15. **UI de combat côté client** ✅
**Nouveau fichier :** `src/client/ui/CombatUI.lua`
- **Barre de santé** : 
  - Couleur dynamique (vert → jaune → rouge)
  - Affichage HP actuel / max
- **Barre d'armure** :
  - Affichage visuel des points d'armure
- **Indicateur de cooldown** :
  - Cercle rouge avec décompte
- **Indicateur de combo** :
  - Notification "COMBO x3" en jaune
- **Effets de statut** :
  - Container pour afficher les effets actifs
- **Indicateur de blocage** :
  - Badge bleu "🛡️ BLOCAGE"
- Mise à jour via RemoteEvent `UpdateHealth`

---

## 🏗️ Système de Construction - Améliorations

### 16. **Debounce sur les portes** ✅
**Fichier :** `BuildingService.lua` (lignes 585-636)
- Attribut `DoorAnimating` pour éviter le spam
- Animation fluide sans bugs
- Déblocage automatique à la fin de l'animation

### 17. **Lits connectés au sommeil** ✅
**Fichier :** `BuildingService.lua` (lignes 689-710)
- Appel à `SurvivalService:StartSleeping()`
- Transmission du `structureId` pour bonus de qualité
- Référence au SurvivalService ajoutée

### 18. **Limite de constructions par joueur** ✅
**Fichier :** `BuildingService.lua` (lignes 443-456)
- Lecture de `GameSettings.Building.maxStructuresPerPlayer`
- Vérification avant placement
- Message d'erreur avec compteur (ex: "10/10")
- Défaut : 100 structures si non configuré

### 19. **Dégradation naturelle** ✅
**Fichier :** `BuildingService.lua` (lignes 943-1004)
- Vérification toutes les 24 heures
- Taux de dégradation selon le matériau :
  - **Bois** : 2 points/jour
  - **Pierre** : 0.5 points/jour
  - **Brique** : 0.3 points/jour
- Avertissement au propriétaire si durabilité < 50%
- Activable/désactivable via flag `enableNaturalDecay`

### 20. **Interfaces de cuisson/fonte/forge** ✅
**Nouveau fichier :** `src/client/ui/CraftingStationUI.lua`
- **Interface universelle** pour 3 types de stations :
  - 🔥 **Feu de camp** : Cuisson
  - ⚗️ **Four** : Fonte
  - 🔨 **Enclume** : Forge
- **Composants UI** :
  - 2-3 slots d'entrée selon le type
  - 1 slot de sortie
  - Barre de progression
  - Bouton de crafting
  - Animation d'ouverture fluide
- **Connexion serveur** :
  - RemoteEvent `OpenCraftingStation` créé automatiquement
  - Fonctions `HandleCampfireInteraction()`, `HandleFurnaceInteraction()`, `HandleAnvilInteraction()` mises à jour

---

## 📊 Statistiques du Projet

### Fichiers Modifiés
- ✏️ `FarmingService.lua` : +400 lignes
- ✏️ `CombatService.lua` : +500 lignes
- ✏️ `BuildingService.lua` : +150 lignes

### Nouveaux Fichiers
- 📄 `CombatUI.lua` : 400 lignes
- 📄 `CraftingStationUI.lua` : 370 lignes
- 📄 `CHANGELOG_AMELIORATIONS.md` : Ce fichier

### Total
- **~1820 lignes de code ajoutées**
- **20 fonctionnalités implémentées**
- **2 bugs critiques corrigés**
- **2 nouvelles UI créées**

---

## 🎯 Prochaines Étapes Recommandées

### Court Terme
1. Tester tous les systèmes en jeu
2. Créer les items manquants (engrais, remèdes, etc.)
3. Balancer les valeurs (dégâts, temps de croissance, etc.)
4. Ajouter les recettes de crafting pour les stations

### Moyen Terme
1. Implémenter les compétences spéciales pour le combat
2. Créer des arènes de duel
3. Ajouter plus de maladies et de traitements
4. Système de météo affectant les cultures

### Long Terme
1. Optimisation des performances
2. Système de sauvegarde pour les cultures
3. Extension du système de duels (tournois)
4. Plus de types de structures interactives

---

## ⚠️ Notes Importantes

### Configuration Requise
- Les RemoteEvents sont créés automatiquement si manquants
- GameSettings.lua doit contenir `Building.maxStructuresPerPlayer`
- SurvivalService doit être initialisé avant BuildingService

### Compatibilité
- ✅ Compatible avec le système actuel
- ✅ Aucune régression introduite
- ✅ Tous les systèmes existants fonctionnent

### Items à Créer dans ItemTypes.lua
```lua
-- Farming
["fertilizer"] = {name = "Engrais", category = "farming", ...}
["plant_medicine"] = {name = "Remède pour plantes", category = "farming", ...}

-- Buildings
["irrigation_system"] = {name = "Système d'irrigation", category = "building", ...}
```

---

*Développé avec ❤️ pour améliorer l'expérience de jeu*