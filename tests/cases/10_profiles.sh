#!/usr/bin/env zsh

profile_catalog_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

printf 'languages=%s\n' "$(evop_supported_profiles_as_string languages)"
printf 'frameworks=%s\n' "$(evop_supported_profiles_as_string frameworks)"
printf 'project-types=%s\n' "$(evop_supported_profiles_as_string project-types)"
EOF
)"
assert_contains "$profile_catalog_output" " cpp " "Profile catalog should expose language profiles"
assert_contains "$profile_catalog_output" "languages=c " "Profile catalog should expose the C language profile"
assert_contains "$profile_catalog_output" "dart" "Profile catalog should expose the Dart language profile"
assert_contains "$profile_catalog_output" "elixir" "Profile catalog should expose the Elixir language profile"
assert_contains "$profile_catalog_output" "scala" "Profile catalog should expose the Scala language profile"
assert_contains "$profile_catalog_output" "lua" "Profile catalog should expose the Lua language profile"
assert_contains "$profile_catalog_output" "clojure" "Profile catalog should expose the Clojure language profile"
assert_contains "$profile_catalog_output" "haskell" "Profile catalog should expose the Haskell language profile"
assert_contains "$profile_catalog_output" "julia" "Profile catalog should expose the Julia language profile"
assert_contains "$profile_catalog_output" "zig" "Profile catalog should expose the Zig language profile"
assert_contains "$profile_catalog_output" "r" "Profile catalog should expose the R language profile"
assert_contains "$profile_catalog_output" "terraform" "Profile catalog should expose the Terraform language profile"
assert_contains "$profile_catalog_output" "frameworks=actix-web" "Profile catalog should expose framework profiles"
assert_contains "$profile_catalog_output" "flutter" "Profile catalog should expose the Flutter framework profile"
assert_contains "$profile_catalog_output" "astro" "Profile catalog should expose the Astro framework profile"
assert_contains "$profile_catalog_output" "aspnet-core" "Profile catalog should expose the ASP.NET Core framework profile"
assert_contains "$profile_catalog_output" "expo" "Profile catalog should expose the Expo framework profile"
assert_contains "$profile_catalog_output" "maui" "Profile catalog should expose the .NET MAUI framework profile"
assert_contains "$profile_catalog_output" "nuxt" "Profile catalog should expose the Nuxt framework profile"
assert_contains "$profile_catalog_output" "phoenix" "Profile catalog should expose the Phoenix framework profile"
assert_contains "$profile_catalog_output" "react-native" "Profile catalog should expose the React Native framework profile"
assert_contains "$profile_catalog_output" "shiny" "Profile catalog should expose the Shiny framework profile"
assert_contains "$profile_catalog_output" "project-types=ai-agent" "Profile catalog should expose project-type profiles"
assert_contains "$profile_catalog_output" "mobile-app" "Profile catalog should expose the mobile-app project type"
assert_contains "$profile_catalog_output" "infrastructure" "Profile catalog should expose the infrastructure project type"
pass "Profile catalog"

profile_hook_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/tests"

evop_reset_project_context
evop_apply_profile_project_context_hooks "languages" "python" "$tmpdir" "fix a failing endpoint"

printf 'search=%s\n' "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY"
printf 'verify=%s\n' "$EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY"
EOF
)"
assert_contains "$profile_hook_output" "Inspect package entrypoints, service modules, schemas, and tests before editing." "Language profiles should be able to contribute project-context search guidance"
assert_contains "$profile_hook_output" "Existing pytest-style tests are present; extend the nearest coverage before broadening integration checks." "Profile hooks should be able to add dynamic analysis based on the target directory"
pass "Profile project-context hooks"

profile_cache_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/test"
printf 'name: dart_app\nflutter:\n  uses-material-design: true\n' >"$tmpdir/pubspec.yaml"

first_prompt="$(evop_print_profile_prompt frameworks flutter)"
second_prompt="$(evop_print_profile_prompt frameworks flutter)"

evop_reset_project_context
evop_apply_profile_project_context_hooks "frameworks" "flutter" "$tmpdir" ""

printf 'same_prompt=%s\n' "$([[ "$first_prompt" == "$second_prompt" ]] && printf true || printf false)"
printf 'search=%s\n' "$EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY"
EOF
)"
assert_contains "$profile_cache_output" "same_prompt=true" "Profile caching should preserve repeated prompt rendering"
assert_contains "$profile_cache_output" "integration_test/" "Profile caching should preserve apply-project-context hooks"
pass "Profile definition cache reuse"

profile_catalog_zsh_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

printf 'languages=%s\n' "$(evop_supported_profiles_as_string languages)"
EOF
)"
assert_contains "$profile_catalog_zsh_output" "languages=c " "Profile catalog should load cleanly under zsh"
pass "Profile catalog zsh compatibility"

profile_candidate_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
printf '#!/usr/bin/env zsh\n' >"$tmpdir/tool.sh"

evop_prepare_profile_detection_candidates "languages" "$tmpdir" ""

printf 'mode=%s\n' "$EVOP_PROFILE_CANDIDATE_MODE"
printf 'candidates=%s\n' "$EVOP_PROFILE_CANDIDATE_LIST"
EOF
)"
assert_contains "$profile_candidate_output" "mode=filtered" "Profile candidate planning should narrow obvious repositories"
assert_contains "$profile_candidate_output" "candidates=shell" "Profile candidate planning should keep the matching shell profile"
pass "Profile candidate planning"

profile_detect_zsh_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
printf '#!/usr/bin/env zsh\n' >"$tmpdir/tool.sh"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'detected=%s\n' "$EVOP_DETECTED_PROFILE"
else
    printf 'detected=none\n'
fi
EOF
)"
assert_contains "$profile_detect_zsh_output" "detected=shell" "Profile detection should honor filename patterns under zsh"
pass "Profile detect zsh patterns"

shell_cli_candidate_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/bin" "$tmpdir/lib" "$tmpdir/tests"
printf '#!/usr/bin/env zsh\n' >"$tmpdir/bin/tool"
printf '#!/usr/bin/env zsh\n' >"$tmpdir/MAIN.sh"

for category in languages frameworks project-types; do
    evop_prepare_profile_detection_candidates "$category" "$tmpdir" ""
    printf '%s_mode=%s\n' "$category" "$EVOP_PROFILE_CANDIDATE_MODE"
    printf '%s_candidates=%s\n' "$category" "$EVOP_PROFILE_CANDIDATE_LIST"
done

if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
else
    printf 'project_type=none\n'
fi
EOF
)"
assert_contains "$shell_cli_candidate_output" "languages_mode=filtered" "Shell CLI repos should narrow language candidates"
assert_contains "$shell_cli_candidate_output" "languages_candidates=shell" "Shell CLI repos should keep the shell language candidate"
assert_contains "$shell_cli_candidate_output" "frameworks_mode=none" "Shell CLI repos should skip irrelevant framework detection"
assert_contains "$shell_cli_candidate_output" "project-types_mode=filtered" "Shell CLI repos should narrow project-type candidates"
assert_contains "$shell_cli_candidate_output" "project-types_candidates=cli-tool" "Shell CLI repos should keep the cli-tool project type candidate"
assert_contains "$shell_cli_candidate_output" "project_type=cli-tool" "Shell CLI repos should auto-detect the cli-tool project type"
pass "Shell CLI project detection"

shell_cli_candidate_zsh_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/bin" "$tmpdir/lib" "$tmpdir/tests"
printf '#!/usr/bin/env zsh\n' >"$tmpdir/bin/tool"
printf '#!/usr/bin/env zsh\n' >"$tmpdir/MAIN.sh"

evop_prepare_profile_detection_candidates "frameworks" "$tmpdir" ""
printf 'frameworks_mode=%s\n' "$EVOP_PROFILE_CANDIDATE_MODE"
evop_prepare_profile_detection_candidates "project-types" "$tmpdir" ""
printf 'project-types_candidates=%s\n' "$EVOP_PROFILE_CANDIDATE_LIST"

if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
else
    printf 'project_type=none\n'
fi
EOF
)"
assert_contains "$shell_cli_candidate_zsh_output" "frameworks_mode=none" "Shell CLI repos should skip framework detection under zsh"
assert_contains "$shell_cli_candidate_zsh_output" "project-types_candidates=cli-tool" "Shell CLI repos should keep cli-tool candidates under zsh"
assert_contains "$shell_cli_candidate_zsh_output" "project_type=cli-tool" "Shell CLI repos should auto-detect cli-tool under zsh"
pass "Shell CLI project detection zsh"

flutter_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/lib" "$tmpdir/test" "$tmpdir/android" "$tmpdir/ios"
cat >"$tmpdir/pubspec.yaml" <<'PUBSPEC'
name: flutter_app
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
PUBSPEC
printf 'void main() {}\n' >"$tmpdir/lib/main.dart"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_framework_profile "$tmpdir" ""; then
    printf 'framework=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$flutter_profile_output" "language=dart" "Flutter repos should detect the Dart language profile"
assert_contains "$flutter_profile_output" "framework=flutter" "Flutter repos should detect the Flutter framework profile"
assert_contains "$flutter_profile_output" "project_type=mobile-app" "Flutter repos should detect the mobile-app project type"
pass "Flutter profile detection"

node_cli_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/src"
cat >"$tmpdir/package.json" <<'JSON'
{
  "name": "node-cli",
  "bin": {
    "node-cli": "dist/index.js"
  },
  "dependencies": {
    "commander": "12.0.0"
  }
}
JSON
printf 'export {};\n' >"$tmpdir/src/index.ts"

if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$node_cli_profile_output" "project_type=cli-tool" "Non-shell CLI repos should detect the cli-tool project type"
pass "Node CLI project detection"

node_package_lookup_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cat >"$tmpdir/package.json" <<'JSON'
{
  "name": "lookup-demo",
  "scripts": {
    "dev": "react-native start"
  },
  "dependencies": {
    "@expo/vector-icons": "^14.0.0"
  }
}
JSON

printf 'react_native=%s\n' "$(
    if evop_repo_has_node_package "$tmpdir" "react-native"; then
        printf true
    else
        printf false
    fi
)"
printf 'expo_icons=%s\n' "$(
    if evop_repo_has_node_package "$tmpdir" "@expo/vector-icons"; then
        printf true
    else
        printf false
    fi
)"
EOF
)"
assert_contains "$node_package_lookup_output" "react_native=false" "Node package indexing should avoid matching package names that only appear inside scripts"
assert_contains "$node_package_lookup_output" "expo_icons=true" "Node package indexing should preserve exact scoped package matches"
pass "Node package indexing"

expo_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/app"
cat >"$tmpdir/package.json" <<'JSON'
{
  "name": "expo-demo",
  "dependencies": {
    "expo": "~52.0.0",
    "expo-router": "~4.0.0",
    "react": "18.3.0",
    "react-native": "0.76.0"
  }
}
JSON
cat >"$tmpdir/app.json" <<'APPJSON'
{
  "expo": {
    "name": "Expo Demo"
  }
}
APPJSON
printf '{ "compilerOptions": { "strict": true } }\n' >"$tmpdir/tsconfig.json"
printf 'export default function Screen() { return null; }\n' >"$tmpdir/app/index.tsx"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_framework_profile "$tmpdir" ""; then
    printf 'framework=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$expo_profile_output" "language=typescript" "Expo repos should detect the TypeScript language profile when tsconfig is present"
assert_contains "$expo_profile_output" "framework=expo" "Expo repos should detect the Expo framework profile"
assert_contains "$expo_profile_output" "project_type=mobile-app" "Expo repos should detect the mobile-app project type"
pass "Expo profile detection"

react_native_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cat >"$tmpdir/package.json" <<'JSON'
{
  "name": "react-native-demo",
  "dependencies": {
    "react": "18.3.0",
    "react-native": "0.76.0"
  }
}
JSON
printf 'module.exports = {};\n' >"$tmpdir/metro.config.js"
printf '{ "compilerOptions": { "strict": true } }\n' >"$tmpdir/tsconfig.json"
printf 'export default function App() { return null; }\n' >"$tmpdir/App.tsx"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_framework_profile "$tmpdir" ""; then
    printf 'framework=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$react_native_profile_output" "language=typescript" "React Native repos should detect the TypeScript language profile when tsconfig is present"
assert_contains "$react_native_profile_output" "framework=react-native" "React Native repos should detect the React Native framework profile"
assert_contains "$react_native_profile_output" "project_type=mobile-app" "React Native repos should detect the mobile-app project type"
pass "React Native profile detection"

aspnet_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/Controllers"
cat >"$tmpdir/DemoService.csproj" <<'CSPROJ'
<Project Sdk="Microsoft.NET.Sdk.Web">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
  </PropertyGroup>
</Project>
CSPROJ
printf 'var builder = WebApplication.CreateBuilder(args);\n' >"$tmpdir/Program.cs"
printf '{}\n' >"$tmpdir/appsettings.json"
printf 'namespace Demo.Controllers;\n' >"$tmpdir/Controllers/HealthController.cs"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_framework_profile "$tmpdir" ""; then
    printf 'framework=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$aspnet_profile_output" "language=csharp" "ASP.NET Core repos should detect the C# language profile"
assert_contains "$aspnet_profile_output" "framework=aspnet-core" "ASP.NET Core repos should detect the ASP.NET Core framework profile"
assert_contains "$aspnet_profile_output" "project_type=backend-service" "ASP.NET Core repos should detect the backend-service project type"
pass "ASP.NET Core profile detection"

maui_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/Platforms/Android" "$tmpdir/Platforms/iOS"
cat >"$tmpdir/DemoMaui.csproj" <<'CSPROJ'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFrameworks>net8.0-android;net8.0-ios</TargetFrameworks>
    <UseMaui>true</UseMaui>
  </PropertyGroup>
  <ItemGroup>
    <PackageReference Include="Microsoft.Maui.Controls" Version="8.0.0" />
  </ItemGroup>
</Project>
CSPROJ
printf 'namespace DemoMaui;\n' >"$tmpdir/MauiProgram.cs"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_framework_profile "$tmpdir" ""; then
    printf 'framework=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$maui_profile_output" "language=csharp" ".NET MAUI repos should detect the C# language profile"
assert_contains "$maui_profile_output" "framework=maui" ".NET MAUI repos should detect the MAUI framework profile"
assert_contains "$maui_profile_output" "project_type=mobile-app" ".NET MAUI repos should detect the mobile-app project type"
pass ".NET MAUI profile detection"

r_shiny_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/R" "$tmpdir/tests/testthat"
cat >"$tmpdir/DESCRIPTION" <<'DESC'
Package: shinydemo
Imports:
    shiny,
    testthat,
    lintr
DESC
cat >"$tmpdir/app.R" <<'APP'
library(shiny)
shinyApp(fluidPage("demo"), function(input, output, session) {})
APP
printf 'testthat::test_local()\n' >"$tmpdir/tests/testthat/test-app.R"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_framework_profile "$tmpdir" ""; then
    printf 'framework=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$r_shiny_profile_output" "language=r" "R repositories should detect the R language profile"
assert_contains "$r_shiny_profile_output" "framework=shiny" "Shiny repositories should detect the Shiny framework profile"
assert_contains "$r_shiny_profile_output" "project_type=web-app" "Shiny repositories should detect the web-app project type"
pass "R Shiny profile detection"

terraform_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/tests"
cat >"$tmpdir/main.tf" <<'TF'
terraform {
  required_version = ">= 1.6.0"
}
TF
cat >"$tmpdir/tests/basic.tftest.hcl" <<'TEST'
run "plan" {
  command = plan
}
TEST

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$terraform_profile_output" "language=terraform" "Terraform repositories should detect the Terraform language profile"
assert_contains "$terraform_profile_output" "project_type=infrastructure" "Terraform repositories should detect the infrastructure project type"
pass "Terraform profile detection"

godot_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/scenes"
printf '[application]\nconfig/name=\"TestGame\"\n' >"$tmpdir/project.godot"
printf 'extends Node\n' >"$tmpdir/scenes/main.gd"

if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$godot_profile_output" "project_type=single-player-game" "Game-engine repos should default to single-player-game without mobile markers"
pass "Game project detection"

elixir_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
printf 'defmodule Demo.MixProject do\nend\n' >"$tmpdir/mix.exs"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$elixir_profile_output" "language=elixir" "Elixir repos should detect the Elixir language profile"
pass "Elixir profile detection"

phoenix_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/lib/demo_web"
cat >"$tmpdir/mix.exs" <<'MIX'
defmodule Demo.MixProject do
  def project do
    [
      app: :demo,
      deps: deps()
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.7"}
    ]
  end
end
MIX
printf 'defmodule DemoWeb.Router do\nend\n' >"$tmpdir/lib/demo_web/router.ex"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_framework_profile "$tmpdir" ""; then
    printf 'framework=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$phoenix_profile_output" "language=elixir" "Phoenix repos should keep the Elixir language profile"
assert_contains "$phoenix_profile_output" "framework=phoenix" "Phoenix repos should detect the Phoenix framework profile"
assert_contains "$phoenix_profile_output" "project_type=backend-service" "Phoenix repos should detect the backend-service project type"
pass "Phoenix profile detection"

c_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
printf 'cmake_minimum_required(VERSION 3.20)\nproject(demo C)\n' >"$tmpdir/CMakeLists.txt"
printf 'int main(void) { return 0; }\n' >"$tmpdir/main.c"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$c_profile_output" "language=c" "Pure C repos should detect the C language profile"
pass "C profile detection"

scala_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
printf 'scalaVersion := "3.3.1"\n' >"$tmpdir/build.sbt"
mkdir -p "$tmpdir/src/main/scala"
printf 'object Main extends App { println("hello") }\n' >"$tmpdir/src/main/scala/Main.scala"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$scala_profile_output" "language=scala" "Scala repos should detect the Scala language profile"
pass "Scala profile detection"

lua_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
printf 'function love.load() end\n' >"$tmpdir/main.lua"

if evop_detect_language_profile "$tmpdir" ""; then
    printf 'language=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$lua_profile_output" "language=lua" "Lua repos should detect the Lua language profile"
pass "Lua profile detection"

nuxt_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
cat >"$tmpdir/package.json" <<'JSON'
{
  "name": "nuxt-app",
  "dependencies": {
    "nuxt": "3.15.0"
  }
}
JSON
printf 'export default defineNuxtConfig({})\n' >"$tmpdir/nuxt.config.ts"

if evop_detect_framework_profile "$tmpdir" ""; then
    printf 'framework=%s\n' "$EVOP_DETECTED_PROFILE"
fi
if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$nuxt_profile_output" "framework=nuxt" "Nuxt repos should detect the Nuxt framework profile"
assert_contains "$nuxt_profile_output" "project_type=web-app" "Nuxt repos should detect the web-app project type"
pass "Nuxt profile detection"

infrastructure_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/terraform"
printf 'terraform {\n  required_version = ">= 1.6.0"\n}\n' >"$tmpdir/main.tf"
printf 'resource "aws_s3_bucket" "assets" {}\n' >"$tmpdir/terraform/storage.tf"

if evop_detect_project_type "$tmpdir" ""; then
    printf 'project_type=%s\n' "$EVOP_DETECTED_PROFILE"
fi
EOF
)"
assert_contains "$infrastructure_profile_output" "project_type=infrastructure" "Terraform repos should detect the infrastructure project type"
pass "Infrastructure profile detection"

expanded_language_profile_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/clojure" "$tmpdir/haskell" "$tmpdir/julia" "$tmpdir/zig"

printf '{:paths ["src"]}\n' >"$tmpdir/clojure/deps.edn"
printf '(ns demo.core)\n' >"$tmpdir/clojure/core.clj"

printf 'resolver: lts-22.0\npackages:\n  - .\n' >"$tmpdir/haskell/stack.yaml"
printf 'cabal-version: 2.4\nname: demo\nversion: 0.1.0.0\n' >"$tmpdir/haskell/demo.cabal"
printf 'module Demo where\n' >"$tmpdir/haskell/Demo.hs"

printf 'name = "Demo"\n' >"$tmpdir/julia/Project.toml"
printf 'module Demo\nend\n' >"$tmpdir/julia/Demo.jl"

printf 'const std = @import("std");\n\npub fn build(_: *std.Build) void {}\n' >"$tmpdir/zig/build.zig"
printf 'pub fn main() void {}\n' >"$tmpdir/zig/main.zig"

for language_dir in clojure haskell julia zig; do
    if evop_detect_language_profile "$tmpdir/$language_dir" ""; then
        printf '%s=%s\n' "$language_dir" "$EVOP_DETECTED_PROFILE"
    fi
done
EOF
)"
assert_contains "$expanded_language_profile_output" "clojure=clojure" "Clojure repos should detect the Clojure language profile"
assert_contains "$expanded_language_profile_output" "haskell=haskell" "Haskell repos should detect the Haskell language profile"
assert_contains "$expanded_language_profile_output" "julia=julia" "Julia repos should detect the Julia language profile"
assert_contains "$expanded_language_profile_output" "zig=zig" "Zig repos should detect the Zig language profile"
pass "Expanded language profile detection"

expanded_project_type_output="$(
    ROOT_DIR="$ROOT_DIR" zsh <<'EOF'
set -euo pipefail
source "$ROOT_DIR/lib/common.sh"
source "$ROOT_DIR/lib/profile.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
mkdir -p "$tmpdir/library/src" "$tmpdir/plugin/src" "$tmpdir/pipeline/dags" "$tmpdir/embedded/firmware"

printf '[package]\nname = "demo-lib"\nversion = "0.1.0"\n' >"$tmpdir/library/Cargo.toml"
printf 'pub fn demo() {}\n' >"$tmpdir/library/src/lib.rs"

cat >"$tmpdir/plugin/package.json" <<'JSON'
{
  "name": "vite-plugin-demo",
  "exports": "./src/index.js"
}
JSON
printf 'export default function demoPlugin() {}\n' >"$tmpdir/plugin/src/index.js"

printf '[project]\nname = "demo-pipeline"\ndependencies = ["prefect"]\n' >"$tmpdir/pipeline/pyproject.toml"
printf 'def run_flow():\n    return None\n' >"$tmpdir/pipeline/dags/flow.py"

printf '[env:test]\nplatform = espressif32\nboard = esp32dev\nframework = arduino\n' >"$tmpdir/embedded/platformio.ini"
printf 'int main() { return 0; }\n' >"$tmpdir/embedded/firmware/main.cpp"

for project_dir in library plugin pipeline embedded; do
    if evop_detect_project_type "$tmpdir/$project_dir" ""; then
        printf '%s=%s\n' "$project_dir" "$EVOP_DETECTED_PROFILE"
    fi
done
EOF
)"
assert_contains "$expanded_project_type_output" "library=library" "Library repos should detect the library project type"
assert_contains "$expanded_project_type_output" "plugin=plugin" "Plugin repos should detect the plugin project type"
assert_contains "$expanded_project_type_output" "pipeline=data-pipeline" "Pipeline repos should detect the data-pipeline project type"
assert_contains "$expanded_project_type_output" "embedded=embedded-system" "Embedded repos should detect the embedded-system project type"
pass "Expanded project-type detection"

profiles_summary_output="$(run_expect_success "PROFILES should summarize supported profiles" "$PROFILES_SCRIPT" --category languages)"
assert_contains "$profiles_summary_output" "Supported profiles (Languages):" "PROFILES summary should print the selected category"
assert_contains "$profiles_summary_output" "shell:" "PROFILES summary should include language entries"
assert_contains "$profiles_summary_output" "lib/profiles/definitions/languages/shell/profile.sh" "PROFILES summary should include definition paths"
pass "PROFILES summary"

profiles_json_output="$(run_expect_success "PROFILES should render json output" "$PROFILES_SCRIPT" --category project-types --format json)"
profiles_json_summary="$(PROFILES_JSON="$profiles_json_output" python3 - <<'PY'
import json
import os

data = json.loads(os.environ["PROFILES_JSON"])
print(data["category"])
print(f"cli_tool_ok={any(item['name'] == 'cli-tool' for item in data['categories']['project-types'])}")
print(f"summary_ok={all(item['summary'] for item in data['categories']['project-types'])}")
PY
)"
assert_contains "$profiles_json_summary" "project-types" "PROFILES json should report the selected category"
assert_contains "$profiles_json_summary" "cli_tool_ok=True" "PROFILES json should include project type entries"
assert_contains "$profiles_json_summary" "summary_ok=True" "PROFILES json should include summaries"
pass "PROFILES json"

profiles_report_env="$TEST_TMPDIR/profiles-report.env"
run_expect_success "PROFILES should write an env report file" "$PROFILES_SCRIPT" --category frameworks --report-file "$profiles_report_env" --report-format env >/dev/null
profiles_report_env_summary="$(
    PROFILES_REPORT_ENV="$profiles_report_env" zsh <<'EOF'
set -euo pipefail
source "$PROFILES_REPORT_ENV"
printf '%s\n' "$EVOP_PROFILES_CATEGORY"
printf 'count_ok=%s\n' "$([[ "$EVOP_PROFILES_FRAMEWORK_COUNT" =~ ^[1-9][0-9]*$ ]] && printf true || printf false)"
printf 'name_ok=%s\n' "$([[ -n "${EVOP_PROFILES_FRAMEWORK_1_NAME:-}" ]] && printf true || printf false)"
printf 'summary_ok=%s\n' "$([[ -n "${EVOP_PROFILES_FRAMEWORK_1_SUMMARY:-}" ]] && printf true || printf false)"
EOF
)"
assert_contains "$profiles_report_env_summary" "frameworks" "PROFILES env should export the selected category"
assert_contains "$profiles_report_env_summary" "count_ok=true" "PROFILES env should export category counts"
assert_contains "$profiles_report_env_summary" "name_ok=true" "PROFILES env should export entry names"
assert_contains "$profiles_report_env_summary" "summary_ok=true" "PROFILES env should export entry summaries"
pass "PROFILES env report"
