# EvoProgrammer

[中文说明](./README_CN.md)

EvoProgrammer is a small Bash CLI around coding-agent commands such as `codex` and `claude`. It can enter any project directory, run a natural-language instruction against that directory, and keep iterating until you stop it.

## What It Does

- `EvoProgrammer "your prompt"`: run the selected agent in the current directory and keep iterating.
- `EvoProgrammer once "your prompt"`: run a single agent pass.
- `--agent`: switch between built-in agent presets such as `codex` and `claude`.
- `--language`: add language-specific implementation guidance for built-in profiles such as `python`, `rust`, `go`, `typescript`, `gdscript`, or `swift`, or let EvoProgrammer auto-detect it.
- `--framework`: add framework-specific implementation guidance for built-in profiles such as `fastapi`, `django`, `react`, `nextjs`, `godot`, `bevy`, or `axum`, or let EvoProgrammer auto-detect it.
- `--project-type`: add scenario-specific guidance for built-in profiles such as `single-player-game`, `online-game`, `paper`, `scientific-experiment`, `ppt`, `office`, `web-app`, or `backend-service`, or let EvoProgrammer auto-detect it.
- After profile detection, EvoProgrammer also derives repository context such as package manager, workspace mode, likely dev/build/test/lint commands, architecture hotspots, validation hints, and a task-specific workflow.
- The workflow layer now adapts search order, edit strategy, verification strategy, and risk focus using the detected language plus project type.
- `EvoProgrammer doctor`: validate the local setup before a long autonomous run.
- `--target-dir`: point the CLI at another directory when needed.
- Default run artifacts under `TARGET_DIR/.evoprogrammer/runs` for later inspection.
- When `TARGET_DIR` is a Git repository, EvoProgrammer adds `.evoprogrammer/` to the local `.git/info/exclude` file so later iterations do not read their own artifacts back into context.
- `--artifacts-dir`: store run artifacts in a custom location.
- `--prompt-file`: load large prompts from a file instead of the command line.
- `--dry-run`: inspect the exact command and target directory without running the agent.
- `--max-iterations`, `--delay-seconds`, `--continue-on-error`: control long-running autonomous loops.
- Wrapper-level options can appear before `once` or `doctor`.

Internally:

- `bin/EvoProgrammer` is the user-facing CLI entrypoint.
- `LOOP.sh` runs one agent iteration.
- `MAIN.sh` runs repeated iterations.
- `install.sh` installs the `EvoProgrammer` command into a local bin directory.

## Requirements

- Bash
- At least one supported agent CLI on `PATH`, such as `codex` or `claude`

## Install

Install the command into `~/.local/bin`:

```bash
./install.sh
```

Install into a custom directory:

```bash
./install.sh /custom/bin
```

If you prefer not to run the installer, you can also add this repo's `bin/` directory to your `PATH`.

## Usage

Enter the directory where you want code generated or evolved, then run:

```bash
EvoProgrammer "Build a complete blog system with authentication, article management, comments, and deployment scripts."
```

That command uses the current directory as the target project directory and will keep iterating until you stop it with `Ctrl+C`.

Run a bounded number of iterations:

```bash
EvoProgrammer --max-iterations 3 "Build a full-stack todo app with tests."
```

Run a single pass only:

```bash
EvoProgrammer once "Initialize a Vite + React + TypeScript project."
```

You can also place wrapper options before the subcommand:

```bash
EvoProgrammer --agent claude once "Scaffold a typed FastAPI service."
```

Point the CLI at another directory:

```bash
EvoProgrammer --target-dir /path/to/project "Improve the README, tests, and CI."
```

Run Claude Code instead of Codex:

```bash
EvoProgrammer --agent claude "Implement the first playable card-battle loop."
```

Adapt the run for a Rust Bevy online game:

```bash
EvoProgrammer --language rust --framework bevy --project-type online-game "Build the dedicated server, client sync, and test scaffolding."
```

Adapt the run for a Godot GDScript project:

```bash
EvoProgrammer --language gdscript --framework godot --project-type single-player-game "Build the first playable loop, scene transitions, and save checkpoints."
```

Let EvoProgrammer auto-detect both from the repository and prompt:

```bash
EvoProgrammer "Build a multiplayer arena prototype with dedicated-server support."
```

The analyzed context is surfaced in three places:

- terminal output from `LOOP.sh`, `MAIN.sh`, and `doctor`
- the prompt sent to the coding agent
- `metadata.env` artifacts for later inspection or reuse

Pass extra flags through to the selected agent CLI:

```bash
EvoProgrammer \
  --agent-args '["--model","gpt-5"]' \
  "Generate the full project and keep fixing issues."
```

`--codex-arg` still works as a backward-compatible alias for Codex-oriented scripts.

Load a long prompt from a file:

```bash
EvoProgrammer --prompt-file ./prompt.txt
```

Preview the next command without running the agent:

```bash
EvoProgrammer --max-iterations 3 --dry-run "Refine the project structure and add tests."
```

Write artifacts to a dedicated directory:

```bash
EvoProgrammer --artifacts-dir /tmp/evop-runs "Refine the project structure and add tests."
```

Check whether the environment is ready:

```bash
EvoProgrammer doctor --target-dir /path/to/project
```

Run a prompt that starts with `-`:

```bash
EvoProgrammer -- --write a changelog
```

## Low-Level Scripts

Run one iteration:

```bash
./LOOP.sh "improve this repo"
```

Run one iteration against another repository:

```bash
./LOOP.sh --target-dir /path/to/repo --prompt "improve test coverage"
```

Pass extra flags through to the selected agent CLI:

```bash
./LOOP.sh --agent-args '["--model","gpt-5"]' --prompt "improve this repo"
```

Run a prompt that starts with `-`:

```bash
./LOOP.sh -- --write a changelog
```

Run repeated iterations forever:

```bash
./MAIN.sh "improve this repo"
```

Run three iterations with a delay:

```bash
EVOPROGRAMMER_MAX_ITERATIONS=3 \
EVOPROGRAMMER_DELAY_SECONDS=5 \
./MAIN.sh "improve this repo"
```

Repeat iterations while forwarding extra agent flags:

```bash
./MAIN.sh --max-iterations 3 --agent claude --agent-args '["--model","sonnet"]' "improve this repo"
```

## Configuration

By default, both scripts target the current working directory, use the `codex` agent, and auto-detect language/framework/project-type guidance when possible. You can override that with `EVOPROGRAMMER_TARGET_DIR`, `EVOPROGRAMMER_AGENT`, `--target-dir`, or `--agent`.

Built-in language profiles:

- `python`
- `cpp`
- `go`
- `rust`
- `typescript`
- `javascript`
- `java`
- `csharp`
- `kotlin`
- `swift`
- `php`
- `ruby`
- `gdscript`

Built-in framework profiles:

- `django`
- `flask`
- `fastapi`
- `streamlit`
- `pygame`
- `qt`
- `react`
- `nextjs`
- `vue`
- `svelte`
- `express`
- `nestjs`
- `electron`
- `tauri`
- `godot`
- `unity`
- `unreal`
- `bevy`
- `rails`
- `laravel`
- `spring`
- `gin`
- `actix-web`
- `axum`

Built-in project types:

- `single-player-game`
- `paper`
- `scientific-experiment`
- `mobile-game`
- `online-game`
- `ppt`
- `office`
- `web-app`
- `backend-service`
- `cli-tool`
- `library`
- `desktop-app`
- `browser-game`
- `ai-agent`
- `data-pipeline`
- `plugin`
- `embedded-system`

`LOOP.sh` supports:

- `EVOPROGRAMMER_PROMPT` to set the prompt.
- `EVOPROGRAMMER_PROMPT_FILE` to read the prompt from a file.
- `EVOPROGRAMMER_AGENT` to choose which built-in agent preset to run.
- `EVOPROGRAMMER_AGENT_ARGS` to provide extra agent arguments as a JSON-like string list.
- `EVOPROGRAMMER_LANGUAGE_PROFILE` to inject language-specific guidance into the prompt.
- `EVOPROGRAMMER_FRAMEWORK_PROFILE` to inject framework-specific guidance into the prompt.
- `EVOPROGRAMMER_PROJECT_TYPE` to inject project-type guidance into the prompt.
- `EVOPROGRAMMER_TARGET_DIR` to choose the working directory for the agent command.
- `EVOPROGRAMMER_ARTIFACTS_DIR` to override where run artifacts are stored. Default: `TARGET_DIR/.evoprogrammer/runs`.
- `--prompt`, `--prompt-file`, and `--target-dir` flags for one-off runs without exporting environment variables.
- `--language` to apply a built-in language adaptation profile.
- `--framework` to apply a built-in framework adaptation profile.
- `--project-type` to apply a built-in project-type adaptation profile.
- `--artifacts-dir` to store artifacts somewhere other than the target repository.
- If the target directory is a Git repository and artifacts stay inside it, EvoProgrammer registers a local `.git/info/exclude` rule to keep `.evoprogrammer/` out of later iterations.
- `--agent-args` to pass additional arguments directly to the selected agent CLI as a JSON-like string list.
- `--agent-arg` as a repeatable flag when you prefer shell-style repetition.
- `--codex-arg` as a backward-compatible alias for `--agent-arg`.
- `--dry-run` to print the agent command without executing it.

Each `LOOP.sh` run creates a timestamped directory containing:

- `prompt.txt`
- `command.txt`
- `metadata.env`
- `<agent>.log`

`metadata.env` includes the selected profiles plus derived repository facts such as package manager, workspace mode, suggested verification commands, search roots, and task kind.

`MAIN.sh` supports:

- `EVOPROGRAMMER_PROMPT` to set the prompt.
- `EVOPROGRAMMER_PROMPT_FILE` to read the prompt from a file before each iteration.
- `EVOPROGRAMMER_AGENT` to choose which built-in agent preset to run.
- `EVOPROGRAMMER_AGENT_ARGS` to provide extra agent arguments as a JSON-like string list.
- `EVOPROGRAMMER_LANGUAGE_PROFILE` to inject language-specific guidance into every iteration.
- `EVOPROGRAMMER_FRAMEWORK_PROFILE` to inject framework-specific guidance into every iteration.
- `EVOPROGRAMMER_PROJECT_TYPE` to inject project-type guidance into every iteration.
- `EVOPROGRAMMER_TARGET_DIR` to choose the working directory for each loop iteration.
- `EVOPROGRAMMER_ARTIFACTS_DIR` to override where session and iteration artifacts are stored.
- `EVOPROGRAMMER_MAX_ITERATIONS` to stop after a fixed number of runs. `0` means no limit.
- `EVOPROGRAMMER_DELAY_SECONDS` to wait between runs.
- `EVOPROGRAMMER_CONTINUE_ON_ERROR=1` to keep looping after a failed iteration.
- `--max-iterations`, `--delay-seconds`, and `--continue-on-error` flags as CLI equivalents.
- `--prompt-file` to reload the prompt from disk on every iteration.
- `--language` to apply a built-in language adaptation profile on every iteration.
- `--framework` to apply a built-in framework adaptation profile on every iteration.
- `--project-type` to apply a built-in project-type adaptation profile on every iteration.
- `--artifacts-dir` to store session artifacts outside the target repository.
- `--agent-args` to forward extra agent arguments on every iteration as a JSON-like string list.
- `--agent-arg` as a repeatable flag when you prefer shell-style repetition.
- `--codex-arg` as a backward-compatible alias for `--agent-arg`.
- `--dry-run` to preview the next loop command instead of running it.
- When artifacts stay inside a Git-backed target directory, EvoProgrammer writes a local exclude rule so `.evoprogrammer/` does not get fed back into subsequent runs.

Each `MAIN.sh` run creates a timestamped session directory with `session.env` plus an `iterations/` folder that contains the per-iteration artifacts produced by `LOOP.sh`.

`DOCTOR.sh` supports:

- `EVOPROGRAMMER_LANGUAGE_PROFILE` and `--language` to validate a selected language profile.
- `EVOPROGRAMMER_FRAMEWORK_PROFILE` and `--framework` to validate a selected framework profile.
- `EVOPROGRAMMER_PROJECT_TYPE` and `--project-type` to validate a selected project-type profile.
- `EVOPROGRAMMER_TARGET_DIR` and `--target-dir` to validate a specific repository directory.
- `EVOPROGRAMMER_ARTIFACTS_DIR` and `--artifacts-dir` to validate the artifact storage location.

Use `./LOOP.sh --help` or `./MAIN.sh --help` for a quick summary.

Use `--` before the prompt when the prompt itself starts with `-`.

## Verification

Run the lightweight shell test suite with:

```bash
bash tests/run_tests.sh
```
