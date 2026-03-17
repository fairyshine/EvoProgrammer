# EvoProgrammer

[中文说明](./README_CN.md)

**A self-evolving programmer that iterates on your codebase autonomously.**

Give it a natural-language goal, point it at a directory, and walk away — EvoProgrammer will keep calling a coding agent (Codex, Claude Code, or your own) in a loop, reading its own output, fixing its own mistakes, and pushing the project forward iteration after iteration until the job is done or you hit `Ctrl+C`.

## Why EvoProgrammer

**Self-iterating code evolution** — Unlike a single-shot agent call, EvoProgrammer feeds the agent back into the same repo over and over (It actually also iterate this code repo, its own repo.). Each pass builds on the last: scaffolding in round 1, tests in round 2, bug fixes in round 3, polish in round 4… The loop keeps going until the codebase converges or you set a limit.

**Broad language, framework, and project coverage** — 13 languages, 24 frameworks, 17 project types out of the box, all auto-detected from your repo. Whether you're building a Next.js SaaS, a Bevy multiplayer game, a FastAPI microservice, or a Godot single-player adventure, EvoProgrammer injects the right idioms, toolchain commands, and architectural guidance into every agent call.

| Languages (13) | Frameworks (24) | Project Types (17) |
|---|---|---|
| Python, TypeScript, JavaScript, Rust, Go, C++, Java, C#, Kotlin, Swift, PHP, Ruby, GDScript | React, Next.js, Vue, Svelte, Django, Flask, FastAPI, Streamlit, Express, NestJS, Rails, Laravel, Spring, Gin, Actix-web, Axum, Bevy, Godot, Unity, Unreal, Electron, Tauri, Pygame, Qt | Web App, Backend Service, CLI Tool, Library, Desktop App, Browser Game, Single-player Game, Mobile Game, Online Game, AI Agent, Data Pipeline, Plugin, Embedded System, Paper, Scientific Experiment, PPT, Office |

## Quick Start

### 1. Clone & install

```bash
git clone https://github.com/user/EvoProgrammer.git
cd EvoProgrammer
chmod +x bin/EvoProgrammer install.sh LOOP.sh MAIN.sh DOCTOR.sh INSPECT.sh VERIFY.sh CLEAN.sh STATUS.sh
./install.sh            # symlinks to ~/.local/bin/EvoProgrammer
```

> **Note:** After cloning you may need to run `chmod +x` on the scripts above. The install script creates a symlink, so make sure `~/.local/bin` is on your `PATH`.

### 2. Simplest possible run

```bash
mkdir my-project && cd my-project
EvoProgrammer "Build a todo app with authentication and tests"
```

That's it. EvoProgrammer auto-detects everything and keeps iterating until you press `Ctrl+C`.

### 3. One-shot mode

```bash
EvoProgrammer once "Initialize a Vite + React + TypeScript project"
```

### 4. Bounded iterations

```bash
EvoProgrammer --max-iterations 5 "Build a full-stack blog with comments and deploy scripts"
```

## More Examples

```bash
# Use Claude Code instead of Codex
EvoProgrammer --agent claude "Implement a card-battle game loop"

# Explicit language + framework + project type
EvoProgrammer --language rust --framework bevy --project-type online-game \
  "Build the dedicated server, client sync, and test scaffolding"

# Godot single-player game
EvoProgrammer --language gdscript --framework godot --project-type single-player-game \
  "Build the first playable loop, scene transitions, and save checkpoints"

# Auto-detect everything from repo + prompt
EvoProgrammer "Build a multiplayer arena prototype with dedicated-server support"

# Point at another directory
EvoProgrammer --target-dir /path/to/project "Improve the README, tests, and CI"

# Pass extra flags to the agent CLI
EvoProgrammer --agent-args '["--model","gpt-5"]' "Generate the full project and keep fixing issues"

# Load a long prompt from a file
EvoProgrammer --prompt-file ./prompt.txt

# Preview the command without running
EvoProgrammer --max-iterations 3 --dry-run "Refine the project structure and add tests"

# Check environment readiness
EvoProgrammer doctor --target-dir /path/to/project

# Inspect what EvoProgrammer detected in a repo
EvoProgrammer inspect --target-dir /path/to/project

# Run the detected verification chain
EvoProgrammer verify --target-dir /path/to/project

# Check version
EvoProgrammer --version

# Clean old artifacts (older than 30 days by default)
EvoProgrammer clean --dry-run

# Show recent run history
EvoProgrammer status --last 5
```

## Requirements

- Bash 4.3+
- At least one supported agent CLI on `PATH` (`codex` or `claude`)

## Subcommands

| Command | Description |
|---|---|
| `EvoProgrammer [prompt]` | Loop mode — keep iterating until stopped |
| `EvoProgrammer once [prompt]` | Single iteration |
| `EvoProgrammer doctor` | Validate local prerequisites |
| `EvoProgrammer inspect` | Show detected repo context and command plan |
| `EvoProgrammer verify` | Run detected lint/typecheck/test/build commands |
| `EvoProgrammer clean` | Remove old artifact directories |
| `EvoProgrammer status` | Show recent run history |
| `EvoProgrammer --version` | Print version |
| `EvoProgrammer help` | Show help |

## Common Options

| Flag | Description |
|---|---|
| `-g, --agent NAME` | Agent to run: `codex` or `claude` |
| `--language NAME` | Language profile (auto-detected if omitted) |
| `--framework NAME` | Framework profile (auto-detected if omitted) |
| `--project-type NAME` | Project-type profile (auto-detected if omitted) |
| `-p, --prompt TEXT` | Prompt text |
| `-f, --prompt-file FILE` | Read prompt from file |
| `-t, --target-dir DIR` | Target repository directory |
| `-o, --artifacts-dir DIR` | Custom artifact storage location |
| `-n, --max-iterations N` | Stop after N iterations (0 = unlimited) |
| `-d, --delay-seconds N` | Delay between iterations |
| `-c, --continue-on-error` | Keep looping after a failed iteration |
| `-q, --quiet` | Suppress informational output |
| `-v, --verbose` | Show extra detail |
| `--dry-run` | Print the command without running it |
| `--agent-args JSON` | Extra agent arguments as a JSON string list |

## Inspection And Verification

Use `inspect` when you want to see exactly what EvoProgrammer inferred before it
calls an agent:

```bash
EvoProgrammer inspect --target-dir /path/to/project --format summary
EvoProgrammer inspect --target-dir /path/to/project --prompt "fix the failing tests" --format prompt
```

Use `verify` when you want EvoProgrammer to execute the detected command chain
itself:

```bash
EvoProgrammer verify --target-dir /path/to/project
EvoProgrammer verify --target-dir /path/to/project --steps lint,test
EvoProgrammer verify --target-dir /path/to/project --dry-run
```

`verify` uses the same command-detection layer as prompt generation, so `doctor`,
`inspect`, agent prompts, and verification all agree on the repo's runnable
commands.

## Project Configuration

Drop a `.evoprogrammer.conf` in your project root to set defaults:

```ini
agent=claude
language=typescript
framework=nextjs
project_type=web-app
verbosity=0
```

Priority: CLI flags > environment variables > `.evoprogrammer.conf` > built-in defaults.

## Lifecycle Hooks

Place executable scripts in `.evoprogrammer/hooks/`:

- `pre-iteration` — runs before each agent call
- `post-iteration` — runs after each agent call

Hooks are advisory: a failure prints a warning but does not stop the run.

## Internals

| File | Role |
|---|---|
| `bin/EvoProgrammer` | CLI entrypoint and subcommand dispatcher |
| `LOOP.sh` | Single agent iteration |
| `MAIN.sh` | Repeated iteration loop |
| `DOCTOR.sh` | Environment validation |
| `INSPECT.sh` | Human-readable repo inspection and prompt preview |
| `VERIFY.sh` | Detected verification-chain runner |
| `CLEAN.sh` | Artifact cleanup |
| `STATUS.sh` | Run history viewer |
| `lib/agents/definitions/` | Pluggable agent definitions |
| `lib/profiles/definitions/` | Language, framework, and project-type profiles |
| `lib/project-context/` | Repo inspection, command inference, and prompt rendering |

See [`docs/architecture.md`](./docs/architecture.md) for the current architecture
and layering model.

## Verification

```bash
bash tests/run_tests.sh
```
