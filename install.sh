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

# Couleurs avec détection automatique
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1 && [[ $(tput colors) -ge 8 ]]; then
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
else
    # Pas de couleurs si le terminal ne les supporte pas
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    PURPLE=''
    CYAN=''
    BOLD=''
    DIM=''
    UNDERLINE=''
    NC=''
fi

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
    
    # Créer un dossier temporaire unique
    local temp_dir="/tmp/mkf-install-$"
    mkdir -p "$temp_dir"
    
    local temp_script="$temp_dir/generate_makefile.sh"
    local temp_manager="$temp_dir/mkf-manager.sh"
    
    log "Dossier temporaire: $temp_dir"
    
    # Télécharger le générateur principal
    log "Téléchargement du générateur..."
    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "$SCRIPT_URL" -o "$temp_script"; then
            error "Échec du téléchargement du générateur avec curl"
            error "URL: $SCRIPT_URL"
            rm -rf "$temp_dir"
            exit 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -q "$SCRIPT_URL" -O "$temp_script"; then
            error "Échec du téléchargement du générateur avec wget"
            error "URL: $SCRIPT_URL"
            rm -rf "$temp_dir"
            exit 1
        fi
    fi
    
    # Vérifier immédiatement après téléchargement
    log "Vérification du générateur téléchargé..."
    if [[ ! -f "$temp_script" ]]; then
        error "ERREUR: Fichier générateur non créé"
        error "Attendu: $temp_script"
        ls -la "$temp_dir" 2>/dev/null || true
        rm -rf "$temp_dir"
        exit 1
    fi
    
    if [[ ! -s "$temp_script" ]]; then
        error "ERREUR: Fichier générateur vide"
        error "Taille: $(wc -c < "$temp_script" 2>/dev/null || echo "0") bytes"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    if ! head -1 "$temp_script" | grep -q "#!/bin/bash"; then
        error "ERREUR: Fichier générateur invalide"
        error "Première ligne: $(head -1 "$temp_script" 2>/dev/null || echo "vide")"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    success "Générateur téléchargé: $(wc -l < "$temp_script") lignes"
    
    # Télécharger le manager (optionnel)
    log "Téléchargement du gestionnaire..."
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "$MANAGER_URL" -o "$temp_manager" 2>/dev/null; then
            if [[ -f "$temp_manager" ]] && [[ -s "$temp_manager" ]] && head -1 "$temp_manager" | grep -q "#!/bin/bash"; then
                success "Gestionnaire téléchargé: $(wc -l < "$temp_manager") lignes"
            else
                log "Gestionnaire invalide, ignoré"
                rm -f "$temp_manager"
                temp_manager=""
            fi
        else
            log "Gestionnaire non disponible (optionnel)"
            temp_manager=""
        fi
    else
        log "Gestionnaire non téléchargé (wget non testé)"
        temp_manager=""
    fi
    
    # Vérification finale avant retour
    if [[ ! -f "$temp_script" ]]; then
        error "ERREUR CRITIQUE: Fichier générateur perdu"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    log "Fichiers prêts dans: $temp_dir"
    echo "$temp_script|$temp_manager|$temp_dir"
}

# Installer les scripts
install_scripts() {
    local files_info="$1"
    local temp_script=$(echo "$files_info" | cut -d'|' -f1)
    local temp_manager=$(echo "$files_info" | cut -d'|' -f2)
    local temp_dir=$(echo "$files_info" | cut -d'|' -f3)
    
    local target_script="$INSTALL_DIR/$ALIAS_NAME"
    local target_manager="$INSTALL_DIR/mkf-manager"
    
    log "Installation depuis: $temp_dir"
    
    # Double vérification que le générateur existe
    if [[ ! -f "$temp_script" ]]; then
        error "ERREUR CRITIQUE: Fichier générateur introuvable"
        error "Attendu: $temp_script"
        error "Contenu du dossier temporaire:"
        ls -la "$temp_dir" 2>/dev/null || echo "Dossier inexistant"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    log "Installation du générateur: $temp_script -> $target_script"
    
    # Demander confirmation si déjà installé
    if [[ -f "$target_script" ]]; then
        warning "MKF est déjà installé"
        if [[ "${FORCE_INSTALL:-}" != "true" ]]; then
            read -p "Remplacer l'installation existante ? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "Installation annulée"
                rm -rf "$temp_dir"
                exit 0
            fi
        fi
        
        # Backup de l'ancienne version
        cp "$target_script" "$target_script.backup.$(date +%s)"
        success "Backup du générateur créé"
    fi
    
    # Installer le générateur principal
    if [[ "$INSTALL_TYPE" == "system" ]]; then
        if ! sudo cp "$temp_script" "$target_script"; then
            error "Échec de l'installation système du générateur"
            rm -rf "$temp_dir"
            exit 1
        fi
        sudo chmod +x "$target_script"
    else
        if ! cp "$temp_script" "$target_script"; then
            error "Échec de l'installation utilisateur du générateur"
            rm -rf "$temp_dir"
            exit 1
        fi
        chmod +x "$target_script"
    fi
    
    success "Générateur installé: $target_script"
    
    # Installer le gestionnaire si disponible
    if [[ -n "$temp_manager" ]] && [[ -f "$temp_manager" ]]; then
        log "Installation du gestionnaire: $temp_manager -> $target_manager"
        
        if [[ -f "$target_manager" ]]; then
            cp "$target_manager" "$target_manager.backup.$(date +%s)"
            log "Backup du gestionnaire créé"
        fi
        
        if [[ "$INSTALL_TYPE" == "system" ]]; then
            if sudo cp "$temp_manager" "$target_manager" && sudo chmod +x "$target_manager"; then
                success "Gestionnaire installé: $target_manager"
            else
                warning "Échec de l'installation du gestionnaire (non critique)"
            fi
        else
            if cp "$temp_manager" "$target_manager" && chmod +x "$target_manager"; then
                success "Gestionnaire installé: $target_manager"
            else
                warning "Échec de l'installation du gestionnaire (non critique)"
            fi
        fi
    else
        log "Gestionnaire non disponible, installation du générateur seulement"
    fi
    
    # Vérification post-installation
    if [[ ! -x "$target_script" ]]; then
        error "ERREUR: Le générateur installé n'est pas exécutable"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Nettoyage du dossier temporaire
    rm -rf "$temp_dir"
    log "Dossier temporaire nettoyé"
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
    # Options de ligne de commande
    while [[ $# -gt 0 ]]; do
        case $1 in
            --silent)
                SILENT=true
                FORCE_INSTALL=true
                shift
                ;;
            --no-colors)
                # Forcer la désactivation des couleurs
                RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN=''
                BOLD='' DIM='' UNDERLINE='' NC=''
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --help|-h)
                echo "Installation MKF - Options disponibles:"
                echo "  --silent     Installation silencieuse"
                echo "  --no-colors  Désactiver les couleurs"
                echo "  --force      Forcer l'installation sans confirmation"
                exit 0
                ;;
            *)
                echo "Option inconnue: $1"
                echo "Utilise --help pour voir les options disponibles"
                exit 1
                ;;
        esac
    done
    
    # Mode silencieux pour automatisation
    if [[ "${SILENT_INSTALL:-}" == "true" ]]; then
        SILENT=true
        FORCE_INSTALL=true
    fi
    
    # Définir les valeurs par défaut si pas déjà définies
    SILENT="${SILENT:-false}"
    
    if [[ "$SILENT" != "true" ]]; then
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
