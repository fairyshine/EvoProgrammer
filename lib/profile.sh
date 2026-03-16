#!/usr/bin/env bash

PROFILE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/profiles" && pwd)"
PROJECT_CONTEXT_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/project-context.sh"

source "$PROFILE_LIB_DIR/catalog.sh"
source "$PROFILE_LIB_DIR/detect.sh"
source "$PROJECT_CONTEXT_LIB"
source "$PROFILE_LIB_DIR/resolve.sh"
