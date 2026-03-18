# Architecture

EvoProgrammer is now organized around a small set of explicit layers instead of
mixing detection, prompt rendering, and command execution in the same path.

## Core Flow

1. `bin/EvoProgrammer` dispatches to a subcommand through a POSIX bootstrap shim and then re-execs into `zsh`.
2. CLI context resolution loads config, validates flags, and resolves the target directory.
3. Profile detection identifies language, framework, and project type.
4. Project inspection derives package manager, workspace mode, command plan, structure hints, conventions, and risk areas.
5. The result is consumed in one of three ways:
   - `LOOP.sh` / `MAIN.sh` inject it into the agent prompt.
   - `INSPECT.sh` prints it for humans or writes machine-readable report files.
   - `VERIFY.sh` executes the detected verification chain.
   - `PROFILES.sh` exposes the built-in profile catalog for humans and wrappers.

## Layers

### 1. Entry scripts

- `MAIN.sh`: iterative agent loop
- `LOOP.sh`: single agent iteration
- `DOCTOR.sh`: environment readiness check
- `INSPECT.sh`: repository inspection and prompt preview
- `VERIFY.sh`: command-chain execution for lint/typecheck/test/build
- `STATUS.sh`: run-history filtering and report export
- `PROFILES.sh`: built-in profile catalog reporting

### 2. CLI and runtime

- `lib/cli.sh`: shared flag parsing and context finalization
- `lib/runtime.sh`: filesystem, artifacts, command capture, and path helpers
- `lib/git.sh`: iteration-scoped git diff snapshots and safe auto-commit helpers
- `lib/config.sh`: `.evoprogrammer.conf` loading
- `lib/prompt-facts.sh`: cached structured prompt-fact extraction shared by profile resolution and workflow rebuilding
- `lib/inspect.sh`: inspect-format validation and stdout/report-file dispatch
- `lib/status-collect.sh`: status filtering and metadata collection
- `lib/status-render.sh`: summary/json/env rendering for status output
- `lib/status.sh`: aggregator for status helpers
- `lib/profiles/report.sh`: profile-catalog validation and summary/json/env rendering
- `lib/verify-state.sh`: reusable verification report state
- `lib/verify-render.sh`: JSON/env rendering for verification reports
- `lib/verify-plan.sh`: plan printing and missing-command enforcement
- `lib/verify.sh`: aggregator for verification helpers

### 3. Profile system

- `lib/profiles/detect.sh`: profile entrypoints
- `lib/profiles/candidates-common.sh`: shared candidate state and shell-CLI prefilters
- `lib/profiles/ecosystem-facts.sh`: cached manifest-text probes shared by candidate planning and repo-shape heuristics
- `lib/profiles/repo-shape.sh`: cached repository-shape heuristics shared by candidate planning and detect hooks
- `lib/profiles/candidates-languages.sh`: language candidate planning
- `lib/profiles/candidates-frameworks.sh`: framework candidate planning
- `lib/profiles/candidates-project-types.sh`: project-type candidate planning
- `lib/profiles/candidates.sh`: aggregator for candidate planning
- `lib/profiles/diagnostics.sh`: matched-candidate and score tracking for profile auto-detection
- `lib/profiles/definitions/`: language/framework/project-type definitions
- `lib/profiles/report.sh`: reusable catalog rendering for the `profiles` command
- `lib/profiles/resolve.sh`: merges explicit flags and auto-detection results
- `lib/profiles/facts-cache.sh`: cached repo facts for profile detection
- `lib/profiles/facts-files.sh`: file/path/pattern helpers for profile detection
- `lib/profiles/facts-text.sh`: lowercased file-text and prompt matching helpers
- `lib/profiles/detect-helpers.sh`: aggregator for profile-detection fact helpers

This layer answers: "What kind of repo is this?"

Profile definitions now also use an in-process cache for prompt text and copied
detect/apply hooks. That keeps repeated prompt rendering, project-context hook
application, and related reporting paths from re-sourcing the same definition
multiple times in one command execution.

Repository-shape heuristics now live in a shared helper layer instead of being
duplicated across project-type candidate planning and individual detect hooks.
That keeps CLI-tool, backend-service, desktop-app, and game-project
classification aligned while still allowing prompt-driven overrides when the
repo shape is ambiguous. The same layer now also centralizes higher-signal
library, plugin, data-pipeline, and embedded-system heuristics so those
project types no longer depend on prompt keywords alone.

Manifest-level ecosystem probes now also live in their own helper layer. That
keeps Node, Python, Cargo, Go, Composer, Gem, Mix, and JVM dependency checks
cached and reusable across framework detection, repo-shape inference, and new
ecosystem support such as Astro, Nuxt, Phoenix, Scala, Lua, and infrastructure
repositories without scattering repeated text scans through multiple modules.
Node package detection now also builds a cached quoted-token index for
`package.json`, so repeated framework and repo-shape checks reuse exact package
lookups instead of rescanning manifest text for every candidate. That both
trims the hot path for JavaScript repositories and avoids false positives from
script bodies or other non-dependency text. The same shared repo-shape layer
now also centralizes Expo and React Native mobile-app heuristics so framework,
project-type, and command detection stay aligned.

The same ecosystem layer now also exposes shared .NET project markers and
manifest-property probes. That keeps C#, F#, and Visual Basic language
detection, console-CLI classification, workspace manifest discovery, and
`dotnet` command inference aligned on one cached set of repository facts
instead of repeating `.sln` / `*.proj` checks across multiple modules.

The repo-shape layer now also exposes cached browser-game and multiplayer-game
runtime markers. That lets `browser-game`, `online-game`, and
`single-player-game` classification share the same narrowed heuristics instead
of re-checking the same Phaser / Pixi / socket / engine-networking signals in
candidate planning and detect hooks separately.

### 4. Project inspection

- `lib/project-context/slots.sh`: centralized command-slot metadata
- `lib/project-context/commands.sh`: package manager and command-slot inference
- `lib/project-context/facts-cache.sh`: cached filesystem and manifest lookup state
- `lib/project-context/facts-files.sh`: cached file, regex, literal, and Makefile queries
- `lib/project-context/facts-diagnostics.sh`: facts-cache diagnostics rendering
- `lib/project-context/facts.sh`: aggregator for repo-inspection facts helpers
- `lib/project-context/timings.sh`: phase timing capture for profile resolution and inspection diagnostics
- `lib/project-context/repo-analysis.sh`: structure, conventions, and risk hints
- `lib/project-context/workflow.sh`: task-kind workflow guidance
- `lib/project-context/snapshot.sh`: reusable inspect-env snapshot loading and workflow refresh
- `lib/project-context/render-base.sh`: shared text and JSON rendering primitives
- `lib/project-context/render-json.sh`: JSON inspection rendering
- `lib/project-context/render-env.sh`: shell-safe env export rendering
- `lib/project-context/render-prompt.sh`: prompt-context rendering
- `lib/project-context/render-summary.sh`: summary and human-readable rendering
- `lib/project-context/render-diagnostics.sh`: diagnostics and timings rendering
- `lib/project-context/render.sh`: aggregator for render helpers
- `lib/project-context/state.sh`: shared inspection state

This layer answers: "How should this repo be searched, changed, verified, and
operated?"

The facts and timings sub-layers expose diagnostics to the render layer, which
keeps `inspect --format diagnostics`, `inspect --format timings`, and
`inspect --format json` informative without leaking cache or measurement
internals into the CLI entrypoint. The facts cache now also stores manifest text
for repeated literal lookups so repo analysis can avoid re-reading the same
files dozens of times in one inspection pass. Cache entry counts are also
tracked as first-class diagnostics now, so rendering diagnostics or replaying a
saved inspection snapshot does not need to recount cache contents.

That facts layer now also caches Makefile target extraction and reuses cached
manifest text for repeated package.json script checks. The implementation is
now zsh-only and uses associative arrays directly rather than carrying a second
fallback cache backend for shells the project no longer targets.

The same facts layer now also caches nested workspace manifest discovery for
common monorepo roots such as `apps/`, `packages/`, `services/`, `crates/`,
and `tools/`. That lets command inference, architecture hints, prompt context,
JSON/env export, and snapshot reuse share one discovery pass instead of each
re-scanning the workspace tree. JavaScript workspaces can now also fall back to
recursive pnpm/npm commands when the root `package.json` does not define its
own scripts, which keeps `inspect` and `verify` useful for package-oriented
monorepos without adding a second command-planning path.

The snapshot sub-layer lets other entrypoints reuse an earlier
`inspect --format env` report. That keeps profile resolution and repo analysis
centralized in one place while allowing `verify`, `doctor`, `LOOP.sh`, and
`MAIN.sh` to skip repeated inspection work when the repo context is already
known. Prompt-dependent workflow guidance is rebuilt on top of the reused repo
context so `--context-file` remains compatible with different task prompts.

The profile candidate and diagnostics sub-layers keep auto-detection both fast
and observable. Candidate planning narrows the expensive hook-loading path using
cheap repo facts first, while diagnostics preserves the final matched candidates
without re-running detection logic in presentation code. That keeps
`inspect --format profiles`, `inspect --format env`, diagnostics output, and
JSON rendering aligned on the same detection state. The candidate layer now also
short-circuits obvious shell/CLI repositories so framework and project-type
detection do not source unrelated profile definitions. Repository-shape checks
are cached as first-class candidate facts now, which avoids recomputing the
same shell-CLI classification across language, framework, and project-type
detection passes in one inspection run.

Structured prompt facts now also live in a small shared helper layer instead of
being reparsed independently by profile resolution, candidate planning, and
workflow rebuilding. That lets explicit prompt sections such as
`[Language Adaptation]`, `[Project-Type Adaptation]`, and
`[Recommended Workflow]` act as first-class hints for exact profile IDs and task
kinds, while keeping that parsing work cached to a single pass per prompt.

Prompt keyword matching now also reuses a normalized lowercase prompt context
across candidate planning and hook-based detection. That keeps language,
framework, and project-type passes from repeatedly lowercasing the same prompt
dozens of times in one inspection run, which trims the hot path for prompt-rich
invocations without changing detection behavior.

The detection facts layer now also indexes file extensions directly. That keeps
common candidate checks such as `.kt`, `.csproj`, `.ipynb`, `.tex`, and similar
signals on top of set lookups instead of repeatedly scanning every collected
basename for glob matches. Repeated glob-style filename checks are now cached
too, which trims redundant `*.cabal`, `*.ino`, `*.zig`, and similar scans across
language, framework, and project-type detection passes in one inspection run.
The same layer now also keeps basename and simple-extension indexes for the
collected file list, so exact filename and `*.ext` lookups can answer common
detection and manifest queries without rescanning every collected file.

Project inspection now also derives cached agent command surfaces alongside the
verification slots. That lightweight index focuses on directly invocable repo
executables, top-level shell entrypoints, and non-verification helper commands
from `package.json` or `Makefile`. It now also includes executable helper
programs under common repo-local automation directories such as `scripts/`,
`tools/`, `hack/`, and `dev/`, so coding agents can discover more of the
commands the repository already exposes. The result gives coding agents a
clearer tool menu without forcing prompt generation, JSON export, env
snapshots, and human-readable inspection output to rescan the same command
surfaces.

Package-script discovery in the same layer now also uses a dedicated cached
script-name index per `package.json`. That lets command planning, workspace
script inference, and agent-surface rendering reuse one parse instead of
re-running separate script-name regex checks across the same manifest.

The same inspection layer now also derives cached agent support tools for the
current machine. That availability index keeps prompt context, `inspect`
reports, and snapshot reuse aligned on which host CLIs are actually callable
for search, shell scripting, package management, runtimes, and container
operations without repeating `command -v` probes across the same execution.

## Command Model

Commands are treated as first-class slots:

- `dev`
- `build`
- `test`
- `lint`
- `typecheck`

Each slot stores:

- the detected command
- the source of that command, such as `package.json script`, `make target`, or
  language defaults

That makes the command plan reusable across:

- prompt generation
- `doctor`
- `inspect`
- `verify`
- metadata written into artifacts

Verification execution also records first-class step results, durations, and log
paths. `VERIFY.sh` can emit that report as JSON or shell-safe env assignments so
CI and helper scripts can consume the same execution state without scraping the
human-readable log stream.

Loop and one-shot execution now follow the same first-class state model for git
history too. When `--auto-commit` is enabled, `lib/git.sh` snapshots the repo's
pre-iteration dirty paths, compares the post-iteration working tree, and only
stages or commits the paths that became newly changed during that iteration.
That keeps pre-existing dirty worktree files out of EvoProgrammer-managed
commits while still allowing repeated automated runs to checkpoint their
progress.

Verification planning follows the same pattern now: `verify --list` can emit the
selected step plan as summary, JSON, or env output, and `--require-all` lets CI
fail early when a required verification command is missing.

Status reporting now follows the same model: `STATUS.sh` can filter runs versus
sessions, narrow by recorded status or agent, and emit the selected history as
human-readable text, JSON, or shell-safe env assignments for wrappers and CI.

Profile catalog reporting follows the same pattern too: `PROFILES.sh` can emit
human-readable summaries, JSON, or shell-safe env assignments so wrappers can
discover supported built-in profiles without scraping the README.

## Detection Strategy

The architecture intentionally uses a hybrid approach.

- Rules handle stable facts: files, lockfiles, manifests, Make targets, common directory names.
- Profiles add domain-specific workflow guidance.
- The coding agent consumes that context and can still make softer inferences from code structure and the user request.

This keeps detection deterministic while still allowing the agent to reason about
ambiguous repos and task intent.

## Runtime Baseline

EvoProgrammer now targets `zsh` as its single runtime baseline.

- User-facing entrypoints still use `#!/bin/sh` shims where needed.
- Those shims immediately re-exec into `zsh`.
- The library layer, test harness, and static syntax validation all assume `zsh`.
- `shellcheck` is limited to the true POSIX bootstrap shim; the rest of the repository is syntax-checked with `zsh -n`.
