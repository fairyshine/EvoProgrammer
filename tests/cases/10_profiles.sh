#!/usr/bin/env bash

profile_catalog_output="$(
    ROOT_DIR="$ROOT_DIR" bash <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

count_non_empty_lines() {
    awk 'NF { count++ } END { print count + 0 }'
}

for category in languages frameworks project-types; do
    catalog_count="$(evop_supported_profiles_for_category "$category" | count_non_empty_lines)"
    definition_count="$(find "$ROOT_DIR/lib/profiles/definitions/$category" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/profile.sh' ';' -print | count_non_empty_lines)"

    if [[ "$catalog_count" != "$definition_count" ]]; then
        printf 'mismatch:%s:%s:%s\n' "$category" "$catalog_count" "$definition_count" >&2
        exit 1
    fi
done

printf 'languages=%s\n' "$(evop_supported_profiles_as_string languages)"
printf 'frameworks=%s\n' "$(evop_supported_profiles_as_string frameworks)"
printf 'project-types=%s\n' "$(evop_supported_profiles_as_string project-types)"
EOF
)"
assert_contains "$profile_catalog_output" "languages=cpp" "Profile catalog should expose discovered language profiles"
assert_contains "$profile_catalog_output" "typescript" "Profile catalog should include TypeScript"
assert_contains "$profile_catalog_output" "frameworks=actix-web" "Profile catalog should expose discovered framework profiles"
assert_contains "$profile_catalog_output" "nextjs" "Profile catalog should include Next.js"
assert_contains "$profile_catalog_output" "project-types=ai-agent" "Profile catalog should expose discovered project types"
assert_contains "$profile_catalog_output" "web-app" "Profile catalog should include web-app"
pass "Profile catalog matches on-disk definitions"
