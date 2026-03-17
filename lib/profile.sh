#!/usr/bin/env bash

if [[ -z "${PROFILE_LIB_DIR:-}" ]]; then
    if [[ -n "${EVOP_LIB_DIR:-}" ]]; then
        PROFILE_LIB_DIR="$EVOP_LIB_DIR/profiles"
    else
        PROFILE_LIB_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/profiles"
    fi
fi

if [[ -z "${PROJECT_CONTEXT_LIB:-}" ]]; then
    if [[ -n "${EVOP_LIB_DIR:-}" ]]; then
        PROJECT_CONTEXT_LIB="$EVOP_LIB_DIR/project-context.sh"
    else
        PROJECT_CONTEXT_LIB="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/project-context.sh"
    fi
fi

source "$PROFILE_LIB_DIR/catalog.sh"
source "$PROFILE_LIB_DIR/detect.sh"
source "$PROJECT_CONTEXT_LIB"
source "$PROFILE_LIB_DIR/resolve.sh"
