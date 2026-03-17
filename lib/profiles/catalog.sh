#!/usr/bin/env zsh

if [[ -z "${PROFILE_CATALOG_DIR:-}" ]]; then
    if [[ -n "${PROFILE_LIB_DIR:-}" ]]; then
        PROFILE_CATALOG_DIR="$PROFILE_LIB_DIR"
    else
        PROFILE_CATALOG_DIR="$(evop_callsite_dir)"
    fi
fi

source "$PROFILE_CATALOG_DIR/definitions.sh"
source "$PROFILE_CATALOG_DIR/validate.sh"
