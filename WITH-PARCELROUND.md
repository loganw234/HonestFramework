# With ParcelRound

[ParcelRound](https://github.com/loganw234/ParcelRound) is the companion
method, and the two were arrived at from opposite ends of the same problem.

- **ParcelRound** answers *how do several agents work on one codebase at once
  without the pieces failing to meet?* It is about **allocation**: parcels,
  briefs, ownership, a cross-agent ledger, serial merges, and a verifier agent
  between a parcel and the merge.
- **This** answers *how does anything an agent reports get believed?* It is
  about **verification**: an authority, gates watched to fail, one copy of each
  fact, artifacts that identify themselves, a record with dates on it.

They are orthogonal and they reinforce. ParcelRound multiplies throughput and,
in doing so, multiplies the number of reports you have to trust — which is
exactly what the mechanisms here are for. Run parcels without them and you get
more green gates per hour without knowing whether any of the green means
anything.

Use ParcelRound when you have three or more session-sized, mostly independent
pieces landing in one codebase. Use this always, and build it first: its
§§1–3 are what a parcel's gate is measured against.

## The same rules, arrived at twice

Most of ParcelRound's discipline is this framework applied to a multi-agent
round. Where they overlap, they agree, which is the useful part — neither was
derived from the other.

| ParcelRound | here | the shared idea |
|---|---|---|
| "A gate that cannot fail is not a gate" (§5) | [§3](METHOD.md) | identical, down to the wording |
| Name the **specific** negative control in each brief; require the parcel to run it, confirm it fails, and report both results | [§3](METHOD.md) | a control described but not run is worth nothing |
| P0: anything touched by three or more parcels is the **first** parcel, done before anyone splits (§2) | [§4](METHOD.md) | one fact, one place — applied to work rather than to data |
| A ledger, append-only, one file per author, outside every worktree (§4) | [§7](METHOD.md) | the record is the only way to correct a brief after dispatch |
| "Merge serially, run the full suite after each one, and **read the log rather than the exit code**" | [§5](METHOD.md) | word for word |
| The verifier must re-run the gate from a clean build rather than trust pasted output (§6) | [§5](METHOD.md), [§6](METHOD.md) | a pasted result is not a result |
| The verifier must not fix anything; "found nothing" is an acceptable answer (§6) | [§9](METHOD.md) | the judge has its own failure mode |

## What ParcelRound adds that this framework did not have

Two things, both now folded in, both credited where they appear.

**A taxonomy of how a gate dies.** [§3](METHOD.md) said "break it and watch it
fail" and listed the plumbing failures — no exit code, a file nobody reads, a
stale binary. ParcelRound's §5 found four more *semantic* ones in a single
round, each caught by the parcel that wrote the code the gate was meant to hold
down: a gate passing **against itself** because the mode under test was
silently ignored; a gate **proving nothing** because the state it re-read was
still all zeros; a gate **vacuous through the observable**, where the
difference existed but re-converged below the last bit of the rounded view it
was checked through; and a gate **inert by construction**, in a configuration
where the quantity being tested was exactly zero. Plus the one a verifier
found: a bit comparison that could be swapped for a value comparison and still
pass the whole suite, while silently breaking signed zero.

And the worst shape of all, which is not plumbing and not semantics but
grammar: **a case that prints what the code answers instead of asserting what
it should.** One did precisely that — printing `-> NOT REFUSED, which is a bug`
for anything accepted — and after a capability landed, it shipped that line
about **correct** behaviour, accusing the library of a defect in the project's
own published output, with the build exiting 0.

**The gap between gates.** This framework assumed that if every gate is real,
the project is covered. ParcelRound's case study is the counterexample, and it
is the single best argument either repository contains: a bit-identity defect
that **five parcels, two verifiers, a follow-up parcel and 211 assertions all
passed over**, because it lived in a combination that two parcels' gates each
excluded *by construction*. One parcel's file pinned the setting; the other's
registered no force; neither brief mentioned the other. A hundred-line seam
test — written by the lead, because it belonged to no parcel — found it in
seconds: 21 of 21 values differing at about 1e-4, a trajectory divergence
rather than a last bit. The fix was three lines.

It is now [FAILURE-MODES.md](FAILURE-MODES.md) §I. Splitting work creates a gap
exactly where the split is, and the gap is invisible to everyone working inside
it — including, and especially, to an agent whose brief defines its scope.

## What this framework adds to a ParcelRound round

**Control the verifier.** ParcelRound names rubber-stamping as the verifier's
failure mode and handles it by asking what it actually ran, command by command.
[§9](METHOD.md) makes that measurable: plant faults of the shapes a verifier is
meant to catch — an assertion loosened, a tolerance where exactness was
required, a constant transcribed, a skipped case — into a diff it is asked to
review, withhold the key, and score it. Until that exists, a verifier's
"found nothing" and a rubber stamp are the same text.

**One front door, before dispatch.** [§10](METHOD.md). Every parcel brief that
has to explain how to run the suite is a brief that can explain it differently
from the last one. Name one command, in the agent notes, and briefs can simply
point at it.

**Provenance on what parcels hand back.** [§6](METHOD.md). A parcel's claimed
result should name the artifact and its hash. ParcelRound's own verifier
technique is the sharpest version of this: to prove a change did not affect a
build it was not supposed to, **diff the preprocessed translation unit** at both
commits rather than the source — in one case 3,610 lines each, differing by a
single line — or compare the compiled object's hash, which is the same idea
more cheaply.

## The one line both repositories would keep

ParcelRound's, and it belongs here too:

> *"Report anything you found that this brief got wrong."*

Nine words that returned **twelve corrections from five parcels — every single
parcel corrected its brief**, including one where the lead had described a
mechanism backwards in a way that changed what the feature cost.

That is this framework's thesis from the other direction. The mechanisms here
exist because an agent cannot certify its own output; that line exists because
the *lead* cannot either, and the fastest way to find out which parts of your
own model of the code are wrong is to ask the agents who just had to work
inside it.
