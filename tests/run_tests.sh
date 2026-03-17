#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

source "$ROOT_DIR/tests/lib/test_helpers.sh"
source "$ROOT_DIR/tests/cases/05_smoke.sh"
source "$ROOT_DIR/tests/cases/10_profiles.sh"
source "$ROOT_DIR/tests/cases/20_loop.sh"
source "$ROOT_DIR/tests/cases/30_main.sh"
source "$ROOT_DIR/tests/cases/40_cli_doctor_install.sh"

echo "All $PASS_COUNT tests passed."
