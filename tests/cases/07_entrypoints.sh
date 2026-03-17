#!/usr/bin/env bash

for rel_path in \
    bin/EvoProgrammer \
    CLEAN.sh \
    DOCTOR.sh \
    INSPECT.sh \
    LOOP.sh \
    MAIN.sh \
    STATUS.sh \
    VERIFY.sh \
    install.sh
do
    shebang_line="$(sed -n '1p' "$ROOT_DIR/$rel_path")"
    assert_equals "$shebang_line" "#!/bin/sh" "Bootstrap entrypoint should use a POSIX shim: $rel_path"
done
pass "Bootstrap entrypoint shebangs"
