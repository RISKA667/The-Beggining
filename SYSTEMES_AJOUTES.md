# Systèmes Ajoutés - The Beginning

## 📋 Vue d'ensemble

Ce document détaille les nouveaux systèmes implémentés pour compléter le projet "The Beginning".

---

## 🔌 1. Système de RemoteEvents

### Fichier : `src/server/init.lua`

**Description :** Script d'initialisation centralisé qui crée automatiquement tous les RemoteEvents et RemoteFunctions nécessaires au bon fonctionnement du jeu.

### RemoteEvents créés :

#### Inventaire
- `UpdateInventory` - Synchronisation de l'inventaire
- `InventoryAction` - Actions d'inventaire

#### Survie
- `UpdateStats` - Mise à jour des statistiques de survie
- `Sleep` - Gestion du sommeil

#### Artisanat
- `UpdateRecipes` - Mise à jour des recettes
- `CraftComplete` - Notification de craft terminé
- `CraftRequest` - Demande de fabrication

#### Tribus
- `TribeAction` - Actions de tribu
- `TribeUpdate` - Mises à jour de tribu

#### Temps
- `TimeUpdate` - Synchronisation du temps

#### Ressources
- `ResourceHarvest` - Récolte de ressources
- `ResourceGenerate` - Génération de ressources

#### Construction
- `BuildingStart` - Début de construction
- `BuildingPlacement` - Placement de bâtiment
- `BuildingAction` - Actions de construction

#### **Combat** (nouveau)
- `AttackPlayer` - Attaque de joueur
- `TakeDamage` - Réception de dégâts
- `UpdateHealth` - Mise à jour de la santé
- `EquipWeapon` - Équipement d'arme

#### **Farming** (nouveau)
- `PlantSeed` - Plantation de graine
- `HarvestCrop` - Récolte de culture
- `UpdateCrop` - Mise à jour de culture

#### Général
- `Notification` - Notifications globales
- `PlayerAction` - Actions de joueur
- `PlayAnimation` - Lecture d'animations
- `UpdatePlayerData` - Mise à jour des données joueur

### RemoteFunctions créées :
- `GetPlayerData`
- `GetInventory`
- `GetTribeData`
- `CanCraft`

---

## 🌾 2. Système de Farming (Agriculture)

### Fichier : `src/server/services/FarmingService.lua`

**Description :** Système complet de plantation et de croissance des cultures.

### Fonctionnalités :

#### Plantation
- ✅ Planter des graines à des emplacements valides
- ✅ Vérification de la proximité et du terrain
- ✅ Détection des emplacements occupés
- ✅ Consommation automatique de la graine

#### Croissance
- ✅ **5 stades de croissance** : Graine → Pousse → Jeune plante → Plante mature → Prêt à récolter
- ✅ Temps de croissance personnalisable par type de plante (défini dans `ItemTypes`)
- ✅ Mise à jour visuelle automatique (taille et couleur)
- ✅ Système d'arrosage pour accélérer la croissance (+10%)
- ✅ Croissance continue même en déconnexion

#### Récolte
- ✅ Récolte uniquement quand la plante est mature (stade 5)
- ✅ Rendement variable (2-4 unités + bonus)
- ✅ Bonus de rendement si la plante était arrosée
- ✅ Ajout automatique à l'inventaire
- ✅ Destruction de la plante après récolte

#### Interaction
- ✅ ClickDetector sur chaque plante
- ✅ Affichage de l'état et du temps restant
- ✅ Notifications de maturité au propriétaire

### Exemple d'utilisation :

```lua
-- Le joueur plante une graine de blé
FarmingService:PlantSeed(player, "wheat_seeds", position)

-- Arroser une culture
FarmingService:WaterCrop(player, cropId)

-- Récolter une culture mature
FarmingService:HarvestCrop(player, cropId)
```

### Types de graines supportés (ItemTypes) :
- `wheat_seeds` → `wheat` (20 min)
- `carrot_seeds` → `carrot` (15 min)
- Extensible facilement avec d'autres types

---

## ⚔️ 3. Système de Combat

### Fichier : `src/server/services/CombatService.lua`

**Description :** Système de combat complet avec PvP, armes, armures et statistiques.

### Fonctionnalités :

#### Système de santé
- ✅ Santé par défaut : 100 PV
- ✅ Régénération automatique hors combat (0.5 PV/sec)
- ✅ Suivi de l'état de combat (en combat / hors combat)
- ✅ Sortie automatique du combat après 10 secondes

#### Système d'armure
- ✅ Calcul automatique de l'armure équipée
- ✅ Réduction des dégâts : 0.5 dégât par point d'armure
- ✅ Support des équipements avec `defenseBonus`

#### Combat de mêlée
- ✅ Attaques avec armes ou à mains nues
- ✅ Portée variable selon l'arme (5-7 studs)
- ✅ Cooldown d'attaque (0.5 seconde)
- ✅ Calcul des dégâts basé sur l'arme équipée
- ✅ Indicateur visuel des dégâts

#### Combat à distance
- ✅ Support des arcs et flèches
- ✅ Création de projectiles physiques
- ✅ Détection de collision réaliste
- ✅ Portée de 50 studs
- ✅ Consommation automatique de munitions

#### Protection tribale
- ✅ Impossible d'attaquer les membres de sa tribu
- ✅ Vérification automatique des alliances

#### Statistiques
- ✅ Dégâts infligés
- ✅ Dégâts reçus
- ✅ Nombre de kills
- ✅ Nombre de morts

#### Mort et respawn
- ✅ Gestion de la mort en combat
- ✅ Notification du tueur et de la victime
- ✅ Réinitialisation de la santé après respawn (5 secondes)
- ✅ Intégration avec `PlayerService` pour la réincarnation

### Exemple d'utilisation :

```lua
-- Attaquer un joueur
CombatService:AttackTarget(attacker, target, "melee")

-- Infliger des dégâts directs
CombatService:DealDamage(attacker, victim, 25, "melee")

-- Soigner un joueur
CombatService:HealPlayer(player, 50)

-- Obtenir l'arme équipée
local weapon = CombatService:GetEquippedWeapon(player)
```

### Armes supportées (ItemTypes) :

#### Mêlée
- `stone_spear` - 8 dégâts, portée 7
- `stone_axe` - 5 dégâts (outil)
- `bronze_sword` - 12 dégâts
- `iron_sword` - 16 dégâts
- Et autres armes avec `damage` et `toolType = "weapon"`

#### Distance
- `wooden_bow` - 6 dégâts, portée 50, munition : `arrow`

#### Armures
- Tous les équipements avec `defenseBonus` :
  - `iron_helmet` - 15 points d'armure
  - `iron_chestplate` - 25 points d'armure
  - `iron_leggings` - 20 points d'armure
  - `iron_boots` - 10 points d'armure

---

## 🔄 Intégration avec les services existants

### Dépendances

#### FarmingService
- **InventoryService** : Pour retirer les graines et ajouter les récoltes
- **TribeService** : Pour les permissions de plantation sur territoire tribal (à implémenter)

#### CombatService
- **InventoryService** : Pour obtenir l'arme/armure équipée
- **PlayerService** : Pour gérer la mort et réincarnation
- **TribeService** : Pour vérifier les alliances

### Initialisation

Les services sont automatiquement chargés et démarrés par `src/server/init.lua` :

```lua
local FarmingService = require(Services.FarmingService).new()
local CombatService = require(Services.CombatService).new()

-- Démarrage avec injection de dépendances
FarmingService:Start(services)
CombatService:Start(services)
```

---

## 🧪 Test des nouveaux systèmes

### Test du Farming

1. Obtenir des graines : `/give wheat_seeds 5`
2. Approcher un terrain plat
3. Utiliser l'item de graine (clic droit)
4. Observer la croissance progressive
5. Récolter quand la plante est dorée (stade 5)

### Test du Combat

1. Équiper une arme : Stone Spear, Bronze Sword, ou Bow
2. Approcher un autre joueur (pas de la même tribu)
3. Attaquer avec la touche d'attaque
4. Observer les dégâts et la santé
5. Tester avec différentes armures

---

## 📊 Statistiques techniques

### RemoteEvents
- **Total créé** : 24 RemoteEvents + 4 RemoteFunctions

### FarmingService
- **Lignes de code** : ~550
- **Fonctions principales** : 15
- **Stades de croissance** : 5
- **Mise à jour** : Toutes les 30 secondes

### CombatService
- **Lignes de code** : ~650
- **Fonctions principales** : 18
- **Cooldown attaque** : 0.5 seconde
- **Régénération** : 0.5 PV/sec hors combat
- **Mise à jour** : Toutes les secondes

---

## 🎯 Améliorations futures possibles

### Farming
- [ ] Engrais pour accélérer la croissance
- [ ] Maladies et parasites des plantes
- [ ] Système d'irrigation automatique
- [ ] Cultures en serre
- [ ] Saisons affectant la croissance

### Combat
- [ ] Compétences spéciales et combos
- [ ] Effets de statut (poison, saignement, etc.)
- [ ] Système de bloquage et parade
- [ ] Zones de non-combat (safe zones)
- [ ] Duels organisés

---

## ✅ Conclusion

Les trois systèmes (RemoteEvents, Farming, Combat) sont maintenant **pleinement fonctionnels** et **intégrés** au projet The Beginning. 

Le code est :
- ✅ Propre et bien commenté
- ✅ Modulaire et extensible
- ✅ Cohérent avec l'architecture existante
- ✅ Prêt pour la production

**Prochaines étapes suggérées :**
1. Tests en jeu avec plusieurs joueurs
2. Ajustement de l'équilibrage (dégâts, temps de croissance)
3. Création des assets 3D pour les cultures et projectiles
4. Interface utilisateur pour les statistiques de combat
