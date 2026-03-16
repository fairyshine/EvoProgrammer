# EvoProgrammer

[中文说明](./README_CN.md)

EvoProgrammer is a small Bash CLI around the `codex` command. It can enter any project directory, run a natural-language instruction against that directory, and keep iterating until you stop it.

## What It Does

- `EvoProgrammer "your prompt"`: run Codex in the current directory and keep iterating.
- `EvoProgrammer once "your prompt"`: run a single Codex pass.
- `EvoProgrammer doctor`: validate the local setup before a long autonomous run.
- `--target-dir`: point the CLI at another directory when needed.
- `--prompt-file`: load large prompts from a file instead of the command line.
- `--dry-run`: inspect the exact command and target directory without running Codex.
- `--max-iterations`, `--delay-seconds`, `--continue-on-error`: control long-running autonomous loops.

Internally:

- `bin/EvoProgrammer` is the user-facing CLI entrypoint.
- `LOOP.sh` runs one Codex iteration.
- `MAIN.sh` runs repeated iterations.
- `install.sh` installs the `EvoProgrammer` command into a local bin directory.

## Requirements

- Bash
- The `codex` CLI available on `PATH`

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

Point the CLI at another directory:

```bash
EvoProgrammer --target-dir /path/to/project "Improve the README, tests, and CI."
```

Pass extra flags through to `codex exec`:

```bash
EvoProgrammer \
  --codex-arg "--model" \
  --codex-arg "gpt-5" \
  --codex-arg "--profile" \
  --codex-arg "danger-full-access" \
  "Generate the full project and keep fixing issues."
```

Load a long prompt from a file:

```bash
EvoProgrammer --prompt-file ./prompt.txt
```

Preview the next command without running Codex:

```bash
EvoProgrammer --max-iterations 3 --dry-run "Refine the project structure and add tests."
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

Pass extra flags through to `codex exec`:

```bash
./LOOP.sh --codex-arg "--model" --codex-arg "gpt-5" --prompt "improve this repo"
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

Repeat iterations while forwarding extra `codex exec` flags:

```bash
./MAIN.sh --max-iterations 3 --codex-arg "--profile" --codex-arg "danger-full-access" "improve this repo"
```

## Configuration

By default, both scripts target the current working directory. You can override that with `EVOPROGRAMMER_TARGET_DIR` or `--target-dir`.

`LOOP.sh` supports:

- `EVOPROGRAMMER_PROMPT` to set the prompt.
- `EVOPROGRAMMER_PROMPT_FILE` to read the prompt from a file.
- `EVOPROGRAMMER_TARGET_DIR` to choose the working directory for `codex exec`.
- `--prompt`, `--prompt-file`, and `--target-dir` flags for one-off runs without exporting environment variables.
- `--codex-arg` as a repeatable flag to pass additional arguments directly to `codex exec`.
- `--dry-run` to print the `codex exec` command without executing it.

`MAIN.sh` supports:

- `EVOPROGRAMMER_PROMPT` to set the prompt.
- `EVOPROGRAMMER_PROMPT_FILE` to read the prompt from a file before each iteration.
- `EVOPROGRAMMER_TARGET_DIR` to choose the working directory for each loop iteration.
- `EVOPROGRAMMER_MAX_ITERATIONS` to stop after a fixed number of runs. `0` means no limit.
- `EVOPROGRAMMER_DELAY_SECONDS` to wait between runs.
- `EVOPROGRAMMER_CONTINUE_ON_ERROR=1` to keep looping after a failed iteration.
- `--max-iterations`, `--delay-seconds`, and `--continue-on-error` flags as CLI equivalents.
- `--prompt-file` to reload the prompt from disk on every iteration.
- `--codex-arg` as a repeatable flag to forward extra `codex exec` arguments on every iteration.
- `--dry-run` to preview the next loop command instead of running it.

`DOCTOR.sh` supports:

- `EVOPROGRAMMER_TARGET_DIR` and `--target-dir` to validate a specific repository directory.

Use `./LOOP.sh --help` or `./MAIN.sh --help` for a quick summary.

Use `--` before the prompt when the prompt itself starts with `-`.

## Verification

Run the lightweight shell test suite with:

```bash
bash tests/run_tests.sh
```
