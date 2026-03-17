#!/usr/bin/env bash

setup_context_workspace

inspect_output="$(run_expect_success "INSPECT should summarize detected project context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test")"
assert_contains "$inspect_output" "Language profile: typescript (auto-detected)" "INSPECT should print the detected language profile"
assert_contains "$inspect_output" "Framework profile: nextjs (auto-detected)" "INSPECT should print the detected framework profile"
assert_contains "$inspect_output" "Suggested commands:" "INSPECT should print the suggested command section"
assert_contains "$inspect_output" "Lint: pnpm lint [package.json script]" "INSPECT should include command sources"
assert_contains "$inspect_output" "Operational surfaces:" "INSPECT should print operational surfaces"
assert_contains "$inspect_output" ".github/workflows" "INSPECT should report CI workflow surfaces"
pass "INSPECT summary"

inspect_prompt_output="$(run_expect_success "INSPECT should render prompt context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format prompt)"
assert_contains "$inspect_prompt_output" "[Repository Context]" "INSPECT prompt mode should render repository context"
assert_contains "$inspect_prompt_output" "[Recommended Workflow]" "INSPECT prompt mode should render workflow guidance"
assert_contains "$inspect_prompt_output" "Operational surfaces:" "INSPECT prompt mode should render operational surfaces"
pass "INSPECT prompt"

inspect_json_output="$(run_expect_success "INSPECT should render machine-readable json context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format json)"
inspect_json_summary="$(INSPECT_JSON="$inspect_json_output" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["INSPECT_JSON"])
print(data["profiles"]["language"]["name"])
print(data["package_manager"])
print(data["commands"]["lint"]["command"])
print(f"automation_ok={any('.github/workflows' in item for item in data['automation'])}")
print(f"backend_ok={data['facts_cache']['backend'] in {'associative-array', 'line-table'}}")
print(f"lookups_ok={data['facts_cache']['lookups'] > 0}")
print(f"entries_ok={data['facts_cache']['relative_exists_entries'] > 0}")
print(f"timings_ok={all(isinstance(data['timings'][key], int) and data['timings'][key] >= 0 for key in data['timings'])}")
print(f"profile_detection_ok={any(item['name'] == 'typescript' for item in data['profile_detection']['languages'])}")
PY
)"
assert_contains "$inspect_json_summary" "typescript" "INSPECT json should include the detected language profile"
assert_contains "$inspect_json_summary" "pnpm" "INSPECT json should include the package manager"
assert_contains "$inspect_json_summary" "pnpm lint" "INSPECT json should include the lint command"
assert_contains "$inspect_json_summary" "automation_ok=True" "INSPECT json should include automation entries"
assert_contains "$inspect_json_summary" "backend_ok=True" "INSPECT json should include the facts-cache backend"
assert_contains "$inspect_json_summary" "lookups_ok=True" "INSPECT json should include facts-cache lookup diagnostics"
assert_contains "$inspect_json_summary" "entries_ok=True" "INSPECT json should include facts-cache entry counts"
assert_contains "$inspect_json_summary" "timings_ok=True" "INSPECT json should include phase timings"
assert_contains "$inspect_json_summary" "profile_detection_ok=True" "INSPECT json should include profile-detection candidates"
pass "INSPECT json"

inspect_env_summary="$(
    ROOT_DIR="$ROOT_DIR" INSPECT_SCRIPT="$INSPECT_SCRIPT" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" bash <<'EOF'
set -euo pipefail
source /dev/stdin <<<"$("$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format env)"

printf '%s\n' "$EVOP_INSPECT_LANGUAGE_PROFILE"
printf '%s\n' "$EVOP_INSPECT_PACKAGE_MANAGER"
printf '%s\n' "$EVOP_INSPECT_LINT_COMMAND"
printf 'automation_ok=%s\n' "$([[ "$EVOP_INSPECT_AUTOMATION" == *".github/workflows"* ]] && printf true || printf false)"
printf 'workflow_ok=%s\n' "$([[ "$EVOP_INSPECT_TASK_WORKFLOW" == *"Reproduce or localize the failure path first"* ]] && printf true || printf false)"
printf 'timings_ok=%s\n' "$([[ "$EVOP_INSPECT_TIMING_RESOLVE_PROFILES_MS" =~ ^[0-9]+$ ]] && printf true || printf false)"
EOF
)"
assert_contains "$inspect_env_summary" "typescript" "INSPECT env should export the detected language profile"
assert_contains "$inspect_env_summary" "pnpm" "INSPECT env should export the package manager"
assert_contains "$inspect_env_summary" "pnpm lint" "INSPECT env should export command slots"
assert_contains "$inspect_env_summary" "automation_ok=true" "INSPECT env should export automation surfaces"
assert_contains "$inspect_env_summary" "workflow_ok=true" "INSPECT env should export workflow guidance"
assert_contains "$inspect_env_summary" "timings_ok=true" "INSPECT env should export timing diagnostics"
pass "INSPECT env"

inspect_diagnostics_output="$(run_expect_success "INSPECT should render diagnostics context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format diagnostics)"
assert_contains "$inspect_diagnostics_output" "Inspection diagnostics:" "INSPECT diagnostics should print the diagnostics heading"
assert_contains "$inspect_diagnostics_output" "Facts cache backend:" "INSPECT diagnostics should print the cache backend"
assert_contains "$inspect_diagnostics_output" "Facts cache lookups:" "INSPECT diagnostics should print cache lookup counts"
assert_contains "$inspect_diagnostics_output" "Facts cache hit rate:" "INSPECT diagnostics should print cache hit rates"
assert_contains "$inspect_diagnostics_output" "Timing resolve_profiles:" "INSPECT diagnostics should print timing diagnostics"
assert_contains "$inspect_diagnostics_output" "Language candidates:" "INSPECT diagnostics should include profile detection candidates"
pass "INSPECT diagnostics"

inspect_timings_output="$(run_expect_success "INSPECT should render timings context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format timings)"
assert_contains "$inspect_timings_output" "Inspection timings (ms):" "INSPECT timings should print the timings heading"
assert_contains "$inspect_timings_output" "resolve_profiles:" "INSPECT timings should print the overall resolve timing"
assert_contains "$inspect_timings_output" "finalize_analysis:" "INSPECT timings should print the overall finalize timing"
pass "INSPECT timings"

inspect_profiles_output="$(run_expect_success "INSPECT should render profile detection candidates" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format profiles)"
assert_contains "$inspect_profiles_output" "Profile detection report:" "INSPECT profiles mode should print the profile detection heading"
assert_contains "$inspect_profiles_output" "Language candidates:" "INSPECT profiles mode should print language candidates"
assert_contains "$inspect_profiles_output" "typescript (score: 100)" "INSPECT profiles mode should include the detected TypeScript candidate"
assert_contains "$inspect_profiles_output" "Framework candidates:" "INSPECT profiles mode should print framework candidates"
assert_contains "$inspect_profiles_output" "nextjs (score: 95)" "INSPECT profiles mode should include the detected Next.js candidate"
pass "INSPECT profiles"

setup_verify_workspace
verify_output="$(run_expect_success "VERIFY should run the detected verification chain" "$VERIFY_SCRIPT" --target-dir "$TEST_VERIFY_DIR")"
verify_log="$(cat "$TEST_VERIFY_LOG")"
assert_contains "$verify_output" "Running lint: make lint" "VERIFY should run lint first"
assert_contains "$verify_output" "Running build: make build" "VERIFY should include build in the chain"
assert_contains "$verify_log" $'lint\ntypecheck\ntest\nbuild' "VERIFY should run the steps in the expected order"
pass "VERIFY execution"

setup_verify_shell_workspace
verify_shell_output="$(run_expect_success "VERIFY should prefer zsh for command execution" env PATH="$TEST_VERIFY_SHELL_BIN:$PATH" "$VERIFY_SCRIPT" --target-dir "$TEST_VERIFY_SHELL_DIR" --steps lint)"
verify_shell_log="$(cat "$TEST_VERIFY_SHELL_LOG")"
assert_contains "$verify_shell_output" "Running lint: make lint" "VERIFY should still run the detected lint command"
assert_contains "$verify_shell_log" "zsh" "VERIFY should execute commands through zsh when available"
pass "VERIFY shell preference"

verify_dry_run_output="$(run_expect_success "VERIFY dry-run should print commands without executing them" "$VERIFY_SCRIPT" --target-dir "$TEST_VERIFY_DIR" --steps test,build --dry-run)"
assert_contains "$verify_dry_run_output" "Running test: make test" "VERIFY dry-run should print the selected test command"
assert_contains "$verify_dry_run_output" "Running build: make build" "VERIFY dry-run should print the selected build command"
pass "VERIFY dry-run"

cli_inspect_output="$(run_expect_success "CLI inspect should dispatch to INSPECT" "$CLI_SCRIPT" inspect --target-dir "$TEST_CONTEXT_DIR")"
assert_contains "$cli_inspect_output" "Suggested commands:" "CLI inspect should dispatch to INSPECT"
pass "CLI inspect behavior"
