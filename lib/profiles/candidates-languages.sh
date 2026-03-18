#!/usr/bin/env zsh

evop_prepare_language_profile_candidates() {
    local target_dir="$1"
    local prompt="${2:-}"
    local candidates=""

    if evop_repo_looks_like_shell_cli "$target_dir"; then
        evop_profile_candidate_append_unique candidates "shell"
        evop_profile_candidate_add_if_prompt_matches candidates "shell" "$prompt" "bash" "shell" "shell script" "脚本"
        EVOP_PROFILE_CANDIDATE_MODE="filtered"
        EVOP_PROFILE_CANDIDATE_LIST="$candidates"
        return 0
    fi

    if evop_directory_has_file_named "$target_dir" "tsconfig.json" \
        || evop_directory_has_file_extension "$target_dir" "ts" "tsx"; then
        evop_profile_candidate_append_unique candidates "typescript"
    fi

    if evop_directory_has_file_named "$target_dir" "package.json" \
        || evop_directory_has_file_extension "$target_dir" "js" "jsx" "mjs" "cjs"; then
        evop_profile_candidate_append_unique candidates "javascript"
    fi

    if evop_directory_has_file_named "$target_dir" "pyproject.toml" "requirements.txt" "setup.py" \
        || evop_directory_has_file_extension "$target_dir" "py"; then
        evop_profile_candidate_append_unique candidates "python"
    fi

    if evop_directory_has_file_named "$target_dir" "Cargo.toml" \
        || evop_directory_has_file_extension "$target_dir" "rs"; then
        evop_profile_candidate_append_unique candidates "rust"
    fi

    if evop_directory_has_file_named "$target_dir" "build.sbt" \
        || evop_directory_has_file_extension "$target_dir" "scala" "sc"; then
        evop_profile_candidate_append_unique candidates "scala"
    fi

    if evop_directory_has_file_named "$target_dir" "go.mod" \
        || evop_directory_has_file_extension "$target_dir" "go"; then
        evop_profile_candidate_append_unique candidates "go"
    fi

    if evop_directory_has_file_named "$target_dir" "Gemfile" \
        || evop_directory_has_file_extension "$target_dir" "rb"; then
        evop_profile_candidate_append_unique candidates "ruby"
    fi

    if evop_directory_has_file_named "$target_dir" "composer.json" \
        || evop_directory_has_file_extension "$target_dir" "php"; then
        evop_profile_candidate_append_unique candidates "php"
    fi

    if evop_directory_has_file_named "$target_dir" "pom.xml" "build.gradle" "build.gradle.kts" \
        || evop_directory_has_file_extension "$target_dir" "java"; then
        evop_profile_candidate_append_unique candidates "java"
    fi

    if evop_directory_has_file_extension "$target_dir" "kt" "kts"; then
        evop_profile_candidate_append_unique candidates "kotlin"
    fi

    if evop_directory_has_file_extension "$target_dir" "sln" "csproj" "cs"; then
        evop_profile_candidate_append_unique candidates "csharp"
    fi

    if evop_directory_has_file_extension "$target_dir" "c" "h" \
        && ! evop_directory_has_file_extension "$target_dir" "cpp" "cc" "cxx" "hpp" "hh" "hxx"; then
        evop_profile_candidate_append_unique candidates "c"
    fi

    if evop_directory_has_file_named "$target_dir" "CMakeLists.txt" \
        || evop_directory_has_file_extension "$target_dir" "cpp" "cc" "cxx" "hpp" "hh" "hxx"; then
        evop_profile_candidate_append_unique candidates "cpp"
    fi

    if evop_directory_has_file_named "$target_dir" "Package.swift" \
        || evop_directory_has_file_extension "$target_dir" "swift"; then
        evop_profile_candidate_append_unique candidates "swift"
    fi

    if evop_directory_has_file_named "$target_dir" "pubspec.yaml" \
        || evop_directory_has_file_extension "$target_dir" "dart"; then
        evop_profile_candidate_append_unique candidates "dart"
    fi

    if evop_directory_has_file_pattern "$target_dir" "*.rockspec" \
        || evop_directory_has_file_extension "$target_dir" "lua"; then
        evop_profile_candidate_append_unique candidates "lua"
    fi

    if evop_directory_has_file_named "$target_dir" "project.godot" \
        || evop_directory_has_file_extension "$target_dir" "gd"; then
        evop_profile_candidate_append_unique candidates "gdscript"
    fi

    if evop_directory_has_file_named "$target_dir" "mix.exs" \
        || evop_directory_has_file_extension "$target_dir" "ex" "exs"; then
        evop_profile_candidate_append_unique candidates "elixir"
    fi

    if evop_directory_has_file_named "$target_dir" "deps.edn" "project.clj" "build.boot" \
        || evop_directory_has_file_extension "$target_dir" "clj" "cljs" "cljc"; then
        evop_profile_candidate_append_unique candidates "clojure"
    fi

    if evop_directory_has_file_named "$target_dir" "stack.yaml" "cabal.project" \
        || evop_directory_has_file_pattern "$target_dir" "*.cabal" \
        || evop_directory_has_file_extension "$target_dir" "hs" "lhs"; then
        evop_profile_candidate_append_unique candidates "haskell"
    fi

    if evop_directory_has_file_named "$target_dir" "Project.toml" "Manifest.toml" \
        || evop_directory_has_file_extension "$target_dir" "jl"; then
        evop_profile_candidate_append_unique candidates "julia"
    fi

    if evop_directory_has_file_named "$target_dir" "build.zig" \
        || evop_directory_has_file_extension "$target_dir" "zig"; then
        evop_profile_candidate_append_unique candidates "zig"
    fi

    if evop_directory_has_file_extension "$target_dir" "sh" \
        || evop_directory_has_file_named "$target_dir" ".zshrc" ".zprofile" ".bashrc" ".bash_profile"; then
        evop_profile_candidate_append_unique candidates "shell"
    fi

    evop_profile_candidate_add_if_prompt_matches candidates "typescript" "$prompt" "typescript"
    evop_profile_candidate_add_if_prompt_matches candidates "javascript" "$prompt" "javascript" "node.js" "nodejs"
    evop_profile_candidate_add_if_prompt_matches candidates "python" "$prompt" "python"
    evop_profile_candidate_add_if_prompt_matches candidates "rust" "$prompt" "rust"
    evop_profile_candidate_add_if_prompt_matches candidates "scala" "$prompt" "scala" "sbt"
    evop_profile_candidate_add_if_prompt_matches candidates "go" "$prompt" "golang" " go "
    evop_profile_candidate_add_if_prompt_matches candidates "ruby" "$prompt" "ruby"
    evop_profile_candidate_add_if_prompt_matches candidates "php" "$prompt" "php"
    evop_profile_candidate_add_if_prompt_matches candidates "java" "$prompt" "java"
    evop_profile_candidate_add_if_prompt_matches candidates "kotlin" "$prompt" "kotlin"
    evop_profile_candidate_add_if_prompt_matches candidates "csharp" "$prompt" "c#" "dotnet"
    evop_profile_candidate_add_if_prompt_matches candidates "c" "$prompt" "language c" "ansi c" "embedded c"
    evop_profile_candidate_add_if_prompt_matches candidates "cpp" "$prompt" "c++" "cpp"
    evop_profile_candidate_add_if_prompt_matches candidates "swift" "$prompt" "swift"
    evop_profile_candidate_add_if_prompt_matches candidates "dart" "$prompt" "dart" "flutter"
    evop_profile_candidate_add_if_prompt_matches candidates "lua" "$prompt" "lua" "luajit"
    evop_profile_candidate_add_if_prompt_matches candidates "gdscript" "$prompt" "gdscript"
    evop_profile_candidate_add_if_prompt_matches candidates "elixir" "$prompt" "elixir" "phoenix" "mix"
    evop_profile_candidate_add_if_prompt_matches candidates "clojure" "$prompt" "clojure" "clojurescript" "leiningen"
    evop_profile_candidate_add_if_prompt_matches candidates "haskell" "$prompt" "haskell" "cabal" "stack"
    evop_profile_candidate_add_if_prompt_matches candidates "julia" "$prompt" "julia"
    evop_profile_candidate_add_if_prompt_matches candidates "zig" "$prompt" "zig"
    evop_profile_candidate_add_if_prompt_matches candidates "shell" "$prompt" "zsh" "bash" "shell" "shell script" "脚本"

    if [[ -n "$candidates" ]]; then
        EVOP_PROFILE_CANDIDATE_MODE="filtered"
        EVOP_PROFILE_CANDIDATE_LIST="$candidates"
    elif [[ -n "$prompt" ]]; then
        EVOP_PROFILE_CANDIDATE_MODE="all"
    else
        EVOP_PROFILE_CANDIDATE_MODE="none"
    fi
}
