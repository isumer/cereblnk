#!/usr/bin/env python3
"""xmlcore — minimal line-aware, namespace-aware XML tree for xmltools.

Original parser built on the stdlib expat bindings only. Every node
carries its source line so downstream findings are traceable
(evidence-reference discipline). No third-party libraries.
"""
import xml.parsers.expat as expat

XS = "http://www.w3.org/2001/XMLSchema"
XSI = "http://www.w3.org/2001/XMLSchema-instance"
SEP = "\x01"  # never appears in URIs or names


class Node:
    __slots__ = ("ns", "local", "attrs", "children", "text", "line",
                 "parent", "nsmap")

    def __init__(self, ns, local, attrs, line, parent, nsmap=None):
        self.ns = ns            # namespace URI or ""
        self.local = local      # local name
        self.attrs = attrs      # {(ns, local): value}
        self.children = []      # element children, in order
        self.text = []          # text fragments (element's own text)
        self.line = line
        self.parent = parent
        self.nsmap = nsmap or {}   # in-scope prefix -> uri ("" = default)

    def resolve_qname(self, qname):
        """Resolve a QName found in an attribute VALUE (e.g. type="tns:X")
        against this node's in-scope namespace map."""
        if ":" in qname:
            prefix, local = qname.split(":", 1)
        else:
            prefix, local = "", qname
        return self.nsmap.get(prefix, ""), local

    @property
    def name(self):
        return (self.ns, self.local)

    def full_text(self):
        return "".join(self.text)

    def attr(self, local, ns=""):
        return self.attrs.get((ns, local))

    def path(self):
        parts, n = [], self
        while n is not None:
            if n.parent is not None:
                idx = 1
                for sib in n.parent.children:
                    if sib is n:
                        break
                    if sib.name == n.name:
                        idx += 1
                parts.append(f"{n.local}[{idx}]" if idx > 1 else n.local)
            else:
                parts.append(n.local)
            n = n.parent
        return "/" + "/".join(reversed(parts))

    def find_all(self, ns, local):
        return [c for c in self.children if c.ns == ns and c.local == local]


class ParseError(Exception):
    def __init__(self, message, line, column):
        super().__init__(message)
        self.line, self.column = line, column


def _split(qname):
    if SEP in qname:
        ns, local = qname.split(SEP, 1)
        return ns, local
    return "", qname


def parse_file(path):
    """Parse an XML file into a Node tree. Raises ParseError on
    malformed input with the exact line/column from expat."""
    parser = expat.ParserCreate(namespace_separator=SEP)
    parser.buffer_text = True
    root = [None]
    stack = []
    ns_stack = [{}]
    pending_ns = {}

    def start_ns(prefix, uri):
        pending_ns[prefix or ""] = uri or ""

    def start(qname, attrs):
        nonlocal pending_ns
        scope = dict(ns_stack[-1])
        scope.update(pending_ns)
        ns_stack.append(scope)
        pending_ns = {}
        ns, local = _split(qname)
        a = {_split(k): v for k, v in attrs.items()}
        node = Node(ns, local, a, parser.CurrentLineNumber,
                    stack[-1] if stack else None, scope)
        if stack:
            stack[-1].children.append(node)
        else:
            root[0] = node
        stack.append(node)

    def end(_qname):
        stack.pop()
        ns_stack.pop()

    def chars(data):
        if stack:
            stack[-1].text.append(data)

    parser.StartNamespaceDeclHandler = start_ns
    parser.StartElementHandler = start
    parser.EndElementHandler = end
    parser.CharacterDataHandler = chars
    try:
        with open(path, "rb") as fh:
            parser.ParseFile(fh)
    except expat.ExpatError as e:
        raise ParseError(expat.errors.messages[e.code], e.lineno, e.offset + 1)
    if root[0] is None:
        raise ParseError("no root element", 1, 1)
    return root[0]


def walk(node):
    yield node
    for c in node.children:
        yield from walk(c)
