# xmltools — XML/XSD create · parse · validate

Original, stdlib-only tooling (M-class). Zero third-party libraries —
fully offline/air-gap safe, same dependency discipline as `docparse/`.
Consumed through `skills/practices/xml-processing`.

| Tool | Job | Exit codes |
|---|---|---|
| `xml_parse.py [--outline] f.xml` | Well-formedness with exact line:col on failure; structure outline (root, namespaces, counts, depth, collapsed tree) | 0 ok · 1 malformed |
| `xsd_validate.py schema.xsd f.xml` | Validate an instance against an XSD (documented subset); every finding carries file:line + element path | 0 valid · 1 invalid/malformed · 2 schema refused |
| `xsd_generate.py sample.xml > draft.xsd` | Infer a DRAFT schema from a sample; output is labeled ESTIMATED in its header, inference rules stated in the tool's docstring | 0 · 1 malformed sample |

Shared core: `xmlcore.py` — line-aware, namespace-aware tree on the
stdlib expat bindings; every node carries its source line so findings
are evidence-referenced.

## Honesty rules (binding)

- **Fail-closed subset.** `xsd_validate.py` implements a practical
  XSD 1.0 subset (supported/unsupported lists in its docstring). A
  schema using an unsupported construct (import, complexContent,
  substitutionGroup, key/keyref, xs:any, ...) is **refused with the
  construct named** — never silently half-validated. "VALID" always
  means "valid within the documented subset" and says so.
- **Generated schemas are Estimated, never Known.** `xsd_generate.py`
  encodes only what one sample shows; the draft's header comment says
  exactly that, and the inference rules are printed in `--help` so the
  output is auditable.
- **Findings are evidence.** Every validation error names file, line,
  and element path — quotable directly as an ACP evidence reference.

## Verified in-container (build-time fixtures)

Valid instance accepted; planted violations each surfaced with line
refs (range, enumeration, sequence order); malformed input rejected at
exact line:col; unsupported construct refused by name; mixed content +
nested choice/unbounded groups; minOccurs=0 and optional-attribute
inference; round-trip (generated draft re-consumed by the validator).
