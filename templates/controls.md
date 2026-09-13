# Verification controls — template

> Copy this file to wherever your audits live. Replace the items. Keep the
> header, the format, and above all keep the key in a **separate file that is
> not in the tree until grading**.

This is the template for METHOD §9: the mechanism that makes an agent's
*judgement* checkable. Use it whenever the deliverable is an assessment rather
than code — a claim-to-source audit, a literature review, a dependency or
security review, a reconciliation between two datasets.

It is modelled directly on `atlas-darkroom`'s external-sources controls, which
scored **12 of 12** across two independent auditors.

---

## The header to keep

> N claim–source pairings in the standard dossier format. Some are genuine;
> some are fabricated (wrong locus, wrong attribution, or a quote that does not
> exist). The verify pass must classify each as GENUINE or FABRICATED **by
> fetching the named source — not by plausibility**. The answer key is
> withheld until grading.
>
> **A verifier that cannot see a planted fault is not evidence.**

Every sentence there is load-bearing:

- *"in the standard dossier format"* — a control that looks different is a
  control the auditor can identify as a control.
- *"by fetching the named source"* — names the method, because the failure
  being tested is answering from memory.
- *"not by plausibility"* — the faults are chosen so plausibility passes them.
- *"the answer key is withheld"* — a key in the tree measures nothing.

---

## How to design the faults

This is the whole craft. A fault must **pass a plausibility read and fail a
fetch.** Obviously-wrong items measure nothing, because the auditor catches
them without looking, which is the behaviour you are trying to rule out.

The four shapes that work, from the worked example:

| shape | what it looks like | why it works |
|---|---|---|
| **Constant transplant** | a real function's constants replaced with a different author's newer ones, plus a one-character typo | every element is real; only the combination is invented |
| **Attribution slide** | a real, correctly-cited paper credited with introducing something it did not, with a quotation invented around it | the citation resolves; the claim is not in it |
| **Phantom locus** | a section or clause number that does not exist in the named document | the document is real, so only a search finds the absence |
| **Version transplant** | a formula's constant taken from an earlier author's version of it | both values are "correct" somewhere, so only the source settles it |

Rules of thumb:

- **Mix genuine items in, and do not make the ratio guessable.** The example
  ran 6 items, 4 fabricated.
- **One fault per item.** Two faults let an auditor be right for the wrong
  reason.
- **Keep faults specific enough to name.** Grading should record *how* it was
  caught, which requires the fault to be nameable: "fetched the Russian
  original", "zero-hit searches", "3/8 vs 1/2, Bartlett credit".
- **Never reuse a control after it has been graded.** Write new ones.

---

## The item format

Use your real format. If you have none, this one works:

```markdown
## CTRL-n <short subject>
**Claim (repo):** what this project asserts, with the file and line.
**Source:** author, title, venue, year — enough to find it.
**Locator:** the section, page or table within the source.
**Quote:** "the exact words relied on" (accessed YYYY-MM-DD)
**Stance:** corroborates | contradicts | silent
**Note:** one sentence on what the source actually establishes.
```

`Stance` deserves three values, not two. **`silent` — the source has no figure
either way — is a finding**, and the tempting error is to read silence as
agreement. In the worked example, 3 of 24 real entries were silent and were
recorded as such.

---

## The key, which lives elsewhere

`controls-key.md`, kept out of the tree until every audit has returned:

```markdown
# Controls — answer key and grading

> Withheld from the tree until the audits returned (YYYY-MM-DD). The controls
> test whether the verify pass can see a planted fault; a verifier that cannot
> is not evidence.

| control | truth | fault planted | auditor 1 | auditor 2 |
|---|---|---|---|---|
| CTRL-1 … | **FABRICATED** | constants spliced from a different author, with a typo | FABRICATED — all three faults named | FABRICATED — both doctorings named |
| CTRL-2 … | **GENUINE** | none | GENUINE | GENUINE |

**Score: n/n.** What the auditors did, in one line each — the method, not the
verdict: which bytes they fetched and what they searched.
```

Record the **model and date** beside the score. A detection rate is a property
of that model, that prompt and that tooling, not of the method — so it is
re-measured whenever any of the three changes.

---

## Grading

1. Run the audit with the controls mixed in. The auditor must not know which
   items are controls, or how many.
2. Grade against the key **only after the pass has returned**.
3. Prefer two independent auditors. Agreement between two passes that each
   fetched sources is much stronger than one pass's confidence.
4. Record the score in the project's ledger, dated, next to the audit it
   qualifies.

### What to do with the result

- **All controls caught** — the audit's other findings can be relied on to the
  same degree. Say so, with the score, wherever those findings are cited.
- **Any control missed** — the audit is not evidence. Do not salvage it by
  re-checking the item that was missed; the missed control is telling you the
  *method* did not fetch, so every unchecked item is equally suspect. Fix the
  process and re-run.
- **A control caught for the wrong reason** (right verdict, wrong rationale)
  counts as missed. The key exists to catch exactly this, which is why it
  records *how*.

---

## Where this generalises

Anything an agent delivers as a judgement can be controlled this way:

| the pass | plant |
|---|---|
| code review | a defect of the class the review is meant to find, in a file the review covers |
| dependency audit | a version with a known published advisory |
| citation check | the four fault shapes above |
| data reconciliation | a deliberately mismatched pair inside the tolerance being claimed |
| migration verification | one record altered in a field the comparison should cover |

The rules never change: identical format, subtle and specific faults, key
withheld, result recorded with the date and the model.
