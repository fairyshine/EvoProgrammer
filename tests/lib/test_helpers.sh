#!/usr/bin/env bash

LOOP_SCRIPT="$ROOT_DIR/LOOP.sh"
MAIN_SCRIPT="$ROOT_DIR/MAIN.sh"
CLI_SCRIPT="$ROOT_DIR/bin/EvoProgrammer"
INSTALL_SCRIPT="$ROOT_DIR/install.sh"
DOCTOR_SCRIPT="$ROOT_DIR/DOCTOR.sh"
INSPECT_SCRIPT="$ROOT_DIR/INSPECT.sh"
VERIFY_SCRIPT="$ROOT_DIR/VERIFY.sh"

source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

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

count_non_empty_lines() {
    awk 'NF { count++ } END { print count + 0 }'
}

assert_profile_guidance_in_output() {
    local output="$1"
    local category="$2"
    local profile_name="$3"
    local context="$4"
    local prompt_line=""
    local profile_prompt=""

    profile_prompt="$(evop_print_profile_prompt "$category" "$profile_name")"

    while IFS= read -r prompt_line; do
        [[ -n "$prompt_line" ]] || continue
        assert_contains "$output" "$prompt_line" "$context"
    done <<<"$profile_prompt"
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

setup_agent_test_workspace() {
    if [[ -n "${TEST_TARGET_DIR:-}" ]]; then
        return 0
    fi

    FAKE_CODEX_LOG="$TEST_TMPDIR/bootstrap-codex.log"
    export FAKE_CODEX_LOG
    TEST_FAKE_BIN="$(setup_fake_codex)"
    setup_fake_claude >/dev/null

    TEST_TARGET_DIR="$TEST_TMPDIR/project"
    mkdir -p "$TEST_TARGET_DIR"
    git init -q "$TEST_TARGET_DIR"

    TEST_TARGET_DIR_PHYSICAL="$(cd "$TEST_TARGET_DIR" && pwd -P)"
    TEST_PROMPT_FILE="$TEST_TMPDIR/prompt.txt"
    printf 'ship from file' >"$TEST_PROMPT_FILE"

    TEST_DEFAULT_ARTIFACTS_ROOT="$TEST_TARGET_DIR/.evoprogrammer/runs"
    TEST_EXCLUDE_FILE="$TEST_TARGET_DIR/.git/info/exclude"
}

setup_context_workspace() {
    if [[ -n "${TEST_CONTEXT_DIR:-}" ]]; then
        return 0
    fi

    TEST_CONTEXT_DIR="$TEST_TMPDIR/context-web"
    mkdir -p \
        "$TEST_CONTEXT_DIR/src/app" \
        "$TEST_CONTEXT_DIR/src/components" \
        "$TEST_CONTEXT_DIR/src/services" \
        "$TEST_CONTEXT_DIR/src/store" \
        "$TEST_CONTEXT_DIR/tests" \
        "$TEST_CONTEXT_DIR/prisma" \
        "$TEST_CONTEXT_DIR/src/auth" \
        "$TEST_CONTEXT_DIR/packages/shared/src/types" \
        "$TEST_CONTEXT_DIR/config"

    printf 'packages:\n  - "packages/*"\n' >"$TEST_CONTEXT_DIR/pnpm-workspace.yaml"
    printf '{ "compilerOptions": { "strict": true } }\n' >"$TEST_CONTEXT_DIR/tsconfig.json"
    printf '{\n  "name": "context-app",\n  "scripts": {\n    "dev": "next dev",\n    "build": "next build",\n    "test": "vitest",\n    "lint": "eslint .",\n    "typecheck": "tsc --noEmit"\n  },\n  "dependencies": {\n    "next": "14.0.0",\n    "react": "18.2.0",\n    "tailwindcss": "3.4.0",\n    "zustand": "4.5.0",\n    "prisma": "5.0.0"\n  },\n  "devDependencies": {\n    "eslint": "9.0.0",\n    "prettier": "3.0.0",\n    "vitest": "2.0.0"\n  }\n}\n' >"$TEST_CONTEXT_DIR/package.json"
    printf 'export default function Page() { return null; }\n' >"$TEST_CONTEXT_DIR/src/app/page.tsx"
    printf 'export function Card() { return null; }\n' >"$TEST_CONTEXT_DIR/src/components/Card.tsx"
    printf 'export async function getDashboard() { return null; }\n' >"$TEST_CONTEXT_DIR/src/services/dashboard.ts"
    printf 'export const useStore = () => null;\n' >"$TEST_CONTEXT_DIR/src/store/app.ts"
    printf 'model User { id String @id }\n' >"$TEST_CONTEXT_DIR/prisma/schema.prisma"
    printf 'describe("dashboard", () => {});\n' >"$TEST_CONTEXT_DIR/tests/dashboard.test.ts"
    printf 'export const session = {};\n' >"$TEST_CONTEXT_DIR/src/auth/session.ts"
    printf 'export type SharedUser = { id: string };\n' >"$TEST_CONTEXT_DIR/packages/shared/src/types/user.ts"
    printf 'NEXT_PUBLIC_API_URL=http://localhost:3000\n' >"$TEST_CONTEXT_DIR/.env.example"
}

setup_verify_workspace() {
    if [[ -n "${TEST_VERIFY_DIR:-}" ]]; then
        return 0
    fi

    TEST_VERIFY_DIR="$TEST_TMPDIR/verify-project"
    TEST_VERIFY_LOG="$TEST_TMPDIR/verify-steps.log"
    mkdir -p "$TEST_VERIFY_DIR"

    cat >"$TEST_VERIFY_DIR/Makefile" <<EOF
lint:
	@printf 'lint\n' >>"$TEST_VERIFY_LOG"

typecheck:
	@printf 'typecheck\n' >>"$TEST_VERIFY_LOG"

test:
	@printf 'test\n' >>"$TEST_VERIFY_LOG"

build:
	@printf 'build\n' >>"$TEST_VERIFY_LOG"
EOF
}
