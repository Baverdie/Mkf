#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 🏷️ CONFIGURATION DE VERSION GLOBALE - MKF PROJECT
# ═══════════════════════════════════════════════════════════════
# Source unique de vérité pour la version du projet
# À sourcer dans tous les scripts : source "$(dirname "$0")/version-config.sh"

# Version du projet MKF
export MKF_VERSION="2.3.0"

# Fonction utilitaire pour récupérer la version
get_mkf_version() {
    echo "$MKF_VERSION"
}

# Fonction utilitaire pour définir la version
set_mkf_version() {
    local new_version="$1"
    if [[ ! "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Erreur: Format de version invalide. Utilisez X.Y.Z" >&2
        return 1
    fi
    
    # Mettre à jour la version dans ce fichier
    local script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/version-config.sh"
    sed -i.bak "s/export MKF_VERSION=\"[^\"]*\"/export MKF_VERSION=\"$new_version\"/" "$script_path"
    rm -f "$script_path.bak"
    
    export MKF_VERSION="2.3.0"
    echo "Version mise à jour vers: $new_version"
}

# Si le script est exécuté directement (pas sourcé)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "get"|"")
            echo "$MKF_VERSION"
            ;;
        "set")
            if [[ -z "$2" ]]; then
                echo "Usage: $0 set <version>" >&2
                exit 1
            fi
            set_mkf_version "$2"
            ;;
        *)
            echo "Version MKF: $MKF_VERSION"
            echo ""
            echo "Usage: $0 [get|set <version>]"
            echo "  get           Afficher la version actuelle"
            echo "  set X.Y.Z     Définir une nouvelle version"
            ;;
    esac
fi