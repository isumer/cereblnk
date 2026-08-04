---
name: scss
description: How to reason about Sass — a source that is not the output, a module system replacing a deprecated global one, and variables that resolve before the browser sees them. Use for .scss or .sass work. Constraints in rules/languages/scss/.
---

# SCSS Skill

## 1. Identity
name: scss · domain: languages
requires: css
complements: angular · vue · react
escalate_to: css (cascade and containment) · accessibility (perception and focus)

## 2. Mission
The source is not the output. Every preprocessor question is a
question about the CSS it compiles to.

## 3. Philosophy

**Reading requests.** "Make this a mixin" hides the output question.
Does it duplicate declarations, or rewrite selectors? "Theme it with a
variable" hides a harder one. A Sass variable resolves at build time.
Nothing at runtime can reach it.

**Where risk lives.** In the loading layer. The deprecated import rule
runs a file again at every import site. It emits that file's CSS again
too. One partial, five importers, five copies. Everything also lands
in a single global namespace. No reader can tell where a member came
from. Then the extend rule, which rewrites selectors globally. And
nesting, where source depth becomes output specificity unseen.

**Verification here.** Read the compiled CSS, not the source. A
duplication claim is checked by finding the repeated block in the
output. A specificity claim is checked against the emitted selector.
How deep the nesting looked is not evidence. A theming claim is
checked by naming what changes the value at runtime.

**False-competence traps.** A Sass variable behind a switch the user
operates. An extend reaching selectors nobody intended, because extend
is global. Nesting that mirrors the markup and emits selectors no one
would write by hand. Migrating imports one warning at a time, leaving
both loading systems live.

**Instincts.** Load with the module system, never the deprecated
import. Custom properties for what runtime decides, Sass variables for
what the build decides. Mixins over extend when in doubt. Assume every
nesting level costs specificity.

## 4. Decision Strategy — the paths

**A partial is loaded**
→ Use the module system. The import rule re-emits the file per
  importer, and it is removed in the next major release.

**A member's origin is unclear**
→ Namespace it at the load site. Global members leave provenance
  unknowable to readers and tools alike.

**A value must change at runtime**
→ Use a custom property. Sass variables are gone before the browser
  parses the stylesheet.

**Shared declarations are needed**
→ Reach for a mixin. Extend rewrites selectors globally, and its blast
  radius is not local to the call.

**Nesting passes three levels**
→ Flatten it. Depth in the source is specificity in the output, and
  the cascade reads the output.

**A build warns about deprecation**
→ Migrate the loading layer, not the single warning. Half-migrated
  files keep both namespaces alive at once.

**A global built-in function is called**
→ Load it from its module instead. These follow the import rule out of
  the language on the same timeline.

## 5. Inputs
The source and the compiled CSS. The loading graph: which file loads
which. Deprecation warnings from the build. The runtime theming
requirement, if any. Emitted selectors for every specificity claim.

## 6. Outputs
ACP Response Block only. Facts labeled. A duplication or specificity
claim is `known` only against compiled output. Reading the source
yields `derived`.

## 7. Quality Gates
- Every specificity claim cites the emitted selector.
- Every duplication claim cites the compiled output.
- Every runtime-switched value is a custom property.

## 8. Failure Modes
- A partial emitted once per importer, inflating the bundle.
- A theme that cannot switch, because its values compiled away.
- An extend pulling unrelated selectors into a rule.
- A selector too specific to override, grown from unread nesting.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/languages/scss/`:
`coding-style` · `patterns`.

Before producing or reviewing stylesheets, read the files whose
`paths:` glob matches what the task touches, plus `rules/common/` once
per run. Cascade constraints stay in `rules/languages/css/`. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | the deprecated import rule | duplicate emission, global scope |
| 2 | a member used without a namespace | provenance unknown |
| 3 | a Sass variable behind a runtime switch | compiled away |
| 4 | extend used for shared declarations | global selector rewrite |
| 5 | nesting past three levels | specificity grown from depth |
| 6 | a specificity claim from source depth | output unread |
| 7 | both loading systems in one build | migration half done |
| 8 | a global built-in function call | removed on the same timeline |

## 9. Worked Example
Claim: "the theme switch is wired, the colours are variables."
Evidence: the colours are Sass variables, resolved at build time. Path
fires: a value that must change at runtime. Verdict: refuted (Known:
compiled output, file#L). The emitted CSS carries literal colours, and
no switch reaches them. Fix: move themed values to custom properties.
Keep Sass variables for the build-time scale.
