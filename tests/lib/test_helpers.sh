#!/usr/bin/env zsh

# shellcheck disable=SC2034
# shellcheck source=lib/common.sh
# shellcheck source=lib/profile.sh
LOOP_SCRIPT="$ROOT_DIR/LOOP.sh"
MAIN_SCRIPT="$ROOT_DIR/MAIN.sh"
CLI_SCRIPT="$ROOT_DIR/bin/EvoProgrammer"
INSTALL_SCRIPT="$ROOT_DIR/install.sh"
DOCTOR_SCRIPT="$ROOT_DIR/DOCTOR.sh"
INSPECT_SCRIPT="$ROOT_DIR/INSPECT.sh"
VERIFY_SCRIPT="$ROOT_DIR/VERIFY.sh"
STATUS_SCRIPT="$ROOT_DIR/STATUS.sh"
PROFILES_SCRIPT="$ROOT_DIR/PROFILES.sh"

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

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local context="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
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
    local file_path="$1"
    local context="$2"
    if [[ ! -f "$file_path" ]]; then
        fail "$context"
    fi
}

assert_directory_exists() {
    local dir_path="$1"
    local context="$2"
    if [[ ! -d "$dir_path" ]]; then
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
#!/usr/bin/env zsh
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
#!/usr/bin/env zsh
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
    git -C "$TEST_TARGET_DIR" config user.name "EvoProgrammer Tests"
    git -C "$TEST_TARGET_DIR" config user.email "tests@example.com"

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
        "$TEST_CONTEXT_DIR/.github/workflows" \
        "$TEST_CONTEXT_DIR/.devcontainer" \
        "$TEST_CONTEXT_DIR/bin" \
        "$TEST_CONTEXT_DIR/tools" \
        "$TEST_CONTEXT_DIR/src/app" \
        "$TEST_CONTEXT_DIR/src/components" \
        "$TEST_CONTEXT_DIR/src/services" \
        "$TEST_CONTEXT_DIR/src/store" \
        "$TEST_CONTEXT_DIR/scripts" \
        "$TEST_CONTEXT_DIR/docs" \
        "$TEST_CONTEXT_DIR/tests" \
        "$TEST_CONTEXT_DIR/prisma" \
        "$TEST_CONTEXT_DIR/src/auth" \
        "$TEST_CONTEXT_DIR/packages/shared/src/types" \
        "$TEST_CONTEXT_DIR/config"

    printf 'packages:\n  - "packages/*"\n' >"$TEST_CONTEXT_DIR/pnpm-workspace.yaml"
    printf '{ "compilerOptions": { "strict": true } }\n' >"$TEST_CONTEXT_DIR/tsconfig.json"
    printf '{\n  "name": "context-app",\n  "scripts": {\n    "dev": "next dev",\n    "build": "next build",\n    "test": "vitest",\n    "lint": "eslint .",\n    "typecheck": "tsc --noEmit",\n    "inspect": "node scripts/inspect.js",\n    "clean": "node scripts/clean.js",\n    "generate": "node scripts/generate.js"\n  },\n  "dependencies": {\n    "next": "14.0.0",\n    "react": "18.2.0",\n    "tailwindcss": "3.4.0",\n    "zustand": "4.5.0",\n    "prisma": "5.0.0"\n  },\n  "devDependencies": {\n    "eslint": "9.0.0",\n    "prettier": "3.0.0",\n    "vitest": "2.0.0"\n  }\n}\n' >"$TEST_CONTEXT_DIR/package.json"
    printf 'export default function Page() { return null; }\n' >"$TEST_CONTEXT_DIR/src/app/page.tsx"
    printf 'export function Card() { return null; }\n' >"$TEST_CONTEXT_DIR/src/components/Card.tsx"
    printf 'export async function getDashboard() { return null; }\n' >"$TEST_CONTEXT_DIR/src/services/dashboard.ts"
    printf 'export const useStore = () => null;\n' >"$TEST_CONTEXT_DIR/src/store/app.ts"
    printf 'model User { id String @id }\n' >"$TEST_CONTEXT_DIR/prisma/schema.prisma"
    printf 'describe("dashboard", () => {});\n' >"$TEST_CONTEXT_DIR/tests/dashboard.test.ts"
    printf 'export const session = {};\n' >"$TEST_CONTEXT_DIR/src/auth/session.ts"
    printf 'export type SharedUser = { id: string };\n' >"$TEST_CONTEXT_DIR/packages/shared/src/types/user.ts"
    printf 'NEXT_PUBLIC_API_URL=http://localhost:3000\n' >"$TEST_CONTEXT_DIR/.env.example"
    printf 'name: ci\n' >"$TEST_CONTEXT_DIR/.github/workflows/ci.yml"
    printf '{ "name": "context-devcontainer" }\n' >"$TEST_CONTEXT_DIR/.devcontainer/devcontainer.json"
    printf 'FROM node:20\n' >"$TEST_CONTEXT_DIR/Dockerfile"
    printf 'version: "3.9"\nservices:\n  web:\n    build: .\n' >"$TEST_CONTEXT_DIR/docker-compose.yml"
    printf 'release workflow\n' >"$TEST_CONTEXT_DIR/scripts/release"
    chmod +x "$TEST_CONTEXT_DIR/scripts/release"
    printf '#!/usr/bin/env zsh\nprint context-tool\n' >"$TEST_CONTEXT_DIR/bin/context-tool"
    chmod +x "$TEST_CONTEXT_DIR/bin/context-tool"
    printf '#!/usr/bin/env zsh\nprint status\n' >"$TEST_CONTEXT_DIR/STATUS.sh"
    chmod +x "$TEST_CONTEXT_DIR/STATUS.sh"
    printf '#!/usr/bin/env zsh\nprint sync-context\n' >"$TEST_CONTEXT_DIR/tools/sync-context"
    chmod +x "$TEST_CONTEXT_DIR/tools/sync-context"
    printf '# Context app\n' >"$TEST_CONTEXT_DIR/docs/overview.md"
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

setup_verify_shell_workspace() {
    if [[ -n "${TEST_VERIFY_SHELL_DIR:-}" ]]; then
        return 0
    fi

    TEST_VERIFY_SHELL_DIR="$TEST_TMPDIR/verify-shell-project"
    TEST_VERIFY_SHELL_LOG="$TEST_TMPDIR/verify-shell.log"
    TEST_VERIFY_SHELL_BIN="$TEST_TMPDIR/verify-shell-bin"

    mkdir -p "$TEST_VERIFY_SHELL_DIR" "$TEST_VERIFY_SHELL_BIN"

    cat >"$TEST_VERIFY_SHELL_DIR/Makefile" <<'EOF'
lint:
	@true
EOF

    cat >"$TEST_VERIFY_SHELL_BIN/make" <<EOF
#!/usr/bin/env zsh
set -euo pipefail
printf '%s\n' "\${EVOP_PREFERRED_SHELL:-unknown}" >"$TEST_VERIFY_SHELL_LOG"
EOF
    chmod +x "$TEST_VERIFY_SHELL_BIN/make"
}

setup_flutter_workspace() {
    if [[ -n "${TEST_FLUTTER_DIR:-}" ]]; then
        return 0
    fi

    TEST_FLUTTER_DIR="$TEST_TMPDIR/flutter-app"
    mkdir -p \
        "$TEST_FLUTTER_DIR/lib" \
        "$TEST_FLUTTER_DIR/test" \
        "$TEST_FLUTTER_DIR/android/app/src/main" \
        "$TEST_FLUTTER_DIR/ios/Runner"

    cat >"$TEST_FLUTTER_DIR/pubspec.yaml" <<'EOF'
name: flutter_app
description: Test Flutter app
environment:
  sdk: ">=3.3.0 <4.0.0"
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
flutter:
  uses-material-design: true
EOF

    cat >"$TEST_FLUTTER_DIR/analysis_options.yaml" <<'EOF'
include: package:flutter_lints/flutter.yaml
EOF

    cat >"$TEST_FLUTTER_DIR/lib/main.dart" <<'EOF'
import 'package:flutter/material.dart';

void main() {
  runApp(const Placeholder());
}
EOF

    cat >"$TEST_FLUTTER_DIR/test/widget_test.dart" <<'EOF'
void main() {}
EOF
}

setup_aspnet_workspace() {
    if [[ -n "${TEST_ASPNET_DIR:-}" ]]; then
        return 0
    fi

    TEST_ASPNET_DIR="$TEST_TMPDIR/aspnet-service"
    mkdir -p \
        "$TEST_ASPNET_DIR/Controllers" \
        "$TEST_ASPNET_DIR/Properties" \
        "$TEST_ASPNET_DIR/tests"

    cat >"$TEST_ASPNET_DIR/DemoService.csproj" <<'EOF'
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>
EOF

    cat >"$TEST_ASPNET_DIR/Program.cs" <<'EOF'
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddControllers();
var app = builder.Build();
app.MapControllers();
app.Run();
EOF

    cat >"$TEST_ASPNET_DIR/appsettings.json" <<'EOF'
{
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}
EOF

    cat >"$TEST_ASPNET_DIR/Controllers/HealthController.cs" <<'EOF'
namespace Demo.Controllers;

public class HealthController {}
EOF
}

setup_java_service_workspace() {
    if [[ -n "${TEST_JAVA_SERVICE_DIR:-}" ]]; then
        return 0
    fi

    TEST_JAVA_SERVICE_DIR="$TEST_TMPDIR/java-service"
    mkdir -p \
        "$TEST_JAVA_SERVICE_DIR/src/main/java/com/example/api" \
        "$TEST_JAVA_SERVICE_DIR/src/test/java/com/example/api"

    cat >"$TEST_JAVA_SERVICE_DIR/build.gradle" <<'EOF'
plugins {
    id 'java'
    id 'org.springframework.boot' version '3.2.0'
}
EOF

    cat >"$TEST_JAVA_SERVICE_DIR/src/main/java/com/example/api/Application.java" <<'EOF'
package com.example.api;

public class Application {}
EOF

    cat >"$TEST_JAVA_SERVICE_DIR/src/test/java/com/example/api/ApplicationTest.java" <<'EOF'
package com.example.api;

public class ApplicationTest {}
EOF
}

setup_maui_workspace() {
    if [[ -n "${TEST_MAUI_DIR:-}" ]]; then
        return 0
    fi

    TEST_MAUI_DIR="$TEST_TMPDIR/maui-app"
    mkdir -p \
        "$TEST_MAUI_DIR/Platforms/Android" \
        "$TEST_MAUI_DIR/Platforms/iOS" \
        "$TEST_MAUI_DIR/Resources/Styles"

    cat >"$TEST_MAUI_DIR/DemoMaui.csproj" <<'EOF'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFrameworks>net8.0-android;net8.0-ios</TargetFrameworks>
    <OutputType>Exe</OutputType>
    <UseMaui>true</UseMaui>
    <SingleProject>true</SingleProject>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.Maui.Controls" Version="8.0.0" />
  </ItemGroup>
</Project>
EOF

    cat >"$TEST_MAUI_DIR/MauiProgram.cs" <<'EOF'
namespace DemoMaui;

public static class MauiProgram {}
EOF

    cat >"$TEST_MAUI_DIR/App.xaml" <<'EOF'
<?xml version="1.0" encoding="utf-8" ?>
<Application xmlns="http://schemas.microsoft.com/dotnet/2021/maui" />
EOF
}

setup_elixir_workspace() {
    if [[ -n "${TEST_ELIXIR_DIR:-}" ]]; then
        return 0
    fi

    TEST_ELIXIR_DIR="$TEST_TMPDIR/elixir-app"
    mkdir -p "$TEST_ELIXIR_DIR/lib" "$TEST_ELIXIR_DIR/test"

    cat >"$TEST_ELIXIR_DIR/mix.exs" <<'EOF'
defmodule Demo.MixProject do
  use Mix.Project

  def project do
    [
      app: :demo,
      version: "0.1.0",
      deps: []
    ]
  end
end
EOF

    cat >"$TEST_ELIXIR_DIR/lib/demo.ex" <<'EOF'
defmodule Demo do
end
EOF

    cat >"$TEST_ELIXIR_DIR/test/demo_test.exs" <<'EOF'
defmodule DemoTest do
  use ExUnit.Case
end
EOF
}

setup_scala_workspace() {
    if [[ -n "${TEST_SCALA_DIR:-}" ]]; then
        return 0
    fi

    TEST_SCALA_DIR="$TEST_TMPDIR/scala-app"
    mkdir -p "$TEST_SCALA_DIR/src/main/scala" "$TEST_SCALA_DIR/src/test/scala" "$TEST_SCALA_DIR/project"

    cat >"$TEST_SCALA_DIR/build.sbt" <<'EOF'
ThisBuild / scalaVersion := "3.3.1"

lazy val root = (project in file("."))
  .settings(
    name := "demo-scala"
  )
EOF

    cat >"$TEST_SCALA_DIR/project/build.properties" <<'EOF'
sbt.version=1.10.0
EOF

    cat >"$TEST_SCALA_DIR/src/main/scala/Main.scala" <<'EOF'
object Main extends App {
  println("hello")
}
EOF

    cat >"$TEST_SCALA_DIR/src/test/scala/MainSpec.scala" <<'EOF'
class MainSpec
EOF
}

setup_node_cli_workspace() {
    if [[ -n "${TEST_NODE_CLI_DIR:-}" ]]; then
        return 0
    fi

    TEST_NODE_CLI_DIR="$TEST_TMPDIR/node-cli"
    mkdir -p "$TEST_NODE_CLI_DIR/src"

    cat >"$TEST_NODE_CLI_DIR/package.json" <<'EOF'
{
  "name": "node-cli",
  "bin": {
    "node-cli": "dist/index.js"
  },
  "dependencies": {
    "commander": "12.0.0"
  }
}
EOF

    cat >"$TEST_NODE_CLI_DIR/src/index.ts" <<'EOF'
export {};
EOF
}

setup_node_monorepo_workspace() {
    if [[ -n "${TEST_NODE_MONOREPO_DIR:-}" ]]; then
        return 0
    fi

    TEST_NODE_MONOREPO_DIR="$TEST_TMPDIR/node-monorepo"
    setup_js_monorepo_workspace "$TEST_NODE_MONOREPO_DIR" pnpm
}

setup_yarn_monorepo_workspace() {
    if [[ -n "${TEST_YARN_MONOREPO_DIR:-}" ]]; then
        return 0
    fi

    TEST_YARN_MONOREPO_DIR="$TEST_TMPDIR/yarn-monorepo"
    setup_js_monorepo_workspace "$TEST_YARN_MONOREPO_DIR" yarn
}

setup_bun_monorepo_workspace() {
    if [[ -n "${TEST_BUN_MONOREPO_DIR:-}" ]]; then
        return 0
    fi

    TEST_BUN_MONOREPO_DIR="$TEST_TMPDIR/bun-monorepo"
    setup_js_monorepo_workspace "$TEST_BUN_MONOREPO_DIR" bun
}

setup_js_monorepo_workspace() {
    local workspace_dir="$1"
    local package_manager="$2"
    local root_package_manager_field=""

    mkdir -p \
        "$workspace_dir/apps/web/src" \
        "$workspace_dir/packages/shared/src" \
        "$workspace_dir/tools/release"

    case "$package_manager" in
        yarn)
            root_package_manager_field=$',\n  "packageManager": "yarn@4.6.0"'
            ;;
        bun)
            root_package_manager_field=$',\n  "packageManager": "bun@1.2.0"'
            ;;
    esac

    cat >"$workspace_dir/package.json" <<EOF
{
  "name": "node-monorepo",
  "private": true,
  "workspaces": [
    "apps/*",
    "packages/*"
  ]$root_package_manager_field
}
EOF

    case "$package_manager" in
        pnpm)
            cat >"$workspace_dir/pnpm-workspace.yaml" <<'EOF'
packages:
  - "apps/*"
  - "packages/*"
EOF
            ;;
        yarn)
            cat >"$workspace_dir/yarn.lock" <<'EOF'
# yarn lockfile v1
EOF
            cat >"$workspace_dir/.yarnrc.yml" <<'EOF'
nodeLinker: node-modules
EOF
            ;;
        bun)
            : >"$workspace_dir/bun.lock"
            ;;
    esac

    cat >"$workspace_dir/apps/web/package.json" <<'EOF'
{
  "name": "@demo/web",
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "lint": "eslint .",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "next": "15.0.0",
    "react": "19.0.0"
  }
}
EOF

    cat >"$workspace_dir/packages/shared/package.json" <<'EOF'
{
  "name": "@demo/shared",
  "scripts": {
    "test": "vitest run",
    "lint": "eslint ."
  }
}
EOF

    cat >"$workspace_dir/apps/web/src/page.tsx" <<'EOF'
export default function Page() {
  return null;
}
EOF

    cat >"$workspace_dir/packages/shared/src/index.ts" <<'EOF'
export const shared = true;
EOF
}

setup_expo_workspace() {
    if [[ -n "${TEST_EXPO_DIR:-}" ]]; then
        return 0
    fi

    TEST_EXPO_DIR="$TEST_TMPDIR/expo-app"
    mkdir -p "$TEST_EXPO_DIR/app" "$TEST_EXPO_DIR/components"

    cat >"$TEST_EXPO_DIR/package.json" <<'EOF'
{
  "name": "expo-app",
  "dependencies": {
    "expo": "~52.0.0",
    "expo-router": "~4.0.0",
    "react": "18.3.0",
    "react-native": "0.76.0"
  }
}
EOF

    cat >"$TEST_EXPO_DIR/app.json" <<'EOF'
{
  "expo": {
    "name": "Expo Demo",
    "slug": "expo-demo"
  }
}
EOF

    cat >"$TEST_EXPO_DIR/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "strict": true
  }
}
EOF

    cat >"$TEST_EXPO_DIR/app/index.tsx" <<'EOF'
export default function Screen() {
  return null;
}
EOF
}

setup_react_native_workspace() {
    if [[ -n "${TEST_REACT_NATIVE_DIR:-}" ]]; then
        return 0
    fi

    TEST_REACT_NATIVE_DIR="$TEST_TMPDIR/react-native-app"
    mkdir -p "$TEST_REACT_NATIVE_DIR/src"

    cat >"$TEST_REACT_NATIVE_DIR/package.json" <<'EOF'
{
  "name": "react-native-app",
  "dependencies": {
    "react": "18.3.0",
    "react-native": "0.76.0"
  }
}
EOF

    cat >"$TEST_REACT_NATIVE_DIR/metro.config.js" <<'EOF'
module.exports = {};
EOF

    cat >"$TEST_REACT_NATIVE_DIR/tsconfig.json" <<'EOF'
{
  "compilerOptions": {
    "strict": true
  }
}
EOF

    cat >"$TEST_REACT_NATIVE_DIR/App.tsx" <<'EOF'
export default function App() {
  return null;
}
EOF
}

setup_lua_workspace() {
    if [[ -n "${TEST_LUA_DIR:-}" ]]; then
        return 0
    fi

    TEST_LUA_DIR="$TEST_TMPDIR/lua-app"
    mkdir -p "$TEST_LUA_DIR/lua" "$TEST_LUA_DIR/spec"

    cat >"$TEST_LUA_DIR/demo-scm.rockspec" <<'EOF'
package = "demo"
version = "scm-1"
source = { url = "git://example.com/demo" }
description = {
  summary = "Demo Lua project"
}
build = {
  type = "builtin",
  modules = {
    ["demo.core"] = "lua/demo/core.lua"
  }
}
test = {
  type = "command",
  command = "busted"
}
EOF

    mkdir -p "$TEST_LUA_DIR/lua/demo"
    cat >"$TEST_LUA_DIR/lua/demo/core.lua" <<'EOF'
local M = {}

function M.answer()
  return 42
end

return M
EOF

    cat >"$TEST_LUA_DIR/spec/core_spec.lua" <<'EOF'
describe("core", function() end)
EOF
}

setup_godot_workspace() {
    if [[ -n "${TEST_GODOT_DIR:-}" ]]; then
        return 0
    fi

    TEST_GODOT_DIR="$TEST_TMPDIR/godot-game"
    mkdir -p "$TEST_GODOT_DIR/scenes"

    cat >"$TEST_GODOT_DIR/project.godot" <<'EOF'
[application]
config/name="TestGame"
EOF

    cat >"$TEST_GODOT_DIR/scenes/main.gd" <<'EOF'
extends Node
EOF
}

setup_zig_workspace() {
    if [[ -n "${TEST_ZIG_DIR:-}" ]]; then
        return 0
    fi

    TEST_ZIG_DIR="$TEST_TMPDIR/zig-app"
    mkdir -p "$TEST_ZIG_DIR/src" "$TEST_ZIG_DIR/test"

    cat >"$TEST_ZIG_DIR/build.zig" <<'EOF'
const std = @import("std");

pub fn build(_: *std.Build) void {}
EOF

    cat >"$TEST_ZIG_DIR/src/main.zig" <<'EOF'
pub fn main() void {}
EOF

    cat >"$TEST_ZIG_DIR/test/basic.zig" <<'EOF'
test "basic" {}
EOF
}

setup_haskell_workspace() {
    if [[ -n "${TEST_HASKELL_DIR:-}" ]]; then
        return 0
    fi

    TEST_HASKELL_DIR="$TEST_TMPDIR/haskell-app"
    mkdir -p "$TEST_HASKELL_DIR/app" "$TEST_HASKELL_DIR/src" "$TEST_HASKELL_DIR/test"

    cat >"$TEST_HASKELL_DIR/stack.yaml" <<'EOF'
resolver: lts-22.0
packages:
  - .
EOF

    cat >"$TEST_HASKELL_DIR/demo.cabal" <<'EOF'
cabal-version: 2.4
name: demo
version: 0.1.0.0

library
  exposed-modules: Demo
  hs-source-dirs: src
  build-depends: base
  default-language: Haskell2010

test-suite demo-test
  type: exitcode-stdio-1.0
  hs-source-dirs: test
  main-is: Spec.hs
  build-depends: base, demo
  default-language: Haskell2010
EOF

    cat >"$TEST_HASKELL_DIR/src/Demo.hs" <<'EOF'
module Demo where
demo :: String
demo = "demo"
EOF

    cat >"$TEST_HASKELL_DIR/test/Spec.hs" <<'EOF'
main :: IO ()
main = pure ()
EOF
}

setup_clojure_workspace() {
    if [[ -n "${TEST_CLOJURE_DIR:-}" ]]; then
        return 0
    fi

    TEST_CLOJURE_DIR="$TEST_TMPDIR/clojure-app"
    mkdir -p "$TEST_CLOJURE_DIR/src/demo" "$TEST_CLOJURE_DIR/test/demo"

    cat >"$TEST_CLOJURE_DIR/deps.edn" <<'EOF'
{:paths ["src"]
 :aliases {:test {:extra-paths ["test"]}}}
EOF

    cat >"$TEST_CLOJURE_DIR/src/demo/core.clj" <<'EOF'
(ns demo.core)

(defn answer [] 42)
EOF

    cat >"$TEST_CLOJURE_DIR/test/demo/core_test.clj" <<'EOF'
(ns demo.core-test)
EOF
}

setup_julia_workspace() {
    if [[ -n "${TEST_JULIA_DIR:-}" ]]; then
        return 0
    fi

    TEST_JULIA_DIR="$TEST_TMPDIR/julia-app"
    mkdir -p "$TEST_JULIA_DIR/src" "$TEST_JULIA_DIR/test"

    cat >"$TEST_JULIA_DIR/Project.toml" <<'EOF'
name = "Demo"
uuid = "00000000-0000-0000-0000-000000000000"
version = "0.1.0"
EOF

    cat >"$TEST_JULIA_DIR/src/Demo.jl" <<'EOF'
module Demo
end
EOF

    cat >"$TEST_JULIA_DIR/test/runtests.jl" <<'EOF'
using Test
EOF
}

setup_data_pipeline_workspace() {
    if [[ -n "${TEST_DATA_PIPELINE_DIR:-}" ]]; then
        return 0
    fi

    TEST_DATA_PIPELINE_DIR="$TEST_TMPDIR/data-pipeline"
    mkdir -p "$TEST_DATA_PIPELINE_DIR/dags" "$TEST_DATA_PIPELINE_DIR/jobs" "$TEST_DATA_PIPELINE_DIR/tests"

    cat >"$TEST_DATA_PIPELINE_DIR/pyproject.toml" <<'EOF'
[project]
name = "demo-pipeline"
version = "0.1.0"
dependencies = ["prefect", "pytest"]
EOF

    cat >"$TEST_DATA_PIPELINE_DIR/dags/ingest.py" <<'EOF'
def build_flow():
    return None
EOF

    cat >"$TEST_DATA_PIPELINE_DIR/tests/test_ingest.py" <<'EOF'
def test_ingest():
    assert True
EOF
}

setup_r_shiny_workspace() {
    if [[ -n "${TEST_R_SHINY_DIR:-}" ]]; then
        return 0
    fi

    TEST_R_SHINY_DIR="$TEST_TMPDIR/r-shiny-app"
    mkdir -p "$TEST_R_SHINY_DIR/R" "$TEST_R_SHINY_DIR/tests/testthat"

    cat >"$TEST_R_SHINY_DIR/DESCRIPTION" <<'EOF'
Package: shinydemo
Title: Demo Shiny App
Version: 0.1.0
Imports:
    shiny,
    testthat,
    lintr
EOF

    cat >"$TEST_R_SHINY_DIR/app.R" <<'EOF'
library(shiny)

ui <- fluidPage("demo")
server <- function(input, output, session) {}

shinyApp(ui, server)
EOF

    cat >"$TEST_R_SHINY_DIR/R/helpers.R" <<'EOF'
build_message <- function() {
  "demo"
}
EOF

    cat >"$TEST_R_SHINY_DIR/tests/testthat.R" <<'EOF'
library(testthat)
test_check("shinydemo")
EOF

    cat >"$TEST_R_SHINY_DIR/tests/testthat/test-app.R" <<'EOF'
test_that("app is configured", {
  expect_true(TRUE)
})
EOF

    cat >"$TEST_R_SHINY_DIR/.lintr" <<'EOF'
linters: linters_with_defaults()
EOF
}

setup_terraform_workspace() {
    if [[ -n "${TEST_TERRAFORM_DIR:-}" ]]; then
        return 0
    fi

    TEST_TERRAFORM_DIR="$TEST_TMPDIR/terraform-infra"
    mkdir -p "$TEST_TERRAFORM_DIR/modules/network" "$TEST_TERRAFORM_DIR/tests"

    cat >"$TEST_TERRAFORM_DIR/main.tf" <<'EOF'
terraform {
  required_version = ">= 1.6.0"
}

module "network" {
  source = "./modules/network"
}
EOF

    cat >"$TEST_TERRAFORM_DIR/modules/network/main.tf" <<'EOF'
resource "null_resource" "demo" {}
EOF

    cat >"$TEST_TERRAFORM_DIR/tests/basic.tftest.hcl" <<'EOF'
run "plan" {
  command = plan
}
EOF
}

setup_plugin_workspace() {
    if [[ -n "${TEST_PLUGIN_DIR:-}" ]]; then
        return 0
    fi

    TEST_PLUGIN_DIR="$TEST_TMPDIR/plugin-project"
    mkdir -p "$TEST_PLUGIN_DIR/src"

    cat >"$TEST_PLUGIN_DIR/package.json" <<'EOF'
{
  "name": "vite-plugin-demo",
  "keywords": ["plugin", "vite-plugin"],
  "exports": "./src/index.js"
}
EOF

    cat >"$TEST_PLUGIN_DIR/src/index.js" <<'EOF'
export default function demoPlugin() {}
EOF
}

setup_embedded_workspace() {
    if [[ -n "${TEST_EMBEDDED_DIR:-}" ]]; then
        return 0
    fi

    TEST_EMBEDDED_DIR="$TEST_TMPDIR/embedded-fw"
    mkdir -p "$TEST_EMBEDDED_DIR/firmware" "$TEST_EMBEDDED_DIR/boards"

    cat >"$TEST_EMBEDDED_DIR/platformio.ini" <<'EOF'
[env:test]
platform = espressif32
board = esp32dev
framework = arduino
EOF

    cat >"$TEST_EMBEDDED_DIR/firmware/main.cpp" <<'EOF'
int main() { return 0; }
EOF
}

setup_library_workspace() {
    if [[ -n "${TEST_LIBRARY_DIR:-}" ]]; then
        return 0
    fi

    TEST_LIBRARY_DIR="$TEST_TMPDIR/library-project"
    mkdir -p "$TEST_LIBRARY_DIR/src"

    cat >"$TEST_LIBRARY_DIR/Cargo.toml" <<'EOF'
[package]
name = "demo-lib"
version = "0.1.0"
edition = "2021"
EOF

    cat >"$TEST_LIBRARY_DIR/src/lib.rs" <<'EOF'
pub fn demo() -> &'static str {
    "demo"
}
EOF
}
