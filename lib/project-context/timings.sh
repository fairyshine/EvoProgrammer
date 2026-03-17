#!/usr/bin/env bash

if [[ -n "${ZSH_VERSION:-}" ]]; then
    zmodload zsh/datetime 2>/dev/null || true
fi

EVOP_PROJECT_CONTEXT_TIMING_LANGUAGE_DETECT_MS=0
EVOP_PROJECT_CONTEXT_TIMING_FRAMEWORK_DETECT_MS=0
EVOP_PROJECT_CONTEXT_TIMING_PROJECT_TYPE_DETECT_MS=0
EVOP_PROJECT_CONTEXT_TIMING_ANALYZE_CONTEXT_MS=0
EVOP_PROJECT_CONTEXT_TIMING_RESOLVE_PROFILES_MS=0
EVOP_PROJECT_CONTEXT_TIMING_FINALIZE_ANALYSIS_MS=0

evop_reset_project_context_timings() {
    EVOP_PROJECT_CONTEXT_TIMING_LANGUAGE_DETECT_MS=0
    EVOP_PROJECT_CONTEXT_TIMING_FRAMEWORK_DETECT_MS=0
    EVOP_PROJECT_CONTEXT_TIMING_PROJECT_TYPE_DETECT_MS=0
    EVOP_PROJECT_CONTEXT_TIMING_ANALYZE_CONTEXT_MS=0
    EVOP_PROJECT_CONTEXT_TIMING_RESOLVE_PROFILES_MS=0
    EVOP_PROJECT_CONTEXT_TIMING_FINALIZE_ANALYSIS_MS=0
}

evop_now_millis() {
    local epoch_real=""
    local seconds=""
    local fraction=""

    if [[ -n "${EPOCHREALTIME:-}" ]]; then
        epoch_real="$EPOCHREALTIME"
        seconds="${epoch_real%%.*}"
        if [[ "$epoch_real" == *.* ]]; then
            fraction="${epoch_real#*.}"
        else
            fraction="0"
        fi

        while ((${#fraction} < 3)); do
            fraction+="0"
        done
        fraction="${fraction:0:3}"

        printf '%s' $((10#$seconds * 1000 + 10#$fraction))
        return 0
    fi

    printf '%s000' "$(date +%s)"
}

evop_elapsed_millis_since() {
    local started_ms="$1"
    local finished_ms=""
    local elapsed_ms=0

    finished_ms="$(evop_now_millis)"
    elapsed_ms=$((finished_ms - started_ms))
    if (( elapsed_ms < 0 )); then
        elapsed_ms=0
    fi

    printf '%s' "$elapsed_ms"
}

evop_project_context_timing_slots() {
    printf '%s\n' \
        language_detect \
        framework_detect \
        project_type_detect \
        analyze_context \
        resolve_profiles \
        finalize_analysis
}

evop_get_project_context_timing_ms() {
    case "$1" in
        language_detect)
            printf '%s' "$EVOP_PROJECT_CONTEXT_TIMING_LANGUAGE_DETECT_MS"
            ;;
        framework_detect)
            printf '%s' "$EVOP_PROJECT_CONTEXT_TIMING_FRAMEWORK_DETECT_MS"
            ;;
        project_type_detect)
            printf '%s' "$EVOP_PROJECT_CONTEXT_TIMING_PROJECT_TYPE_DETECT_MS"
            ;;
        analyze_context)
            printf '%s' "$EVOP_PROJECT_CONTEXT_TIMING_ANALYZE_CONTEXT_MS"
            ;;
        resolve_profiles)
            printf '%s' "$EVOP_PROJECT_CONTEXT_TIMING_RESOLVE_PROFILES_MS"
            ;;
        finalize_analysis)
            printf '%s' "$EVOP_PROJECT_CONTEXT_TIMING_FINALIZE_ANALYSIS_MS"
            ;;
        *)
            return 1
            ;;
    esac
}

evop_print_project_context_timings() {
    local slot=""
    local timing_ms=""

    while IFS= read -r slot; do
        timing_ms="$(evop_get_project_context_timing_ms "$slot")" || continue
        printf '%s: %sms\n' "$slot" "$timing_ms"
    done < <(evop_project_context_timing_slots)
}

evop_render_project_context_timings_json() {
    local output="{"
    local slot=""
    local timing_ms=""
    local needs_comma=0

    while IFS= read -r slot; do
        timing_ms="$(evop_get_project_context_timing_ms "$slot")" || continue
        if (( needs_comma == 1 )); then
            output+=", "
        fi
        output+="\"${slot}_ms\": $timing_ms"
        needs_comma=1
    done < <(evop_project_context_timing_slots)

    output+="}"
    printf '%s' "$output"
}
