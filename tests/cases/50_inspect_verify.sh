#!/usr/bin/env zsh

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

inspect_commands_output="$(run_expect_success "INSPECT should render a focused command report" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --format commands)"
assert_contains "$inspect_commands_output" "Suggested commands:" "INSPECT commands mode should print the command heading"
assert_contains "$inspect_commands_output" "Lint: pnpm lint [package.json script]" "INSPECT commands mode should include command sources"
assert_not_contains "$inspect_commands_output" "Architecture hints:" "INSPECT commands mode should stay focused on commands"
pass "INSPECT commands"

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
print(f"text_entries_ok={data['facts_cache']['file_text_entries'] > 0}")
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
assert_contains "$inspect_json_summary" "text_entries_ok=True" "INSPECT json should include file-text cache entry counts"
assert_contains "$inspect_json_summary" "timings_ok=True" "INSPECT json should include phase timings"
assert_contains "$inspect_json_summary" "profile_detection_ok=True" "INSPECT json should include profile-detection candidates"
pass "INSPECT json"

inspect_env_summary="$(
    ROOT_DIR="$ROOT_DIR" INSPECT_SCRIPT="$INSPECT_SCRIPT" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" zsh <<'EOF'
set -euo pipefail
source /dev/stdin <<<"$("$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format env)"

printf '%s\n' "$EVOP_INSPECT_LANGUAGE_PROFILE"
printf '%s\n' "$EVOP_INSPECT_PACKAGE_MANAGER"
printf '%s\n' "$EVOP_INSPECT_LINT_COMMAND"
printf 'automation_ok=%s\n' "$([[ "$EVOP_INSPECT_AUTOMATION" == *".github/workflows"* ]] && printf true || printf false)"
printf 'workflow_ok=%s\n' "$([[ "$EVOP_INSPECT_TASK_WORKFLOW" == *"Reproduce or localize the failure path first"* ]] && printf true || printf false)"
printf 'text_cache_ok=%s\n' "$([[ "$EVOP_INSPECT_FACTS_CACHE_FILE_TEXT_ENTRIES" =~ ^[1-9][0-9]*$ ]] && printf true || printf false)"
printf 'timings_ok=%s\n' "$([[ "$EVOP_INSPECT_TIMING_RESOLVE_PROFILES_MS" =~ ^[0-9]+$ ]] && printf true || printf false)"
EOF
)"
assert_contains "$inspect_env_summary" "typescript" "INSPECT env should export the detected language profile"
assert_contains "$inspect_env_summary" "pnpm" "INSPECT env should export the package manager"
assert_contains "$inspect_env_summary" "pnpm lint" "INSPECT env should export command slots"
assert_contains "$inspect_env_summary" "automation_ok=true" "INSPECT env should export automation surfaces"
assert_contains "$inspect_env_summary" "workflow_ok=true" "INSPECT env should export workflow guidance"
assert_contains "$inspect_env_summary" "text_cache_ok=true" "INSPECT env should export file-text cache entry counts"
assert_contains "$inspect_env_summary" "timings_ok=true" "INSPECT env should export timing diagnostics"
pass "INSPECT env"

inspect_diagnostics_output="$(run_expect_success "INSPECT should render diagnostics context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format diagnostics)"
assert_contains "$inspect_diagnostics_output" "Inspection diagnostics:" "INSPECT diagnostics should print the diagnostics heading"
assert_contains "$inspect_diagnostics_output" "Facts cache backend:" "INSPECT diagnostics should print the cache backend"
assert_contains "$inspect_diagnostics_output" "Facts cache lookups:" "INSPECT diagnostics should print cache lookup counts"
assert_contains "$inspect_diagnostics_output" "Facts cache hit rate:" "INSPECT diagnostics should print cache hit rates"
assert_contains "$inspect_diagnostics_output" "File-text cache entries:" "INSPECT diagnostics should print file-text cache entries"
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

inspect_report_json="$TEST_TMPDIR/inspect-report.json"
run_expect_success "INSPECT should write a json report file" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format summary --report-file "$inspect_report_json" --report-format json >/dev/null
inspect_report_json_summary="$(INSPECT_REPORT_JSON="$(cat "$inspect_report_json")" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["INSPECT_REPORT_JSON"])
print(data["profiles"]["framework"]["name"])
print(data["commands"]["build"]["command"])
print(f"automation_ok={any('docs/' in item or 'docs' in item for item in data['automation'])}")
PY
)"
assert_contains "$inspect_report_json_summary" "nextjs" "INSPECT json report files should include detected profiles"
assert_contains "$inspect_report_json_summary" "pnpm build" "INSPECT json report files should include command slots"
assert_contains "$inspect_report_json_summary" "automation_ok=True" "INSPECT json report files should include automation hints"
pass "INSPECT json report file"

inspect_report_env="$TEST_TMPDIR/inspect-report.env"
run_expect_success "INSPECT should write an env report file" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format summary --report-file "$inspect_report_env" --report-format env >/dev/null
inspect_report_env_summary="$(
    INSPECT_REPORT_ENV="$inspect_report_env" zsh <<'EOF'
set -euo pipefail
source "$INSPECT_REPORT_ENV"
printf '%s\n' "$EVOP_INSPECT_FRAMEWORK_PROFILE"
printf '%s\n' "$EVOP_INSPECT_BUILD_COMMAND"
printf 'diagnostics_ok=%s\n' "$([[ "$EVOP_INSPECT_FACTS_CACHE_LOOKUPS" =~ ^[1-9][0-9]*$ ]] && printf true || printf false)"
EOF
)"
assert_contains "$inspect_report_env_summary" "nextjs" "INSPECT env report files should export detected profiles"
assert_contains "$inspect_report_env_summary" "pnpm build" "INSPECT env report files should export command slots"
assert_contains "$inspect_report_env_summary" "diagnostics_ok=true" "INSPECT env report files should export diagnostics"
pass "INSPECT env report file"

setup_verify_workspace
verify_output="$(run_expect_success "VERIFY should run the detected verification chain" "$VERIFY_SCRIPT" --target-dir "$TEST_VERIFY_DIR")"
verify_log="$(cat "$TEST_VERIFY_LOG")"
assert_contains "$verify_output" "Running lint: make lint" "VERIFY should run lint first"
assert_contains "$verify_output" "Running build: make build" "VERIFY should include build in the chain"
assert_contains "$verify_log" $'lint\ntypecheck\ntest\nbuild' "VERIFY should run the steps in the expected order"
pass "VERIFY execution"

verify_list_json_output="$(run_expect_success "VERIFY should render the selected verification plan as json" "$VERIFY_SCRIPT" --target-dir "$TEST_VERIFY_DIR" --steps lint,test --list --list-format json)"
verify_list_json_summary="$(VERIFY_LIST_JSON="$verify_list_json_output" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["VERIFY_LIST_JSON"])
print(data["target_dir"])
print(data["steps"]["lint"]["command"])
print(data["steps"]["test"]["source"])
print(f"lint_ok={data['steps']['lint']['runnable']}")
PY
)"
assert_contains "$verify_list_json_summary" "$TEST_VERIFY_DIR" "VERIFY list json should include the target directory"
assert_contains "$verify_list_json_summary" "make lint" "VERIFY list json should include the lint command"
assert_contains "$verify_list_json_summary" "make target" "VERIFY list json should include command sources"
assert_contains "$verify_list_json_summary" "lint_ok=True" "VERIFY list json should report runnable steps"
pass "VERIFY list json"

verify_list_env_summary="$(
    VERIFY_SCRIPT="$VERIFY_SCRIPT" TEST_VERIFY_DIR="$TEST_VERIFY_DIR" zsh <<'EOF'
set -euo pipefail
source /dev/stdin <<<"$("$VERIFY_SCRIPT" --target-dir "$TEST_VERIFY_DIR" --steps lint,test --list --list-format env)"
printf '%s\n' "$EVOP_VERIFY_PLAN_TARGET_DIR"
printf '%s\n' "$EVOP_VERIFY_PLAN_SELECTED_STEPS"
printf '%s\n' "$EVOP_VERIFY_PLAN_LINT_COMMAND"
printf 'test_ok=%s\n' "$([[ "$EVOP_VERIFY_PLAN_TEST_RUNNABLE" == "1" ]] && printf true || printf false)"
EOF
)"
assert_contains "$verify_list_env_summary" "$TEST_VERIFY_DIR" "VERIFY list env should export the target directory"
assert_contains "$verify_list_env_summary" "lint" "VERIFY list env should export the selected steps"
assert_contains "$verify_list_env_summary" "make lint" "VERIFY list env should export selected commands"
assert_contains "$verify_list_env_summary" "test_ok=true" "VERIFY list env should export runnable flags"
pass "VERIFY list env"

verify_report_json="$TEST_TMPDIR/verify-report.json"
run_expect_success "VERIFY should write a json report" "$VERIFY_SCRIPT" --target-dir "$TEST_VERIFY_DIR" --steps lint,test --report-file "$verify_report_json" --report-format json >/dev/null
verify_report_json_summary="$(VERIFY_REPORT_JSON="$(cat "$verify_report_json")" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["VERIFY_REPORT_JSON"])
print(data["final_status"])
print(data["steps"]["lint"]["status"])
print(data["steps"]["test"]["status"])
print(f"build_ok={data['steps']['build']['status'] == 'not_selected'}")
print(f"log_ok={data['steps']['lint']['log_file'].endswith('lint.log')}")
print(f"duration_ok={data['steps']['lint']['duration_ms'] >= 0}")
PY
)"
assert_contains "$verify_report_json_summary" "0" "VERIFY json report should include the final status"
assert_contains "$verify_report_json_summary" "passed" "VERIFY json report should mark selected passing steps"
assert_contains "$verify_report_json_summary" "build_ok=True" "VERIFY json report should mark unselected steps"
assert_contains "$verify_report_json_summary" "log_ok=True" "VERIFY json report should include step log files"
assert_contains "$verify_report_json_summary" "duration_ok=True" "VERIFY json report should include step durations"
pass "VERIFY json report"

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

verify_partial_dir="$TEST_TMPDIR/verify-partial-project"
mkdir -p "$verify_partial_dir"
cat >"$verify_partial_dir/Makefile" <<'EOF'
lint:
	@true
EOF
verify_require_all_output="$(run_expect_failure "VERIFY should fail when require-all is set and a step is missing" "$VERIFY_SCRIPT" --target-dir "$verify_partial_dir" --steps lint,test --require-all --list)"
assert_contains "$verify_require_all_output" "Missing verification commands for selected steps: test" "VERIFY require-all should identify missing commands"
pass "VERIFY require-all"

verify_report_env="$TEST_TMPDIR/verify-report.env"
run_expect_success "VERIFY dry-run should write an env report" "$VERIFY_SCRIPT" --target-dir "$TEST_VERIFY_DIR" --steps test,build --dry-run --report-file "$verify_report_env" --report-format env >/dev/null
verify_report_env_summary="$(
    VERIFY_REPORT_ENV="$verify_report_env" zsh <<'EOF'
set -euo pipefail
source "$VERIFY_REPORT_ENV"
printf '%s\n' "$EVOP_VERIFY_FINAL_STATUS"
printf '%s\n' "$EVOP_VERIFY_DRY_RUN"
printf '%s\n' "$EVOP_VERIFY_TEST_STATUS"
printf 'build_ok=%s\n' "$([[ "$EVOP_VERIFY_BUILD_STATUS" == "dry_run" ]] && printf true || printf false)"
printf 'lint_ok=%s\n' "$([[ "$EVOP_VERIFY_LINT_STATUS" == "not_selected" ]] && printf true || printf false)"
EOF
)"
assert_contains "$verify_report_env_summary" "0" "VERIFY env report should include the final status"
assert_contains "$verify_report_env_summary" "1" "VERIFY env report should record dry-run mode"
assert_contains "$verify_report_env_summary" "dry_run" "VERIFY env report should mark selected dry-run steps"
assert_contains "$verify_report_env_summary" "build_ok=true" "VERIFY env report should export build status"
assert_contains "$verify_report_env_summary" "lint_ok=true" "VERIFY env report should export unselected step status"
pass "VERIFY env report"

cli_inspect_output="$(run_expect_success "CLI inspect should dispatch to INSPECT" "$CLI_SCRIPT" inspect --target-dir "$TEST_CONTEXT_DIR")"
assert_contains "$cli_inspect_output" "Suggested commands:" "CLI inspect should dispatch to INSPECT"
pass "CLI inspect behavior"

setup_flutter_workspace
flutter_inspect_output="$(run_expect_success "INSPECT should summarize Flutter mobile projects" "$INSPECT_SCRIPT" --target-dir "$TEST_FLUTTER_DIR")"
assert_contains "$flutter_inspect_output" "Language profile: dart (auto-detected)" "INSPECT should detect Dart for Flutter projects"
assert_contains "$flutter_inspect_output" "Framework profile: flutter (auto-detected)" "INSPECT should detect Flutter framework context"
assert_contains "$flutter_inspect_output" "Project type: mobile-app (auto-detected)" "INSPECT should detect the mobile-app project type"
assert_contains "$flutter_inspect_output" "Test: flutter test" "INSPECT should infer Flutter test commands"
assert_contains "$flutter_inspect_output" "Lint: flutter analyze" "INSPECT should infer Flutter analyzer commands"
pass "INSPECT Flutter summary"

setup_agent_test_workspace
mkdir -p "$TEST_TARGET_DIR/.evoprogrammer/hooks"
cat >"$TEST_TARGET_DIR/.evoprogrammer/hooks/post-iteration" <<'EOF'
#!/usr/bin/env zsh
set -euo pipefail
printf 'generated\n' >"generated.txt"
EOF
chmod +x "$TEST_TARGET_DIR/.evoprogrammer/hooks/post-iteration"
printf 'baseline dirty change\n' >"$TEST_TARGET_DIR/existing.txt"

run_expect_success "LOOP should auto-commit only iteration changes" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --target-dir "$TEST_TARGET_DIR" --auto-commit --auto-commit-message "feat: auto commit test" --prompt "generate a file" >/dev/null
auto_commit_status="$(
    TARGET_DIR="$TEST_TARGET_DIR" zsh <<'EOF'
set -euo pipefail
commit_subject="$(git -C "$TARGET_DIR" log -1 --pretty=%s)"
status_output="$(git -C "$TARGET_DIR" status --short)"
tracked_generated="$(git -C "$TARGET_DIR" ls-files generated.txt)"
printf 'subject=%s\n' "$commit_subject"
printf 'status=%s\n' "$status_output"
printf 'generated=%s\n' "$tracked_generated"
EOF
)"
assert_contains "$auto_commit_status" "subject=feat: auto commit test" "LOOP auto-commit should use the requested commit message"
assert_contains "$auto_commit_status" "generated=generated.txt" "LOOP auto-commit should commit iteration-created files"
assert_contains "$auto_commit_status" "existing.txt" "LOOP auto-commit should leave pre-existing dirty changes untouched"
pass "LOOP auto-commit isolation"
