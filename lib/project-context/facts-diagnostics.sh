#!/usr/bin/env zsh

evop_print_project_context_facts_diagnostics() {
    printf 'Facts cache backend: %s\n' "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_BACKEND"
    printf 'Facts cache lookups: %s\n' "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_LOOKUPS"
    printf 'Facts cache hits: %s\n' "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS"
    printf 'Facts cache misses: %s\n' "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_MISSES"
    printf 'Facts cache hit rate: %s%%\n' "$(evop_project_context_cache_hit_rate_percent)"
    printf 'Relative-exists cache entries: %s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE)"
    printf 'File-literal cache entries: %s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE)"
    printf 'File-regex cache entries: %s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE)"
    printf 'File-text cache entries: %s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE)"
    printf 'Command-availability cache entries: %s\n' "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_COMMAND_AVAILABILITY_CACHE)"
}

evop_render_project_context_facts_diagnostics_json() {
    printf '{"backend": %s, "lookups": %s, "hits": %s, "misses": %s, "hit_rate_percent": %s, "relative_exists_entries": %s, "file_literal_entries": %s, "file_regex_entries": %s, "file_text_entries": %s, "command_availability_entries": %s}' \
        "\"$EVOP_PROJECT_CONTEXT_FACTS_CACHE_BACKEND\"" \
        "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_LOOKUPS" \
        "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_HITS" \
        "$EVOP_PROJECT_CONTEXT_FACTS_CACHE_MISSES" \
        "$(evop_project_context_cache_hit_rate_percent)" \
        "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_RELATIVE_EXISTS_CACHE)" \
        "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_LITERAL_CACHE)" \
        "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_REGEX_CACHE)" \
        "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_FILE_TEXT_CACHE)" \
        "$(evop_project_context_cache_entry_count EVOP_PROJECT_CONTEXT_COMMAND_AVAILABILITY_CACHE)"
}
