# Gemini CLI — compatibility notes

> Living document. Everything here is a fact about a vendor's product at
> a point in time, which is why it is not in
> `plugins/cereblnk/GEMINI.md`. That file is loaded into every session as
> instruction and should carry only what stays true; a product policy
> that changes leaves a permanent instruction file asserting something
> false, mixed in with the behavioural rules an agent is following.

## Access, as of this release

Gemini CLI stopped serving Google AI Pro, Ultra and free tiers on
18 June 2026. Access continues for Code Assist Standard and Enterprise
licences and for paid API keys. The successor is a different,
closed-source binary carrying the same capability family — skills,
hooks, sub-agents, extensions — under its own plugin format, with no
day-one feature parity per its vendor.

Whether Cereblnk follows it is CB-143.

Source: https://developers.googleblog.com/an-important-update-transitioning-gemini-cli-to-antigravity-cli/

## Feature maturity

Sub-agents are documented as a preview feature under active development.
Cereblnk's `agents/` directory is discovered here, but a preview surface
is not the same promise as a stable one, and nothing in the capability
matrix rests on it: the matrix records hook capabilities, and this host's
absent sub-agent lifecycle hook is already recorded as `declared:F`.

## Delivery, unresolved

Gemini supports extension hooks natively — `hooks/hooks.json` inside the
extension root, which is the documented and intended place for them. The
collision is ours, not the host's: that filename is already Claude Code's
binding in this repository.

Three ways out, none chosen yet (CB-143):

1. **Install-time configuration.** Hook layers are ordered project
   settings, user settings, system settings, extensions. Project settings
   outrank extension hooks, so `hooks/gemini-hooks.json` could be
   delivered into `.gemini/settings.json` rather than packaged.
2. **A host-specific distribution.** Build `dist/gemini/cereblnk/` from
   the core, where `hooks/hooks.json` is the generated Gemini binding.
   Source of truth stays single; distribution becomes host-native. This
   costs a build step and a second tree to keep honest.
3. **Ship skills and sub-agents only**, and record that the enforcement
   layer does not reach this host.

The first is cheapest to try and the second is the one that scales if a
fifth host wants the same filename. Neither is worth starting before the
access question above is settled.

## References

- Extension reference: https://geminicli.com/docs/extensions/reference/
- Hooks: https://geminicli.com/docs/hooks/
- Agent skills: https://geminicli.com/docs/cli/skills/
- Writing extensions: https://geminicli.com/docs/extensions/writing-extensions/
