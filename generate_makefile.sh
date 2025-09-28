#!/bin/bash

# ┌─────────────────────────────────────────────────────────────┐
# │  🚀 GÉNÉRATEUR DE MAKEFILE STYLÉ - ÉDITION PLUGINS 🚀      │
# │  Créé avec amour par un dev paresseux mais efficace        │
# └─────────────────────────────────────────────────────────────┘

set -e

# Chargement de la version depuis la configuration globale
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/version-config.sh" ]]; then
    source "$SCRIPT_DIR/version-config.sh"
    VERSION="$MKF_VERSION"
else
    VERSION="2.2.1"  # Fallback
fi
CONFIG_DIR="$HOME/.config/mkf"
CONFIG_FILE="$CONFIG_DIR/config"
PLUGINS_DIR="$CONFIG_DIR/plugins"

# Couleurs et styles
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Emojis stylés
ROCKET="🚀"
GEAR="⚙️"
SPARKLES="✨"
FIRE="🔥"
PLUGIN="🔌"
CHECK="✅"
CROSS="❌"
WARNING="⚠️"

# ═══════════════════════════════════════════════════════════════
# 🎨 SYSTÈME D'AFFICHAGE STYLÉ
# ═══════════════════════════════════════════════════════════════

log_info() { echo -e "${BLUE}${BOLD}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}${BOLD}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}${BOLD}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}${BOLD}[ERROR]${NC} $1"; }
log_plugin() { echo -e "${PURPLE}${BOLD}[PLUGIN]${NC} $1"; }

# ═══════════════════════════════════════════════════════════════
# 🔄 SYSTÈME DE MISE À JOUR AUTOMATIQUE
# ═══════════════════════════════════════════════════════════════

# URLs pour les vérifications de version
REPO_API_URL="https://api.github.com/repos/Baverdie/Mkf/releases/latest"
REPO_RAW_URL="https://raw.githubusercontent.com/Baverdie/Mkf/main"
UPDATE_CACHE_FILE="$CONFIG_DIR/update_cache"
UPDATE_CONFIG_FILE="$CONFIG_DIR/update_config"

# Vérifier si les mises à jour sont activées
is_update_enabled() {
    if [[ -f "$UPDATE_CONFIG_FILE" ]]; then
        source "$UPDATE_CONFIG_FILE"
        [[ "${AUTO_UPDATE_CHECK:-true}" == "true" ]]
    else
        true  # Activé par défaut
    fi
}

# Obtenir la version actuelle
get_current_version() {
    echo "$VERSION"
}

# Obtenir la dernière version depuis GitHub
get_latest_version() {
    local latest_version=""
    
    # Essayer avec l'API GitHub d'abord
    if command -v curl >/dev/null 2>&1; then
        latest_version=$(curl -s "$REPO_API_URL" 2>/dev/null | grep '"tag_name"' | sed 's/.*"tag_name": *"v\?\([^"]*\)".*/\1/' 2>/dev/null)
    fi
    
    # Fallback : chercher dans version-config.sh sur GitHub
    if [[ -z "$latest_version" ]] && command -v curl >/dev/null 2>&1; then
        latest_version=$(curl -s "$REPO_RAW_URL/version-config.sh" 2>/dev/null | grep 'export MKF_VERSION=' | sed 's/.*export MKF_VERSION="\([^"]*\)".*/\1/' 2>/dev/null)
    fi
    
    echo "$latest_version"
}

# Comparer les versions (retourne 0 si update disponible)
version_compare() {
    local current="$1"
    local latest="$2"
    
    # Conversion en nombres pour comparaison
    local current_num=$(echo "$current" | sed 's/[^0-9.]//g' | awk -F. '{print $1*10000 + $2*100 + $3}')
    local latest_num=$(echo "$latest" | sed 's/[^0-9.]//g' | awk -F. '{print $1*10000 + $2*100 + $3}')
    
    [[ $latest_num -gt $current_num ]]
}

# Vérifier si on doit checker les mises à jour
should_check_update() {
    if ! is_update_enabled; then
        return 1
    fi
    
    if [[ ! -f "$UPDATE_CACHE_FILE" ]]; then
        return 0  # Premier check
    fi
    
    # Vérifier si le dernier check remonte à plus de 24h
    local last_check=$(cat "$UPDATE_CACHE_FILE" 2>/dev/null | head -1)
    local current_time=$(date +%s)
    local time_diff=$((current_time - last_check))
    
    # 86400 = 24 heures en secondes
    [[ $time_diff -gt 86400 ]]
}

# Sauvegarder les infos de cache
save_update_cache() {
    local latest_version="$1"
    local current_time=$(date +%s)
    
    mkdir -p "$CONFIG_DIR"
    cat > "$UPDATE_CACHE_FILE" << EOF
$current_time
$latest_version
$(get_current_version)
EOF
}

# Vérification des mises à jour (non-bloquante)
check_for_updates() {
    if ! should_check_update; then
        return
    fi
    
    local current_version=$(get_current_version)
    local latest_version=$(get_latest_version)
    
    # Sauvegarder le cache même si pas de nouvelle version
    save_update_cache "$latest_version"
    
    if [[ -n "$latest_version" ]] && version_compare "$current_version" "$latest_version"; then
        # Nouvelle version disponible
        cat > "$UPDATE_CACHE_FILE.available" << EOF
$latest_version
$(date +%s)
EOF
    else
        # Supprimer le fichier de notification s'il existe
        rm -f "$UPDATE_CACHE_FILE.available"
    fi
}

# Notification popup système
show_popup_notification() {
    if [[ ! -f "$UPDATE_CACHE_FILE.available" ]] || ! is_update_enabled; then
        return
    fi
    
    local latest_version=$(head -1 "$UPDATE_CACHE_FILE.available" 2>/dev/null)
    local current_version=$(get_current_version)
    
    if [[ -n "$latest_version" ]]; then
        local title="MKF - Mise à jour disponible"
        local message="Nouvelle version $latest_version disponible (actuellement $current_version)"
        
        # Tentative de notification popup selon l'OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS - osascript
            if command -v osascript >/dev/null 2>&1; then
                osascript -e "display notification \"$message\" with title \"$title\"" 2>/dev/null &
            fi
        elif [[ "$OSTYPE" == "linux"* ]] || [[ "$OSTYPE" == "msys"* ]]; then
            # Linux - notify-send
            if command -v notify-send >/dev/null 2>&1; then
                notify-send "$title" "$message" --icon=software-update-available 2>/dev/null &
            elif command -v zenity >/dev/null 2>&1; then
                zenity --info --title="$title" --text="$message" --timeout=5 2>/dev/null &
            fi
        fi
    fi
}

# Afficher la notification de mise à jour (si nécessaire)
show_update_notification() {
    if [[ ! -f "$UPDATE_CACHE_FILE.available" ]] || ! is_update_enabled; then
        return
    fi
    
    local latest_version=$(head -1 "$UPDATE_CACHE_FILE.available" 2>/dev/null)
    local current_version=$(get_current_version)
    
    if [[ -n "$latest_version" ]]; then
        # Notification popup en arrière-plan
        show_popup_notification
        
        # Notification console
        echo ""
        echo -e "${YELLOW}${BOLD}📢 Mise à jour disponible !${NC}"
        echo -e "  ${DIM}Version actuelle: ${NC}${BOLD}$current_version${NC}"
        echo -e "  ${DIM}Nouvelle version: ${NC}${GREEN}${BOLD}$latest_version${NC}"
        echo -e "  ${CYAN}Commande: ${NC}${YELLOW}mkf --update${NC} ${DIM}ou${NC} ${YELLOW}mkf-manager reinstall${NC}"
        echo -e "  ${DIM}Désactiver: ${NC}${YELLOW}mkf --no-update-check${NC}"
    fi
}

# Mise à jour automatique
perform_update() {
    echo -e "${BLUE}${BOLD}🔄 MISE À JOUR MKF${NC}"
    echo ""
    
    local current_version=$(get_current_version)
    local latest_version=$(get_latest_version)
    
    if [[ -z "$latest_version" ]]; then
        log_error "Impossible de récupérer la version distante"
        echo -e "${RED}Vérifiez votre connexion internet${NC}"
        return 1
    fi
    
    if ! version_compare "$current_version" "$latest_version"; then
        log_success "Vous avez déjà la dernière version ($current_version)"
        return 0
    fi
    
    echo -e "  ${BOLD}Version actuelle:${NC} $current_version"
    echo -e "  ${BOLD}Nouvelle version:${NC} ${GREEN}$latest_version${NC}"
    echo ""
    
    read -p "$(echo -e "${CYAN}Continuer la mise à jour ? (Y/n): ${NC}")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ -n $REPLY ]]; then
        log_info "Mise à jour annulée"
        return 0
    fi
    
    echo ""
    log_info "Téléchargement de la nouvelle version..."
    
    # Utiliser l'installateur pour la mise à jour
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "https://raw.githubusercontent.com/Baverdie/Mkf/main/install.sh" | bash -s -- --force --silent; then
            # Supprimer le cache de notification
            rm -f "$UPDATE_CACHE_FILE.available"
            
            log_success "Mise à jour réussie vers la version $latest_version !"
            echo ""
            echo -e "${GREEN}🎉 MKF a été mis à jour avec succès !${NC}"
            echo -e "${DIM}Redémarre ton terminal pour finaliser${NC}"
        else
            log_error "Échec de la mise à jour"
            return 1
        fi
    else
        log_error "curl requis pour la mise à jour automatique"
        echo -e "${YELLOW}Installation manuelle:${NC}"
        echo "  curl -fsSL https://raw.githubusercontent.com/Baverdie/Mkf/main/install.sh | bash"
        return 1
    fi
}

# Configuration des mises à jour
configure_updates() {
    local action="$1"
    
    mkdir -p "$CONFIG_DIR"
    
    case "$action" in
        "disable")
            echo 'AUTO_UPDATE_CHECK=false' > "$UPDATE_CONFIG_FILE"
            log_success "Vérifications de mise à jour désactivées"
            ;;
        "enable")
            echo 'AUTO_UPDATE_CHECK=true' > "$UPDATE_CONFIG_FILE"
            log_success "Vérifications de mise à jour activées"
            ;;
        "status")
            if is_update_enabled; then
                echo -e "${GREEN}✅ Vérifications automatiques activées${NC}"
            else
                echo -e "${RED}❌ Vérifications automatiques désactivées${NC}"
            fi
            
            if [[ -f "$UPDATE_CACHE_FILE" ]]; then
                local last_check=$(head -1 "$UPDATE_CACHE_FILE" 2>/dev/null)
                if [[ -n "$last_check" ]]; then
                    local check_date=$(date -r "$last_check" 2>/dev/null || date -d "@$last_check" 2>/dev/null || echo "Inconnu")
                    echo -e "${DIM}Dernière vérification: $check_date${NC}"
                fi
            fi
            
            if [[ -f "$UPDATE_CACHE_FILE.available" ]]; then
                local available_version=$(head -1 "$UPDATE_CACHE_FILE.available" 2>/dev/null)
                echo -e "${YELLOW}📢 Mise à jour disponible: $available_version${NC}"
            else
                echo -e "${GREEN}✅ Aucune mise à jour disponible${NC}"
            fi
            ;;
        *)
            echo "Usage: configure_updates [enable|disable|status]"
            ;;
    esac
}

# Animation de loading stylée
show_spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local temp
    
    while ps -p $pid > /dev/null 2>&1; do
        temp=${spinstr#?}
        printf " [%c] %s" "$spinstr" "$2"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r"
    done
    printf "    \r"
}

# Barre de progression stylée
progress_bar() {
    local current=$1
    local total=$2
    local width=40
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    printf "\r${CYAN}["
    printf "%*s" $completed | tr ' ' '█'
    printf "%*s" $remaining | tr ' ' '░'
    printf "] ${BOLD}%d%%${NC} " $percentage
}

# ═══════════════════════════════════════════════════════════════
# 🔌 SYSTÈME DE PLUGINS
# ═══════════════════════════════════════════════════════════════

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    else
        # Configuration par défaut
        RECURSIVE_SEARCH=true
        AUTO_LIBRARIES=true
        AUTO_GITIGNORE=false
        WATCH_MODE=false
        CMAKE_SUPPORT=false
        PERFORMANCE_ANALYSIS=false
        UPDATE_MODE=false
        DEFAULT_CC="c++"
        DEFAULT_CFLAGS="-std=c++98 -Wall -Wextra -Werror -g"
        MAKEFILE_STYLE="classic"
        FALLBACK_EMOJI="🚀"
    fi
}

save_config() {
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << EOF
# Configuration MKF - Générateur de Makefile v$VERSION
# Généré automatiquement - Modifiable manuellement

# Plugins activés
RECURSIVE_SEARCH=$RECURSIVE_SEARCH
AUTO_LIBRARIES=$AUTO_LIBRARIES
AUTO_GITIGNORE=$AUTO_GITIGNORE
WATCH_MODE=$WATCH_MODE
CMAKE_SUPPORT=$CMAKE_SUPPORT
PERFORMANCE_ANALYSIS=$PERFORMANCE_ANALYSIS
UPDATE_MODE=$UPDATE_MODE

# Paramètres de compilation
DEFAULT_CC="$DEFAULT_CC"
DEFAULT_CFLAGS="$DEFAULT_CFLAGS"

# Style et préférences
MAKEFILE_STYLE="$MAKEFILE_STYLE"
FALLBACK_EMOJI="$FALLBACK_EMOJI"

# Méta
CONFIG_VERSION="$VERSION"
LAST_UPDATE="$(date)"
EOF
}

# ═══════════════════════════════════════════════════════════════
# 🔌 PLUGINS INDIVIDUELS
# ═══════════════════════════════════════════════════════════════

# Plugin: Scan récursif
plugin_recursive_scan() {
    if [[ "$RECURSIVE_SEARCH" != "true" ]]; then return; fi
    
    log_plugin "Scan récursif activé ${PLUGIN}" >&2
    local src_dir="src"
    if [[ -d "$src_dir" ]]; then
        find "$src_dir" -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" | sed "s|^$src_dir/||" | sort
    fi
}

# Plugin: Détection automatique des bibliothèques
plugin_auto_libraries() {
    if [[ "$AUTO_LIBRARIES" != "true" ]]; then return; fi
    
    local src_files="$1"
    local libraries=""
    local detected_libs=()
    
    log_plugin "Détection des bibliothèques ${PLUGIN}" >&2
    
    for file in $src_files; do
        if [[ -f "src/$file" ]]; then
            local content=$(cat "src/$file" 2>/dev/null || echo "")
            
            if [[ $content =~ \#include.*opengl|GL/gl\.h ]] && [[ ! " ${detected_libs[@]} " =~ " opengl " ]]; then
                libraries="$libraries -lGL -lGLU -lglfw"
                detected_libs+=("opengl")
                log_info "  ${CHECK} OpenGL détecté" >&2
            fi
            if [[ $content =~ \#include.*pthread ]] && [[ ! " ${detected_libs[@]} " =~ " pthread " ]]; then
                libraries="$libraries -lpthread"
                detected_libs+=("pthread")
                log_info "  ${CHECK} pthreads détecté" >&2
            fi
            if [[ $content =~ \#include.*math\.h ]] && [[ ! " ${detected_libs[@]} " =~ " math " ]]; then
                libraries="$libraries -lm"
                detected_libs+=("math")
                log_info "  ${CHECK} math.h détecté" >&2
            fi
            if [[ $content =~ \#include.*curl ]] && [[ ! " ${detected_libs[@]} " =~ " curl " ]]; then
                libraries="$libraries -lcurl"
                detected_libs+=("curl")
                log_info "  ${CHECK} cURL détecté" >&2
            fi
            if [[ $content =~ \#include.*sqlite ]] && [[ ! " ${detected_libs[@]} " =~ " sqlite " ]]; then
                libraries="$libraries -lsqlite3"
                detected_libs+=("sqlite")
                log_info "  ${CHECK} SQLite détecté" >&2
            fi
        fi
    done
    
    echo "$libraries" | tr -s ' '
}

# Plugin: Génération de .gitignore
plugin_auto_gitignore() {
    if [[ "$AUTO_GITIGNORE" != "true" ]]; then return; fi
    
    local project_name="$1"
    
    log_plugin "Génération .gitignore ${PLUGIN}"
    
    cat > .gitignore << EOF
# ═══════════════════════════════════════════════════════════════
# 🗑️  GITIGNORE GÉNÉRÉ AUTOMATIQUEMENT - $(date)
# ═══════════════════════════════════════════════════════════════

# Exécutables
$project_name
$project_name.exe
*.exe
*.out

# Fichiers objets
*.o
*.obj
*.d
obj/
build/

# Bibliothèques
*.a
*.so
*.dylib
*.dll

# Fichiers temporaires et cache
*~
*.tmp
*.swp
*.swo
.DS_Store
Thumbs.db

# IDE et éditeurs
.vscode/
.idea/
*.vcxproj*
*.sln
*.suo
*.user
.vs/

# Debug et profiling
*.dSYM/
*.gdb_history
core
*.stackdump
callgrind.out.*

# Logs
*.log
log/

# Documentation générée
doc/html/
doc/latex/

# Makefiles de backup
Makefile.backup
Makefile.bak
EOF
    
    log_success "  ${CHECK} .gitignore créé"
}

# Plugin: Analyse de performance
plugin_performance_analysis() {
    if [[ "$PERFORMANCE_ANALYSIS" != "true" ]] || [[ ! -f "Makefile" ]]; then return; fi
    
    log_plugin "Analyse de performance ${PLUGIN}"
    
    local rules_count=$(grep -c "^[a-zA-Z].*:" Makefile 2>/dev/null || echo "0")
    local has_parallel=$(grep -q "\.PARALLEL" Makefile && echo "${CHECK}" || echo "${CROSS}")
    local has_phony=$(grep -q "\.PHONY" Makefile && echo "${CHECK}" || echo "${CROSS}")
    local src_count=$(grep "SRC =" Makefile | wc -w)
    
    echo ""
    log_info "📊 Analyse du Makefile:"
    echo -e "  ${CYAN}Règles définies:${NC} $rules_count"
    echo -e "  ${CYAN}Compilation parallèle:${NC} $has_parallel"
    echo -e "  ${CYAN}Règles .PHONY:${NC} $has_phony"
    echo -e "  ${CYAN}Fichiers source:${NC} $((src_count - 2))"
}

# ═══════════════════════════════════════════════════════════════
# 🎯 FONCTIONS PRINCIPALES
# ═══════════════════════════════════════════════════════════════

show_header() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🚀 MAKEFILE GENERATOR 🚀                  ║"
    echo "║                      Version $VERSION                          ║"
    echo "║              Générateur intelligent de Makefile              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_help() {
    show_header
    echo -e "${BLUE}${BOLD}USAGE:${NC}"
    echo "  mkf <nom_projet> [emoji] [fichiers_source...]"
    echo ""
    echo -e "${BLUE}${BOLD}OPTIONS:${NC}"
    echo "  -i, --interactive       Mode interactif pour choisir l'emoji"
    echo "  -u, --update           Mettre à jour MKF vers la dernière version"
    echo "  -g, --gitignore        Forcer la génération de .gitignore"
    echo "  -c, --cmake            Générer un CMakeLists.txt au lieu d'un Makefile"
    echo "  -w, --watch            Mode surveillance (regénération auto)"
    echo "  --config               Ouvrir la configuration des plugins"
    echo "  --analyze              Analyser un Makefile existant"
    echo "  --plugins              Lister les plugins disponibles"
    echo "  --update-status        Afficher le statut des mises à jour"
    echo "  --no-update-check      Désactiver les vérifications de MAJ"
    echo "  --enable-update-check  Activer les vérifications de MAJ"
    echo "  -v, --version          Afficher la version"
    echo "  -h, --help             Afficher cette aide"
    echo ""
    echo -e "${BLUE}${BOLD}EXEMPLES:${NC}"
    echo -e "  ${YELLOW}mkf Serializer${NC}                    # Détection automatique complète"
    echo -e "  ${YELLOW}mkf MyProject 🚀${NC}                 # Avec emoji personnalisé"
    echo -e "  ${YELLOW}mkf -i Calculator${NC}                # Mode interactif"
    echo -e "  ${YELLOW}mkf --update${NC}                     # Mettre à jour MKF"
    echo -e "  ${YELLOW}mkf --config${NC}                     # Configuration des plugins"
    echo ""
}

show_plugins_status() {
    show_header
    echo -e "${BLUE}${BOLD}📦 PLUGINS DISPONIBLES:${NC}"
    echo ""
    
    local plugins=(
        "RECURSIVE_SEARCH:Scan récursif des sous-dossiers:📁"
        "AUTO_LIBRARIES:Détection automatique des bibliothèques:📚"
        "AUTO_GITIGNORE:Génération automatique de .gitignore:🗑️"
        "WATCH_MODE:Mode surveillance des fichiers:👁️"
        "CMAKE_SUPPORT:Support CMake en alternative:🏗️"
        "PERFORMANCE_ANALYSIS:Analyse de performance du Makefile:📊"
        "UPDATE_MODE:Mode mise à jour intelligente:🔄"
    )
    
    for plugin_info in "${plugins[@]}"; do
        local var_name=$(echo "$plugin_info" | cut -d: -f1)
        local description=$(echo "$plugin_info" | cut -d: -f2)
        local emoji=$(echo "$plugin_info" | cut -d: -f3)
        local status="${!var_name}"
        
        if [[ "$status" == "true" ]]; then
            echo -e "  ${GREEN}${CHECK}${NC} ${emoji} ${BOLD}$description${NC}"
        else
            echo -e "  ${DIM}${CROSS}${NC} ${emoji} ${DIM}$description${NC}"
        fi
    done
    echo ""
}

configure_plugins() {
    show_header
    echo -e "${BLUE}${BOLD}⚙️ CONFIGURATION DES PLUGINS${NC}"
    echo ""
    
    local plugins=(
        "RECURSIVE_SEARCH:Scan récursif des sous-dossiers"
        "AUTO_LIBRARIES:Détection automatique des bibliothèques"
        "AUTO_GITIGNORE:Génération automatique de .gitignore"
        "PERFORMANCE_ANALYSIS:Analyse de performance du Makefile"
    )
    
    for plugin_info in "${plugins[@]}"; do
        local var_name=$(echo "$plugin_info" | cut -d: -f1)
        local description=$(echo "$plugin_info" | cut -d: -f2)
        local current_status="${!var_name}"
        
        echo -e "${CYAN}$description${NC}"
        echo -e "  Statut actuel: $([ "$current_status" == "true" ] && echo "${GREEN}Activé${NC}" || echo "${RED}Désactivé${NC}")"
        read -p "  Activer ce plugin ? (y/N): " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            declare -g "$var_name=true"
            log_success "  Plugin activé"
        else
            declare -g "$var_name=false"
            log_info "  Plugin désactivé"
        fi
        echo ""
    done
    
    save_config
    log_success "Configuration sauvegardée!"
}

# Génération de la bannière ASCII améliorée
generate_ascii_banner() {
    local project_name="$1"
    local upper_name=$(echo "$project_name" | tr '[:lower:]' '[:upper:]')
    
    if command -v figlet &> /dev/null; then
        figlet -f small "$upper_name" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed '$ s/\\n$//'
    else
        local len=${#upper_name}
        local border=""
        for ((i=0; i<len+8; i++)); do border+="═"; done
        echo "╔$border╗\\n║    $upper_name    ║\\n╚$border╝"
    fi
}

# Détection automatique des fichiers source (avec plugins)
auto_detect_sources() {
    local src_dir="src"
    local found_files=""
    
    if [[ "$RECURSIVE_SEARCH" == "true" ]]; then
        found_files=$(plugin_recursive_scan)
    else
        if [[ -d "$src_dir" ]]; then
            found_files=$(find "$src_dir" -maxdepth 1 -name "*.cpp" -type f | sed "s|^$src_dir/||" | sort)
        fi
    fi
    
    if [[ -n "$found_files" ]]; then
        echo "$found_files" | tr '\n' ' ' | sed 's/ $//'
    else
        echo "main.cpp"
    fi
}

# Analyse intelligente du code (améliorée)
analyze_source_files() {
    local src_files="$1"
    local project_type=""
    local confidence=0
    local src_dir="src"
    
    log_info "Analyse du code source..." >&2
    
    local total_files=$(echo $src_files | wc -w)
    local current_file=0
    
    for file in $src_files; do
        ((current_file++))
        progress_bar $current_file $total_files "Analyse de $file" >&2
        
        local filepath="$src_dir/$file"
        if [[ -f "$filepath" ]]; then
            local content=$(cat "$filepath" 2>/dev/null || echo "")
            
            # Analyse plus poussée
            if [[ $content =~ \#include.*math|calculate|compute|sqrt|pow|M_PI|cos|sin ]]; then
                project_type="math"; ((confidence += 4))
            elif [[ $content =~ \#include.*fstream|ofstream|ifstream|file|filesystem|iostream.*file ]]; then
                project_type="file"; ((confidence += 3))
            elif [[ $content =~ \#include.*algorithm|sort|find|binary_search|vector|list|map|set ]]; then
                project_type="algo"; ((confidence += 3))
            elif [[ $content =~ \#include.*thread|mutex|async|parallel|future|atomic ]]; then
                project_type="thread"; ((confidence += 4))
            elif [[ $content =~ \#include.*socket|network|http|tcp|curl|boost.*asio ]]; then
                project_type="network"; ((confidence += 4))
            elif [[ $content =~ serialize|deserialize|json|xml|yaml|protobuf ]]; then
                project_type="serial"; ((confidence += 4))
            elif [[ $content =~ encrypt|decrypt|hash|crypto|openssl|sha|md5|aes ]]; then
                project_type="crypto"; ((confidence += 4))
            elif [[ $content =~ database|sql|sqlite|mysql|postgres|mongodb ]]; then
                project_type="database"; ((confidence += 4))
            elif [[ $content =~ game|player|score|level|sprite|texture|entity ]]; then
                project_type="game"; ((confidence += 3))
            elif [[ $content =~ parse|lexer|token|syntax|grammar|ast|compiler ]]; then
                project_type="parser"; ((confidence += 4))
            elif [[ $content =~ test|assert|unittest|gtest|catch|doctest ]]; then
                project_type="test"; ((confidence += 3))
            elif [[ $content =~ \#include.*opengl|vulkan|directx|sdl|sfml|allegro ]]; then
                project_type="graphics"; ((confidence += 4))
            elif [[ $content =~ \#include.*boost|eigen|opencv|qt|gtk ]]; then
                project_type="library"; ((confidence += 2))
            fi
        fi
        
        sleep 0.01  # Animation fluide
    done
    
    # Nouvelle ligne après la barre de progression
    echo "" >&2
    echo "$project_type:$confidence"
}

# Sélection interactive améliorée
interactive_emoji_selection() {
    show_header
    echo -e "${YELLOW}${BOLD}🤔 Sélection interactive d'emoji${NC}"
    echo -e "${DIM}Je n'ai pas pu détecter automatiquement le type de projet${NC}"
    echo ""
    
    local options=(
        "🧮:Mathématiques/Calcul"
        "🎮:Jeu/Divertissement" 
        "🌐:Réseau/Web/API"
        "📁:Fichiers/I/O"
        "🔐:Cryptographie/Sécurité"
        "🗄️:Base de données"
        "📝:Parser/Compilateur"
        "🧪:Tests/Debug"
        "🎨:Graphiques/Rendu"
        "📚:Bibliothèque/Framework"
        "⚙️:Système/Utilitaire"
        "🚀:Autre/Général"
    )
    
    echo -e "${BLUE}${BOLD}Choisis une catégorie:${NC}"
    echo ""
    
    for i in "${!options[@]}"; do
        local emoji=$(echo "${options[$i]}" | cut -d: -f1)
        local desc=$(echo "${options[$i]}" | cut -d: -f2)
        printf "  %2d) %s %s\n" $((i+1)) "$emoji" "$desc"
    done
    
    echo ""
    while true; do
        read -p "$(echo -e "${CYAN}Ton choix (1-${#options[@]}): ${NC}")" choice
        
        if [[ "$choice" =~ ^[1-9]$|^1[0-2]$ ]] && [[ $choice -le ${#options[@]} ]]; then
            local selected_option="${options[$((choice-1))]}"
            local selected_emoji=$(echo "$selected_option" | cut -d: -f1)
            local selected_desc=$(echo "$selected_option" | cut -d: -f2)
            
            echo ""
            echo -e "${GREEN}${CHECK} Sélectionné: $selected_emoji $selected_desc${NC}"
            read -p "$(echo -e "${BLUE}Confirmer ce choix ? (Y/n): ${NC}")" confirm
            
            if [[ -z "$confirm" ]] || [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo "$selected_emoji"
                return
            else
                echo -e "${YELLOW}🔄 Nouveau choix...${NC}"
                echo ""
            fi
        else
            echo -e "${RED}${CROSS} Choix invalide. Entre un numéro entre 1 et ${#options[@]}.${NC}"
        fi
    done
}

# Choix intelligent d'emoji (amélioré)
get_smart_emoji() {
    local project_name="$1"
    local src_files="$2"
    
    local analysis=$(analyze_source_files "$src_files")
    local detected_type=$(echo "$analysis" | cut -d: -f1)
    local confidence=$(echo "$analysis" | cut -d: -f2)
    
    if [[ $confidence -ge 3 ]] && [[ -n "$detected_type" ]]; then
        case "$detected_type" in
            "math") echo "🧮" ;;
            "file") echo "📁" ;;
            "algo") echo "🔍" ;;
            "thread") echo "🧵" ;;
            "network") echo "🌐" ;;
            "serial") echo "🤳" ;;
            "crypto") echo "🔐" ;;
            "database") echo "🗄️" ;;
            "game") echo "🎮" ;;
            "parser") echo "📝" ;;
            "test") echo "🧪" ;;
            "graphics") echo "🎨" ;;
            "library") echo "📚" ;;
            *) echo "⚙️" ;;
        esac
        return
    fi
    
    # Fallback sur le nom
    local lower_name=$(echo "$project_name" | tr '[:upper:]' '[:lower:]')
    case "$lower_name" in
        *serial*) echo "🤳" ;;
        *calc*|*math*) echo "🧮" ;;
        *game*) echo "🎮" ;;
        *server*|*network*) echo "🌐" ;;
        *parse*) echo "📝" ;;
        *crypto*) echo "🔐" ;;
        *test*) echo "🧪" ;;
        *file*) echo "📁" ;;
        *) echo "$FALLBACK_EMOJI" ;;
    esac
}

# Génération du Makefile principal (améliorée)
generate_makefile() {
    local project_name="$1"
    local project_emoji="$2"
    local src_files="$3"
    local libraries="$4"
    local stealth="${5:-false}"
    
    local banner=$(generate_ascii_banner "$project_name")
    
    if [[ "$stealth" == "true" ]]; then
        # Mode discret - Conserve bannière et messages mais supprime les signatures MKF
        cat > Makefile << EOF
BANNER := "$banner"

PROJECT = $project_name
NAME = $project_name
PROJET_EMOJI = $project_emoji
CC = \$(SILENT)$DEFAULT_CC \$(CFLAGS)
CFLAGS = $DEFAULT_CFLAGS

HSRCS = src
SRC_DIR = src
OBJ_DIR = obj

SRC = $src_files
LIBS = $libraries

OBJS = \$(patsubst %.cpp,\$(OBJ_DIR)/%.o,\$(SRC))

DELET_LINE = \$(SILENT) echo -ne "\\033[2K";
RM = \$(SILENT) rm -rf

SILENT = @
COLOUR_GREEN = \\033[0;32m
COLOUR_RED = \\033[0;31m
COLOUR_PURPLE = \\033[38;5;197m
COLOUR_BLUE = \\033[0;34m
COLOUR_YELLOW = \\033[0;33m
COLOUR_CYAN = \\033[0;36m
NO_COLOR = \\033[m

bold := \$(shell tput bold)
notbold := \$(shell tput sgr0)

PRINT = \$(SILENT) printf "\\r%b"

MSG_CLEANING = "\$(COLOUR_RED)\$(bold)🧹 Nettoyage \$(notbold)\$(COLOUR_YELLOW)\$(PROJECT)\$(NO_COLOR)"
MSG_CLEANED = "\$(COLOUR_RED)\$(bold)[🗑️ ] \$(PROJECT) \$(notbold)\$(COLOUR_YELLOW)nettoyé \$(NO_COLOR)\\n"
MSG_TOTALLY_CLEANED = "\$(COLOUR_RED)\$(bold)[🗑️ ] \$(PROJECT) \$(notbold)\$(COLOUR_YELLOW)complètement nettoyé \$(NO_COLOR)\\n"
MSG_COMPILING = "\$(COLOUR_YELLOW)\$(bold)[⚡ Compilation ⚡]\$(notbold)\$(COLOUR_CYAN) \$(^)\$(NO_COLOR)"
MSG_LINKING = "\$(COLOUR_BLUE)\$(bold)[🔗 Linkage 🔗]\$(notbold)\$(COLOUR_CYAN) \$(NAME)\$(NO_COLOR)"
MSG_READY = "\$(PROJET_EMOJI) \$(COLOUR_BLUE)\$(bold)\$(PROJECT) \$(COLOUR_GREEN)\$(bold)prêt!\$(NO_COLOR)\\n"

HEADER = \$(SILENT) printf "\\n\$(COLOUR_PURPLE)"; printf \$(BANNER); printf "\$(NO_COLOR)\\n\\n"

# Règle par défaut
all: \$(NAME)

# Compilation de l'exécutable
\$(NAME): \$(OBJS)
	\$(HEADER)
	\$(DELET_LINE)
	\$(PRINT) \$(MSG_LINKING)
	\$(CC) \$^ \$(LIBS) -o \$@
	\$(DELET_LINE)
	\$(PRINT) \$(MSG_READY)

# Compilation des fichiers objets
\$(OBJ_DIR)/%.o: \$(SRC_DIR)/%.cpp
	@mkdir -p \$(@D)
	\$(DELET_LINE)
	\$(PRINT) \$(MSG_COMPILING)
	@\$(CC) \$(CFLAGS) -I \$(HSRCS) -o \$@ -c \$<

# Nettoyage des objets
clean:
	\$(PRINT) \$(MSG_CLEANING)
	\$(RM) \$(OBJ_DIR)
	\$(DELET_LINE)
	\$(PRINT) \$(MSG_CLEANED)

# Nettoyage complet
fclean: clean
	\$(PRINT) \$(MSG_CLEANING)
	\$(RM) \$(NAME)
	\$(DELET_LINE)
	\$(PRINT) \$(MSG_TOTALLY_CLEANED)

# Recompilation complète
re: fclean all

# Installation (optionnel)
install: \$(NAME)
	@echo "Installation de \$(NAME) dans /usr/local/bin"
	@sudo cp \$(NAME) /usr/local/bin/

# Désinstallation
uninstall:
	@echo "Suppression de \$(NAME) de /usr/local/bin"
	@sudo rm -f /usr/local/bin/\$(NAME)

# Aide
help:
	@echo "Commandes disponibles:"
	@echo "  make        - Compiler le projet"
	@echo "  make clean  - Nettoyer les objets"
	@echo "  make fclean - Nettoyage complet"
	@echo "  make re     - Recompiler from scratch"
	@echo "  make install- Installer globalement"
	@echo "  make help   - Afficher cette aide"

# Règles phony
.PHONY: all clean fclean re install uninstall help
EOF
    else
        # Mode normal avec signatures complètes
        cat > Makefile << EOF
# ╔══════════════════════════════════════════════════════════════╗
# ║            🚀 MAKEFILE GÉNÉRÉ AUTOMATIQUEMENT 🚀             ║
# ║                    Générateur MKF v$VERSION                    ║
# ║                     $(date)                      ║
# ╚══════════════════════════════════════════════════════════════╝

BANNER := "$banner"

PROJECT = $project_name
NAME = $project_name
PROJET_EMOJI = $project_emoji
CC = \$(SILENT)$DEFAULT_CC \$(CFLAGS)
CFLAGS = $DEFAULT_CFLAGS

HSRCS = src
SRC_DIR = src
OBJ_DIR = obj

SRC = $src_files
LIBS = $libraries

OBJS = \$(patsubst %.cpp,\$(OBJ_DIR)/%.o,\$(SRC))

DELET_LINE = \$(SILENT) echo -ne "\\033[2K";
RM = \$(SILENT) rm -rf

SILENT = @
COLOUR_GREEN = \\033[0;32m
COLOUR_RED = \\033[0;31m
COLOUR_PURPLE = \\033[38;5;197m
COLOUR_BLUE = \\033[0;34m
COLOUR_YELLOW = \\033[0;33m
COLOUR_CYAN = \\033[0;36m
NO_COLOR = \\033[m

bold := \$(shell tput bold)
notbold := \$(shell tput sgr0)

PRINT = \$(SILENT) printf "\\r%b"

MSG_CLEANING = "\$(COLOUR_RED)\$(bold)🧹 Nettoyage \$(notbold)\$(COLOUR_YELLOW)\$(PROJECT)\$(NO_COLOR)"
MSG_CLEANED = "\$(COLOUR_RED)\$(bold)[🗑️ ] \$(PROJECT) \$(notbold)\$(COLOUR_YELLOW)nettoyé \$(NO_COLOR)\\n"
MSG_TOTALLY_CLEANED = "\$(COLOUR_RED)\$(bold)[🗑️ ] \$(PROJECT) \$(notbold)\$(COLOUR_YELLOW)complètement nettoyé \$(NO_COLOR)\\n"
MSG_COMPILING = "\$(COLOUR_YELLOW)\$(bold)[⚡ Compilation ⚡]\$(notbold)\$(COLOUR_CYAN) \$(^)\$(NO_COLOR)"
MSG_LINKING = "\$(COLOUR_BLUE)\$(bold)[🔗 Linkage 🔗]\$(notbold)\$(COLOUR_CYAN) \$(NAME)\$(NO_COLOR)"
MSG_READY = "\$(PROJET_EMOJI) \$(COLOUR_BLUE)\$(bold)\$(PROJECT) \$(COLOUR_GREEN)\$(bold)prêt!\$(NO_COLOR)\\n"

HEADER = \$(SILENT) printf "\\n\$(COLOUR_PURPLE)"; printf \$(BANNER); printf "\$(NO_COLOR)\\n\\n"

# Règle par défaut
all: \$(NAME)

# Compilation de l'exécutable
\$(NAME): \$(OBJS)
	\$(HEADER)
	\$(DELET_LINE)
	\$(PRINT) \$(MSG_LINKING)
	\$(CC) \$^ \$(LIBS) -o \$@
	\$(DELET_LINE)
	\$(PRINT) \$(MSG_READY)

# Compilation des fichiers objets
\$(OBJ_DIR)/%.o: \$(SRC_DIR)/%.cpp
	@mkdir -p \$(@D)
	\$(DELET_LINE)
	\$(PRINT) \$(MSG_COMPILING)
	@\$(CC) \$(CFLAGS) -I \$(HSRCS) -o \$@ -c \$<

# Nettoyage des objets
clean:
	\$(PRINT) \$(MSG_CLEANING)
	\$(RM) \$(OBJ_DIR)
	\$(DELET_LINE)
	\$(PRINT) \$(MSG_CLEANED)

# Nettoyage complet
fclean: clean
	\$(PRINT) \$(MSG_CLEANING)
	\$(RM) \$(NAME)
	\$(DELET_LINE)
	\$(PRINT) \$(MSG_TOTALLY_CLEANED)

# Recompilation complète
re: fclean all

# Installation (optionnel)
install: \$(NAME)
	@echo "Installation de \$(NAME) dans /usr/local/bin"
	@sudo cp \$(NAME) /usr/local/bin/

# Désinstallation
uninstall:
	@echo "Suppression de \$(NAME) de /usr/local/bin"
	@sudo rm -f /usr/local/bin/\$(NAME)

# Aide
help:
	@echo "Commandes disponibles:"
	@echo "  make        - Compiler le projet"
	@echo "  make clean  - Nettoyer les objets"
	@echo "  make fclean - Nettoyage complet"
	@echo "  make re     - Recompiler from scratch"
	@echo "  make install- Installer globalement"
	@echo "  make help   - Afficher cette aide"

# Règles phony
.PHONY: all clean fclean re install uninstall help
EOF
    fi
}

# ═══════════════════════════════════════════════════════════════
# 👁️ MODE SURVEILLANCE
# ═══════════════════════════════════════════════════════════════

# Mode surveillance des fichiers
start_watch_mode() {
    local project_name="$1"
    local project_emoji="$2"
    local src_files="$3"
    local libraries="$4"
    local stealth_mode="$5"
    
    echo ""
    echo -e "${CYAN}${BOLD}👁️ MODE SURVEILLANCE ACTIVÉ${NC}"
    echo -e "${DIM}Surveillance des modifications des fichiers source...${NC}"
    echo -e "${DIM}Appuyez sur Ctrl+C pour arrêter${NC}"
    echo ""
    
    local last_modification=""
    local watch_interval=2
    
    while true; do
        # Calculer le hash des fichiers source pour détecter les changements
        local current_modification=""
        
        # Surveiller les fichiers source existants
        for file in $src_files; do
            local filepath="src/$file"
            if [[ -f "$filepath" ]]; then
                local file_mod=$(stat -f "%m" "$filepath" 2>/dev/null || stat -c "%Y" "$filepath" 2>/dev/null || echo "0")
                current_modification="$current_modification$file:$file_mod;"
            fi
        done
        
        # Surveiller les nouveaux fichiers dans src/
        if [[ -d "src" ]]; then
            local new_files=$(find src -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" 2>/dev/null | sort)
            for new_file in $new_files; do
                local basename_file=$(basename "$new_file")
                if [[ ! " $src_files " =~ " $basename_file " ]]; then
                    log_info "📄 Nouveau fichier détecté: $basename_file"
                    src_files="$src_files $basename_file"
                fi
            done
        fi
        
        # Si changement détecté, regénérer
        if [[ "$current_modification" != "$last_modification" ]] && [[ -n "$last_modification" ]]; then
            echo ""
            log_info "🔄 Changement détecté, regénération du Makefile..."
            
            # Regénérer avec les mêmes paramètres
            generate_makefile "$project_name" "$project_emoji" "$src_files" "$libraries" "$stealth_mode"
            
            # Analyse de performance
            plugin_performance_analysis
            
            log_success "✅ Makefile mis à jour"
            echo ""
            echo -e "${DIM}Surveillance continue...${NC}"
        fi
        
        last_modification="$current_modification"
        sleep $watch_interval
    done
}

# ═══════════════════════════════════════════════════════════════
# 🎯 FONCTION PRINCIPALE
# ═══════════════════════════════════════════════════════════════

main() {
    load_config
    
    # Vérification des mises à jour en arrière-plan (non-bloquant)
    check_for_updates &
    
    # Variables pour les options
    local interactive_mode=false
    local force_gitignore=false
    local cmake_mode=false
    local watch_mode=false
    local stealth_mode=false
    
    # Parse des options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--interactive)
                interactive_mode=true
                shift
                ;;
            -u|--update)
                perform_update
                exit $?
                ;;
            -g|--gitignore)
                force_gitignore=true
                shift
                ;;
            -c|--cmake)
                cmake_mode=true
                shift
                ;;
            -w|--watch)
                watch_mode=true
                shift
                ;;
            --config)
                configure_plugins
                exit 0
                ;;
            --analyze)
                plugin_performance_analysis
                exit 0
                ;;
            --plugins)
                show_plugins_status
                exit 0
                ;;
            --update-status)
                configure_updates "status"
                exit 0
                ;;
            --no-update-check)
                configure_updates "disable"
                exit 0
                ;;
            --enable-update-check)
                configure_updates "enable"
                exit 0
                ;;
            --simulate-update)
                # Fonction cachée pour tester les notifications
                shift
                local test_version="${1:-$(echo "$VERSION" | awk -F. '{print $1"."$2+1".0"}')}"
                mkdir -p "$CONFIG_DIR"
                echo -e "$test_version\n$(date +%s)" > "$UPDATE_CACHE_FILE.available"
                echo "Simulation d'une mise à jour vers $test_version créée"
                exit 0
                ;;
            --clear-simulation)
                # Fonction cachée pour nettoyer les tests
                rm -f "$UPDATE_CACHE_FILE.available"
                echo "Simulation de mise à jour supprimée"
                exit 0
                ;;
            --test-popup)
                # Fonction cachée pour tester uniquement la popup
                local title="MKF - Test de notification"
                local message="Ceci est un test de notification popup"
                if [[ "$OSTYPE" == "darwin"* ]] && command -v osascript >/dev/null 2>&1; then
                    osascript -e "display notification \"$message\" with title \"$title\""
                elif command -v notify-send >/dev/null 2>&1; then
                    notify-send "$title" "$message" --icon=software-update-available
                elif command -v zenity >/dev/null 2>&1; then
                    zenity --info --title="$title" --text="$message" --timeout=5
                else
                    echo "Aucun système de notification popup disponible"
                fi
                exit 0
                ;;
            --42)
                # Option ultra-cachée pour mode discret (masque uniquement les signatures du Makefile)
                stealth_mode=true
                shift
                ;;
            -v|--version)
                echo "MKF Makefile Generator v$VERSION"
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Option inconnue: $1"
                show_help
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Vérification des arguments
    if [[ $# -eq 0 ]]; then
        show_help
        exit 0
    fi
    
    show_header
    
    local project_name="$1"
    local provided_emoji="$2"
    local manual_src_files="${@:3}"
    
    log_info "Initialisation du projet: ${BOLD}$project_name${NC}"
    
    # Détection des fichiers source
    local src_files
    if [[ -n "$manual_src_files" ]]; then
        src_files="$manual_src_files"
        log_info "📁 Fichiers source spécifiés: ${YELLOW}$src_files${NC}"
    else
        log_info "🔍 Détection automatique des fichiers source..."
        src_files=$(auto_detect_sources)
        if [[ "$src_files" == "main.cpp" ]] && [[ ! -f "src/main.cpp" ]]; then
            log_warning "Aucun fichier source détecté, utilisation du défaut: main.cpp"
        else
            log_success "Fichiers détectés: ${YELLOW}$src_files${NC}"
        fi
    fi
    
    # Choix de l'emoji
    local project_emoji
    if [[ -n "$provided_emoji" ]]; then
        project_emoji="$provided_emoji"
        log_info "Emoji fourni: $project_emoji"
    elif [[ "$interactive_mode" == true ]]; then
        project_emoji=$(interactive_emoji_selection)
    else
        log_info "🤖 Détection automatique du type de projet..."
        project_emoji=$(get_smart_emoji "$project_name" "$src_files")
        
        local analysis=$(analyze_source_files "$src_files")
        local detected_type=$(echo "$analysis" | cut -d: -f1)
        local confidence=$(echo "$analysis" | cut -d: -f2)
        
        if [[ $confidence -ge 3 ]] && [[ -n "$detected_type" ]]; then
            log_success "Type détecté: ${YELLOW}$detected_type${NC} (confiance: $confidence/10)"
        fi
    fi
    
    log_info "Emoji sélectionné: $project_emoji"
    
    # Exécution des plugins
    echo ""
    log_info "${SPARKLES} Exécution des plugins..."
    
    # Plugin bibliothèques
    local libraries=$(plugin_auto_libraries "$src_files")
    if [[ -n "$libraries" ]]; then
        log_success "Bibliothèques détectées: ${YELLOW}$libraries${NC}"
    fi
    
    # Création des dossiers
    if [[ ! -d "src" ]]; then
        mkdir -p src
        log_success "📂 Dossier 'src' créé"
    fi
    
    # Génération du Makefile
    echo ""
    log_info "⚡ Génération du Makefile..."
    generate_makefile "$project_name" "$project_emoji" "$src_files" "$libraries" "$stealth_mode"
    
    # Plugin .gitignore
    if [[ "$force_gitignore" == true ]] || [[ "$AUTO_GITIGNORE" == true ]]; then
        plugin_auto_gitignore "$project_name"
    fi
    
    # Création d'un main.cpp basique si nécessaire
    if [[ ! -f "src/main.cpp" ]] && [[ "$src_files" == "main.cpp" ]]; then
        cat > src/main.cpp << 'EOF'
#include <iostream>

int main() {
    std::cout << "Hello World! 🚀" << std::endl;
    return 0;
}
EOF
        log_success "📄 Fichier 'src/main.cpp' créé"
    fi
    
    # Analyse de performance
    plugin_performance_analysis
    
    # Messages de fin
    echo ""
    log_success "${SPARKLES} Makefile généré avec succès!"
    log_info "📁 Fichier créé: ${YELLOW}./Makefile${NC}"
    echo ""
    echo -e "${PURPLE}${BOLD}🎯 Commandes disponibles:${NC}"
    echo -e "   ${YELLOW}make${NC}           # Compiler le projet"
    echo -e "   ${YELLOW}make clean${NC}     # Nettoyer les objets"
    echo -e "   ${YELLOW}make fclean${NC}    # Nettoyage complet"
    echo -e "   ${YELLOW}make re${NC}        # Recompiler from scratch"
    echo -e "   ${YELLOW}make help${NC}      # Aide du Makefile"
    echo ""
    
    if ! command -v figlet &> /dev/null; then
        log_info "💡 ${DIM}Astuce: Installe 'figlet' pour des bannières ASCII plus stylées!${NC}"
        echo -e "   ${PURPLE}brew install figlet${NC} ou ${PURPLE}apt-get install figlet${NC}"
        echo ""
    fi
    
    log_success "${FIRE} Projet prêt à décoller! ${FIRE}"
    
    # Notification de mise à jour si disponible
    show_update_notification
    
    # Mode surveillance si activé
    if [[ "$watch_mode" == "true" ]]; then
        start_watch_mode "$project_name" "$project_emoji" "$src_files" "$libraries" "$stealth_mode"
    fi
}

# Point d'entrée
main "$@"
