# The method

Ten mechanisms. Each one exists because a specific kind of true-but-worthless
report got through, and each is described the same way: **what goes wrong
without it**, **how to build it**, and **how you know it is working** —
because a safeguard nobody has tested is just another claim.

The ordering is deliberate:

- **1–3** are load-bearing. A project with only the authority, refusal, and
  watched-to-fail gates is already honest.
- **4–6** make honesty cheap enough to keep: one copy of each fact, logs read
  rather than exit codes, artifacts that identify themselves.
- **7–8** keep it true over months — a record that is never rewritten, and
  uncertainty that cannot be detached from the value it qualifies.
- **9** covers the case with no compiler: when the deliverable is a judgement
  rather than code. For AI-heavy work this is the one with no substitute.
- **10** is the surface the agent and your future self actually read.

Examples are drawn from projects built this way and are cited specifically,
because a method document full of invented illustrations would be the thing
it warns against. [CASE-STUDY.md](CASE-STUDY.md) lists the repositories and
what each contributes.

---

## 1. The authority: one thing that cannot argue

Name, once and in writing, **the artifact that defines correct**. Not a
person, not a convention, not "the tests" — a specific implementation whose
output is correct by definition, so that every disagreement has an answer
that requires no judgement.

In the case study it is a pure-Python reference model. It is slow, it has no
optimisations, and it is the authority precisely because of that: there is
nothing in it to be clever about. The accelerator, the C library, the
simulator, the WebAssembly build and the hardware are all **held against it
bit for bit**. When any of them disagrees with it, the authority is right.
That sentence is the whole mechanism.

### What goes wrong without it

Disagreements become negotiations. An agent — or a person — finds that two
implementations differ and must decide which is correct, and whatever it
decides *sounds* equally plausible in the report. Worse, the decision is
usually made in favour of the thing that is easier to change, which is
whichever one was written most recently.

With an authority, the agent is never asked. It reports "the C path differs
from the model at element 7" and the next step is forced.

### How to build it

- **Make it the slow, obvious implementation.** Optimisation is where
  disagreement comes from; the authority must have none.
- **Make it independent.** It must not share code with the thing it judges.
  A reference model that imports the library's own rounding helper tests
  nothing.
- **Publish its output as data.** Freeze vector sets — inputs, expected
  outputs, and expected side effects — as files with hashes. Then a gate is a
  replay, not a re-derivation, and the authority's verdict survives the
  authority being offline or rewritten.
- **Get a second, foreign oracle where you can.** The case study holds
  division and square root against the host CPU's own hardware (23.9 billion
  cases) and against GNU MPFR (999,000 cases). Two oracles that were never
  written by the same project agreeing is worth more than any amount of
  internal consistency.
- **Say what the authority does *not* cover.** Timing, resource use and
  anything statistical are outside it. Write that down, or someone will cite
  a bit-identity pass as evidence about performance.

### When the authority is outside the project

Sometimes the thing that defines correct is published literature or measured
physical data, not code you can run. The discipline is the same and one step
is easy to get wrong: **commit the source's own independently documented
figure alongside your value**, and compare against that.

`atlas-optical` does exactly this. Its lens registry was extracted from an
open compilation of historic prescriptions, and `data/dioptrique.json`
carries, per entry, the page it came from *and the focal length the site
documents independently* — committed, in the words of its own provenance
file, "so that the tracing test compares this repository's numbers against
the source's rather than against a copy of itself."

That clause is the whole trap. A test that re-traces your own extracted
numbers and finds them self-consistent has tested your arithmetic and
nothing about whether the extraction was right.

The result is a measurement rather than a claim: **1040 of 1043 entries
reproduce their documented focal length** (worst 0.05%, median 0.0003%), and
the three that do not "are recorded as refusals with reasons rather than
shipped" — §2 applied to data.

Two further rules fall out of it:

- **Name the sources and their terms in a file of their own.** Both
  `atlas-optical` and `atlas-film` carry a `PROVENANCE.md`, on the stated
  grounds that "a registry whose numbers cannot be traced to their sources is
  a compilation with better manners", and that "a process table whose
  constants cannot be traced to their sources is a look wearing a physics
  costume."
- **Hold your constants against literature deliberately, and record the
  contradictions.** `atlas-darkroom` runs an external-sources programme whose
  dossiers state their counts up front — one reports *24 claim–source entries:
  2 contradicted, 9 corroborated, 10 corroborated-with-caveats, 3 silent (no
  published figure found)* — and puts the **contradictions first**. The
  "silent" category matters as much as the others: absence of a published
  figure is recorded as a finding rather than quietly read as agreement.

### How you know it is working

Sabotage the fast path and confirm the authority catches it — see §3. And
check the dependency direction mechanically: the authority's module must not
import anything from the implementations. That is one grep, and it belongs in
the gate.

For an external authority, the equivalent check is the one above: confirm the
comparison is against a committed figure from the source, not against your own
re-derivation.

---

## 2. Refusal is the only alternative to correctness

Every operation has exactly two permitted outcomes: **the right answer**, or
**a refusal that names what is missing**. There is no third branch that
approximates, degrades, falls back, or does its best.

This is the rule that makes an agent's output safe to ship, because it
removes the category of decision an agent should never make: *is this close
enough?*

### What goes wrong without it

A fallback is a wrong answer with good manners. It returns, the caller
proceeds, and the divergence surfaces far away from its cause — if it ever
does. And an agent asked to implement a feature the platform cannot support
will, left to itself, write the approximation and describe it accurately in
the report, where it reads as success.

### How to build it

- **Refuse by name.** Not "unsupported". The refusal says which capability is
  absent and what would provide it. In the case study, a refusal that says
  `CFT_ERR_ARTIFACT` when it means *this device predates the feature* is
  itself logged as a defect, because the caller cannot act on it.
- **Make capability bits load-bearing, never advisory.** If a build advertises
  a feature, the code path that performs it must read the *same* constant the
  advertisement is generated from, so a build cannot claim something it would
  then turn away.
- **Make unknown inputs fail closed.** Reserved fields must be *checked*, not
  ignored. This is the one that bites hardest: in the case study, nothing
  validated the reserved bits of a control word, so an older device handed a
  newer flag **ignored it** and read a thousand elements from a one-element
  buffer. The fix was a guard that refuses any non-zero reserved bit. It
  cannot retrofit the devices already built — which is the argument for
  writing the guard before the first one ships.
- **Test the refusals as first-class cases.** Sweep the whole input space
  where you can: all 256 opcode values, every reserved bit, a null argument
  in each position. A refusal that is never exercised is a branch that has
  never run.

### How you know it is working

Count your refusal tests against your success tests. If refusals are under
10% of the contract suite, they are not being taken seriously. Then take one
capability bit, turn it off in a build, and confirm the calls that need it
are refused rather than attempted — the case study's equivalent of that test
*segfaults* when the bit is wrongly believed, which is exactly the
demonstration you want on file.

---

## 3. A gate you have not watched fail is not a gate

Write the gate. Then **break the thing it guards** and confirm the gate goes
red. Until you have seen that, you have a script whose green means nothing,
and you cannot tell the difference from the outside.

This is the single highest-yield rule in the document, and the one most often
skipped, because a new gate that passes feels like success.

### What goes wrong without it

You get gates that cannot fail. Not rarely — one project found **seven in a
single day**. The modes are mundane:

- the framework cannot set an exit code, so the runner's `0` means only that
  it ran (the suite in the README: twenty-one benches, three real defects
  reported as passes);
- the check writes its result to a file nothing reads;
- a typo'd filter selects zero cases, and zero failures out of zero cases is
  a pass;
- the test binary is stale because the build target that makes it is not in
  `all`;
- output was redirected, so the warning naming the bug was never seen.

Every one of these reports success in a way an agent cannot distinguish from
success, and neither can you.

### How to build it

- **Keep the break as a permanent negative control.** Not a one-off
  experiment — a case in the suite that *must fail*, and whose passing fails
  the build. The case study runs a deliberately sabotaged arithmetic job on
  every soak: if the sabotaged run is *not* detected, the harness aborts with
  `NEGATIVE CONTROL FAILED TO FAIL`.
- **Choose the sabotage so it cannot hide.** That same control picks an input
  range whose results are never NaN, specifically so a flipped bit cannot
  disappear into the NaN class. A negative control in a region where the
  corruption is invisible proves nothing.
- **Do not let the control eat the experiment.** The first version of that
  control wrote its log beside the real ones, and its 65,536 intentional
  mismatches poisoned the aggregate — *a negative control that fails the run
  it just validated*. Give controls their own output path.
- **Assert on content, not just on status.** `grep` the log for the line that
  proves the work happened, and for the count. An exit code says the process
  ended; it does not say what it did.
- **Gate the gate's own plumbing.** If a suite reports results in a file,
  something must read the file, and something must prove the reader can say
  no. Both.

### How you know it is working

This is the mechanism that verifies itself, which is why it comes third and
not last: run the negative controls and watch them fail. If you have no
negative control for a gate, that gate is unverified — list it as such, in
writing, where the next person will see it.

---

## 4. One fact, one place — generate the rest

A fact — a list of opcodes, a set of flag bit positions, the stages of a
pipeline, the names of the tests — lives in **exactly one file**. Every other
copy is generated from it, and a `--check` mode fails the build when a
generated copy has drifted.

### What goes wrong without it

Parallel lists drift, silently, and the drift is a wrong answer rather than a
crash. Two measured examples from the case study:

- A test runner kept its stage names in **three** places — a `--list`
  heredoc, a validation list, and the calls themselves. Two copies drifted:
  two stages reached the run without appearing in `--list`, and one line
  claimed 15 sub-targets after the real count had grown to 17. *A list that
  can lie about what the build does is worse than no list.*
- Assigning **one** new opcode number touched **ten hand-written lists across
  four languages**. Not one was findable by reading the change. Every single
  one surfaced as a *refusal* at run time — which is the design working, and
  is also ten chances to ship a half-assignment.

### How to build it

- **Pick the definition, then generate.** The case study defines header flag
  numbering in one Python module; a generator emits the C header, and
  `--check` compares the generated text against the committed file and fails
  the build on any difference. That check is a prerequisite of two other
  targets, so it cannot be forgotten.
- **Derive, don't re-list.** Where generation is overkill, derive. A list of
  result files was derived from the list of benches with one documented
  exception, rather than written twice — so a bench cannot be added to the
  run and left out of the check, which would reintroduce the exact bug being
  fixed.
- **Derive from the code when the code is the list.** That same runner now
  extracts its stage names by grepping its own `stage` calls. Adding a stage
  needs one edit; the `--list` output and the name validation pick it up for
  free.
- **Never transcribe a constant.** Compute it, or copy it in the base it is
  specified in. Hand-typed magic numbers in the case study were wrong three
  times. Prefer `sizeof("-9223372036854775808")` to `21`.

### How you know it is working

Add a member to the single source and run the build **without** touching
anything else. Every consumer should either update itself or fail. If some
third copy silently keeps the old value, you have found the next thing to
single-source.

---

## 5. Exit codes are not reports

Treat `$?` as the weakest signal in the system. Read the log, assert on its
content, and never redirect output you have not arranged to read.

### What goes wrong without it

This is where agents fail most often, and the failures are all the same
shape: *something true about a thing next to the thing that mattered.* Four
from one day, in one project:

| what was reported | what was actually checked |
|---|---|
| "the library builds clean, `rc=0`" | the build, piped to `/dev/null` — it had printed `warning: excess elements in array initializer`, naming the bug |
| "all contract checks passed" | a **stale** test binary; `make all` does not build the tests target |
| "pushed to main" | `git push -q`, then an echo of the **local** `HEAD`, which is true whether or not anything moved |
| "the suite is green" | a suite that exits 0 regardless |

### How to build it

- **Assert on a line that only success prints**, and on its count. "Read the
  log" becomes mechanical: `grep -c`, and fail if the number is wrong.
- **Make skips loud and optionally fatal.** Every stage whose tools are
  absent must print *by name, with the reason*, and a `--require-all` flag
  must turn every skip into a failure, for hosts that claim to be complete.
  A silently skipped stage is a gate that cannot fail.
- **Never `> /dev/null` a build.** If output is too long, tee it and grep it.
- **For remote state, ask the remote.** After a push, `git ls-remote`. Never
  echo a local ref as evidence about a remote one.
- **Name the artifact you tested.** Print the path and its hash next to the
  result, so "which binary was that?" is answerable afterwards.

### How you know it is working

Take a green run and make one assertion false — delete a line the gate greps
for — and confirm it goes red. Then check every redirect in your scripts: for
each `>` or `2>&1`, name the thing that reads the file. If nothing does,
that is a gate with its eyes shut.

---

## 6. The artifact carries its own provenance

Every build output ships with a manifest recording the commit, the flags, the
measured results and a hash of the artifact — and a checker re-derives all of
it **from the artifact alone**, so "this is the right binary" is decidable
without trusting whoever handed it over.

### What goes wrong without it

Builds get mixed up, and the mix-up is invisible. Two specific modes:

- **The stale clone.** A remote build host reported the right commit from
  `git rev-parse` while its working tree had never updated. Both build hosts
  produced stale bundles in one day. The defence is to assert the pointer
  **and** the content: check the SHA, *and* grep the sources for something
  only the intended commit contains.
- **The stale checkout reporting phantom defects.** A compile check on an
  out-of-date clone reported two warnings for code that had been fixed
  days earlier. They came within one step of being written up as live
  findings — a stale source reporting an old warning is the same class as a
  stale binary reporting a passing test.

### How to build it

- **Write the manifest from the build, never by hand.** Commit, every flag
  that was actually applied (read back from the tool's own log, not from the
  intent), the results, the hash.
- **Verify the artifact against its manifest as a separate step**, before
  anything is staged or installed, and re-hash again after copying. In the
  case study this is eight independent checks; a copy that does not re-hash
  identically is refused.
- **Put the environment in the key.** When a cache or a stamp records "this
  passed", the identity of the *device or backend it passed on* must be part
  of the key. The case study puts the backend selector in every cache key so
  that **a pass on the software path can never satisfy a hardware run.**
- **Keep the forensics you will want later, and extract before you delete.**
  Intermediate build trees are large and mostly worthless; the timing report
  inside one is small and irreplaceable. In the case study a question about
  which path limited the design was unanswerable because that tree had been
  cleaned — 13,415 MB of trees distilled to **9 MB** worth keeping, after the
  deletion that made the question unanswerable had already happened once.
- **Compare like with like across platforms.** Compare git tree hashes, not
  `sha256sum` output, when one side is MSYS and the other is Linux: the
  digests differ on output formatting alone and look like a mismatch.

### How you know it is working

Hand the checker an artifact from a *different* build and confirm it is
refused. Then corrupt one byte of a staged artifact and confirm the re-hash
catches it.

---

## 7. The record is append-only and dated

Keep a ledger of **runs**, not conclusions. Every entry carries the date, the
exact command, the numbers it produced, and the failures. Nothing in it is
ever edited to agree with a later belief.

### What goes wrong without it

Without dates, every number is implicitly a claim about *now*, and the
project slowly fills with figures that were true once. Worse, a rewritten
record destroys the only evidence that a mechanism ever caught anything — and
the catches are the entire argument for the mechanisms.

### How to build it

- **A figure is a fact about its run.** "Run 2026-09-08: 1,071,635 cases" stays
  exactly that after the census changes size. In the case study, one round
  updated 15 *live* claims and deliberately left **51 historical
  measurements** untouched, because they describe runs that happened.
- **Write the failures down, including the embarrassing ones.** The ledger in
  the case study records the gates that could not fail, the five hours spent
  building at the wrong clock, the mistaken readings and who made them. That
  is what makes the passing entries credible.
- **Separate the live claim from the historical one in the layout**, so the
  question "may I edit this?" has a structural answer rather than a judgement
  call.
- **Record what a thing does not prove.** A bit-identity pass says the two
  backends agree; it does not say the problem was the one you meant. Print a
  second, independent counter beside the headline number — in the case study,
  a physics counter beside a timing figure — so an identical result cannot be
  mistaken for a meaningful one.

### How you know it is working

Open the ledger at a random old entry. If you cannot tell from it alone which
commit, which machine and which command produced the number, the entry is not
evidence yet. And grep your documentation for numbers with no date and no
citation; each one is a claim nobody can check.

---

## 8. Uncertainty travels in the value, not in a footnote

Where a value is inferred, assumed or interpolated, the uncertainty must be
**attached to the value itself**, carried everywhere the value goes, and
enforced by something that runs. A caveat in a document two directories away
is not a property of the number.

### What goes wrong without it

An uncertain value is indistinguishable from a measured one at the point of
use, which is where it matters. An agent asked to fill gaps will fill them —
correctly, reasonably, and without any surviving marker — and the result is a
table in which some entries are evidence and some are inference, with nothing
to tell them apart.

### How to build it

`atlas-optical` is the worked example. Many of its historic lenses cannot be
run to a named patent, and leaving five hundred of them untitled "helps
nobody", so a reasoned attribution is permitted **on the condition that it is
legible as one everywhere the title appears**. The rule, from the source:

> *"Anastigmat (Assumed)" is honest; the same string without the suffix is a
> claim nobody checked.*

And it is enforced in both directions, in `tools/dioptrique_registry.py`:

- a name whose stated basis is inferred and which does **not** end in
  `(Assumed)` is **dropped** — not flagged, not warned about, dropped;
- a name marked `(Assumed)` that nevertheless cites a real source raises a
  note, because the marker is also a claim;
- a name with no stated basis at all is dropped.

Note the choice of failure. An improperly marked value does not become an
error for somebody to triage later; it **cannot reach the output**. That is
§2 — refuse rather than approximate — applied to metadata, and it is stronger
than a gate, because there is nothing to ignore.

Where the upstream source expresses its own doubt, preserve that too. The
same registry keeps the compilation's "names are given with reservations"
caveat by propagating it into each affected entry, rather than resolving it
silently in either direction.

### How you know it is working

Add an inferred value without its marker and confirm it does not appear in
the output. Then grep the shipped data for the marker and count: if the
fraction is zero or implausibly low, the rule is being satisfied by
relabelling rather than by honesty.

---

## 9. When the deliverable is a judgement, control the judge

Some outputs cannot be gated by a reference implementation because they are
assessments: a literature review, a claim-to-source audit, a security review,
a "does this citation say what we think it says" pass. This is exactly where
an agent's output is least checkable and most confidently delivered.

The answer is to **plant faults and score the detector.**

### How to build it

`atlas-darkroom`'s external-sources programme is the cleanest instance I know
of. Alongside two dossier audits sits `_controls.md`: six claim–source
pairings **in the identical format as the real ones**, some genuine and some
fabricated, with the instruction stated plainly:

> *The verify pass must classify each as GENUINE or FABRICATED by fetching
> the named source — not by plausibility. The answer key is withheld until
> grading. A verifier that cannot see a planted fault is not evidence.*

The design of the faults is the craft, and they are not caricatures:

- a real hash function's constants **spliced** with a different author's newer
  ones, carrying a one-character typo;
- a genuine 1967 paper credited with introducing something it did not, with an
  invented quotation attached;
- a specification section number that **does not exist** anywhere in the
  document;
- a real statistical transform with its constant **transplanted** from a
  different author's earlier version, and a sentence invented around it.

Each is a thing a plausibility check passes and a fetch fails. That is the
entire selection criterion.

Then the measurement: the key is withheld until both audits return, two
independent auditors grade, and the result is recorded — **12 of 12,
classified correctly, independently, "on fetched bytes rather than
plausibility"**, with the key recording *how* each was caught (one fetched
the Russian original; another found zero-hit searches for a section that does
not exist). The same audits re-verified about eighty-six load-bearing quotes
and found zero fabrications.

### Why this is the load-bearing one for AI-heavy work

Every other mechanism in this document protects against an agent's *code*
being wrong. This one protects against an agent's *reading* being wrong,
which is the failure mode with no compiler. Without it, "the agent checked
the sources" is precisely the LLM opinion the whole framework exists to
remove — and with it, that sentence becomes a detection rate with a date on
it.

It generalises past citations. Any judgement an agent delivers can be
controlled the same way: plant a defect in a code sample given to a review
pass, a known-vulnerable dependency in a list to audit, a deliberately
mismatched pair in a set to reconcile. The rules are constant — **identical
format, subtle and specific faults, key withheld, result recorded.**

### How you know it is working

You know by construction, which is the point: the score *is* the evidence.
Re-run it whenever the model, the prompt or the tooling changes, because the
detection rate is a property of that combination and not of the method. And
keep the key out of the tree until grading — a key an auditor can read is a
control that measures nothing.

---

## 10. The agent's own surface: one front door, and a list of what bites

Two files, for two different failures. Both are for the agent — and for you
in three weeks, which is nearly the same reader.

### One command that means "does this still hold?"

Not twelve tiers the reader must assemble. **One command, in two or three
sizes**, that runs the gates and prints a verdict.

This matters more than it sounds, and the case study proves it in an
uncomfortable way. That project *had* a runner with three well-judged budgets
— a twenty-minute cut, a two-hour cut, and the full census. It was reachable
from the runner's own header comment and from one document, and from nowhere
else: not the README, not the agent-facing notes, and not usefully from
`make`, whose `verify` target passed no budget and therefore meant the
multi-hour run.

The result, measured: **an entire working session ran the individual targets
by hand, one at a time, never once using the command that covers them** — a
session that spent part of its time writing the agent-facing notes. The
structure was fine. Nothing pointed at it, and from the inside that is
indistinguishable from its absence.

So: name the front door in the README's first screen, in the agent notes'
first section, and in `make help`. State its real cost in minutes. State
whether repeated runs are cheap — and if there is no cache, **say so**, or
the next reader will assume warmth that is not there.

### A list of what has already cost hours

Not a tutorial and not a style guide. A short file, in the repository root,
of things that are **non-obvious** and have **already gone wrong**. Each
entry: the symptom as it actually appears, then the cause, then the fix.

The symptom matters more than the cause, because the symptom is what the next
reader searches for. "The default compiler here is the 32-bit one" is useless;
"`undefined reference` to a function that is plainly defined — and also
sometimes `internal compiler error: ... collect2` — means the 32-bit compiler
is first on `PATH`" is the entry that saves the hour.

Keep it ruthlessly short and **delete entries when they stop being true.**
In the case study, that file listed two gates as "known, unfixed" after both
had been repaired, and claimed a checker failed on a clean checkout when it
passed. A stale warning teaches the reader to distrust a check that works,
which is the same damage as trusting one that does not.

### How you know it is working

Run the front door from a clean clone and time it. If the figure in the
documentation is wrong, fix the documentation. Then read the bite-list
end to end and verify every entry against the current code — anything you
cannot reproduce is either fixed (delete it) or a live bug (file it).

---

## What this costs

Honestly, so the trade is visible:

- **A reference implementation you would not otherwise write.** In the case
  study it is about 23,000 lines. It earns its keep because every other
  surface is scored against it, but it is real duplicated effort.
- **A second copy of some checks** — the generator plus its `--check`, the
  negative control beside the positive one.
- **A ledger that only grows.** 11,000 lines in the case study, never pruned.
- **Slower merges.** Gates run, logs get read, and some rounds end with a
  finding instead of a feature.

And what it buys: the sentence *"every line of this was written by an AI and
no claim about it depends on one."* If that sentence is not worth the cost for
your project, take §§1–3 and leave the rest. Most of the value is there.

---

## A closing distinction

None of this is distrust of the model. The agent in the case study wrote
essentially all of it, including every mechanism on this page, and found most
of the defects listed here. What it cannot do — what no amount of care fixes —
is be the thing that certifies its own output, for the same reason a ruler
cannot measure itself.

So the project becomes the ruler. The agent builds it, uses it, and reports
what it reads off it. That division is the method.
