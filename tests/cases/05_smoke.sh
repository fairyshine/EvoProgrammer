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
assert_contains "$profile_catalog_output" "frameworks=actix-web" "Profile catalog should expose discovered framework profiles"
assert_contains "$profile_catalog_output" "project-types=ai-agent" "Profile catalog should expose discovered project types"
pass "Profile catalog smoke"

setup_agent_test_workspace

loop_help_output="$(run_expect_success "LOOP help should succeed" "$LOOP_SCRIPT" --help)"
assert_contains "$loop_help_output" "Usage: ./LOOP.sh [options] [prompt]" "LOOP help output should mention options usage"
pass "LOOP help smoke"

loop_dry_run_output="$(run_expect_success "LOOP dry-run should validate core options" env PATH="/usr/bin:/bin" "$LOOP_SCRIPT" --agent claude --target-dir "$TEST_TARGET_DIR" --language typescript --framework react --project-type web-app --prompt "smoke prompt" --dry-run)"
assert_contains "$loop_dry_run_output" "Agent: claude" "LOOP dry-run should print the selected agent"
assert_contains "$loop_dry_run_output" "Target language: typescript" "LOOP dry-run should print the selected language profile"
assert_contains "$loop_dry_run_output" "Target framework: react" "LOOP dry-run should print the selected framework profile"
assert_contains "$loop_dry_run_output" "Project type: web-app" "LOOP dry-run should print the selected project type"
pass "LOOP dry-run smoke"

FAKE_CODEX_LOG="$TEST_TMPDIR/smoke-loop.log"
export FAKE_CODEX_LOG
run_expect_success "LOOP should invoke codex once in smoke mode" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --target-dir "$TEST_TARGET_DIR" --prompt "ship it" >/dev/null
smoke_loop_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$smoke_loop_log" "arg=exec" "LOOP smoke run should invoke codex exec"
assert_contains "$smoke_loop_log" "arg=ship it" "LOOP smoke run should forward the prompt"
pass "LOOP execution smoke"

main_dry_run_output="$(run_expect_success "MAIN dry-run should succeed" env PATH="/usr/bin:/bin" "$MAIN_SCRIPT" --target-dir "$TEST_TARGET_DIR" --max-iterations 2 --prompt "smoke prompt" --dry-run)"
assert_contains "$main_dry_run_output" "Max iterations: 2" "MAIN dry-run should print loop settings"
assert_contains "$main_dry_run_output" "Target directory: $TEST_TARGET_DIR" "MAIN dry-run should print the target directory"
pass "MAIN dry-run smoke"

cli_help_output="$(run_expect_success "CLI help should succeed" "$CLI_SCRIPT" --help)"
assert_contains "$cli_help_output" "EvoProgrammer once" "CLI help should mention the once subcommand"
assert_contains "$cli_help_output" "EvoProgrammer doctor" "CLI help should mention the doctor subcommand"
pass "CLI help smoke"

doctor_output="$(run_expect_success "DOCTOR should validate the environment" env PATH="$TEST_FAKE_BIN:$PATH" "$DOCTOR_SCRIPT" --target-dir "$TEST_TARGET_DIR")"
assert_contains "$doctor_output" "OK agent codex" "DOCTOR smoke should print the selected default agent"
assert_contains "$doctor_output" "OK command $TEST_FAKE_BIN/codex" "DOCTOR smoke should print the discovered codex path"
pass "DOCTOR smoke"

install_dir="$TEST_TMPDIR/install-bin"
install_output="$(run_expect_success "install.sh should create a symlinked CLI" "$INSTALL_SCRIPT" "$install_dir")"
assert_contains "$install_output" "$install_dir/EvoProgrammer" "Installer smoke should report the target path"
if [[ ! -L "$install_dir/EvoProgrammer" ]]; then
    fail "Installer smoke should create a symlink"
fi
installed_target="$(readlink "$install_dir/EvoProgrammer")"
assert_equals "$installed_target" "$CLI_SCRIPT" "Installer smoke should point the symlink to the CLI entrypoint"
pass "Installer smoke"
