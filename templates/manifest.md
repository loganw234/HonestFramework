# Template: the artifact manifest

> For any build output that leaves the machine that made it. This is METHOD §6.

The question a manifest answers is **"is this the artifact I think it is?"** —
decidable from the artifact alone, without trusting whoever handed it over.

Two pieces: the manifest the build writes, and the checker that re-derives it.
Neither is useful without the other. A manifest nothing verifies is a label.

---

## The manifest the build writes

Written **by the build**, never by hand, into the same directory as the
artifact:

```
artifact:      cft_hw.xclbin
sha256:        0f77d00fb14a57e0aecce0f37876ae2f92e19202d333443ab1d84fe3ee4b903c
built:         2026-09-12T17:18:04-07:00
host:          <hostname>, <cores> threads
commit:        f636cf39c8b52144190b6f35308908646619ca44
tree_dirty:    no
toolchain:     <tool> <exact version>
target:        <platform identifier>

# Every flag as APPLIED, read back from the tool's own log rather than from
# the variable that was set. These two have disagreed.
kernel_freq:   135000000
retiming:      1
phys_opt:      1
directives:    default
clock_arg:     135000000:cft_krnl_1.ap_clk

# Results the build measured, so a later reader need not re-run it to know
# whether this artifact closed.
kernel_wns_ns: 0.210   # THIS is the design's margin
routed_wns_ns: 0.055   # whole design, shell included
failing_endpoints: 0 of 129804

# What the artifact is FOR, in the terms a consumer checks.
compute_units: 1
memory_map:    a->HBM[0] b->HBM[1] c->HBM[2] d->HBM[3], no channel shared
abi_minimum:   0.12
```

### The fields that are not obvious

**`tree_dirty`.** A build from a modified tree is not the commit it names.
Record it rather than refusing it — local builds are legitimate — but a dirty
artifact must never be staged as a release.

**Flags as applied, not as requested.** Read them out of the tool's own log.
In the case study a five-hour build ran at a default clock while the intent
said otherwise, and the manifest is where that becomes visible immediately
instead of hours later.

**The measurement with the units and the meaning in a comment.** `0.210` alone
invites the next reader to compare it with a number from a different clock
domain — which happened, twice, including once into an archive. Say which
figure is the design's.

**The environment selector.** If the artifact or its test pass depends on a
backend, device or feature flag, it is part of the identity. A pass on a
software path must never satisfy a hardware run.

---

## The checker

A separate script, run **before anything is staged or installed**:

```
== verify-image
   artifact: <path>
   manifest: <path>
PASS: sha256 — <digest>
PASS: platform — <expected target>
PASS: content — <the artifact really is of the kind claimed>
PASS: compute units — <n> found, <n> declared
PASS: link config — <the config named was the config used>
PASS: clock — <value> on <n> units
PASS: topology — <the clocks present, and which one is the kernel's>
PASS: memory intent — <n> masters, all on the declared memory, no sharing
== PASS: all 8 checks passed — artifact matches its manifest
```

Three properties make it worth having:

1. **It reads the artifact, not the build directory.** Anything it can only
   learn from the build tree is not a check on the artifact.
2. **Every check is a separate named verdict.** "Verified" is not a report; a
   reader needs to know *which* eight things were true.
3. **It runs before staging and again after copying.** The case study re-hashes
   each staged copy against the manifest, because a copy is a place a byte can
   change.

---

## The release discipline around it

When a set of artifacts is promoted together:

- **Checker passes on every member, or nothing is promoted.** A half-staged
  set is worse than none, because the staging directory is what a later
  session trusts.
- **Don't spend hours on the second half if the first failed.** Build the
  cheap one first and stop.
- **Write a `SHA256SUMS` and a README naming the lineage** — what this set is,
  what changed since the previous one, what the previous one was, and the
  minimum consumer version.
- **Negative WNS, or any missed target, is a finding in the README** — not a
  footnote and not a reason to quietly relabel. A slower artifact that is
  *correct* can be a complete answer; it is a different artifact and it gets
  said out loud.

---

## Keep the forensics before you delete the tree

Intermediate build trees are large and mostly worthless; a few files inside
them are small and irreplaceable. Extract those **before** reclaiming, as a
separate run — a script that extracts and deletes in one pass, and fails in
the middle, has deleted something it did not copy.

In the case study: 13,415 MB of trees reduced to **9 MB** kept per set — the
manifest, the full timing report gzipped, and a distilled extract naming the
limiting path. The rule was learned by losing it once: a question about which
path limited a design was unanswerable because that tree had already been
cleaned, and the staged artifact keeps no report.

When you write the distiller, **name the subject in its output.** The first
version of that one extracted the first entry in the report, which belongs to
whichever clock domain printed first — a value that is correct about the wrong
thing, in a file built specifically to answer the right one.
