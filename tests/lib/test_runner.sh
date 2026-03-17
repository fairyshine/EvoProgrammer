#!/usr/bin/env bash

# shellcheck disable=SC2034

evop_clear_named_array() {
    local output_name="$1"

    case "$output_name" in
        EVOP_TEST_CASE_FILES)
            EVOP_TEST_CASE_FILES=()
            ;;
        EVOP_SHELLCHECK_TARGETS)
            EVOP_SHELLCHECK_TARGETS=()
            ;;
        *)
            printf 'Unsupported array name: %s\n' "$output_name" >&2
            return 1
            ;;
    esac
}

evop_append_named_array() {
    local output_name="$1"
    local value="$2"

    case "$output_name" in
        EVOP_TEST_CASE_FILES)
            EVOP_TEST_CASE_FILES+=("$value")
            ;;
        EVOP_SHELLCHECK_TARGETS)
            EVOP_SHELLCHECK_TARGETS+=("$value")
            ;;
        *)
            printf 'Unsupported array name: %s\n' "$output_name" >&2
            return 1
            ;;
    esac
}

evop_read_lines_into_array() {
    local output_name="$1"
    shift
    local line

    evop_clear_named_array "$output_name"

    while IFS= read -r line; do
        evop_append_named_array "$output_name" "$line"
    done < <("$@")
}

evop_sort_named_array() {
    local output_name="$1"
    local value
    local sorted_values=()

    case "$output_name" in
        EVOP_TEST_CASE_FILES)
            if ((${#EVOP_TEST_CASE_FILES[@]} == 0)); then
                return 0
            fi
            while IFS= read -r value; do
                sorted_values+=("$value")
            done < <(printf '%s\n' "${EVOP_TEST_CASE_FILES[@]}" | LC_ALL=C sort)
            EVOP_TEST_CASE_FILES=("${sorted_values[@]}")
            ;;
        EVOP_SHELLCHECK_TARGETS)
            if ((${#EVOP_SHELLCHECK_TARGETS[@]} == 0)); then
                return 0
            fi
            while IFS= read -r value; do
                sorted_values+=("$value")
            done < <(printf '%s\n' "${EVOP_SHELLCHECK_TARGETS[@]}" | LC_ALL=C sort)
            EVOP_SHELLCHECK_TARGETS=("${sorted_values[@]}")
            ;;
        *)
            printf 'Unsupported array name: %s\n' "$output_name" >&2
            return 1
            ;;
    esac
}

evop_collect_test_case_files() {
    local root_dir="$1"
    local cases_dir="$root_dir/tests/cases"

    if [[ ! -d "$cases_dir" ]]; then
        EVOP_TEST_CASE_FILES=()
        return 0
    fi

    evop_read_lines_into_array EVOP_TEST_CASE_FILES find "$cases_dir" -type f -name '*.sh'
    evop_sort_named_array EVOP_TEST_CASE_FILES
}

evop_test_case_matches_filters() {
    local root_dir="$1"
    local case_file="$2"
    shift 2
    local relative_path case_name case_stem filter

    if (($# == 0)); then
        return 0
    fi

    relative_path="${case_file#"$root_dir"/}"
    case_name="${case_file##*/}"
    case_stem="${case_name%.sh}"

    for filter in "$@"; do
        case "$relative_path" in
            *"$filter"*)
                return 0
                ;;
        esac
        case "$case_name" in
            *"$filter"*)
                return 0
                ;;
        esac
        case "$case_stem" in
            *"$filter"*)
                return 0
                ;;
        esac
    done

    return 1
}

evop_select_test_case_files() {
    local root_dir="$1"
    shift
    local case_file

    evop_collect_test_case_files "$root_dir"
    EVOP_SELECTED_TEST_CASE_FILES=()

    for case_file in "${EVOP_TEST_CASE_FILES[@]}"; do
        if evop_test_case_matches_filters "$root_dir" "$case_file" "$@"; then
            EVOP_SELECTED_TEST_CASE_FILES+=("$case_file")
        fi
    done
}

evop_print_selected_test_cases() {
    local root_dir="$1"
    shift
    local case_file

    evop_select_test_case_files "$root_dir" "$@"
    for case_file in "${EVOP_SELECTED_TEST_CASE_FILES[@]}"; do
        printf '%s\n' "${case_file#"$root_dir"/}"
    done
}

evop_collect_shellcheck_targets() {
    local root_dir="$1"

    EVOP_SHELLCHECK_TARGETS=()

    evop_read_lines_into_array EVOP_SHELLCHECK_TARGETS find "$root_dir/tests" -type f -name '*.sh'
    EVOP_SHELLCHECK_TARGETS+=("$root_dir/install.sh")
    evop_sort_named_array EVOP_SHELLCHECK_TARGETS
}
