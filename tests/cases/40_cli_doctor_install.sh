#!/usr/bin/env bash

setup_agent_test_workspace

cli_help_output="$(run_expect_success "CLI help should succeed" "$CLI_SCRIPT" --help)"
assert_contains "$cli_help_output" "Usage:" "CLI help should show usage"
pass "CLI help"

FAKE_CODEX_LOG="$TEST_TMPDIR/cli-once.log"
export FAKE_CODEX_LOG
(
    cd "$TEST_TARGET_DIR"
    run_expect_success "CLI once should dispatch to LOOP" env PATH="$TEST_FAKE_BIN:$PATH" "$CLI_SCRIPT" once --prompt "cli once" >/dev/null
)
cli_once_log="$(cat "$FAKE_CODEX_LOG")"
cli_once_exec_count="$(grep -c '^arg=exec$' "$FAKE_CODEX_LOG")"
assert_equals "$cli_once_exec_count" "1" "CLI once should run only one iteration"
pass "CLI once behavior"

doctor_output="$(run_expect_success "DOCTOR should validate the environment" env PATH="$TEST_FAKE_BIN:$PATH" "$DOCTOR_SCRIPT" --target-dir "$TEST_TARGET_DIR")"
assert_contains "$doctor_output" "OK command $TEST_FAKE_BIN/codex" "DOCTOR should print the discovered codex path"
pass "DOCTOR success"

cli_doctor_output="$(run_expect_success "CLI doctor should dispatch to DOCTOR" env PATH="$TEST_FAKE_BIN:$PATH" "$CLI_SCRIPT" doctor --target-dir "$TEST_TARGET_DIR")"
assert_contains "$cli_doctor_output" "OK command $TEST_FAKE_BIN/codex" "CLI doctor should run the doctor command"
pass "CLI doctor behavior"

install_dir="$TEST_TMPDIR/install-bin"
install_output="$(run_expect_success "install.sh should create a symlinked CLI" "$INSTALL_SCRIPT" "$install_dir")"
assert_contains "$install_output" "$install_dir/EvoProgrammer" "Installer should report the target path"
if [[ ! -L "$install_dir/EvoProgrammer" ]]; then
    fail "Installer should create a symlink"
fi
installed_target="$(readlink "$install_dir/EvoProgrammer")"
assert_equals "$installed_target" "$CLI_SCRIPT" "Installer should point the symlink to the CLI entrypoint"
pass "Installer"
