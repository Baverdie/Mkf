#!/bin/bash

# ╔══════════════════════════════════════════════════════════════╗
# ║              🚀 MKF ONE-LINER INSTALLER 🚀                   ║
# ║     Installation automatique depuis GitHub en une ligne      ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

# Configuration
VERSION="2.0.0"
REPO_USER="Baverdie"
REPO_NAME="Mkf"
BRANCH="main"               # ← À changer si nécessaire
ALIAS_NAME="mkf"

# URLs
REPO_URL="https://github.com/$REPO_USER/$REPO_NAME"
RAW_URL="https://raw.githubusercontent.com/$REPO_USER/$REPO_NAME/$BRANCH"
SCRIPT_URL="$RAW_URL/generate_makefile.sh"
MANAGER_URL="$RAW_URL/mkf-manager.sh"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
NC='\033[0m'

# Emojis
ROCKET="🚀"
SUCCESS="✅"
ERROR="❌"
WARNING="⚠️"
DOWNLOAD="📥"
INSTALL="🔧"
SPARKLES="✨"

# ═══════════════════════════════════════════════════════════════
# 🎨 FUNCTIONS
# ═══════════════════════════════════════════════════════════════

log() { echo -e "${BLUE}[MKF]${NC} $1"; }
success() { echo -e "${GREEN}${SUCCESS}${NC} $1"; }
error() { echo -e "${RED}${ERROR}${NC} $1"; }
warning() { echo -e "${YELLOW}${WARNING}${NC} $1"; }

show_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║    ███╗   ███╗██╗  ██╗███████╗                              ║
    ║    ████╗ ████║██║ ██╔╝██╔════╝                              ║
    ║    ██╔████╔██║█████╔╝ █████╗                                ║
    ║    ██║╚██╔╝██║██╔═██╗ ██╔══╝                                ║
    ║    ██║ ╚═╝ ██║██║  ██╗██║                                   ║
    ║    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝                                   ║
    ║                                                              ║
    ║           🚀 INSTALLATION AUTOMATIQUE 🚀                     ║
    ║                    One-liner installer                      ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Vérifier les prérequis
check_requirements() {
    log "Vérification des prérequis..."
    
    # Vérifier curl ou wget
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        error "curl ou wget requis pour le téléchargement"
        exit 1
    fi
    
    # Vérifier bash
    if [[ -z "$BASH_VERSION" ]]; then
        error "Bash requis pour l'installation"
        exit 1
    fi
    
    success "Prérequis OK"
}

# Détecter le système
detect_system() {
    log "Détection du système..."
    
    # OS
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    
    # Shell
    SHELL_NAME=$(basename "$SHELL")
    
    # Installation directory
    if [[ "$EUID" -eq 0 ]]; then
        INSTALL_DIR="/usr/local/bin"
        INSTALL_TYPE="system"
    else
        INSTALL_DIR="$HOME/bin"
        INSTALL_TYPE="user"
        mkdir -p "$INSTALL_DIR"
    fi
    
    success "Système: $OS, Shell: $SHELL_NAME, Installation: $INSTALL_TYPE"
}

# Télécharger les scripts
download_scripts() {
    log "Téléchargement depuis $REPO_URL..."
    
    local temp_script="/tmp/mkf_generate_makefile.sh"
    local temp_manager="/tmp/mkf_manager.sh"
    
    # Nettoyer les anciens fichiers temporaires
    rm -f "$temp_script" "$temp_manager"
    
    # Télécharger le générateur principal
    log "Téléchargement du générateur..."
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "$SCRIPT_URL" -o "$temp_script"; then
            error "Échec du téléchargement du générateur avec curl"
            error "URL: $SCRIPT_URL"
            exit 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q "$SCRIPT_URL" -O "$temp_script"; then
            error "Échec du téléchargement du générateur avec wget"
            error "URL: $SCRIPT_URL"
            exit 1
        fi
    fi
    
    # Vérifier le générateur principal
    if [[ ! -f "$temp_script" ]] || [[ ! -s "$temp_script" ]]; then
        error "Générateur téléchargé vide ou inexistant"
        error "Fichier: $temp_script"
        ls -la /tmp/mkf_* 2>/dev/null || true
        exit 1
    fi
    
    if ! head -1 "$temp_script" | grep -q "#!/bin/bash"; then
        error "Le générateur téléchargé n'est pas un script bash valide"
        error "Première ligne: $(head -1 "$temp_script")"
        rm -f "$temp_script" "$temp_manager"
        exit 1
    fi
    
    success "Générateur téléchargé: $(wc -l < "$temp_script") lignes"
    log "Fichier générateur: $temp_script"
    
    # Télécharger le manager
    log "Téléchargement du gestionnaire..."
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "$MANAGER_URL" -o "$temp_manager"; then
            warning "Échec du téléchargement du gestionnaire (optionnel)"
            temp_manager=""
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q "$MANAGER_URL" -O "$temp_manager"; then
            warning "Échec du téléchargement du gestionnaire (optionnel)"
            temp_manager=""
        fi
    fi
    
    # Vérifier le manager si téléchargé
    if [[ -n "$temp_manager" ]] && [[ -f "$temp_manager" ]] && [[ -s "$temp_manager" ]]; then
        if head -1 "$temp_manager" | grep -q "#!/bin/bash"; then
            success "Gestionnaire téléchargé: $(wc -l < "$temp_manager") lignes"
            log "Fichier gestionnaire: $temp_manager"
        else
            warning "Gestionnaire invalide, ignoré"
            temp_manager=""
        fi
    else
        log "Gestionnaire non téléchargé"
        temp_manager=""
    fi
    
    # Vérifier que les fichiers existent avant de retourner
    if [[ ! -f "$temp_script" ]]; then
        error "ERREUR CRITIQUE: Fichier générateur perdu après téléchargement"
        exit 1
    fi
    
    echo "$temp_script|$temp_manager"
}

# Installer les scripts
install_scripts() {
    local files_info="$1"
    local temp_script=$(echo "$files_info" | cut -d'|' -f1)
    local temp_manager=$(echo "$files_info" | cut -d'|' -f2)
    
    local target_script="$INSTALL_DIR/$ALIAS_NAME"
    local target_manager="$INSTALL_DIR/mkf-manager"
    
    # Vérifier que le générateur existe
    if [[ ! -f "$temp_script" ]]; then
        error "Fichier générateur temporaire introuvable: $temp_script"
        exit 1
    fi
    
    log "Installation du générateur dans $target_script..."
    
    # Demander confirmation si le fichier existe déjà
    if [[ -f "$target_script" ]]; then
        warning "MKF est déjà installé"
        if [[ "${FORCE_INSTALL:-}" != "true" ]]; then
            read -p "Remplacer l'installation existante ? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "Installation annulée"
                rm -f "$temp_script" "$temp_manager"
                exit 0
            fi
        fi
        
        # Backup de l'ancienne version
        cp "$target_script" "$target_script.backup.$(date +%s)"
        success "Backup du générateur créé"
    fi
    
    # Installer le générateur principal
    if [[ "$INSTALL_TYPE" == "system" ]]; then
        sudo cp "$temp_script" "$target_script"
        sudo chmod +x "$target_script"
    else
        cp "$temp_script" "$target_script"
        chmod +x "$target_script"
    fi
    
    success "Générateur installé: $target_script"
    
    # Installer le gestionnaire si disponible
    if [[ -n "$temp_manager" ]] && [[ -f "$temp_manager" ]]; then
        log "Installation du gestionnaire dans $target_manager..."
        
        if [[ -f "$target_manager" ]]; then
            cp "$target_manager" "$target_manager.backup.$(date +%s)"
        fi
        
        if [[ "$INSTALL_TYPE" == "system" ]]; then
            sudo cp "$temp_manager" "$target_manager"
            sudo chmod +x "$target_manager"
        else
            cp "$temp_manager" "$target_manager"
            chmod +x "$target_manager"
        fi
        
        success "Gestionnaire installé: $target_manager"
    else
        warning "Gestionnaire non disponible (installation du générateur seulement)"
    fi
    
    # Nettoyer seulement à la fin
    rm -f "$temp_script" "$temp_manager"
}

# Configurer les alias shell
setup_shell() {
    log "Configuration des alias shell..."
    
    # Fichiers de configuration shell à modifier
    local shell_files=()
    [[ -f "$HOME/.bashrc" ]] && shell_files+=("$HOME/.bashrc")
    [[ -f "$HOME/.zshrc" ]] && shell_files+=("$HOME/.zshrc")
    [[ -f "$HOME/.profile" ]] && shell_files+=("$HOME/.profile")
    
    if [[ ${#shell_files[@]} -eq 0 ]]; then
        warning "Aucun fichier de configuration shell trouvé"
        return
    fi
    
    # Ajouter ~/bin au PATH si nécessaire (pour installation user)
    if [[ "$INSTALL_TYPE" == "user" ]]; then
        for shell_file in "${shell_files[@]}"; do
            if ! grep -q 'export PATH="$HOME/bin:$PATH"' "$shell_file" 2>/dev/null; then
                echo "" >> "$shell_file"
                echo "# Ajouté par MKF installer $(date)" >> "$shell_file"
                echo 'export PATH="$HOME/bin:$PATH"' >> "$shell_file"
                success "PATH mis à jour dans $(basename "$shell_file")"
            fi
        done
    fi
    
    # Ajouter les alias
    local aliases=(
        "alias $ALIAS_NAME='$INSTALL_DIR/$ALIAS_NAME'"
        "alias mkf-help='$ALIAS_NAME --help'"
        "alias mkf-config='$ALIAS_NAME --config'"
        "alias mkf-version='$ALIAS_NAME --version'"
    )
    
    # Ajouter l'alias du gestionnaire si installé
    if [[ -f "$INSTALL_DIR/mkf-manager" ]]; then
        aliases+=("alias mkf-manager='$INSTALL_DIR/mkf-manager'")
    fi
    
    for shell_file in "${shell_files[@]}"; do
        # Vérifier si les alias existent déjà
        if ! grep -q "alias $ALIAS_NAME=" "$shell_file" 2>/dev/null; then
            echo "" >> "$shell_file"
            echo "# Alias MKF - Ajoutés par l'installer $(date)" >> "$shell_file"
            for alias_cmd in "${aliases[@]}"; do
                echo "$alias_cmd" >> "$shell_file"
            done
            success "Alias ajoutés dans $(basename "$shell_file")"
        fi
    done
    
    # Activer les alias pour cette session
    for alias_cmd in "${aliases[@]}"; do
        eval "$alias_cmd"
    done
}

# Créer la configuration initiale
setup_config() {
    log "Configuration initiale..."
    
    local config_dir="$HOME/.config/mkf"
    local config_file="$config_dir/config"
    
    mkdir -p "$config_dir"
    
    if [[ ! -f "$config_file" ]]; then
        cat > "$config_file" << EOF
# Configuration MKF v$VERSION - Générée automatiquement

# Plugins activés par défaut
RECURSIVE_SEARCH=true
AUTO_LIBRARIES=true
AUTO_GITIGNORE=false
PERFORMANCE_ANALYSIS=true

# Paramètres de compilation
DEFAULT_CC="c++"
DEFAULT_CFLAGS="-std=c++98 -Wall -Wextra -Werror -g"

# Style
MAKEFILE_STYLE="classic"
FALLBACK_EMOJI="🚀"

# Meta
INSTALL_DATE="$(date)"
INSTALL_TYPE="$INSTALL_TYPE"
INSTALL_SOURCE="one-liner"
REPO_URL="$REPO_URL"
EOF
        success "Configuration créée: $config_file"
    else
        success "Configuration existante conservée"
    fi
}

# Test de l'installation
test_installation() {
    log "Test de l'installation..."
    
    # Test 1: Commande disponible
    if command -v "$ALIAS_NAME" >/dev/null 2>&1; then
        success "Commande '$ALIAS_NAME' disponible"
    else
        warning "Commande '$ALIAS_NAME' pas encore disponible (redémarre ton terminal)"
    fi
    
    # Test 2: Exécution
    local target_path="$INSTALL_DIR/$ALIAS_NAME"
    if [[ -x "$target_path" ]]; then
        local version_output="$($target_path --version 2>/dev/null || echo "")"
        if [[ -n "$version_output" ]]; then
            success "Version: $version_output"
        else
            warning "Impossible d'obtenir la version"
        fi
    fi
    
    # Test 3: Configuration
    if [[ -f "$HOME/.config/mkf/config" ]]; then
        success "Configuration trouvée"
    else
        warning "Configuration manquante"
    fi
    
    # Test 4: Gestionnaire
    if [[ -f "$INSTALL_DIR/mkf-manager" ]]; then
        success "Gestionnaire installé"
    else
        warning "Gestionnaire non installé"
    fi
}

# Afficher le résumé final
show_summary() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║                 🎉 INSTALLATION RÉUSSIE! 🎉                  ║
    ║                                                              ║
    ║              MKF est maintenant disponible                   ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${CYAN}${BOLD}🚀 UTILISATION:${NC}"
    echo ""
    echo -e "  ${YELLOW}$ALIAS_NAME MonProjet${NC}         # Créer un Makefile automatiquement"
    echo -e "  ${YELLOW}$ALIAS_NAME -i Calculator${NC}     # Mode interactif"
    echo -e "  ${YELLOW}$ALIAS_NAME --config${NC}          # Configuration des plugins"
    echo -e "  ${YELLOW}$ALIAS_NAME --help${NC}            # Aide complète"
    echo ""
    
    if [[ -f "$INSTALL_DIR/mkf-manager" ]]; then
        echo -e "${PURPLE}${BOLD}⚙️ GESTIONNAIRE:${NC}"
        echo ""
        echo -e "  ${YELLOW}mkf-manager${NC}                # Interface de gestion complète"
        echo -e "  ${YELLOW}mkf-manager uninstall${NC}      # Désinstaller MKF"
        echo -e "  ${YELLOW}mkf-manager plugins${NC}        # Gérer les plugins"
        echo ""
    fi
    
    echo -e "${BLUE}${BOLD}📚 EXEMPLES:${NC}"
    echo ""
    echo -e "  ${CYAN}# Dans un nouveau projet${NC}"
    echo -e "  mkdir MonProjet && cd MonProjet"
    echo -e "  $ALIAS_NAME MonProjet"
    echo ""
    echo -e "  ${CYAN}# Projet avec emoji spécifique${NC}"
    echo -e "  $ALIAS_NAME WebServer 🌐"
    echo ""
    
    if [[ "$INSTALL_TYPE" == "user" ]]; then
        echo -e "${YELLOW}${BOLD}🔄 ACTIVATION:${NC}"
        echo ""
        echo "Pour utiliser immédiatement dans ce terminal:"
        echo -e "  ${BLUE}source ~/.bashrc${NC} (ou ~/.zshrc selon ton shell)"
        echo ""
        echo "Ou ouvre un nouveau terminal pour que les alias soient actifs."
        echo ""
    fi
    
    echo -e "${PURPLE}Repository: ${UNDERLINE}$REPO_URL${NC}"
    echo -e "${DIM}Merci d'utiliser MKF! 🚀${NC}"
}

# ═══════════════════════════════════════════════════════════════
# 🎯 MAIN FUNCTION
# ═══════════════════════════════════════════════════════════════

main() {
    # Mode silencieux pour automatisation
    if [[ "${1:-}" == "--silent" ]] || [[ "${SILENT_INSTALL:-}" == "true" ]]; then
        SILENT=true
        FORCE_INSTALL=true
    else
        SILENT=false
        show_banner
    fi
    
    # Vérifications préalables
    check_requirements
    detect_system
    
    # Téléchargement et installation
    local files_info
    files_info=$(download_scripts)
    install_scripts "$files_info"
    
    # Configuration
    setup_shell
    setup_config
    
    # Tests
    test_installation
    
    # Résumé
    if [[ "$SILENT" != "true" ]]; then
        show_summary
    else
        success "MKF installé avec succès!"
    fi
}

# Gestion d'erreur globale
trap 'error "Installation interrompue"; exit 1' INT TERM

# Point d'entrée
main "$@"
