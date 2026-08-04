#!/usr/bin/env python3
"""xsd_generate — infer a DRAFT XSD from a sample XML instance.

Original tool, stdlib only. Epistemic status of the output: ESTIMATED.
A schema inferred from one sample encodes only what that sample shows:
optionality, cardinality, and value types are guesses from observed
occurrences and must be reviewed against the real contract before use.
The generated file says so in its header comment.

Inference rules (stated, so the output is auditable):
- Same-named element seen >1× under one parent  -> maxOccurs="unbounded"
- Child absent in some occurrences of a parent  -> minOccurs="0"
- Attribute absent in some occurrences          -> use="optional"
- Text values: all-int -> xs:integer · all-decimal -> xs:decimal ·
  all true/false -> xs:boolean · all ISO dates -> xs:date · else xs:string
- Root namespace, if any -> targetNamespace + elementFormDefault=qualified
- One named complexType per distinct element local name (occurrences merged)

Usage: xsd_generate.py sample.xml > draft.xsd
Exit codes: 0 draft written · 1 sample not well-formed · 2 usage
"""
import re
import sys
from collections import Counter

from xmlcore import parse_file, ParseError, walk

RE_INT = re.compile(r"^[+-]?\d+$")
RE_DEC = re.compile(r"^[+-]?(\d+\.\d*|\.\d+)$")
RE_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")


def infer_type(values):
    vals = [v.strip() for v in values if v.strip()]
    if not vals:
        return "xs:string"
    if all(RE_INT.match(v) for v in vals):
        return "xs:integer"
    if all(RE_INT.match(v) or RE_DEC.match(v) for v in vals):
        return "xs:decimal"
    if all(v in ("true", "false") for v in vals):
        return "xs:boolean"
    if all(RE_DATE.match(v) for v in vals):
        return "xs:date"
    return "xs:string"


class Profile:
    """Merged observation of every occurrence of one element name."""

    def __init__(self):
        self.occurrences = 0
        self.child_order = []          # first-seen order of child names
        self.child_min = {}            # name -> min count over occurrences
        self.child_max = {}            # name -> max count over occurrences
        self.attr_seen = Counter()     # attr local -> occurrences having it
        self.attr_values = {}          # attr local -> sample values
        self.texts = []
        self.has_children = False


def profile(root):
    profiles = {}
    for n in walk(root):
        p = profiles.setdefault(n.local, Profile())
        p.occurrences += 1
        counts = Counter(c.local for c in n.children)
        for c in n.children:
            if c.local not in p.child_order:
                p.child_order.append(c.local)
        for name in p.child_order:
            c = counts.get(name, 0)
            p.child_max[name] = max(p.child_max.get(name, 0), c)
            prev = p.child_min.get(name)
            p.child_min[name] = c if prev is None else min(prev, c)
        for (_, alocal), val in n.attrs.items():
            p.attr_seen[alocal] += 1
            p.attr_values.setdefault(alocal, []).append(val)
        if n.children:
            p.has_children = True
        else:
            p.texts.append(n.full_text())
    return profiles


def esc(s):
    return (s.replace("&", "&amp;").replace("<", "&lt;")
             .replace('"', "&quot;"))


def emit(root, profiles, out):
    tns = root.ns
    out.append('<?xml version="1.0" encoding="UTF-8"?>')
    out.append("<!-- DRAFT schema inferred from a single sample instance.")
    out.append("     Epistemic status: ESTIMATED — cardinality, optionality")
    out.append("     and types reflect only the observed sample. Review")
    out.append("     against the real contract before treating as Known. -->")
    attrs = ['xmlns:xs="http://www.w3.org/2001/XMLSchema"']
    if tns:
        attrs.append(f'targetNamespace="{esc(tns)}"')
        attrs.append(f'xmlns:tns="{esc(tns)}"')
        attrs.append('elementFormDefault="qualified"')
    out.append(f'<xs:schema {" ".join(attrs)}>')
    prefix = "tns:" if tns else ""
    out.append(f'  <xs:element name="{root.local}" '
               f'type="{prefix}{root.local}Type"/>')
    for name, p in profiles.items():
        if not p.has_children and not p.attr_seen:
            continue  # simple leaf: typed inline at the use site
        out.append(f'  <xs:complexType name="{name}Type"'
                   + (' mixed="true"' if p.has_children
                      and any(t.strip() for t in p.texts) else "")
                   + ">")
        if p.has_children:
            out.append("    <xs:sequence>")
            for child in p.child_order:
                cp = profiles[child]
                mn = p.child_min.get(child, 0)
                mx = p.child_max.get(child, 1)
                occ = ""
                if mn == 0:
                    occ += ' minOccurs="0"'
                if mx > 1:
                    occ += ' maxOccurs="unbounded"'
                if cp.has_children or cp.attr_seen:
                    out.append(f'      <xs:element name="{child}" '
                               f'type="{prefix}{child}Type"{occ}/>')
                else:
                    t = infer_type(cp.texts)
                    out.append(f'      <xs:element name="{child}" '
                               f'type="{t}"{occ}/>')
            out.append("    </xs:sequence>")
        elif p.attr_seen:
            # attributes on a text-bearing leaf -> simpleContent
            base = infer_type(p.texts)
            out.append("    <xs:simpleContent>")
            out.append(f'      <xs:extension base="{base}">')
            for a in sorted(p.attr_seen):
                use = "required" if p.attr_seen[a] == p.occurrences \
                    else "optional"
                t = infer_type(p.attr_values[a])
                out.append(f'        <xs:attribute name="{a}" type="{t}" '
                           f'use="{use}"/>')
            out.append("      </xs:extension>")
            out.append("    </xs:simpleContent>")
            out.append("  </xs:complexType>")
            continue
        for a in sorted(p.attr_seen):
            use = "required" if p.attr_seen[a] == p.occurrences else "optional"
            t = infer_type(p.attr_values[a])
            out.append(f'    <xs:attribute name="{a}" type="{t}" '
                       f'use="{use}"/>')
        out.append("  </xs:complexType>")
    out.append("</xs:schema>")


def main(argv):
    if len(argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    try:
        root = parse_file(argv[1])
    except ParseError as e:
        print(f"NOT WELL-FORMED: {argv[1]}:{e.line}:{e.column}: {e}",
              file=sys.stderr)
        return 1
    profiles = profile(root)
    out = []
    emit(root, profiles, out)
    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
