#!/usr/bin/env zsh

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

    if evop_directory_has_file_named "$target_dir" "pubspec.yaml"; then
        if evop_directory_contains_text "$target_dir" "flutter:" "pubspec.yaml" \
            || evop_directory_contains_text "$target_dir" "sdk: flutter" "pubspec.yaml" \
            || { evop_directory_has_path_named "$target_dir" "android" && evop_directory_has_path_named "$target_dir" "ios"; }; then
            evop_profile_candidate_append_unique candidates "flutter"
        fi
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

    if evop_directory_contains_text "$target_dir" "spring-boot" "pom.xml" "build.gradle" "build.gradle.kts" \
        || evop_directory_contains_text "$target_dir" "org.springframework.boot" "build.gradle" "build.gradle.kts"; then
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
    evop_profile_candidate_add_if_prompt_matches candidates "flutter" "$prompt" "flutter"
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

    if [[ -z "$candidates" && -f "$target_dir/pubspec.yaml" ]]; then
        candidates="flutter"
    fi

    if [[ -n "$candidates" ]]; then
        EVOP_PROFILE_CANDIDATE_MODE="filtered"
        EVOP_PROFILE_CANDIDATE_LIST="$candidates"
    elif evop_repo_looks_like_shell_cli "$target_dir"; then
        EVOP_PROFILE_CANDIDATE_MODE="none"
    elif [[ -n "$prompt" ]]; then
        EVOP_PROFILE_CANDIDATE_MODE="all"
    else
        EVOP_PROFILE_CANDIDATE_MODE="none"
    fi
}
