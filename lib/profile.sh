#!/usr/bin/env zsh

if [[ -z "${PROFILE_LIB_DIR:-}" ]]; then
    if [[ -n "${EVOP_LIB_DIR:-}" ]]; then
        PROFILE_LIB_DIR="$EVOP_LIB_DIR/profiles"
    else
        PROFILE_LIB_DIR="$(evop_callsite_dir)/profiles"
    fi
fi

if [[ -z "${PROJECT_CONTEXT_LIB:-}" ]]; then
    if [[ -n "${EVOP_LIB_DIR:-}" ]]; then
        PROJECT_CONTEXT_LIB="$EVOP_LIB_DIR/project-context.sh"
    else
        PROJECT_CONTEXT_LIB="$(evop_callsite_dir)/project-context.sh"
    fi
fi

source "$PROFILE_LIB_DIR/diagnostics.sh"
source "$PROFILE_LIB_DIR/repo-shape.sh"
source "$PROFILE_LIB_DIR/catalog.sh"
source "$PROFILE_LIB_DIR/detect.sh"
source "$PROFILE_LIB_DIR/candidates.sh"
source "$PROJECT_CONTEXT_LIB"
source "$PROFILE_LIB_DIR/resolve.sh"
