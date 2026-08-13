#!/usr/bin/env bash
# Claude runtime stages (CB-154) — not implemented.
#
# The runner contract is in tests/runtime/README.md and the worked
# example is tests/runtime/codex/stages.sh. This file exists so a run
# against this host produces honest evidence instead of a missing-file
# error: every stage reports UNMEASURED with the reason, which is what is
# true.
#
# Codex is implemented first on purpose. Its packaging contract is the
# one already measured (CB-151) and its failure mode is known, so the
# pattern is proven somewhere real before three more hosts inherit it.
#
# UNMEASURED rather than BLOCKED: nothing outside this repository is
# stopping these stages. The driver is simply not written, and saying
# BLOCKED would put the reason somewhere it does not belong.
set -uo pipefail
STAGE="${1:?stage required}"
printf 'CB_STATUS=UNMEASURED\n'
printf 'CB_REASON=no stage driver for claude yet; stage %s not attempted (CB-154)\n' "$STAGE"
