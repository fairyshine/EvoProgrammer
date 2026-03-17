#!/usr/bin/env bash

if [[ -z "${PROJECT_CONTEXT_LIB_DIR:-}" ]]; then
    if [[ -n "${EVOP_LIB_DIR:-}" ]]; then
        PROJECT_CONTEXT_LIB_DIR="$EVOP_LIB_DIR/project-context"
    else
        PROJECT_CONTEXT_LIB_DIR="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/project-context"
    fi
fi

source "$PROJECT_CONTEXT_LIB_DIR/state.sh"
source "$PROJECT_CONTEXT_LIB_DIR/facts.sh"
source "$PROJECT_CONTEXT_LIB_DIR/commands.sh"
source "$PROJECT_CONTEXT_LIB_DIR/repo-analysis.sh"
source "$PROJECT_CONTEXT_LIB_DIR/workflow.sh"
source "$PROJECT_CONTEXT_LIB_DIR/render.sh"
