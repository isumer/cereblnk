#!/usr/bin/env python3
"""xsd_validate — validate an XML instance against an XSD schema.

Original validator, stdlib only, no third-party libraries. Implements
the practical XSD 1.0 subset below and is FAIL-CLOSED beyond it: a
schema using an unsupported construct is refused with the construct
named — it is never silently half-validated.

Supported: global elements; named + inline complexType/simpleType;
sequence/choice/all (nested) with minOccurs/maxOccurs; attributes
(use, fixed, default, type); simpleContent extension; mixed content;
simpleType restriction facets (enumeration, pattern, length, minLength,
maxLength, minInclusive, maxInclusive, minExclusive, maxExclusive);
built-in types (string family, integer family, decimal, float, double,
boolean, date, dateTime, time, anyURI); element ref=.

Unsupported (fail-closed): import, include, redefine, group,
attributeGroup, complexContent, union, list, key/keyref/unique,
substitutionGroup, abstract, any, anyAttribute, notation, xsi:type,
xsi:nil.

Usage: xsd_validate.py schema.xsd instance.xml
Exit codes: 0 valid · 1 invalid instance · 2 schema/usage problem
"""
import re
import sys

from xmlcore import XS, XSI, parse_file, ParseError

UNSUPPORTED = {
    "import", "include", "redefine", "group", "attributeGroup",
    "complexContent", "union", "list", "key", "keyref", "unique",
    "any", "anyAttribute", "notation",
}

INT_RANGES = {
    "byte": (-128, 127), "short": (-32768, 32767),
    "int": (-2**31, 2**31 - 1), "long": (-2**63, 2**63 - 1),
    "integer": (None, None), "nonNegativeInteger": (0, None),
    "positiveInteger": (1, None), "negativeInteger": (None, -1),
    "nonPositiveInteger": (None, 0), "unsignedInt": (0, 2**32 - 1),
    "unsignedLong": (0, 2**64 - 1), "unsignedShort": (0, 65535),
    "unsignedByte": (0, 255),
}
STRING_TYPES = {"string", "normalizedString", "token", "anyURI", "ID",
                "IDREF", "NCName", "Name", "NMTOKEN", "language",
                "QName", "base64Binary", "hexBinary", "duration",
                "anySimpleType", "anyType"}
RE_DATE = re.compile(r"^-?\d{4,}-\d{2}-\d{2}(Z|[+-]\d{2}:\d{2})?$")
RE_TIME = re.compile(r"^\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?$")
RE_DATETIME = re.compile(
    r"^-?\d{4,}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:\d{2})?$")
RE_DECIMAL = re.compile(r"^[+-]?(\d+(\.\d*)?|\.\d+)$")
RE_FLOAT = re.compile(
    r"^([+-]?(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?|INF|-INF|NaN)$")


class SchemaError(Exception):
    pass


def check_builtin(local, value):
    """Return None if value is a valid lexical form of builtin type
    `local`, else an error string."""
    v = value if local in ("string", "normalizedString") else value.strip()
    if local in STRING_TYPES:
        return None
    if local in INT_RANGES:
        if not re.match(r"^[+-]?\d+$", v):
            return f"not a valid {local}"
        n = int(v)
        lo, hi = INT_RANGES[local]
        if (lo is not None and n < lo) or (hi is not None and n > hi):
            return f"out of range for {local}"
        return None
    if local == "decimal":
        return None if RE_DECIMAL.match(v) else "not a valid decimal"
    if local in ("float", "double"):
        return None if RE_FLOAT.match(v) else f"not a valid {local}"
    if local == "boolean":
        return None if v in ("true", "false", "1", "0") else "not a valid boolean"
    if local == "date":
        return None if RE_DATE.match(v) else "not a valid date"
    if local == "time":
        return None if RE_TIME.match(v) else "not a valid time"
    if local == "dateTime":
        return None if RE_DATETIME.match(v) else "not a valid dateTime"
    return f"unknown built-in type '{local}'"


class SimpleType:
    def __init__(self, base_local, facets):
        self.base = base_local          # builtin local name
        self.facets = facets            # list of (facet, value)

    def check(self, value):
        err = check_builtin(self.base, value)
        if err:
            return err
        v = value if self.base in ("string", "normalizedString") else value.strip()
        enums = [x for f, x in self.facets if f == "enumeration"]
        if enums and v not in enums:
            return f"value '{v}' not in enumeration {enums}"
        for f, x in self.facets:
            if f == "pattern" and not re.fullmatch(x, v):
                return f"value '{v}' does not match pattern '{x}'"
            if f == "length" and len(v) != int(x):
                return f"length {len(v)} != required {x}"
            if f == "minLength" and len(v) < int(x):
                return f"length {len(v)} < minLength {x}"
            if f == "maxLength" and len(v) > int(x):
                return f"length {len(v)} > maxLength {x}"
            if f in ("minInclusive", "maxInclusive",
                     "minExclusive", "maxExclusive"):
                try:
                    n, b = float(v), float(x)
                except ValueError:
                    return f"non-numeric value for {f} facet"
                if f == "minInclusive" and n < b:
                    return f"{v} < minInclusive {x}"
                if f == "maxInclusive" and n > b:
                    return f"{v} > maxInclusive {x}"
                if f == "minExclusive" and n <= b:
                    return f"{v} <= minExclusive {x}"
                if f == "maxExclusive" and n >= b:
                    return f"{v} >= maxExclusive {x}"
        return None


BUILTIN = object()  # marker: type is a builtin, stored as its local name


class ComplexType:
    def __init__(self):
        self.attributes = {}   # local -> {"use","type","fixed","default"}
        self.model = None      # group tuple, or ("simpleContent", SimpleType/loc)
        self.mixed = False


class Schema:
    def __init__(self):
        self.target_ns = ""
        self.qualified = False
        self.elements = {}     # local -> decl {"type": ...}
        self.types = {}        # local -> ComplexType | SimpleType | builtin str


def occurs(node):
    mn = int(node.attr("minOccurs") or 1)
    mx = node.attr("maxOccurs") or "1"
    mx = None if mx == "unbounded" else int(mx)
    return mn, mx


def compile_schema(path):
    root = parse_file(path)
    if root.name != (XS, "schema"):
        raise SchemaError(f"root is not xs:schema (line {root.line})")
    s = Schema()
    s.target_ns = root.attr("targetNamespace") or ""
    s.qualified = (root.attr("elementFormDefault") == "qualified")

    problems = []
    from xmlcore import walk
    for n in walk(root):
        if n.ns == XS and n.local in UNSUPPORTED:
            problems.append(f"xs:{n.local} (line {n.line})")
        if n.ns == XS and n.local == "element" and (
                n.attr("substitutionGroup") or n.attr("abstract") == "true"):
            problems.append(f"substitutionGroup/abstract (line {n.line})")
    if problems:
        raise SchemaError(
            "schema uses unsupported constructs — refusing to validate "
            "(fail-closed): " + ", ".join(problems))

    def type_of(node):
        """Resolve a decl's type: returns ('builtin', local) |
        ('ref', local) | ('inline', compiled) | ('any', None)."""
        tq = node.attr("type")
        if tq:
            ns, local = node.resolve_qname(tq)
            if ns == XS:
                return ("builtin", local)
            return ("ref", local)
        inline_ct = node.find_all(XS, "complexType")
        if inline_ct:
            return ("inline", compile_complex(inline_ct[0]))
        inline_st = node.find_all(XS, "simpleType")
        if inline_st:
            return ("inline", compile_simple(inline_st[0]))
        return ("any", None)

    def compile_simple(node):
        rs = node.find_all(XS, "restriction")
        if not rs:
            raise SchemaError(
                f"simpleType without restriction (line {node.line})")
        r = rs[0]
        ns, base = r.resolve_qname(r.attr("base") or "xs:string")
        if ns != XS:
            raise SchemaError(
                f"simpleType base must be a built-in in this subset "
                f"(line {r.line})")
        facets = [(c.local, c.attr("value")) for c in r.children
                  if c.ns == XS]
        return SimpleType(base, facets)

    def compile_group(node):
        parts = []
        for c in node.children:
            if c.ns != XS:
                continue
            if c.local in ("sequence", "choice", "all"):
                mn, mx = occurs(c)
                parts.append(("group", compile_group(c), mn, mx))
            elif c.local == "element":
                mn, mx = occurs(c)
                ref = c.attr("ref")
                if ref:
                    _, local = c.resolve_qname(ref)
                    parts.append(("elemref", local, mn, mx))
                else:
                    parts.append(("elem", c.attr("name"), type_of(c),
                                  mn, mx))
            elif c.local == "annotation":
                continue
        return (node.local, parts)

    def compile_complex(node):
        ct = ComplexType()
        ct.mixed = (node.attr("mixed") == "true")
        for c in node.children:
            if c.ns != XS:
                continue
            if c.local in ("sequence", "choice", "all"):
                mn, mx = occurs(c)
                ct.model = ("group", compile_group(c), mn, mx)
            elif c.local == "attribute":
                ct.attributes[c.attr("name")] = {
                    "use": c.attr("use") or "optional",
                    "type": type_of(c),
                    "fixed": c.attr("fixed"),
                    "default": c.attr("default"),
                }
            elif c.local == "simpleContent":
                exts = c.find_all(XS, "extension")
                if not exts:
                    raise SchemaError(
                        f"simpleContent without extension (line {c.line})")
                e = exts[0]
                ns, base = e.resolve_qname(e.attr("base") or "xs:string")
                ct.model = ("simpleContent",
                            ("builtin", base) if ns == XS else ("ref", base))
                for a in e.find_all(XS, "attribute"):
                    ct.attributes[a.attr("name")] = {
                        "use": a.attr("use") or "optional",
                        "type": type_of(a),
                        "fixed": a.attr("fixed"),
                        "default": a.attr("default"),
                    }
            elif c.local == "annotation":
                continue
        return ct

    for c in root.children:
        if c.ns != XS:
            continue
        if c.local == "element":
            s.elements[c.attr("name")] = {"type": type_of(c)}
        elif c.local == "complexType":
            s.types[c.attr("name")] = compile_complex(c)
        elif c.local == "simpleType":
            s.types[c.attr("name")] = compile_simple(c)
    return s


class Validator:
    def __init__(self, schema):
        self.s = schema
        self.errors = []

    def err(self, node, msg):
        self.errors.append(f"line {node.line}: {node.path()}: {msg}")

    def resolve(self, t):
        kind, val = t
        if kind == "builtin":
            return SimpleType(val, [])
        if kind == "inline":
            return val
        if kind == "ref":
            if val not in self.s.types:
                raise SchemaError(f"reference to undefined type '{val}'")
            return self.s.types[val]
        return None  # any

    def expected_ns(self):
        return self.s.target_ns if self.s.qualified else ""

    def validate_root(self, node):
        want_ns = self.s.target_ns  # global elements are always qualified
        if node.local not in self.s.elements or node.ns != want_ns:
            self.err(node, f"no global element declaration for "
                           f"'{{{node.ns}}}{node.local}'")
            return
        self.validate_elem(node, self.s.elements[node.local]["type"])

    def validate_elem(self, node, t):
        for (ans, alocal) in node.attrs:
            if ans == XSI and alocal in ("type", "nil"):
                self.err(node, f"xsi:{alocal} is unsupported (fail-closed)")
                return
        typ = self.resolve(t)
        if typ is None:
            return  # anyType: accepted, structure unchecked
        if isinstance(typ, SimpleType):
            if node.children:
                self.err(node, "element of simple type has child elements")
            e = typ.check(node.full_text())
            if e:
                self.err(node, e)
            if node.attrs:
                self.err(node, "element of simple type has attributes")
            return
        self.validate_attrs(node, typ)
        if typ.model and typ.model[0] == "simpleContent":
            if node.children:
                self.err(node, "simpleContent element has child elements")
            st = self.resolve(typ.model[1])
            e = st.check(node.full_text()) if isinstance(st, SimpleType) \
                else "simpleContent base is not a simple type"
            if e:
                self.err(node, e)
            return
        if not typ.mixed and node.full_text().strip() and typ.model:
            self.err(node, "unexpected text content (type is not mixed)")
        self.validate_children(node, typ)

    def validate_attrs(self, node, ct):
        for local, decl in ct.attributes.items():
            val = node.attr(local)
            if val is None:
                if decl["use"] == "required":
                    self.err(node, f"required attribute '{local}' missing")
                continue
            if decl["fixed"] is not None and val != decl["fixed"]:
                self.err(node, f"attribute '{local}' must be fixed value "
                               f"'{decl['fixed']}', got '{val}'")
            st = self.resolve(decl["type"])
            if isinstance(st, SimpleType):
                e = st.check(val)
                if e:
                    self.err(node, f"attribute '{local}': {e}")
        for (ans, alocal) in node.attrs:
            if ans in (XSI,):
                continue
            if alocal not in ct.attributes:
                self.err(node, f"undeclared attribute '{alocal}'")

    def validate_children(self, node, ct):
        kids = node.children
        if ct.model is None:
            if kids:
                self.err(node, "element of empty content type has children")
            return
        _, group, mn, mx = ct.model
        ends = self.match_group_repeat(group, mn, mx, kids, 0, node)
        if not any(e == len(kids) for e in ends):
            covered = max(ends) if ends else 0
            bad = kids[covered] if covered < len(kids) else node
            self.err(bad, f"content does not match model of "
                          f"'{node.local}' (first problem at "
                          f"'{bad.local}', line {bad.line})")
            return
        # recurse using a successful assignment: re-match to bind decls
        self.bind_and_recurse(group, mn, mx, kids, node)

    # --- content model matching (backtracking, memoized) ---

    def elem_decl(self, part):
        if part[0] == "elemref":
            local = part[1]
            if local not in self.s.elements:
                raise SchemaError(f"element ref to undefined '{local}'")
            return local, self.s.elements[local]["type"], self.s.target_ns
        _, name, t, _, _ = part
        return name, t, self.expected_ns()

    def match_part(self, part, kids, i):
        if part[0] == "group":
            _, grp, mn, mx = part
            return self.match_group_repeat(grp, mn, mx, kids, i, None)
        mn, mx = part[3], part[4]
        name, _t, ns = self.elem_decl(part)
        ends, count, j = set(), 0, i
        if mn == 0:
            ends.add(i)
        while j < len(kids) and kids[j].local == name and kids[j].ns == ns \
                and (mx is None or count < mx):
            j += 1
            count += 1
            if count >= mn:
                ends.add(j)
        return ends

    def match_group_once(self, group, kids, i):
        kind, parts = group
        if kind == "sequence":
            fronts = {i}
            for p in parts:
                nxt = set()
                for f in fronts:
                    nxt |= self.match_part(p, kids, f)
                if not nxt:
                    return set()
                fronts = nxt
            return fronts
        if kind == "choice":
            out = set()
            for p in parts:
                out |= self.match_part(p, kids, i)
            return out
        if kind == "all":  # order-free, each element part per its occurs
            j = i
            counts = {}
            index = {}
            for p in parts:
                if p[0] == "group":
                    raise SchemaError("nested group inside xs:all "
                                      "is not allowed")
                name, _t, ns = self.elem_decl(p)
                index[(ns, name)] = p
                counts[(ns, name)] = 0
            while j < len(kids) and kids[j].name in index:
                counts[kids[j].name] += 1
                j += 1
            for key, p in index.items():
                mn, mx = p[3], p[4]
                c = counts[key]
                if c < mn or (mx is not None and c > mx):
                    return set()
            return {j}
        raise SchemaError(f"unknown group kind '{kind}'")

    def match_group_repeat(self, group, mn, mx, kids, i, _node):
        results, seen = set(), set()

        def go(pos, reps):
            if (pos, reps) in seen:
                return
            seen.add((pos, reps))
            if reps >= mn:
                results.add(pos)
            if mx is not None and reps >= mx:
                return
            for e in self.match_group_once(group, kids, pos):
                if e == pos and reps >= mn:
                    continue  # zero-width repeat guard
                go(e, reps + 1)
        go(i, 0)
        return results

    def bind_and_recurse(self, group, mn, mx, kids, node):
        """After a successful structural match, validate each child
        against its declaration (name-directed — unambiguous in this
        subset because decls are matched by qualified name)."""
        decls = {}

        def collect(g):
            for p in g[1]:
                if p[0] == "group":
                    collect(p[1])
                else:
                    name, t, ns = self.elem_decl(p)
                    decls[(ns, name)] = t
        collect(group)
        for k in kids:
            if k.name in decls:
                self.validate_elem(k, decls[k.name])
            else:
                self.err(k, f"element '{k.local}' not declared in "
                            f"parent's content model")


def main(argv):
    if len(argv) != 3:
        print(__doc__)
        return 2
    schema_path, xml_path = argv[1], argv[2]
    try:
        schema = compile_schema(schema_path)
    except ParseError as e:
        print(f"SCHEMA NOT WELL-FORMED: {schema_path}:{e.line}:{e.column}: {e}")
        return 2
    except SchemaError as e:
        print(f"SCHEMA REFUSED: {e}")
        return 2
    try:
        doc = parse_file(xml_path)
    except ParseError as e:
        print(f"NOT WELL-FORMED: {xml_path}:{e.line}:{e.column}: {e}")
        return 1
    v = Validator(schema)
    try:
        v.validate_root(doc)
    except SchemaError as e:
        print(f"SCHEMA REFUSED: {e}")
        return 2
    if v.errors:
        print(f"INVALID: {len(v.errors)} finding(s) "
              f"[validator subset: see --help header]")
        for e in v.errors:
            print(f"  {xml_path}:{e}")
        return 1
    print(f"VALID: {xml_path} conforms to {schema_path} "
          f"(within the documented subset)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
