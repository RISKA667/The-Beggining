# Guide d'utilisation - The Beginning

Ce guide vous aidera à configurer, développer et transférer votre projet "The Beginning" de Visual Studio Code vers Roblox Studio.

## Table des matières

1. [Configuration de l'environnement](#1-configuration-de-lenvironnement)
2. [Structure du projet](#2-structure-du-projet)
3. [Développement avec Visual Studio Code](#3-développement-avec-visual-studio-code)
4. [Transfert vers Roblox Studio](#4-transfert-vers-roblox-studio)
5. [Test et débogage](#5-test-et-débogage)
6. [Continuer le développement](#6-continuer-le-développement)

## 1. Configuration de l'environnement

### Prérequis

- Visual Studio Code
- Roblox Studio
- Git (facultatif, mais recommandé pour le versionnage)

### Installation des outils

1. **Rojo**: Un outil qui vous permet de synchroniser des fichiers entre votre système de fichiers et Roblox Studio.
   ```bash
   npm install -g rojo
   ```

2. **Extensions VS Code**:
   - Roblox LSP - Fournit un support pour le langage Lua spécifique à Roblox
   - Lua - Support de base pour Lua
   - Lua Debug - Pour le débogage de code Lua

## 2. Structure du projet

Le projet suit la structure suivante:

```
the-beginning/
├── src/
│   ├── client/           # Code exécuté sur le client
│   │   ├── controllers/  # Contrôleurs client
│   │   ├── ui/           # Interfaces utilisateur
│   │   └── init.lua      # Point d'entrée client
│   ├── server/           # Code exécuté sur le serveur
│   │   ├── services/     # Services serveur
│   │   └── init.lua      # Point d'entrée serveur
│   └── shared/           # Code partagé entre client et serveur
│       ├── constants/    # Constantes et données du jeu
│       └── modules/      # Modules utilitaires
├── default.project.json  # Configuration Rojo
└── README.md             # Documentation
```

## 3. Développement avec Visual Studio Code

### Démarrer un nouveau projet

1. Créez un dossier pour votre projet
2. Initialisez la structure de fichiers comme indiqué ci-dessus
3. Placez-y tous les fichiers Lua que nous avons développés

### Commandes Rojo

Pour démarrer un serveur Rojo et permettre la synchronisation avec Roblox Studio:

```bash
cd the-beginning
rojo serve
```

Cela va démarrer un serveur sur `localhost:34872` par défaut.

## 4. Transfert vers Roblox Studio

### Méthode 1: Plugin Rojo

1. Dans Roblox Studio, installez le plugin Rojo depuis le Marketplace.
2. Démarrez un serveur Rojo avec `rojo serve` dans votre terminal.
3. Dans Roblox Studio, cliquez sur le plugin Rojo et connectez-vous au serveur.
4. Vos fichiers seront synchronisés en temps réel lors des modifications.

### Méthode 2: Build de projet

1. Construisez un fichier RBXL (place Roblox) avec la commande:
   ```bash
   rojo build -o TheBeginning.rbxl
   ```
2. Ouvrez le fichier `.rbxl` généré avec Roblox Studio.

## 5. Test et débogage

### Test dans Roblox Studio

1. Appuyez sur le bouton "Play" dans Roblox Studio pour tester votre jeu.
2. Utilisez la console de sortie pour voir les messages de débogage.

### Débogage dans VS Code

Avec l'extension Lua Debug, vous pouvez configurer le débogage pour votre code Lua:

1. Créez un fichier `.vscode/launch.json` avec la configuration appropriée.
2. Placez des points d'arrêt dans votre code.
3. Utilisez la fonction `print()` librement pour le débogage.

## 6. Continuer le développement

### Fonctionnalités à implémenter

- **ResourceService**: Service pour gérer la génération et la récolte des ressources
- **BuildingService**: Système de construction pour les structures et le mobilier
- **TimeService**: Gestion du cycle jour/nuit et du vieillissement
- **CraftingUI**: Interface utilisateur pour le système d'artisanat
- **AgeUI**: Interface utilisateur pour afficher l'âge du joueur

### Ressources et modèles

Pour continuer le développement, vous aurez besoin:

1. De modèles 3D pour:
   - Les ressources (bois, pierre, minerais)
   - Les outils et armes
   - Les bâtiments et meubles
   - Les personnages

2. De sons pour:
   - Les interactions (récolte, craft)
   - Les ambiances (jour, nuit, forêt, etc.)
   - Les événements (naissance, mort)

### Suggestions de développement

1. **Commencez petit**: Implémentez d'abord les mécaniques de base (récolte, survie) et testez-les bien.
2. **Itérez**: Ajoutez progressivement des fonctionnalités et testez-les une par une.
3. **Utilisez des placeholders**: Développez avec des modèles simples en attendant les assets définitifs.
4. **Documentez**: Commentez votre code et maintenez la documentation à jour.

---

Bonne chance dans le développement de "The Beginning"! Ce jeu a un potentiel incroyable et, avec de la persévérance, vous pourrez créer une expérience de jeu captivante pour vos joueurs.