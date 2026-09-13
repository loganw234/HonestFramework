# Honest framework

A way to lay out a project so that an AI can write nearly all of it and
**no claim about it ever rests on the AI's judgement**.

Not "review the AI's work carefully". Not "ask it to double-check". Those
are opinions about opinions. This is about building the project so that
every question of the form *is this actually true?* is answered by something
that cannot hold an opinion: a reference implementation, a bit-identity
comparison, a hash, a gate that has been watched to fail, an append-only
record with dates on it.

## The problem this solves

A coding agent is good at producing work and bad at one specific thing:
**knowing whether what it just said is true.** It does not lie. It reports
something true about a thing *adjacent* to the thing that mattered, and the
two are indistinguishable in the report:

- it ran the test binary — a stale one, because `make all` never built it;
- it reported `rc=0` — having piped the build to `/dev/null`, where the
  compiler had printed the warning naming the bug;
- it pushed, and echoed the local `HEAD` as proof;
- it ran the suite, which exits 0 whether or not the suite passed.

Each is an honest report of a real check. Each is worthless. Asking the agent
to be more careful does not help, because at the moment of reporting it has
no way to tell the two apart — **and neither do you, from the report.**

So the answer is not better prompting. It is that the project must contain
the thing that can tell them apart, and the agent must be unable to route
around it.

## What's here

| | |
|---|---|
| [METHOD.md](METHOD.md) | The ten mechanisms. Start here. |
| [FAILURE-MODES.md](FAILURE-MODES.md) | The catalogue: every way an agent's true report has been worthless, and the mechanism that catches each. |
| [CASE-STUDY.md](CASE-STUDY.md) | Six real projects, measured — 743,605 lines written this way, and every defect the mechanisms caught. |
| [ADOPTING.md](ADOPTING.md) | Retrofitting this onto a project that already exists, in an order that pays as it goes. |
| [templates/](templates/README.md) | Drop-in files, two of them runnable: a stage runner, the generate-and-check pattern, planted-fault controls, a manifest, a ledger, the agent notes. |
| [tools/check_claims.py](tools/check_claims.py) | This repo's own gate. It refuses a broken link or a stated line count that has drifted. |

## The five-minute version

1. **Name one authority, and make it something that cannot argue.** A
   reference implementation, a published vector set, a second independent
   oracle. Everything else — the fast path, the accelerator, the port — is
   *held against it bit for bit*. When they disagree the authority wins by
   definition, so no judgement call is needed and none is made.

2. **A gate you have not watched fail is not a gate.** Break it on purpose
   and confirm it goes red. Do it when you write it, and keep the broken case
   as a permanent negative control that fails the build if it ever passes.
   Seven gates that could not fail were found in one repository in one day.

3. **Never let the same fact be written twice.** Generate the second copy
   from the first and have a `--check` mode that fails the build when they
   disagree. Two hand-maintained copies of one list is not a style problem;
   it is a future wrong answer with a date on it.

4. **Make refusal the only alternative to correctness.** If a thing cannot
   be done exactly, it is refused *by name* — never approximated, never
   silently degraded. A capability bit that is merely advisory is a lie
   waiting for the first caller who believes it.

5. **Put provenance inside the artifact.** Commit, flags, and a hash, written
   by the build into a manifest the artifact carries; then a checker that
   re-derives all of it from the artifact alone. "This is the right binary"
   must be decidable without trusting whoever handed it to you.

6. **Record runs, never conclusions, and never edit them.** Append-only, with
   the date and the exact command. A number is a fact about the run that
   produced it. Failures stay in. The moment a record is rewritten to match
   today's belief, it stops being evidence.

7. **Skip loudly. Fail loudly. Exit codes are not reports.** A stage whose
   tools are missing must announce itself by name with a reason, and a flag
   must exist that turns every skip into a failure. Read the log; the exit
   code is the weakest signal in the system.

## The strongest single argument

A test suite of twenty-one hardware benches that **could not fail.**

cocotb — the framework it used — cannot set a process exit code. It says so
itself, in its own makefile:

> `# Check that the COCOTB_RESULTS_FILE was created, since we can't set an exit code from cocotb.`

The check it defines tests that the results file **exists**. A bench that
ran, compared against the reference model, found a mismatch and wrote it into
the XML still produced the file — so the file existed, so the check passed,
so `make sim` returned 0. **Three real hardware defects were reported as
passes this way.**

No amount of agent diligence finds that, because the agent asks the suite
and the suite says yes. What finds it is a rule — *a gate you have not
watched fail is not a gate* — applied to the suite itself, and then a
hundred-line script that reads the XML and a negative control that proves
the script can say no.

That is the whole thesis in one example. The agent wrote every line of the
fix. It decided nothing about whether the fix worked.

## What this is not

**Not a prompting guide.** Nothing here depends on phrasing, model, or
version. The mechanisms are files and exit codes.

**Not a substitute for tests.** It is a set of properties your tests and
build must have before their green means anything.

**Not free.** A project built this way carries a reference implementation it
could have done without, a second copy of some checks, and a ledger that only
grows. On work where being *approximately* right is fine, that cost buys
nothing. Use it where a wrong answer is expensive and a *confidently* wrong
answer is much worse.

**Not about distrusting the agent.** The agent in the case study wrote
essentially all of 743,605 lines across six repositories, including every
mechanism described here, and found most of the defects listed in it. The
point is narrower and stranger: it is very good at the work and structurally
unable to certify it, so the certifying is moved out of it.

## Licence

MIT ([LICENSE](LICENSE)) — so it can be copied into anything without
thought. One file to change if you would rather it were something else.
