#!/usr/bin/env bash

# shellcheck disable=SC2153
# shellcheck source=tests/lib/test_runner.sh
source "$ROOT_DIR/tests/lib/test_runner.sh"

listed_cases="$(run_expect_success "run_tests --list should succeed" bash "$ROOT_DIR/tests/run_tests.sh" --list)"
assert_contains "$listed_cases" "tests/cases/05_smoke.sh" "run_tests --list should include smoke tests"
assert_contains "$listed_cases" "tests/cases/15_test_runner.sh" "run_tests --list should include test-runner coverage"
pass "Test runner list"

filtered_output="$(run_expect_success "run_tests filter should succeed" bash "$ROOT_DIR/tests/run_tests.sh" 05_smoke)"
assert_contains "$filtered_output" "PASS: LOOP help smoke" "run_tests filter should execute the requested case"
assert_not_contains "$filtered_output" "PASS: CLI help" "run_tests filter should avoid unrelated cases"
pass "Test runner filter"

extended_output="$(run_expect_success "run_extended_tests filter should succeed" bash "$ROOT_DIR/tests/run_extended_tests.sh" 05_smoke)"
assert_contains "$extended_output" "PASS: LOOP help smoke" "run_extended_tests should forward filters to run_tests"
assert_not_contains "$extended_output" "PASS: CLI help" "run_extended_tests should preserve targeted execution"
pass "Extended runner filter"

evop_collect_shellcheck_targets "$ROOT_DIR"
shellcheck_targets="$(printf '%s\n' "${EVOP_SHELLCHECK_TARGETS[@]}")"
assert_contains "$shellcheck_targets" "$ROOT_DIR/tests/run_tests.sh" "shellcheck target collection should include run_tests.sh"
assert_contains "$shellcheck_targets" "$ROOT_DIR/install.sh" "shellcheck target collection should include install.sh"
pass "Extended runner shellcheck targets"
