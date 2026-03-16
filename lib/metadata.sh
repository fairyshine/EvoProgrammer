#!/usr/bin/env bash

EVOP_COMMON_METADATA_ARGS=()

evop_build_common_metadata_args() {
    local prompt_source="$1"
    local artifacts_root="$2"

    EVOP_COMMON_METADATA_ARGS=(
        AGENT "$AGENT"
        LANGUAGE_PROFILE "$LANGUAGE_PROFILE"
        LANGUAGE_PROFILE_SOURCE "$LANGUAGE_PROFILE_SOURCE"
        FRAMEWORK_PROFILE "$FRAMEWORK_PROFILE"
        FRAMEWORK_PROFILE_SOURCE "$FRAMEWORK_PROFILE_SOURCE"
        PROJECT_TYPE "$PROJECT_TYPE"
        PROJECT_TYPE_SOURCE "$PROJECT_TYPE_SOURCE"
        TARGET_DIR "$TARGET_DIR"
        ARTIFACTS_ROOT "$artifacts_root"
        PROMPT_SOURCE "$prompt_source"
    )
}
