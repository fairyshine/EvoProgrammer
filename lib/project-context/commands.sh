#!/usr/bin/env zsh

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

evop_python_tool_command() {
    local package_manager="$1"
    shift

    case "$package_manager" in
        poetry)
            printf 'poetry run'
            ;;
        uv)
            printf 'uv run'
            ;;
        *)
            printf '%s' "$1"
            shift
            if (($# == 0)); then
                return 0
            fi
            printf ' %s' "$@"
            return 0
            ;;
    esac

    while (($# > 0)); do
        printf ' %s' "$1"
        shift
    done
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

evop_detect_package_json_commands() {
    local package_json="$1"
    local package_manager="$2"
    local script_name=""

    [[ -f "$package_json" ]] || return 0

    for script_name in dev start; do
        if evop_package_json_has_script "$package_json" "$script_name"; then
            evop_set_project_command_if_empty dev "$(evop_package_manager_script_command "$package_manager" "$script_name")" "package.json script"
            break
        fi
    done

    if evop_package_json_has_script "$package_json" build; then
        evop_set_project_command_if_empty build "$(evop_package_manager_script_command "$package_manager" build)" "package.json script"
    fi

    if evop_package_json_has_script "$package_json" test; then
        evop_set_project_command_if_empty test "$(evop_package_manager_script_command "$package_manager" test)" "package.json script"
    fi

    if evop_package_json_has_script "$package_json" lint; then
        evop_set_project_command_if_empty lint "$(evop_package_manager_script_command "$package_manager" lint)" "package.json script"
    fi

    for script_name in typecheck check-types types:check; do
        if evop_package_json_has_script "$package_json" "$script_name"; then
            evop_set_project_command_if_empty typecheck "$(evop_package_manager_script_command "$package_manager" "$script_name")" "package.json script"
            break
        fi
    done
}

evop_detect_makefile_commands() {
    local makefile="$1"

    [[ -n "$makefile" ]] || return 0

    if evop_makefile_has_target "$makefile" dev; then
        evop_set_project_command_if_empty dev "make dev" "make target"
    fi
    if evop_makefile_has_target "$makefile" build; then
        evop_set_project_command_if_empty build "make build" "make target"
    fi
    if evop_makefile_has_target "$makefile" test; then
        evop_set_project_command_if_empty test "make test" "make target"
    fi
    if evop_makefile_has_target "$makefile" lint; then
        evop_set_project_command_if_empty lint "make lint" "make target"
    fi
    if evop_makefile_has_target "$makefile" typecheck; then
        evop_set_project_command_if_empty typecheck "make typecheck" "make target"
    fi
}

evop_detect_language_default_commands() {
    local target_dir="$1"
    local package_manager="$2"
    local language_profile="$3"
    local pyproject="$target_dir/pyproject.toml"

    case "$language_profile" in
        rust)
            evop_set_project_command_if_empty dev "cargo run" "Rust defaults"
            evop_set_project_command_if_empty build "cargo build" "Rust defaults"
            evop_set_project_command_if_empty test "cargo test" "Rust defaults"
            evop_set_project_command_if_empty lint "cargo clippy --all-targets --all-features" "Rust defaults"
            evop_set_project_command_if_empty typecheck "cargo check" "Rust defaults"
            ;;
        go)
            evop_set_project_command_if_empty build "go build ./..." "Go defaults"
            evop_set_project_command_if_empty test "go test ./..." "Go defaults"
            ;;
        python)
            if [[ -d "$target_dir/tests" || -d "$target_dir/test" || -f "$target_dir/pytest.ini" ]] \
                || evop_file_contains_literal "$pyproject" "pytest"; then
                evop_set_project_command_if_empty test "$(evop_python_tool_command "$package_manager" pytest)" "Python conventions"
            fi
            if [[ -f "$target_dir/.ruff.toml" || -f "$target_dir/ruff.toml" ]] \
                || evop_file_contains_literal "$pyproject" "ruff"; then
                evop_set_project_command_if_empty lint "$(evop_python_tool_command "$package_manager" ruff check .)" "Python conventions"
            fi
            if [[ -f "$target_dir/mypy.ini" || -f "$target_dir/.mypy.ini" ]] \
                || evop_file_contains_literal "$pyproject" "mypy"; then
                evop_set_project_command_if_empty typecheck "$(evop_python_tool_command "$package_manager" mypy .)" "Python conventions"
            fi
            ;;
        typescript|javascript)
            if [[ -f "$target_dir/tsconfig.json" ]]; then
                evop_set_project_command_if_empty typecheck "tsc --noEmit" "TypeScript defaults"
            fi
            ;;
    esac
}

evop_detect_shell_project_commands() {
    local target_dir="$1"
    local language_profile="$2"
    local project_type="${3:-}"

    if [[ "$language_profile" != "shell" && "$project_type" != "cli-tool" ]]; then
        return 0
    fi

    if [[ -f "$target_dir/tests/run_tests.sh" ]]; then
        evop_set_project_command_if_empty test "zsh tests/run_tests.sh" "shell project conventions"
    fi

    if [[ -f "$target_dir/tests/run_lint.sh" ]]; then
        evop_set_project_command_if_empty lint "zsh tests/run_lint.sh" "shell project conventions"
    elif [[ -f "$target_dir/tests/run_extended_tests.sh" ]]; then
        evop_set_project_command_if_empty lint "zsh tests/run_extended_tests.sh" "shell project conventions"
    fi
}

evop_detect_command_hints() {
    local target_dir="$1"
    local package_manager="$2"
    local language_profile="$3"
    local project_type="${4:-}"
    local package_json="$target_dir/package.json"
    local makefile=""

    if [[ -f "$target_dir/Makefile" ]]; then
        makefile="$target_dir/Makefile"
    elif [[ -f "$target_dir/makefile" ]]; then
        makefile="$target_dir/makefile"
    fi

    evop_detect_package_json_commands "$package_json" "$package_manager"
    evop_detect_makefile_commands "$makefile"
    evop_detect_language_default_commands "$target_dir" "$package_manager" "$language_profile"
    evop_detect_shell_project_commands "$target_dir" "$language_profile" "$project_type"
}
