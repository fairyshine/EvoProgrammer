#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

source "$ROOT_DIR/tests/lib/test_helpers.sh"
source "$ROOT_DIR/tests/cases/05_smoke.sh"

echo "All $PASS_COUNT tests passed."
