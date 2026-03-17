#!/usr/bin/env bash

if [[ -z "${PROFILE_CATALOG_DIR:-}" ]]; then
    if [[ -n "${PROFILE_LIB_DIR:-}" ]]; then
        PROFILE_CATALOG_DIR="$PROFILE_LIB_DIR"
    else
        PROFILE_CATALOG_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    fi
fi

source "$PROFILE_CATALOG_DIR/definitions.sh"
source "$PROFILE_CATALOG_DIR/validate.sh"
