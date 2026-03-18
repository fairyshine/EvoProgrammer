#!/usr/bin/env zsh

evop_detect_task_workflow() {
    local prompt="${1:-}"

    evop_prepare_prompt_facts "$prompt"
    case "${EVOP_PROMPT_FACTS_TASK_KIND:-}" in
        review)
            EVOP_PROJECT_CONTEXT_TASK_KIND="review"
            EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Inspect the touched paths first, prioritize bugs, regressions, and missing tests, and keep summaries secondary."
            return 0
            ;;
        bugfix)
            EVOP_PROJECT_CONTEXT_TASK_KIND="bugfix"
            EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Reproduce or localize the failure path first, apply the smallest coherent fix, and add targeted verification."
            return 0
            ;;
        refactor)
            EVOP_PROJECT_CONTEXT_TASK_KIND="refactor"
            EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Preserve behavior, move one boundary at a time, and compare against existing call sites before broad cleanup."
            return 0
            ;;
        performance)
            EVOP_PROJECT_CONTEXT_TASK_KIND="performance"
            EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Measure or localize the hotspot first, optimize the smallest hot path, and re-verify correctness after the change."
            return 0
            ;;
        feature)
            EVOP_PROJECT_CONTEXT_TASK_KIND="feature"
            EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Find the nearest existing implementation first, extend types, data flow, and tests together, and avoid inventing a parallel pattern."
            return 0
            ;;
    esac

    if evop_text_contains_any "$prompt" "review" "code review" "审查" "评审"; then
        EVOP_PROJECT_CONTEXT_TASK_KIND="review"
        EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Inspect the touched paths first, prioritize bugs, regressions, and missing tests, and keep summaries secondary."
        return 0
    fi

    if evop_text_contains_any "$prompt" "bug" "fix" "error" "failing" "regression" "修复" "报错"; then
        EVOP_PROJECT_CONTEXT_TASK_KIND="bugfix"
        EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Reproduce or localize the failure path first, apply the smallest coherent fix, and add targeted verification."
        return 0
    fi

    if evop_text_contains_any "$prompt" "refactor" "cleanup" "clean up" "restructure" "重构"; then
        EVOP_PROJECT_CONTEXT_TASK_KIND="refactor"
        EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Preserve behavior, move one boundary at a time, and compare against existing call sites before broad cleanup."
        return 0
    fi

    if evop_text_contains_any "$prompt" "performance" "optimize" "latency" "slow" "性能" "优化"; then
        EVOP_PROJECT_CONTEXT_TASK_KIND="performance"
        EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Measure or localize the hotspot first, optimize the smallest hot path, and re-verify correctness after the change."
        return 0
    fi

    EVOP_PROJECT_CONTEXT_TASK_KIND="feature"
    EVOP_PROJECT_CONTEXT_TASK_WORKFLOW="Find the nearest existing implementation first, extend types, data flow, and tests together, and avoid inventing a parallel pattern."
}

evop_reset_project_context_workflow() {
    EVOP_PROJECT_CONTEXT_TASK_KIND=""
    EVOP_PROJECT_CONTEXT_TASK_WORKFLOW=""
    EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY=""
    EVOP_PROJECT_CONTEXT_EDIT_STRATEGY=""
    EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY=""
    EVOP_PROJECT_CONTEXT_RISK_FOCUS=""
}

evop_apply_profile_workflow() {
    local category_dir="$1"
    local profile_name="${2:-}"
    local target_dir="$3"
    local prompt="${4:-}"

    [[ -n "$profile_name" ]] || return 0
    evop_apply_profile_project_context_hooks "$category_dir" "$profile_name" "$target_dir" "$prompt"
}

evop_detect_task_kind_workflow() {
    case "$EVOP_PROJECT_CONTEXT_TASK_KIND" in
        review)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Inspect the changed paths and surrounding callers before forming conclusions."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Do not optimize for rewrites; prioritize concrete defects, regressions, and missing tests."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Anchor findings to existing behavior, affected tests, and contract surfaces."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Focus on correctness, regressions, and unverified assumptions instead of style."
            ;;
        bugfix)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Trace the failing path or closest reproduction before changing unrelated code."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Apply the smallest coherent fix and keep unrelated cleanup out of scope."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Re-run the closest failing checks first, then the normal verification chain."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Regression risk is highest around call sites that depended on the old failure mode."
            ;;
        refactor)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Map callers, shared interfaces, and tests before moving boundaries."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Preserve behavior, migrate one seam at a time, and compare before and after call paths."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Prefer equivalence-focused tests and broad type or compile checks after each move."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Behavioral drift and missed edge-case coverage are the main refactor risks."
            ;;
        performance)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Localize the hotspot, expensive render path, or slow query before editing."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Optimize the narrowest hot path first and avoid speculative architectural changes."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Verify both correctness and the targeted latency or throughput path after changes."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Caching mistakes, stale data, and concurrency regressions often hide behind performance work."
            ;;
        feature|*)
            evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Find the nearest existing implementation and mirror its structure before adding new code."
            evop_append_multiline EVOP_PROJECT_CONTEXT_EDIT_STRATEGY "Extend types, behavior, and tests together instead of introducing a parallel pattern."
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "Confirm the new path works end-to-end and that adjacent flows still behave correctly."
            evop_append_multiline EVOP_PROJECT_CONTEXT_RISK_FOCUS "Partial integration is the main risk: types, storage, APIs, and UI can drift if changed separately."
            ;;
    esac
}

evop_finalize_workflow_strategy() {
    local slot=""
    local verification_summary=""

    if [[ -n "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS" ]]; then
        evop_append_multiline EVOP_PROJECT_CONTEXT_SEARCH_STRATEGY "Start with these repository paths: $EVOP_PROJECT_CONTEXT_SEARCH_ROOTS"
    fi

    if evop_project_has_any_command; then
        verification_summary="Use the repository verification chain in this order:"
        while IFS= read -r slot; do
            [[ -n "$(evop_get_project_command "$slot")" ]] || continue
            if [[ "$verification_summary" == *":" ]]; then
                verification_summary+=" $slot"
            else
                verification_summary+=" -> $slot"
            fi
        done < <(evop_project_verification_slots)
        if [[ "$verification_summary" != "Use the repository verification chain in this order:" ]]; then
            evop_append_multiline EVOP_PROJECT_CONTEXT_VERIFICATION_STRATEGY "$verification_summary"
        fi
    fi
}

evop_rebuild_project_context_workflow() {
    local target_dir="$1"
    local prompt="${2:-}"
    local language_profile="${3:-}"
    local framework_profile="${4:-}"
    local project_type="${5:-}"

    evop_reset_project_context_workflow
    evop_detect_task_workflow "$prompt"
    evop_apply_profile_workflow "languages" "$language_profile" "$target_dir" "$prompt"
    evop_apply_profile_workflow "frameworks" "$framework_profile" "$target_dir" "$prompt"
    evop_apply_profile_workflow "project-types" "$project_type" "$target_dir" "$prompt"
    evop_detect_task_kind_workflow
    evop_finalize_workflow_strategy
}

evop_analyze_project_context() {
    local target_dir="$1"
    local prompt="${2:-}"
    local language_profile="${3:-}"
    local framework_profile="${4:-}"
    local project_type="${5:-}"

    evop_reset_project_context
    evop_use_project_context_facts_dir "$target_dir"
    EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER="$(evop_choose_package_manager "$target_dir" "$language_profile" || true)"
    EVOP_PROJECT_CONTEXT_WORKSPACE_MODE="$(evop_detect_workspace_mode "$target_dir")"

    evop_detect_command_hints "$target_dir" "$EVOP_PROJECT_CONTEXT_PACKAGE_MANAGER" "$language_profile" "$framework_profile" "$project_type"
    evop_detect_structure_hints "$target_dir"
    evop_detect_conventions "$target_dir" "$language_profile"
    evop_detect_automation_hints "$target_dir"
    evop_detect_risk_areas "$target_dir"
    evop_detect_validation_hints
    evop_detect_task_workflow "$prompt"

    if [[ -z "$EVOP_PROJECT_CONTEXT_SEARCH_ROOTS" ]]; then
        if [[ -d "$target_dir/src" ]]; then
            EVOP_PROJECT_CONTEXT_SEARCH_ROOTS="src"
        elif [[ -n "$framework_profile" || -n "$project_type" ]]; then
            EVOP_PROJECT_CONTEXT_SEARCH_ROOTS="."
        fi
    fi

    evop_rebuild_project_context_workflow "$target_dir" "$prompt" "$language_profile" "$framework_profile" "$project_type"
}
