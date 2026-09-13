#!/usr/bin/env python3
"""This repository's own gate. It refuses the mistakes this repository can make.

A method document about mechanical verification that is not itself mechanically
verified would be the exact thing it warns against, so the claims in these
files are checkable and this checks them.

WHAT IT CHECKS, and why each one is here rather than hoped for:

  1. Every relative link resolves. A broken link in a document whose subject
     is rigour is the cheapest possible own goal.

  2. README's stated mechanism count equals METHOD's numbered sections. This
     check exists because the count was WRONG on the first draft: the README
     said twelve and METHOD had eight, and the error survived both files being
     written in the same sitting. It is the repository's own §4 - one fact in
     two places drifts - caught by its own §3.

  3. CASE-STUDY's headline total equals the sum of its own per-repository
     table. An arithmetic claim nobody re-adds is a number waiting to be
     wrong, and this one is quoted in the README as well.

  4. Every file under templates/ and tools/ is referenced from a document.
     An unreferenced template is one nobody will find, which is the same
     failure as not writing it.

  5. The shipped scripts parse - bash -n for shell, compile() for Python. A
     template that does not run teaches its reader nothing.

    python tools/check_claims.py           # report and exit nonzero on any problem
    python tools/check_claims.py --quiet   # output only on failure
"""
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
DOCS = sorted(ROOT.glob("*.md")) + sorted(ROOT.glob("templates/*.md"))

WORDS = {
    "one": 1, "two": 2, "three": 3, "four": 4, "five": 5, "six": 6,
    "seven": 7, "eight": 8, "nine": 9, "ten": 10, "eleven": 11, "twelve": 12,
    "thirteen": 13, "fourteen": 14, "fifteen": 15,
}


def check_links(problems):
    n = 0
    for doc in DOCS:
        text = doc.read_text(encoding="utf-8")
        # Skip fenced blocks: they carry templates full of angle-bracket
        # placeholders and example links that are not meant to resolve.
        outside, fenced = [], False
        for line in text.splitlines():
            if line.lstrip().startswith("```"):
                fenced = not fenced
                continue
            if not fenced:
                outside.append(line)
        for href in re.findall(r"\[[^\]]+\]\(([^)]+)\)", "\n".join(outside)):
            if href.startswith(("http://", "https://", "#", "mailto:")):
                continue
            target = (doc.parent / href.split("#")[0]).resolve()
            n += 1
            if not target.exists():
                problems.append("%s: broken link %s" % (doc.name, href))
    return n


def check_mechanism_count(problems):
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    method = (ROOT / "METHOD.md").read_text(encoding="utf-8")

    sections = re.findall(r"^## (\d+)\. ", method, re.M)
    actual = len(sections)
    # The numbers must also be contiguous from 1; a renumbering that skips one
    # is how a "§7" reference starts pointing at the wrong mechanism.
    if sorted(int(s) for s in sections) != list(range(1, actual + 1)):
        problems.append("METHOD.md sections are not numbered 1..%d: %s"
                        % (actual, ", ".join(sections)))

    m = re.search(r"The (\w+) mechanisms", readme)
    if not m:
        problems.append("README.md no longer states a mechanism count")
        return actual
    claimed = WORDS.get(m.group(1).lower())
    if claimed is None:
        problems.append("README.md says %r mechanisms, which is not a number "
                        "this check knows" % m.group(1))
    elif claimed != actual:
        problems.append("README.md claims %d mechanisms; METHOD.md has %d"
                        % (claimed, actual))

    m2 = re.search(r"^(\w+) mechanisms\.", method, re.M)
    if m2:
        intro = WORDS.get(m2.group(1).lower())
        if intro is not None and intro != actual:
            problems.append("METHOD.md's intro says %d mechanisms; it has %d"
                            % (intro, actual))
    return actual


def check_case_study_total(problems):
    text = (ROOT / "CASE-STUDY.md").read_text(encoding="utf-8")

    # The per-repository table rows: | `name` | 264,618 | 514 | ...
    rows = re.findall(r"^\| `([a-z0-9-]+)` \| ([\d,]+) \| ([\d,]+) \|",
                      text, re.M)
    if len(rows) < 2:
        problems.append("CASE-STUDY.md: could not find the repository table")
        return 0
    total = sum(int(r[1].replace(",", "")) for r in rows)

    claimed = set(int(x.replace(",", ""))
                  for x in re.findall(r"\*\*([\d,]{7,}) tracked lines\*\*", text))
    for c in claimed:
        if c != total:
            problems.append("CASE-STUDY.md claims %s tracked lines; its own "
                            "table sums to %s" % (f"{c:,}", f"{total:,}"))
    if not claimed:
        problems.append("CASE-STUDY.md states no headline total to check")

    # The README quotes the same figure twice; it must agree.
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    for c in set(int(x.replace(",", ""))
                 for x in re.findall(r"([\d]{3},\d{3}) lines", readme)):
        if c != total:
            problems.append("README.md quotes %s lines; CASE-STUDY's table "
                            "sums to %s" % (f"{c:,}", f"{total:,}"))
    return total


def check_everything_referenced(problems):
    body = "\n".join(d.read_text(encoding="utf-8") for d in DOCS)
    shipped = [p for p in list(ROOT.glob("templates/*")) + list(ROOT.glob("tools/*"))
               if p.is_file()]
    for p in shipped:
        rel = p.relative_to(ROOT).as_posix()
        if rel not in body and p.name not in body:
            problems.append("nothing references %s" % rel)
    return len(shipped)


def check_scripts_parse(problems):
    n = 0
    for p in sorted(ROOT.glob("templates/*.sh")):
        n += 1
        # The script is fed on STDIN rather than named as an argument,
        # because the `bash` on PATH here is MSYS's and rejects a
        # drive-letter path in this context - reporting "No such file or
        # directory", which reads as a missing template rather than as a
        # broken checker.
        #
        # And BYTES, not text. text=True opens the pipe in text mode,
        # which on Windows translates every newline into CR+LF - so the
        # checker INJECTED carriage returns into a clean file and then
        # reported it as a syntax error near a token ending in CR. A
        # checker that manufactures the defect it reports is the worst
        # kind there is, and this one did it for exactly one commit.
        r = subprocess.run(["bash", "-n"], input=p.read_bytes(),
                           capture_output=True)
        if r.returncode != 0:
            first = r.stderr.decode("utf-8", "replace").strip().splitlines()[:1]
            problems.append("%s does not parse: %s" % (p.name, first))
    for p in sorted(list(ROOT.glob("templates/*.py")) + list(ROOT.glob("tools/*.py"))):
        n += 1
        try:
            compile(p.read_text(encoding="utf-8"), str(p), "exec")
        except SyntaxError as exc:
            problems.append("%s does not parse: %s" % (p.name, exc))
    return n


def main(argv):
    quiet = "--quiet" in argv[1:]
    problems = []

    links = check_links(problems)
    mechs = check_mechanism_count(problems)
    total = check_case_study_total(problems)
    shipped = check_everything_referenced(problems)
    scripts = check_scripts_parse(problems)

    if problems:
        sys.stderr.write("check_claims: %d problem(s)\n" % len(problems))
        for p in problems:
            sys.stderr.write("  %s\n" % p)
        return 1

    if not quiet:
        print("check_claims: %d links resolve, %d mechanisms agree across "
              "README and METHOD," % (links, mechs))
        print("              %s lines sums from the case-study table, "
              "%d shipped files referenced," % (f"{total:,}", shipped))
        print("              %d scripts parse." % scripts)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
