#!/usr/bin/env bash

setup_agent_test_workspace

cli_help_output="$(run_expect_success "CLI help should succeed" "$CLI_SCRIPT" --help)"
assert_contains "$cli_help_output" "Usage:" "CLI help should show usage"
assert_contains "$cli_help_output" "EvoProgrammer [global-options] clean [options]" "CLI help should mention the clean subcommand"
assert_contains "$cli_help_output" "EvoProgrammer [global-options] status [options]" "CLI help should mention the status subcommand"
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

cli_clean_output="$(run_expect_success "CLI clean should dispatch to CLEAN" sh "$CLI_SCRIPT" clean --target-dir "$TEST_TARGET_DIR" --dry-run)"
assert_contains "$cli_clean_output" "No artifacts to clean." "CLI clean should support sh invocation via bootstrap"
pass "CLI clean behavior"

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
