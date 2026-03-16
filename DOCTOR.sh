#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
RUNTIME_LIB="$SCRIPT_DIR/lib/runtime.sh"
AGENT_LIB="$SCRIPT_DIR/lib/agent.sh"
PROFILE_LIB="$SCRIPT_DIR/lib/profile.sh"
MAIN_SCRIPT="$SCRIPT_DIR/MAIN.sh"
LOOP_SCRIPT="$SCRIPT_DIR/LOOP.sh"

source "$COMMON_LIB"
source "$RUNTIME_LIB"
source "$AGENT_LIB"
source "$PROFILE_LIB"

TARGET_DIR="${EVOPROGRAMMER_TARGET_DIR:-$(pwd)}"
ARTIFACTS_DIR="${EVOPROGRAMMER_ARTIFACTS_DIR:-}"
AGENT="${EVOPROGRAMMER_AGENT:-$EVOPROGRAMMER_DEFAULT_AGENT}"
LANGUAGE_PROFILE="${EVOPROGRAMMER_LANGUAGE_PROFILE:-}"
PROJECT_TYPE="${EVOPROGRAMMER_PROJECT_TYPE:-}"
LANGUAGE_PROFILE_SOURCE="none"
PROJECT_TYPE_SOURCE="none"

usage() {
    cat <<'EOF'
Usage: ./DOCTOR.sh [options]

Checks whether EvoProgrammer can run in the requested target directory.

Options:
  -g, --agent NAME       Agent to validate: codex or claude.
      --language NAME    Language adaptation profile. Auto-detected when omitted.
      --project-type NAME
                         Project-type adaptation profile. Auto-detected when omitted.
  -t, --target-dir DIR   Repository directory to validate.
  -o, --artifacts-dir DIR
                         Root directory used to store run artifacts.
  -h, --help             Show this help text.

Environment variables:
  EVOPROGRAMMER_AGENT       Agent to validate. Default: codex.
  EVOPROGRAMMER_LANGUAGE_PROFILE
                           Language adaptation profile. Auto-detected when omitted.
  EVOPROGRAMMER_PROJECT_TYPE
                           Project-type adaptation profile. Auto-detected when omitted.
  EVOPROGRAMMER_TARGET_DIR  Repository directory to validate. Default: current directory.
  EVOPROGRAMMER_ARTIFACTS_DIR
                           Root directory used to store run artifacts.
                           Default: TARGET_DIR/.evoprogrammer/runs
EOF
}

while (($# > 0)); do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -g|--agent)
            evop_require_option_value "$1" "$#"
            AGENT="$2"
            shift 2
            ;;
        --language)
            evop_require_option_value "$1" "$#"
            LANGUAGE_PROFILE="$2"
            shift 2
            ;;
        --project-type)
            evop_require_option_value "$1" "$#"
            PROJECT_TYPE="$2"
            shift 2
            ;;
        -t|--target-dir)
            evop_require_option_value "$1" "$#"
            TARGET_DIR="$2"
            shift 2
            ;;
        -o|--artifacts-dir)
            evop_require_option_value "$1" "$#"
            ARTIFACTS_DIR="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
        *)
            echo "Unexpected argument: $1" >&2
            exit 1
            ;;
    esac
done

if (($# > 0)); then
    echo "Unexpected extra arguments: $*" >&2
    exit 1
fi

evop_require_executable_file "$MAIN_SCRIPT" "Main script"
evop_require_executable_file "$LOOP_SCRIPT" "Loop script"
evop_validate_agent "$AGENT"
evop_validate_language_profile "$LANGUAGE_PROFILE"
evop_validate_project_type "$PROJECT_TYPE"
evop_require_directory "$TARGET_DIR"
target_dir_abs="$(evop_resolve_physical_dir "$TARGET_DIR")"
evop_resolve_profiles "$target_dir_abs" "" "$LANGUAGE_PROFILE" "$PROJECT_TYPE"
LANGUAGE_PROFILE="$EVOP_RESOLVED_LANGUAGE_PROFILE"
LANGUAGE_PROFILE_SOURCE="$EVOP_RESOLVED_LANGUAGE_SOURCE"
PROJECT_TYPE="$EVOP_RESOLVED_PROJECT_TYPE"
PROJECT_TYPE_SOURCE="$EVOP_RESOLVED_PROJECT_SOURCE"
agent_command_name="$(evop_agent_command_name "$AGENT")"
evop_require_command "$agent_command_name"
artifacts_root="$(evop_resolve_artifacts_root "$TARGET_DIR" "$ARTIFACTS_DIR")"
mkdir -p "$artifacts_root"

printf 'OK main-script %s\n' "$MAIN_SCRIPT"
printf 'OK loop-script %s\n' "$LOOP_SCRIPT"
printf 'OK agent %s\n' "$AGENT"
if [[ -n "$LANGUAGE_PROFILE" ]]; then
    printf 'OK language-profile %s' "$LANGUAGE_PROFILE"
    if [[ "$LANGUAGE_PROFILE_SOURCE" == "auto" ]]; then
        printf ' (auto-detected)'
    fi
    printf '\n'
fi
if [[ -n "$PROJECT_TYPE" ]]; then
    printf 'OK project-type %s' "$PROJECT_TYPE"
    if [[ "$PROJECT_TYPE_SOURCE" == "auto" ]]; then
        printf ' (auto-detected)'
    fi
    printf '\n'
fi
printf 'OK target-dir %s\n' "$TARGET_DIR"
printf 'OK artifacts-dir %s\n' "$artifacts_root"
printf 'OK command %s\n' "$(command -v "$agent_command_name")"
