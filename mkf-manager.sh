#!/bin/bash

# ╔══════════════════════════════════════════════════════════════╗
# ║              🚀 MKF MANAGER - GESTIONNAIRE COMPLET 🚀        ║
# ║     Gestion, désinstallation, plugins & configuration MKF    ║
# ╚══════════════════════════════════════════════════════════════╝

set -e

# Chargement de la version depuis le fichier centralisé
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/version.sh" ]]; then
    VERSION="$("$SCRIPT_DIR/version.sh" get)"
else
    VERSION="2.2.0"  # Fallback
fi
ALIAS_NAME="mkf"
MANAGER_NAME="mkf-manager"

# Configuration
CONFIG_DIR="$HOME/.config/mkf"
CONFIG_FILE="$CONFIG_DIR/config"
PLUGINS_CONFIG="$CONFIG_DIR/plugins.conf"

# ═══════════════════════════════════════════════════════════════
# 🎨 COULEURS ET STYLES
# ═══════════════════════════════════════════════════════════════
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
NC='\033[0m'

# Emojis
ROCKET="🚀"
FIRE="🔥"
SPARKLES="✨"
GEAR="⚙️"
PACKAGE="📦"
UNINSTALL="🗑️"
SUCCESS="✅"
ERROR="❌"
WARNING="⚠️"
FOLDER="📁"
SHIELD="🛡️"
MAGIC="🪄"
PLUGIN="🔌"
TOGGLE_ON="🟢"
TOGGLE_OFF="🔴"
MENU="📋"
BACK="⬅️"
EXIT="🚪"

# ═══════════════════════════════════════════════════════════════
# 🎭 FONCTIONS UTILITAIRES
# ═══════════════════════════════════════════════════════════════

log_info() { echo -e "${BLUE}${BOLD}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}${BOLD}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}${BOLD}[ERROR]${NC} $1"; }

# Animation spinner
show_spinner() {
    local pid=$1
    local message="$2"
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local colors=("$RED" "$YELLOW" "$GREEN" "$CYAN" "$BLUE" "$PURPLE")
    local frame_index=0
    local color_index=0
    
    while ps -p $pid > /dev/null 2>&1; do
        local current_color="${colors[$color_index]}"
        printf "\r  ${current_color}${frames[$frame_index]}${NC} ${BOLD}%s${NC}" "$message"
        
        frame_index=$(( (frame_index + 1) % ${#frames[@]} ))
        color_index=$(( (color_index + 1) % ${#colors[@]} ))
        sleep 0.1
    done
    printf "\r  ${GREEN}${SUCCESS}${NC} ${BOLD}%s${NC}\n" "$message"
}

# Détection de l'installation MKF
detect_installation() {
    local possible_paths=(
        "$HOME/bin/$ALIAS_NAME"
        "/usr/local/bin/$ALIAS_NAME"
        "/usr/bin/$ALIAS_NAME"
        "./$ALIAS_NAME"
    )
    
    for path in "${possible_paths[@]}"; do
        if [[ -f "$path" ]]; then
            INSTALL_PATH="$path"
            INSTALL_DIR="$(dirname "$path")"
            if [[ "$INSTALL_DIR" == "$HOME/bin" ]]; then
                INSTALL_TYPE="user"
            elif [[ "$INSTALL_DIR" == "/usr/local/bin" ]] || [[ "$INSTALL_DIR" == "/usr/bin" ]]; then
                INSTALL_TYPE="system"
            else
                INSTALL_TYPE="portable"
            fi
            return 0
        fi
    done
    
    return 1
}

# Chargement de la configuration des plugins
load_plugins_config() {
    if [[ -f "$PLUGINS_CONFIG" ]]; then
        source "$PLUGINS_CONFIG"
    else
        # Configuration par défaut
        RECURSIVE_SEARCH=true
        AUTO_LIBRARIES=true
        AUTO_GITIGNORE=false
        WATCH_MODE=false
        CMAKE_SUPPORT=false
        PERFORMANCE_ANALYSIS=true
        UPDATE_MODE=false
        ADVANCED_ANALYSIS=false
        AUTO_TESTS=false
        SMART_INCLUDES=true
    fi
}

# Sauvegarde de la configuration des plugins
save_plugins_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$PLUGINS_CONFIG" << EOF
# ╔══════════════════════════════════════════════════════════════╗
# ║              Configuration des Plugins MKF v$VERSION          ║
# ║                 Modifiable via MKF Manager                   ║
# ╚══════════════════════════════════════════════════════════════╝

# Plugins de base
RECURSIVE_SEARCH=$RECURSIVE_SEARCH
AUTO_LIBRARIES=$AUTO_LIBRARIES
AUTO_GITIGNORE=$AUTO_GITIGNORE
PERFORMANCE_ANALYSIS=$PERFORMANCE_ANALYSIS

# Plugins avancés  
WATCH_MODE=$WATCH_MODE
CMAKE_SUPPORT=$CMAKE_SUPPORT
UPDATE_MODE=$UPDATE_MODE
ADVANCED_ANALYSIS=$ADVANCED_ANALYSIS
AUTO_TESTS=$AUTO_TESTS
SMART_INCLUDES=$SMART_INCLUDES

# Méta-informations
LAST_MODIFIED="$(date)"
MODIFIED_BY="MKF Manager v$VERSION"
EOF
}

# ═══════════════════════════════════════════════════════════════
# 🎨 INTERFACE UTILISATEUR
# ═══════════════════════════════════════════════════════════════

show_header() {
    clear
    echo -e "${PURPLE}${BOLD}"
    cat << "EOF"
    ╔══════════════════════════════════════════════════════════════╗
    ║                                                              ║
    ║    ███╗   ███╗██╗  ██╗███████╗                              ║
    ║    ████╗ ████║██║ ██╔╝██╔════╝                              ║
    ║    ██╔████╔██║█████╔╝ █████╗          MANAGER               ║
    ║    ██║╚██╔╝██║██╔═██╗ ██╔══╝                                ║
    ║    ██║ ╚═╝ ██║██║  ██╗██║                                   ║
    ║    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝                                   ║
    ║                                                              ║
    ║           🚀 GESTIONNAIRE MKF v2.0.0 🚀                      ║
    ║                                                              ║
    ╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

show_status() {
    echo -e "${BLUE}${BOLD}📊 STATUT SYSTÈME${NC}"
    echo ""
    
    if detect_installation; then
        echo -e "  ${SUCCESS} MKF installé: ${BOLD}$INSTALL_PATH${NC}"
        echo -e "  ${GEAR} Type d'installation: ${BOLD}$INSTALL_TYPE${NC}"
        
        local version_output="$($INSTALL_PATH --version 2>/dev/null || echo "Inconnue")"
        echo -e "  ${PACKAGE} Version: ${BOLD}$version_output${NC}"
    else
        echo -e "  ${ERROR} MKF non installé"
    fi
    
    if [[ -f "$CONFIG_FILE" ]]; then
        echo -e "  ${SUCCESS} Configuration: ${BOLD}$CONFIG_FILE${NC}"
    else
        echo -e "  ${WARNING} Aucune configuration trouvée"
    fi
    
    # Compter les plugins actifs
    local plugin_count=0
    load_plugins_config
    local plugins=(RECURSIVE_SEARCH AUTO_LIBRARIES AUTO_GITIGNORE PERFORMANCE_ANALYSIS WATCH_MODE CMAKE_SUPPORT UPDATE_MODE ADVANCED_ANALYSIS AUTO_TESTS SMART_INCLUDES)
    
    for plugin in "${plugins[@]}"; do
        if [[ "${!plugin}" == "true" ]]; then
            ((plugin_count++))
        fi
    done
    
    echo -e "  ${PLUGIN} Plugins actifs: ${BOLD}$plugin_count${NC}/$(( ${#plugins[@]} ))"
    echo ""
}

show_main_menu() {
    show_header
    show_status
    
    echo -e "${YELLOW}${BOLD}${MENU} MENU PRINCIPAL${NC}"
    echo ""
    echo -e "  ${BOLD}1)${NC} ${UNINSTALL} Désinstaller MKF"
    echo -e "  ${BOLD}2)${NC} ${PLUGIN} Gestionnaire de plugins"
    echo -e "  ${BOLD}3)${NC} ${GEAR} Configuration avancée"
    echo -e "  ${BOLD}4)${NC} ${SHIELD} Diagnostic et réparation"
    echo -e "  ${BOLD}5)${NC} ${FOLDER} Ouvrir dossier de configuration"
    echo -e "  ${BOLD}6)${NC} ${MAGIC} Test et validation"
    echo -e "  ${BOLD}7)${NC} ${SPARKLES} Mise à jour MKF"
    echo -e "  ${BOLD}8)${NC} ${ROCKET} Réinstallation propre"
    echo -e "  ${BOLD}0)${NC} ${EXIT} Quitter"
    echo ""
}

show_plugins_menu() {
    show_header
    load_plugins_config
    
    echo -e "${PLUGIN}${BOLD} GESTIONNAIRE DE PLUGINS${NC}"
    echo ""
    
    local plugins=(
        "RECURSIVE_SEARCH:Scan récursif des sous-dossiers:📁"
        "AUTO_LIBRARIES:Détection automatique des bibliothèques:📚"
        "AUTO_GITIGNORE:Génération automatique de .gitignore:🗑️"
        "PERFORMANCE_ANALYSIS:Analyse de performance du Makefile:📊"
        "WATCH_MODE:Mode surveillance des fichiers:👁️"
        "CMAKE_SUPPORT:Support CMake en alternative:🏗️"
        "UPDATE_MODE:Mode mise à jour intelligente:🔄"
        "ADVANCED_ANALYSIS:Analyse avancée du code source:🔬"
        "AUTO_TESTS:Génération automatique de tests:🧪"
        "SMART_INCLUDES:Détection intelligente des includes:🧠"
    )
    
    for i in "${!plugins[@]}"; do
        local plugin_info="${plugins[$i]}"
        local var_name=$(echo "$plugin_info" | cut -d: -f1)
        local description=$(echo "$plugin_info" | cut -d: -f2)
        local emoji=$(echo "$plugin_info" | cut -d: -f3)
        local status="${!var_name}"
        
        local status_icon="${TOGGLE_OFF}"
        local status_text="${RED}Désactivé${NC}"
        if [[ "$status" == "true" ]]; then
            status_icon="${TOGGLE_ON}"
            status_text="${GREEN}Activé${NC}"
        fi
        
        echo -e "  ${BOLD}$((i+1)))${NC} $emoji $status_icon $description [$status_text]"
    done
    
    echo ""
    echo -e "  ${BOLD}11)${NC} ${SUCCESS} Activer tous les plugins"
    echo -e "  ${BOLD}12)${NC} ${ERROR} Désactiver tous les plugins"
    echo -e "  ${BOLD}13)${NC} ${GEAR} Configuration par défaut"
    echo -e "  ${BOLD}0)${NC} ${BACK} Retour au menu principal"
    echo ""
}

# ═══════════════════════════════════════════════════════════════
# 🔧 FONCTIONS PRINCIPALES
# ═══════════════════════════════════════════════════════════════

uninstall_mkf() {
    show_header
    echo -e "${UNINSTALL}${BOLD} DÉSINSTALLATION MKF${NC}"
    echo ""
    
    if ! detect_installation; then
        log_error "MKF n'est pas installé ou introuvable"
        read -p "$(echo -e "${CYAN}Appuie sur Entrée pour continuer...${NC}")"
        return
    fi
    
    echo -e "  ${WARNING} Installation détectée: ${BOLD}$INSTALL_PATH${NC}"
    echo -e "  ${WARNING} Type: ${BOLD}$INSTALL_TYPE${NC}"
    echo ""
    echo -e "${RED}${BOLD}⚠️  ATTENTION ⚠️${NC}"
    echo "Cette action va supprimer:"
    echo "  • L'exécutable MKF ($INSTALL_PATH)"
    if [[ -f "$INSTALL_DIR/mkf-manager" ]]; then
        echo "  • Le gestionnaire MKF ($INSTALL_DIR/mkf-manager)"
    fi
    echo "  • Les alias shell"
    echo "  • Optionnellement: la configuration"
    echo ""
    
    read -p "$(echo -e "${RED}Confirmer la désinstallation ? (y/N): ${NC}")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Désinstallation annulée"
        return
    fi
    
    # Suppression des exécutables
    {
        if [[ "$INSTALL_TYPE" == "system" ]]; then
            sudo rm -f "$INSTALL_PATH"
            sudo rm -f "$INSTALL_DIR/mkf-manager"
        else
            rm -f "$INSTALL_PATH"
            rm -f "$INSTALL_DIR/mkf-manager"
        fi
    } &
    
    show_spinner $! "Suppression des exécutables"
    
    # Suppression des alias shell
    local shell_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile")
    
    for shell_file in "${shell_files[@]}"; do
        if [[ -f "$shell_file" ]]; then
            if grep -q "alias $ALIAS_NAME=" "$shell_file" 2>/dev/null; then
                # Créer une backup
                cp "$shell_file" "$shell_file.mkf-backup.$(date +%s)"
                
                # Supprimer les lignes MKF
                sed -i '/# Alias MKF/,+20d' "$shell_file" 2>/dev/null || true
                sed -i "/alias $ALIAS_NAME=/d" "$shell_file" 2>/dev/null || true
                sed -i "/alias mkf-/d" "$shell_file" 2>/dev/null || true
                sed -i '/# Ajouté par MKF/,+5d' "$shell_file" 2>/dev/null || true
                
                log_success "Alias supprimés de $(basename "$shell_file")"
            fi
        fi
    done
    
    # Demander pour la configuration
    echo ""
    read -p "$(echo -e "${YELLOW}Supprimer aussi la configuration ? (y/N): ${NC}")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        log_success "Configuration supprimée"
    else
        log_info "Configuration conservée"
    fi
    
    echo ""
    log_success "Désinstallation terminée!"
    log_warning "Redémarre ton terminal pour finaliser"
    echo ""
    read -p "$(echo -e "${CYAN}Appuie sur Entrée pour continuer...${NC}")"
}

toggle_plugin() {
    local plugin_var="$1"
    local current_value="${!plugin_var}"
    
    if [[ "$current_value" == "true" ]]; then
        declare -g "$plugin_var=false"
        log_info "${TOGGLE_OFF} Plugin ${BOLD}$plugin_var${NC} ${RED}désactivé${NC}"
    else
        declare -g "$plugin_var=true"
        log_info "${TOGGLE_ON} Plugin ${BOLD}$plugin_var${NC} ${GREEN}activé${NC}"
    fi
    
    save_plugins_config
}

manage_plugins() {
    while true; do
        show_plugins_menu
        
        read -p "$(echo -e "${CYAN}Choix (0-13): ${NC}")" choice
        
        case $choice in
            1) toggle_plugin "RECURSIVE_SEARCH" ;;
            2) toggle_plugin "AUTO_LIBRARIES" ;;
            3) toggle_plugin "AUTO_GITIGNORE" ;;
            4) toggle_plugin "PERFORMANCE_ANALYSIS" ;;
            5) toggle_plugin "WATCH_MODE" ;;
            6) toggle_plugin "CMAKE_SUPPORT" ;;
            7) toggle_plugin "UPDATE_MODE" ;;
            8) toggle_plugin "ADVANCED_ANALYSIS" ;;
            9) toggle_plugin "AUTO_TESTS" ;;
            10) toggle_plugin "SMART_INCLUDES" ;;
            11)
                # Activer tous
                RECURSIVE_SEARCH=true AUTO_LIBRARIES=true AUTO_GITIGNORE=true
                PERFORMANCE_ANALYSIS=true WATCH_MODE=true CMAKE_SUPPORT=true
                UPDATE_MODE=true ADVANCED_ANALYSIS=true AUTO_TESTS=true
                SMART_INCLUDES=true
                save_plugins_config
                log_success "Tous les plugins activés"
                ;;
            12)
                # Désactiver tous
                RECURSIVE_SEARCH=false AUTO_LIBRARIES=false AUTO_GITIGNORE=false
                PERFORMANCE_ANALYSIS=false WATCH_MODE=false CMAKE_SUPPORT=false
                UPDATE_MODE=false ADVANCED_ANALYSIS=false AUTO_TESTS=false
                SMART_INCLUDES=false
                save_plugins_config
                log_success "Tous les plugins désactivés"
                ;;
            13)
                # Configuration par défaut
                RECURSIVE_SEARCH=true AUTO_LIBRARIES=true AUTO_GITIGNORE=false
                PERFORMANCE_ANALYSIS=true WATCH_MODE=false CMAKE_SUPPORT=false
                UPDATE_MODE=false ADVANCED_ANALYSIS=false AUTO_TESTS=false
                SMART_INCLUDES=true
                save_plugins_config
                log_success "Configuration par défaut restaurée"
                ;;
            0) break ;;
            *) log_error "Choix invalide" ;;
        esac
        
        if [[ "$choice" != "0" ]]; then
            sleep 1
        fi
    done
}

diagnostic_system() {
    show_header
    echo -e "${SHIELD}${BOLD} DIAGNOSTIC SYSTÈME${NC}"
    echo ""
    
    # Test 1: Installation
    echo -e "${BLUE}${BOLD}1. Vérification de l'installation${NC}"
    if detect_installation; then
        log_success "MKF trouvé: $INSTALL_PATH"
        
        if [[ -x "$INSTALL_PATH" ]]; then
            log_success "Permissions d'exécution OK"
        else
            log_error "Permissions d'exécution manquantes"
        fi
        
        local version_output="$($INSTALL_PATH --version 2>/dev/null || echo "")"
        if [[ -n "$version_output" ]]; then
            log_success "Version: $version_output"
        else
            log_error "Impossible d'obtenir la version"
        fi
    else
        log_error "MKF non installé"
    fi
    
    echo ""
    
    # Test 2: Configuration
    echo -e "${BLUE}${BOLD}2. Vérification de la configuration${NC}"
    if [[ -d "$CONFIG_DIR" ]]; then
        log_success "Dossier de configuration: $CONFIG_DIR"
        
        if [[ -f "$CONFIG_FILE" ]]; then
            log_success "Fichier de configuration principal trouvé"
        else
            log_warning "Fichier de configuration principal manquant"
        fi
        
        if [[ -f "$PLUGINS_CONFIG" ]]; then
            log_success "Configuration des plugins trouvée"
        else
            log_warning "Configuration des plugins manquante"
        fi
    else
        log_error "Dossier de configuration manquant"
    fi
    
    echo ""
    
    # Test 3: Alias et PATH
    echo -e "${BLUE}${BOLD}3. Vérification des alias et PATH${NC}"
    if command -v "$ALIAS_NAME" &> /dev/null; then
        log_success "Commande '$ALIAS_NAME' disponible"
    else
        log_error "Commande '$ALIAS_NAME' non disponible"
    fi
    
    if [[ ":$PATH:" == *":$HOME/bin:"* ]]; then
        log_success "~/bin dans le PATH"
    else
        log_warning "~/bin pas dans le PATH"
    fi
    
    echo ""
    
    # Test 4: Dépendances
    echo -e "${BLUE}${BOLD}4. Vérification des dépendances${NC}"
    local deps=("bash" "find" "grep" "sed" "awk")
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            log_success "$dep disponible"
        else
            log_error "$dep manquant"
        fi
    done
    
    echo ""
    read -p "$(echo -e "${CYAN}Appuie sur Entrée pour continuer...${NC}")"
}

configuration_avancee() {
    show_header
    echo -e "${GEAR}${BOLD} CONFIGURATION AVANCÉE${NC}"
    echo ""
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_warning "Aucune configuration trouvée"
        read -p "$(echo -e "${CYAN}Créer une configuration par défaut ? (Y/n): ${NC}")" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            mkdir -p "$CONFIG_DIR"
            cat > "$CONFIG_FILE" << EOF
# Configuration MKF v$VERSION
DEFAULT_CC="c++"
DEFAULT_CFLAGS="-std=c++98 -Wall -Wextra -Werror -g"
MAKEFILE_STYLE="classic"
FALLBACK_EMOJI="🚀"
EOF
            log_success "Configuration créée"
        fi
        return
    fi
    
    log_info "Configuration actuelle: $CONFIG_FILE"
    echo ""
    
    if command -v nano &> /dev/null; then
        read -p "$(echo -e "${CYAN}Ouvrir avec nano ? (Y/n): ${NC}")" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            nano "$CONFIG_FILE"
        fi
    elif command -v vim &> /dev/null; then
        read -p "$(echo -e "${CYAN}Ouvrir avec vim ? (Y/n): ${NC}")" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            vim "$CONFIG_FILE"
        fi
    else
        log_info "Chemin du fichier: $CONFIG_FILE"
        echo "Édite-le avec ton éditeur préféré"
    fi
    
    echo ""
    read -p "$(echo -e "${CYAN}Appuie sur Entrée pour continuer...${NC}")"
}

reinstall_mkf() {
    show_header
    echo -e "${ROCKET}${BOLD} RÉINSTALLATION PROPRE${NC}"
    echo ""
    
    log_warning "Cette fonction nécessite un accès internet"
    log_info "Elle va télécharger et réinstaller la dernière version"
    echo ""
    
    read -p "$(echo -e "${CYAN}Continuer ? (y/N): ${NC}")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        return
    fi
    
    # Sauvegarde de la configuration
    local backup_dir="/tmp/mkf-backup-$(date +%s)"
    if [[ -d "$CONFIG_DIR" ]]; then
        mkdir -p "$backup_dir"
        cp -r "$CONFIG_DIR"/* "$backup_dir/" 2>/dev/null || true
        log_success "Configuration sauvegardée dans $backup_dir"
    fi
    
    # Proposer différentes méthodes
    echo ""
    echo "Méthode de réinstallation:"
    echo "  1) Téléchargement automatique (curl)"
    echo "  2) Instructions manuelles"
    echo ""
    
    read -p "$(echo -e "${CYAN}Choix (1-2): ${NC}")" choice
    
    case $choice in
        1)
            if command -v curl &> /dev/null; then
                log_info "Lancement de l'installateur automatique..."
                curl -fsSL https://raw.githubusercontent.com/Baverdie/Mkf/main/install.sh | bash
            else
                log_error "curl non disponible"
                choice=2
            fi
            ;;
        2)
            ;;
    esac
    
    if [[ $choice -eq 2 ]]; then
        echo ""
        log_info "Instructions de réinstallation manuelle:"
        echo ""
        echo "1. Ouvre un nouveau terminal"
        echo "2. Exécute la commande:"
        echo -e "   ${YELLOW}curl -fsSL https://raw.githubusercontent.com/Baverdie/Mkf/main/install.sh | bash${NC}"
        echo "3. Ou télécharge depuis: https://github.com/Baverdie/Mkf"
        echo ""
    fi
    
    # Restauration de la configuration
    if [[ -d "$backup_dir" ]]; then
        read -p "$(echo -e "${CYAN}Restaurer la configuration sauvegardée ? (Y/n): ${NC}")" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            mkdir -p "$CONFIG_DIR"
            cp -r "$backup_dir"/* "$CONFIG_DIR/" 2>/dev/null || true
            log_success "Configuration restaurée"
        fi
        rm -rf "$backup_dir"
    fi
    
    echo ""
    read -p "$(echo -e "${CYAN}Appuie sur Entrée pour continuer...${NC}")"
}

test_validation() {
    show_header
    echo -e "${MAGIC}${BOLD} TESTS ET VALIDATION${NC}"
    echo ""
    
    if ! detect_installation; then
        log_error "MKF non installé, impossible de tester"
        read -p "$(echo -e "${CYAN}Appuie sur Entrée pour continuer...${NC}")"
        return
    fi
    
    log_info "Test du générateur MKF..."
    
    # Test 1: Version
    local version_output="$($INSTALL_PATH --version 2>/dev/null || echo "")"
    if [[ -n "$version_output" ]]; then
        log_success "Version: $version_output"
    else
        log_error "Impossible d'obtenir la version"
    fi
    
    # Test 2: Aide
    if $INSTALL_PATH --help &> /dev/null; then
        log_success "Commande --help fonctionnelle"
    else
        log_error "Commande --help défaillante"
    fi
    
    # Test 3: Configuration
    if $INSTALL_PATH --config &> /dev/null; then
        log_success "Commande --config fonctionnelle"
    else
        log_warning "Commande --config pourrait avoir des problèmes"
    fi
    
    # Test 4: Génération dans un dossier temporaire
    local test_dir="/tmp/mkf-test-$(date +%s)"
    mkdir -p "$test_dir/src"
    cd "$test_dir"
    
    # Créer un fichier de test
    cat > src/main.cpp << 'EOF'
#include <iostream>
int main() {
    std::cout << "Hello World!" << std::endl;
    return 0;
}
EOF
    
    log_info "Test de génération dans $test_dir..."
    
    if $INSTALL_PATH TestProject &> /dev/null; then
        if [[ -f "Makefile" ]]; then
            log_success "Génération de Makefile réussie"
            
            # Test de compilation si possible
            if command -v c++ &> /dev/null; then
                if make &> /dev/null; then
                    log_success "Compilation test réussie"
                else
                    log_warning "Compilation test échouée"
                fi
            fi
        else
            log_error "Makefile non généré"
        fi
    else
        log_error "Échec de la génération"
    fi
    
    # Nettoyage
    cd - > /dev/null
    rm -rf "$test_dir"
    
    echo ""
    read -p "$(echo -e "${CYAN}Appuie sur Entrée pour continuer...${NC}")"
}

update_mkf() {
    show_header
    echo -e "${SPARKLES}${BOLD} MISE À JOUR MKF${NC}"
    echo ""
    
    if ! detect_installation; then
        log_error "MKF non installé"
        read -p "$(echo -e "${CYAN}Appuie sur Entrée pour continuer...${NC}")"
        return
    fi
    
    log_info "Version actuelle: ${BOLD}$($INSTALL_PATH --version 2>/dev/null || echo "Inconnue")${NC}"
    echo ""
    
    read -p "$(echo -e "${CYAN}Lancer la mise à jour automatique ? (Y/n): ${NC}")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
        log_info "Mise à jour annulée"
        return
    fi
    
    # Utiliser la commande de mise à jour de MKF
    if command -v mkf &> /dev/null; then
        mkf --update
    else
        # Fallback : utiliser l'installateur
        log_info "Utilisation de l'installateur pour la mise à jour..."
        if command -v curl &> /dev/null; then
            curl -fsSL https://raw.githubusercontent.com/Baverdie/Mkf/main/install.sh | bash -s -- --force
        else
            log_error "curl requis pour la mise à jour"
            log_info "Installation manuelle nécessaire"
        fi
    fi
    
    echo ""
    read -p "$(echo -e "${CYAN}Appuie sur Entrée pour continuer...${NC}")"
}

# ═══════════════════════════════════════════════════════════════
# 🎯 FONCTION PRINCIPALE
# ═══════════════════════════════════════════════════════════════

main() {
    # Gestion des arguments en ligne de commande
    case "${1:-}" in
        uninstall) uninstall_mkf; exit 0 ;;
        plugins) manage_plugins; exit 0 ;;
        diagnostic) diagnostic_system; exit 0 ;;
        config) configuration_avancee; exit 0 ;;
        update) update_mkf; exit 0 ;;
        reinstall) reinstall_mkf; exit 0 ;;
        test) test_validation; exit 0 ;;
        --help|-h)
            echo "MKF Manager v$VERSION - Gestionnaire MKF"
            echo ""
            echo "Usage: $0 [commande]"
            echo ""
            echo "Commandes:"
            echo "  uninstall   Désinstaller MKF"
            echo "  plugins     Gérer les plugins"
            echo "  diagnostic  Diagnostic système"
            echo "  config      Configuration avancée"
            echo "  update      Mettre à jour MKF"
            echo "  reinstall   Réinstallation propre"
            echo "  test        Tests et validation"
            echo ""
            echo "Sans argument: Interface interactive"
            exit 0
            ;;
    esac
    
    # Interface interactive
    while true; do
        show_main_menu
        
        read -p "$(echo -e "${CYAN}Choix (0-8): ${NC}")" choice
        
        case $choice in
            1) uninstall_mkf ;;
            2) manage_plugins ;;
            3) configuration_avancee ;;
            4) diagnostic_system ;;
            5) 
                if [[ -d "$CONFIG_DIR" ]]; then
                    log_info "Ouverture: $CONFIG_DIR"
                    if command -v xdg-open &> /dev/null; then
                        xdg-open "$CONFIG_DIR"
                    elif command -v open &> /dev/null; then
                        open "$CONFIG_DIR"
                    else
                        log_warning "Impossible d'ouvrir automatiquement"
                        log_info "Chemin: $CONFIG_DIR"
                    fi
                else
                    log_error "Dossier de configuration introuvable"
                fi
                sleep 2
                ;;
            6) test_validation ;;
            7) update_mkf ;;
            8) reinstall_mkf ;;
            0) 
                echo ""
                echo -e "${GREEN}À bientôt! 🚀${NC}"
                exit 0
                ;;
            *) 
                log_error "Choix invalide"
                sleep 1
                ;;
        esac
    done
}

# Point d'entrée
main "$@"
