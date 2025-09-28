# 🚀 MKF - Makefile Generator

Générateur intelligent de Makefiles avec détection automatique du type de projet, système de plugins modulaire et interface de gestion complète.

## ⚡ Installation en une ligne

```bash
curl -fsSL https://raw.githubusercontent.com/Baverdie/Mkf/main/install.sh | bash
```

## 🎯 Utilisation

```bash
mkf MonProjet              # Génération automatique complète
mkf -i Calculator          # Mode interactif pour choisir l'emoji
mkf WebServer 🌐           # Avec emoji spécifique
mkf --watch MyProject      # Mode surveillance avec auto-régénération
mkf --42 Project           # Mode discret (sans signatures MKF)
mkf --config              # Configuration des plugins
mkf --help                # Aide complète
```

## 🔧 Gestion avec MKF Manager

```bash
mkf-manager               # Interface de gestion complète
mkf-manager uninstall     # Désinstallation propre avec backup
mkf-manager plugins       # Gestion fine des plugins
mkf-manager diagnostic    # Diagnostic et réparation système
```

## ✨ Fonctionnalités principales

### 🧠 Intelligence artificielle
- **Détection automatique du type de projet** par analyse du code source
- **Choix d'emoji pertinent** selon le contenu (🌐 pour serveurs, 🔐 pour crypto, etc.)
- **Scan récursif intelligent** des fichiers source dans tous les sous-dossiers

### 📚 Détection automatique des bibliothèques
- **OpenGL/Vulkan** → `-lGL -lGLU -lglfw`
- **Threading** → `-lpthread`
- **Math** → `-lm`
- **cURL** → `-lcurl`
- **SQLite** → `-lsqlite3`
- Et bien d'autres...

### 🎨 Interface stylée
- **Bannières ASCII** dynamiques avec figlet
- **Barres de progression** colorées
- **Messages d'erreur** informatifs
- **Feedback visuel** en temps réel
- **Messages Makefile** entièrement en anglais
- **Notifications système** pour les mises à jour

### 🔌 Système de plugins modulaire
- **Scan récursif** des sous-dossiers
- **Génération .gitignore** automatique
- **Analyse de performance** des Makefiles
- **Mode surveillance** des fichiers avec auto-régénération
- **Support CMake** en alternative
- **Notifications popup** pour les mises à jour disponibles
- Configuration **activable/désactivable** individuellement

## 🎮 Exemples d'utilisation

### Projet simple
```bash
mkdir Calculator && cd Calculator
mkf Calculator
# → Détecte automatiquement les fichiers, choisit 🧮, génère un Makefile optimisé
```

### Projet complexe avec détection avancée
```bash
# Dans un projet avec OpenGL et threading
mkf GameEngine
# → Détecte OpenGL → 🎨
# → Ajoute automatiquement -lGL -lGLU -lpthread
# → Scan récursif des sources dans src/graphics/, src/engine/, etc.
```

### Mode interactif
```bash
mkf -i MyProject
# → Interface interactive pour choisir parmi 12 catégories d'emojis
# → Prévisualisation et confirmation avant génération
```

### Mode surveillance
```bash
mkf --watch GameEngine
# → Surveillance en temps réel des fichiers source
# → Auto-régénération du Makefile à chaque modification
# → Messages de progression et détection des nouveaux fichiers
```

### Mode discret (sans signatures)
```bash
mkf --42 SecretProject
# → Génère un Makefile sans en-têtes MKF
# → Conserve toutes les fonctionnalités et messages colorés
# → Idéal pour les projets où la discrétion est requise
```

## 🛠️ Installation avancée

### Installation silencieuse
```bash
curl -fsSL https://raw.githubusercontent.com/Baverdie/Mkf/main/install.sh | bash -s -- --silent
```

### Installation avec variables d'environnement
```bash
FORCE_INSTALL=true SILENT_INSTALL=true curl -fsSL https://raw.githubusercontent.com/Baverdie/Mkf/main/install.sh | bash
```

## ⚙️ Configuration

### Configuration des plugins
```bash
mkf-manager plugins
# Interface interactive pour activer/désactiver :
# [🟢] Scan récursif des sous-dossiers         [Activé]
# [🔴] Génération automatique de .gitignore    [Désactivé]  
# [🟢] Détection automatique des bibliothèques [Activé]
```

### Configuration manuelle
```bash
# Fichier de configuration : ~/.config/mkf/config
nano ~/.config/mkf/config
```

## 🔍 Diagnostic et maintenance

```bash
mkf-manager diagnostic
# Vérification complète :
# ✅ Installation et permissions
# ✅ Configuration et plugins  
# ✅ Alias et PATH
# ✅ Dépendances système
```

## 🗑️ Désinstallation

```bash
mkf-manager uninstall
# Désinstallation propre avec :
# • Suppression des exécutables
# • Nettoyage des alias shell (avec backup)
# • Option de conservation de la configuration
```

## 📊 Types de projets détectés

| Type de projet | Emoji | Détection basée sur |
|----------------|-------|-------------------|
| Mathématiques/Calcul | 🧮 | `#include <math.h>`, `sqrt`, `pow` |
| Jeux/Graphics | 🎮🎨 | `opengl`, `vulkan`, `sdl`, `game` |
| Réseau/Web | 🌐 | `socket`, `http`, `curl`, `network` |
| Cryptographie | 🔐 | `encrypt`, `hash`, `openssl`, `crypto` |
| Base de données | 🗄️ | `sql`, `sqlite`, `mysql`, `database` |
| Sérialisation | 🤳 | `serialize`, `json`, `xml`, `protobuf` |
| Fichiers/I/O | 📁 | `fstream`, `ifstream`, `filesystem` |
| Tests | 🧪 | `gtest`, `catch`, `assert`, `unittest` |
| Threading | 🧵 | `thread`, `mutex`, `async`, `parallel` |
| Parsing | 📝 | `lexer`, `parser`, `grammar`, `ast` |

## 🏗️ Architecture du projet

```
Mkf/
├── generate_makefile.sh    # Générateur principal avec plugins
├── install.sh              # Installateur one-liner automatique  
├── mkf-manager.sh          # Gestionnaire et interface de maintenance
└── README.md              # Cette documentation
```

## 🤝 Contribution

1. Fork le repo
2. Crée une branche feature (`git checkout -b feature/amazing-feature`)
3. Commit tes changements (`git commit -m 'Add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvre une Pull Request

## 📝 Licence

Projet open source - voir le fichier LICENSE pour plus de détails.

## 🎯 Roadmap

- [ ] Support pour d'autres langages (C, Rust, Go)
- [ ] Templates de Makefile personnalisables
- [ ] Intégration avec les IDE populaires
- [x] Mode watch avec auto-regénération ✅
- [x] Notifications popup pour mises à jour ✅
- [x] Mode discret sans signatures ✅
- [ ] Support des monorepos
- [ ] Plugin pour détection des tests automatiques

---

**Développé avec ❤️ par [Baverdie](https://github.com/Baverdie)**

*MKF - Parce que personne n'aime écrire des Makefiles à la main ! 🚀*
