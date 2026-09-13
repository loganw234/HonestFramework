# Adopting this on a project that already exists

The method is cheap to start and expensive to retrofit in the wrong order.
This is the order that pays as it goes, with the audit that comes first.

Nothing here requires rewriting anything. Every step is additive, and each one
is useful on its own if you stop there.

---

## Step 0 — The audit, before any building

Two hours, no code. You are establishing **which of your current green
signals mean anything**, because everything after this builds on them.

### 0a. Find the gates that cannot fail

For each gate — every test target, linter, checker and CI job — answer one
question in writing: *when did I last see this go red?*

Then make each one fail on purpose. Break the thing it guards, run it, confirm
red, put it back. Any gate you cannot make fail goes on a list titled
**unverified**, in the repository, where the next person will see it.

Expect this to find things. One project found seven in a day. The usual
culprits:

- a framework that cannot set an exit code (check: does your runner's `0`
  survive a deliberately failing test?);
- a results file nothing reads;
- a filter or tag selecting zero cases — zero failures of zero cases is a pass;
- a test binary the default target does not build;
- output redirected to `/dev/null`, or to a file nothing opens;
- a pipeline whose reported status belongs to the last command, not the test.

### 0b. Grep your own scripts for the four patterns

Mechanical, fast, high yield:

```bash
grep -rn '> */dev/null' .            # output nobody will read
grep -rn 'rev-parse HEAD' .          # local ref quoted as remote evidence
grep -rn -- '--porcelain' .          # shows files, never the branch
grep -rn '| *head\|| *tail' .        # $? belongs to head, not the test
```

For each hit, name the thing that reads the output, or fix it.

### 0c. Walk [FAILURE-MODES.md](FAILURE-MODES.md) once

Mark each entry **caught mechanically**, **caught by habit**, or **not
caught**. Habits are not defences — they are the same judgement the framework
removes, just yours instead of the model's. The "by habit" column is your
backlog, in priority order, for free.

**Stop here if you stop anywhere.** A project that knows which of its gates
are real is already in a much better position than one with more gates.

---

## Step 1 — Name the authority (half a day)

Write down, in the README, the answer to *"when two parts of this disagree,
which one is right?"*

If you already have a reference implementation, a published vector set or an
external dataset, this is a paragraph. If you do not, you have found the
largest piece of work in the method, and you should decide deliberately
whether the project needs it:

- **It does** if wrong answers are expensive and silent — numerics, protocol
  encoders, anything whose output feeds another system unexamined.
- **It probably does not** if correctness is already defined by an external
  spec with a conformance suite you can run, in which case *that* is your
  authority; say so and wire it in.
- **It does not** if the work is exploratory, or if "approximately right" is
  genuinely acceptable. Take Step 0 and stop.

Then add the rule that makes it load-bearing: **the authority must not import
from the things it judges.** One grep, in the gate.

---

## Step 2 — Negative-control the gates you kept (a day)

For every gate that survived Step 0a, add the break you performed as a
**permanent** case: it must fail, and its passing fails the build.

Three rules, each learned the hard way:

1. **Choose a sabotage that cannot hide.** Pick inputs where the corruption
   must show. A control in a region where a flipped bit lands in a
   "don't-care" class proves nothing.
2. **Give controls their own output path.** A control writing beside the real
   results will poison aggregates — *a negative control that fails the run it
   just validated* is a real thing that happened.
3. **Assert on content, not status.** Grep the log for the line only success
   prints, and for the count.

---

## Step 3 — Make skips and selections loud (half a day)

Your runner must, by the end of this:

- print every skipped stage **by name with a reason**;
- support a flag that turns every skip into a failure;
- **refuse** an unknown stage name rather than silently selecting nothing;
- print, for a given invocation, **which stages it would actually run** — not
  which exist. That distinction was itself a defect in one project: a `--list`
  beside a budget flag printed the whole file and read as though the budget
  covered all of it.

Derive that list from the same predicate the runner uses to decide. Two copies
of a selection rule is §4's problem with worse consequences.

---

## Step 4 — One front door (an hour, highest ratio in the document)

One command, in two or three sizes, that runs the gates and prints a verdict.
Name it in the README's first screen, in your agent-facing notes, and in
`make help`. State its real cost in minutes, and **state whether repeated runs
are cheap** — if there is no cache, say so.

Do not skip this because the runner already exists. In the case study it
*did* exist, with three well-judged budgets, reachable from the runner's own
header comment and nowhere else — and an entire working session ran the
individual targets by hand instead, including the part of the session spent
writing the agent-facing notes. Structure nothing points at is
indistinguishable from structure that is absent.

---

## Step 5 — Single-source the lists that have already bitten you (ongoing)

Do not attempt this repository-wide. Do it when a list drifts, and do it to
that list.

The pattern: pick the definition, generate the copies, add a `--check` mode
that fails the build on drift, and make that check a prerequisite of something
people already run. Where generation is too heavy, derive the second list from
the first and name the exceptions explicitly.

You will know which list is next: it is the one whose omission you last found
at run time.

---

## Step 6 — Provenance, when you start shipping artifacts (a day)

The moment a build output leaves the machine that made it:

- the build writes a manifest — commit, every flag **read back from the
  tool's own log**, results, and a hash;
- a separate checker re-derives that from the artifact alone;
- re-hash after any copy;
- the backend or device identity goes into any cache or stamp key, so a pass on
  one can never satisfy the other;
- before deleting intermediates, **extract what you will want later.** A
  question about which path limited a design was unanswerable in the case study
  because the tree had been cleaned; 13,415 MB of intermediates reduce to 9 MB
  worth keeping.

---

## Step 7 — The record (ongoing, start now)

Append-only, dated, one entry per run, with the command. Write failures in.
Never edit an entry to agree with a later belief; a figure is a fact about its
run.

Start it today even if it is thin, because its value is entirely in its age.

---

## Step 8 — Control the judges, if any output is a judgement (a day)

If the project asks an agent to assess rather than build — review code, verify
citations, audit dependencies, reconcile datasets — build the controls from
METHOD §9 before you trust a single one of those reports:

1. Write 5–8 items in the **identical format** as the real work.
2. Plant specific, subtle faults in some: a transplanted constant, a real
   source credited with the wrong claim, a section number that does not exist,
   a quote that is close but not present. Each must pass a plausibility read
   and fail a fetch.
3. **Withhold the key** from the tree until the pass returns.
4. Record the score, the date, and the model. Re-run when any of those change.

Until this exists, an agent's audit is an opinion with citations, and the
citations are the part you cannot check.

---

## What to do first if you only have an afternoon

Step 0a and Step 4. Find out which of your gates are real, and make the real
ones reachable by one command. Everything else can wait, and those two will
tell you whether the rest is worth it.
