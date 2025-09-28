#!/bin/bash

# Installation MKF - Version simple et robuste

set -e

# Configuration
REPO_USER="Baverdie"
REPO_NAME="Mkf"
BRANCH="main"
ALIAS_NAME="mkf"

# URLs
SCRIPT_URL="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$BRANCH/generate_makefile.sh"
MANAGER_URL="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$BRANCH/mkf-manager.sh"

# Couleurs simples
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' NC=''
fi

echo -e "${BLUE}${BOLD}🚀 Installation MKF${NC}"
echo ""

# Détection du système
if [[ "$EUID" -eq 0 ]]; then
    INSTALL_DIR="/usr/local/bin"
    echo "Installation système détectée"
else
    INSTALL_DIR="$HOME/bin"
    mkdir -p "$INSTALL_DIR"
    echo "Installation utilisateur: $INSTALL_DIR"
fi

# Fichiers temporaires avec noms fixes
TEMP_SCRIPT="/tmp/mkf_script_temp.sh"
TEMP_MANAGER="/tmp/mkf_manager_temp.sh"
TARGET_SCRIPT="$INSTALL_DIR/$ALIAS_NAME"
TARGET_MANAGER="$INSTALL_DIR/mkf-manager"

# Nettoyage initial
rm -f "$TEMP_SCRIPT" "$TEMP_MANAGER"

echo "Téléchargement du générateur..."

# Téléchargement du générateur
if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$SCRIPT_URL" -o "$TEMP_SCRIPT"
elif command -v wget >/dev/null 2>&1; then
    wget -q "$SCRIPT_URL" -O "$TEMP_SCRIPT"
else
    echo -e "${RED}Erreur: curl ou wget requis${NC}"
    exit 1
fi

# Vérification immédiate
if [[ ! -f "$TEMP_SCRIPT" ]] || [[ ! -s "$TEMP_SCRIPT" ]]; then
    echo -e "${RED}Erreur: Téléchargement du générateur échoué${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Générateur téléchargé: $(wc -l < "$TEMP_SCRIPT") lignes${NC}"

# Téléchargement du gestionnaire (optionnel)
echo "Téléchargement du gestionnaire..."
if command -v curl >/dev/null 2>&1; then
    if curl -fsSL "$MANAGER_URL" -o "$TEMP_MANAGER" 2>/dev/null; then
        if [[ -f "$TEMP_MANAGER" ]] && [[ -s "$TEMP_MANAGER" ]]; then
            echo -e "${GREEN}✅ Gestionnaire téléchargé: $(wc -l < "$TEMP_MANAGER") lignes${NC}"
        else
            rm -f "$TEMP_MANAGER"
            echo "⚠️  Gestionnaire non disponible"
        fi
    else
        echo "⚠️  Gestionnaire non disponible"
    fi
fi

# Installation du générateur
echo "Installation du générateur: $TARGET_SCRIPT"

if [[ -f "$TARGET_SCRIPT" ]]; then
    echo "⚠️  MKF déjà installé"
    read -p "Remplacer ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation annulée"
        rm -f "$TEMP_SCRIPT" "$TEMP_MANAGER"
        exit 0
    fi
    cp "$TARGET_SCRIPT" "$TARGET_SCRIPT.backup.$(date +%s)"
    echo "✅ Backup créé"
fi

# Copie du générateur
if [[ "$EUID" -eq 0 ]]; then
    cp "$TEMP_SCRIPT" "$TARGET_SCRIPT"
    chmod +x "$TARGET_SCRIPT"
else
    cp "$TEMP_SCRIPT" "$TARGET_SCRIPT"
    chmod +x "$TARGET_SCRIPT"
fi

echo -e "${GREEN}✅ Générateur installé: $TARGET_SCRIPT${NC}"

# Installation du gestionnaire
if [[ -f "$TEMP_MANAGER" ]]; then
    echo "Installation du gestionnaire: $TARGET_MANAGER"
    if [[ "$EUID" -eq 0 ]]; then
        cp "$TEMP_MANAGER" "$TARGET_MANAGER"
        chmod +x "$TARGET_MANAGER"
    else
        cp "$TEMP_MANAGER" "$TARGET_MANAGER"
        chmod +x "$TARGET_MANAGER"
    fi
    echo -e "${GREEN}✅ Gestionnaire installé: $TARGET_MANAGER${NC}"
fi

# Configuration des alias
echo "Configuration des alias..."

SHELL_FILES=()
[[ -f "$HOME/.bashrc" ]] && SHELL_FILES+=("$HOME/.bashrc")
[[ -f "$HOME/.zshrc" ]] && SHELL_FILES+=("$HOME/.zshrc")

if [[ ${#SHELL_FILES[@]} -gt 0 ]]; then
    # Ajouter ~/bin au PATH si nécessaire
    if [[ "$INSTALL_DIR" == "$HOME/bin" ]]; then
        for shell_file in "${SHELL_FILES[@]}"; do
            if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$shell_file" 2>/dev/null; then
                echo "" >> "$shell_file"
                echo "# MKF PATH" >> "$shell_file"
                echo 'export PATH="$HOME/bin:$PATH"' >> "$shell_file"
                echo "✅ PATH mis à jour dans $(basename "$shell_file")"
            fi
        done
    fi
    
    # Ajouter les alias
    for shell_file in "${SHELL_FILES[@]}"; do
        if ! grep -q "alias $ALIAS_NAME=" "$shell_file" 2>/dev/null; then
            echo "" >> "$shell_file"
            echo "# Alias MKF" >> "$shell_file"
            echo "alias $ALIAS_NAME='$TARGET_SCRIPT'" >> "$shell_file"
            echo "alias mkf-help='$ALIAS_NAME --help'" >> "$shell_file"
            [[ -f "$TARGET_MANAGER" ]] && echo "alias mkf-manager='$TARGET_MANAGER'" >> "$shell_file"
            echo "✅ Alias ajoutés dans $(basename "$shell_file")"
        fi
    done
fi

# Configuration initiale
CONFIG_DIR="$HOME/.config/mkf"
CONFIG_FILE="$CONFIG_DIR/config"

mkdir -p "$CONFIG_DIR"

if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" << 'EOF'
# Configuration MKF
RECURSIVE_SEARCH=true
AUTO_LIBRARIES=true
AUTO_GITIGNORE=false
PERFORMANCE_ANALYSIS=true
DEFAULT_CC="c++"
DEFAULT_CFLAGS="-std=c++98 -Wall -Wextra -Werror -g"
MAKEFILE_STYLE="classic"
FALLBACK_EMOJI="🚀"
EOF
    echo "✅ Configuration créée: $CONFIG_FILE"
fi

# Test de l'installation
echo "Test de l'installation..."

if [[ -x "$TARGET_SCRIPT" ]]; then
    echo -e "${GREEN}✅ Installation réussie!${NC}"
else
    echo -e "${RED}❌ Problème d'installation${NC}"
    exit 1
fi

# Nettoyage
rm -f "$TEMP_SCRIPT" "$TEMP_MANAGER"

echo ""
echo -e "${BLUE}${BOLD}🎉 Installation terminée!${NC}"
echo ""
echo -e "${YELLOW}Utilisation:${NC}"
echo "  $ALIAS_NAME MonProjet    # Générer un Makefile"
echo "  $ALIAS_NAME -i Calculator # Mode interactif"
echo "  $ALIAS_NAME --help       # Aide"
[[ -f "$TARGET_MANAGER" ]] && echo "  mkf-manager             # Gestionnaire"
echo ""
echo -e "${YELLOW}⚠️  Redémarre ton terminal ou exécute:${NC}"
echo "  source ~/.bashrc  (ou ~/.zshrc)"
echo ""
echo -e "${GREEN}🚀 Prêt à générer des Makefiles!${NC}"
