#!/usr/bin/env zsh

# shellcheck disable=SC2034

EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_VALUE=""
EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE=""
EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_VALUE=""
EVOP_REPO_LOOKS_LIKE_GAME_PROJECT_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_GAME_PROJECT_CACHE_VALUE=""
EVOP_REPO_LOOKS_LIKE_MOBILE_GAME_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_MOBILE_GAME_CACHE_VALUE=""

evop_repo_shape_cache_value_matches() {
    local cached_value="$1"
    [[ "$cached_value" == "1" ]]
}

evop_repo_has_mobile_platform_markers() {
    local target_dir="$1"

    if evop_directory_has_file_named "$target_dir" "AndroidManifest.xml" "Info.plist"; then
        return 0
    fi

    if evop_directory_has_path_named "$target_dir" "android" \
        && evop_directory_has_path_named "$target_dir" "ios"; then
        return 0
    fi

    return 1
}

evop_repo_looks_like_cli_tool() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_DIR" == "$target_dir" ]]; then
        evop_repo_shape_cache_value_matches "$EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_VALUE"
        return $?
    fi

    if evop_repo_looks_like_shell_cli "$target_dir"; then
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "package.json" \
        && {
            evop_directory_contains_text "$target_dir" "\"bin\"" "package.json" \
                || evop_directory_contains_text "$target_dir" "\"commander\"" "package.json" \
                || evop_directory_contains_text "$target_dir" "\"yargs\"" "package.json" \
                || evop_directory_contains_text "$target_dir" "\"cac\"" "package.json" \
                || evop_directory_contains_text "$target_dir" "\"oclif\"" "package.json" \
                || evop_directory_contains_text "$target_dir" "\"clipanion\"" "package.json";
        }; then
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "pyproject.toml" "requirements.txt" "setup.py" \
        && {
            evop_directory_contains_text "$target_dir" "click" "pyproject.toml" "requirements.txt" "setup.py" \
                || evop_directory_contains_text "$target_dir" "typer" "pyproject.toml" "requirements.txt" "setup.py" \
                || evop_directory_contains_text "$target_dir" "console_scripts" "pyproject.toml" "setup.py";
        }; then
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "Cargo.toml" \
        && {
            evop_directory_contains_text "$target_dir" "[[bin]]" "Cargo.toml" \
                || evop_directory_contains_text "$target_dir" "clap" "Cargo.toml" \
                || evop_directory_has_path_named "$target_dir" "bin";
        }; then
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "go.mod" \
        && {
            evop_directory_has_path_named "$target_dir" "cmd" \
                || evop_directory_has_file_named "$target_dir" "main.go" \
                || evop_directory_contains_text "$target_dir" "spf13/cobra" "go.mod" "*.go";
        }; then
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_VALUE="0"
    return 1
}

evop_repo_looks_like_backend_service() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR" == "$target_dir" ]]; then
        evop_repo_shape_cache_value_matches "$EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE"
        return $?
    fi

    if evop_directory_has_path_named "$target_dir" "api" "server" "backend" "routes" "controllers" "openapi"; then
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "package.json" \
        && {
            evop_directory_contains_text "$target_dir" "\"@nestjs/core\"" "package.json" \
                || evop_directory_contains_text "$target_dir" "\"express\"" "package.json" \
                || evop_directory_contains_text "$target_dir" "\"fastify\"" "package.json" \
                || evop_directory_contains_text "$target_dir" "\"koa\"" "package.json";
        }; then
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "pyproject.toml" "requirements.txt" "requirements-dev.txt" "manage.py" \
        && {
            evop_directory_contains_text "$target_dir" "django" "pyproject.toml" "requirements.txt" "requirements-dev.txt" \
                || evop_directory_contains_text "$target_dir" "fastapi" "pyproject.toml" "requirements.txt" "requirements-dev.txt" \
                || evop_directory_contains_text "$target_dir" "flask" "pyproject.toml" "requirements.txt" "requirements-dev.txt";
        }; then
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "Cargo.toml" \
        && {
            evop_directory_contains_text "$target_dir" "actix-web" "Cargo.toml" \
                || evop_directory_contains_text "$target_dir" "axum" "Cargo.toml";
        }; then
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "go.mod" \
        && evop_directory_contains_text "$target_dir" "gin-gonic/gin" "go.mod" "*.go"; then
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_contains_text "$target_dir" "spring-boot" "pom.xml" "build.gradle" "build.gradle.kts" \
        || evop_directory_contains_text "$target_dir" "org.springframework.boot" "build.gradle" "build.gradle.kts"; then
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE="0"
    return 1
}

evop_repo_looks_like_desktop_app() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_DIR" == "$target_dir" ]]; then
        evop_repo_shape_cache_value_matches "$EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_VALUE"
        return $?
    fi

    if evop_directory_has_path_named "$target_dir" "src-tauri" \
        || evop_directory_has_file_named "$target_dir" "tauri.conf.json"; then
        EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "package.json" \
        && evop_directory_contains_text "$target_dir" "\"electron\"" "package.json"; then
        EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_extension "$target_dir" "ui" \
        || evop_directory_contains_text "$target_dir" "qt" "CMakeLists.txt" "*.pro" "pyproject.toml"; then
        EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_path_named "$target_dir" "macos" "linux" "windows" \
        && ! evop_repo_has_mobile_platform_markers "$target_dir"; then
        EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_DESKTOP_APP_CACHE_VALUE="0"
    return 1
}

evop_repo_looks_like_game_project() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_LOOKS_LIKE_GAME_PROJECT_CACHE_DIR" == "$target_dir" ]]; then
        evop_repo_shape_cache_value_matches "$EVOP_REPO_LOOKS_LIKE_GAME_PROJECT_CACHE_VALUE"
        return $?
    fi

    if evop_directory_has_file_named "$target_dir" "project.godot" \
        || { evop_directory_has_path_named "$target_dir" "Assets" && evop_directory_has_path_named "$target_dir" "ProjectSettings"; } \
        || evop_directory_has_file_extension "$target_dir" "uproject" \
        || evop_directory_contains_text "$target_dir" "bevy" "Cargo.toml" \
        || evop_directory_contains_text "$target_dir" "pygame" "pyproject.toml" "requirements.txt"; then
        EVOP_REPO_LOOKS_LIKE_GAME_PROJECT_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_GAME_PROJECT_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_GAME_PROJECT_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_GAME_PROJECT_CACHE_VALUE="0"
    return 1
}

evop_repo_looks_like_mobile_game() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_LOOKS_LIKE_MOBILE_GAME_CACHE_DIR" == "$target_dir" ]]; then
        evop_repo_shape_cache_value_matches "$EVOP_REPO_LOOKS_LIKE_MOBILE_GAME_CACHE_VALUE"
        return $?
    fi

    if evop_repo_looks_like_game_project "$target_dir" && evop_repo_has_mobile_platform_markers "$target_dir"; then
        EVOP_REPO_LOOKS_LIKE_MOBILE_GAME_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_MOBILE_GAME_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_MOBILE_GAME_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_MOBILE_GAME_CACHE_VALUE="0"
    return 1
}
