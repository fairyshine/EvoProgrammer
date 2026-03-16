#!/usr/bin/env bash

PROFILE_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/profiles" && pwd)"

source "$PROFILE_LIB_DIR/catalog.sh"
source "$PROFILE_LIB_DIR/detect.sh"
source "$PROFILE_LIB_DIR/resolve.sh"
