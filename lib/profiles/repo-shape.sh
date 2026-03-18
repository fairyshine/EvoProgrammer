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
EVOP_REPO_LOOKS_LIKE_LIBRARY_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_LIBRARY_CACHE_VALUE=""
EVOP_REPO_LOOKS_LIKE_MOBILE_GAME_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_MOBILE_GAME_CACHE_VALUE=""
EVOP_REPO_LOOKS_LIKE_PLUGIN_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_PLUGIN_CACHE_VALUE=""
EVOP_REPO_LOOKS_LIKE_DATA_PIPELINE_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_DATA_PIPELINE_CACHE_VALUE=""
EVOP_REPO_LOOKS_LIKE_EMBEDDED_SYSTEM_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_EMBEDDED_SYSTEM_CACHE_VALUE=""
EVOP_REPO_LOOKS_LIKE_WEB_APP_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_WEB_APP_CACHE_VALUE=""
EVOP_REPO_LOOKS_LIKE_INFRASTRUCTURE_CACHE_DIR=""
EVOP_REPO_LOOKS_LIKE_INFRASTRUCTURE_CACHE_VALUE=""

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

evop_repo_looks_like_library() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_LOOKS_LIKE_LIBRARY_CACHE_DIR" == "$target_dir" ]]; then
        evop_repo_shape_cache_value_matches "$EVOP_REPO_LOOKS_LIKE_LIBRARY_CACHE_VALUE"
        return $?
    fi

    if evop_project_relative_exists "$target_dir" "src/lib.rs"; then
        EVOP_REPO_LOOKS_LIKE_LIBRARY_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_LIBRARY_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "package.json" \
        && ! evop_directory_contains_text "$target_dir" "\"bin\"" "package.json" \
        && ! evop_repo_looks_like_web_app "$target_dir" \
        && ! evop_repo_looks_like_backend_service "$target_dir" \
        && ! evop_repo_looks_like_cli_tool "$target_dir" \
        && {
            evop_directory_contains_text "$target_dir" "\"exports\"" "package.json" \
                || evop_directory_contains_text "$target_dir" "\"types\"" "package.json";
        }; then
        EVOP_REPO_LOOKS_LIKE_LIBRARY_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_LIBRARY_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.cabal" \
        && evop_directory_contains_text "$target_dir" "library" "*.cabal"; then
        EVOP_REPO_LOOKS_LIKE_LIBRARY_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_LIBRARY_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_LIBRARY_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_LIBRARY_CACHE_VALUE="0"
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
            evop_repo_has_node_package "$target_dir" "commander" "yargs" "cac" "oclif" "clipanion" \
                || evop_directory_contains_text "$target_dir" "\"bin\"" "package.json";
        }; then
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "pyproject.toml" "requirements.txt" "setup.py" \
        && {
            evop_repo_has_python_package "$target_dir" "click" "typer" "console_scripts";
        }; then
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_CLI_TOOL_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "Cargo.toml" \
        && {
            evop_repo_has_cargo_crate "$target_dir" "clap" "[[bin]]" \
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
                || evop_repo_has_go_module "$target_dir" "spf13/cobra" "urfave/cli";
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
            evop_repo_has_node_package "$target_dir" "@nestjs/core" "express" "fastify" "koa";
        }; then
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "pyproject.toml" "requirements.txt" "requirements-dev.txt" "manage.py" \
        && {
            evop_repo_has_python_package "$target_dir" "django" "fastapi" "flask";
        }; then
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "Cargo.toml" \
        && {
            evop_repo_has_cargo_crate "$target_dir" "actix-web" "axum";
        }; then
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "go.mod" \
        && evop_repo_has_go_module "$target_dir" "gin-gonic/gin"; then
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE="1"
        return 0
    fi

    if evop_repo_has_java_dependency "$target_dir" "spring-boot" "org.springframework.boot"; then
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_BACKEND_SERVICE_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "mix.exs" \
        && evop_repo_has_mix_package "$target_dir" "phoenix"; then
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
        && evop_repo_has_node_package "$target_dir" "electron"; then
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
        || evop_repo_has_cargo_crate "$target_dir" "bevy" \
        || evop_repo_has_python_package "$target_dir" "pygame"; then
        EVOP_REPO_LOOKS_LIKE_GAME_PROJECT_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_GAME_PROJECT_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_GAME_PROJECT_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_GAME_PROJECT_CACHE_VALUE="0"
    return 1
}

evop_repo_looks_like_plugin() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_LOOKS_LIKE_PLUGIN_CACHE_DIR" == "$target_dir" ]]; then
        evop_repo_shape_cache_value_matches "$EVOP_REPO_LOOKS_LIKE_PLUGIN_CACHE_VALUE"
        return $?
    fi

    if evop_directory_has_file_named "$target_dir" "plugin.xml" \
        || evop_directory_has_file_pattern "$target_dir" "*.uplugin"; then
        EVOP_REPO_LOOKS_LIKE_PLUGIN_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_PLUGIN_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "package.json" \
        && evop_directory_contains_text "$target_dir" "-plugin" "package.json" "package.json"; then
        EVOP_REPO_LOOKS_LIKE_PLUGIN_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_PLUGIN_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_PLUGIN_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_PLUGIN_CACHE_VALUE="0"
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

evop_repo_looks_like_data_pipeline() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_LOOKS_LIKE_DATA_PIPELINE_CACHE_DIR" == "$target_dir" ]]; then
        evop_repo_shape_cache_value_matches "$EVOP_REPO_LOOKS_LIKE_DATA_PIPELINE_CACHE_VALUE"
        return $?
    fi

    if evop_directory_has_file_named "$target_dir" "dbt_project.yml" "airflow.cfg" \
        || evop_directory_has_path_named "$target_dir" "dags" "pipelines" "jobs" \
        || {
            evop_directory_has_file_named "$target_dir" "pyproject.toml" "requirements.txt" "requirements-dev.txt" \
                && evop_repo_has_python_package "$target_dir" "airflow" "dagster" "prefect" "pyspark";
        }; then
        EVOP_REPO_LOOKS_LIKE_DATA_PIPELINE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_DATA_PIPELINE_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_DATA_PIPELINE_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_DATA_PIPELINE_CACHE_VALUE="0"
    return 1
}

evop_repo_looks_like_embedded_system() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_LOOKS_LIKE_EMBEDDED_SYSTEM_CACHE_DIR" == "$target_dir" ]]; then
        evop_repo_shape_cache_value_matches "$EVOP_REPO_LOOKS_LIKE_EMBEDDED_SYSTEM_CACHE_VALUE"
        return $?
    fi

    if evop_directory_has_file_named "$target_dir" "platformio.ini" "sdkconfig" "idf_component.yml" \
        || evop_directory_has_file_pattern "$target_dir" "*.ino" \
        || evop_directory_has_path_named "$target_dir" "firmware" "boards"; then
        EVOP_REPO_LOOKS_LIKE_EMBEDDED_SYSTEM_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_EMBEDDED_SYSTEM_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_EMBEDDED_SYSTEM_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_EMBEDDED_SYSTEM_CACHE_VALUE="0"
    return 1
}

evop_repo_looks_like_web_app() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_LOOKS_LIKE_WEB_APP_CACHE_DIR" == "$target_dir" ]]; then
        evop_repo_shape_cache_value_matches "$EVOP_REPO_LOOKS_LIKE_WEB_APP_CACHE_VALUE"
        return $?
    fi

    if evop_directory_has_path_named "$target_dir" "public" "src" "app" "pages" "components"; then
        EVOP_REPO_LOOKS_LIKE_WEB_APP_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_WEB_APP_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "app.R" "ui.R" "server.R" \
        && evop_directory_contains_text "$target_dir" "shiny" "DESCRIPTION" "app.R" "ui.R" "server.R"; then
        EVOP_REPO_LOOKS_LIKE_WEB_APP_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_WEB_APP_CACHE_VALUE="1"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "package.json" \
        && evop_repo_has_node_package "$target_dir" "next" "react" "vue" "svelte" "nuxt" "astro"; then
        EVOP_REPO_LOOKS_LIKE_WEB_APP_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_WEB_APP_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_WEB_APP_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_WEB_APP_CACHE_VALUE="0"
    return 1
}

evop_repo_looks_like_infrastructure() {
    local target_dir="$1"

    if [[ "$EVOP_REPO_LOOKS_LIKE_INFRASTRUCTURE_CACHE_DIR" == "$target_dir" ]]; then
        evop_repo_shape_cache_value_matches "$EVOP_REPO_LOOKS_LIKE_INFRASTRUCTURE_CACHE_VALUE"
        return $?
    fi

    if evop_directory_has_file_named "$target_dir" "main.tf" "terraform.tfvars" "terragrunt.hcl" "Pulumi.yaml" "Chart.yaml" "helmfile.yaml" "kustomization.yaml" "playbook.yml" "playbook.yaml" \
        || evop_directory_has_file_pattern "$target_dir" "*.tf" "*.tfvars" \
        || evop_directory_has_path_named "$target_dir" "terraform" "ansible" "charts" "helm" "k8s" "kubernetes"; then
        EVOP_REPO_LOOKS_LIKE_INFRASTRUCTURE_CACHE_DIR="$target_dir"
        EVOP_REPO_LOOKS_LIKE_INFRASTRUCTURE_CACHE_VALUE="1"
        return 0
    fi

    EVOP_REPO_LOOKS_LIKE_INFRASTRUCTURE_CACHE_DIR="$target_dir"
    EVOP_REPO_LOOKS_LIKE_INFRASTRUCTURE_CACHE_VALUE="0"
    return 1
}
