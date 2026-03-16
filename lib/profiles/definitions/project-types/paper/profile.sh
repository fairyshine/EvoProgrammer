#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for argument structure, citations, reproducibility notes, and publication-ready organization.\n- Separate source materials, generated figures/tables, and final deliverables cleanly.\n- Prefer workflows that make revision tracking and review straightforward.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_pattern 100 "$target_dir" "*.tex" "*.bib" && return 0
    evop_profile_match_prompt 100 "$prompt" "paper" "manuscript" "latex" "论文" && return 0
    return 1
}
