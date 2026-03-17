#!/usr/bin/env bash

setup_agent_test_workspace

help_output="$(run_expect_success "LOOP help should succeed" "$LOOP_SCRIPT" --help)"
assert_contains "$help_output" "Usage: ./LOOP.sh [options] [prompt]" "LOOP help output should mention options usage"
pass "LOOP help"

missing_codex_output="$(run_expect_failure "LOOP should fail without codex" env HOME="$HOME" PATH="/usr/bin:/bin" "$LOOP_SCRIPT" --prompt "test")"
assert_contains "$missing_codex_output" "The 'codex' CLI is required" "LOOP should report missing codex"
pass "LOOP missing codex"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop.log"
export FAKE_CODEX_LOG
run_expect_success "LOOP should invoke codex with prompt and target directory" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --target-dir "$TEST_TARGET_DIR" --prompt "ship it" >/dev/null
loop_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_log" "cwd=$TEST_TARGET_DIR" "LOOP should run codex in the requested target directory"
assert_contains "$loop_log" "arg=exec" "LOOP should call codex exec"
assert_contains "$loop_log" "arg=ship it" "LOOP should forward the prompt"
pass "LOOP execution wiring"

setup_context_workspace
FAKE_CLAUDE_LOG="$TEST_TMPDIR/context.log"
export FAKE_CLAUDE_LOG
context_loop_output="$(run_expect_success "LOOP should analyze repository context and surface it to the agent" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$TEST_CONTEXT_DIR" --prompt "add a billing dashboard feature")"
context_loop_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$context_loop_output" "Package manager: pnpm" "LOOP should print the detected package manager"
assert_contains "$context_loop_output" "Task kind: feature" "LOOP should print the inferred task kind"
assert_contains "$context_loop_log" "[Repository Context]" "LOOP should prepend repository context guidance"
assert_contains "$context_loop_log" "[Recommended Workflow]" "LOOP should inject a task-specific workflow"
pass "LOOP repository context analysis"

empty_prompt_file="$TEST_TMPDIR/empty-prompt.txt"
: >"$empty_prompt_file"
blank_prompt_output="$(run_expect_failure "LOOP should reject blank prompts" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --target-dir "$TEST_TARGET_DIR" --prompt-file "$empty_prompt_file")"
assert_contains "$blank_prompt_output" "Prompt must not be empty." "LOOP should reject empty prompt inputs"
pass "LOOP blank prompt validation"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop-dash.log"
export FAKE_CODEX_LOG
run_expect_success "LOOP should accept a prompt after --" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --target-dir "$TEST_TARGET_DIR" -- "--leading-dash prompt" >/dev/null
loop_dash_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_dash_log" "arg=--leading-dash prompt" "LOOP should preserve prompts that begin with a dash"
pass "LOOP prompt after --"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop-default-target.log"
export FAKE_CODEX_LOG
(
    cd "$TEST_TARGET_DIR"
    run_expect_success "LOOP should default to current working directory" env -u EVOPROGRAMMER_TARGET_DIR PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --prompt "default target" >/dev/null
)
loop_default_target_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_default_target_log" "cwd=$TEST_TARGET_DIR" "LOOP should use the current working directory by default"
pass "LOOP default target directory"
