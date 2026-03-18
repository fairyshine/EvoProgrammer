# EvoProgrammer

[中文说明](./README_CN.md)

**A self-evolving programmer that iterates on your codebase autonomously.**

Give it a natural-language goal, point it at a directory, and walk away — EvoProgrammer will keep calling a coding agent (Codex, Claude Code, or your own) in a loop, reading its own output, fixing its own mistakes, and pushing the project forward iteration after iteration until the job is done or you hit `Ctrl+C`.

## Why EvoProgrammer

**Self-iterating code evolution** — Unlike a single-shot agent call, EvoProgrammer feeds the agent back into the same repo over and over (It actually also iterates this code repo, its own repo.). Each pass builds on the last: scaffolding in round 1, tests in round 2, bug fixes in round 3, polish in round 4… The loop keeps going until the codebase converges or you set a limit.

**Broad language, framework, and project coverage** — 22 languages, 31 frameworks, 19 project types out of the box, all auto-detected from your repo. Whether you're building a Next.js SaaS, an Expo or React Native mobile app, a Flutter mobile app, a Bevy multiplayer game, a FastAPI microservice, a Spring backend, a Phoenix service, an Astro or Nuxt frontend, a Shiny app, Terraform infrastructure, a .NET CLI in C#/F#/Visual Basic, or a CMake-based native tool, EvoProgrammer injects the right idioms, toolchain commands, and architectural guidance into every agent call.

| Languages (22) | Frameworks (31) | Project Types (19) |
|---|---|---|
| Python, TypeScript, JavaScript, Rust, Go, C, C++, Java, C#, F#, Visual Basic, Kotlin, Swift, Dart, PHP, Ruby, GDScript, Elixir, Scala, Lua, R, Terraform | React, Next.js, Vue, Svelte, Nuxt, Astro, Expo, React Native, Django, Flask, FastAPI, Streamlit, Express, NestJS, Rails, Laravel, Spring, Gin, Actix-web, Axum, Bevy, Flutter, Godot, Unity, Unreal, Electron, Tauri, Pygame, Qt, Phoenix, Shiny | Web App, Backend Service, CLI Tool, Library, Desktop App, Mobile App, Browser Game, Single-player Game, Mobile Game, Online Game, AI Agent, Data Pipeline, Plugin, Embedded System, Infrastructure, Paper, Scientific Experiment, PPT, Office |

Recent detection improvements also make project-type inference less shell-centric: non-shell CLIs, Spring-style or Phoenix backend services, Expo or React Native mobile apps, Nuxt or Astro frontends, Electron or Tauri desktop apps, Shiny web apps, Terraform infrastructure repos, .NET console tools, browser-first game repos, multiplayer game repos, and engine-backed game repos now resolve more accurately. The Node framework hot path now also uses a cached package-token index, which cuts repeated `package.json` scans while making framework detection more precise. Shared .NET project markers now also keep C#/F#/Visual Basic language detection, CLI classification, workspace manifest discovery, and `dotnet` command inference aligned on the same cached repo facts. Game sub-type detection now also reuses cached browser-runtime and multiplayer-runtime markers, so `browser-game`, `online-game`, and `single-player-game` classification can share one pass of repo-shape facts instead of re-checking the same signals in multiple hooks. Monorepo inspection now also caches nested workspace manifest discovery, surfaces workspace package roots in `inspect`, and can infer recursive pnpm/npm workspace commands when the root manifest does not define its own scripts. `inspect` and `verify` can also infer stronger default commands for Gradle, Maven, .NET, SwiftPM, Mix, sbt, LuaRocks, R, Terraform, CMake, Expo, and React Native projects.

## Quick Start

### 1. Clone & install

```zsh
git clone https://github.com/user/EvoProgrammer.git
cd EvoProgrammer
chmod +x bin/EvoProgrammer install.sh LOOP.sh MAIN.sh DOCTOR.sh INSPECT.sh VERIFY.sh CLEAN.sh STATUS.sh PROFILES.sh CATALOG.sh
./install.sh            # symlinks to ~/.local/bin/EvoProgrammer
```

> **Note:** After cloning you may need to run `chmod +x` on the scripts above. The install script creates a symlink, so make sure `~/.local/bin` is on your `PATH`.

### 2. Simplest possible run

```zsh
mkdir my-project && cd my-project
EvoProgrammer "Build a todo app with authentication and tests"
```

That's it. EvoProgrammer auto-detects everything and keeps iterating until you press `Ctrl+C`.

### 3. One-shot mode

```zsh
EvoProgrammer once "Initialize a Vite + React + TypeScript project"
```

### 4. Bounded iterations

```zsh
EvoProgrammer --max-iterations 5 "Build a full-stack blog with comments and deploy scripts"
```

## More Examples

```zsh
# Use Claude Code instead of Codex
EvoProgrammer --agent claude "Implement a card-battle game loop"

# Explicit language + framework + project type
EvoProgrammer --language rust --framework bevy --project-type online-game \
  "Build the dedicated server, client sync, and test scaffolding"

# Godot single-player game
EvoProgrammer --language gdscript --framework godot --project-type single-player-game \
  "Build the first playable loop, scene transitions, and save checkpoints"

# Flutter mobile app
EvoProgrammer --language dart --framework flutter --project-type mobile-app \
  "Build offline auth, app navigation, and widget tests"

# Expo mobile app
EvoProgrammer --language typescript --framework expo --project-type mobile-app \
  "Build the auth flow, navigation, and device-safe form validation"

# Auto-detect everything from repo + prompt
EvoProgrammer "Build a multiplayer arena prototype with dedicated-server support"

# Point at another directory
EvoProgrammer --target-dir /path/to/project "Improve the README, tests, and CI"

# Commit each successful iteration automatically
EvoProgrammer --auto-commit --auto-commit-message "feat: evolve repo" \
  "Add the missing mobile flow and tighten verification"

# Pass extra flags to the agent CLI
EvoProgrammer --agent-args '["--model","gpt-5"]' "Generate the full project and keep fixing issues"

# Load a long prompt from a file
EvoProgrammer --prompt-file ./prompt.txt

# Preview the command without running
EvoProgrammer --max-iterations 3 --dry-run "Refine the project structure and add tests"

# Reuse an inspect env snapshot across commands
EvoProgrammer inspect --target-dir /path/to/project \
  --report-file ./project-context.env --report-format env
EvoProgrammer verify --context-file ./project-context.env --steps lint,test
EvoProgrammer once --context-file ./project-context.env "Optimize startup time"

# Check environment readiness
EvoProgrammer doctor --target-dir /path/to/project

# Inspect what EvoProgrammer detected in a repo
EvoProgrammer inspect --target-dir /path/to/project
EvoProgrammer inspect --target-dir /path/to/project --format commands
EvoProgrammer inspect --target-dir /path/to/project --format agent
EvoProgrammer inspect --target-dir /path/to/project --format agent-json
EvoProgrammer inspect --target-dir /path/to/project --format json
EvoProgrammer inspect --target-dir /path/to/project --format diagnostics
EvoProgrammer inspect --target-dir /path/to/project --format profiles
EvoProgrammer inspect --target-dir /path/to/project --format env
EvoProgrammer inspect --target-dir /path/to/project \
  --report-file ./inspect-report.json --report-format json

# Run the detected verification chain
EvoProgrammer verify --target-dir /path/to/project
EvoProgrammer verify --target-dir /path/to/project --steps lint,test --list --list-format json
EvoProgrammer verify --target-dir /path/to/project --steps lint,test --require-all
EvoProgrammer verify --target-dir /path/to/project \
  --report-file ./verify-report.json --report-format json

# Check version
EvoProgrammer --version

# Clean old artifacts (older than 30 days by default)
EvoProgrammer clean --dry-run

# Show recent run history
EvoProgrammer status --last 5
EvoProgrammer status --kind session --status completed
EvoProgrammer status --format json --report-file ./status-report.json --report-format json

# Browse built-in profiles
EvoProgrammer profiles
EvoProgrammer profiles --category languages
EvoProgrammer profiles --category frameworks --format json

# Export a focused agent tool catalog
EvoProgrammer catalog --target-dir /path/to/project
EvoProgrammer catalog --target-dir /path/to/project --kind commands --format json
EvoProgrammer catalog --target-dir /path/to/project --kind support --format env
```

## Requirements

- zsh 4.3+
- At least one supported agent CLI on `PATH` (`codex` or `claude`)

## Development Checks

```zsh
zsh tests/run_tests.sh
zsh tests/run_lint.sh
zsh tests/run_extended_tests.sh
```

`tests/run_lint.sh` matches the repository's zsh-only runtime model: it limits
`shellcheck` to the POSIX bootstrap shim and validates the remaining scripts
with `zsh -n`.

## Subcommands

| Command | Description |
|---|---|
| `EvoProgrammer [prompt]` | Loop mode — keep iterating until stopped |
| `EvoProgrammer once [prompt]` | Single iteration |
| `EvoProgrammer doctor` | Validate local prerequisites |
| `EvoProgrammer inspect` | Show detected repo context and command plan |
| `EvoProgrammer verify` | Run detected lint/typecheck/test/build commands |
| `EvoProgrammer clean` | Remove old artifact directories |
| `EvoProgrammer status` | Show recent run history, filters, and machine-readable reports |
| `EvoProgrammer profiles` | List built-in language, framework, and project-type profiles |
| `EvoProgrammer catalog` | Print a focused agent command/support-tool catalog |
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
| `--context-file FILE` | Reuse an `inspect --format env` context snapshot |
| `-n, --max-iterations N` | Stop after N iterations (0 = unlimited) |
| `-d, --delay-seconds N` | Delay between iterations |
| `-c, --continue-on-error` | Keep looping after a failed iteration |
| `-q, --quiet` | Suppress informational output |
| `-v, --verbose` | Show extra detail |
| `--dry-run` | Print the command without running it |
| `--agent-args JSON` | Extra agent arguments as a JSON string list |
| `--auto-commit` | Commit each successful iteration's new git changes |
| `--auto-commit-message TEXT` | Override the auto-commit message |

## Inspection And Verification

Use `inspect` when you want to see exactly what EvoProgrammer inferred before it
calls an agent:

```zsh
EvoProgrammer inspect --target-dir /path/to/project --format summary
EvoProgrammer inspect --target-dir /path/to/project --format commands
EvoProgrammer inspect --target-dir /path/to/project --format agent
EvoProgrammer inspect --target-dir /path/to/project --format agent-json
EvoProgrammer inspect --target-dir /path/to/project --format agent-env
EvoProgrammer inspect --target-dir /path/to/project --prompt "fix the failing tests" --format prompt
EvoProgrammer inspect --target-dir /path/to/project --format json
EvoProgrammer inspect --target-dir /path/to/project --format diagnostics
EvoProgrammer inspect --target-dir /path/to/project --format profiles
EvoProgrammer inspect --target-dir /path/to/project --format env
EvoProgrammer inspect --target-dir /path/to/project --report-file ./inspect-report.env --report-format env
```

Use `verify` when you want EvoProgrammer to execute the detected command chain
itself:

```zsh
EvoProgrammer verify --target-dir /path/to/project
EvoProgrammer verify --target-dir /path/to/project --steps lint,test
EvoProgrammer verify --target-dir /path/to/project --steps lint,test --list --list-format env
EvoProgrammer verify --target-dir /path/to/project --steps lint,test --require-all
EvoProgrammer verify --target-dir /path/to/project --dry-run
EvoProgrammer verify --target-dir /path/to/project --report-file ./verify-report.env --report-format env
```

`inspect --format diagnostics` adds facts-cache counters for repo inspection, so
you can see cache lookups, hit rate, and entry counts when profiling detection.

`once` and loop mode now also support `--auto-commit` and
`--auto-commit-message`. Auto-commit only stages and commits the paths that
became newly changed during the current iteration, so pre-existing dirty files
in the repo are left alone.

`inspect --format profiles` shows the matched language, framework, and
project-type candidates with their detection scores, which is useful when you
want to understand or debug auto-detection decisions.

`inspect --format commands` prints a tighter command-only view when you just
want the inferred dev/build/test/lint/typecheck plan without the rest of the
repository analysis.

`inspect --format agent`, `agent-json`, and `agent-env` expose a lighter-weight
agent-facing catalog of repo command surfaces, invocable helper programs, test
harnesses, and support CLIs. Those formats now also include a structured host
tool catalog with resolved executable paths, so wrappers can invoke repo-local
commands and machine tools without scraping human-readable text. They
intentionally skip the broader architecture and workflow report so wrappers can
fetch the callable tool menu with less detection work.

`catalog` exposes that same agent-facing tool menu as a first-class subcommand,
with `--kind all|commands|support` filters and `summary|json|env` output. Use it
when a wrapper or coding agent only needs callable repo surfaces and host
tooling without the wider inspection report.

`inspect --format env` exports the same resolved context as shell-safe
`EVOP_INSPECT_*` assignments, including detected workspace packages for
monorepos, so CI jobs and helper scripts can `source` the result instead of
re-parsing human-readable output.

`inspect --report-file` writes any inspect format to disk, including JSON and
shell-safe env exports for CI jobs and wrapper scripts.

`--context-file` lets `inspect`, `verify`, `doctor`, `once`, and loop mode reuse
an earlier `inspect --format env` snapshot instead of re-detecting the same
repository context every time. That is useful when you want reproducible CI
wrappers or faster repeated runs against the same repo state.

`verify` uses the same command-detection layer as prompt generation, so `doctor`,
`inspect`, agent prompts, and verification all agree on the repo's runnable
commands.

`verify --report-file` writes the executed step results, exit codes, durations,
and log paths as either JSON or shell-safe `EVOP_VERIFY_*` assignments. That
makes it easier to chain EvoProgrammer verification into CI or wrapper scripts
without parsing stdout.

`verify --list --list-format json|env` prints the selected verification plan
without executing it, which is useful for CI wrappers that want to inspect the
resolved commands first.

`verify --require-all` makes verification fail early when any selected step has
no detected command, which helps keep automation reproducible.

`status` now supports `--kind`, `--status`, and `--agent` filters, plus
`--format json|env` and `--report-file` for machine-readable run history export.

`profiles` lists the built-in language, framework, and project-type profiles,
including a short summary derived from prompt guidance plus the definition file
path. It supports `--category`, `--format summary|json|env`, and `--report-file`
for wrapper scripts and CI diagnostics.

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
| `PROFILES.sh` | Built-in profile catalog reporting |
| `lib/inspect.sh` | Inspect-format validation plus stdout/report-file dispatch |
| `lib/status.sh` | Status filtering, metadata parsing, and summary/json/env rendering |
| `lib/agents/definitions/` | Pluggable agent definitions |
| `lib/profiles/diagnostics.sh` | Matched profile candidates and detection-score reporting |
| `lib/profiles/report.sh` | Profile catalog summary/json/env rendering |
| `lib/profiles/candidates.sh` | Cheap candidate planning that narrows profile loading before hook execution |
| `lib/profiles/definitions/` | Language, framework, and project-type profiles |
| `lib/project-context/` | Repo inspection, command inference, and prompt rendering |

See [`docs/architecture.md`](./docs/architecture.md) for the current architecture
and layering model.

## Verification

```zsh
zsh tests/run_tests.sh
```
