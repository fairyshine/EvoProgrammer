#!/usr/bin/env zsh

setup_context_workspace

inspect_output="$(run_expect_success "INSPECT should summarize detected project context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test")"
assert_contains "$inspect_output" "Language profile: typescript (auto-detected)" "INSPECT should print the detected language profile"
assert_contains "$inspect_output" "Framework profile: nextjs (auto-detected)" "INSPECT should print the detected framework profile"
assert_contains "$inspect_output" "Suggested commands:" "INSPECT should print the suggested command section"
assert_contains "$inspect_output" "Lint: pnpm lint [package.json script]" "INSPECT should include command sources"
assert_contains "$inspect_output" "Agent command surfaces:" "INSPECT should print agent command surfaces"
assert_contains "$inspect_output" "./bin/context-tool [repo executable]" "INSPECT should list repo executables that agents can call directly"
assert_contains "$inspect_output" "zsh ./STATUS.sh [top-level script]" "INSPECT should list top-level scripts as agent command surfaces"
assert_contains "$inspect_output" "./scripts/release [repo helper executable]" "INSPECT should list executable helper scripts for agents"
assert_contains "$inspect_output" "sh ./scripts/bootstrap.sh [repo helper program]" "INSPECT should list invocable helper programs even when they are not executable"
assert_contains "$inspect_output" "./tools/sync-context [repo helper executable]" "INSPECT should list executable helper tools for agents"
assert_contains "$inspect_output" "zsh ./tests/run_tests.sh [test harness script]" "INSPECT should list test harness scripts as agent command surfaces"
assert_contains "$inspect_output" "pnpm inspect [package.json script]" "INSPECT should list non-verification package scripts as agent command surfaces"
assert_contains "$inspect_output" "pnpm generate [package.json script]" "INSPECT should list generation scripts as agent command surfaces"
assert_contains "$inspect_output" "Agent support tools:" "INSPECT should print agent support tools"
assert_contains "$inspect_output" "git [host cli]" "INSPECT should list available host CLI support tools"
assert_contains "$inspect_output" "gh [host cli]" "INSPECT should list GitHub host CLI support tools when the repo exposes GitHub surfaces"
assert_contains "$inspect_output" "curl [http cli]" "INSPECT should list HTTP host CLI support tools when available"
assert_contains "$inspect_output" "yq [yaml cli]" "INSPECT should list YAML-aware host CLI support tools for YAML-heavy repos"
assert_contains "$inspect_output" "sqlite3 [database cli]" "INSPECT should list database CLIs when local SQL surfaces exist"
assert_contains "$inspect_output" "Operational surfaces:" "INSPECT should print operational surfaces"
assert_contains "$inspect_output" ".github/workflows" "INSPECT should report CI workflow surfaces"
pass "INSPECT summary"

inspect_prompt_output="$(run_expect_success "INSPECT should render prompt context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format prompt)"
assert_contains "$inspect_prompt_output" "[Repository Context]" "INSPECT prompt mode should render repository context"
assert_contains "$inspect_prompt_output" "[Recommended Workflow]" "INSPECT prompt mode should render workflow guidance"
assert_contains "$inspect_prompt_output" "Agent command surfaces:" "INSPECT prompt mode should render agent command surfaces"
assert_contains "$inspect_prompt_output" "Agent support tools:" "INSPECT prompt mode should render agent support tools"
assert_contains "$inspect_prompt_output" "Operational surfaces:" "INSPECT prompt mode should render operational surfaces"
pass "INSPECT prompt"

prompt_adaptation_dir="$TEST_TMPDIR/prompt-adaptation"
mkdir -p "$prompt_adaptation_dir"
inspect_prompt_adaptation_output="$(run_expect_success "INSPECT should honor structured prompt adaptations" "$INSPECT_SCRIPT" --target-dir "$prompt_adaptation_dir" --prompt $'[Language Adaptation]\nTarget language: csharp\n\n[Project-Type Adaptation]\nTarget project type: cli-tool\n\n[Recommended Workflow]\nTask kind: performance\n')"
assert_contains "$inspect_prompt_adaptation_output" "Language profile: csharp (from prompt)" "INSPECT should surface prompt-derived language profiles"
assert_contains "$inspect_prompt_adaptation_output" "Project type: cli-tool (from prompt)" "INSPECT should surface prompt-derived project types"
assert_contains "$inspect_prompt_adaptation_output" "Task kind: performance" "INSPECT should honor structured prompt task kinds"
pass "INSPECT structured prompt adaptations"

inspect_commands_output="$(run_expect_success "INSPECT should render a focused command report" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --format commands)"
assert_contains "$inspect_commands_output" "Suggested commands:" "INSPECT commands mode should print the command heading"
assert_contains "$inspect_commands_output" "Lint: pnpm lint [package.json script]" "INSPECT commands mode should include command sources"
assert_not_contains "$inspect_commands_output" "Architecture hints:" "INSPECT commands mode should stay focused on commands"
pass "INSPECT commands"

inspect_agent_output="$(run_expect_success "INSPECT should render an agent-facing command catalog" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --format agent)"
assert_contains "$inspect_agent_output" "Agent command catalog:" "INSPECT agent mode should print the agent command catalog heading"
assert_contains "$inspect_agent_output" "./bin/context-tool [repo_executable; context; repo executable; direct; high]" "INSPECT agent mode should show structured repo executable entries"
assert_contains "$inspect_agent_output" "sh ./scripts/bootstrap.sh [repo_helper_program; bootstrap; repo helper program; shell-runtime; high]" "INSPECT agent mode should show structured helper program entries"
assert_contains "$inspect_agent_output" "git [host cli]" "INSPECT agent mode should include agent support tools"
assert_contains "$inspect_agent_output" "Agent support tool catalog:" "INSPECT agent mode should print the structured support tool catalog"
assert_contains "$inspect_agent_output" "git -> " "INSPECT agent mode should include resolved support tool paths"
assert_contains "$inspect_agent_output" "[vcs; host cli; inspect repository state and record commits]" "INSPECT agent mode should include support tool capability and usage metadata"
assert_contains "$inspect_agent_output" "gh -> " "INSPECT agent mode should include structured GitHub CLI support entries"
assert_contains "$inspect_agent_output" "[github; host cli; inspect pull requests, issues, and workflow runs]" "INSPECT agent mode should describe GitHub CLI support usage"
assert_contains "$inspect_agent_output" "curl -> " "INSPECT agent mode should include structured HTTP CLI support entries"
assert_contains "$inspect_agent_output" "[http; http cli; fetch APIs, docs, and health endpoints directly]" "INSPECT agent mode should describe HTTP CLI support usage"
assert_not_contains "$inspect_agent_output" "Suggested commands:" "INSPECT agent mode should skip the general command plan"
pass "INSPECT agent"

inspect_json_output="$(run_expect_success "INSPECT should render machine-readable json context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format json)"
inspect_json_summary="$(INSPECT_JSON="$inspect_json_output" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["INSPECT_JSON"])
print(data["profiles"]["language"]["name"])
print(data["package_manager"])
print("\n".join(f"{item['kind']}|{item['capability']}|{item['runner']}|{item['workdir']}|{item['priority']}|{item['usage']}|{item['command']}|{item['source']}" for item in data["agent_command_catalog"]))
print("\n".join(f"{item['name']}|{item['path']}|{item['source']}|{item['capability']}|{item['usage']}" for item in data["agent_support_tool_catalog"]))
print("\n".join(data["agent_tools"]))
print("\n".join(data["agent_support_tools"]))
print(data["commands"]["lint"]["command"])
print(f"automation_ok={any('.github/workflows' in item for item in data['automation'])}")
print(f"backend_ok={data['facts_cache']['backend'] in {'associative-array', 'line-table'}}")
print(f"lookups_ok={data['facts_cache']['lookups'] > 0}")
print(f"entries_ok={data['facts_cache']['relative_exists_entries'] > 0}")
print(f"text_entries_ok={data['facts_cache']['file_text_entries'] > 0}")
print(f"command_entries_ok={data['facts_cache']['command_availability_entries'] > 0}")
print(f"command_path_entries_ok={data['facts_cache']['command_path_entries'] > 0}")
print(f"timings_ok={all(isinstance(data['timings'][key], int) and data['timings'][key] >= 0 for key in data['timings'])}")
print(f"profile_detection_ok={any(item['name'] == 'typescript' for item in data['profile_detection']['languages'])}")
PY
)"
assert_contains "$inspect_json_summary" "typescript" "INSPECT json should include the detected language profile"
assert_contains "$inspect_json_summary" "pnpm" "INSPECT json should include the package manager"
assert_contains "$inspect_json_summary" "repo_helper_program|bootstrap|shell-runtime|repo-root|high|prepare the repository environment or setup workflow|sh ./scripts/bootstrap.sh|repo helper program" "INSPECT json should include structured helper program entries"
assert_contains "$inspect_json_summary" "test_harness_script|verify|shell-runtime|repo-root|high|run verification or quality gates through the repo workflow|zsh ./tests/run_tests.sh|test harness script" "INSPECT json should include structured test harness entries"
assert_contains "$inspect_json_summary" "git|" "INSPECT json should include structured support tool catalog entries"
assert_contains "$inspect_json_summary" "|host cli|vcs|inspect repository state and record commits" "INSPECT json should include support tool capability and usage metadata"
assert_contains "$inspect_json_summary" "gh|" "INSPECT json should include structured GitHub support tool catalog entries"
assert_contains "$inspect_json_summary" "|host cli|github|inspect pull requests, issues, and workflow runs" "INSPECT json should include GitHub support tool metadata"
assert_contains "$inspect_json_summary" "curl|" "INSPECT json should include structured HTTP support tool catalog entries"
assert_contains "$inspect_json_summary" "|http cli|http|fetch APIs, docs, and health endpoints directly" "INSPECT json should include HTTP support tool metadata"
assert_contains "$inspect_json_summary" "./bin/context-tool [repo executable]" "INSPECT json should include agent command surfaces"
assert_contains "$inspect_json_summary" "./scripts/release [repo helper executable]" "INSPECT json should include repo helper executables"
assert_contains "$inspect_json_summary" "git [host cli]" "INSPECT json should include agent support tools"
assert_contains "$inspect_json_summary" "pnpm lint" "INSPECT json should include the lint command"
assert_contains "$inspect_json_summary" "automation_ok=True" "INSPECT json should include automation entries"
assert_contains "$inspect_json_summary" "backend_ok=True" "INSPECT json should include the facts-cache backend"
assert_contains "$inspect_json_summary" "lookups_ok=True" "INSPECT json should include facts-cache lookup diagnostics"
assert_contains "$inspect_json_summary" "entries_ok=True" "INSPECT json should include facts-cache entry counts"
assert_contains "$inspect_json_summary" "text_entries_ok=True" "INSPECT json should include file-text cache entry counts"
assert_contains "$inspect_json_summary" "command_entries_ok=True" "INSPECT json should include command-availability cache entry counts"
assert_contains "$inspect_json_summary" "command_path_entries_ok=True" "INSPECT json should include command-path cache entry counts"
assert_contains "$inspect_json_summary" "timings_ok=True" "INSPECT json should include phase timings"
assert_contains "$inspect_json_summary" "profile_detection_ok=True" "INSPECT json should include profile-detection candidates"
pass "INSPECT json"

inspect_agent_json_output="$(run_expect_success "INSPECT should render agent-catalog json context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format agent-json)"
inspect_agent_json_summary="$(INSPECT_AGENT_JSON="$inspect_agent_json_output" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["INSPECT_AGENT_JSON"])
print(data["language_profile"]["name"])
print(data["package_manager"])
print("\n".join(f"{item['kind']}|{item['capability']}|{item['runner']}|{item['workdir']}|{item['priority']}|{item['usage']}|{item['command']}|{item['source']}" for item in data["agent_command_catalog"]))
print("\n".join(f"{item['name']}|{item['path']}|{item['source']}|{item['capability']}|{item['usage']}" for item in data["agent_support_tool_catalog"]))
print("\n".join(data["agent_support_tools"]))
print(f"timings_ok={all(isinstance(data['timings'][key], int) and data['timings'][key] >= 0 for key in data['timings'])}")
print(f"commands_key={'commands' in data}")
PY
)"
assert_contains "$inspect_agent_json_summary" "typescript" "INSPECT agent-json should include the detected language profile"
assert_contains "$inspect_agent_json_summary" "pnpm" "INSPECT agent-json should include the package manager"
assert_contains "$inspect_agent_json_summary" "repo_helper_program|bootstrap|shell-runtime|repo-root|high|prepare the repository environment or setup workflow|sh ./scripts/bootstrap.sh|repo helper program" "INSPECT agent-json should include structured helper program entries"
assert_contains "$inspect_agent_json_summary" "git|" "INSPECT agent-json should include the structured support tool catalog"
assert_contains "$inspect_agent_json_summary" "|host cli|vcs|inspect repository state and record commits" "INSPECT agent-json should include support tool capability and usage metadata"
assert_contains "$inspect_agent_json_summary" "gh|" "INSPECT agent-json should include the structured GitHub support tool catalog"
assert_contains "$inspect_agent_json_summary" "|host cli|github|inspect pull requests, issues, and workflow runs" "INSPECT agent-json should include GitHub support tool metadata"
assert_contains "$inspect_agent_json_summary" "git [host cli]" "INSPECT agent-json should include support tools"
assert_contains "$inspect_agent_json_summary" "timings_ok=True" "INSPECT agent-json should include timing diagnostics"
assert_contains "$inspect_agent_json_summary" "commands_key=False" "INSPECT agent-json should stay focused on agent-facing data"
pass "INSPECT agent-json"

inspect_env_summary="$(
    ROOT_DIR="$ROOT_DIR" INSPECT_SCRIPT="$INSPECT_SCRIPT" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" zsh <<'EOF'
set -euo pipefail
source /dev/stdin <<<"$("$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format env)"

printf '%s\n' "$EVOP_INSPECT_LANGUAGE_PROFILE"
printf '%s\n' "$EVOP_INSPECT_PACKAGE_MANAGER"
printf '%s\n' "$EVOP_INSPECT_AGENT_COMMAND_CATALOG"
printf '%s\n' "$EVOP_INSPECT_AGENT_COMMAND_CAPABILITIES"
printf '%s\n' "$EVOP_INSPECT_AGENT_COMMAND_RUNNERS"
printf '%s\n' "$EVOP_INSPECT_AGENT_COMMAND_WORKDIRS"
printf '%s\n' "$EVOP_INSPECT_AGENT_COMMAND_PRIORITIES"
printf '%s\n' "$EVOP_INSPECT_AGENT_COMMAND_USAGES"
printf '%s\n' "$EVOP_INSPECT_AGENT_SUPPORT_TOOL_CATALOG"
printf '%s\n' "$EVOP_INSPECT_AGENT_SUPPORT_TOOL_CAPABILITIES"
printf '%s\n' "$EVOP_INSPECT_AGENT_TOOLS"
printf '%s\n' "$EVOP_INSPECT_AGENT_SUPPORT_TOOLS"
printf '%s\n' "$EVOP_INSPECT_LINT_COMMAND"
printf 'automation_ok=%s\n' "$([[ "$EVOP_INSPECT_AUTOMATION" == *".github/workflows"* ]] && printf true || printf false)"
printf 'workflow_ok=%s\n' "$([[ "$EVOP_INSPECT_TASK_WORKFLOW" == *"Reproduce or localize the failure path first"* ]] && printf true || printf false)"
printf 'text_cache_ok=%s\n' "$([[ "$EVOP_INSPECT_FACTS_CACHE_FILE_TEXT_ENTRIES" =~ ^[1-9][0-9]*$ ]] && printf true || printf false)"
printf 'command_cache_ok=%s\n' "$([[ "$EVOP_INSPECT_FACTS_CACHE_COMMAND_AVAILABILITY_ENTRIES" =~ ^[1-9][0-9]*$ ]] && printf true || printf false)"
printf 'command_path_cache_ok=%s\n' "$([[ "$EVOP_INSPECT_FACTS_CACHE_COMMAND_PATH_ENTRIES" =~ ^[1-9][0-9]*$ ]] && printf true || printf false)"
printf 'timings_ok=%s\n' "$([[ "$EVOP_INSPECT_TIMING_RESOLVE_PROFILES_MS" =~ ^[0-9]+$ ]] && printf true || printf false)"
EOF
)"
assert_contains "$inspect_env_summary" "typescript" "INSPECT env should export the detected language profile"
assert_contains "$inspect_env_summary" "pnpm" "INSPECT env should export the package manager"
assert_contains "$inspect_env_summary" $'repo_helper_program\tsh ./scripts/bootstrap.sh\trepo helper program' "INSPECT env should export the structured agent command catalog"
assert_contains "$inspect_env_summary" $'sh ./scripts/bootstrap.sh\tbootstrap' "INSPECT env should export command capability mappings"
assert_contains "$inspect_env_summary" $'sh ./scripts/bootstrap.sh\tshell-runtime' "INSPECT env should export command runner mappings"
assert_contains "$inspect_env_summary" $'sh ./scripts/bootstrap.sh\trepo-root' "INSPECT env should export command workdir mappings"
assert_contains "$inspect_env_summary" $'sh ./scripts/bootstrap.sh\thigh' "INSPECT env should export command priority mappings"
assert_contains "$inspect_env_summary" $'sh ./scripts/bootstrap.sh\tprepare the repository environment or setup workflow' "INSPECT env should export command usage mappings"
assert_contains "$inspect_env_summary" $'git\t' "INSPECT env should export the structured support tool catalog"
assert_contains "$inspect_env_summary" $'git\tvcs' "INSPECT env should export support tool capability mappings"
assert_contains "$inspect_env_summary" $'host cli\tvcs\tinspect repository state and record commits' "INSPECT env should export support tool usage metadata"
assert_contains "$inspect_env_summary" $'gh\tgithub' "INSPECT env should export GitHub support tool capability mappings"
assert_contains "$inspect_env_summary" "inspect pull requests, issues, and workflow runs" "INSPECT env should export GitHub support tool usage metadata"
assert_contains "$inspect_env_summary" $'curl\thttp' "INSPECT env should export HTTP support tool capability mappings"
assert_contains "$inspect_env_summary" $'test_harness_script\tzsh ./tests/run_tests.sh\ttest harness script' "INSPECT env should export structured test harness entries"
assert_contains "$inspect_env_summary" "pnpm inspect [package.json script]" "INSPECT env should export agent command surfaces"
assert_contains "$inspect_env_summary" "./tools/sync-context [repo helper executable]" "INSPECT env should export repo helper executables"
assert_contains "$inspect_env_summary" "git [host cli]" "INSPECT env should export agent support tools"
assert_contains "$inspect_env_summary" "pnpm lint" "INSPECT env should export command slots"
assert_contains "$inspect_env_summary" "automation_ok=true" "INSPECT env should export automation surfaces"
assert_contains "$inspect_env_summary" "workflow_ok=true" "INSPECT env should export workflow guidance"
assert_contains "$inspect_env_summary" "text_cache_ok=true" "INSPECT env should export file-text cache entry counts"
assert_contains "$inspect_env_summary" "command_cache_ok=true" "INSPECT env should export command-availability cache entry counts"
assert_contains "$inspect_env_summary" "command_path_cache_ok=true" "INSPECT env should export command-path cache entry counts"
assert_contains "$inspect_env_summary" "timings_ok=true" "INSPECT env should export timing diagnostics"
pass "INSPECT env"

inspect_agent_env_summary="$(
    ROOT_DIR="$ROOT_DIR" INSPECT_SCRIPT="$INSPECT_SCRIPT" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" zsh <<'EOF'
set -euo pipefail
source /dev/stdin <<<"$("$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format agent-env)"

printf '%s\n' "$EVOP_AGENT_CATALOG_LANGUAGE_PROFILE"
printf '%s\n' "$EVOP_AGENT_CATALOG_PACKAGE_MANAGER"
printf '%s\n' "$EVOP_AGENT_CATALOG_COMMAND_CATALOG"
printf '%s\n' "$EVOP_AGENT_CATALOG_COMMAND_CAPABILITIES"
printf '%s\n' "$EVOP_AGENT_CATALOG_COMMAND_RUNNERS"
printf '%s\n' "$EVOP_AGENT_CATALOG_COMMAND_WORKDIRS"
printf '%s\n' "$EVOP_AGENT_CATALOG_COMMAND_PRIORITIES"
printf '%s\n' "$EVOP_AGENT_CATALOG_COMMAND_USAGES"
printf '%s\n' "$EVOP_AGENT_CATALOG_SUPPORT_TOOL_CATALOG"
printf '%s\n' "$EVOP_AGENT_CATALOG_SUPPORT_TOOL_CAPABILITIES"
printf '%s\n' "$EVOP_AGENT_CATALOG_SUPPORT_TOOLS"
printf 'timings_ok=%s\n' "$([[ "$EVOP_AGENT_CATALOG_TIMING_ANALYZE_CONTEXT_MS" =~ ^[0-9]+$ && "$EVOP_AGENT_CATALOG_TIMING_FINALIZE_ANALYSIS_MS" =~ ^[0-9]+$ ]] && printf true || printf false)"
EOF
)"
assert_contains "$inspect_agent_env_summary" "typescript" "INSPECT agent-env should export the detected language profile"
assert_contains "$inspect_agent_env_summary" "pnpm" "INSPECT agent-env should export the package manager"
assert_contains "$inspect_agent_env_summary" $'repo_helper_program\tsh ./scripts/bootstrap.sh\trepo helper program' "INSPECT agent-env should export the structured command catalog"
assert_contains "$inspect_agent_env_summary" $'sh ./scripts/bootstrap.sh\tbootstrap' "INSPECT agent-env should export command capability mappings"
assert_contains "$inspect_agent_env_summary" $'sh ./scripts/bootstrap.sh\tshell-runtime' "INSPECT agent-env should export command runner mappings"
assert_contains "$inspect_agent_env_summary" $'sh ./scripts/bootstrap.sh\trepo-root' "INSPECT agent-env should export command workdir mappings"
assert_contains "$inspect_agent_env_summary" $'sh ./scripts/bootstrap.sh\thigh' "INSPECT agent-env should export command priority mappings"
assert_contains "$inspect_agent_env_summary" $'sh ./scripts/bootstrap.sh\tprepare the repository environment or setup workflow' "INSPECT agent-env should export command usage mappings"
assert_contains "$inspect_agent_env_summary" $'git\t' "INSPECT agent-env should export the structured support tool catalog"
assert_contains "$inspect_agent_env_summary" $'git\tvcs' "INSPECT agent-env should export support tool capability mappings"
assert_contains "$inspect_agent_env_summary" $'gh\tgithub' "INSPECT agent-env should export GitHub support tool capability mappings"
assert_contains "$inspect_agent_env_summary" "git [host cli]" "INSPECT agent-env should export support tools"
assert_contains "$inspect_agent_env_summary" "timings_ok=true" "INSPECT agent-env should export timing diagnostics"
pass "INSPECT agent-env"

catalog_output="$(run_expect_success "CATALOG should render the focused agent catalog summary" "$CATALOG_SCRIPT" --target-dir "$TEST_CONTEXT_DIR")"
assert_contains "$catalog_output" "Agent command catalog:" "CATALOG summary should print the command catalog heading"
assert_contains "$catalog_output" "Agent support tool catalog:" "CATALOG summary should print the support tool catalog heading"
assert_not_contains "$catalog_output" "Suggested commands:" "CATALOG summary should stay focused on agent-facing data"
pass "CATALOG summary"

catalog_commands_output="$(run_expect_success "CATALOG should filter to command entries" "$CATALOG_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --kind commands)"
assert_contains "$catalog_commands_output" "Agent command catalog:" "CATALOG commands view should print command entries"
assert_not_contains "$catalog_commands_output" "Agent support tool catalog:" "CATALOG commands view should omit support-tool catalog entries"
assert_not_contains "$catalog_commands_output" "Agent support tools:" "CATALOG commands view should omit support-tool summaries"
pass "CATALOG commands kind"

catalog_capability_output="$(run_expect_success "CATALOG should filter command entries by capability" "$CATALOG_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --kind commands --capability bootstrap)"
assert_contains "$catalog_capability_output" "Capability filter: bootstrap" "CATALOG summary should surface the applied capability filter"
assert_contains "$catalog_capability_output" "sh ./scripts/bootstrap.sh [repo_helper_program; bootstrap; repo helper program; shell-runtime; high]" "CATALOG capability view should keep matching helper programs"
assert_not_contains "$catalog_capability_output" "pnpm inspect [package_script; inspect; package.json script]" "CATALOG capability view should omit non-matching commands"
pass "CATALOG capability filter"

inspect_agent_recommend_output="$(run_expect_success "INSPECT agent should recommend task-oriented commands" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --format agent --recommend-for performance)"
assert_contains "$inspect_agent_recommend_output" "Recommended for: performance" "INSPECT agent should surface the requested recommendation task kind"
assert_contains "$inspect_agent_recommend_output" "Recommended agent commands:" "INSPECT agent should print the recommended command section"
assert_contains "$inspect_agent_recommend_output" "pnpm inspect [inspect; package_script; package.json script; package-manager; high]" "INSPECT agent should recommend inspect first for performance work"
assert_contains "$inspect_agent_recommend_output" "./bin/context-tool [context; repo_executable; repo executable; direct; high]" "INSPECT agent should recommend repo context tools for performance work"
pass "INSPECT agent recommendations"

catalog_recommend_json_output="$(run_expect_success "CATALOG should render recommended commands in json output" "$CATALOG_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --format json --kind commands --recommend-for performance)"
catalog_recommend_json_summary="$(CATALOG_JSON="$catalog_recommend_json_output" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["CATALOG_JSON"])
print(data["recommend_for"])
print(f"inspect_ok={any(item['command'] == 'pnpm inspect' and item['capability'] == 'inspect' for item in data['recommended_agent_command_catalog'])}")
print(f"context_ok={any(item['command'] == './bin/context-tool' and item['capability'] == 'context' for item in data['recommended_agent_command_catalog'])}")
print(f"tools_ok={'pnpm inspect [package.json script]' in data['recommended_agent_tools']}")
PY
)"
assert_contains "$catalog_recommend_json_summary" "performance" "CATALOG json should expose the resolved recommendation task kind"
assert_contains "$catalog_recommend_json_summary" "inspect_ok=True" "CATALOG json should include an inspect recommendation"
assert_contains "$catalog_recommend_json_summary" "context_ok=True" "CATALOG json should include a context recommendation"
assert_contains "$catalog_recommend_json_summary" "tools_ok=True" "CATALOG json should include flattened recommended tool lines"
pass "CATALOG recommendations json"

catalog_support_json_output="$(run_expect_success "CATALOG should render support-only json output" "$CATALOG_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --format json --kind support)"
catalog_support_json_summary="$(CATALOG_JSON="$catalog_support_json_output" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["CATALOG_JSON"])
print(data["kind"])
print(data["capability_filter"])
print(f"command_entries_ok={data['agent_command_catalog'] == []}")
print(f"support_catalog_ok={any(item['name'] == 'git' for item in data['agent_support_tool_catalog'])}")
print(f"support_metadata_ok={any(item['name'] == 'git' and item['capability'] == 'vcs' for item in data['agent_support_tool_catalog'])}")
print(f"support_tools_ok={'git [host cli]' in data['agent_support_tools']}")
PY
)"
assert_contains "$catalog_support_json_summary" "support" "CATALOG json should expose the selected kind"
assert_contains "$catalog_support_json_summary" "all" "CATALOG json should expose the default capability filter"
assert_contains "$catalog_support_json_summary" "command_entries_ok=True" "CATALOG support json should omit command catalog entries"
assert_contains "$catalog_support_json_summary" "support_catalog_ok=True" "CATALOG support json should keep structured support-tool entries"
assert_contains "$catalog_support_json_summary" "support_metadata_ok=True" "CATALOG support json should keep support tool capability metadata"
assert_contains "$catalog_support_json_summary" "support_tools_ok=True" "CATALOG support json should keep support-tool summaries"
pass "CATALOG json"

catalog_env_summary="$(
    CATALOG_SCRIPT="$CATALOG_SCRIPT" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" zsh <<'EOF'
set -euo pipefail
source /dev/stdin <<<"$("$CATALOG_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --format env --kind commands)"

printf '%s\n' "$EVOP_AGENT_CATALOG_KIND"
printf '%s\n' "$EVOP_AGENT_CATALOG_CAPABILITY_FILTER"
printf 'commands_ok=%s\n' "$([[ "$EVOP_AGENT_CATALOG_COMMAND_CATALOG" == *$'repo_executable\t./bin/context-tool\trepo executable'* ]] && printf true || printf false)"
printf 'capabilities_ok=%s\n' "$([[ "$EVOP_AGENT_CATALOG_COMMAND_CAPABILITIES" == *$'sh ./scripts/bootstrap.sh\tbootstrap'* ]] && printf true || printf false)"
printf 'runners_ok=%s\n' "$([[ "$EVOP_AGENT_CATALOG_COMMAND_RUNNERS" == *$'sh ./scripts/bootstrap.sh\tshell-runtime'* ]] && printf true || printf false)"
printf 'workdirs_ok=%s\n' "$([[ "$EVOP_AGENT_CATALOG_COMMAND_WORKDIRS" == *$'sh ./scripts/bootstrap.sh\trepo-root'* ]] && printf true || printf false)"
printf 'priorities_ok=%s\n' "$([[ "$EVOP_AGENT_CATALOG_COMMAND_PRIORITIES" == *$'sh ./scripts/bootstrap.sh\thigh'* ]] && printf true || printf false)"
printf 'support_empty_ok=%s\n' "$([[ -z "$EVOP_AGENT_CATALOG_SUPPORT_TOOL_CATALOG" && -z "$EVOP_AGENT_CATALOG_SUPPORT_TOOL_CAPABILITIES" && -z "$EVOP_AGENT_CATALOG_SUPPORT_TOOLS" ]] && printf true || printf false)"
EOF
)"
assert_contains "$catalog_env_summary" "commands" "CATALOG env should export the selected kind"
assert_contains "$catalog_env_summary" "all" "CATALOG env should export the selected capability filter"
assert_contains "$catalog_env_summary" "commands_ok=true" "CATALOG env commands view should export structured command entries"
assert_contains "$catalog_env_summary" "capabilities_ok=true" "CATALOG env commands view should export command capability mappings"
assert_contains "$catalog_env_summary" "runners_ok=true" "CATALOG env commands view should export command runner mappings"
assert_contains "$catalog_env_summary" "workdirs_ok=true" "CATALOG env commands view should export command workdir mappings"
assert_contains "$catalog_env_summary" "priorities_ok=true" "CATALOG env commands view should export command priority mappings"
assert_contains "$catalog_env_summary" "support_empty_ok=true" "CATALOG env commands view should clear support-tool exports"
pass "CATALOG env"

catalog_recommend_env_summary="$(
    CATALOG_SCRIPT="$CATALOG_SCRIPT" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" zsh <<'EOF'
set -euo pipefail
source /dev/stdin <<<"$("$CATALOG_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --format env --kind commands --recommend-for performance)"

printf '%s\n' "$EVOP_AGENT_CATALOG_RECOMMEND_FOR"
printf 'recommended_commands_ok=%s\n' "$([[ "$EVOP_AGENT_CATALOG_RECOMMENDED_COMMAND_CATALOG" == *$'package_script\tpnpm inspect\tpackage.json script'* ]] && printf true || printf false)"
printf 'recommended_capabilities_ok=%s\n' "$([[ "$EVOP_AGENT_CATALOG_RECOMMENDED_COMMAND_CAPABILITIES" == *$'./bin/context-tool\tcontext'* ]] && printf true || printf false)"
printf 'recommended_tools_ok=%s\n' "$([[ "$EVOP_AGENT_CATALOG_RECOMMENDED_TOOLS" == *"pnpm inspect [package.json script]"* ]] && printf true || printf false)"
EOF
)"
assert_contains "$catalog_recommend_env_summary" "performance" "CATALOG env should export the resolved recommendation task kind"
assert_contains "$catalog_recommend_env_summary" "recommended_commands_ok=true" "CATALOG env should export structured recommended command entries"
assert_contains "$catalog_recommend_env_summary" "recommended_capabilities_ok=true" "CATALOG env should export recommended command capability mappings"
assert_contains "$catalog_recommend_env_summary" "recommended_tools_ok=true" "CATALOG env should export flattened recommended tool lines"
pass "CATALOG recommendations env"

catalog_report_json="$TEST_TMPDIR/catalog-report.json"
run_expect_success "CATALOG should write a json report file" "$CATALOG_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --kind commands --report-file "$catalog_report_json" --report-format json >/dev/null
catalog_report_json_summary="$(CATALOG_REPORT_JSON="$(cat "$catalog_report_json")" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["CATALOG_REPORT_JSON"])
print(data["kind"])
print(data["capability_filter"])
print(f"commands_ok={any(item['command'] == './bin/context-tool' and item['runner'] == 'direct' and item['priority'] == 'high' for item in data['agent_command_catalog'])}")
print(f"support_empty_ok={data['agent_support_tool_catalog'] == []}")
PY
)"
assert_contains "$catalog_report_json_summary" "commands" "CATALOG json report should preserve the selected kind"
assert_contains "$catalog_report_json_summary" "all" "CATALOG json report should preserve the default capability filter"
assert_contains "$catalog_report_json_summary" "commands_ok=True" "CATALOG json report should include command catalog entries"
assert_contains "$catalog_report_json_summary" "support_empty_ok=True" "CATALOG json report should omit support-tool entries for commands-only views"
pass "CATALOG json report file"

setup_node_monorepo_workspace
monorepo_inspect_output="$(run_expect_success "INSPECT should surface workspace package roots and recursive commands" "$INSPECT_SCRIPT" --target-dir "$TEST_NODE_MONOREPO_DIR")"
assert_contains "$monorepo_inspect_output" "Workspace mode: monorepo" "INSPECT should classify JS workspaces as monorepos"
assert_contains "$monorepo_inspect_output" "Workspace packages:" "INSPECT should print discovered workspace packages"
assert_contains "$monorepo_inspect_output" "apps/web [package.json]" "INSPECT should list app workspace packages"
assert_contains "$monorepo_inspect_output" "packages/shared [package.json]" "INSPECT should list shared workspace packages"
assert_contains "$monorepo_inspect_output" "Build: pnpm -r --if-present run build [workspace package.json scripts]" "INSPECT should infer recursive workspace build commands when the root manifest has no scripts"
assert_contains "$monorepo_inspect_output" "Typecheck: pnpm -r --if-present run typecheck [workspace package.json scripts]" "INSPECT should infer recursive workspace typecheck commands"
assert_contains "$monorepo_inspect_output" "apps/web: workspace package root [package.json]" "INSPECT should add workspace package roots to architecture hints"
pass "INSPECT monorepo workspace packages"

monorepo_inspect_json_output="$(run_expect_success "INSPECT json should include workspace packages" "$INSPECT_SCRIPT" --target-dir "$TEST_NODE_MONOREPO_DIR" --format json)"
monorepo_inspect_json_summary="$(INSPECT_JSON="$monorepo_inspect_json_output" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["INSPECT_JSON"])
print(data["workspace_mode"])
print(data["commands"]["build"]["command"])
print(f"apps_ok={'apps/web [package.json]' in data['workspace_packages']}")
print(f"shared_ok={'packages/shared [package.json]' in data['workspace_packages']}")
PY
)"
assert_contains "$monorepo_inspect_json_summary" "monorepo" "INSPECT json should include workspace mode for monorepos"
assert_contains "$monorepo_inspect_json_summary" "pnpm -r --if-present run build" "INSPECT json should export recursive workspace commands"
assert_contains "$monorepo_inspect_json_summary" "apps_ok=True" "INSPECT json should export app workspace packages"
assert_contains "$monorepo_inspect_json_summary" "shared_ok=True" "INSPECT json should export shared workspace packages"
pass "INSPECT monorepo json"

monorepo_inspect_env_summary="$(
    INSPECT_SCRIPT="$INSPECT_SCRIPT" TEST_NODE_MONOREPO_DIR="$TEST_NODE_MONOREPO_DIR" zsh <<'EOF'
set -euo pipefail
source /dev/stdin <<<"$("$INSPECT_SCRIPT" --target-dir "$TEST_NODE_MONOREPO_DIR" --format env)"
printf '%s\n' "$EVOP_INSPECT_WORKSPACE_MODE"
printf '%s\n' "$EVOP_INSPECT_BUILD_COMMAND"
printf 'packages_ok=%s\n' "$([[ "$EVOP_INSPECT_WORKSPACE_PACKAGES" == *"apps/web [package.json]"* && "$EVOP_INSPECT_WORKSPACE_PACKAGES" == *"packages/shared [package.json]"* ]] && printf true || printf false)"
EOF
)"
assert_contains "$monorepo_inspect_env_summary" "monorepo" "INSPECT env should export workspace mode"
assert_contains "$monorepo_inspect_env_summary" "pnpm -r --if-present run build" "INSPECT env should export recursive workspace commands"
assert_contains "$monorepo_inspect_env_summary" "packages_ok=true" "INSPECT env should export workspace packages"
pass "INSPECT monorepo env"

setup_yarn_monorepo_workspace
yarn_monorepo_inspect_output="$(run_expect_success "INSPECT should infer Yarn workspace commands for Berry monorepos" "$INSPECT_SCRIPT" --target-dir "$TEST_YARN_MONOREPO_DIR")"
assert_contains "$yarn_monorepo_inspect_output" "Package manager: yarn" "INSPECT should detect Yarn as the package manager for Yarn workspaces"
assert_contains "$yarn_monorepo_inspect_output" "Build: yarn workspaces foreach --all --parallel --topological run build [workspace package.json scripts]" "INSPECT should infer recursive Yarn build commands"
assert_contains "$yarn_monorepo_inspect_output" "Dev: yarn workspaces foreach --all --parallel run dev [workspace package.json scripts]" "INSPECT should infer parallel Yarn dev commands"
pass "INSPECT Yarn monorepo workspace commands"

setup_bun_monorepo_workspace
bun_monorepo_inspect_output="$(run_expect_success "INSPECT should infer Bun workspace commands" "$INSPECT_SCRIPT" --target-dir "$TEST_BUN_MONOREPO_DIR")"
assert_contains "$bun_monorepo_inspect_output" "Package manager: bun" "INSPECT should detect Bun as the package manager for Bun workspaces"
assert_contains "$bun_monorepo_inspect_output" "Build: bun run --workspaces --if-present --parallel build [workspace package.json scripts]" "INSPECT should infer recursive Bun build commands"
assert_contains "$bun_monorepo_inspect_output" "Test: bun run --workspaces --if-present --parallel test [workspace package.json scripts]" "INSPECT should infer recursive Bun test commands"
pass "INSPECT Bun monorepo workspace commands"

workspace_script_cache_output="$(
    ROOT_DIR="$ROOT_DIR" TEST_NODE_MONOREPO_DIR="$TEST_NODE_MONOREPO_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/project-context.sh"

evop_project_workspace_has_package_json_script_cached "$TEST_NODE_MONOREPO_DIR" "build"
printf 'first_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_WORKSPACE_SCRIPT_CACHE)"
evop_project_workspace_has_package_json_script_cached "$TEST_NODE_MONOREPO_DIR" "build"
printf 'second_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_WORKSPACE_SCRIPT_CACHE)"
printf 'package_json_manifest_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_WORKSPACE_PACKAGE_JSON_MANIFESTS_CACHE)"
EOF
)"
assert_contains "$workspace_script_cache_output" "first_cache_entries=1" "Workspace script lookups should populate the dedicated cache on first access"
assert_contains "$workspace_script_cache_output" "second_cache_entries=1" "Workspace script lookups should reuse the cached result on repeated access"
assert_contains "$workspace_script_cache_output" "package_json_manifest_cache_entries=1" "Workspace package.json filtering should also be cached"
pass "Workspace script cache reuse"

agent_tool_cache_output="$(
    ROOT_DIR="$ROOT_DIR" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/project-context.sh"

evop_project_agent_tool_surfaces_cached "$TEST_CONTEXT_DIR" "pnpm" >/dev/null
printf 'first_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_AGENT_TOOL_SURFACES_CACHE)"
evop_project_agent_tool_surfaces_cached "$TEST_CONTEXT_DIR" "pnpm" >/dev/null
printf 'second_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_AGENT_TOOL_SURFACES_CACHE)"
printf 'tool_ok=%s\n' "$([[ "$EVOP_PROJECT_CONTEXT_AGENT_TOOL_SURFACES_RESULT" == *"./bin/context-tool [repo executable]"* ]] && printf true || printf false)"
printf 'helper_ok=%s\n' "$([[ "$EVOP_PROJECT_CONTEXT_AGENT_TOOL_SURFACES_RESULT" == *"./tools/sync-context [repo helper executable]"* ]] && printf true || printf false)"
EOF
)"
assert_contains "$agent_tool_cache_output" "first_cache_entries=1" "Agent tool discovery should populate the dedicated cache on first access"
assert_contains "$agent_tool_cache_output" "second_cache_entries=1" "Agent tool discovery should reuse the cache on repeated access"
assert_contains "$agent_tool_cache_output" "tool_ok=true" "Agent tool discovery should return repo executable surfaces"
assert_contains "$agent_tool_cache_output" "helper_ok=true" "Agent tool discovery should return repo helper executable surfaces"
pass "Agent tool cache reuse"

agent_command_catalog_cache_output="$(
    ROOT_DIR="$ROOT_DIR" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/project-context.sh"

evop_project_agent_command_catalog_cached "$TEST_CONTEXT_DIR" "pnpm" >/dev/null
printf 'first_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_CACHE)"
evop_project_agent_command_catalog_cached "$TEST_CONTEXT_DIR" "pnpm" >/dev/null
printf 'second_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_CACHE)"
printf 'helper_program_ok=%s\n' "$([[ "$EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_RESULT" == *$'repo_helper_program\tsh ./scripts/bootstrap.sh\trepo helper program'* ]] && printf true || printf false)"
printf 'test_harness_ok=%s\n' "$([[ "$EVOP_PROJECT_CONTEXT_AGENT_COMMAND_CATALOG_RESULT" == *$'test_harness_script\tzsh ./tests/run_tests.sh\ttest harness script'* ]] && printf true || printf false)"
EOF
)"
assert_contains "$agent_command_catalog_cache_output" "first_cache_entries=1" "Agent command catalog should populate the dedicated cache on first access"
assert_contains "$agent_command_catalog_cache_output" "second_cache_entries=1" "Agent command catalog should reuse the cache on repeated access"
assert_contains "$agent_command_catalog_cache_output" "helper_program_ok=true" "Agent command catalog should include invocable helper programs"
assert_contains "$agent_command_catalog_cache_output" "test_harness_ok=true" "Agent command catalog should include test harness scripts"
pass "Agent command catalog cache reuse"

agent_command_metadata_cache_output="$(
    ROOT_DIR="$ROOT_DIR" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/project-context.sh"

evop_project_agent_command_metadata_cached "$TEST_CONTEXT_DIR" "pnpm" >/dev/null
printf 'first_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_AGENT_COMMAND_METADATA_CACHE)"
evop_project_agent_command_metadata_cached "$TEST_CONTEXT_DIR" "pnpm" >/dev/null
printf 'second_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_AGENT_COMMAND_METADATA_CACHE)"
printf 'inspect_ok=%s\n' "$([[ "$EVOP_PROJECT_CONTEXT_AGENT_COMMAND_METADATA_RESULT" == *$'package_script\tinspect\tpnpm inspect\tpackage.json script\tpackage-manager\trepo-root\thigh\tinspect repository state or generate repo context'* ]] && printf true || printf false)"
EOF
)"
assert_contains "$agent_command_metadata_cache_output" "first_cache_entries=1" "Agent command metadata should populate the dedicated cache on first access"
assert_contains "$agent_command_metadata_cache_output" "second_cache_entries=1" "Agent command metadata should reuse the dedicated cache on repeated access"
assert_contains "$agent_command_metadata_cache_output" "inspect_ok=true" "Agent command metadata should include cached command execution metadata"
pass "Agent command metadata cache reuse"

agent_local_command_catalog_cache_output="$(
    ROOT_DIR="$ROOT_DIR" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/project-context.sh"

evop_project_agent_local_command_catalog_cached "$TEST_CONTEXT_DIR" >/dev/null
printf 'first_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_CACHE)"
evop_project_agent_local_command_catalog_cached "$TEST_CONTEXT_DIR" >/dev/null
printf 'second_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_CACHE)"
printf 'bin_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_BIN_EXECUTABLES_CACHE)"
printf 'top_level_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_TOP_LEVEL_SHELL_SCRIPTS_CACHE)"
printf 'helper_path_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_HELPER_SURFACE_PATHS_CACHE)"
printf 'harness_path_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_TEST_HARNESS_PATHS_CACHE)"
printf 'make_ok=%s\n' "$([[ "$EVOP_PROJECT_CONTEXT_AGENT_LOCAL_COMMAND_CATALOG_RESULT" == *$'top_level_script\tzsh ./STATUS.sh\ttop-level script'* ]] && printf true || printf false)"
EOF
)"
assert_contains "$agent_local_command_catalog_cache_output" "first_cache_entries=1" "Repo-local agent command catalog should populate its dedicated cache on first access"
assert_contains "$agent_local_command_catalog_cache_output" "second_cache_entries=1" "Repo-local agent command catalog should reuse its dedicated cache on repeated access"
assert_contains "$agent_local_command_catalog_cache_output" "bin_cache_entries=1" "Repo-local agent command discovery should cache bin executable scans"
assert_contains "$agent_local_command_catalog_cache_output" "top_level_cache_entries=1" "Repo-local agent command discovery should cache top-level shell script scans"
assert_contains "$agent_local_command_catalog_cache_output" "helper_path_cache_entries=4" "Repo-local agent command discovery should cache helper-dir scans per helper root"
assert_contains "$agent_local_command_catalog_cache_output" "harness_path_cache_entries=1" "Repo-local agent command discovery should cache test harness scans"
assert_contains "$agent_local_command_catalog_cache_output" "make_ok=true" "Repo-local agent command catalog should include top-level scripts"
pass "Agent local command catalog cache reuse"

package_json_script_cache_output="$(
    ROOT_DIR="$ROOT_DIR" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/project-context.sh"

evop_project_package_json_scripts_cached "$TEST_CONTEXT_DIR/package.json" >/dev/null
printf 'first_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_CACHE)"
printf 'generate_ok=%s\n' "$([[ "$EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_RESULT" == *$'\n'generate$'\n'* || "$EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_RESULT" == generate || "$EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_RESULT" == generate$'\n'* || "$EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_RESULT" == *$'\n'generate ]] && printf true || printf false)"
evop_project_package_json_scripts_cached "$TEST_CONTEXT_DIR/package.json" >/dev/null
printf 'second_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_PACKAGE_JSON_SCRIPTS_CACHE)"
EOF
)"
assert_contains "$package_json_script_cache_output" "first_cache_entries=1" "Package.json script discovery should populate the dedicated cache on first access"
assert_contains "$package_json_script_cache_output" "generate_ok=true" "Package.json script discovery should return cached script names"
assert_contains "$package_json_script_cache_output" "second_cache_entries=1" "Package.json script discovery should reuse the cache on repeated access"
pass "Package.json script cache reuse"

agent_support_tool_cache_output="$(
    ROOT_DIR="$ROOT_DIR" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/project-context.sh"

evop_project_agent_support_tools_cached "$TEST_CONTEXT_DIR" "pnpm" "typescript" >/dev/null
printf 'first_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS_CACHE)"
printf 'availability_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_COMMAND_AVAILABILITY_CACHE)"
printf 'path_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_COMMAND_PATH_CACHE)"
evop_project_agent_support_tools_cached "$TEST_CONTEXT_DIR" "pnpm" "typescript" >/dev/null
printf 'second_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS_CACHE)"
printf 'tool_ok=%s\n' "$([[ "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS_RESULT" == *"git [host cli]"* ]] && printf true || printf false)"
printf 'github_ok=%s\n' "$([[ "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOLS_RESULT" == *"gh [host cli]"* ]] && printf true || printf false)"
EOF
)"
assert_contains "$agent_support_tool_cache_output" "first_cache_entries=1" "Agent support tool discovery should populate the dedicated cache on first access"
assert_contains "$agent_support_tool_cache_output" "availability_entries=" "Agent support tool discovery should populate command-availability cache entries"
assert_contains "$agent_support_tool_cache_output" "path_entries=" "Agent support tool discovery should populate command-path cache entries"
assert_contains "$agent_support_tool_cache_output" "second_cache_entries=1" "Agent support tool discovery should reuse the cache on repeated access"
assert_contains "$agent_support_tool_cache_output" "tool_ok=true" "Agent support tool discovery should return available host CLI support tools"
assert_contains "$agent_support_tool_cache_output" "github_ok=true" "Agent support tool discovery should include GitHub CLI support tools when available"
pass "Agent support tool cache reuse"

agent_support_tool_catalog_cache_output="$(
    ROOT_DIR="$ROOT_DIR" TEST_CONTEXT_DIR="$TEST_CONTEXT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/project-context.sh"

evop_project_agent_support_tool_catalog_cached "$TEST_CONTEXT_DIR" "pnpm" "typescript" >/dev/null
printf 'first_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG_CACHE)"
evop_project_agent_support_tool_catalog_cached "$TEST_CONTEXT_DIR" "pnpm" "typescript" >/dev/null
printf 'second_cache_entries=%s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG_CACHE)"
printf 'tool_ok=%s\n' "$([[ "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG_RESULT" == *$'git\t'*$'\thost cli\tvcs\tinspect repository state and record commits'* ]] && printf true || printf false)"
printf 'http_ok=%s\n' "$([[ "$EVOP_PROJECT_CONTEXT_AGENT_SUPPORT_TOOL_CATALOG_RESULT" == *$'curl\t'*$'\thttp cli\thttp\tfetch APIs, docs, and health endpoints directly'* ]] && printf true || printf false)"
EOF
)"
assert_contains "$agent_support_tool_catalog_cache_output" "first_cache_entries=1" "Agent support tool catalog should populate the dedicated cache on first access"
assert_contains "$agent_support_tool_catalog_cache_output" "second_cache_entries=1" "Agent support tool catalog should reuse the dedicated cache on repeated access"
assert_contains "$agent_support_tool_catalog_cache_output" "tool_ok=true" "Agent support tool catalog should include resolved host CLI entries"
assert_contains "$agent_support_tool_catalog_cache_output" "http_ok=true" "Agent support tool catalog should include structured HTTP CLI support entries"
pass "Agent support tool catalog cache reuse"

inspect_diagnostics_output="$(run_expect_success "INSPECT should render diagnostics context" "$INSPECT_SCRIPT" --target-dir "$TEST_CONTEXT_DIR" --prompt "fix a failing dashboard test" --format diagnostics)"
assert_contains "$inspect_diagnostics_output" "Inspection diagnostics:" "INSPECT diagnostics should print the diagnostics heading"
assert_contains "$inspect_diagnostics_output" "Facts cache backend:" "INSPECT diagnostics should print the cache backend"
assert_contains "$inspect_diagnostics_output" "Facts cache lookups:" "INSPECT diagnostics should print cache lookup counts"
assert_contains "$inspect_diagnostics_output" "Facts cache hit rate:" "INSPECT diagnostics should print cache hit rates"
assert_contains "$inspect_diagnostics_output" "File-text cache entries:" "INSPECT diagnostics should print file-text cache entries"
assert_contains "$inspect_diagnostics_output" "Command-availability cache entries:" "INSPECT diagnostics should print command-availability cache entries"
assert_contains "$inspect_diagnostics_output" "Command-path cache entries:" "INSPECT diagnostics should print command-path cache entries"
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

verify_monorepo_dry_run_output="$(run_expect_success "VERIFY dry-run should reuse recursive monorepo commands" "$VERIFY_SCRIPT" --target-dir "$TEST_NODE_MONOREPO_DIR" --steps lint,typecheck,test,build --dry-run)"
assert_contains "$verify_monorepo_dry_run_output" "Running lint: pnpm -r --if-present run lint" "VERIFY dry-run should reuse recursive monorepo lint commands"
assert_contains "$verify_monorepo_dry_run_output" "Running typecheck: pnpm -r --if-present run typecheck" "VERIFY dry-run should reuse recursive monorepo typecheck commands"
assert_contains "$verify_monorepo_dry_run_output" "Running test: pnpm -r --if-present run test" "VERIFY dry-run should reuse recursive monorepo test commands"
assert_contains "$verify_monorepo_dry_run_output" "Running build: pnpm -r --if-present run build" "VERIFY dry-run should reuse recursive monorepo build commands"
pass "VERIFY monorepo dry-run"

verify_yarn_monorepo_dry_run_output="$(run_expect_success "VERIFY dry-run should reuse Yarn workspace commands" "$VERIFY_SCRIPT" --target-dir "$TEST_YARN_MONOREPO_DIR" --steps lint,typecheck,test,build --dry-run)"
assert_contains "$verify_yarn_monorepo_dry_run_output" "Running lint: yarn workspaces foreach --all --parallel --topological run lint" "VERIFY dry-run should reuse recursive Yarn lint commands"
assert_contains "$verify_yarn_monorepo_dry_run_output" "Running typecheck: yarn workspaces foreach --all --parallel --topological run typecheck" "VERIFY dry-run should reuse recursive Yarn typecheck commands"
assert_contains "$verify_yarn_monorepo_dry_run_output" "Running test: yarn workspaces foreach --all --parallel --topological run test" "VERIFY dry-run should reuse recursive Yarn test commands"
assert_contains "$verify_yarn_monorepo_dry_run_output" "Running build: yarn workspaces foreach --all --parallel --topological run build" "VERIFY dry-run should reuse recursive Yarn build commands"
pass "VERIFY Yarn monorepo dry-run"

verify_bun_monorepo_dry_run_output="$(run_expect_success "VERIFY dry-run should reuse Bun workspace commands" "$VERIFY_SCRIPT" --target-dir "$TEST_BUN_MONOREPO_DIR" --steps lint,typecheck,test,build --dry-run)"
assert_contains "$verify_bun_monorepo_dry_run_output" "Running lint: bun run --workspaces --if-present --parallel lint" "VERIFY dry-run should reuse recursive Bun lint commands"
assert_contains "$verify_bun_monorepo_dry_run_output" "Running typecheck: bun run --workspaces --if-present --parallel typecheck" "VERIFY dry-run should reuse recursive Bun typecheck commands"
assert_contains "$verify_bun_monorepo_dry_run_output" "Running test: bun run --workspaces --if-present --parallel test" "VERIFY dry-run should reuse recursive Bun test commands"
assert_contains "$verify_bun_monorepo_dry_run_output" "Running build: bun run --workspaces --if-present --parallel build" "VERIFY dry-run should reuse recursive Bun build commands"
pass "VERIFY Bun monorepo dry-run"

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

setup_maui_workspace
maui_inspect_output="$(run_expect_success "INSPECT should summarize .NET MAUI mobile projects" "$INSPECT_SCRIPT" --target-dir "$TEST_MAUI_DIR")"
assert_contains "$maui_inspect_output" "Language profile: csharp (auto-detected)" "INSPECT should detect C# for .NET MAUI projects"
assert_contains "$maui_inspect_output" "Framework profile: maui (auto-detected)" "INSPECT should detect .NET MAUI framework context"
assert_contains "$maui_inspect_output" "Project type: mobile-app (auto-detected)" "INSPECT should classify .NET MAUI repos as mobile apps"
assert_contains "$maui_inspect_output" "Package manager: dotnet" "INSPECT should surface dotnet for .NET MAUI projects"
assert_contains "$maui_inspect_output" "Build: dotnet build" "INSPECT should infer dotnet build commands for .NET MAUI projects"
assert_contains "$maui_inspect_output" "Test: dotnet test" "INSPECT should infer dotnet test commands for .NET MAUI projects"
pass "INSPECT .NET MAUI summary"

setup_expo_workspace
expo_inspect_output="$(run_expect_success "INSPECT should summarize Expo mobile projects" "$INSPECT_SCRIPT" --target-dir "$TEST_EXPO_DIR")"
assert_contains "$expo_inspect_output" "Language profile: typescript (auto-detected)" "INSPECT should detect TypeScript for Expo projects"
assert_contains "$expo_inspect_output" "Framework profile: expo (auto-detected)" "INSPECT should detect Expo framework context"
assert_contains "$expo_inspect_output" "Project type: mobile-app (auto-detected)" "INSPECT should classify Expo repos as mobile apps"
assert_contains "$expo_inspect_output" "Package manager: npm" "INSPECT should surface npm for Expo projects without an explicit lockfile"
assert_contains "$expo_inspect_output" "Dev: npx expo start" "INSPECT should infer Expo dev commands"
assert_contains "$expo_inspect_output" "Typecheck: tsc --noEmit" "INSPECT should preserve TypeScript defaults for Expo projects"
pass "INSPECT Expo summary"

setup_react_native_workspace
react_native_inspect_output="$(run_expect_success "INSPECT should summarize React Native mobile projects" "$INSPECT_SCRIPT" --target-dir "$TEST_REACT_NATIVE_DIR")"
assert_contains "$react_native_inspect_output" "Language profile: typescript (auto-detected)" "INSPECT should detect TypeScript for React Native projects"
assert_contains "$react_native_inspect_output" "Framework profile: react-native (auto-detected)" "INSPECT should detect React Native framework context"
assert_contains "$react_native_inspect_output" "Project type: mobile-app (auto-detected)" "INSPECT should classify React Native repos as mobile apps"
assert_contains "$react_native_inspect_output" "Package manager: npm" "INSPECT should surface npm for React Native projects without an explicit lockfile"
assert_contains "$react_native_inspect_output" "Dev: npx react-native start" "INSPECT should infer React Native dev commands"
assert_contains "$react_native_inspect_output" "Typecheck: tsc --noEmit" "INSPECT should preserve TypeScript defaults for React Native projects"
pass "INSPECT React Native summary"

setup_java_service_workspace
java_service_inspect_output="$(run_expect_success "INSPECT should summarize Gradle-backed Java services" "$INSPECT_SCRIPT" --target-dir "$TEST_JAVA_SERVICE_DIR")"
assert_contains "$java_service_inspect_output" "Language profile: java (auto-detected)" "INSPECT should detect Java for Gradle projects"
assert_contains "$java_service_inspect_output" "Framework profile: spring (auto-detected)" "INSPECT should detect Spring framework context"
assert_contains "$java_service_inspect_output" "Project type: backend-service (auto-detected)" "INSPECT should detect backend services from framework and repo markers"
assert_contains "$java_service_inspect_output" "Package manager: gradle" "INSPECT should surface the Gradle package manager"
assert_contains "$java_service_inspect_output" "Build: gradle build" "INSPECT should infer Gradle build commands"
assert_contains "$java_service_inspect_output" "Test: gradle test" "INSPECT should infer Gradle test commands"
pass "INSPECT Java service summary"

setup_aspnet_workspace
aspnet_inspect_output="$(run_expect_success "INSPECT should summarize ASP.NET Core services" "$INSPECT_SCRIPT" --target-dir "$TEST_ASPNET_DIR")"
assert_contains "$aspnet_inspect_output" "Language profile: csharp (auto-detected)" "INSPECT should detect C# for ASP.NET Core projects"
assert_contains "$aspnet_inspect_output" "Framework profile: aspnet-core (auto-detected)" "INSPECT should detect ASP.NET Core framework context"
assert_contains "$aspnet_inspect_output" "Project type: backend-service (auto-detected)" "INSPECT should classify ASP.NET Core repos as backend services"
assert_contains "$aspnet_inspect_output" "Package manager: dotnet" "INSPECT should surface dotnet as the package manager"
assert_contains "$aspnet_inspect_output" "Dev: dotnet run" "INSPECT should infer dotnet run for ASP.NET Core services"
assert_contains "$aspnet_inspect_output" "Build: dotnet build" "INSPECT should infer dotnet build commands"
assert_contains "$aspnet_inspect_output" "Test: dotnet test" "INSPECT should infer dotnet test commands"
pass "INSPECT ASP.NET Core summary"

setup_elixir_workspace
elixir_inspect_output="$(run_expect_success "INSPECT should summarize Elixir projects" "$INSPECT_SCRIPT" --target-dir "$TEST_ELIXIR_DIR")"
assert_contains "$elixir_inspect_output" "Language profile: elixir (auto-detected)" "INSPECT should detect Elixir projects"
assert_contains "$elixir_inspect_output" "Package manager: mix" "INSPECT should surface the Mix package manager"
assert_contains "$elixir_inspect_output" "Build: mix compile" "INSPECT should infer Mix compile commands"
assert_contains "$elixir_inspect_output" "Test: mix test" "INSPECT should infer Mix test commands"
assert_contains "$elixir_inspect_output" "Lint: mix format --check-formatted" "INSPECT should infer Mix formatting checks"
pass "INSPECT Elixir summary"

setup_scala_workspace
scala_inspect_output="$(run_expect_success "INSPECT should summarize Scala projects" "$INSPECT_SCRIPT" --target-dir "$TEST_SCALA_DIR")"
assert_contains "$scala_inspect_output" "Language profile: scala (auto-detected)" "INSPECT should detect Scala projects"
assert_contains "$scala_inspect_output" "Package manager: sbt" "INSPECT should surface the sbt package manager"
assert_contains "$scala_inspect_output" "Workspace mode: single-package" "INSPECT should classify sbt projects as package-oriented repos"
assert_contains "$scala_inspect_output" "Build: sbt compile" "INSPECT should infer sbt compile commands"
assert_contains "$scala_inspect_output" "Test: sbt test" "INSPECT should infer sbt test commands"
pass "INSPECT Scala summary"

setup_node_cli_workspace
node_cli_inspect_output="$(run_expect_success "INSPECT should summarize non-shell CLI projects" "$INSPECT_SCRIPT" --target-dir "$TEST_NODE_CLI_DIR")"
assert_contains "$node_cli_inspect_output" "Project type: cli-tool (auto-detected)" "INSPECT should detect non-shell CLI repos"
pass "INSPECT Node CLI summary"

setup_lua_workspace
lua_inspect_output="$(run_expect_success "INSPECT should summarize Lua projects" "$INSPECT_SCRIPT" --target-dir "$TEST_LUA_DIR")"
assert_contains "$lua_inspect_output" "Language profile: lua (auto-detected)" "INSPECT should detect Lua projects"
assert_contains "$lua_inspect_output" "Package manager: luarocks" "INSPECT should surface the LuaRocks package manager"
assert_contains "$lua_inspect_output" "Workspace mode: single-package" "INSPECT should classify rockspec repos as package-oriented repos"
assert_contains "$lua_inspect_output" "Build: luarocks make" "INSPECT should infer LuaRocks build commands"
assert_contains "$lua_inspect_output" "Test: luarocks test" "INSPECT should infer LuaRocks test commands"
pass "INSPECT Lua summary"

setup_zig_workspace
zig_inspect_output="$(run_expect_success "INSPECT should summarize Zig projects" "$INSPECT_SCRIPT" --target-dir "$TEST_ZIG_DIR")"
assert_contains "$zig_inspect_output" "Language profile: zig (auto-detected)" "INSPECT should detect Zig projects"
assert_contains "$zig_inspect_output" "Package manager: zig" "INSPECT should surface the Zig package manager"
assert_contains "$zig_inspect_output" "Build: zig build" "INSPECT should infer Zig build commands"
assert_contains "$zig_inspect_output" "Test: zig build test" "INSPECT should infer Zig test commands"
pass "INSPECT Zig summary"

setup_haskell_workspace
haskell_inspect_output="$(run_expect_success "INSPECT should summarize Haskell projects" "$INSPECT_SCRIPT" --target-dir "$TEST_HASKELL_DIR")"
assert_contains "$haskell_inspect_output" "Language profile: haskell (auto-detected)" "INSPECT should detect Haskell projects"
assert_contains "$haskell_inspect_output" "Package manager: stack" "INSPECT should surface the Stack package manager"
assert_contains "$haskell_inspect_output" "Build: stack build" "INSPECT should infer Stack build commands"
assert_contains "$haskell_inspect_output" "Test: stack test" "INSPECT should infer Stack test commands"
pass "INSPECT Haskell summary"

setup_data_pipeline_workspace
data_pipeline_inspect_output="$(run_expect_success "INSPECT should summarize data pipeline projects" "$INSPECT_SCRIPT" --target-dir "$TEST_DATA_PIPELINE_DIR")"
assert_contains "$data_pipeline_inspect_output" "Project type: data-pipeline (auto-detected)" "INSPECT should detect pipeline-oriented repos"
assert_contains "$data_pipeline_inspect_output" "dags: scheduled DAG definitions or orchestration entrypoints" "INSPECT should expose pipeline structure hints"
assert_contains "$data_pipeline_inspect_output" "Scheduling, idempotency, backfill behavior, and data contracts can fail long after a code change lands." "INSPECT should surface pipeline risk areas"
pass "INSPECT data pipeline summary"

setup_r_shiny_workspace
r_shiny_inspect_output="$(run_expect_success "INSPECT should summarize R Shiny projects" "$INSPECT_SCRIPT" --target-dir "$TEST_R_SHINY_DIR")"
assert_contains "$r_shiny_inspect_output" "Language profile: r (auto-detected)" "INSPECT should detect R projects"
assert_contains "$r_shiny_inspect_output" "Framework profile: shiny (auto-detected)" "INSPECT should detect Shiny apps"
assert_contains "$r_shiny_inspect_output" "Project type: web-app (auto-detected)" "INSPECT should classify Shiny apps as web apps"
assert_contains "$r_shiny_inspect_output" "Package manager: r" "INSPECT should surface the R package manager"
assert_contains "$r_shiny_inspect_output" 'Dev: Rscript -e "shiny::runApp(\".\", launch.browser = FALSE)"' "INSPECT should infer a Shiny dev command"
assert_contains "$r_shiny_inspect_output" 'Test: Rscript -e "testthat::test_local()"' "INSPECT should infer testthat commands"
assert_contains "$r_shiny_inspect_output" 'Lint: Rscript -e "lintr::lint_dir(\".\")"' "INSPECT should infer lintr commands"
pass "INSPECT R Shiny summary"

setup_terraform_workspace
terraform_inspect_output="$(run_expect_success "INSPECT should summarize Terraform infrastructure projects" "$INSPECT_SCRIPT" --target-dir "$TEST_TERRAFORM_DIR")"
assert_contains "$terraform_inspect_output" "Language profile: terraform (auto-detected)" "INSPECT should detect Terraform projects"
assert_contains "$terraform_inspect_output" "Project type: infrastructure (auto-detected)" "INSPECT should classify Terraform repos as infrastructure"
assert_contains "$terraform_inspect_output" "Package manager: terraform" "INSPECT should surface the Terraform package manager"
assert_contains "$terraform_inspect_output" "Workspace mode: single-package" "INSPECT should classify Terraform repos as package-oriented repos"
assert_contains "$terraform_inspect_output" "Lint: terraform fmt -check -recursive" "INSPECT should infer terraform fmt checks"
assert_contains "$terraform_inspect_output" "Typecheck: terraform validate" "INSPECT should infer terraform validation commands"
assert_contains "$terraform_inspect_output" "Test: terraform test" "INSPECT should infer terraform test commands"
pass "INSPECT Terraform summary"

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
