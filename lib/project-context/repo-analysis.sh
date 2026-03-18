#!/usr/bin/env zsh

evop_file_contains_regex() {
    local file_path="$1"
    local regex="$2"

    evop_project_file_contains_regex_cached "$file_path" "$regex"
}

evop_file_contains_literal() {
    local file_path="$1"
    local text="$2"

    evop_project_file_contains_literal_cached "$file_path" "$text"
}

evop_package_json_has_script() {
    local package_json="$1"
    local script_name="$2"

    evop_project_file_text_contains_regex_cached "$package_json" "\"$script_name\"[[:space:]]*:"
}

evop_package_json_mentions() {
    local package_json="$1"
    local needle="$2"

    evop_file_contains_literal "$package_json" "\"$needle\""
}

evop_makefile_has_target() {
    local makefile="$1"
    local target="$2"

    evop_project_makefile_targets_cached "$makefile" >/dev/null
    case $'\n'"$EVOP_PROJECT_CONTEXT_MAKEFILE_TARGETS_RESULT"$'\n' in
        *$'\n'"$target"$'\n'*)
            return 0
            ;;
    esac

    return 1
}

evop_existing_relative_path() {
    local target_dir="$1"
    shift
    local rel_path

    for rel_path in "$@"; do
        if evop_project_relative_exists "$target_dir" "$rel_path"; then
            printf '%s' "$rel_path"
            return 0
        fi
    done

    return 1
}

evop_add_structure_hint() {
    local target_dir="$1"
    local rel_path="$2"
    local description="$3"

    evop_project_relative_exists "$target_dir" "$rel_path" || return 0
    evop_append_multiline EVOP_PROJECT_CONTEXT_STRUCTURE "$rel_path: $description"
    evop_append_csv_unique EVOP_PROJECT_CONTEXT_SEARCH_ROOTS "$rel_path"
}

evop_detect_structure_hints() {
    local target_dir="$1"

    evop_add_structure_hint "$target_dir" "bin" "CLI entrypoints or executable wrappers"
    evop_add_structure_hint "$target_dir" "apps" "runnable applications in the workspace"
    evop_add_structure_hint "$target_dir" "packages" "shared packages or libraries"
    evop_add_structure_hint "$target_dir" "app" "application routes or screens"
    evop_add_structure_hint "$target_dir" "src/app" "application routes or screens"
    evop_add_structure_hint "$target_dir" "pages" "page or route entrypoints"
    evop_add_structure_hint "$target_dir" "src/pages" "page or route entrypoints"
    evop_add_structure_hint "$target_dir" "components" "shared UI components"
    evop_add_structure_hint "$target_dir" "src/components" "shared UI components"
    evop_add_structure_hint "$target_dir" "features" "feature-focused modules"
    evop_add_structure_hint "$target_dir" "src/features" "feature-focused modules"
    evop_add_structure_hint "$target_dir" "services" "service or API integration layer"
    evop_add_structure_hint "$target_dir" "src/services" "service or API integration layer"
    evop_add_structure_hint "$target_dir" "scripts" "automation or release scripts"
    evop_add_structure_hint "$target_dir" "store" "state management"
    evop_add_structure_hint "$target_dir" "src/store" "state management"
    evop_add_structure_hint "$target_dir" "src/stores" "state management"
    evop_add_structure_hint "$target_dir" "hooks" "reusable hooks or shared control flow"
    evop_add_structure_hint "$target_dir" "src/hooks" "reusable hooks or shared control flow"
    evop_add_structure_hint "$target_dir" "lib" "shared utilities or infrastructure glue"
    evop_add_structure_hint "$target_dir" "src/lib" "shared utilities or infrastructure glue"
    evop_add_structure_hint "$target_dir" "api" "API handlers or request entrypoints"
    evop_add_structure_hint "$target_dir" "src/api" "API handlers or request entrypoints"
    evop_add_structure_hint "$target_dir" "server" "backend or server entrypoints"
    evop_add_structure_hint "$target_dir" "src/server" "backend or server entrypoints"
    evop_add_structure_hint "$target_dir" "backend" "backend services or adapters"
    evop_add_structure_hint "$target_dir" "android" "Android application shell, build files, and native integration"
    evop_add_structure_hint "$target_dir" "ios" "iOS application shell, Xcode project, and native integration"
    evop_add_structure_hint "$target_dir" "macos" "macOS desktop target and platform integration"
    evop_add_structure_hint "$target_dir" "linux" "Linux desktop target and packaging integration"
    evop_add_structure_hint "$target_dir" "windows" "Windows desktop target and packaging integration"
    evop_add_structure_hint "$target_dir" "integration_test" "end-to-end or device-level test coverage"
    evop_add_structure_hint "$target_dir" "docs" "project documentation and design notes"
    evop_add_structure_hint "$target_dir" "tests" "automated tests"
    evop_add_structure_hint "$target_dir" "test" "automated tests"
    evop_add_structure_hint "$target_dir" "__tests__" "automated tests"
    evop_add_structure_hint "$target_dir" "prisma" "database schema and generated client configuration"
    evop_add_structure_hint "$target_dir" "db" "database access or persistence logic"
    evop_add_structure_hint "$target_dir" "migrations" "schema migrations"

    if evop_directory_has_file_pattern "$target_dir" "*.sh"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_STRUCTURE ".: top-level automation or command entry scripts"
        evop_append_csv_unique EVOP_PROJECT_CONTEXT_SEARCH_ROOTS "."
    fi
}

evop_detect_conventions() {
    local target_dir="$1"
    local language_profile="$2"
    local package_json="$target_dir/package.json"
    local pyproject="$target_dir/pyproject.toml"

    if evop_file_contains_regex "$target_dir/tsconfig.json" "\"strict\"[[:space:]]*:[[:space:]]*true"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "TypeScript strict mode is enabled."
    fi

    if evop_package_json_mentions "$package_json" "eslint" || evop_directory_has_file_pattern "$target_dir" ".eslintrc" ".eslintrc.*" "eslint.config.*"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "Linting is configured with ESLint."
    fi

    if evop_package_json_mentions "$package_json" "prettier" || evop_directory_has_file_pattern "$target_dir" ".prettierrc" ".prettierrc.*" "prettier.config.*"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "Formatting is configured with Prettier."
    fi

    if evop_package_json_mentions "$package_json" "@biomejs/biome" || evop_directory_has_file_named "$target_dir" "biome.json"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "Linting and formatting are centered on Biome."
    fi

    if evop_package_json_mentions "$package_json" "tailwindcss" || evop_directory_has_file_pattern "$target_dir" "tailwind.config.*"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "Styling appears to rely on Tailwind conventions."
    fi

    if evop_package_json_mentions "$package_json" "zustand"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "State management uses Zustand."
    fi

    if evop_package_json_mentions "$package_json" "@reduxjs/toolkit" || evop_package_json_mentions "$package_json" "redux"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "State management uses Redux-style patterns."
    fi

    if evop_package_json_mentions "$package_json" "vitest"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "Tests are wired through Vitest."
    elif evop_package_json_mentions "$package_json" "jest"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "Tests are wired through Jest."
    fi

    if evop_file_contains_literal "$pyproject" "pytest" || [[ -f "$target_dir/pytest.ini" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "Tests are wired through pytest."
    fi

    if evop_file_contains_literal "$pyproject" "ruff" || [[ -f "$target_dir/.ruff.toml" || -f "$target_dir/ruff.toml" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "Linting is wired through Ruff."
    fi

    if [[ "$language_profile" == "rust" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "Cargo is the primary workflow for build, check, test, and lint."
    fi

    if [[ "$language_profile" == "dart" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "Dart or Flutter tooling is the primary workflow for run, analyze, and test."
    fi

    if [[ -f "$target_dir/analysis_options.yaml" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_CONVENTIONS "Analyzer rules are configured through analysis_options.yaml."
    fi
}

evop_detect_automation_hints() {
    local target_dir="$1"
    local has_container_surface=0

    if evop_project_relative_exists "$target_dir" ".github/workflows"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_AUTOMATION "GitHub Actions workflows live under .github/workflows."
    fi

    if evop_project_relative_exists "$target_dir" ".gitlab-ci.yml"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_AUTOMATION "GitLab CI is configured through .gitlab-ci.yml."
    fi

    if evop_project_relative_exists "$target_dir" ".devcontainer" \
        || evop_project_relative_exists "$target_dir" ".devcontainer/devcontainer.json"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_AUTOMATION "Dev container configuration is present."
    fi

    if evop_existing_relative_path "$target_dir" "Dockerfile" "docker/Dockerfile" "Dockerfile.dev" >/dev/null \
        || evop_existing_relative_path "$target_dir" "docker-compose.yml" "docker-compose.yaml" "compose.yml" "compose.yaml" >/dev/null; then
        has_container_surface=1
    fi

    if (( has_container_surface == 1 )); then
        evop_append_multiline EVOP_PROJECT_CONTEXT_AUTOMATION "Container build or compose definitions are present."
    fi

    if evop_project_relative_exists "$target_dir" "scripts"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_AUTOMATION "Repository automation scripts live under scripts/."
    fi

    if evop_project_relative_exists "$target_dir" "docs"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_AUTOMATION "Project documentation lives under docs/."
    fi
}

evop_detect_risk_areas() {
    local target_dir="$1"

    if evop_directory_has_path_named "$target_dir" "auth" \
        || evop_directory_has_path_named "$target_dir" "session" \
        || evop_directory_has_path_named "$target_dir" "permissions"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_AREAS "Authentication, session, or permission flows are likely high-risk."
    fi

    if evop_directory_has_path_named "$target_dir" "prisma" \
        || evop_directory_has_path_named "$target_dir" "migrations" \
        || evop_directory_has_path_named "$target_dir" "schema" \
        || evop_directory_has_path_named "$target_dir" "db" \
        || evop_directory_has_path_named "$target_dir" "database"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_AREAS "Database schema, migrations, and persistence contracts need careful coordination."
    fi

    if evop_directory_has_path_named "$target_dir" "types" \
        || evop_directory_has_path_named "$target_dir" "contracts" \
        || evop_directory_has_path_named "$target_dir" "shared" \
        || evop_directory_has_path_named "$target_dir" "packages"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_AREAS "Shared types or cross-package contracts can create wide regressions."
    fi

    if [[ -n "$(evop_existing_relative_path "$target_dir" "config" "configs" "src/config" "src/configs" || true)" ]] \
        || evop_directory_has_file_pattern "$target_dir" ".env" ".env.*" "appsettings.json"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_AREAS "Environment and build configuration changes can have repo-wide impact."
    fi

    if evop_directory_has_path_named "$target_dir" "api" \
        || evop_directory_has_path_named "$target_dir" "routes" \
        || evop_directory_has_path_named "$target_dir" "controllers" \
        || evop_directory_has_path_named "$target_dir" "openapi"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_AREAS "Public API routes or contracts should be changed conservatively."
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_AUTOMATION" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_AREAS "CI, container, or developer-environment automation may need updates when workflows or runtime contracts change."
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.sh" \
        && evop_directory_has_path_named "$target_dir" "lib" "bin"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_AREAS "Shell entrypoints often share sourced helpers, so changing common libraries can break multiple commands at once."
    fi

    if evop_directory_has_path_named "$target_dir" "android" \
        || evop_directory_has_path_named "$target_dir" "ios"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_AREAS "Mobile platform glue, permissions, and lifecycle handling can regress independently of shared app logic."
    fi

    if evop_directory_contains_text "$target_dir" "#!/usr/bin/env zsh" "*.sh" \
        && evop_directory_contains_text "$target_dir" "#!/bin/sh" "*.sh"; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_AREAS "Mixed shebangs are present; bootstrap shims and zsh-backed scripts must stay aligned on runtime expectations."
    fi
}

evop_detect_validation_hints() {
    local slot=""
    local command=""

    while IFS= read -r slot; do
        command="$(evop_get_project_command "$slot")"
        [[ -n "$command" ]] || continue

        case "$slot" in
            lint)
                evop_append_multiline EVOP_PROJECT_CONTEXT_VALIDATION "Run lint first: $command"
                ;;
            typecheck)
                evop_append_multiline EVOP_PROJECT_CONTEXT_VALIDATION "Run type or compile checks next: $command"
                ;;
            test)
                evop_append_multiline EVOP_PROJECT_CONTEXT_VALIDATION "Run focused automated tests: $command"
                ;;
            build)
                evop_append_multiline EVOP_PROJECT_CONTEXT_VALIDATION "Confirm the production build still passes: $command"
                ;;
        esac
    done < <(evop_project_verification_slots)
}
