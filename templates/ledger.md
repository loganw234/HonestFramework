# Template: the validation ledger

> Copy to `docs/VALIDATION.md` or equivalent. **Append only.** Nothing in it is
> ever edited to agree with a later belief.

This is METHOD §7. It is the cheapest mechanism in the framework and the one
whose value depends entirely on its age, so start it today even if the first
entry is thin.

---

## The rule, at the top of the file

```markdown
# Validation ledger

Every run that established something, in the order it happened. **A figure
here is a fact about the run that produced it**, on the date given, and is
never updated to match a later measurement — a later run gets a later entry.

Failures stay in, including the ones caused by the author of this file.
A ledger of successes is a brochure.

What this file is NOT: a description of how the project works (see the
README), or a list of what is true now (see <CAPABILITIES.md>). It is the
evidence those documents cite.
```

That third paragraph matters more than it looks. Without it the ledger slowly
becomes documentation, and then someone edits it to be accurate — which
destroys the only thing it was for.

---

## The entry format

```markdown
## YYYY-MM-DD — <what this round established, in one clause>

<One paragraph: what was being asked, and why. Link the contract or the
issue. Name the decision, if a decision was made, and by whom.>

### <What changed, if anything>

<The change, with file references. Mechanism, not narrative.>

### Measured

<Numbers, each with the command that produced it. This is the part that gets
cited elsewhere, so it has to be copy-pasteable.>

- `<exact command>` — <result>, <N> cases, 0 failures
- `<exact command>` — <result> (<host>, <date if different from the heading>)
- <gate> <k>/<k>, <negative control> confirmed to fail

### <Findings, if the round produced any>

<Anything learned that was not the goal. This section earns the ledger its
keep — it is where "we went looking for X and found Y" lives.>

### Not done, and why

<Scope deliberately left out, so a later reader does not mistake absence for
oversight.>
```

---

## What to record, specifically

**The command, not the intent.** `make check` is not a record; the flags,
environment variables and host matter. If the run was on a particular machine
or against particular hardware, name it — and if a configuration selector
exists, record its value, because a pass on one backend is not a pass on
another.

**The negative controls, by name, every time.** "Gate X 12/12, control
confirmed to fail" is one line and it is the difference between a number and
an assertion.

**The failures, in full.** The ledger in the case study records the gates that
could not fail, five hours spent building at the wrong clock, a timing report
read off the wrong clock twice, and a warning dismissed by checking the wrong
half of it. Those entries are why the passing ones are believable.

**Who or what decided.** When a judgement was unavoidable — a tolerance, a
scope cut, an accepted deviation — name it as a decision with a date, so it
can be revisited rather than inherited as a fact.

**What a result does not prove.** A bit-identity pass says two
implementations agree; it does not say the computation was the one you meant.
Where a result is easy to over-read, write the limit next to it.

---

## What never to do

**Never edit a past entry's numbers.** If a later round changes the count, the
old entry still describes its own run correctly. In the case study one round
updated 15 *live* claims across the documentation and deliberately left **51
historical measurements** untouched for exactly this reason.

**Never prune for length.** The case study's ledger is 11,136 lines, about 42%
of that project's documentation, and none of it has been removed. If it is
hard to navigate, add an index — do not delete evidence to make a directory
listing tidier.

**Never let it become the contract.** If someone starts citing the ledger for
*what the system does* rather than *what was measured*, the live document is
missing a section. Write that instead.

---

## The companion: live claims

Keep a separate, editable place for "what is true now" — capabilities,
supported platforms, current limits. That file is maintained; the ledger is
accumulated. Two files because they have opposite rules, and a single file
cannot have both.

The useful discipline between them: **every number in the live document cites
a ledger entry**, by date. Then a stale live claim is mechanically findable —
grep the live document for figures with no citation, and each one is a claim
nobody can check.
