#!/bin/bash
# Utilitaire simple pour lire la version centralisée
VERSION_FILE="$(dirname "$0")/VERSION"
if [[ -f "$VERSION_FILE" ]]; then
    cat "$VERSION_FILE" | tr -d '\n\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
else
    echo "2.2.0"
fi
