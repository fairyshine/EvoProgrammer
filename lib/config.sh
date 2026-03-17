#!/usr/bin/env zsh

EVOP_CONFIG_FILENAME=".evoprogrammer.conf"

evop_load_project_config() {
    local target_dir="$1"
    local config_file="$target_dir/$EVOP_CONFIG_FILENAME"

    if [[ ! -f "$config_file" ]]; then
        return 0
    fi

    local line key value
    while IFS= read -r line || [[ -n "$line" ]]; do
        # skip comments and blank lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue

        if [[ "$line" != *=* ]]; then
            continue
        fi

        key="${line%%=*}"
        value="${line#*=}"
        # trim whitespace from key
        key="$(printf '%s' "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        # strip surrounding quotes from value
        value="$(printf '%s' "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
        value="${value#\"}"
        value="${value%\"}"
        value="${value#\'}"
        value="${value%\'}"

        # only set if the corresponding env var is not already set
        # priority: CLI flags > env vars > config file > defaults
        case "$key" in
            agent)
                AGENT="${EVOPROGRAMMER_AGENT:-$value}"
                ;;
            language)
                if [[ -z "${EVOPROGRAMMER_LANGUAGE_PROFILE:-}" && -z "$LANGUAGE_PROFILE" ]]; then
                    LANGUAGE_PROFILE="$value"
                fi
                ;;
            framework)
                if [[ -z "${EVOPROGRAMMER_FRAMEWORK_PROFILE:-}" && -z "$FRAMEWORK_PROFILE" ]]; then
                    FRAMEWORK_PROFILE="$value"
                fi
                ;;
            project_type)
                if [[ -z "${EVOPROGRAMMER_PROJECT_TYPE:-}" && -z "$PROJECT_TYPE" ]]; then
                    PROJECT_TYPE="$value"
                fi
                ;;
            max_iterations)
                if [[ -z "${EVOPROGRAMMER_MAX_ITERATIONS:-}" ]]; then
                    EVOP_CONFIG_MAX_ITERATIONS="$value"
                fi
                ;;
            delay_seconds)
                if [[ -z "${EVOPROGRAMMER_DELAY_SECONDS:-}" ]]; then
                    EVOP_CONFIG_DELAY_SECONDS="$value"
                fi
                ;;
            continue_on_error)
                if [[ -z "${EVOPROGRAMMER_CONTINUE_ON_ERROR:-}" ]]; then
                    EVOP_CONFIG_CONTINUE_ON_ERROR="$value"
                fi
                ;;
            artifacts_dir)
                if [[ -z "${EVOPROGRAMMER_ARTIFACTS_DIR:-}" && -z "$ARTIFACTS_DIR" ]]; then
                    ARTIFACTS_DIR="$value"
                fi
                ;;
            verbosity)
                if [[ "$EVOP_VERBOSITY" == "1" ]]; then
                    EVOP_VERBOSITY="$value"
                fi
                ;;
        esac
    done <"$config_file"
}
