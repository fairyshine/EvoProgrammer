#!/usr/bin/env zsh

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

    if evop_repo_looks_like_shell_cli "$target_dir"; then
        evop_profile_candidate_append_unique candidates "cli-tool"
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
