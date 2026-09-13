# Case study

Six repositories, **743,605 tracked lines**, written almost entirely by a
coding agent. Not one claim in any of them rests on that agent's judgement
about whether it was true.

This file is the evidence for [METHOD.md](METHOD.md). Every figure below was
measured from the repositories on 2026-09-12, and the commands are the obvious
ones — `git ls-files`, `wc -l`, and reading the gates' own output.

## The projects

Counts are tracked lines excluding images and compiled blobs
(`.png .jpg .gif .wasm .pdf`).

| repository | lines | files | what it is | what it contributes to the method |
|---|---|---|---|---|
| `cft-fp256` | 264,618 | 514 | a deterministic IEEE-754-2019 coprocessor: reference model, C library, RTL, bindings | §1 bit-identity authority, §2 refusal, §3 the gates, §4 single-sourcing, §6 artifact manifests |
| `atlas-darkroom` | 143,721 | 1,058 | a large-format print engine for a mathematical atlas | §9 **planted-fault controls on an audit** — the load-bearing one |
| `atlas-optical` | 133,283 | 43 | traced lens prescriptions and an exact ray tracer | §1 external authority, §8 enforced uncertainty markers |
| `cft-rebound` | 125,404 | 471 | an N-body integrator driven through the coprocessor | §3 and §6 via a content-addressed gate cache |
| `atlas-engine` | 70,351 | 215 | a language whose programs are evaluated as deposited light | §1 one-hash determinism across backends |
| `atlas-film` | 6,228 | 47 | what film stocks and pigments do to light, as sourced numbers | §1 external authority, provenance as a first-class file |

Two families, two kinds of authority. The `cft` projects are judged by a
reference implementation and every verdict is bit-identity. The `atlas`
projects are judged by **published literature and measured physical data**,
which is a harder problem and the reason §8 and §9 exist at all.

---

## What the mechanisms actually caught

This is the part that matters. A framework whose safeguards have never fired
is a style guide.

### Three hardware defects reported as passes

A twenty-one-bench RTL suite returned `0` regardless of outcome, because
cocotb cannot set an exit code — it says so in its own makefile, and the check
it ships tests only that the results file *exists*. Benches that compared
against the reference model, found mismatches, and wrote them into XML still
produced the file.

Found by applying §3 to the suite itself rather than by reading any test.
The fix reads the XML and is itself negative-controlled five ways: a recorded
failure, an error, a missing file, an unparseable file, and a clean run. On its
first pass over real data it surfaced a recorded failure from **eleven days
earlier** that nothing had ever read.

### Seven gates that could not fail, in one day

From `cft-rebound`'s cache documentation, written after the audit that found
them: *"A silently skipped leg is a gate that cannot fail, and this repository
has found seven of those in one day."*

The defence became structural — every skip prints itself by name and key, and
the authoritative full run never consults the cache at all, so *"the full
suite passed"* keeps meaning exactly what it always meant.

### A buffer overrun that no test could have found

Nothing validated the reserved bits of a control word, so a device predating a
new flag **ignored** it and read a thousand elements from a one-element
buffer. The negative control demonstrates it as a segfault rather than arguing
it. The guard that refuses non-zero reserved bits cannot retrofit devices
already built — which is §2's argument for writing it before the first one
ships.

### Ten lists, one number

A single new opcode assignment touched **ten hand-written lists across four
languages**. Not one was findable by reading the change; every one surfaced as
a run-time refusal. The design worked, and it was also ten chances to ship a
half-assignment — which is §4's entire case.

### A documentation index that caught its own first drift

Built on 2026-09-12 with a checker for broken links, unlisted documents and
stale line counts. Editing another document in the *same commit* took it from
254 to 270 lines; the gate failed until the index was corrected. Thirty
seconds old and already earning its place.

### Two contradictions in the published literature

`atlas-darkroom`'s external-sources programme holds the repository's own
constants against monographs and papers. One dossier: **24 claim–source
entries — 2 contradicted, 9 corroborated, 10 corroborated-with-caveats, 3
silent** (no published figure found at all). Contradictions are reported
first, and one is traced to a structural cause in the repository's own curve
rather than waved away as a typo.

The "silent" category is the subtle one. Three claims had no published figure
either way, and that is recorded as a finding — where the tempting move is to
read silence as agreement.

### 1,040 of 1,043 lens prescriptions reproducing their source

`atlas-optical` re-traced every historic prescription through its own surfaces
and compared against the focal length its source documents independently —
committed per entry, *"so that the tracing test compares this repository's
numbers against the source's rather than against a copy of itself."*

Worst error 0.05%, median 0.0003%. The three that do not reproduce "are
recorded as refusals with reasons rather than shipped."

### The audit's own controls: 11 of 12 on the source's own bytes

The best single result here, and the one with no equivalent in the `cft`
projects. Six claim–source pairings were planted among the real ones in
identical format — some genuine, some fabricated — with the key **withheld
from the tree until both audits returned**. The instruction:

> *The verify pass must classify each as GENUINE or FABRICATED by fetching the
> named source — not by plausibility. A verifier that cannot see a planted
> fault is not evidence.*

The fabrications were specific enough that plausibility passes them and a
fetch does not: a hash function's constants spliced with a different author's
newer ones plus a one-character typo; a real 1967 paper credited with
something it did not introduce, with an invented quotation; a specification
section number that exists nowhere in the document; a statistical transform
with its constant transplanted from an earlier author.

**Score: 11 of 12 on the named source's own bytes.** Two independent
auditors, every control classified correctly; the twelfth was reached only
through three independent secondary sources, because the primary was
closed-access and just one auditor got to it. The key records *how* each was
caught: one fetched the Russian original, another found zero-hit searches for a
section that does not exist. The same audits re-verified about **86
load-bearing quotations** and found zero fabrications.

That is what "the agent checked the sources" looks like when it is a
measurement instead of an assurance.

**And two things about it that only checking revealed**, both now in
[METHOD.md](METHOD.md) §9 as requirements rather than as notes. The controls,
the key and both audit reports landed in **one commit**, so the withholding
that the score depends on cannot be established from the record — the fix is
three commits, and it costs nothing. And three of the four planted answers were
already documented correctly in sibling files *inside the corpus being
audited*, which both auditors cite: the key was withheld, the answers were not.

Neither makes the mechanism worse than any alternative. It remains the only
thing in six repositories that converts an agent's reading into a number. It
needed one more part, and finding that out is what the read-only sweep was
for — the framework's own §9 applied to the framework's own §9.

---

## What it cost

| cost | measured |
|---|---|
| a reference implementation that exists only to be the authority | ~23,000 lines in `cft-fp256` |
| an append-only ledger, never pruned | 11,136 lines, ~42% of that repo's documentation |
| the same contract restated on every surface | `bindings/` is 76,450 lines — though **94% of the largest is a byte-verified copy**, not independent work |
| gates that take real time | 20 min for the quick cut, ~2 h for the gate cut, hours for the full census |
| rounds that end in a finding instead of a feature | several, including an entire day |

And the shape of the spend is worth noting: in `cft-fp256` the actual
hardware description is **12,294 lines** — under 5% of the repository. The
load-bearing core including the reference model and the library is about 24%.
The rest is surfaces, proof, demonstration and record. A project built this way
is mostly not the thing; it is the evidence about the thing.

---

## The uncomfortable part

The framework's best catches are of its own author, and the author is the
agent that wrote the framework. A single day, 2026-09-12:

- reported a build clean from `rc=0` after piping it to `/dev/null`, where the
  compiler had printed the warning naming the bug;
- ran a stale test binary and reported "all contract checks passed" — the test
  target is not in `all`;
- reported two pushes that never happened, by echoing the local `HEAD`;
- worked on the wrong branch for ten commits, because `--porcelain` shows
  files and never the branch;
- read a timing report's first entry — a shell clock with +7.28 ns — as the
  design's margin, when the design's own clock had +0.21; then **repeated the
  same misreading into an archive built specifically to answer that question**;
- dismissed a real compiler warning by checking the format specifier and not
  the buffer;
- estimated a set of reports at "a few hundred KB" when they were 31 MB each,
  and used the estimate in a plan;
- classified ten documents by filename without opening them, and got six
  wrong;
- wrote a stage count into two files and made it stale in the same session by
  adding a stage.

Every one of those was caught — by a gate, a negative control, a checker, or
by the discipline of measuring before quoting. None were caught by the agent
being careful, because in each case the agent *was* careful and the check it
ran was real.

That is the argument. Not that the model is unreliable: it wrote 743,605 lines
of working, verified software. It is that "careful" is not a property you can
build on, and the project has to hold the ruler.
