#!/usr/bin/env bash

EVOP_PROFILE_PROMPT=$'- Make routing, App Router or Pages Router choices, and server/client boundaries explicit.\n- Keep data fetching, mutations, and cache or revalidation behavior aligned with Next.js conventions.\n- Avoid leaking server-only logic into client bundles, and keep route structure predictable for deployment.'

evop_profile_detect() {
    local target_dir="$1"
    local prompt="${2:-}"

    evop_profile_match_file_named 100 "$target_dir" "next.config.js" "next.config.mjs" "next.config.ts" && return 0
    evop_profile_match_directory_text 95 "$target_dir" "\"next\"" "package.json" && return 0
    evop_profile_match_prompt 40 "$prompt" "next.js" "nextjs" && return 0
    return 1
}
