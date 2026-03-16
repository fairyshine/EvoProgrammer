#!/usr/bin/env bash

setup_agent_test_workspace

help_output="$(run_expect_success "LOOP help should succeed" "$LOOP_SCRIPT" --help)"
assert_contains "$help_output" "Usage: ./LOOP.sh [options] [prompt]" "LOOP help output should mention options usage"
pass "LOOP help"

missing_codex_output="$(run_expect_failure "LOOP should fail without codex" env HOME="$HOME" PATH="/usr/bin:/bin" "$LOOP_SCRIPT" --prompt "test")"
assert_contains "$missing_codex_output" "The 'codex' CLI is required" "LOOP should report missing codex"
pass "LOOP missing codex"

bad_target_output="$(run_expect_failure "LOOP should fail for missing target directory" env PATH="$PATH" "$LOOP_SCRIPT" --target-dir "$TEST_TMPDIR/does-not-exist" --prompt "test")"
assert_contains "$bad_target_output" "Target directory does not exist" "LOOP should validate target directory"
pass "LOOP target-dir validation"

bad_language_output="$(run_expect_failure "LOOP should reject unsupported language profiles" env PATH="$PATH" "$LOOP_SCRIPT" --language elixir --prompt "test")"
assert_contains "$bad_language_output" "Unsupported language profile: elixir" "LOOP should validate language profiles"
pass "LOOP language profile validation"

bad_framework_output="$(run_expect_failure "LOOP should reject unsupported framework profiles" env PATH="$PATH" "$LOOP_SCRIPT" --framework hibernate --prompt "test")"
assert_contains "$bad_framework_output" "Unsupported framework profile: hibernate" "LOOP should validate framework profiles"
pass "LOOP framework profile validation"

bad_project_type_output="$(run_expect_failure "LOOP should reject unsupported project types" env PATH="$PATH" "$LOOP_SCRIPT" --project-type unknown-project --prompt "test")"
assert_contains "$bad_project_type_output" "Unsupported project type: unknown-project" "LOOP should validate project types"
pass "LOOP project-type validation"

gdscript_profile_output="$(run_expect_success "LOOP should accept gdscript and godot profiles" env PATH="/usr/bin:/bin" "$LOOP_SCRIPT" --language gdscript --framework godot --dry-run --prompt "test")"
assert_contains "$gdscript_profile_output" "Target language: gdscript" "LOOP should accept the gdscript language profile"
assert_contains "$gdscript_profile_output" "Target framework: godot" "LOOP should accept the godot framework profile"
pass "LOOP gdscript/godot profile support"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop.log"
export FAKE_CODEX_LOG
run_expect_success "LOOP should invoke codex with prompt and target directory" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --target-dir "$TEST_TARGET_DIR" --prompt "ship it" >/dev/null
loop_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_log" "cwd=$TEST_TARGET_DIR" "LOOP should run codex in the requested target directory"
assert_contains "$loop_log" "arg=exec" "LOOP should call codex exec"
assert_contains "$loop_log" "arg=--dangerously-bypass-approvals-and-sandbox" "LOOP should bypass codex sandboxing by default"
assert_contains "$loop_log" "arg=--cd" "LOOP should tell codex which directory is the workspace root"
assert_contains "$loop_log" "arg=$TEST_TARGET_DIR_PHYSICAL" "LOOP should pass the target directory to codex"
assert_contains "$loop_log" "arg=--add-dir" "LOOP should allow codex to write to the target directory"
assert_contains "$loop_log" "arg=ship it" "LOOP should forward the prompt"
pass "LOOP execution wiring"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/loop-profiles.log"
export FAKE_CLAUDE_LOG
run_expect_success "LOOP should inject language, framework, and project-type guidance into the prompt" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$TEST_TARGET_DIR" --language python --framework fastapi --project-type mobile-game --prompt "ship it" >/dev/null
loop_profiles_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$loop_profiles_log" "[Language Adaptation]" "LOOP should prepend language adaptation guidance"
assert_contains "$loop_profiles_log" "Target language: python" "LOOP should name the selected language profile"
assert_profile_guidance_in_output "$loop_profiles_log" "languages" "python" "LOOP should inject the Python profile guidance"
assert_contains "$loop_profiles_log" "[Framework Adaptation]" "LOOP should prepend framework adaptation guidance"
assert_contains "$loop_profiles_log" "Target framework: fastapi" "LOOP should name the selected framework profile"
assert_profile_guidance_in_output "$loop_profiles_log" "frameworks" "fastapi" "LOOP should inject the FastAPI profile guidance"
assert_contains "$loop_profiles_log" "[Project-Type Adaptation]" "LOOP should prepend project-type guidance"
assert_contains "$loop_profiles_log" "Target project type: mobile-game" "LOOP should name the selected project type"
assert_profile_guidance_in_output "$loop_profiles_log" "project-types" "mobile-game" "LOOP should inject the mobile-game project-type guidance"
assert_contains "$loop_profiles_log" "[User Request]" "LOOP should keep the user request section"
assert_contains "$loop_profiles_log" "ship it" "LOOP should preserve the original user request inside the final prompt"
pass "LOOP prompt adaptation"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/loop-react-profiles.log"
export FAKE_CLAUDE_LOG
run_expect_success "LOOP should inject richer TypeScript and React guidance into the prompt" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$TEST_TARGET_DIR" --language typescript --framework react --prompt "refine the settings form" >/dev/null
loop_react_profiles_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$loop_react_profiles_log" "Target language: typescript" "LOOP should name the selected TypeScript profile"
assert_profile_guidance_in_output "$loop_react_profiles_log" "languages" "typescript" "LOOP should inject the TypeScript profile guidance"
assert_contains "$loop_react_profiles_log" "Target framework: react" "LOOP should name the selected React profile"
assert_profile_guidance_in_output "$loop_react_profiles_log" "frameworks" "react" "LOOP should inject the React profile guidance"
pass "LOOP react/typescript prompt adaptation"

auto_detect_dir="$TEST_TMPDIR/auto-detect-rust"
mkdir -p "$auto_detect_dir"
printf '[package]\nname = "arena"\nversion = "0.1.0"\n[dependencies]\nbevy = "0.1"\n' >"$auto_detect_dir/Cargo.toml"
FAKE_CLAUDE_LOG="$TEST_TMPDIR/loop-auto-detect.log"
export FAKE_CLAUDE_LOG
loop_auto_detect_output="$(run_expect_success "LOOP should auto-detect language and project type" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$auto_detect_dir" --prompt "build a multiplayer arena prototype")"
loop_auto_detect_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$loop_auto_detect_output" "Language profile: rust (auto-detected)" "LOOP should report an auto-detected language profile"
assert_contains "$loop_auto_detect_output" "Framework profile: bevy (auto-detected)" "LOOP should report an auto-detected framework profile"
assert_contains "$loop_auto_detect_output" "Project type: online-game (auto-detected)" "LOOP should report an auto-detected project type"
assert_contains "$loop_auto_detect_log" "Target language: rust" "LOOP should auto-detect Rust from the repository"
assert_contains "$loop_auto_detect_log" "Target framework: bevy" "LOOP should auto-detect Bevy from the repository"
assert_contains "$loop_auto_detect_log" "Target project type: online-game" "LOOP should auto-detect an online game from the prompt"
pass "LOOP auto detection"

setup_context_workspace
FAKE_CLAUDE_LOG="$TEST_TMPDIR/context.log"
export FAKE_CLAUDE_LOG
context_loop_output="$(run_expect_success "LOOP should analyze repository context and surface it to the agent" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$TEST_CONTEXT_DIR" --prompt "add a billing dashboard feature")"
context_loop_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$context_loop_output" "Package manager: pnpm" "LOOP should print the detected package manager"
assert_contains "$context_loop_output" "Workspace mode: monorepo" "LOOP should print the detected workspace mode"
assert_contains "$context_loop_output" "Test command: pnpm test" "LOOP should print the detected test command"
assert_contains "$context_loop_output" "Task kind: feature" "LOOP should print the inferred task kind"
assert_contains "$context_loop_log" "[Repository Context]" "LOOP should prepend repository context guidance"
assert_contains "$context_loop_log" "Package manager: pnpm" "LOOP should inject the detected package manager into the prompt"
assert_contains "$context_loop_log" "Suggested commands:" "LOOP should inject recommended commands into the prompt"
assert_contains "$context_loop_log" "Architecture hints:" "LOOP should inject structure hints into the prompt"
assert_contains "$context_loop_log" "src/components: shared UI components" "LOOP should point the agent to key UI directories"
assert_contains "$context_loop_log" "Conventions to preserve:" "LOOP should inject repository conventions into the prompt"
assert_contains "$context_loop_log" "TypeScript strict mode is enabled." "LOOP should surface strict TypeScript configuration"
assert_contains "$context_loop_log" "Risk areas:" "LOOP should inject high-risk areas into the prompt"
assert_contains "$context_loop_log" "Database schema, migrations, and persistence contracts need careful coordination." "LOOP should flag database-related risk areas"
assert_contains "$context_loop_log" "Validation plan:" "LOOP should inject a validation plan into the prompt"
assert_contains "$context_loop_log" "Run lint first: pnpm lint" "LOOP should recommend lint validation when available"
assert_contains "$context_loop_log" "Similar implementation starting points: packages, src/app, src/components" "LOOP should point the agent at likely search roots"
assert_contains "$context_loop_log" "[Recommended Workflow]" "LOOP should inject a task-specific workflow"
assert_contains "$context_loop_log" "Find the nearest existing implementation first" "LOOP should adapt workflow guidance to feature work"
assert_contains "$context_loop_log" "Search strategy:" "LOOP should inject a structured search strategy"
assert_contains "$context_loop_log" "Inspect user-facing routes, components, client state, and API integration paths first." "LOOP should adapt search strategy to web apps"
assert_contains "$context_loop_log" "Edit strategy:" "LOOP should inject a structured edit strategy"
assert_contains "$context_loop_log" "Change user flows end-to-end: types, data loading, loading or error states, and UI tests together." "LOOP should adapt edit strategy to web apps"
assert_contains "$context_loop_log" "Verification strategy:" "LOOP should inject a structured verification strategy"
assert_contains "$context_loop_log" "Use the repository verification chain in this order: lint -> typecheck -> test -> build" "LOOP should inject ordered verification workflow"
assert_contains "$context_loop_log" "Risk focus:" "LOOP should inject a structured risk focus"
assert_contains "$context_loop_log" "Routing, auth, caching, and shared frontend contracts deserve extra scrutiny." "LOOP should adapt risk focus to web apps"
context_artifact_dir="$(find "$TEST_CONTEXT_DIR/.evoprogrammer/runs" -maxdepth 1 -type d -name 'run-*' | sort | tail -n 1)"
context_metadata="$(cat "$context_artifact_dir/metadata.env")"
assert_contains "$context_metadata" "PACKAGE_MANAGER=pnpm" "LOOP metadata should record the detected package manager"
assert_contains "$context_metadata" "WORKSPACE_MODE=monorepo" "LOOP metadata should record the workspace mode"
assert_contains "$context_metadata" "TEST_COMMAND=pnpm\\ test" "LOOP metadata should record the suggested test command"
assert_contains "$context_metadata" "TASK_KIND=feature" "LOOP metadata should record the inferred task kind"
assert_contains "$context_metadata" "SEARCH_STRATEGY=" "LOOP metadata should record the structured search strategy"
assert_contains "$context_metadata" "VERIFICATION_STRATEGY=" "LOOP metadata should record the structured verification strategy"
assert_contains "$context_metadata" "RISK_FOCUS=" "LOOP metadata should record the structured risk focus"
pass "LOOP repository context analysis"

auto_godot_dir="$TEST_TMPDIR/auto-detect-godot"
mkdir -p "$auto_godot_dir"
printf '; Engine configuration file.\n[application]\nconfig/name="Arena"\n' >"$auto_godot_dir/project.godot"
printf 'extends Node2D\n\nfunc _ready() -> void:\n    print("ready")\n' >"$auto_godot_dir/main.gd"
FAKE_CLAUDE_LOG="$TEST_TMPDIR/loop-auto-godot.log"
export FAKE_CLAUDE_LOG
loop_auto_godot_output="$(run_expect_success "LOOP should auto-detect GDScript and Godot" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$auto_godot_dir" --prompt "build the first playable godot arena loop")"
loop_auto_godot_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$loop_auto_godot_output" "Language profile: gdscript (auto-detected)" "LOOP should auto-detect GDScript from a Godot project"
assert_contains "$loop_auto_godot_output" "Framework profile: godot (auto-detected)" "LOOP should auto-detect Godot from the repository"
assert_contains "$loop_auto_godot_log" "Target language: gdscript" "LOOP should inject GDScript guidance when auto-detected"
assert_contains "$loop_auto_godot_log" "Target framework: godot" "LOOP should inject Godot guidance when auto-detected"
pass "LOOP godot auto detection"

loop_artifact_dir="$(find "$TEST_DEFAULT_ARTIFACTS_ROOT" -maxdepth 2 -type f -name 'codex.log' | sort | head -n 1 | xargs dirname)"
assert_directory_exists "$loop_artifact_dir" "LOOP should create a default artifacts directory"
assert_file_exists "$loop_artifact_dir/prompt.txt" "LOOP artifacts should include the resolved prompt"
assert_file_exists "$loop_artifact_dir/command.txt" "LOOP artifacts should include the codex command"
assert_file_exists "$loop_artifact_dir/metadata.env" "LOOP artifacts should include run metadata"
assert_file_exists "$loop_artifact_dir/codex.log" "LOOP artifacts should include a combined codex log"
loop_artifact_metadata="$(cat "$loop_artifact_dir/metadata.env")"
assert_contains "$loop_artifact_metadata" "STATUS=0" "LOOP metadata should record a successful exit status"
assert_contains "$loop_artifact_metadata" "AGENT=codex" "LOOP metadata should record the selected agent"
loop_artifact_log="$(cat "$loop_artifact_dir/codex.log")"
assert_contains "$loop_artifact_log" "fake codex output for exec --dangerously-bypass-approvals-and-sandbox --cd $TEST_TARGET_DIR_PHYSICAL --add-dir $TEST_TARGET_DIR_PHYSICAL ship it" "LOOP artifacts should capture command output"
pass "LOOP artifacts"

loop_profiles_artifact_dir="$(find "$TEST_DEFAULT_ARTIFACTS_ROOT" -maxdepth 2 -type f -name 'claude.log' | sort | head -n 1 | xargs dirname)"
loop_profiles_prompt="$(cat "$loop_profiles_artifact_dir/prompt.txt")"
assert_contains "$loop_profiles_prompt" "Target language: python" "LOOP prompt artifacts should record the language guidance"
assert_contains "$loop_profiles_prompt" "Target framework: fastapi" "LOOP prompt artifacts should record the framework guidance"
assert_contains "$loop_profiles_prompt" "Target project type: mobile-game" "LOOP prompt artifacts should record the project-type guidance"
pass "LOOP prompt artifacts"

assert_file_exists "$TEST_EXCLUDE_FILE" "LOOP should create a local git exclude file when the target is a git repo"
exclude_contents="$(cat "$TEST_EXCLUDE_FILE")"
assert_contains "$exclude_contents" ".evoprogrammer/" "LOOP should locally exclude EvoProgrammer artifacts from future runs"
pass "LOOP git exclude"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop-codex-args.log"
export FAKE_CODEX_LOG
run_expect_success "LOOP should forward extra codex exec arguments" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --target-dir "$TEST_TARGET_DIR" --codex-arg "--model" --codex-arg "gpt-5" --prompt "ship it" >/dev/null
loop_codex_args_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_codex_args_log" "arg=--model" "LOOP should pass through codex option names"
assert_contains "$loop_codex_args_log" "arg=gpt-5" "LOOP should pass through codex option values"
assert_contains "$loop_codex_args_log" "arg=ship it" "LOOP should keep the prompt as the final codex argument"
pass "LOOP codex-arg forwarding"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/loop-agent-args-list.log"
export FAKE_CLAUDE_LOG
run_expect_success "LOOP should parse list-style agent args" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$TEST_TARGET_DIR" --agent-args "[\"--model\",\"sonnet\"]" --prompt "ship it" >/dev/null
loop_agent_args_list_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$loop_agent_args_list_log" "arg=--model" "LOOP should parse list-style agent arg names"
assert_contains "$loop_agent_args_list_log" "arg=sonnet" "LOOP should parse list-style agent arg values"
assert_contains "$loop_agent_args_list_log" "arg=ship it" "LOOP should keep the prompt after list-style agent args"
pass "LOOP agent-args list"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop-prompt-file.log"
export FAKE_CODEX_LOG
run_expect_success "LOOP should load prompts from a file" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --target-dir "$TEST_TARGET_DIR" --prompt-file "$TEST_PROMPT_FILE" >/dev/null
loop_prompt_file_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_prompt_file_log" "arg=ship from file" "LOOP should read the prompt contents from disk"
pass "LOOP prompt-file"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/loop-claude.log"
export FAKE_CLAUDE_LOG
run_expect_success "LOOP should support Claude Code as an agent" env PATH="$TEST_FAKE_BIN:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$TEST_TARGET_DIR" --agent-arg "--model" --agent-arg "sonnet" --prompt "ship it" >/dev/null
loop_claude_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$loop_claude_log" "cwd=$TEST_TARGET_DIR" "LOOP should run claude in the requested target directory"
assert_contains "$loop_claude_log" "arg=--print" "LOOP should call claude in print mode"
assert_contains "$loop_claude_log" "arg=--dangerously-skip-permissions" "LOOP should bypass claude permissions by default"
assert_contains "$loop_claude_log" "arg=--model" "LOOP should forward extra Claude arguments"
assert_contains "$loop_claude_log" "arg=sonnet" "LOOP should forward Claude argument values"
assert_contains "$loop_claude_log" "arg=ship it" "LOOP should forward the prompt to claude"
loop_claude_artifact_dir="$(find "$TEST_DEFAULT_ARTIFACTS_ROOT" -maxdepth 1 -type d -name 'run-*' | sort | tail -n 1)"
assert_file_exists "$loop_claude_artifact_dir/claude.log" "LOOP should capture Claude output in a tool-specific log file"
loop_claude_metadata="$(cat "$loop_claude_artifact_dir/metadata.env")"
assert_contains "$loop_claude_metadata" "AGENT=claude" "LOOP metadata should record the Claude agent"
pass "LOOP claude agent"

loop_dry_run_output="$(run_expect_success "LOOP dry-run should succeed without codex" env PATH="/usr/bin:/bin" "$LOOP_SCRIPT" --target-dir "$TEST_TARGET_DIR" --prompt "preview only" --dry-run)"
assert_contains "$loop_dry_run_output" "Agent: codex" "LOOP dry-run should print the selected agent"
assert_contains "$loop_dry_run_output" "Artifacts root: $TEST_TARGET_DIR/.evoprogrammer/runs" "LOOP dry-run should print the default artifacts root"
assert_contains "$loop_dry_run_output" "Target directory: $TEST_TARGET_DIR" "LOOP dry-run should print the target directory"
assert_contains "$loop_dry_run_output" "codex exec" "LOOP dry-run should print the codex command"
assert_contains "$loop_dry_run_output" "--dangerously-bypass-approvals-and-sandbox" "LOOP dry-run should show the codex sandbox bypass"
assert_contains "$loop_dry_run_output" "--cd $TEST_TARGET_DIR_PHYSICAL" "LOOP dry-run should show the codex workspace root"
assert_contains "$loop_dry_run_output" "--add-dir $TEST_TARGET_DIR_PHYSICAL" "LOOP dry-run should show the writable target directory"
assert_contains "$loop_dry_run_output" "preview\\ only" "LOOP dry-run should keep the prompt in the command preview"
pass "LOOP dry-run"

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
