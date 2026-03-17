#!/usr/bin/env bash

setup_context_workspace

inspect_output="$(run_expect_success "INSPECT should summarize detected project context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test")"
assert_contains "$inspect_output" "Language profile: typescript (auto-detected)" "INSPECT should print the detected language profile"
assert_contains "$inspect_output" "Framework profile: nextjs (auto-detected)" "INSPECT should print the detected framework profile"
assert_contains "$inspect_output" "Suggested commands:" "INSPECT should print the suggested command section"
assert_contains "$inspect_output" "Lint: pnpm lint [package.json script]" "INSPECT should include command sources"
pass "INSPECT summary"

inspect_prompt_output="$(run_expect_success "INSPECT should render prompt context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format prompt)"
assert_contains "$inspect_prompt_output" "[Repository Context]" "INSPECT prompt mode should render repository context"
assert_contains "$inspect_prompt_output" "[Recommended Workflow]" "INSPECT prompt mode should render workflow guidance"
pass "INSPECT prompt"

setup_verify_workspace
verify_output="$(run_expect_success "VERIFY should run the detected verification chain" "$VERIFY_SCRIPT" --target-dir "$TEST_VERIFY_DIR")"
verify_log="$(cat "$TEST_VERIFY_LOG")"
assert_contains "$verify_output" "Running lint: make lint" "VERIFY should run lint first"
assert_contains "$verify_output" "Running build: make build" "VERIFY should include build in the chain"
assert_contains "$verify_log" $'lint\ntypecheck\ntest\nbuild' "VERIFY should run the steps in the expected order"
pass "VERIFY execution"

verify_dry_run_output="$(run_expect_success "VERIFY dry-run should print commands without executing them" "$VERIFY_SCRIPT" --target-dir "$TEST_VERIFY_DIR" --steps test,build --dry-run)"
assert_contains "$verify_dry_run_output" "Running test: make test" "VERIFY dry-run should print the selected test command"
assert_contains "$verify_dry_run_output" "Running build: make build" "VERIFY dry-run should print the selected build command"
pass "VERIFY dry-run"

cli_inspect_output="$(run_expect_success "CLI inspect should dispatch to INSPECT" "$CLI_SCRIPT" inspect --target-dir "$TEST_CONTEXT_DIR")"
assert_contains "$cli_inspect_output" "Suggested commands:" "CLI inspect should dispatch to INSPECT"
pass "CLI inspect behavior"
