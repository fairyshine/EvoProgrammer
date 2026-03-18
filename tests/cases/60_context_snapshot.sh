#!/usr/bin/env zsh

setup_context_workspace

FAKE_CODEX_LOG="$TEST_TMPDIR/context-snapshot-codex.log"
export FAKE_CODEX_LOG
TEST_FAKE_BIN="$(setup_fake_codex)"

context_snapshot="$TEST_TMPDIR/project-context.env"
run_expect_success "INSPECT should write a reusable env snapshot" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format env --report-file "$context_snapshot" >/dev/null
assert_file_exists "$context_snapshot" "INSPECT should write the context snapshot file"
pass "INSPECT context snapshot report"

inspect_snapshot_prompt_output="$(run_expect_success "INSPECT should rebuild workflow guidance from a context snapshot" "$INSPECT_SCRIPT" --context-file "$context_snapshot" --prompt "optimize command startup" --format prompt)"
assert_contains "$inspect_snapshot_prompt_output" "Task kind: performance" "INSPECT prompt should rebuild the task kind from the current prompt"
assert_contains "$inspect_snapshot_prompt_output" "Measure or localize the hotspot first" "INSPECT prompt should rebuild performance workflow guidance"
assert_contains "$inspect_snapshot_prompt_output" "Package manager: pnpm" "INSPECT prompt should retain repo context from the snapshot"
pass "INSPECT context snapshot reuse"

inspect_snapshot_structured_prompt_output="$(run_expect_success "INSPECT should honor structured task-kind hints when reusing a context snapshot" "$INSPECT_SCRIPT" --context-file "$context_snapshot" --prompt $'[Recommended Workflow]\nTask kind: performance\n' --format prompt)"
assert_contains "$inspect_snapshot_structured_prompt_output" "Task kind: performance" "INSPECT prompt should honor structured task kinds from the current prompt"
assert_contains "$inspect_snapshot_structured_prompt_output" "Measure or localize the hotspot first" "INSPECT prompt should rebuild performance guidance from structured prompt facts"
pass "INSPECT structured snapshot prompt reuse"

verify_snapshot_output="$(run_expect_success "VERIFY should reuse a context snapshot without an explicit target dir" "$VERIFY_SCRIPT" --context-file "$context_snapshot" --list)"
assert_contains "$verify_snapshot_output" "Target directory: $TEST_CONTEXT_DIR" "VERIFY should adopt the target directory from the context snapshot"
assert_contains "$verify_snapshot_output" "lint: pnpm lint" "VERIFY should reuse the detected lint command from the snapshot"
assert_contains "$verify_snapshot_output" "build: pnpm build" "VERIFY should reuse the detected build command from the snapshot"
pass "VERIFY context snapshot reuse"

loop_snapshot_dry_run_output="$(run_expect_success "LOOP should show snapshot-derived profiles in dry-run mode" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --context-file "$context_snapshot" --prompt "ship it" --dry-run)"
assert_contains "$loop_snapshot_dry_run_output" "Language profile: typescript (from context file)" "LOOP dry-run should surface the snapshot language profile"
assert_contains "$loop_snapshot_dry_run_output" "Target directory: $TEST_CONTEXT_DIR" "LOOP dry-run should adopt the target directory from the context snapshot"
pass "LOOP context snapshot dry-run"

main_snapshot_dry_run_output="$(run_expect_success "MAIN should reuse a context snapshot in dry-run mode" env PATH="$TEST_FAKE_BIN:$PATH" "$MAIN_SCRIPT" --context-file "$context_snapshot" --max-iterations 1 --prompt "ship it" --dry-run)"
assert_contains "$main_snapshot_dry_run_output" "Language profile: typescript (from context file)" "MAIN dry-run should surface the snapshot language profile"
assert_contains "$main_snapshot_dry_run_output" "Target directory: $TEST_CONTEXT_DIR" "MAIN dry-run should adopt the target directory from the context snapshot"
pass "MAIN context snapshot dry-run"

run_expect_success "LOOP should execute in the snapshot target directory" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --context-file "$context_snapshot" --prompt "ship it" >/dev/null
loop_snapshot_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_snapshot_log" "cwd=$TEST_CONTEXT_DIR" "LOOP should execute the agent in the snapshot target directory"
pass "LOOP context snapshot execution"

verify_snapshot_mismatch_output="$(run_expect_failure "VERIFY should reject mismatched target directories for a context snapshot" "$VERIFY_SCRIPT" --context-file "$context_snapshot" --target-dir "$TEST_TMPDIR" --list)"
assert_contains "$verify_snapshot_mismatch_output" "Context file target directory does not match the requested target directory." "VERIFY should reject mismatched snapshot target directories"
pass "Context snapshot target-dir validation"
