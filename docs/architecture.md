# Architecture

EvoProgrammer is now organized around a small set of explicit layers instead of
mixing detection, prompt rendering, and command execution in the same path.

## Core Flow

1. `bin/EvoProgrammer` dispatches to a subcommand through a POSIX bootstrap shim and then re-execs into the preferred interactive shell.
2. CLI context resolution loads config, validates flags, and resolves the target directory.
3. Profile detection identifies language, framework, and project type.
4. Project inspection derives package manager, workspace mode, command plan, structure hints, conventions, and risk areas.
5. The result is consumed in one of three ways:
   - `LOOP.sh` / `MAIN.sh` inject it into the agent prompt.
   - `INSPECT.sh` prints it for humans or writes machine-readable report files.
   - `VERIFY.sh` executes the detected verification chain.

## Layers

### 1. Entry scripts

- `MAIN.sh`: iterative agent loop
- `LOOP.sh`: single agent iteration
- `DOCTOR.sh`: environment readiness check
- `INSPECT.sh`: repository inspection and prompt preview
- `VERIFY.sh`: command-chain execution for lint/typecheck/test/build

### 2. CLI and runtime

- `lib/cli.sh`: shared flag parsing and context finalization
- `lib/runtime.sh`: filesystem, artifacts, command capture, and path helpers
- `lib/config.sh`: `.evoprogrammer.conf` loading
- `lib/inspect.sh`: inspect-format validation and stdout/report-file dispatch

### 3. Profile system

- `lib/profiles/detect.sh`: profile entrypoints
- `lib/profiles/candidates.sh`: cheap candidate planning that narrows which profiles need to be loaded for a given repo and prompt
- `lib/profiles/diagnostics.sh`: matched-candidate and score tracking for profile auto-detection
- `lib/profiles/definitions/`: language/framework/project-type definitions
- `lib/profiles/resolve.sh`: merges explicit flags and auto-detection results

This layer answers: "What kind of repo is this?"

### 4. Project inspection

- `lib/project-context/commands.sh`: package manager and command-slot inference
- `lib/project-context/facts.sh`: cached filesystem, file-match, and manifest-text facts for repo inspection, plus cache diagnostics
- `lib/project-context/timings.sh`: phase timing capture for profile resolution and inspection diagnostics
- `lib/project-context/repo-analysis.sh`: structure, conventions, and risk hints
- `lib/project-context/workflow.sh`: task-kind workflow guidance
- `lib/project-context/render.sh`: prompt and human-readable rendering
- `lib/project-context/state.sh`: shared inspection state
- `lib/verify.sh`: reusable verification-report state and JSON/env rendering

This layer answers: "How should this repo be searched, changed, verified, and
operated?"

The facts and timings sub-layers expose diagnostics to the render layer, which
keeps `inspect --format diagnostics`, `inspect --format timings`, and
`inspect --format json` informative without leaking cache or measurement
internals into the CLI entrypoint. The facts cache now also stores manifest text
for repeated literal lookups so repo analysis can avoid re-reading the same
files dozens of times in one inspection pass.

The profile candidate and diagnostics sub-layers keep auto-detection both fast
and observable. Candidate planning narrows the expensive hook-loading path using
cheap repo facts first, while diagnostics preserves the final matched candidates
without re-running detection logic in presentation code. That keeps
`inspect --format profiles`, `inspect --format env`, diagnostics output, and
JSON rendering aligned on the same detection state. The candidate layer now also
short-circuits obvious shell/CLI repositories so framework and project-type
detection do not source unrelated profile definitions.

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

## Detection Strategy

The architecture intentionally uses a hybrid approach.

- Rules handle stable facts: files, lockfiles, manifests, Make targets, common directory names.
- Profiles add domain-specific workflow guidance.
- The coding agent consumes that context and can still make softer inferences from code structure and the user request.

This keeps detection deterministic while still allowing the agent to reason about
ambiguous repos and task intent.
