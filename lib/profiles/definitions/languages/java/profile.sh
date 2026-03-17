#!/usr/bin/env zsh

EVOP_PROFILE_PROMPT=$'- Prefer reproducible builds with Maven or Gradle and document the entrypoints clearly.\n- Organize packages by domain and execution boundary rather than dumping everything into one layer.\n- Keep test structure maintainable and be explicit about runtime and JVM requirements.\n- Favor straightforward dependency wiring and operational clarity.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    if evop_profile_match_file_named 90 "$target_dir" "pom.xml"; then
        return 0
    fi

    if evop_profile_match_file_named 85 "$target_dir" "build.gradle" "build.gradle.kts"; then
        if evop_directory_has_file_pattern "$target_dir" "*.kt" "*.kts" || evop_text_contains_any "$prompt" "kotlin"; then
            return 1
        fi
        return 0
    fi

    evop_profile_match_file_pattern 80 "$target_dir" "*.java" && return 0
    evop_profile_match_prompt 40 "$prompt" "java" && return 0
    return 1
}
