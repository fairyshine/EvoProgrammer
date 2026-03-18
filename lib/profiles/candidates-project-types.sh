#!/usr/bin/env zsh

evop_prepare_project_type_candidates() {
    local target_dir="$1"
    local prompt="${2:-}"
    local candidates=""

    if evop_directory_has_file_named "$target_dir" "AndroidManifest.xml" "Info.plist" \
        || { evop_directory_has_path_named "$target_dir" "android" && evop_directory_has_path_named "$target_dir" "ios"; }; then
        evop_profile_candidate_append_unique candidates "mobile-app"
    fi

    if evop_repo_looks_like_mobile_game "$target_dir"; then
        evop_profile_candidate_append_unique candidates "mobile-game"
    fi

    if evop_repo_looks_like_game_project "$target_dir" && ! evop_repo_looks_like_mobile_game "$target_dir"; then
        evop_profile_candidate_append_unique candidates "single-player-game"
    fi

    if evop_directory_has_file_extension "$target_dir" "docx" "xlsx" "doc" "xls"; then
        evop_profile_candidate_append_unique candidates "office"
    fi

    if evop_directory_has_file_extension "$target_dir" "tex" "bib"; then
        evop_profile_candidate_append_unique candidates "paper"
    fi

    if evop_directory_has_file_extension "$target_dir" "pptx" "key" \
        || evop_directory_has_path_named "$target_dir" "slides"; then
        evop_profile_candidate_append_unique candidates "ppt"
    fi

    if evop_directory_has_file_extension "$target_dir" "ipynb" \
        || evop_directory_has_file_pattern "$target_dir" "*.Rmd" \
        || evop_directory_has_path_named "$target_dir" "notebooks" \
        || evop_directory_has_path_named "$target_dir" "datasets"; then
        evop_profile_candidate_append_unique candidates "scientific-experiment"
    fi

    if evop_repo_looks_like_data_pipeline "$target_dir"; then
        evop_profile_candidate_append_unique candidates "data-pipeline"
    fi

    if evop_repo_looks_like_embedded_system "$target_dir"; then
        evop_profile_candidate_append_unique candidates "embedded-system"
    fi

    if evop_repo_looks_like_plugin "$target_dir"; then
        evop_profile_candidate_append_unique candidates "plugin"
    fi

    if evop_repo_looks_like_library "$target_dir"; then
        evop_profile_candidate_append_unique candidates "library"
    fi

    if evop_repo_looks_like_web_app "$target_dir"; then
        evop_profile_candidate_append_unique candidates "web-app"
    fi

    if evop_repo_looks_like_cli_tool "$target_dir"; then
        evop_profile_candidate_append_unique candidates "cli-tool"
    fi

    if evop_repo_looks_like_backend_service "$target_dir"; then
        evop_profile_candidate_append_unique candidates "backend-service"
    fi

    if evop_repo_looks_like_desktop_app "$target_dir"; then
        evop_profile_candidate_append_unique candidates "desktop-app"
    fi

    if evop_repo_looks_like_infrastructure "$target_dir"; then
        evop_profile_candidate_append_unique candidates "infrastructure"
    fi

    evop_profile_candidate_add_if_prompt_matches candidates "ai-agent" "$prompt" "ai agent" "assistant" "tool-using agent" "workflow agent"
    evop_profile_candidate_add_if_prompt_matches candidates "backend-service" "$prompt" "backend service" "api service" "microservice" "rest api" "backend"
    evop_profile_candidate_add_if_prompt_matches candidates "browser-game" "$prompt" "browser game" "html5 game" "web game"
    evop_profile_candidate_add_if_prompt_matches candidates "cli-tool" "$prompt" "cli tool" "command line" "terminal tool" "命令行"
    evop_profile_candidate_add_if_prompt_matches candidates "data-pipeline" "$prompt" "data pipeline" "etl" "ingestion pipeline" "batch job"
    evop_profile_candidate_add_if_prompt_matches candidates "desktop-app" "$prompt" "desktop app" "desktop application" "桌面应用"
    evop_profile_candidate_add_if_prompt_matches candidates "embedded-system" "$prompt" "embedded" "firmware" "mcu" "microcontroller"
    evop_profile_candidate_add_if_prompt_matches candidates "infrastructure" "$prompt" "terraform" "infra" "infrastructure" "helm" "kubernetes" "k8s" "ansible" "iac"
    evop_profile_candidate_add_if_prompt_matches candidates "library" "$prompt" "sdk" "library" "package" "crate" "module"
    evop_profile_candidate_add_if_prompt_matches candidates "mobile-app" "$prompt" "mobile app" "ios app" "android app" "flutter app" "手机应用" "移动应用"
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
