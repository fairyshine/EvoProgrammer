#!/usr/bin/env bash

EVOPROGRAMMER_SUPPORTED_LANGUAGES="python cpp go rust typescript"
EVOPROGRAMMER_SUPPORTED_PROJECT_TYPES="single-player-game paper scientific-experiment mobile-game online-game ppt office"
EVOP_RESOLVED_LANGUAGE_PROFILE=""
EVOP_RESOLVED_LANGUAGE_SOURCE="none"
EVOP_RESOLVED_PROJECT_TYPE=""
EVOP_RESOLVED_PROJECT_SOURCE="none"

evop_validate_language_profile() {
    local language_profile="${1:-}"

    if [[ -z "$language_profile" ]]; then
        return 0
    fi

    case "$language_profile" in
        python|cpp|go|rust|typescript)
            ;;
        *)
            evop_fail "Unsupported language profile: $language_profile. Supported values: $EVOPROGRAMMER_SUPPORTED_LANGUAGES"
            ;;
    esac
}

evop_validate_project_type() {
    local project_type="${1:-}"

    if [[ -z "$project_type" ]]; then
        return 0
    fi

    case "$project_type" in
        single-player-game|paper|scientific-experiment|mobile-game|online-game|ppt|office)
            ;;
        *)
            evop_fail "Unsupported project type: $project_type. Supported values: $EVOPROGRAMMER_SUPPORTED_PROJECT_TYPES"
            ;;
    esac
}

evop_directory_has_file_named() {
    local directory="$1"
    local filename="$2"
    local match

    match="$(find "$directory" -type f -name "$filename" -print -quit 2>/dev/null)"
    [[ -n "$match" ]]
}

evop_directory_has_file_pattern() {
    local directory="$1"
    shift
    local pattern
    local match=""

    for pattern in "$@"; do
        match="$(find "$directory" -type f -name "$pattern" -print -quit 2>/dev/null)"
        if [[ -n "$match" ]]; then
            return 0
        fi
    done

    return 1
}

evop_directory_has_path_named() {
    local directory="$1"
    local name="$2"
    local match

    match="$(find "$directory" \( -type f -o -type d \) -name "$name" -print -quit 2>/dev/null)"
    [[ -n "$match" ]]
}

evop_lowercase() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

evop_text_contains_any() {
    local text
    text="$(evop_lowercase "$1")"
    shift
    local needle

    for needle in "$@"; do
        if [[ "$text" == *"$(evop_lowercase "$needle")"* ]]; then
            return 0
        fi
    done

    return 1
}

evop_detect_language_profile() {
    local target_dir="$1"

    if evop_directory_has_file_named "$target_dir" "Cargo.toml"; then
        printf 'rust'
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "go.mod"; then
        printf 'go'
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "pyproject.toml" \
        || evop_directory_has_file_named "$target_dir" "requirements.txt" \
        || evop_directory_has_file_named "$target_dir" "setup.py"; then
        printf 'python'
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "tsconfig.json"; then
        printf 'typescript'
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "CMakeLists.txt"; then
        printf 'cpp'
        return 0
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.rs"; then
        printf 'rust'
        return 0
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.go"; then
        printf 'go'
        return 0
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.py"; then
        printf 'python'
        return 0
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.ts" "*.tsx"; then
        printf 'typescript'
        return 0
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.cpp" "*.cc" "*.cxx" "*.hpp" "*.hh" "*.hxx"; then
        printf 'cpp'
        return 0
    fi

    return 1
}

evop_detect_project_type() {
    local target_dir="$1"
    local prompt="${2:-}"
    local combined_text

    combined_text="$(evop_lowercase "$prompt")"

    if evop_directory_has_file_pattern "$target_dir" "*.tex" "*.bib" \
        || evop_text_contains_any "$combined_text" "paper" "manuscript" "latex" "论文"; then
        printf 'paper'
        return 0
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.pptx" "*.key" \
        || evop_directory_has_path_named "$target_dir" "slides" \
        || evop_text_contains_any "$combined_text" "ppt" "slides" "slide deck" "presentation" "deck" "幻灯片" "演示文稿"; then
        printf 'ppt'
        return 0
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.ipynb" \
        || evop_directory_has_path_named "$target_dir" "notebooks" \
        || evop_directory_has_path_named "$target_dir" "datasets" \
        || evop_text_contains_any "$combined_text" "experiment" "scientific experiment" "benchmark" "dataset" "analysis pipeline" "实验"; then
        printf 'scientific-experiment'
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "AndroidManifest.xml" \
        || evop_directory_has_file_named "$target_dir" "Info.plist" \
        || evop_text_contains_any "$combined_text" "mobile game" "ios game" "android game" "手机游戏"; then
        printf 'mobile-game'
        return 0
    fi

    if evop_text_contains_any "$combined_text" "online game" "multiplayer" "networked game" "dedicated server" "client sync" "server authoritative" "联网游戏"; then
        printf 'online-game'
        return 0
    fi

    if evop_text_contains_any "$combined_text" "single-player game" "offline game" "solo game" "单机游戏"; then
        printf 'single-player-game'
        return 0
    fi

    if evop_text_contains_any "$combined_text" "game" "玩法" "关卡" "combat loop" "boss fight"; then
        printf 'single-player-game'
        return 0
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.docx" "*.xlsx" "*.doc" "*.xls" \
        || evop_text_contains_any "$combined_text" "office" "spreadsheet" "report" "word document" "excel" "办公"; then
        printf 'office'
        return 0
    fi

    return 1
}

evop_resolve_profiles() {
    local target_dir="$1"
    local prompt="${2:-}"
    local requested_language_profile="${3:-}"
    local requested_project_type="${4:-}"

    EVOP_RESOLVED_LANGUAGE_PROFILE="$requested_language_profile"
    EVOP_RESOLVED_LANGUAGE_SOURCE="none"
    EVOP_RESOLVED_PROJECT_TYPE="$requested_project_type"
    EVOP_RESOLVED_PROJECT_SOURCE="none"

    if [[ -n "$requested_language_profile" ]]; then
        EVOP_RESOLVED_LANGUAGE_SOURCE="explicit"
    elif EVOP_RESOLVED_LANGUAGE_PROFILE="$(evop_detect_language_profile "$target_dir")"; then
        EVOP_RESOLVED_LANGUAGE_SOURCE="auto"
    else
        EVOP_RESOLVED_LANGUAGE_PROFILE=""
    fi

    if [[ -n "$requested_project_type" ]]; then
        EVOP_RESOLVED_PROJECT_SOURCE="explicit"
    elif EVOP_RESOLVED_PROJECT_TYPE="$(evop_detect_project_type "$target_dir" "$prompt")"; then
        EVOP_RESOLVED_PROJECT_SOURCE="auto"
    else
        EVOP_RESOLVED_PROJECT_TYPE=""
    fi
}

evop_language_guidance() {
    local language_profile="$1"

    case "$language_profile" in
        python)
            cat <<'EOF'
- Prefer `pyproject.toml`-based project structure.
- Use virtual-environment-friendly commands and document setup clearly.
- Favor typed Python, modular packages, and `pytest`-style tests when tests are appropriate.
- Keep scripts and entrypoints simple to run from a clean machine.
EOF
            ;;
        cpp)
            cat <<'EOF'
- Prefer a reproducible build setup such as CMake.
- Be explicit about compiler requirements, include paths, and third-party dependencies.
- Keep headers and source files organized for maintainability and build speed.
- Prioritize memory safety, deterministic behavior, and practical testability.
EOF
            ;;
        go)
            cat <<'EOF'
- Follow standard Go project layout and module conventions.
- Keep packages small, explicit, and easy to test with `go test`.
- Prefer simple concurrency patterns and clear error handling.
- Minimize unnecessary abstraction and keep tooling reproducible.
EOF
            ;;
        rust)
            cat <<'EOF'
- Use idiomatic Cargo project structure and document crate usage clearly.
- Favor safe Rust, explicit error handling, and strong type modeling.
- Keep modules cohesive and write tests that fit Rust workflows.
- Avoid unnecessary `unsafe` and explain it if it is truly required.
EOF
            ;;
        typescript)
            cat <<'EOF'
- Use clear TypeScript configuration and keep strict typing where practical.
- Prefer maintainable module boundaries and consistent package scripts.
- Make browser/server distinctions explicit and avoid implicit any-like behavior.
- Include developer-friendly setup, build, lint, and test workflows when relevant.
EOF
            ;;
    esac
}

evop_project_type_guidance() {
    local project_type="$1"

    case "$project_type" in
        single-player-game)
            cat <<'EOF'
- Optimize for offline play, clear progression, save/load behavior, and moment-to-moment responsiveness.
- Keep game loops, assets, controls, and content pipelines understandable for a solo codebase.
- Prefer simple deployment and playtesting workflows over backend complexity.
EOF
            ;;
        paper)
            cat <<'EOF'
- Optimize for argument structure, citations, reproducibility notes, and publication-ready organization.
- Separate source materials, generated figures/tables, and final deliverables cleanly.
- Prefer workflows that make revision tracking and review straightforward.
EOF
            ;;
        scientific-experiment)
            cat <<'EOF'
- Optimize for reproducibility, parameter tracking, logging, and experimental rigor.
- Make datasets, scripts, outputs, and analysis steps traceable end-to-end.
- Prefer deterministic runs, explicit assumptions, and result summaries that can be audited later.
EOF
            ;;
        mobile-game)
            cat <<'EOF'
- Optimize for touch-first interaction, low-friction onboarding, and mobile performance constraints.
- Account for battery, memory, varying screen sizes, and mobile asset handling.
- Prefer iteration speed, simple packaging, and testable gameplay slices.
EOF
            ;;
        online-game)
            cat <<'EOF'
- Optimize for client/server boundaries, latency tolerance, synchronization, and operational safety.
- Be explicit about networking assumptions, state authority, and failure handling.
- Prefer observability, testability, and incremental rollout of multiplayer features.
EOF
            ;;
        ppt)
            cat <<'EOF'
- Optimize for clear slide narrative, audience readability, and presentation-ready output.
- Structure source content so charts, visuals, notes, and exported deliverables stay maintainable.
- Prefer repeatable generation workflows over one-off manual edits when automation is involved.
EOF
            ;;
        office)
            cat <<'EOF'
- Optimize for practical business workflows, maintainable documents, and low-friction handoff.
- Favor clarity, templates, automation where useful, and outputs that non-engineers can use.
- Keep setup simple and document how to run or update office deliverables.
EOF
            ;;
    esac
}

evop_compose_prompt() {
    local prompt="$1"
    local language_profile="${2:-}"
    local project_type="${3:-}"
    local guidance=""

    if [[ -n "$language_profile" ]]; then
        guidance+="[Language Adaptation]\n"
        guidance+="Target language: $language_profile\n"
        guidance+="$(evop_language_guidance "$language_profile")\n\n"
    fi

    if [[ -n "$project_type" ]]; then
        guidance+="[Project-Type Adaptation]\n"
        guidance+="Target project type: $project_type\n"
        guidance+="$(evop_project_type_guidance "$project_type")\n\n"
    fi

    if [[ -z "$guidance" ]]; then
        printf '%s' "$prompt"
        return 0
    fi

    printf '%b' "${guidance}[User Request]\n${prompt}"
}
