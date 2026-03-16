#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOOP_SCRIPT="$ROOT_DIR/LOOP.sh"
MAIN_SCRIPT="$ROOT_DIR/MAIN.sh"
CLI_SCRIPT="$ROOT_DIR/bin/EvoProgrammer"
INSTALL_SCRIPT="$ROOT_DIR/install.sh"
DOCTOR_SCRIPT="$ROOT_DIR/DOCTOR.sh"
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

PASS_COUNT=0

fail() {
    echo "FAIL: $1" >&2
    exit 1
}

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    echo "PASS: $1"
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local context="$3"
    if [[ "$haystack" != *"$needle"* ]]; then
        fail "$context"
    fi
}

assert_equals() {
    local actual="$1"
    local expected="$2"
    local context="$3"
    if [[ "$actual" != "$expected" ]]; then
        printf 'Expected: %s\nActual: %s\n' "$expected" "$actual" >&2
        fail "$context"
    fi
}

assert_file_exists() {
    local path="$1"
    local context="$2"
    if [[ ! -f "$path" ]]; then
        fail "$context"
    fi
}

assert_directory_exists() {
    local path="$1"
    local context="$2"
    if [[ ! -d "$path" ]]; then
        fail "$context"
    fi
}

run_expect_success() {
    local name="$1"
    shift
    local output
    if ! output="$("$@" 2>&1)"; then
        printf '%s\n' "$output" >&2
        fail "$name"
    fi
    printf '%s' "$output"
}

run_expect_failure() {
    local name="$1"
    shift
    local output
    if output="$("$@" 2>&1)"; then
        printf '%s\n' "$output" >&2
        fail "$name"
    fi
    printf '%s' "$output"
}

setup_fake_codex() {
    local bin_dir="$TEST_TMPDIR/bin"
    mkdir -p "$bin_dir"
    cat >"$bin_dir/codex" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'fake codex output for %s\n' "$*"
printf 'cwd=%s\n' "$PWD" >>"${FAKE_CODEX_LOG:?}"
printf 'argc=%s\n' "$#" >>"${FAKE_CODEX_LOG:?}"
for arg in "$@"; do
    printf 'arg=%s\n' "$arg" >>"${FAKE_CODEX_LOG:?}"
done
if [[ "${FAKE_CODEX_FAIL:-0}" == "1" ]]; then
    exit 23
fi
EOF
    chmod +x "$bin_dir/codex"
    printf '%s' "$bin_dir"
}

setup_fake_claude() {
    local bin_dir="$TEST_TMPDIR/bin"
    mkdir -p "$bin_dir"
    cat >"$bin_dir/claude" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf 'fake claude output for %s\n' "$*"
printf 'cwd=%s\n' "$PWD" >>"${FAKE_CLAUDE_LOG:?}"
printf 'argc=%s\n' "$#" >>"${FAKE_CLAUDE_LOG:?}"
for arg in "$@"; do
    printf 'arg=%s\n' "$arg" >>"${FAKE_CLAUDE_LOG:?}"
done
if [[ "${FAKE_CLAUDE_FAIL:-0}" == "1" ]]; then
    exit 29
fi
EOF
    chmod +x "$bin_dir/claude"
    printf '%s' "$bin_dir"
}

profile_catalog_output="$(
    ROOT_DIR="$ROOT_DIR" bash <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

count_lines() {
    awk 'NF { count++ } END { print count + 0 }'
}

for category in languages frameworks project-types; do
    catalog_count="$(evop_supported_profiles_for_category "$category" | count_lines)"
    definition_count="$(find "$ROOT_DIR/lib/profiles/definitions/$category" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/profile.sh' ';' -print | count_lines)"

    if [[ "$catalog_count" != "$definition_count" ]]; then
        printf 'mismatch:%s:%s:%s\n' "$category" "$catalog_count" "$definition_count" >&2
        exit 1
    fi
done

printf 'languages=%s\n' "$(evop_supported_profiles_as_string languages)"
printf 'frameworks=%s\n' "$(evop_supported_profiles_as_string frameworks)"
printf 'project-types=%s\n' "$(evop_supported_profiles_as_string project-types)"
EOF
)"
assert_contains "$profile_catalog_output" "languages=cpp" "Profile catalog should expose discovered language profiles"
assert_contains "$profile_catalog_output" "typescript" "Profile catalog should include TypeScript"
assert_contains "$profile_catalog_output" "frameworks=actix-web" "Profile catalog should expose discovered framework profiles"
assert_contains "$profile_catalog_output" "nextjs" "Profile catalog should include Next.js"
assert_contains "$profile_catalog_output" "project-types=ai-agent" "Profile catalog should expose discovered project types"
assert_contains "$profile_catalog_output" "web-app" "Profile catalog should include web-app"
pass "Profile catalog matches on-disk definitions"

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
fake_bin="$(setup_fake_codex)"
setup_fake_claude >/dev/null
target_dir="$TEST_TMPDIR/project"
mkdir -p "$target_dir"
git init -q "$target_dir"
target_dir_physical="$(cd "$target_dir" && pwd -P)"
prompt_file="$TEST_TMPDIR/prompt.txt"
printf 'ship from file' >"$prompt_file"
run_expect_success "LOOP should invoke codex with prompt and target directory" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --target-dir "$target_dir" --prompt "ship it" >/dev/null
loop_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_log" "cwd=$target_dir" "LOOP should run codex in the requested target directory"
assert_contains "$loop_log" "arg=exec" "LOOP should call codex exec"
assert_contains "$loop_log" "arg=--dangerously-bypass-approvals-and-sandbox" "LOOP should bypass codex sandboxing by default"
assert_contains "$loop_log" "arg=--cd" "LOOP should tell codex which directory is the workspace root"
assert_contains "$loop_log" "arg=$target_dir_physical" "LOOP should pass the target directory to codex"
assert_contains "$loop_log" "arg=--add-dir" "LOOP should allow codex to write to the target directory"
assert_contains "$loop_log" "arg=ship it" "LOOP should forward the prompt"
pass "LOOP execution wiring"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/loop-profiles.log"
export FAKE_CLAUDE_LOG
run_expect_success "LOOP should inject language, framework, and project-type guidance into the prompt" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$target_dir" --language python --framework fastapi --project-type mobile-game --prompt "ship it" >/dev/null
loop_profiles_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$loop_profiles_log" "[Language Adaptation]" "LOOP should prepend language adaptation guidance"
assert_contains "$loop_profiles_log" "Target language: python" "LOOP should name the selected language profile"
assert_contains "$loop_profiles_log" "[Framework Adaptation]" "LOOP should prepend framework adaptation guidance"
assert_contains "$loop_profiles_log" "Target framework: fastapi" "LOOP should name the selected framework profile"
assert_contains "$loop_profiles_log" "[Project-Type Adaptation]" "LOOP should prepend project-type guidance"
assert_contains "$loop_profiles_log" "Target project type: mobile-game" "LOOP should name the selected project type"
assert_contains "$loop_profiles_log" "[User Request]" "LOOP should keep the user request section"
assert_contains "$loop_profiles_log" "ship it" "LOOP should preserve the original user request inside the final prompt"
pass "LOOP prompt adaptation"

auto_detect_dir="$TEST_TMPDIR/auto-detect-rust"
mkdir -p "$auto_detect_dir"
printf '[package]\nname = "arena"\nversion = "0.1.0"\n[dependencies]\nbevy = "0.1"\n' >"$auto_detect_dir/Cargo.toml"
FAKE_CLAUDE_LOG="$TEST_TMPDIR/loop-auto-detect.log"
export FAKE_CLAUDE_LOG
loop_auto_detect_output="$(run_expect_success "LOOP should auto-detect language and project type" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$auto_detect_dir" --prompt "build a multiplayer arena prototype")"
loop_auto_detect_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$loop_auto_detect_output" "Language profile: rust (auto-detected)" "LOOP should report an auto-detected language profile"
assert_contains "$loop_auto_detect_output" "Framework profile: bevy (auto-detected)" "LOOP should report an auto-detected framework profile"
assert_contains "$loop_auto_detect_output" "Project type: online-game (auto-detected)" "LOOP should report an auto-detected project type"
assert_contains "$loop_auto_detect_log" "Target language: rust" "LOOP should auto-detect Rust from the repository"
assert_contains "$loop_auto_detect_log" "Target framework: bevy" "LOOP should auto-detect Bevy from the repository"
assert_contains "$loop_auto_detect_log" "Target project type: online-game" "LOOP should auto-detect an online game from the prompt"
pass "LOOP auto detection"

auto_godot_dir="$TEST_TMPDIR/auto-detect-godot"
mkdir -p "$auto_godot_dir"
printf '; Engine configuration file.\n[application]\nconfig/name="Arena"\n' >"$auto_godot_dir/project.godot"
printf 'extends Node2D\n\nfunc _ready() -> void:\n    print("ready")\n' >"$auto_godot_dir/main.gd"
FAKE_CLAUDE_LOG="$TEST_TMPDIR/loop-auto-godot.log"
export FAKE_CLAUDE_LOG
loop_auto_godot_output="$(run_expect_success "LOOP should auto-detect GDScript and Godot" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$auto_godot_dir" --prompt "build the first playable godot arena loop")"
loop_auto_godot_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$loop_auto_godot_output" "Language profile: gdscript (auto-detected)" "LOOP should auto-detect GDScript from a Godot project"
assert_contains "$loop_auto_godot_output" "Framework profile: godot (auto-detected)" "LOOP should auto-detect Godot from the repository"
assert_contains "$loop_auto_godot_log" "Target language: gdscript" "LOOP should inject GDScript guidance when auto-detected"
assert_contains "$loop_auto_godot_log" "Target framework: godot" "LOOP should inject Godot guidance when auto-detected"
pass "LOOP godot auto detection"

default_artifacts_root="$target_dir/.evoprogrammer/runs"
loop_artifact_dir="$(find "$default_artifacts_root" -maxdepth 2 -type f -name 'codex.log' | sort | head -n 1 | xargs dirname)"
assert_directory_exists "$loop_artifact_dir" "LOOP should create a default artifacts directory"
assert_file_exists "$loop_artifact_dir/prompt.txt" "LOOP artifacts should include the resolved prompt"
assert_file_exists "$loop_artifact_dir/command.txt" "LOOP artifacts should include the codex command"
assert_file_exists "$loop_artifact_dir/metadata.env" "LOOP artifacts should include run metadata"
assert_file_exists "$loop_artifact_dir/codex.log" "LOOP artifacts should include a combined codex log"
loop_artifact_metadata="$(cat "$loop_artifact_dir/metadata.env")"
assert_contains "$loop_artifact_metadata" "STATUS=0" "LOOP metadata should record a successful exit status"
assert_contains "$loop_artifact_metadata" "AGENT=codex" "LOOP metadata should record the selected agent"
loop_artifact_log="$(cat "$loop_artifact_dir/codex.log")"
assert_contains "$loop_artifact_log" "fake codex output for exec --dangerously-bypass-approvals-and-sandbox --cd $target_dir_physical --add-dir $target_dir_physical ship it" "LOOP artifacts should capture command output"
pass "LOOP artifacts"

loop_profiles_artifact_dir="$(find "$default_artifacts_root" -maxdepth 2 -type f -name 'claude.log' | sort | head -n 1 | xargs dirname)"
loop_profiles_prompt="$(cat "$loop_profiles_artifact_dir/prompt.txt")"
assert_contains "$loop_profiles_prompt" "Target language: python" "LOOP prompt artifacts should record the language guidance"
assert_contains "$loop_profiles_prompt" "Target framework: fastapi" "LOOP prompt artifacts should record the framework guidance"
assert_contains "$loop_profiles_prompt" "Target project type: mobile-game" "LOOP prompt artifacts should record the project-type guidance"
pass "LOOP prompt artifacts"

exclude_file="$target_dir/.git/info/exclude"
assert_file_exists "$exclude_file" "LOOP should create a local git exclude file when the target is a git repo"
exclude_contents="$(cat "$exclude_file")"
assert_contains "$exclude_contents" ".evoprogrammer/" "LOOP should locally exclude EvoProgrammer artifacts from future runs"
pass "LOOP git exclude"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop-codex-args.log"
export FAKE_CODEX_LOG
run_expect_success "LOOP should forward extra codex exec arguments" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --target-dir "$target_dir" --codex-arg "--model" --codex-arg "gpt-5" --prompt "ship it" >/dev/null
loop_codex_args_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_codex_args_log" "arg=--model" "LOOP should pass through codex option names"
assert_contains "$loop_codex_args_log" "arg=gpt-5" "LOOP should pass through codex option values"
assert_contains "$loop_codex_args_log" "arg=ship it" "LOOP should keep the prompt as the final codex argument"
pass "LOOP codex-arg forwarding"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/loop-agent-args-list.log"
export FAKE_CLAUDE_LOG
run_expect_success "LOOP should parse list-style agent args" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$target_dir" --agent-args "[\"--model\",\"sonnet\"]" --prompt "ship it" >/dev/null
loop_agent_args_list_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$loop_agent_args_list_log" "arg=--model" "LOOP should parse list-style agent arg names"
assert_contains "$loop_agent_args_list_log" "arg=sonnet" "LOOP should parse list-style agent arg values"
assert_contains "$loop_agent_args_list_log" "arg=ship it" "LOOP should keep the prompt after list-style agent args"
pass "LOOP agent-args list"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop-prompt-file.log"
export FAKE_CODEX_LOG
run_expect_success "LOOP should load prompts from a file" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --target-dir "$target_dir" --prompt-file "$prompt_file" >/dev/null
loop_prompt_file_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_prompt_file_log" "arg=ship from file" "LOOP should read the prompt contents from disk"
pass "LOOP prompt-file"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/loop-claude.log"
export FAKE_CLAUDE_LOG
run_expect_success "LOOP should support Claude Code as an agent" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --agent claude --target-dir "$target_dir" --agent-arg "--model" --agent-arg "sonnet" --prompt "ship it" >/dev/null
loop_claude_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$loop_claude_log" "cwd=$target_dir" "LOOP should run claude in the requested target directory"
assert_contains "$loop_claude_log" "arg=--print" "LOOP should call claude in print mode"
assert_contains "$loop_claude_log" "arg=--dangerously-skip-permissions" "LOOP should bypass claude permissions by default"
assert_contains "$loop_claude_log" "arg=--model" "LOOP should forward extra Claude arguments"
assert_contains "$loop_claude_log" "arg=sonnet" "LOOP should forward Claude argument values"
assert_contains "$loop_claude_log" "arg=ship it" "LOOP should forward the prompt to claude"
loop_claude_artifact_dir="$(find "$default_artifacts_root" -maxdepth 1 -type d -name 'run-*' | sort | tail -n 1)"
assert_file_exists "$loop_claude_artifact_dir/claude.log" "LOOP should capture Claude output in a tool-specific log file"
loop_claude_metadata="$(cat "$loop_claude_artifact_dir/metadata.env")"
assert_contains "$loop_claude_metadata" "AGENT=claude" "LOOP metadata should record the Claude agent"
pass "LOOP claude agent"

loop_dry_run_output="$(run_expect_success "LOOP dry-run should succeed without codex" env PATH="/usr/bin:/bin" "$LOOP_SCRIPT" --target-dir "$target_dir" --prompt "preview only" --dry-run)"
assert_contains "$loop_dry_run_output" "Agent: codex" "LOOP dry-run should print the selected agent"
assert_contains "$loop_dry_run_output" "Artifacts root: $target_dir/.evoprogrammer/runs" "LOOP dry-run should print the default artifacts root"
assert_contains "$loop_dry_run_output" "Target directory: $target_dir" "LOOP dry-run should print the target directory"
assert_contains "$loop_dry_run_output" "codex exec" "LOOP dry-run should print the codex command"
assert_contains "$loop_dry_run_output" "--dangerously-bypass-approvals-and-sandbox" "LOOP dry-run should show the codex sandbox bypass"
assert_contains "$loop_dry_run_output" "--cd $target_dir_physical" "LOOP dry-run should show the codex workspace root"
assert_contains "$loop_dry_run_output" "--add-dir $target_dir_physical" "LOOP dry-run should show the writable target directory"
assert_contains "$loop_dry_run_output" "preview\\ only" "LOOP dry-run should keep the prompt in the command preview"
pass "LOOP dry-run"

empty_prompt_file="$TEST_TMPDIR/empty-prompt.txt"
: >"$empty_prompt_file"
blank_prompt_output="$(run_expect_failure "LOOP should reject blank prompts" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --target-dir "$target_dir" --prompt-file "$empty_prompt_file")"
assert_contains "$blank_prompt_output" "Prompt must not be empty." "LOOP should reject empty prompt inputs"
pass "LOOP blank prompt validation"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop-dash.log"
export FAKE_CODEX_LOG
run_expect_success "LOOP should accept a prompt after --" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --target-dir "$target_dir" -- "--leading-dash prompt" >/dev/null
loop_dash_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_dash_log" "arg=--leading-dash prompt" "LOOP should preserve prompts that begin with a dash"
pass "LOOP prompt after --"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop-default-target.log"
export FAKE_CODEX_LOG
(
    cd "$target_dir"
    run_expect_success "LOOP should default to current working directory" env -u EVOPROGRAMMER_TARGET_DIR PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --prompt "default target" >/dev/null
)
loop_default_target_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_default_target_log" "cwd=$target_dir" "LOOP should use the current working directory by default"
pass "LOOP default target directory"

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
run_expect_success "MAIN should loop the requested number of iterations" env PATH="$fake_bin:$PATH" "$MAIN_SCRIPT" --target-dir "$target_dir" --max-iterations 2 --prompt "repeatable" >/dev/null
main_log="$(cat "$FAKE_CODEX_LOG")"
exec_count="$(grep -c '^arg=exec$' "$FAKE_CODEX_LOG")"
assert_equals "$exec_count" "2" "MAIN should invoke LOOP twice when max iterations is 2"
assert_contains "$main_log" "cwd=$target_dir" "MAIN should pass target directory through to LOOP"
assert_contains "$main_log" "arg=repeatable" "MAIN should pass the prompt through to LOOP"
pass "MAIN iteration wiring"

main_session_dir="$(find "$default_artifacts_root" -maxdepth 1 -type d -name 'session-*' | head -n 1)"
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
run_expect_success "MAIN should forward language, framework, and project-type profiles" env PATH="$fake_bin:$PATH" "$MAIN_SCRIPT" --agent claude --target-dir "$target_dir" --max-iterations 1 --language rust --framework axum --project-type online-game --prompt "repeatable" >/dev/null
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
main_auto_detect_output="$(run_expect_success "MAIN should auto-detect language and project type" env PATH="$fake_bin:$PATH" "$MAIN_SCRIPT" --agent claude --target-dir "$auto_main_dir" --max-iterations 1 --prompt "build a reproducible experiment pipeline")"
main_auto_detect_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$main_auto_detect_output" "Language profile: python (auto-detected)" "MAIN should report an auto-detected language profile"
assert_contains "$main_auto_detect_output" "Framework profile: fastapi (auto-detected)" "MAIN should report an auto-detected framework profile"
assert_contains "$main_auto_detect_output" "Project type: scientific-experiment (auto-detected)" "MAIN should report an auto-detected project type"
assert_contains "$main_auto_detect_log" "Target language: python" "MAIN should auto-detect Python from the repository"
assert_contains "$main_auto_detect_log" "Target framework: fastapi" "MAIN should auto-detect FastAPI from the repository"
assert_contains "$main_auto_detect_log" "Target project type: scientific-experiment" "MAIN should auto-detect a scientific experiment from the prompt"
pass "MAIN auto detection"

exclude_count="$(grep -c '^\.evoprogrammer/$' "$exclude_file")"
assert_equals "$exclude_count" "1" "MAIN should not append duplicate local artifact excludes"
pass "MAIN git exclude dedupe"

FAKE_CODEX_LOG="$TEST_TMPDIR/main-codex-args.log"
export FAKE_CODEX_LOG
run_expect_success "MAIN should forward extra codex exec arguments" env PATH="$fake_bin:$PATH" "$MAIN_SCRIPT" --target-dir "$target_dir" --max-iterations 1 --codex-arg "--profile" --codex-arg "danger-full-access" --prompt "repeatable" >/dev/null
main_codex_args_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$main_codex_args_log" "arg=--profile" "MAIN should pass codex option names through LOOP"
assert_contains "$main_codex_args_log" "arg=danger-full-access" "MAIN should pass codex option values through LOOP"
assert_contains "$main_codex_args_log" "arg=repeatable" "MAIN should keep the prompt when forwarding codex arguments"
pass "MAIN codex-arg forwarding"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/main-agent-args-list.log"
export FAKE_CLAUDE_LOG
run_expect_success "MAIN should forward list-style agent args" env PATH="$fake_bin:$PATH" "$MAIN_SCRIPT" --agent claude --target-dir "$target_dir" --max-iterations 1 --agent-args "[\"--model\",\"sonnet\"]" --prompt "repeatable" >/dev/null
main_agent_args_list_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$main_agent_args_list_log" "arg=--model" "MAIN should forward list-style agent arg names"
assert_contains "$main_agent_args_list_log" "arg=sonnet" "MAIN should forward list-style agent arg values"
assert_contains "$main_agent_args_list_log" "arg=repeatable" "MAIN should keep the prompt when forwarding list-style agent args"
pass "MAIN agent-args list"

FAKE_CODEX_LOG="$TEST_TMPDIR/main-dash.log"
export FAKE_CODEX_LOG
run_expect_success "MAIN should preserve prompts that begin with a dash" env PATH="$fake_bin:$PATH" "$MAIN_SCRIPT" --target-dir "$target_dir" --max-iterations 1 -- "--leading-dash prompt" >/dev/null
main_dash_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$main_dash_log" "arg=--leading-dash prompt" "MAIN should pass leading-dash prompts through to LOOP"
pass "MAIN prompt after --"

FAKE_CODEX_LOG="$TEST_TMPDIR/main-prompt-file.log"
export FAKE_CODEX_LOG
run_expect_success "MAIN should load prompts from a file for each iteration" env PATH="$fake_bin:$PATH" "$MAIN_SCRIPT" --target-dir "$target_dir" --max-iterations 2 --prompt-file "$prompt_file" >/dev/null
main_prompt_file_log="$(cat "$FAKE_CODEX_LOG")"
main_prompt_file_count="$(grep -c '^arg=ship from file$' "$FAKE_CODEX_LOG")"
assert_equals "$main_prompt_file_count" "2" "MAIN should re-read the prompt file for each iteration"
assert_contains "$main_prompt_file_log" "cwd=$target_dir" "MAIN prompt-file mode should still target the repository directory"
pass "MAIN prompt-file"

main_dry_run_output="$(run_expect_success "MAIN dry-run should print the next iteration command" env PATH="/usr/bin:/bin" "$MAIN_SCRIPT" --target-dir "$target_dir" --max-iterations 3 --prompt-file "$prompt_file" --dry-run)"
assert_contains "$main_dry_run_output" "Agent: codex" "MAIN dry-run should print the selected agent"
assert_contains "$main_dry_run_output" "Max iterations: 3" "MAIN dry-run should print loop settings"
assert_contains "$main_dry_run_output" "Artifacts root: $target_dir/.evoprogrammer/runs" "MAIN dry-run should print the default artifacts root"
assert_contains "$main_dry_run_output" "--prompt-file" "MAIN dry-run should preserve prompt-file mode"
assert_contains "$main_dry_run_output" "Target directory: $target_dir" "MAIN dry-run should print the target directory"
pass "MAIN dry-run"

FAKE_CODEX_LOG="$TEST_TMPDIR/main-fail.log"
export FAKE_CODEX_LOG
continue_output="$(run_expect_success "MAIN should continue on codex failure when requested" env PATH="$fake_bin:$PATH" FAKE_CODEX_FAIL=1 "$MAIN_SCRIPT" --target-dir "$target_dir" --max-iterations 2 --continue-on-error --prompt "keep going")"
assert_contains "$continue_output" "Iteration 1 failed with exit code 23." "MAIN should report iteration failures"
fail_count="$(grep -c '^arg=exec$' "$FAKE_CODEX_LOG")"
assert_equals "$fail_count" "2" "MAIN should continue running after failures when configured"
pass "MAIN continue-on-error"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/main-claude.log"
export FAKE_CLAUDE_LOG
run_expect_success "MAIN should support Claude Code as an agent" env PATH="$fake_bin:$PATH" "$MAIN_SCRIPT" --agent claude --target-dir "$target_dir" --max-iterations 1 --agent-arg "--model" --agent-arg "sonnet" --prompt "repeatable" >/dev/null
main_claude_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$main_claude_log" "arg=--print" "MAIN should invoke Claude in print mode"
assert_contains "$main_claude_log" "arg=--dangerously-skip-permissions" "MAIN should bypass Claude permissions by default"
assert_contains "$main_claude_log" "arg=sonnet" "MAIN should pass through Claude argument values"
assert_contains "$main_claude_log" "arg=repeatable" "MAIN should pass the prompt through to Claude"
pass "MAIN claude agent"

cli_help_output="$(run_expect_success "CLI help should succeed" "$CLI_SCRIPT" --help)"
assert_contains "$cli_help_output" "Usage:" "CLI help should show usage"
assert_contains "$cli_help_output" "EvoProgrammer once" "CLI help should mention the once subcommand"
assert_contains "$cli_help_output" "EvoProgrammer doctor" "CLI help should mention the doctor subcommand"
pass "CLI help"

FAKE_CODEX_LOG="$TEST_TMPDIR/cli-loop.log"
export FAKE_CODEX_LOG
(
    cd "$target_dir"
    run_expect_success "CLI should default to MAIN behavior in the current directory" env -u EVOPROGRAMMER_TARGET_DIR PATH="$fake_bin:$PATH" "$CLI_SCRIPT" --max-iterations 2 --prompt "cli loop" >/dev/null
)
cli_loop_log="$(cat "$FAKE_CODEX_LOG")"
cli_loop_exec_count="$(grep -c '^arg=exec$' "$FAKE_CODEX_LOG")"
assert_equals "$cli_loop_exec_count" "2" "CLI should loop via MAIN by default"
assert_contains "$cli_loop_log" "cwd=$target_dir" "CLI should target the current working directory by default"
assert_contains "$cli_loop_log" "arg=cli loop" "CLI should forward the prompt to MAIN"
pass "CLI default looping behavior"

FAKE_CODEX_LOG="$TEST_TMPDIR/cli-once.log"
export FAKE_CODEX_LOG
(
    cd "$target_dir"
    run_expect_success "CLI once should dispatch to LOOP" env PATH="$fake_bin:$PATH" "$CLI_SCRIPT" once --prompt "cli once" >/dev/null
)
cli_once_log="$(cat "$FAKE_CODEX_LOG")"
cli_once_exec_count="$(grep -c '^arg=exec$' "$FAKE_CODEX_LOG")"
assert_equals "$cli_once_exec_count" "1" "CLI once should run only one iteration"
assert_contains "$cli_once_log" "arg=cli once" "CLI once should forward the prompt to LOOP"
pass "CLI once behavior"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/cli-once-with-global-options.log"
export FAKE_CLAUDE_LOG
(
    cd "$target_dir"
    run_expect_success "CLI once should allow wrapper options before the subcommand" env PATH="$fake_bin:$PATH" "$CLI_SCRIPT" --agent claude once --prompt "cli once global" >/dev/null
)
cli_once_global_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$cli_once_global_log" "arg=--print" "CLI once should still dispatch to LOOP when wrapper options precede the subcommand"
assert_contains "$cli_once_global_log" "arg=cli once global" "CLI once should preserve the prompt when wrapper options precede the subcommand"
pass "CLI once with global options"

doctor_help_output="$(run_expect_success "DOCTOR help should succeed" "$DOCTOR_SCRIPT" --help)"
assert_contains "$doctor_help_output" "Usage: ./DOCTOR.sh [options]" "DOCTOR help should mention usage"
pass "DOCTOR help"

doctor_missing_codex_output="$(run_expect_failure "DOCTOR should fail without codex" env PATH="/usr/bin:/bin" "$DOCTOR_SCRIPT" --target-dir "$target_dir")"
assert_contains "$doctor_missing_codex_output" "The 'codex' CLI is required" "DOCTOR should report missing codex"
pass "DOCTOR missing codex"

doctor_missing_claude_output="$(run_expect_failure "DOCTOR should fail without claude when requested" env PATH="/usr/bin:/bin" "$DOCTOR_SCRIPT" --agent claude --target-dir "$target_dir")"
assert_contains "$doctor_missing_claude_output" "The 'claude' CLI is required" "DOCTOR should report missing claude"
pass "DOCTOR missing claude"

doctor_output="$(run_expect_success "DOCTOR should validate the environment" env PATH="$fake_bin:$PATH" "$DOCTOR_SCRIPT" --target-dir "$target_dir")"
assert_contains "$doctor_output" "OK agent codex" "DOCTOR should print the selected default agent"
assert_contains "$doctor_output" "OK target-dir $target_dir" "DOCTOR should validate the target directory"
assert_contains "$doctor_output" "OK artifacts-dir $target_dir/.evoprogrammer/runs" "DOCTOR should validate the default artifacts directory"
assert_contains "$doctor_output" "OK command $fake_bin/codex" "DOCTOR should print the discovered codex path"
pass "DOCTOR success"

doctor_profiles_output="$(run_expect_success "DOCTOR should validate language, framework, and project-type profiles" env PATH="$fake_bin:$PATH" "$DOCTOR_SCRIPT" --agent claude --language typescript --framework react --project-type ppt --target-dir "$target_dir")"
assert_contains "$doctor_profiles_output" "OK language-profile typescript" "DOCTOR should print the selected language profile"
assert_contains "$doctor_profiles_output" "OK framework-profile react" "DOCTOR should print the selected framework profile"
assert_contains "$doctor_profiles_output" "OK project-type ppt" "DOCTOR should print the selected project type"
pass "DOCTOR profile success"

doctor_godot_profiles_output="$(run_expect_success "DOCTOR should validate gdscript and godot profiles" env PATH="$fake_bin:$PATH" "$DOCTOR_SCRIPT" --language gdscript --framework godot --target-dir "$target_dir")"
assert_contains "$doctor_godot_profiles_output" "OK language-profile gdscript" "DOCTOR should print the selected gdscript language profile"
assert_contains "$doctor_godot_profiles_output" "OK framework-profile godot" "DOCTOR should print the selected godot framework profile"
pass "DOCTOR gdscript/godot profiles"

doctor_auto_detect_dir="$TEST_TMPDIR/doctor-auto-detect"
mkdir -p "$doctor_auto_detect_dir"
printf '{ "compilerOptions": { "strict": true } }\n' >"$doctor_auto_detect_dir/tsconfig.json"
printf '{ "dependencies": { "next": "14.0.0" } }\n' >"$doctor_auto_detect_dir/package.json"
: >"$doctor_auto_detect_dir/slides.pptx"
doctor_auto_detect_output="$(run_expect_success "DOCTOR should auto-detect language and project type" env PATH="$fake_bin:$PATH" "$DOCTOR_SCRIPT" --agent claude --target-dir "$doctor_auto_detect_dir")"
assert_contains "$doctor_auto_detect_output" "OK language-profile typescript (auto-detected)" "DOCTOR should auto-detect TypeScript from the repository"
assert_contains "$doctor_auto_detect_output" "OK framework-profile nextjs (auto-detected)" "DOCTOR should auto-detect Next.js from the repository"
assert_contains "$doctor_auto_detect_output" "OK project-type ppt (auto-detected)" "DOCTOR should auto-detect PPT projects from the repository"
pass "DOCTOR auto detection"

claude_doctor_output="$(run_expect_success "DOCTOR should validate Claude Code when requested" env PATH="$fake_bin:$PATH" "$DOCTOR_SCRIPT" --agent claude --target-dir "$target_dir")"
assert_contains "$claude_doctor_output" "OK agent claude" "DOCTOR should print the selected Claude agent"
assert_contains "$claude_doctor_output" "OK command $fake_bin/claude" "DOCTOR should print the discovered Claude path"
pass "DOCTOR claude success"

cli_doctor_output="$(run_expect_success "CLI doctor should dispatch to DOCTOR" env PATH="$fake_bin:$PATH" "$CLI_SCRIPT" doctor --target-dir "$target_dir")"
assert_contains "$cli_doctor_output" "OK command $fake_bin/codex" "CLI doctor should run the doctor command"
pass "CLI doctor behavior"

cli_doctor_global_output="$(run_expect_success "CLI doctor should allow wrapper options before the subcommand" env PATH="$fake_bin:$PATH" "$CLI_SCRIPT" --agent claude doctor --target-dir "$target_dir")"
assert_contains "$cli_doctor_global_output" "OK agent claude" "CLI doctor should preserve wrapper options before the subcommand"
assert_contains "$cli_doctor_global_output" "OK command $fake_bin/claude" "CLI doctor should dispatch to DOCTOR with the selected agent"
pass "CLI doctor with global options"

install_dir="$TEST_TMPDIR/install-bin"
install_output="$(run_expect_success "install.sh should create a symlinked CLI" "$INSTALL_SCRIPT" "$install_dir")"
assert_contains "$install_output" "$install_dir/EvoProgrammer" "Installer should report the target path"
if [[ ! -L "$install_dir/EvoProgrammer" ]]; then
    fail "Installer should create a symlink"
fi
installed_target="$(readlink "$install_dir/EvoProgrammer")"
assert_equals "$installed_target" "$CLI_SCRIPT" "Installer should point the symlink to the CLI entrypoint"
pass "Installer"

echo "All $PASS_COUNT tests passed."
