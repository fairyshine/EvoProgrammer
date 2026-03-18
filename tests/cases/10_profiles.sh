#!/usr/bin/env zsh

profile_catalog_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

printf 'languages=%s\n' "$(evop_supported_profiles_as_string languages)"
printf 'frameworks=%s\n' "$(evop_supported_profiles_as_string frameworks)"
printf 'project-types=%s\n' "$(evop_supported_profiles_as_string project-types)"
EOF
)"
assert_contains "$profile_catalog_output" "languages=cpp" "Profile catalog should expose language profiles"
assert_contains "$profile_catalog_output" "dart" "Profile catalog should expose the Dart language profile"
assert_contains "$profile_catalog_output" "frameworks=actix-web" "Profile catalog should expose framework profiles"
assert_contains "$profile_catalog_output" "flutter" "Profile catalog should expose the Flutter framework profile"
assert_contains "$profile_catalog_output" "project-types=ai-agent" "Profile catalog should expose project-type profiles"
assert_contains "$profile_catalog_output" "mobile-app" "Profile catalog should expose the mobile-app project type"
pass "Profile catalog"

profile_hook_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
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

profile_cache_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/test"
printf 'name: dart_app\nflutter:\n  uses-material-design: true\n' >"$tmpdir/pubspec.yaml"

first_prompt="$(evop_print_profile_prompt frameworks flutter)"
second_prompt="$(evop_print_profile_prompt frameworks flutter)"

evop_reset_project_context
evop_apply_profile_project_context_hooks "frameworks" "flutter" "$tmpdir" ""

printf 'same_prompt=%s\n' "$([[ "$first_prompt" == "$second_prompt" ]] && printf true || printf false)"
printf 'search=%s\n' "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY"
EOF
)"
assert_contains "$profile_cache_output" "same_prompt=true" "Profile caching should preserve repeated prompt rendering"
assert_contains "$profile_cache_output" "integration_test/" "Profile caching should preserve apply-project-context hooks"
pass "Profile definition cache reuse"

profile_catalog_zsh_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

printf 'languages=%s\n' "$(evop_supported_profiles_as_string languages)"
EOF
)"
assert_contains "$profile_catalog_zsh_output" "languages=cpp" "Profile catalog should load cleanly under zsh"
pass "Profile catalog zsh compatibility"

profile_candidate_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
printf '#!/usr/bin/env zsh\n' >"$tmpdir/tool.sh"

evop_prepare_profile_detection_candidates "languages" "$tmpdir" ""

printf 'mode=%s\n' "$EVOP_PROFILE_CANDIDATE_MODE"
printf 'candidates=%s\n' "$EVOP_PROFILE_CANDIDATE_LIST"
EOF
)"
assert_contains "$profile_candidate_output" "mode=filtered" "Profile candidate planning should narrow obvious repositories"
assert_contains "$profile_candidate_output" "candidates=shell" "Profile candidate planning should keep the matching shell profile"
pass "Profile candidate planning"

profile_detect_zsh_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
printf '#!/usr/bin/env zsh\n' >"$tmpdir/tool.sh"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'detected=%s\n' "$EVOP_DETECTED_PROFILE"
else
    printf 'detected=none\n'
fi
EOF
)"
assert_contains "$profile_detect_zsh_output" "detected=shell" "Profile detection should honor filename patterns under zsh"
pass "Profile detect zsh patterns"

shell_cli_candidate_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/bin" "$tmpdir/lib" "$tmpdir/tests"
printf '#!/usr/bin/env zsh\n' >"$tmpdir/bin/tool"
printf '#!/usr/bin/env zsh\n' >"$tmpdir/MAIN.sh"

for category in languages frameworks project-types; do
    evop_prepare_profile_detection_candidates "$category" "$tmpdir" ""
    printf '%s_mode=%s\n' "$category" "$EVOP_PROFILE_CANDIDATE_MODE"
    printf '%s_candidates=%s\n' "$category" "$EVOP_PROFILE_CANDIDATE_LIST"
done

if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
else
    printf 'project_type=none\n'
fi
EOF
)"
assert_contains "$shell_cli_candidate_output" "languages_mode=filtered" "Shell CLI repos should narrow language candidates"
assert_contains "$shell_cli_candidate_output" "languages_candidates=shell" "Shell CLI repos should keep the shell language candidate"
assert_contains "$shell_cli_candidate_output" "frameworks_mode=none" "Shell CLI repos should skip irrelevant framework detection"
assert_contains "$shell_cli_candidate_output" "project-types_mode=filtered" "Shell CLI repos should narrow project-type candidates"
assert_contains "$shell_cli_candidate_output" "project-types_candidates=cli-tool" "Shell CLI repos should keep the cli-tool project type candidate"
assert_contains "$shell_cli_candidate_output" "project_type=cli-tool" "Shell CLI repos should auto-detect the cli-tool project type"
pass "Shell CLI project detection"

shell_cli_candidate_zsh_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/bin" "$tmpdir/lib" "$tmpdir/tests"
printf '#!/usr/bin/env zsh\n' >"$tmpdir/bin/tool"
printf '#!/usr/bin/env zsh\n' >"$tmpdir/MAIN.sh"

evop_prepare_profile_detection_candidates "frameworks" "$tmpdir" ""
printf 'frameworks_mode=%s\n' "$EVOP_PROFILE_CANDIDATE_MODE"
evop_prepare_profile_detection_candidates "project-types" "$tmpdir" ""
printf 'project-types_candidates=%s\n' "$EVOP_PROFILE_CANDIDATE_LIST"

if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
else
    printf 'project_type=none\n'
fi
EOF
)"
assert_contains "$shell_cli_candidate_zsh_output" "frameworks_mode=none" "Shell CLI repos should skip framework detection under zsh"
assert_contains "$shell_cli_candidate_zsh_output" "project-types_candidates=cli-tool" "Shell CLI repos should keep cli-tool candidates under zsh"
assert_contains "$shell_cli_candidate_zsh_output" "project_type=cli-tool" "Shell CLI repos should auto-detect cli-tool under zsh"
pass "Shell CLI project detection zsh"

flutter_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/lib" "$tmpdir/test" "$tmpdir/android" "$tmpdir/ios"
cat >"$tmpdir/pubspec.yaml" <<'PUBSPEC'
name: flutter_app
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
PUBSPEC
printf 'void main() {}\n' >"$tmpdir/lib/main.dart"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_framework_profile "$tmpdir" ""; then
    printf 'framework=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$flutter_profile_output" "language=dart" "Flutter repos should detect the Dart language profile"
assert_contains "$flutter_profile_output" "framework=flutter" "Flutter repos should detect the Flutter framework profile"
assert_contains "$flutter_profile_output" "project_type=mobile-app" "Flutter repos should detect the mobile-app project type"
pass "Flutter profile detection"

profiles_summary_output="$(run_expect_success "PROFILES should summarize supported profiles" "$PROFILES_SCRIPT" --category languages)"
assert_contains "$profiles_summary_output" "Supported profiles (Languages):" "PROFILES summary should print the selected category"
assert_contains "$profiles_summary_output" "shell:" "PROFILES summary should include language entries"
assert_contains "$profiles_summary_output" "lib/profiles/definitions/languages/shell/profile.sh" "PROFILES summary should include definition paths"
pass "PROFILES summary"

profiles_json_output="$(run_expect_success "PROFILES should render json output" "$PROFILES_SCRIPT" --category project-types --format json)"
profiles_json_summary="$(PROFILES_JSON="$profiles_json_output" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["PROFILES_JSON"])
print(data["category"])
print(f"cli_tool_ok={any(item['name'] == 'cli-tool' for item in data['categories']['project-types'])}")
print(f"summary_ok={all(item['summary'] for item in data['categories']['project-types'])}")
PY
)"
assert_contains "$profiles_json_summary" "project-types" "PROFILES json should report the selected category"
assert_contains "$profiles_json_summary" "cli_tool_ok=True" "PROFILES json should include project type entries"
assert_contains "$profiles_json_summary" "summary_ok=True" "PROFILES json should include summaries"
pass "PROFILES json"

profiles_report_env="$TEST_TMPDIR/profiles-report.env"
run_expect_success "PROFILES should write an env report file" "$PROFILES_SCRIPT" --category frameworks --report-file "$profiles_report_env" --report-format env >/dev/null
profiles_report_env_summary="$(
    PROFILES_REPORT_ENV="$profiles_report_env" zsh <<'EOF'
set -euo pipefail
source "$PROFILES_REPORT_ENV"
printf '%s\n' "$EVOP_PROFILES_CATEGORY"
printf 'count_ok=%s\n' "$([[ "$EVOP_PROFILES_FRAMEWORK_COUNT" =~ ^[1-9][0-9]*$ ]] && printf true || printf false)"
printf 'name_ok=%s\n' "$([[ -n "${EVOP_PROFILES_FRAMEWORK_1_NAME:-}" ]] && printf true || printf false)"
printf 'summary_ok=%s\n' "$([[ -n "${EVOP_PROFILES_FRAMEWORK_1_SUMMARY:-}" ]] && printf true || printf false)"
EOF
)"
assert_contains "$profiles_report_env_summary" "frameworks" "PROFILES env should export the selected category"
assert_contains "$profiles_report_env_summary" "count_ok=true" "PROFILES env should export category counts"
assert_contains "$profiles_report_env_summary" "name_ok=true" "PROFILES env should export entry names"
assert_contains "$profiles_report_env_summary" "summary_ok=true" "PROFILES env should export entry summaries"
pass "PROFILES env report"
