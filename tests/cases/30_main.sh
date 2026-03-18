#!/usr/bin/env zsh

setup_agent_test_workspace

main_help_output="$(run_expect_success "MAIN help should succeed" "$MAIN_SCRIPT" --help)"
assert_contains "$main_help_output" "Usage: ./MAIN.sh [options] [prompt]" "MAIN help output should mention options usage"
assert_contains "$main_help_output" "--auto-commit" "MAIN help output should mention auto-commit support"
pass "MAIN help"

bad_iterations_output="$(run_expect_failure "MAIN should reject invalid iteration counts" env PATH="$PATH" "$MAIN_SCRIPT" --max-iterations nope)"
assert_contains "$bad_iterations_output" "EVOPROGRAMMER_MAX_ITERATIONS must be a non-negative integer." "MAIN should validate max iterations"
pass "MAIN max-iterations validation"

FAKE_CODEX_LOG="$TEST_TMPDIR/main.log"
export FAKE_CODEX_LOG
run_expect_success "MAIN should loop the requested number of iterations" env PATH="$TEST_FAKE_BIN:$PATH" "$MAIN_SCRIPT" --target-dir "$TEST_TARGET_DIR" --max-iterations 2 --prompt "repeatable" >/dev/null
exec_count="$(grep -c '^arg=exec$' "$FAKE_CODEX_LOG")"
assert_equals "$exec_count" "2" "MAIN should invoke LOOP twice when max iterations is 2"
pass "MAIN iteration wiring"

main_dry_run_output="$(run_expect_success "MAIN dry-run should surface auto-commit wiring" "$MAIN_SCRIPT" --target-dir "$TEST_TARGET_DIR" --max-iterations 1 --auto-commit --auto-commit-message "feat: test commit" --prompt "repeatable" --dry-run)"
assert_contains "$main_dry_run_output" "Auto commit: 1" "MAIN dry-run should show auto-commit state"
assert_contains "$main_dry_run_output" "--auto-commit" "MAIN dry-run should pass auto-commit through to LOOP"
assert_contains "$main_dry_run_output" "--auto-commit-message" "MAIN dry-run should pass auto-commit messages through to LOOP"
pass "MAIN auto-commit dry-run"

main_session_dir="$(find "$TEST_DEFAULT_ARTIFACTS_ROOT" -maxdepth 1 -type d -name 'session-*' | head -n 1)"
assert_directory_exists "$main_session_dir" "MAIN should create a session artifacts directory"
assert_file_exists "$main_session_dir/session.env" "MAIN session artifacts should include session metadata"
pass "MAIN artifacts"
