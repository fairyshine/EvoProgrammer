#!/usr/bin/env bash

setup_agent_test_workspace

main_help_output="$(run_expect_success "MAIN help should succeed" "$MAIN_SCRIPT" --help)"
assert_contains "$main_help_output" "Usage: ./MAIN.sh [options] [prompt]" "MAIN help output should mention options usage"
pass "MAIN help"

bad_iterations_output="$(run_expect_failure "MAIN should reject invalid iteration counts" env PATH="$PATH" "$MAIN_SCRIPT" --max-iterations nope)"
assert_contains "$bad_iterations_output" "EVOPROGRAMMER_MAX_ITERATIONS must be a non-negative integer." "MAIN should validate max iterations"
pass "MAIN max-iterations validation"

bad_delay_output="$(run_expect_failure "MAIN should reject invalid delay values" env PATH="$PATH" "$MAIN_SCRIPT" --delay-seconds nope)"
assert_contains "$bad_delay_output" "EVOPROGRAMMER_DELAY_SECONDS must be a non-negative integer." "MAIN should validate delay seconds"
pass "MAIN delay validation"

FAKE_CODEX_LOG="$TEST_TMPDIR/main.log"
export FAKE_CODEX_LOG
run_expect_success "MAIN should loop the requested number of iterations" env PATH="$TEST_FAKE_BIN:$PATH" "$MAIN_SCRIPT" --target-dir "$TEST_TARGET_DIR" --max-iterations 2 --prompt "repeatable" >/dev/null
main_log="$(cat "$FAKE_CODEX_LOG")"
exec_count="$(grep -c '^arg=exec$' "$FAKE_CODEX_LOG")"
assert_equals "$exec_count" "2" "MAIN should invoke LOOP twice when max iterations is 2"
assert_contains "$main_log" "cwd=$TEST_TARGET_DIR" "MAIN should pass target directory through to LOOP"
assert_contains "$main_log" "arg=repeatable" "MAIN should pass the prompt through to LOOP"
pass "MAIN iteration wiring"

main_session_dir="$(find "$TEST_DEFAULT_ARTIFACTS_ROOT" -maxdepth 1 -type d -name 'session-*' | head -n 1)"
assert_directory_exists "$main_session_dir" "MAIN should create a session artifacts directory"
assert_file_exists "$main_session_dir/session.env" "MAIN session artifacts should include session metadata"
main_iteration_count="$(find "$main_session_dir/iterations" -maxdepth 1 -type d -name 'run-*' | wc -l | tr -d ' ')"
assert_equals "$main_iteration_count" "2" "MAIN should create one artifacts directory per iteration"
main_session_metadata="$(cat "$main_session_dir/session.env")"
assert_contains "$main_session_metadata" "STATE=completed" "MAIN session metadata should mark successful completion"
assert_contains "$main_session_metadata" "AGENT=codex" "MAIN session metadata should record the selected agent"
pass "MAIN artifacts"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/main-profiles.log"
export FAKE_CLAUDE_LOG
run_expect_success "MAIN should forward language, framework, and project-type profiles" env PATH="$TEST_FAKE_BIN:$PATH" "$MAIN_SCRIPT" --agent claude --target-dir "$TEST_TARGET_DIR" --max-iterations 1 --language rust --framework axum --project-type online-game --prompt "repeatable" >/dev/null
main_profiles_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$main_profiles_log" "Target language: rust" "MAIN should inject the selected language profile"
assert_contains "$main_profiles_log" "Target framework: axum" "MAIN should inject the selected framework profile"
assert_contains "$main_profiles_log" "Target project type: online-game" "MAIN should inject the selected project type"
assert_contains "$main_profiles_log" "[User Request]" "MAIN should preserve the prompt section after adaptation"
pass "MAIN prompt adaptation"

auto_main_dir="$TEST_TMPDIR/auto-detect-python"
mkdir -p "$auto_main_dir"
printf '[project]\nname = "lab"\nversion = "0.1.0"\n' >"$auto_main_dir/pyproject.toml"
printf 'fastapi==0.100.0\n' >"$auto_main_dir/requirements.txt"
FAKE_CLAUDE_LOG="$TEST_TMPDIR/main-auto-detect.log"
export FAKE_CLAUDE_LOG
main_auto_detect_output="$(run_expect_success "MAIN should auto-detect language and project type" env PATH="$TEST_FAKE_BIN:$PATH" "$MAIN_SCRIPT" --agent claude --target-dir "$auto_main_dir" --max-iterations 1 --prompt "build a reproducible experiment pipeline")"
main_auto_detect_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$main_auto_detect_output" "Language profile: python (auto-detected)" "MAIN should report an auto-detected language profile"
assert_contains "$main_auto_detect_output" "Framework profile: fastapi (auto-detected)" "MAIN should report an auto-detected framework profile"
assert_contains "$main_auto_detect_output" "Project type: scientific-experiment (auto-detected)" "MAIN should report an auto-detected project type"
assert_contains "$main_auto_detect_log" "Target language: python" "MAIN should auto-detect Python from the repository"
assert_profile_guidance_in_output "$main_auto_detect_log" "languages" "python" "MAIN should inject the Python profile guidance"
assert_contains "$main_auto_detect_log" "Target framework: fastapi" "MAIN should auto-detect FastAPI from the repository"
assert_profile_guidance_in_output "$main_auto_detect_log" "frameworks" "fastapi" "MAIN should inject the FastAPI profile guidance"
assert_contains "$main_auto_detect_log" "Target project type: scientific-experiment" "MAIN should auto-detect a scientific experiment from the prompt"
assert_profile_guidance_in_output "$main_auto_detect_log" "project-types" "scientific-experiment" "MAIN should inject the scientific-experiment project-type guidance"
pass "MAIN auto detection"

exclude_count="$(grep -c '^\.evoprogrammer/$' "$TEST_EXCLUDE_FILE")"
assert_equals "$exclude_count" "1" "MAIN should not append duplicate local artifact excludes"
pass "MAIN git exclude dedupe"

FAKE_CODEX_LOG="$TEST_TMPDIR/main-codex-args.log"
export FAKE_CODEX_LOG
run_expect_success "MAIN should forward extra codex exec arguments" env PATH="$TEST_FAKE_BIN:$PATH" "$MAIN_SCRIPT" --target-dir "$TEST_TARGET_DIR" --max-iterations 1 --codex-arg "--profile" --codex-arg "danger-full-access" --prompt "repeatable" >/dev/null
main_codex_args_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$main_codex_args_log" "arg=--profile" "MAIN should pass codex option names through LOOP"
assert_contains "$main_codex_args_log" "arg=danger-full-access" "MAIN should pass codex option values through LOOP"
assert_contains "$main_codex_args_log" "arg=repeatable" "MAIN should keep the prompt when forwarding codex arguments"
pass "MAIN codex-arg forwarding"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/main-agent-args-list.log"
export FAKE_CLAUDE_LOG
run_expect_success "MAIN should forward list-style agent args" env PATH="$TEST_FAKE_BIN:$PATH" "$MAIN_SCRIPT" --agent claude --target-dir "$TEST_TARGET_DIR" --max-iterations 1 --agent-args "[\"--model\",\"sonnet\"]" --prompt "repeatable" >/dev/null
main_agent_args_list_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$main_agent_args_list_log" "arg=--model" "MAIN should forward list-style agent arg names"
assert_contains "$main_agent_args_list_log" "arg=sonnet" "MAIN should forward list-style agent arg values"
assert_contains "$main_agent_args_list_log" "arg=repeatable" "MAIN should keep the prompt when forwarding list-style agent args"
pass "MAIN agent-args list"

FAKE_CODEX_LOG="$TEST_TMPDIR/main-dash.log"
export FAKE_CODEX_LOG
run_expect_success "MAIN should preserve prompts that begin with a dash" env PATH="$TEST_FAKE_BIN:$PATH" "$MAIN_SCRIPT" --target-dir "$TEST_TARGET_DIR" --max-iterations 1 -- "--leading-dash prompt" >/dev/null
main_dash_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$main_dash_log" "arg=--leading-dash prompt" "MAIN should pass leading-dash prompts through to LOOP"
pass "MAIN prompt after --"

FAKE_CODEX_LOG="$TEST_TMPDIR/main-prompt-file.log"
export FAKE_CODEX_LOG
run_expect_success "MAIN should load prompts from a file for each iteration" env PATH="$TEST_FAKE_BIN:$PATH" "$MAIN_SCRIPT" --target-dir "$TEST_TARGET_DIR" --max-iterations 2 --prompt-file "$TEST_PROMPT_FILE" >/dev/null
main_prompt_file_log="$(cat "$FAKE_CODEX_LOG")"
main_prompt_file_count="$(grep -c '^arg=ship from file$' "$FAKE_CODEX_LOG")"
assert_equals "$main_prompt_file_count" "2" "MAIN should re-read the prompt file for each iteration"
assert_contains "$main_prompt_file_log" "cwd=$TEST_TARGET_DIR" "MAIN prompt-file mode should still target the repository directory"
pass "MAIN prompt-file"

main_dry_run_output="$(run_expect_success "MAIN dry-run should print the next iteration command" env PATH="/usr/bin:/bin" "$MAIN_SCRIPT" --target-dir "$TEST_TARGET_DIR" --max-iterations 3 --prompt-file "$TEST_PROMPT_FILE" --dry-run)"
assert_contains "$main_dry_run_output" "Agent: codex" "MAIN dry-run should print the selected agent"
assert_contains "$main_dry_run_output" "Max iterations: 3" "MAIN dry-run should print loop settings"
assert_contains "$main_dry_run_output" "Artifacts root: $TEST_TARGET_DIR/.evoprogrammer/runs" "MAIN dry-run should print the default artifacts root"
assert_contains "$main_dry_run_output" "--prompt-file" "MAIN dry-run should preserve prompt-file mode"
assert_contains "$main_dry_run_output" "Target directory: $TEST_TARGET_DIR" "MAIN dry-run should print the target directory"
pass "MAIN dry-run"

FAKE_CODEX_LOG="$TEST_TMPDIR/main-fail.log"
export FAKE_CODEX_LOG
continue_output="$(run_expect_success "MAIN should continue on codex failure when requested" env PATH="$TEST_FAKE_BIN:$PATH" FAKE_CODEX_FAIL=1 "$MAIN_SCRIPT" --target-dir "$TEST_TARGET_DIR" --max-iterations 2 --continue-on-error --prompt "keep going")"
assert_contains "$continue_output" "Iteration 1 failed with exit code 23." "MAIN should report iteration failures"
fail_count="$(grep -c '^arg=exec$' "$FAKE_CODEX_LOG")"
assert_equals "$fail_count" "2" "MAIN should continue running after failures when configured"
pass "MAIN continue-on-error"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/main-claude.log"
export FAKE_CLAUDE_LOG
run_expect_success "MAIN should support Claude Code as an agent" env PATH="$TEST_FAKE_BIN:$PATH" "$MAIN_SCRIPT" --agent claude --target-dir "$TEST_TARGET_DIR" --max-iterations 1 --agent-arg "--model" --agent-arg "sonnet" --prompt "repeatable" >/dev/null
main_claude_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$main_claude_log" "arg=--print" "MAIN should invoke Claude in print mode"
assert_contains "$main_claude_log" "arg=--dangerously-skip-permissions" "MAIN should bypass Claude permissions by default"
assert_contains "$main_claude_log" "arg=sonnet" "MAIN should pass through Claude argument values"
assert_contains "$main_claude_log" "arg=repeatable" "MAIN should pass the prompt through to Claude"
pass "MAIN claude agent"
