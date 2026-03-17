#!/usr/bin/env zsh

setup_agent_test_workspace

loop_help_output="$(run_expect_success "LOOP help should succeed" "$LOOP_SCRIPT" --help)"
assert_contains "$loop_help_output" "Usage: ./LOOP.sh [options] [prompt]" "LOOP help output should mention options usage"
pass "LOOP help smoke"

loop_dry_run_output="$(run_expect_success "LOOP dry-run should succeed" env PATH="/usr/bin:/bin" "$LOOP_SCRIPT" --agent claude --target-dir "$TEST_TARGET_DIR" --prompt "smoke prompt" --dry-run)"
assert_contains "$loop_dry_run_output" "Agent: claude" "LOOP dry-run should print the selected agent"
assert_contains "$loop_dry_run_output" "Target directory: $TEST_TARGET_DIR" "LOOP dry-run should print the target directory"
pass "LOOP dry-run smoke"

main_dry_run_output="$(run_expect_success "MAIN dry-run should succeed" env PATH="/usr/bin:/bin" "$MAIN_SCRIPT" --target-dir "$TEST_TARGET_DIR" --max-iterations 2 --prompt "smoke prompt" --dry-run)"
assert_contains "$main_dry_run_output" "Max iterations: 2" "MAIN dry-run should print loop settings"
pass "MAIN dry-run smoke"

doctor_output="$(run_expect_success "DOCTOR should validate the environment" env PATH="$TEST_FAKE_BIN:$PATH" "$DOCTOR_SCRIPT" --target-dir "$TEST_TARGET_DIR")"
assert_contains "$doctor_output" "OK command $TEST_FAKE_BIN/codex" "DOCTOR smoke should print the discovered codex path"
pass "DOCTOR smoke"
