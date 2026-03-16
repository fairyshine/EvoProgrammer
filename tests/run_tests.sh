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

help_output="$(run_expect_success "LOOP help should succeed" "$LOOP_SCRIPT" --help)"
assert_contains "$help_output" "Usage: ./LOOP.sh [options] [prompt]" "LOOP help output should mention options usage"
pass "LOOP help"

missing_codex_output="$(run_expect_failure "LOOP should fail without codex" env HOME="$HOME" PATH="/usr/bin:/bin" "$LOOP_SCRIPT" --prompt "test")"
assert_contains "$missing_codex_output" "The 'codex' CLI is required" "LOOP should report missing codex"
pass "LOOP missing codex"

bad_target_output="$(run_expect_failure "LOOP should fail for missing target directory" env PATH="$PATH" "$LOOP_SCRIPT" --target-dir "$TEST_TMPDIR/does-not-exist" --prompt "test")"
assert_contains "$bad_target_output" "Target directory does not exist" "LOOP should validate target directory"
pass "LOOP target-dir validation"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop.log"
export FAKE_CODEX_LOG
fake_bin="$(setup_fake_codex)"
target_dir="$TEST_TMPDIR/project"
mkdir -p "$target_dir"
prompt_file="$TEST_TMPDIR/prompt.txt"
printf 'ship from file' >"$prompt_file"
run_expect_success "LOOP should invoke codex with prompt and target directory" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --target-dir "$target_dir" --prompt "ship it" >/dev/null
loop_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_log" "cwd=$target_dir" "LOOP should run codex in the requested target directory"
assert_contains "$loop_log" "arg=exec" "LOOP should call codex exec"
assert_contains "$loop_log" "arg=ship it" "LOOP should forward the prompt"
pass "LOOP execution wiring"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop-codex-args.log"
export FAKE_CODEX_LOG
run_expect_success "LOOP should forward extra codex exec arguments" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --target-dir "$target_dir" --codex-arg "--model" --codex-arg "gpt-5" --prompt "ship it" >/dev/null
loop_codex_args_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_codex_args_log" "arg=--model" "LOOP should pass through codex option names"
assert_contains "$loop_codex_args_log" "arg=gpt-5" "LOOP should pass through codex option values"
assert_contains "$loop_codex_args_log" "arg=ship it" "LOOP should keep the prompt as the final codex argument"
pass "LOOP codex-arg forwarding"

FAKE_CODEX_LOG="$TEST_TMPDIR/loop-prompt-file.log"
export FAKE_CODEX_LOG
run_expect_success "LOOP should load prompts from a file" env PATH="$fake_bin:$PATH" "$LOOP_SCRIPT" --target-dir "$target_dir" --prompt-file "$prompt_file" >/dev/null
loop_prompt_file_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$loop_prompt_file_log" "arg=ship from file" "LOOP should read the prompt contents from disk"
pass "LOOP prompt-file"

loop_dry_run_output="$(run_expect_success "LOOP dry-run should succeed without codex" env PATH="/usr/bin:/bin" "$LOOP_SCRIPT" --target-dir "$target_dir" --prompt "preview only" --dry-run)"
assert_contains "$loop_dry_run_output" "Target directory: $target_dir" "LOOP dry-run should print the target directory"
assert_contains "$loop_dry_run_output" "codex exec preview\\ only" "LOOP dry-run should print the codex command"
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

FAKE_CODEX_LOG="$TEST_TMPDIR/main-codex-args.log"
export FAKE_CODEX_LOG
run_expect_success "MAIN should forward extra codex exec arguments" env PATH="$fake_bin:$PATH" "$MAIN_SCRIPT" --target-dir "$target_dir" --max-iterations 1 --codex-arg "--profile" --codex-arg "danger-full-access" --prompt "repeatable" >/dev/null
main_codex_args_log="$(cat "$FAKE_CODEX_LOG")"
assert_contains "$main_codex_args_log" "arg=--profile" "MAIN should pass codex option names through LOOP"
assert_contains "$main_codex_args_log" "arg=danger-full-access" "MAIN should pass codex option values through LOOP"
assert_contains "$main_codex_args_log" "arg=repeatable" "MAIN should keep the prompt when forwarding codex arguments"
pass "MAIN codex-arg forwarding"

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
assert_contains "$main_dry_run_output" "Max iterations: 3" "MAIN dry-run should print loop settings"
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

doctor_help_output="$(run_expect_success "DOCTOR help should succeed" "$DOCTOR_SCRIPT" --help)"
assert_contains "$doctor_help_output" "Usage: ./DOCTOR.sh [options]" "DOCTOR help should mention usage"
pass "DOCTOR help"

doctor_missing_codex_output="$(run_expect_failure "DOCTOR should fail without codex" env PATH="/usr/bin:/bin" "$DOCTOR_SCRIPT" --target-dir "$target_dir")"
assert_contains "$doctor_missing_codex_output" "The 'codex' CLI is required" "DOCTOR should report missing codex"
pass "DOCTOR missing codex"

doctor_output="$(run_expect_success "DOCTOR should validate the environment" env PATH="$fake_bin:$PATH" "$DOCTOR_SCRIPT" --target-dir "$target_dir")"
assert_contains "$doctor_output" "OK target-dir $target_dir" "DOCTOR should validate the target directory"
assert_contains "$doctor_output" "OK codex $fake_bin/codex" "DOCTOR should print the discovered codex path"
pass "DOCTOR success"

cli_doctor_output="$(run_expect_success "CLI doctor should dispatch to DOCTOR" env PATH="$fake_bin:$PATH" "$CLI_SCRIPT" doctor --target-dir "$target_dir")"
assert_contains "$cli_doctor_output" "OK codex $fake_bin/codex" "CLI doctor should run the doctor command"
pass "CLI doctor behavior"

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
