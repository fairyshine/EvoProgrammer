#!/usr/bin/env zsh

if [[ -z "${PROJECT_CONTEXT_LIB_DIR:-}" ]]; then
    if [[ -n "${EVOP_LIB_DIR:-}" ]]; then
        PROJECT_CONTEXT_LIB_DIR="$EVOP_LIB_DIR/project-context"
    else
        PROJECT_CONTEXT_LIB_DIR="$(evop_callsite_dir)/project-context"
    fi
fi

source "$PROJECT_CONTEXT_LIB_DIR/state.sh"
source "$PROJECT_CONTEXT_LIB_DIR/slots.sh"
source "$PROJECT_CONTEXT_LIB_DIR/facts.sh"
source "$PROJECT_CONTEXT_LIB_DIR/timings.sh"
source "$PROJECT_CONTEXT_LIB_DIR/commands.sh"
source "$PROJECT_CONTEXT_LIB_DIR/agent-catalog.sh"
source "$PROJECT_CONTEXT_LIB_DIR/repo-analysis.sh"
source "$PROJECT_CONTEXT_LIB_DIR/workflow.sh"
source "$PROJECT_CONTEXT_LIB_DIR/snapshot.sh"
source "$PROJECT_CONTEXT_LIB_DIR/render.sh"
