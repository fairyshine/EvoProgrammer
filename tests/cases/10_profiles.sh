#!/usr/bin/env bash

profile_catalog_output="$(
    ROOT_DIR="$ROOT_DIR" bash <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

printf 'languages=%s\n' "$(evop_supported_profiles_as_string languages)"
printf 'frameworks=%s\n' "$(evop_supported_profiles_as_string frameworks)"
printf 'project-types=%s\n' "$(evop_supported_profiles_as_string project-types)"
EOF
)"
assert_contains "$profile_catalog_output" "languages=cpp" "Profile catalog should expose language profiles"
assert_contains "$profile_catalog_output" "frameworks=actix-web" "Profile catalog should expose framework profiles"
assert_contains "$profile_catalog_output" "project-types=ai-agent" "Profile catalog should expose project-type profiles"
pass "Profile catalog"

profile_hook_output="$(
    ROOT_DIR="$ROOT_DIR" bash <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/tests"

evop_reset_project_context
evop_apply_profile_project_context_hooks "languages" "python" "$tmpdir" "fix a failing endpoint"

printf 'search=%s\n' "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY"
printf 'verify=%s\n' "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY"
EOF
)"
assert_contains "$profile_hook_output" "Inspect package entrypoints, service modules, schemas, and tests before editing." "Language profiles should be able to contribute project-context search guidance"
assert_contains "$profile_hook_output" "Existing pytest-style tests are present; extend the nearest coverage before broadening integration checks." "Profile hooks should be able to add dynamic analysis based on the target directory"
pass "Profile project-context hooks"
