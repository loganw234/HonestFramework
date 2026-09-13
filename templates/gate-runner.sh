#!/bin/bash
# A gate runner with the properties METHOD.md argues for. Copy it, replace
# the stage block at the bottom, delete this paragraph.
#
# It is deliberately one file of plain bash with no dependencies, because a
# runner that needs installing is a runner someone will route around.
#
# WHAT IT GIVES YOU, and which section of METHOD.md each comes from:
#
#   §3  a negative-control stage that must FAIL, and aborts the run if it
#       passes - so the runner proves it can say no, every time it runs.
#   §4  the stage list is DERIVED by grepping this file's own `stage` calls.
#       There is no second list to drift. Adding a stage is one edit, and
#       --list plus name validation pick it up for free.
#   §5  every skip prints itself BY NAME with a reason; --require-all turns
#       skips into failures; an unknown stage name is REFUSED rather than
#       silently selecting nothing.
#   §5  --list marks what THIS invocation would run, using the same
#       predicate the runner uses, so the list cannot overstate a budget.
#   §6  a run id of timestamp + commit; per-stage .ok markers; --resume
#       reruns only what has not passed and REFUSES to cross commits.
#   §7  an append-only JSONL record of every stage verdict, with the date.
#
# USAGE
#   ./gate-runner.sh                     every stage
#   ./gate-runner.sh --budget quick      a named cut
#   ./gate-runner.sh --only build,unit   by name (refuses unknown names)
#   ./gate-runner.sh --skip slow
#   ./gate-runner.sh --require-all       a skipped stage FAILS the run
#   ./gate-runner.sh --list              stages, with * on what would run
#   ./gate-runner.sh --resume            continue the most recent run
#   ./gate-runner.sh --fresh             force a new run id
#
# THERE IS NO CACHE ACROSS RUNS, on purpose. --resume skips what already
# passed IN THIS RUN ID. If you add a content-addressed cache later, key it
# on the ARTIFACTS a stage executes rather than on source files - the failure
# mode of a missed source dependency is skipping a stage that would have
# failed, which is the one outcome this file exists to prevent - and never
# let the full run consult it.
set -uo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
STATEROOT="${STATEROOT:-$ROOT/.gate-state}"

ONLY=""; SKIP=""; REQUIRE_ALL=0; LIST=0; RESUME=""; FRESH=0; BUDGET=""

# Named cuts. Keep them as comma lists of stage names; the validation below
# checks them against the derived list, so a typo here fails loudly at start
# rather than quietly selecting nothing.
BUDGET_QUICK=lint,unit,controls
BUDGET_FULL=""          # empty means every stage

die () { echo "FATAL: $*" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --only)        [ $# -ge 2 ] || die "--only needs a list"; ONLY="$ONLY,$2"; shift 2;;
    --skip)        [ $# -ge 2 ] || die "--skip needs a list"; SKIP="$SKIP,$2"; shift 2;;
    --budget)      [ $# -ge 2 ] || die "--budget needs quick or full"
                   case "$2" in
                     quick) BUDGET=quick; ONLY="$ONLY,$BUDGET_QUICK";;
                     full)  BUDGET=full;;
                     *) die "--budget: unknown budget '$2' (quick, full)";;
                   esac; shift 2;;
    --require-all) REQUIRE_ALL=1; shift;;
    --list)        LIST=1; shift;;
    --resume)      if [ $# -gt 1 ] && [[ ${2:-} != --* ]]; then RESUME=$2; shift 2
                   else RESUME=last; shift; fi;;
    --fresh)       FRESH=1; shift;;
    -h|--help)     sed -n '2,40p' "$0"; exit 0;;
    *)             die "unknown option $1";;
  esac
done

# Defined here, above --list, because --list exits before the other helpers
# and must answer "would this stage run?" with the SAME predicate stage()
# uses. Two copies of that rule is how a stage list starts lying.
in_list() {  # name, comma-list
  case ",$2," in *",$1,"*) return 0;; esac
  return 1
}

# §4: the only copy of the stage list is the `stage` calls themselves.
SELF="${BASH_SOURCE[0]}"
STAGELIST=$(grep -E '^stage [a-z0-9-]+ "' "$SELF" | awk '{print $2}' | tr '\n' ' ')
STAGELIST="${STAGELIST% }"

if [ "$LIST" = 1 ]; then
  while IFS=$'\t' read -r _nm _ds; do
    if [ -z "$ONLY" ] || in_list "$_nm" "$ONLY"; then _mk="*"; else _mk=" "; fi
    printf '%s %-14s%s\n' "$_mk" "$_nm" "$_ds"
  done < <(grep -E '^stage [a-z0-9-]+ "' "$SELF" \
      | sed -E 's/^stage ([a-z0-9-]+) +"([^"]*)".*/\1\t\2/')
  echo
  if [ -n "$ONLY" ]; then
    printf '* = would run%s. Unmarked stages are NOT in this selection.\n' \
        "${BUDGET:+ under --budget $BUDGET}"
  else
    echo "* = would run: every stage (no --only, no --budget)."
  fi
  exit 0
fi

# §5: refuse a name we do not know. A typo'd filter that selects nothing and
# reports "passed, nothing skipped" is the worst outcome available.
check_names() {  # <flagname> <comma-list>
  local n
  for n in $(echo "$2" | tr ',' ' '); do
    [ -z "$n" ] && continue
    case " $STAGELIST " in
      *" $n "*) ;;
      *) echo "ERROR: $1 names unknown stage '$n'" >&2
         echo "       stages: $STAGELIST" >&2
         exit 2;;
    esac
  done
}
check_names --only "$ONLY"
check_names --skip "$SKIP"

# §6: run identity. Timestamp plus commit, and a resume may not cross commits.
COMMIT=$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo nogit)
if [ -n "$RESUME" ] && [ "$FRESH" = 1 ]; then
  die "--resume and --fresh are contradictory"
fi
if [ -n "$RESUME" ]; then
  if [ "$RESUME" = last ]; then
    RUNID=$(ls -1 "$STATEROOT" 2>/dev/null | sort | tail -n 1)
    [ -n "$RUNID" ] || die "--resume: no previous run under $STATEROOT"
  else
    RUNID=$RESUME
  fi
  case "$RUNID" in
    *-"$COMMIT") ;;
    *) die "run $RUNID was a different commit than $COMMIT; half a run of one
  tree glued to half a run of another is a report about neither. Use --fresh.";;
  esac
else
  RUNID="$(date +%Y%m%d-%H%M%S)-$COMMIT"
fi
RUNDIR="$STATEROOT/$RUNID"
mkdir -p "$RUNDIR"
JSONL="$RUNDIR/stages.jsonl"

PASSED=0; FAILED=0; SKIPPED=0; CACHED=0
note () { echo "   $*"; }

echo "== run $RUNID"
echo "   commit $COMMIT, state in $RUNDIR"
[ -n "$BUDGET" ] && echo "   budget $BUDGET"

# stage <name> <description> -- command...
#
# MUST_FAIL=1 before a stage inverts its verdict: the command is expected to
# fail, and its SUCCESS is the failure. That is how the negative control at
# the bottom proves this runner can say no.
stage() {
  local name=$1 desc=$2; shift 3
  local t0 t1 rc verdict reason="" expect_fail="${MUST_FAIL:-0}"
  MUST_FAIL=0

  if [ -n "$ONLY" ] && ! in_list "$name" "$ONLY"; then
    return 0                         # not selected: not reported either
  fi
  if [ -f "$RUNDIR/$name.ok" ]; then
    CACHED=$((CACHED+1))
    note "$(printf '%-14s %-7s %s' "$name" "ok" "(passed earlier in this run)")"
    echo "{\"stage\":\"$name\",\"verdict\":\"ok-cached\"}" >> "$JSONL"
    return 0
  fi
  # §5: a skip is announced by name, with a reason, always.
  if in_list "$name" "$SKIP"; then
    verdict=SKIP; reason="requested"
  elif [ -n "${STAGE_SKIP_REASON:-}" ]; then
    verdict=SKIP; reason=$STAGE_SKIP_REASON
  fi
  if [ "${verdict:-}" = SKIP ]; then
    SKIPPED=$((SKIPPED+1))
    note "$(printf '%-14s %-7s %s' "$name" "SKIP" "$reason")"
    echo "{\"stage\":\"$name\",\"verdict\":\"skip\",\"reason\":\"$reason\"}" >> "$JSONL"
    [ "$REQUIRE_ALL" = 1 ] && FAILED=$((FAILED+1))
    STAGE_SKIP_REASON=""
    return 0
  fi

  t0=$(date +%s)
  "$@" > "$RUNDIR/$name.log" 2>&1
  rc=$?
  t1=$(date +%s)

  if [ "$expect_fail" = 1 ]; then
    if [ "$rc" -eq 0 ]; then
      FAILED=$((FAILED+1))
      note "$(printf '%-14s %-7s %s' "$name" "FAIL" \
          "NEGATIVE CONTROL DID NOT FAIL - this runner cannot detect a defect")"
      echo "{\"stage\":\"$name\",\"verdict\":\"control-passed\"}" >> "$JSONL"
      return 1
    fi
    rc=0
    note "$(printf '%-14s %-7s %s' "$name" "ok" "(negative control failed, as it must)")"
  fi

  if [ "$rc" -eq 0 ]; then
    : > "$RUNDIR/$name.ok"
    PASSED=$((PASSED+1))
    [ "$expect_fail" = 1 ] || \
      note "$(printf '%-14s %-7s %ss  %s' "$name" "ok" "$((t1-t0))" "$desc")"
    echo "{\"stage\":\"$name\",\"verdict\":\"ok\",\"seconds\":$((t1-t0))}" >> "$JSONL"
  else
    : > "$RUNDIR/$name.fail"
    FAILED=$((FAILED+1))
    note "$(printf '%-14s %-7s rc=%s  see %s' "$name" "FAIL" "$rc" "$RUNDIR/$name.log")"
    echo "{\"stage\":\"$name\",\"verdict\":\"fail\",\"rc\":$rc}" >> "$JSONL"
  fi
}

# Set STAGE_SKIP_REASON before a stage when its tools are absent, so the skip
# says WHY. Never let a missing tool look like a pass.
need () {  # <command> <reason if missing>
  command -v "$1" >/dev/null 2>&1 || STAGE_SKIP_REASON="$2"
}

# ======================================================================
# THE STAGES. Replace these. Keep the shape: one `stage` line each, the
# description in double quotes on the same line so the derivation finds it.
# ======================================================================

need shellcheck "shellcheck not installed"
stage lint "every shell script through shellcheck" -- \
  shellcheck "$ROOT/gate-runner.sh"

stage unit "the unit suite, asserting on output and not only on status" -- \
  bash -c 'echo "ran 3 checks, 0 failures"; exit 0'

# §3: the control. It must FAIL. If it passes, the harness cannot detect a
# defect and everything above it is worthless - so the run says so loudly.
# Point this at a deliberately broken copy of a real check, not at `false`:
# a control that cannot possibly pass tests nothing about your detector.
MUST_FAIL=1
stage controls "a deliberately broken check MUST be detected" -- \
  bash -c 'echo "sabotaged input: expecting a mismatch"; exit 1'

# ======================================================================

echo "== summary"
echo "   passed $PASSED, failed $FAILED, skipped $SKIPPED, cached $CACHED"
echo "   record $JSONL"
if [ "$FAILED" -ne 0 ]; then
  echo "== FAILED"
  exit 1
fi
if [ "$SKIPPED" -ne 0 ] && [ "$REQUIRE_ALL" != 1 ]; then
  echo "== PASSED, with $SKIPPED skipped by name above"
  echo "   (--require-all makes a skip a failure)"
  exit 0
fi
echo "== PASSED"
exit 0
