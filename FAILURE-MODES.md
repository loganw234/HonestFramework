# Failure modes

Every entry here happened. They are not hypotheticals, and they are not
hallucinations — that is the point. In almost every case the agent ran a real
check, read a real result, and reported it accurately. The report was still
worthless, because the check was one step away from the claim.

They are grouped by **what the step away was**, because that is what predicts
the defence. A catalogue organised by symptom would be longer and useless:
the symptoms all look like success.

## The shape of it

> **An agent reports something true about a thing adjacent to the thing that
> mattered, and nothing in the report distinguishes the two.**

Asking for more care does not help. At the moment of reporting there is
nothing to be careful *about* — the check passed. The defence is always
structural: make the adjacent thing impossible to mistake for the real one,
or make the real one the only reachable thing.

---

## Quick reference

| # | Reported | Actually true | Mechanism that catches it |
|---|---|---|---|
| 1 | "library builds clean, `rc=0`" | build was piped to `/dev/null`; it printed the warning naming the bug | never redirect unread; assert on log content (§5) |
| 2 | "all contract checks passed" | a **stale** binary; `make all` does not build the test target | name and hash the artifact tested; put tests in the default target (§5, §6) |
| 3 | "pushed to main" | `git push -q` then an echo of **local** `HEAD` | ask the remote: `git ls-remote` (§5) |
| 4 | "working tree clean" | `--porcelain` shows files, never the branch — ten commits had landed on the wrong one | `git status -sb` when the branch matters (§5) |
| 5 | "suite green, 21 benches" | the framework cannot set an exit code; three real defects passed | read the results file; negative-control the reader (§3) |
| 6 | "built everything with `all`" | the tool was appended to `$(TOOLS)` *below* the `all` rule, so it was never built | assert the target list, not the variable (§3, §5) |
| 7 | "two warnings in the XRT build" | a **stale clone**, four commits behind; both were already fixed | assert the pointer **and** the content (§6) |
| 8 | "light suite: 1,000 steps per family" | the banner printed the *declared* count; the light path scaled it to 10 | print what executed, never what was configured (§5) |
| 9 | "bitstreams built and staged" | built at the script's default 10 MHz, not the intended 135 — five hours | refuse the dangerous default; read the flag back from the tool's log (§6) |
| 10 | "hardware emulation is broken on both hosts" | the agent's own rebuild had omitted the backend flag | print the linkage of the binary under test before believing its verdict (§6) |
| 11 | "`--list` shows what the quick run covers" | it listed every stage in the file; the budget was never applied | derive the list from the same predicate the runner uses (§4) |
| 12 | "worst path is +7.28 ns, ample margin" | that was the *first* path in the report — a shell clock; the design's own was +0.21 | name the thing you are reading; check against a known value (§1) |
| 13 | "the orphan directory is clean" | it had no `.git`; the command answered about the **parent** repo | verify the subject of the check, not just its output (§5) |
| 14 | "that warning is not a real defect" | checked only the format specifier, not the buffer it wrote into | reproduce the failure before dismissing it (§3) |
| 15 | "the docs are all updated" | four files still stale, including the one that calls itself the map | make the cross-reference a gate, not a habit (§4) |
| 16 | "timing reports are a few hundred KB" | 31 MB each — the estimate was ~1000× low | measure before you quote; never estimate into a decision (§7) |
| 17 | "those ten docs are demo essays" | six were tool manuals; the classification was filename-pattern guessing | open the file before classifying it (§7) |

---

## A. Stale inputs

**The most common family, and the least visible.** The check ran correctly
against the wrong version of the thing.

### A1 — The stale binary

`make all` built `libcft.a`; the failing test loaded the *shared* library,
which had not been rebuilt. Twenty minutes went into a defect that did not
exist in the sources.

A second instance, same day, different mechanism: `api-test` is in `$(TESTS)`
and `all:` expands `libcft.a $(SHLIB) $(TOOLS) $(EXAMPLES)`. So `make all`
has never built it, and running `./api-test` after `make all` tests whatever
was there before.

A third: a tool appended to `$(TOOLS)` *below* the `all:` rule. Make expands a
rule's prerequisites when it **reads** the rule, so the later append never
reached `all`. The tool was in the variable and absent from the build — and it
had no clean rule either, so a stale copy could outlive a `clean`.

**Defence.** Before trusting a binary: name the target that builds it and
confirm that target is reachable from what you ran. Print the artifact's path
and hash beside the result. Where a build system can answer "what are this
rule's prerequisites", ask it (`make -p`) rather than reading the variable.

### A2 — The stale clone

A remote host reported the expected commit from `git rev-parse` while its
working tree had never updated. Both build hosts produced stale bundles in one
day. Later, a compile check on a clone four commits behind reported two
warnings for code already fixed — they came within one step of being written up
as live findings.

**Defence.** Assert the pointer **and** the content. Check the SHA, *and* grep
the sources for a string only the intended commit contains. Two lines, and
they catch a class that `rev-parse` cannot see.

### A3 — The stale cached pass

A cache keyed on source files skips a leg when it missed a dependency — a
header, a flag, a data file. The failure mode is *skipping a leg that would
have failed*: a silent wrong answer.

**Defence.** Key the cache on the **artifacts the leg executes**, not on the
sources: a binary is the closed-over result of every source and flag that
produced it. Put the backend or device identity in the key so a pass on the
software path can never satisfy a hardware run. Retire the stamp on failure.
And never let the authoritative full run consult the cache at all.

---

## B. Unread output

The information that contradicted the conclusion was produced, and nothing
read it.

### B1 — The redirect

`make ... > /dev/null 2>&1; echo $?` reported a clean build. The compiler had
printed `warning: excess elements in array initializer`, which named the bug
exactly.

**Defence.** For every `>` and `2>&1` in a script, name the thing that reads
the file. If nothing does, that is a gate with its eyes shut. Tee and grep
instead.

### B2 — The results file nobody opens

The headline case. A twenty-one-bench hardware suite where the framework
**cannot** set an exit code — it says so in its own makefile — and the only
check was that the results file *existed*. A bench that ran, compared against
the reference model, found a mismatch and recorded it in XML produced the
file, so the check passed, so the suite returned 0. Three real defects were
reported as passes.

**Defence.** Something must read the file, and something must prove the reader
can say no. Both halves: the reader, and the negative control on the reader.

### B3 — The exit code of the wrong process

`cmd | head -n 2; echo "rc=$?"` reports `head`'s status. Benign here, but the
same pattern in a gate makes every failure invisible.

**Defence.** `set -o pipefail`, or capture `${PIPESTATUS[0]}`, and never put a
pipe between the thing under test and the status you report.

---

## C. The neighbouring subject

The check was well-formed and ran against something *next to* the subject.

### C1 — Local ref as evidence about a remote

`git push -q` followed by `git rev-parse --short HEAD`. The echo prints the
local head, which is true whether or not anything moved. Reported twice in one
day — and the work was on a feature branch, so `push origin main` was the
honest command.

**Defence.** `git ls-remote origin <branch>` after any push. Never echo a local
ref as remote evidence.

### C2 — The tool that walked up to the parent

`git -C <dir> status --porcelain` on a directory that had **no** `.git`
resolved to the parent repository and reported *that* as clean. The conclusion
"safe to delete 206 MB" rested on a check about a different directory.

**Defence.** Confirm the subject: `git -C <dir> rev-parse --show-toplevel` and
compare it to the directory you meant. Generally — when a tool has a search
path, make it print what it found.

### C3 — Declared configuration instead of executed work

A `--light` suite's banners printed the step counts from the configuration
table while the light path scaled them down by 100×. The log read "1,000
steps"; ten had run. Found by reading the log, never by the exit code.

**Defence.** Print what **ran**, computed from the same value the loop used.
Where a suite has a scaled mode, have it report the scaling and the effective
count on every line.

---

## D. Silent selection

Zero work, reported as zero failures.

### D1 — The filter that selected nothing

A typo'd `--only` selected no stages, printed "PASS, nothing skipped", and
crashed the summary on an unbound variable — after exiting 0.

**Defence.** Validate every name against the derived list and **refuse**
unknown ones. A runner must not accept a filter it cannot satisfy.

### D2 — The silently skipped stage

A stage whose tools were absent simply did not run.

**Defence.** Skip **by name, with the reason**, always printed; plus a
`--require-all` flag that converts every skip into a failure, for hosts that
claim to be complete. And print the selection: a `--list` must mark what *this
invocation* would run, not what exists — which was itself a defect, entry 11.

---

## E. Approximation creep

The agent, asked for a feature the platform cannot provide, built something
that returns.

### E1 — The ignored reserved field

Nothing validated the reserved bits of a control word. A device predating a
new flag therefore **ignored** it and read a thousand elements from a
one-element buffer. Measured as a segfault in a negative control — not argued.

**Defence.** Reserved means *checked*, not *ignored*: any non-zero reserved bit
is refused at entry. Write that guard before the first build ships, because it
cannot retrofit the ones already out.

### E2 — The advisory capability bit

A build advertising a feature while the path that performs it reads a
different constant.

**Defence.** Generate the advertisement from the same constant the refusal
reads, so a build cannot claim what it would turn away.

### E3 — The plausible fallback

Any branch that approximates when the exact path is unavailable. It returns,
the caller proceeds, and the divergence surfaces far from its cause.

**Defence.** Two outcomes only: the right answer, or a refusal that names what
is missing (METHOD §2).

---

## F. Drifted duplicates

### F1 — The list kept in three places

A runner's stage names lived in a `--list` heredoc, a validation list, and the
`stage` calls. Two copies drifted: two stages reached the run without reaching
`--list`, and one line claimed 15 sub-targets after the count grew to 17.

### F2 — One number, ten lists, four languages

A single new opcode assignment touched ten hand-written lists across four
languages. Not one was findable by reading the change; every one surfaced as a
run-time refusal. That is the design working — and ten chances to ship half an
assignment.

**Defence.** One fact, one place; generate or derive the rest; `--check` fails
the build on drift (METHOD §4). Where generation is too heavy, derive the
second list from the first with the exceptions named explicitly.

---

## G. The wrong configuration, run perfectly

### G1 — The dangerous default

A build script defaulted to a 10 MHz clock, a value from first bring-up. A run
on that default meets timing trivially and belongs to no lineage. **Five
hours**, twice over, before the tell was recognised: an absurd slack figure
nobody had looked at.

**Defence.** Refuse the dangerous default rather than documenting it: the
wrapper now rejects any clock below a floor unless the floor is overridden
deliberately. And read the applied value **back from the tool's own log**,
never from the variable you set.

### G2 — Blaming the environment for your own flag

"Hardware emulation is broken on both hosts" — the agent's own rebuild had
omitted the backend flag, so every image failed identically, including ones
that had worked the day before. A broken binary reads exactly like a broken
environment.

**Defence.** Before believing any device verdict, print the linkage of the
binary under test (`ldd ... | grep <backend>`). When *everything* fails at
once, including things that worked, suspect the thing common to all of them —
which is usually the most recent local change.

---

## H. Misread evidence

The subtlest family: the data was correct, complete, and read wrongly.

### H1 — The first entry instead of the relevant one

A timing report lists paths grouped by clock. The first group was a shell
clock with +7.28 ns of slack; the design's own clock had +0.21. The first
reading produced "ample margin" about the wrong clock — and the *second*
occurrence baked the same mistake into an archive built to answer exactly that
question, where the next reader would have had no reason to doubt it.

**Defence.** Name the subject in the query and in the output: the extractor
now finds the clock by name from the manifest and prints which clock it read.
Cross-check one value against a figure obtained another way.

### H2 — Bit-identity mistaken for validity

Two backends agreeing proves they agree. It does not prove the computation was
the one you meant — in one instance, identical results across backends while
the workload had silently been reduced to nothing.

**Defence.** Print an independent counter beside the headline — a domain
counter next to a timing figure — so an identical result cannot be mistaken
for a meaningful one.

### H3 — Dismissing a warning by checking the wrong half

A truncation warning was dismissed because the format specifier was correct
for the type. It was; the defect was the **buffer size**, a different claim.
The item had been on a list for days as a result.

**Defence.** Reproduce the failure before dismissing it. If you cannot
reproduce it, say that — not that it does not exist.

### H4 — Estimating into a decision

"The timing reports are a few hundred KB, so extracting them is free" — they
were 31 MB each, three orders out. And "those ten documents are demo essays"
— six were tool manuals, classified by filename without being opened.

**Defence.** Any number that changes a decision gets measured first. Any
classification gets the file opened. Estimates are fine in prose and never in
a plan.

---

## I. The gap between gates

The family that survives everything else in this document, because every
individual check is real.

### I1 — The seam that belonged to nobody

A bit-identity defect that **five parcels, two verifiers, a follow-up parcel
and 211 assertions all passed over.** It lived in a *combination* that two
parcels' gates each excluded by construction: one parcel's file pinned the
setting, the other's registered no force, and neither brief mentioned the
other. Every gate was honest. Every gate was also, in that combination, not
looking.

A hundred-line seam test — written by the lead, because it belonged to no
parcel — found it in seconds: 21 of 21 values differing at about 1e-4, a
trajectory divergence rather than a last bit. The fix was three lines.

**Defence.** Whenever work is split — across agents, across modules, across
teams — the seam is a deliverable, and it is nobody's by default. Write the
test that exercises the *combination* and assign it to whoever owns the split
rather than to either side of it. And treat the symmetry as a smell: if two
pieces each have a gate and nothing has a gate over both, that is the gap.

This is the one failure mode that scales *with* how well the work was divided.
Clean boundaries make it more likely, not less, because a clean boundary is
precisely an agreement about what each side will not look at.
([ParcelRound](https://github.com/loganw234/ParcelRound) traces this one end
to end; [WITH-PARCELROUND.md](WITH-PARCELROUND.md) is how the two methods fit.)

---

## The meta-failure

**Reporting a safeguard as present because it was intended.** Twice in one
day: documentation describing registers that did not exist, and a claim that
all cross-references had been updated when four were stale — including the
file that calls itself the map of everything that checks the project.

This is the failure the whole framework exists to make impossible, and it has
only one defence: *the safeguard is the thing that runs, not the thing that is
written down.* If a rule is not executable, it is a hope. Make it a gate, give
the gate a negative control, and put the negative control in the suite.

---

## How to use this list

Go through it once against your own project and mark each entry **caught
mechanically**, **caught by habit**, or **not caught**. Habits are not
defences — they are the same judgement the framework exists to remove, just
yours instead of the model's. Every "caught by habit" is a gate waiting to be
written, and every "not caught" is a report you will one day believe.
