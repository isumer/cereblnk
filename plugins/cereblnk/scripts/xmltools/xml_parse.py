#!/usr/bin/env python3
"""xml_parse — well-formedness check and structure outline for XML.

Original tool, stdlib only. Two jobs:
1. Well-formedness: exact line/column on the first syntax error.
2. Outline: the document's element structure with namespaces, counts,
   and depth — the evidence a reviewer needs before trusting any claim
   about "what this XML contains".

Usage:
  xml_parse.py file.xml            # check + summary
  xml_parse.py --outline file.xml  # + indented structure (repeats collapsed)
Exit codes: 0 well-formed · 1 not well-formed · 2 usage
"""
import sys
from collections import Counter

from xmlcore import parse_file, ParseError, walk


def outline(node, indent, lines, max_lines=200):
    if len(lines) >= max_lines:
        return
    groups = []
    for c in node.children:
        if groups and groups[-1][0] == c.name:
            groups[-1][1] += 1
        else:
            groups.append([c.name, 1, c])
    for (ns, local), count, first in groups:
        tag = local + (f"  ({ns})" if ns else "")
        mark = f" ×{count}" if count > 1 else ""
        attrs = "".join(f" @{a}" for (_, a) in first.attrs)
        lines.append(f"{'  ' * indent}{tag}{mark}{attrs}")
        outline(first, indent + 1, lines, max_lines)


def main(argv):
    args = [a for a in argv[1:] if a != "--outline"]
    show_outline = "--outline" in argv
    if len(args) != 1:
        print(__doc__)
        return 2
    path = args[0]
    try:
        root = parse_file(path)
    except ParseError as e:
        print(f"NOT WELL-FORMED: {path}:{e.line}:{e.column}: {e}")
        return 1
    counts = Counter()
    namespaces = set()
    depth = 0

    def measure(n, d):
        nonlocal depth
        depth = max(depth, d)
        counts[n.local] += 1
        if n.ns:
            namespaces.add(n.ns)
        for c in n.children:
            measure(c, d + 1)
    measure(root, 1)
    total = sum(counts.values())
    print(f"WELL-FORMED: {path}")
    print(f"root: {root.local}"
          + (f" ({root.ns})" if root.ns else " (no namespace)"))
    print(f"elements: {total} · distinct tags: {len(counts)} "
          f"· max depth: {depth}")
    if namespaces:
        print("namespaces: " + " · ".join(sorted(namespaces)))
    top = counts.most_common(8)
    print("top tags: " + ", ".join(f"{t}×{c}" for t, c in top))
    if show_outline:
        lines = []
        print(f"\n{root.local}")
        outline(root, 1, lines)
        print("\n".join(lines))
        if len(lines) >= 200:
            print("  ... (outline truncated at 200 lines)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
