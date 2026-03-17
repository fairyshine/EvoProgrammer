#!/usr/bin/env zsh

evop_print_project_inspection_diagnostics() {
    local line=""

    evop_print_project_inspection_report
    printf 'Inspection diagnostics:\n'
    printf -- '- Facts directory: %s\n' "${EVOP_PROJECT_CONTEXT_FACTS_DIR:-unknown}"
    while IFS= read -r line; do
        printf -- '- %s\n' "$line"
    done < <(evop_print_project_context_facts_diagnostics)
    while IFS= read -r line; do
        printf -- '- Timing %s\n' "$line"
    done < <(evop_print_project_context_timings)
    while IFS= read -r line; do
        [[ "$line" == Target\ directory:* ]] && continue
        [[ "$line" == Profile\ detection\ report:* ]] && continue
        printf -- '- %s\n' "$line"
    done < <(evop_print_profile_detection_report)
}

evop_print_project_inspection_timings() {
    printf 'Inspection timings (ms):\n'
    while IFS= read -r line; do
        printf -- '- %s\n' "$line"
    done < <(evop_print_project_context_timings)
}
