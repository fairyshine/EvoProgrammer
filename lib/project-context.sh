#!/usr/bin/env bash

PROJECT_CONTEXT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/project-context" && pwd)"

source "$PROJECT_CONTEXT_LIB_DIR/state.sh"
source "$PROJECT_CONTEXT_LIB_DIR/commands.sh"
source "$PROJECT_CONTEXT_LIB_DIR/repo-analysis.sh"
source "$PROJECT_CONTEXT_LIB_DIR/workflow.sh"
source "$PROJECT_CONTEXT_LIB_DIR/render.sh"
