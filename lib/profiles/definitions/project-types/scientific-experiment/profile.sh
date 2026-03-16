#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Optimize for reproducibility, parameter tracking, logging, and experimental rigor.\n- Make datasets, scripts, outputs, and analysis steps traceable end-to-end.\n- Prefer deterministic runs, explicit assumptions, and result summaries that can be audited later.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_pattern 98 "$target_dir" "*.ipynb" && return 0
    evop_profile_match_path_named 98 "$target_dir" "notebooks" "datasets" && return 0
    evop_profile_match_prompt 98 "$prompt" "experiment" "scientific experiment" "benchmark" "dataset" "analysis pipeline" "实验" && return 0
    return 1
}
