#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for practical business workflows, maintainable documents, and low-friction handoff.\n- Favor clarity, templates, automation where useful, and outputs that non-engineers can use.\n- Keep setup simple and document how to run or update office deliverables.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_pattern 89 "$target_dir" "*.docx" "*.xlsx" "*.doc" "*.xls" && return 0
    evop_profile_match_prompt 89 "$prompt" "office" "spreadsheet" "report" "word document" "excel" "办公" && return 0
    return 1
}
