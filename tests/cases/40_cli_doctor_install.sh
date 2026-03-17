#!/usr/bin/env bash

setup_agent_test_workspace

cli_help_output="$(run_expect_success "CLI help should succeed" "$CLI_SCRIPT" --help)"
assert_contains "$cli_help_output" "Usage:" "CLI help should show usage"
assert_contains "$cli_help_output" "EvoProgrammer [global-options] clean [options]" "CLI help should mention the clean subcommand"
assert_contains "$cli_help_output" "EvoProgrammer [global-options] status [options]" "CLI help should mention the status subcommand"
assert_contains "$cli_help_output" "EvoProgrammer [global-options] profiles [options]" "CLI help should mention the profiles subcommand"
pass "CLI help"

FAKE_CODEX_LOG="$TEST_TMPDIR/cli-once.log"
export FAKE_CODEX_LOG
(
    cd "$TEST_TARGET_DIR" || exit 1
    run_expect_success "CLI once should dispatch to LOOP" env PATH="$TEST_FAKE_BIN:$PATH" "$CLI_SCRIPT" once --prompt "cli once" >/dev/null
)
cli_once_exec_count="$(grep -c '^arg=exec$' "$FAKE_CODEX_LOG")"
assert_equals "$cli_once_exec_count" "1" "CLI once should run only one iteration"
pass "CLI once behavior"

doctor_output="$(run_expect_success "DOCTOR should validate the environment" env PATH="$TEST_FAKE_BIN:$PATH" "$DOCTOR_SCRIPT" --target-dir "$TEST_TARGET_DIR")"
assert_contains "$doctor_output" "OK command $TEST_FAKE_BIN/codex" "DOCTOR should print the discovered codex path"
pass "DOCTOR success"

cli_doctor_output="$(run_expect_success "CLI doctor should dispatch to DOCTOR" env PATH="$TEST_FAKE_BIN:$PATH" "$CLI_SCRIPT" doctor --target-dir "$TEST_TARGET_DIR")"
assert_contains "$cli_doctor_output" "OK command $TEST_FAKE_BIN/codex" "CLI doctor should run the doctor command"
pass "CLI doctor behavior"

FAKE_CODEX_LOG="$TEST_TMPDIR/cli-status.log"
export FAKE_CODEX_LOG
run_expect_success "MAIN should create session history for CLI status" env PATH="$TEST_FAKE_BIN:$PATH" "$MAIN_SCRIPT" --target-dir "$TEST_TARGET_DIR" --max-iterations 1 --prompt "seed status history" >/dev/null
cli_status_output="$(run_expect_success "CLI status should dispatch to STATUS" sh "$CLI_SCRIPT" status --target-dir "$TEST_TARGET_DIR" --last 1)"
assert_contains "$cli_status_output" "session-" "CLI status should show recorded session history"
assert_contains "$cli_status_output" "1 of" "CLI status should support sh invocation via bootstrap"
pass "CLI status behavior"

status_filtered_output="$(run_expect_success "STATUS should filter session entries" "$STATUS_SCRIPT" --target-dir "$TEST_TARGET_DIR" --kind session --status completed --last 1)"
assert_contains "$status_filtered_output" "session-" "STATUS should keep matching session entries"
assert_contains "$status_filtered_output" "final_status=0" "STATUS should include final status for sessions"
assert_not_contains "$status_filtered_output" "run-" "STATUS session filtering should exclude run entries"
pass "STATUS filtering"

status_json_output="$(run_expect_success "STATUS should render json output" "$STATUS_SCRIPT" --target-dir "$TEST_TARGET_DIR" --kind run --format json)"
status_json_summary="$(STATUS_JSON="$status_json_output" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["STATUS_JSON"])
print(f"kind={data['filters']['kind']}")
print(f"matched_ok={data['matched_count'] >= 1}")
print(f"kinds_ok={all(item['kind'] == 'run' for item in data['entries'])}")
print(f"status_ok={any(item['status'] == '0' for item in data['entries'])}")
PY
)"
assert_contains "$status_json_summary" "kind=run" "STATUS json should report applied filters"
assert_contains "$status_json_summary" "matched_ok=True" "STATUS json should report matched entries"
assert_contains "$status_json_summary" "kinds_ok=True" "STATUS json should keep only the selected kind"
assert_contains "$status_json_summary" "status_ok=True" "STATUS json should include run status values"
pass "STATUS json"

status_env_summary="$(
    STATUS_SCRIPT="$STATUS_SCRIPT" TEST_TARGET_DIR="$TEST_TARGET_DIR" bash <<'EOF'
set -euo pipefail
source /dev/stdin <<<"$("$STATUS_SCRIPT" --target-dir "$TEST_TARGET_DIR" --kind session --status completed --last 1 --format env)"

printf '%s\n' "$EVOP_STATUS_FILTER_KIND"
printf 'count_ok=%s\n' "$([[ "$EVOP_STATUS_MATCHED_COUNT" =~ ^[1-9][0-9]*$ ]] && printf true || printf false)"
printf 'name_ok=%s\n' "$([[ "$EVOP_STATUS_ENTRY_1_NAME" == session-* ]] && printf true || printf false)"
printf 'status_ok=%s\n' "$([[ "$EVOP_STATUS_ENTRY_1_STATUS" == "completed" ]] && printf true || printf false)"
EOF
)"
assert_contains "$status_env_summary" "session" "STATUS env should export filters"
assert_contains "$status_env_summary" "count_ok=true" "STATUS env should export matched counts"
assert_contains "$status_env_summary" "name_ok=true" "STATUS env should export entry names"
assert_contains "$status_env_summary" "status_ok=true" "STATUS env should export entry status values"
pass "STATUS env"

status_report_json="$TEST_TMPDIR/status-report.json"
run_expect_success "STATUS should write a json report file" "$STATUS_SCRIPT" --target-dir "$TEST_TARGET_DIR" --kind run --format summary --report-file "$status_report_json" --report-format json >/dev/null
status_report_json_summary="$(STATUS_REPORT_JSON="$(cat "$status_report_json")" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["STATUS_REPORT_JSON"])
print(f"shown_ok={data['shown_count'] >= 1}")
print(f"entries_ok={all(item['kind'] == 'run' for item in data['entries'])}")
PY
)"
assert_contains "$status_report_json_summary" "shown_ok=True" "STATUS json report should include shown counts"
assert_contains "$status_report_json_summary" "entries_ok=True" "STATUS json report should preserve filters"
pass "STATUS json report"

cli_clean_output="$(run_expect_success "CLI clean should dispatch to CLEAN" sh "$CLI_SCRIPT" clean --target-dir "$TEST_TARGET_DIR" --dry-run)"
assert_contains "$cli_clean_output" "No artifacts to clean." "CLI clean should support sh invocation via bootstrap"
pass "CLI clean behavior"

cli_profiles_output="$(run_expect_success "CLI profiles should dispatch to PROFILES" sh "$CLI_SCRIPT" profiles --category project-types)"
assert_contains "$cli_profiles_output" "Supported profiles (Project types):" "CLI profiles should dispatch to the profile catalog command"
assert_contains "$cli_profiles_output" "cli-tool:" "CLI profiles should render profile entries"
pass "CLI profiles behavior"

install_dir="$TEST_TMPDIR/install-bin"
install_home="$TEST_TMPDIR/install-home"
mkdir -p "$install_home"
: >"$install_home/.zshrc"
: >"$install_home/.bashrc"
install_output="$(run_expect_success "install.sh should create a symlinked CLI" env HOME="$install_home" "$INSTALL_SCRIPT" "$install_dir")"
assert_contains "$install_output" "$install_dir/EvoProgrammer" "Installer should report the target path"
assert_contains "$install_output" "source $install_home/.zshrc" "Installer should prefer zsh instructions when zsh rc is present"
if [[ ! -L "$install_dir/EvoProgrammer" ]]; then
    fail "Installer should create a symlink"
fi
installed_target="$(readlink "$install_dir/EvoProgrammer")"
assert_equals "$installed_target" "$CLI_SCRIPT" "Installer should point the symlink to the CLI entrypoint"
pass "Installer"
