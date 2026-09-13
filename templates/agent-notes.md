# Template: the agent-facing notes

> Copy to `CLAUDE.md` (or `AGENTS.md`, or whatever your tool reads) in the
> repository root. Replace everything in angle brackets. **Delete the sections
> you have nothing true to put in** — an empty heading is worse than no
> heading, because it reads as "nothing bites here".

This is METHOD §10. Two jobs: point at the front door, and list what has
already cost hours. It is not a tutorial, not a style guide, and not a
description of the architecture — those belong in the README and the docs, and
an agent that needs them will read them.

**Length discipline:** if it grows past about 150 lines, something in it is
not earning its place. The file people actually read is the short one.

---

```markdown
# Working on <project>

Short, and only things that are non-obvious AND have already cost hours.
The README says what this project is; this says what will bite you.

## Start here: one command answers "does it still hold?"

    <make verify-quick>     # ~<N> min, <k> of <total> stages
    <make verify-gate>      # ~<N> h, <k> of <total> — what a change should pass
    <make verify>           # everything, hours
    <runner --list>         # every stage, with * on what a budget selects

<runner> is the runner and <docs/VERIFICATION.md> is the map of what each
stage proves. **Reach for this before hand-running targets.**

<Is there a cache? Say so either way. If repeated runs are NOT cheap, say
that in these words, or the next reader will assume warmth that is not
there: "A run id is <timestamp + commit> and each stage drops a marker, so
--resume reruns only what has not passed. A fresh invocation runs
everything again.">

A stage whose tools are missing is **skipped by name with a reason**, never
silently passed — so read the skip list, and use <--require-all> on a host
that claims to be complete.

## The authority

<python/reference_model> **is the authority.** <The library, the accelerator
and the hardware> must agree with it <bit for bit>, and anything that cannot
be done exactly is **refused by name** rather than approximated. A refusal
that says <GENERIC_ERROR> where it means <"this device predates the feature">
is a defect, not a detail.

## The machines, if there is more than one

<Delete unless two environments are genuinely confusable. If they are, a
table is the only thing that works — prose gets misread.>

| name | what it is | how to reach it | resources | <special hardware?> |
|---|---|---|---|---|
| <name> | <a WSL distro on this same desktop> | <wsl -d name> | <12 threads> | no |
| <name> | <a separate physical machine> | <ssh user@addr> | <36 threads> | **<yes — X at Y>** |

<One sentence naming the mistake this table prevents, and the date it last
happened. "X always means Y" is worth more than any amount of description.>

## <N> traps, <k> of which exit 0

<Numbered, shortest first. For each: the SYMPTOM AS IT APPEARS, then the
cause, then the fix. The symptom comes first because it is what the next
reader searches for.>

1. **<FLAG=value, always.>** <The script defaults to something from first
   bring-up. A run on the default is unusable AND LOOKS FINE. The tell is
   <an absurd value in field X>.>
2. **<The thing that is off by default.>** <It still compiles without it, so
   the build looks clean and fails at run time with <misleading message>,
   which reads as a broken environment rather than a broken binary. Check
   <concrete command> before believing any result.>
3. **<clean removes more than you think.>**
4. **<One heavy job at a time.>** <An OOM kill reads like a failure of the
   work rather than of the machine.>

## Gates, and which ones mean something

<This section is the one that rots fastest. A fixed gate still listed as
broken teaches people to distrust a check that works — the same damage as
trusting one that does not. Date every entry and delete it when it stops
being true.>

**<gate> now gates (fixed YYYY-MM-DD).** <What it does and what it cannot
catch.>

**<gate> cannot fail (known, unverified).** <What to read instead, and why.
If this entry exists, it is the top of the backlog.>

## Before believing a remote build

Assert the **SHA and the content separately**. A clone reporting the right
SHA whose working tree never updated is the failure `rev-parse` cannot see,
so also grep the sources for something only the new commit has.
<Both build hosts produced stale bundles in one day once.>

<Any cross-platform comparison traps: e.g. compare git tree hashes rather
than checksum output, because the two platforms' tools format output
differently and the digests differ on formatting alone.>

## The discipline that matters most here

<One paragraph. The single thing that, if forgotten, makes the work wrong
rather than late.>
```

---

## Notes on filling it in

**The symptom, not the cause, goes first.** "The default compiler here is
32-bit" is useless. "`undefined reference` to a function that is plainly
defined — and sometimes `internal compiler error: ... collect2` — means the
32-bit compiler is first on `PATH`" is the entry that saves the hour. Put the
exact string the reader will paste into a search.

**Date the entries that can expire.** Gate status, tool versions, machine
inventory. Anything with a date can be audited; anything without reads as
eternal.

**Audit it on a schedule.** Read it end to end and reproduce every claim. In
the case study, one of these files listed two gates as "known, unfixed" after
both had been repaired, and claimed a checker failed on a clean checkout when
it passed — all three found by reading the file against the code, not by
anyone hitting a problem.

**Do not put the architecture in it.** The temptation is strong, because
writing it feels productive. It belongs in the README and it makes this file
long enough that nobody finishes it.
