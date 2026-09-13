# Templates

Drop-in files. Each one implements a specific mechanism from
[METHOD.md](../METHOD.md) and carries its reasoning in comments, so a reader
who inherits the copy understands why it is shaped that way without finding
this repository.

| file | mechanism | what it is |
|---|---|---|
| [gate-runner.sh](gate-runner.sh) | §3, §4, §5, §6, §7 | A working stage runner. Derived stage list, loud skips, a negative control that must fail, `--require-all`, per-run markers, an append-only JSONL record. |
| [check_generated.py](check_generated.py) | §4 | The generate-and-`--check` pattern, runnable. One definition, a rendered file, and a build failure when they drift. |
| [controls.md](controls.md) | §9 | Planted-fault controls for work whose output is a **judgement** — audits, reviews, citation checks. The one with no substitute for AI-heavy work. |
| [manifest.md](manifest.md) | §6 | What a build writes beside its artifact, and the checker that re-derives it from the artifact alone. |
| [ledger.md](ledger.md) | §7 | The append-only record: entry format, what to put in it, and the two things never to do to it. |
| [agent-notes.md](agent-notes.md) | §10 | The `CLAUDE.md` / `AGENTS.md` file: one front door, and a list of what has already cost hours. |

## Two of these actually run

`gate-runner.sh` and `check_generated.py` are working programs, not sketches,
because a template that has never executed teaches its reader nothing. Both
were exercised before being committed — which is §3 applied to this repository:

```
gate-runner.sh
  --list                         marks only the selected stages
  normal run                     rc=0, with the control failing as it must
  control sabotaged to pass      rc=1, "NEGATIVE CONTROL DID NOT FAIL"
  --require-all with a skip      rc=1
  unknown --only name            rc=2, refused with the valid list

check_generated.py
  --check, no file               rc=1
  --write then --check           rc=0
  one line appended              rc=1, with a diff naming the drift
  duplicate bit / duplicate name / missing meaning / lower case
                                 each refused by the definition sanity check
```

The repository's own gate, [../tools/check_claims.py](../tools/check_claims.py),
re-checks that both still parse on every run — and it found three real
problems the first time it was pointed at this directory, including one of
these templates being referenced nowhere.

That gate has its own controls, for the same reason:

```
check_claims.py
  README's mechanism count altered     rc=1, "claims 12; METHOD.md has 10"
  a link target renamed               rc=1, names the link
  one table figure changed by 1        rc=1, in BOTH files that quote the total
  a template given a syntax error      rc=1, with bash's own message
```

It also caught itself. An early version passed the script to `bash` with
`text=True`, which on Windows translates every newline into CR+LF — so the
checker **injected** carriage returns into a clean file and then reported that
file as having a syntax error. A checker that manufactures the defect it
reports is the worst kind there is, and it existed for one commit.

## Order to adopt them

[ADOPTING.md](../ADOPTING.md) has the full sequence, but if you want the short
answer: `agent-notes.md` and `gate-runner.sh` first. They cost an afternoon
between them and they are where the method starts paying.

`controls.md` is the one to reach for the moment an agent is asked to *assess*
rather than build, because until it exists that report is an opinion with
citations attached, and the citations are the part you cannot check.
