#!/usr/bin/env bash

evop_file_contains_regex() {
    local path="$1"
    local regex="$2"

    [[ -f "$path" ]] || return 1
    grep -Eq "$regex" "$path"
}

evop_file_contains_literal() {
    local path="$1"
    local text="$2"

    [[ -f "$path" ]] || return 1
    grep -Fq -- "$text" "$path"
}

evop_package_json_has_script() {
    local package_json="$1"
    local script_name="$2"

    evop_file_contains_regex "$package_json" "\"$script_name\"[[:space:]]*:"
}

evop_package_json_mentions() {
    local package_json="$1"
    local needle="$2"

    evop_file_contains_literal "$package_json" "\"$needle\""
}

evop_makefile_has_target() {
    local makefile="$1"
    local target="$2"

    evop_file_contains_regex "$makefile" "^$target:"
}

evop_existing_relative_path() {
    local target_dir="$1"
    shift
    local rel_path

    for rel_path in "$@"; do
        if [[ -e "$target_dir/$rel_path" ]]; then
            printf '%s' "$rel_path"
            return 0
        fi
    done

    return 1
}

evop_package_manager_script_command() {
    local package_manager="$1"
    local script_name="$2"

    case "$package_manager" in
        pnpm)
            printf 'pnpm %s' "$script_name"
            ;;
        yarn)
            printf 'yarn %s' "$script_name"
            ;;
        bun)
            printf 'bun run %s' "$script_name"
            ;;
        npm|*)
            printf 'npm run %s' "$script_name"
            ;;
    esac
}

evop_choose_package_manager() {
    local target_dir="$1"
    local language_profile="${2:-}"

    case "$language_profile" in
        python)
            if [[ -f "$target_dir/poetry.lock" ]]; then
                printf 'poetry'
                return 0
            fi
            if [[ -f "$target_dir/uv.lock" ]]; then
                printf 'uv'
                return 0
            fi
            if [[ -f "$target_dir/pyproject.toml" ]]; then
                printf 'python'
                return 0
            fi
            ;;
        rust)
            if [[ -f "$target_dir/Cargo.toml" ]]; then
                printf 'cargo'
                return 0
            fi
            ;;
        go)
            if [[ -f "$target_dir/go.mod" ]]; then
                printf 'go'
                return 0
            fi
            ;;
        ruby)
            if [[ -f "$target_dir/Gemfile" ]]; then
                printf 'bundler'
                return 0
            fi
            ;;
        php)
            if [[ -f "$target_dir/composer.json" ]]; then
                printf 'composer'
                return 0
            fi
            ;;
    esac

    if [[ -f "$target_dir/pnpm-lock.yaml" || -f "$target_dir/pnpm-workspace.yaml" ]]; then
        printf 'pnpm'
        return 0
    fi

    if [[ -f "$target_dir/yarn.lock" ]]; then
        printf 'yarn'
        return 0
    fi

    if [[ -f "$target_dir/bun.lock" || -f "$target_dir/bun.lockb" ]]; then
        printf 'bun'
        return 0
    fi

    if [[ -f "$target_dir/package-lock.json" || -f "$target_dir/package.json" ]]; then
        printf 'npm'
        return 0
    fi

    if [[ -f "$target_dir/poetry.lock" ]]; then
        printf 'poetry'
        return 0
    fi

    if [[ -f "$target_dir/uv.lock" ]]; then
        printf 'uv'
        return 0
    fi

    if [[ -f "$target_dir/pyproject.toml" ]]; then
        printf 'python'
        return 0
    fi

    if [[ -f "$target_dir/Cargo.toml" ]]; then
        printf 'cargo'
        return 0
    fi

    if [[ -f "$target_dir/go.mod" ]]; then
        printf 'go'
        return 0
    fi

    if [[ -f "$target_dir/Gemfile" ]]; then
        printf 'bundler'
        return 0
    fi

    if [[ -f "$target_dir/composer.json" ]]; then
        printf 'composer'
        return 0
    fi

    return 1
}

evop_detect_workspace_mode() {
    local target_dir="$1"
    local package_json="$target_dir/package.json"

    if [[ -f "$target_dir/pnpm-workspace.yaml" || -f "$target_dir/go.work" ]]; then
        printf 'monorepo'
        return 0
    fi

    if evop_file_contains_regex "$target_dir/Cargo.toml" "^\[workspace\]"; then
        printf 'monorepo'
        return 0
    fi

    if evop_file_contains_regex "$package_json" "\"workspaces\"[[:space:]]*:"; then
        printf 'monorepo'
        return 0
    fi

    if [[ -d "$target_dir/apps" || -d "$target_dir/packages" ]]; then
        printf 'monorepo'
        return 0
    fi

    if [[ -f "$package_json" || -f "$target_dir/pyproject.toml" || -f "$target_dir/Cargo.toml" || -f "$target_dir/go.mod" ]]; then
        printf 'single-package'
        return 0
    fi

    printf 'single-repo'
}

evop_detect_command_hints() {
    local target_dir="$1"
    local package_manager="$2"
    local language_profile="$3"
    local package_json="$target_dir/package.json"
    local pyproject="$target_dir/pyproject.toml"
    local makefile=""
    local script_name=""

    if [[ -f "$target_dir/Makefile" ]]; then
        makefile="$target_dir/Makefile"
    elif [[ -f "$target_dir/makefile" ]]; then
        makefile="$target_dir/makefile"
    fi

    if [[ -f "$package_json" ]]; then
        for script_name in dev start; do
            if evop_package_json_has_script "$package_json" "$script_name"; then
                evop_set_command_if_empty EVOP_PROJECT_CONTEXT_DEV_COMMAND "$(evop_package_manager_script_command "$package_manager" "$script_name")"
                break
            fi
        done

        if evop_package_json_has_script "$package_json" "build"; then
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_BUILD_COMMAND "$(evop_package_manager_script_command "$package_manager" build)"
        fi

        if evop_package_json_has_script "$package_json" "test"; then
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_TEST_COMMAND "$(evop_package_manager_script_command "$package_manager" test)"
        fi

        if evop_package_json_has_script "$package_json" "lint"; then
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_LINT_COMMAND "$(evop_package_manager_script_command "$package_manager" lint)"
        fi

        for script_name in typecheck check-types types:check; do
            if evop_package_json_has_script "$package_json" "$script_name"; then
                evop_set_command_if_empty EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND "$(evop_package_manager_script_command "$package_manager" "$script_name")"
                break
            fi
        done
    fi

    if [[ -n "$makefile" ]]; then
        if evop_makefile_has_target "$makefile" "dev"; then
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_DEV_COMMAND "make dev"
        fi
        if evop_makefile_has_target "$makefile" "build"; then
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_BUILD_COMMAND "make build"
        fi
        if evop_makefile_has_target "$makefile" "test"; then
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_TEST_COMMAND "make test"
        fi
        if evop_makefile_has_target "$makefile" "lint"; then
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_LINT_COMMAND "make lint"
        fi
        if evop_makefile_has_target "$makefile" "typecheck"; then
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND "make typecheck"
        fi
    fi

    case "$language_profile" in
        rust)
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_DEV_COMMAND "cargo run"
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_BUILD_COMMAND "cargo build"
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_TEST_COMMAND "cargo test"
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_LINT_COMMAND "cargo clippy --all-targets --all-features"
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND "cargo check"
            ;;
        go)
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_BUILD_COMMAND "go build ./..."
            evop_set_command_if_empty EVOP_PROJECT_CONTEXT_TEST_COMMAND "go test ./..."
            ;;
        python)
            if [[ -d "$target_dir/tests" || -d "$target_dir/test" || -f "$target_dir/pytest.ini" ]] \
                || evop_file_contains_literal "$pyproject" "pytest"; then
                evop_set_command_if_empty EVOP_PROJECT_CONTEXT_TEST_COMMAND "pytest"
            fi
            if [[ -f "$target_dir/.ruff.toml" || -f "$target_dir/ruff.toml" ]] \
                || evop_file_contains_literal "$pyproject" "ruff"; then
                evop_set_command_if_empty EVOP_PROJECT_CONTEXT_LINT_COMMAND "ruff check ."
            fi
            if [[ -f "$target_dir/mypy.ini" || -f "$target_dir/.mypy.ini" ]] \
                || evop_file_contains_literal "$pyproject" "mypy"; then
                evop_set_command_if_empty EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND "mypy ."
            fi
            ;;
        typescript|javascript)
            if [[ -f "$target_dir/tsconfig.json" ]]; then
                evop_set_command_if_empty EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND "tsc --noEmit"
            fi
            ;;
    esac
}

evop_add_structure_hint() {
    local target_dir="$1"
    local rel_path="$2"
    local description="$3"

    [[ -e "$target_dir/$rel_path" ]] || return 0
    evop_append_multiline EVOP_PROJECT_CONTEXT_STRUCTURE "$rel_path: $description"
    evop_append_csv_unique EVOP_PROJECT_CONTEXT_SEARCH_ROOTS "$rel_path"
}

evop_detect_structure_hints() {
    local target_dir="$1"

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
    evop_add_structure_hint "$target_dir" "tests" "automated tests"
    evop_add_structure_hint "$target_dir" "test" "automated tests"
    evop_add_structure_hint "$target_dir" "__tests__" "automated tests"
    evop_add_structure_hint "$target_dir" "prisma" "database schema and generated client configuration"
    evop_add_structure_hint "$target_dir" "db" "database access or persistence logic"
    evop_add_structure_hint "$target_dir" "migrations" "schema migrations"
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
}

evop_detect_validation_hints() {
    if [[ -n "$EVOP_PROJECT_CONTEXT_LINT_COMMAND" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_VALIDATION "Run lint first: $EVOP_PROJECT_CONTEXT_LINT_COMMAND"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_VALIDATION "Run type or compile checks next: $EVOP_PROJECT_CONTEXT_TYPECHECK_COMMAND"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_TEST_COMMAND" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_VALIDATION "Run focused automated tests: $EVOP_PROJECT_CONTEXT_TEST_COMMAND"
    fi

    if [[ -n "$EVOP_PROJECT_CONTEXT_BUILD_COMMAND" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_VALIDATION "Confirm the production build still passes: $EVOP_PROJECT_CONTEXT_BUILD_COMMAND"
    fi
}
