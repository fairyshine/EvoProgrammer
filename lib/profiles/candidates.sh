#!/usr/bin/env bash

EVOP_PROFILE_CANDIDATE_MODE="all"
EVOP_PROFILE_CANDIDATE_LIST=""

evop_reset_profile_candidates() {
    EVOP_PROFILE_CANDIDATE_MODE="all"
    EVOP_PROFILE_CANDIDATE_LIST=""
}

evop_profile_candidate_append_unique() {
    local var_name="$1"
    local value="$2"
    local current=""

    [[ -n "$value" ]] || return 0

    eval "current=\${$var_name-}"
    case $'\n'"$current"$'\n' in
        *$'\n'"$value"$'\n'*)
            return 0
            ;;
    esac

    if [[ -n "$current" ]]; then
        printf -v "$var_name" '%s\n%s' "$current" "$value"
    else
        printf -v "$var_name" '%s' "$value"
    fi
}

evop_profile_candidate_add_if_prompt_matches() {
    local var_name="$1"
    local candidate="$2"
    local prompt="${3:-}"
    shift 3

    [[ -n "$prompt" ]] || return 0
    if evop_text_contains_any "$prompt" "$@"; then
        evop_profile_candidate_append_unique "$var_name" "$candidate"
    fi
}

evop_prepare_language_profile_candidates() {
    local target_dir="$1"
    local prompt="${2:-}"
    local candidates=""

    if evop_directory_has_file_named "$target_dir" "tsconfig.json" \
        || evop_directory_has_file_pattern "$target_dir" "*.ts" "*.tsx"; then
        evop_profile_candidate_append_unique candidates "typescript"
    fi

    if evop_directory_has_file_named "$target_dir" "package.json" \
        || evop_directory_has_file_pattern "$target_dir" "*.js" "*.jsx" "*.mjs" "*.cjs"; then
        evop_profile_candidate_append_unique candidates "javascript"
    fi

    if evop_directory_has_file_named "$target_dir" "pyproject.toml" "requirements.txt" "setup.py" \
        || evop_directory_has_file_pattern "$target_dir" "*.py"; then
        evop_profile_candidate_append_unique candidates "python"
    fi

    if evop_directory_has_file_named "$target_dir" "Cargo.toml" \
        || evop_directory_has_file_pattern "$target_dir" "*.rs"; then
        evop_profile_candidate_append_unique candidates "rust"
    fi

    if evop_directory_has_file_named "$target_dir" "go.mod" \
        || evop_directory_has_file_pattern "$target_dir" "*.go"; then
        evop_profile_candidate_append_unique candidates "go"
    fi

    if evop_directory_has_file_named "$target_dir" "Gemfile" \
        || evop_directory_has_file_pattern "$target_dir" "*.rb"; then
        evop_profile_candidate_append_unique candidates "ruby"
    fi

    if evop_directory_has_file_named "$target_dir" "composer.json" \
        || evop_directory_has_file_pattern "$target_dir" "*.php"; then
        evop_profile_candidate_append_unique candidates "php"
    fi

    if evop_directory_has_file_named "$target_dir" "pom.xml" "build.gradle" "build.gradle.kts" \
        || evop_directory_has_file_pattern "$target_dir" "*.java"; then
        evop_profile_candidate_append_unique candidates "java"
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.kt" "*.kts"; then
        evop_profile_candidate_append_unique candidates "kotlin"
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.sln" "*.csproj" "*.cs"; then
        evop_profile_candidate_append_unique candidates "csharp"
    fi

    if evop_directory_has_file_named "$target_dir" "CMakeLists.txt" \
        || evop_directory_has_file_pattern "$target_dir" "*.cpp" "*.cc" "*.cxx" "*.hpp" "*.hh" "*.hxx"; then
        evop_profile_candidate_append_unique candidates "cpp"
    fi

    if evop_directory_has_file_named "$target_dir" "Package.swift" \
        || evop_directory_has_file_pattern "$target_dir" "*.swift"; then
        evop_profile_candidate_append_unique candidates "swift"
    fi

    if evop_directory_has_file_named "$target_dir" "project.godot" \
        || evop_directory_has_file_pattern "$target_dir" "*.gd"; then
        evop_profile_candidate_append_unique candidates "gdscript"
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.sh" \
        || evop_directory_has_file_named "$target_dir" ".zshrc" ".zprofile" ".bashrc" ".bash_profile"; then
        evop_profile_candidate_append_unique candidates "shell"
    fi

    evop_profile_candidate_add_if_prompt_matches candidates "typescript" "$prompt" "typescript"
    evop_profile_candidate_add_if_prompt_matches candidates "javascript" "$prompt" "javascript" "node.js" "nodejs"
    evop_profile_candidate_add_if_prompt_matches candidates "python" "$prompt" "python"
    evop_profile_candidate_add_if_prompt_matches candidates "rust" "$prompt" "rust"
    evop_profile_candidate_add_if_prompt_matches candidates "go" "$prompt" "golang" " go "
    evop_profile_candidate_add_if_prompt_matches candidates "ruby" "$prompt" "ruby"
    evop_profile_candidate_add_if_prompt_matches candidates "php" "$prompt" "php"
    evop_profile_candidate_add_if_prompt_matches candidates "java" "$prompt" "java"
    evop_profile_candidate_add_if_prompt_matches candidates "kotlin" "$prompt" "kotlin"
    evop_profile_candidate_add_if_prompt_matches candidates "csharp" "$prompt" "c#" "dotnet"
    evop_profile_candidate_add_if_prompt_matches candidates "cpp" "$prompt" "c++" "cpp"
    evop_profile_candidate_add_if_prompt_matches candidates "swift" "$prompt" "swift"
    evop_profile_candidate_add_if_prompt_matches candidates "gdscript" "$prompt" "gdscript"
    evop_profile_candidate_add_if_prompt_matches candidates "shell" "$prompt" "bash" "shell" "shell script" "脚本"

    if [[ -n "$candidates" ]]; then
        EVOP_PROFILE_CANDIDATE_MODE="filtered"
        EVOP_PROFILE_CANDIDATE_LIST="$candidates"
    elif [[ -n "$prompt" ]]; then
        EVOP_PROFILE_CANDIDATE_MODE="all"
    else
        EVOP_PROFILE_CANDIDATE_MODE="none"
    fi
}

evop_prepare_framework_profile_candidates() {
    local target_dir="$1"
    local prompt="${2:-}"
    local candidates=""
    local has_package_json=0
    local has_python_project=0
    local has_cargo=0

    if evop_directory_has_file_named "$target_dir" "package.json"; then
        has_package_json=1

        if evop_directory_has_file_named "$target_dir" "next.config.js" "next.config.mjs" "next.config.ts" \
            || evop_directory_contains_text "$target_dir" "\"next\"" "package.json"; then
            evop_profile_candidate_append_unique candidates "nextjs"
        fi

        if evop_directory_contains_text "$target_dir" "\"react\"" "package.json"; then
            evop_profile_candidate_append_unique candidates "react"
        fi

        if evop_directory_contains_text "$target_dir" "\"vue\"" "package.json"; then
            evop_profile_candidate_append_unique candidates "vue"
        fi

        if evop_directory_has_file_named "$target_dir" "svelte.config.js" "svelte.config.cjs" "svelte.config.ts" \
            || evop_directory_contains_text "$target_dir" "\"svelte\"" "package.json"; then
            evop_profile_candidate_append_unique candidates "svelte"
        fi

        if evop_directory_contains_text "$target_dir" "\"@nestjs/core\"" "package.json"; then
            evop_profile_candidate_append_unique candidates "nestjs"
        fi

        if evop_directory_contains_text "$target_dir" "\"express\"" "package.json"; then
            evop_profile_candidate_append_unique candidates "express"
        fi

        if evop_directory_contains_text "$target_dir" "\"electron\"" "package.json"; then
            evop_profile_candidate_append_unique candidates "electron"
        fi
    fi

    if evop_directory_has_file_named "$target_dir" "manage.py" "pyproject.toml" "requirements.txt" "requirements-dev.txt"; then
        has_python_project=1

        if evop_directory_has_file_named "$target_dir" "manage.py" \
            || evop_directory_contains_text "$target_dir" "django" "pyproject.toml" "requirements.txt" "requirements-dev.txt"; then
            evop_profile_candidate_append_unique candidates "django"
        fi

        if evop_directory_contains_text "$target_dir" "fastapi" "pyproject.toml" "requirements.txt" "requirements-dev.txt"; then
            evop_profile_candidate_append_unique candidates "fastapi"
        fi

        if evop_directory_contains_text "$target_dir" "flask" "pyproject.toml" "requirements.txt" "requirements-dev.txt"; then
            evop_profile_candidate_append_unique candidates "flask"
        fi

        if evop_directory_contains_text "$target_dir" "streamlit" "pyproject.toml" "requirements.txt"; then
            evop_profile_candidate_append_unique candidates "streamlit"
        fi

        if evop_directory_contains_text "$target_dir" "pygame" "pyproject.toml" "requirements.txt"; then
            evop_profile_candidate_append_unique candidates "pygame"
        fi
    fi

    if evop_directory_has_file_named "$target_dir" "Cargo.toml"; then
        has_cargo=1

        if evop_directory_contains_text "$target_dir" "actix-web" "Cargo.toml"; then
            evop_profile_candidate_append_unique candidates "actix-web"
        fi

        if evop_directory_contains_text "$target_dir" "axum" "Cargo.toml"; then
            evop_profile_candidate_append_unique candidates "axum"
        fi

        if evop_directory_contains_text "$target_dir" "bevy" "Cargo.toml"; then
            evop_profile_candidate_append_unique candidates "bevy"
        fi
    fi

    if evop_directory_has_file_named "$target_dir" "go.mod" \
        && evop_directory_contains_text "$target_dir" "gin-gonic/gin" "go.mod" "*.go"; then
        evop_profile_candidate_append_unique candidates "gin"
    fi

    if evop_directory_has_file_named "$target_dir" "project.godot" \
        || evop_directory_has_file_pattern "$target_dir" "*.gd"; then
        evop_profile_candidate_append_unique candidates "godot"
    fi

    if evop_directory_has_file_named "$target_dir" "artisan" \
        || evop_directory_contains_text "$target_dir" "laravel/framework" "composer.json"; then
        evop_profile_candidate_append_unique candidates "laravel"
    fi

    if evop_directory_has_file_named "$target_dir" "Gemfile" \
        && evop_directory_contains_text "$target_dir" "rails" "Gemfile"; then
        evop_profile_candidate_append_unique candidates "rails"
    fi

    if evop_directory_has_path_named "$target_dir" "src-tauri" \
        || evop_directory_has_file_named "$target_dir" "tauri.conf.json"; then
        evop_profile_candidate_append_unique candidates "tauri"
    fi

    if evop_directory_has_path_named "$target_dir" "Assets" \
        && evop_directory_has_path_named "$target_dir" "ProjectSettings"; then
        evop_profile_candidate_append_unique candidates "unity"
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.uproject"; then
        evop_profile_candidate_append_unique candidates "unreal"
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.ui" \
        || evop_directory_contains_text "$target_dir" "qt" "CMakeLists.txt" "*.pro" "pyproject.toml"; then
        evop_profile_candidate_append_unique candidates "qt"
    fi

    if evop_directory_contains_text "$target_dir" "spring-boot" "pom.xml" "build.gradle" "build.gradle.kts"; then
        evop_profile_candidate_append_unique candidates "spring"
    fi

    evop_profile_candidate_add_if_prompt_matches candidates "actix-web" "$prompt" "actix"
    evop_profile_candidate_add_if_prompt_matches candidates "axum" "$prompt" "axum"
    evop_profile_candidate_add_if_prompt_matches candidates "bevy" "$prompt" "bevy"
    evop_profile_candidate_add_if_prompt_matches candidates "django" "$prompt" "django"
    evop_profile_candidate_add_if_prompt_matches candidates "electron" "$prompt" "electron"
    evop_profile_candidate_add_if_prompt_matches candidates "express" "$prompt" "express"
    evop_profile_candidate_add_if_prompt_matches candidates "fastapi" "$prompt" "fastapi"
    evop_profile_candidate_add_if_prompt_matches candidates "flask" "$prompt" "flask"
    evop_profile_candidate_add_if_prompt_matches candidates "gin" "$prompt" "gin"
    evop_profile_candidate_add_if_prompt_matches candidates "godot" "$prompt" "godot"
    evop_profile_candidate_add_if_prompt_matches candidates "laravel" "$prompt" "laravel"
    evop_profile_candidate_add_if_prompt_matches candidates "nestjs" "$prompt" "nestjs" "nest.js"
    evop_profile_candidate_add_if_prompt_matches candidates "nextjs" "$prompt" "next.js" "nextjs"
    evop_profile_candidate_add_if_prompt_matches candidates "pygame" "$prompt" "pygame"
    evop_profile_candidate_add_if_prompt_matches candidates "qt" "$prompt" "qt"
    evop_profile_candidate_add_if_prompt_matches candidates "rails" "$prompt" "rails"
    evop_profile_candidate_add_if_prompt_matches candidates "react" "$prompt" "react"
    evop_profile_candidate_add_if_prompt_matches candidates "spring" "$prompt" "spring"
    evop_profile_candidate_add_if_prompt_matches candidates "streamlit" "$prompt" "streamlit"
    evop_profile_candidate_add_if_prompt_matches candidates "svelte" "$prompt" "svelte"
    evop_profile_candidate_add_if_prompt_matches candidates "tauri" "$prompt" "tauri"
    evop_profile_candidate_add_if_prompt_matches candidates "unity" "$prompt" "unity"
    evop_profile_candidate_add_if_prompt_matches candidates "unreal" "$prompt" "unreal"
    evop_profile_candidate_add_if_prompt_matches candidates "vue" "$prompt" "vue"

    if [[ -z "$candidates" && "$has_package_json" == "1" ]]; then
        candidates=$'electron\nexpress\nnestjs\nnextjs\nreact\nsvelte\nvue'
    fi

    if [[ -z "$candidates" && "$has_python_project" == "1" ]]; then
        candidates=$'django\nfastapi\nflask\npygame\nstreamlit'
    fi

    if [[ -z "$candidates" && "$has_cargo" == "1" ]]; then
        candidates=$'actix-web\naxum\nbevy'
    fi

    if [[ -n "$candidates" ]]; then
        EVOP_PROFILE_CANDIDATE_MODE="filtered"
        EVOP_PROFILE_CANDIDATE_LIST="$candidates"
    elif [[ -n "$prompt" ]]; then
        EVOP_PROFILE_CANDIDATE_MODE="all"
    else
        EVOP_PROFILE_CANDIDATE_MODE="none"
    fi
}

evop_prepare_project_type_candidates() {
    local target_dir="$1"
    local prompt="${2:-}"
    local candidates=""

    if evop_directory_has_file_named "$target_dir" "AndroidManifest.xml" "Info.plist"; then
        evop_profile_candidate_append_unique candidates "mobile-game"
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.docx" "*.xlsx" "*.doc" "*.xls"; then
        evop_profile_candidate_append_unique candidates "office"
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.tex" "*.bib"; then
        evop_profile_candidate_append_unique candidates "paper"
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.pptx" "*.key" \
        || evop_directory_has_path_named "$target_dir" "slides"; then
        evop_profile_candidate_append_unique candidates "ppt"
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.ipynb" \
        || evop_directory_has_path_named "$target_dir" "notebooks" \
        || evop_directory_has_path_named "$target_dir" "datasets"; then
        evop_profile_candidate_append_unique candidates "scientific-experiment"
    fi

    if evop_directory_has_path_named "$target_dir" "public" \
        || evop_directory_has_path_named "$target_dir" "src"; then
        evop_profile_candidate_append_unique candidates "web-app"
    fi

    evop_profile_candidate_add_if_prompt_matches candidates "ai-agent" "$prompt" "ai agent" "assistant" "tool-using agent" "workflow agent"
    evop_profile_candidate_add_if_prompt_matches candidates "backend-service" "$prompt" "backend service" "api service" "microservice" "rest api" "backend"
    evop_profile_candidate_add_if_prompt_matches candidates "browser-game" "$prompt" "browser game" "html5 game" "web game"
    evop_profile_candidate_add_if_prompt_matches candidates "cli-tool" "$prompt" "cli tool" "command line" "terminal tool" "命令行"
    evop_profile_candidate_add_if_prompt_matches candidates "data-pipeline" "$prompt" "data pipeline" "etl" "ingestion pipeline" "batch job"
    evop_profile_candidate_add_if_prompt_matches candidates "desktop-app" "$prompt" "desktop app" "desktop application" "桌面应用"
    evop_profile_candidate_add_if_prompt_matches candidates "embedded-system" "$prompt" "embedded" "firmware" "mcu" "microcontroller"
    evop_profile_candidate_add_if_prompt_matches candidates "library" "$prompt" "sdk" "library" "package" "crate" "module"
    evop_profile_candidate_add_if_prompt_matches candidates "mobile-game" "$prompt" "mobile game" "ios game" "android game" "手机游戏"
    evop_profile_candidate_add_if_prompt_matches candidates "office" "$prompt" "office" "spreadsheet" "report" "word document" "excel" "办公"
    evop_profile_candidate_add_if_prompt_matches candidates "online-game" "$prompt" "online game" "multiplayer" "networked game" "dedicated server" "client sync" "server authoritative" "联网游戏"
    evop_profile_candidate_add_if_prompt_matches candidates "paper" "$prompt" "paper" "manuscript" "latex" "论文"
    evop_profile_candidate_add_if_prompt_matches candidates "plugin" "$prompt" "plugin" "extension" "addon" "add-on"
    evop_profile_candidate_add_if_prompt_matches candidates "ppt" "$prompt" "ppt" "slides" "slide deck" "presentation" "deck" "幻灯片" "演示文稿"
    evop_profile_candidate_add_if_prompt_matches candidates "scientific-experiment" "$prompt" "experiment" "scientific experiment" "benchmark" "dataset" "analysis pipeline" "实验"
    evop_profile_candidate_add_if_prompt_matches candidates "single-player-game" "$prompt" "single-player game" "offline game" "solo game" "单机游戏" "game" "玩法" "关卡" "combat loop" "boss fight"
    evop_profile_candidate_add_if_prompt_matches candidates "web-app" "$prompt" "web app" "website" "landing page" "dashboard" "frontend"

    if [[ -n "$candidates" ]]; then
        EVOP_PROFILE_CANDIDATE_MODE="filtered"
        EVOP_PROFILE_CANDIDATE_LIST="$candidates"
    elif [[ -n "$prompt" ]]; then
        EVOP_PROFILE_CANDIDATE_MODE="all"
    else
        EVOP_PROFILE_CANDIDATE_MODE="none"
    fi
}

evop_prepare_profile_detection_candidates() {
    local category_dir="$1"
    local target_dir="$2"
    local prompt="${3:-}"

    evop_reset_profile_candidates

    case "$category_dir" in
        languages)
            evop_prepare_language_profile_candidates "$target_dir" "$prompt"
            ;;
        frameworks)
            evop_prepare_framework_profile_candidates "$target_dir" "$prompt"
            ;;
        project-types)
            evop_prepare_project_type_candidates "$target_dir" "$prompt"
            ;;
        *)
            EVOP_PROFILE_CANDIDATE_MODE="all"
            ;;
    esac
}
