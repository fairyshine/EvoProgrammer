#!/usr/bin/env bash

setup_agent_test_workspace
setup_context_workspace

cli_help_output="$(run_expect_success "CLI help should succeed" "$CLI_SCRIPT" --help)"
assert_contains "$cli_help_output" "Usage:" "CLI help should show usage"
assert_contains "$cli_help_output" "EvoProgrammer once" "CLI help should mention the once subcommand"
assert_contains "$cli_help_output" "EvoProgrammer doctor" "CLI help should mention the doctor subcommand"
pass "CLI help"

FAKE_CODEX_LOG="$TEST_TMPDIR/cli-loop.log"
export FAKE_CODEX_LOG
(
    cd "$TEST_TARGET_DIR"
    run_expect_success "CLI should default to MAIN behavior in the current directory" env -u EVOPROGRAMMER_TARGET_DIR PATH="$TEST_FAKE_BIN:$PATH" "$CLI_SCRIPT" --max-iterations 2 --prompt "cli loop" >/dev/null
)
cli_loop_log="$(cat "$FAKE_CODEX_LOG")"
cli_loop_exec_count="$(grep -c '^arg=exec$' "$FAKE_CODEX_LOG")"
assert_equals "$cli_loop_exec_count" "2" "CLI should loop via MAIN by default"
assert_contains "$cli_loop_log" "cwd=$TEST_TARGET_DIR" "CLI should target the current working directory by default"
assert_contains "$cli_loop_log" "arg=cli loop" "CLI should forward the prompt to MAIN"
pass "CLI default looping behavior"

FAKE_CODEX_LOG="$TEST_TMPDIR/cli-once.log"
export FAKE_CODEX_LOG
(
    cd "$TEST_TARGET_DIR"
    run_expect_success "CLI once should dispatch to LOOP" env PATH="$TEST_FAKE_BIN:$PATH" "$CLI_SCRIPT" once --prompt "cli once" >/dev/null
)
cli_once_log="$(cat "$FAKE_CODEX_LOG")"
cli_once_exec_count="$(grep -c '^arg=exec$' "$FAKE_CODEX_LOG")"
assert_equals "$cli_once_exec_count" "1" "CLI once should run only one iteration"
assert_contains "$cli_once_log" "arg=cli once" "CLI once should forward the prompt to LOOP"
pass "CLI once behavior"

FAKE_CLAUDE_LOG="$TEST_TMPDIR/cli-once-with-global-options.log"
export FAKE_CLAUDE_LOG
(
    cd "$TEST_TARGET_DIR"
    run_expect_success "CLI once should allow wrapper options before the subcommand" env PATH="$TEST_FAKE_BIN:$PATH" "$CLI_SCRIPT" --agent claude once --prompt "cli once global" >/dev/null
)
cli_once_global_log="$(cat "$FAKE_CLAUDE_LOG")"
assert_contains "$cli_once_global_log" "arg=--print" "CLI once should still dispatch to LOOP when wrapper options precede the subcommand"
assert_contains "$cli_once_global_log" "arg=cli once global" "CLI once should preserve the prompt when wrapper options precede the subcommand"
pass "CLI once with global options"

doctor_help_output="$(run_expect_success "DOCTOR help should succeed" "$DOCTOR_SCRIPT" --help)"
assert_contains "$doctor_help_output" "Usage: ./DOCTOR.sh [options]" "DOCTOR help should mention usage"
pass "DOCTOR help"

doctor_missing_codex_output="$(run_expect_failure "DOCTOR should fail without codex" env PATH="/usr/bin:/bin" "$DOCTOR_SCRIPT" --target-dir "$TEST_TARGET_DIR")"
assert_contains "$doctor_missing_codex_output" "The 'codex' CLI is required" "DOCTOR should report missing codex"
pass "DOCTOR missing codex"

doctor_missing_claude_output="$(run_expect_failure "DOCTOR should fail without claude when requested" env PATH="/usr/bin:/bin" "$DOCTOR_SCRIPT" --agent claude --target-dir "$TEST_TARGET_DIR")"
assert_contains "$doctor_missing_claude_output" "The 'claude' CLI is required" "DOCTOR should report missing claude"
pass "DOCTOR missing claude"

doctor_output="$(run_expect_success "DOCTOR should validate the environment" env PATH="$TEST_FAKE_BIN:$PATH" "$DOCTOR_SCRIPT" --target-dir "$TEST_TARGET_DIR")"
assert_contains "$doctor_output" "OK agent codex" "DOCTOR should print the selected default agent"
assert_contains "$doctor_output" "OK target-dir $TEST_TARGET_DIR" "DOCTOR should validate the target directory"
assert_contains "$doctor_output" "OK artifacts-dir $TEST_TARGET_DIR/.evoprogrammer/runs" "DOCTOR should validate the default artifacts directory"
assert_contains "$doctor_output" "OK command $TEST_FAKE_BIN/codex" "DOCTOR should print the discovered codex path"
pass "DOCTOR success"

doctor_profiles_output="$(run_expect_success "DOCTOR should validate language, framework, and project-type profiles" env PATH="$TEST_FAKE_BIN:$PATH" "$DOCTOR_SCRIPT" --agent claude --language typescript --framework react --project-type ppt --target-dir "$TEST_TARGET_DIR")"
assert_contains "$doctor_profiles_output" "OK language-profile typescript" "DOCTOR should print the selected language profile"
assert_contains "$doctor_profiles_output" "OK framework-profile react" "DOCTOR should print the selected framework profile"
assert_contains "$doctor_profiles_output" "OK project-type ppt" "DOCTOR should print the selected project type"
pass "DOCTOR profile success"

doctor_godot_profiles_output="$(run_expect_success "DOCTOR should validate gdscript and godot profiles" env PATH="$TEST_FAKE_BIN:$PATH" "$DOCTOR_SCRIPT" --language gdscript --framework godot --target-dir "$TEST_TARGET_DIR")"
assert_contains "$doctor_godot_profiles_output" "OK language-profile gdscript" "DOCTOR should print the selected gdscript language profile"
assert_contains "$doctor_godot_profiles_output" "OK framework-profile godot" "DOCTOR should print the selected godot framework profile"
pass "DOCTOR gdscript/godot profiles"

doctor_auto_detect_dir="$TEST_TMPDIR/doctor-auto-detect"
mkdir -p "$doctor_auto_detect_dir"
printf '{ "compilerOptions": { "strict": true } }\n' >"$doctor_auto_detect_dir/tsconfig.json"
printf '{ "dependencies": { "next": "14.0.0" } }\n' >"$doctor_auto_detect_dir/package.json"
: >"$doctor_auto_detect_dir/slides.pptx"
doctor_auto_detect_output="$(run_expect_success "DOCTOR should auto-detect language and project type" env PATH="$TEST_FAKE_BIN:$PATH" "$DOCTOR_SCRIPT" --agent claude --target-dir "$doctor_auto_detect_dir")"
assert_contains "$doctor_auto_detect_output" "OK language-profile typescript (auto-detected)" "DOCTOR should auto-detect TypeScript from the repository"
assert_contains "$doctor_auto_detect_output" "OK framework-profile nextjs (auto-detected)" "DOCTOR should auto-detect Next.js from the repository"
assert_contains "$doctor_auto_detect_output" "OK project-type ppt (auto-detected)" "DOCTOR should auto-detect PPT projects from the repository"
pass "DOCTOR auto detection"

doctor_context_output="$(run_expect_success "DOCTOR should print analyzed repository context" env PATH="$TEST_FAKE_BIN:$PATH" "$DOCTOR_SCRIPT" --agent claude --target-dir "$TEST_CONTEXT_DIR")"
assert_contains "$doctor_context_output" "OK package-manager pnpm" "DOCTOR should print the detected package manager"
assert_contains "$doctor_context_output" "OK workspace-mode monorepo" "DOCTOR should print the detected workspace mode"
assert_contains "$doctor_context_output" "OK test-command pnpm test" "DOCTOR should print the suggested test command"
assert_contains "$doctor_context_output" "OK task-kind feature" "DOCTOR should print the inferred task kind"
assert_contains "$doctor_context_output" "OK search-strategy" "DOCTOR should print the structured search strategy"
assert_contains "$doctor_context_output" "OK verification-strategy" "DOCTOR should print the structured verification strategy"
assert_contains "$doctor_context_output" "OK risk-focus" "DOCTOR should print the structured risk focus"
pass "DOCTOR repository context analysis"

claude_doctor_output="$(run_expect_success "DOCTOR should validate Claude Code when requested" env PATH="$TEST_FAKE_BIN:$PATH" "$DOCTOR_SCRIPT" --agent claude --target-dir "$TEST_TARGET_DIR")"
assert_contains "$claude_doctor_output" "OK agent claude" "DOCTOR should print the selected Claude agent"
assert_contains "$claude_doctor_output" "OK command $TEST_FAKE_BIN/claude" "DOCTOR should print the discovered Claude path"
pass "DOCTOR claude success"

cli_doctor_output="$(run_expect_success "CLI doctor should dispatch to DOCTOR" env PATH="$TEST_FAKE_BIN:$PATH" "$CLI_SCRIPT" doctor --target-dir "$TEST_TARGET_DIR")"
assert_contains "$cli_doctor_output" "OK command $TEST_FAKE_BIN/codex" "CLI doctor should run the doctor command"
pass "CLI doctor behavior"

cli_doctor_global_output="$(run_expect_success "CLI doctor should allow wrapper options before the subcommand" env PATH="$TEST_FAKE_BIN:$PATH" "$CLI_SCRIPT" --agent claude doctor --target-dir "$TEST_TARGET_DIR")"
assert_contains "$cli_doctor_global_output" "OK agent claude" "CLI doctor should preserve wrapper options before the subcommand"
assert_contains "$cli_doctor_global_output" "OK command $TEST_FAKE_BIN/claude" "CLI doctor should dispatch to DOCTOR with the selected agent"
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
