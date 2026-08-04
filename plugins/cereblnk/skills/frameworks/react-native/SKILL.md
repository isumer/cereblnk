---
name: react-native
description: How to reason about React Native — two platforms behind one API, a bridge that makes chatter expensive, and a device that is not the simulator. Use for React Native work. Constraints in rules/frameworks/react-native/.
---

# React Native Skill

## 1. Identity
name: react-native · domain: frameworks
requires: react
complements: accessibility
escalate_to: performance-engineering (frame budget and startup)

## 2. Mission
One API, two platforms, and a real device that behaves like neither
simulator. Name which one a claim is about.

## 3. Philosophy

**Reading requests.** "It works on my simulator" is not a claim about
either platform. Startup, memory pressure, keyboard behavior and
permissions all differ on hardware. "Make the list smooth" is a frame
budget question, and the answer is usually fewer re-renders rather than
faster ones.

**Where risk lives.** Platform divergence hidden behind a shared
component, so one side is untested. Crossing between JavaScript and
native per item, which turns a list into a stall. Permissions and
secrets, since a mobile bundle is readable on a rooted device. And
navigation state that survives a background and resume.

**Verification here.** A behavior claim names its platform and its
device class. A performance claim cites a frame or startup measurement
on hardware, never a simulator. A permission claim is verified in the
denied case, because the granted path is the one everyone tests.

**False-competence traps.** A platform check spreading through
components instead of sitting behind one boundary. A list built without
virtualisation because the sample had twenty rows. A secret in the
bundle, treated as hidden. An animation driven from JavaScript on every
frame.

**Instincts.** Isolate platform differences at one boundary. Virtualise
every list that can grow. Drive animation natively where the API allows.
Test the denied permission and the resumed app, not only the happy
launch.

## 4. Decision Strategy — the paths

**A behavior differs by platform**
→ Put the difference behind one boundary. Checks spread through
  components leave one side untested.

**A list can grow**
→ Virtualise it, with a stable key. A sample of twenty rows proves
  nothing about a thousand.

**Work happens per item or per frame**
→ Count the crossings between JavaScript and native. Chatter is the
  cost, not the individual call.

**A permission is required**
→ Handle the denied and revoked cases explicitly. The granted path is
  the one everyone already tested.

**A secret is needed on the device**
→ Assume the bundle is readable. What must stay secret stays on a
  server.

**The app is backgrounded**
→ Decide what survives resume: navigation state, timers, sockets,
  in-flight requests.

**An animation is added**
→ Drive it natively where the API allows. A frame-by-frame update from
  JavaScript competes with rendering.

## 5. Inputs
Component source with line refs. Platform-specific branches. Frame and
startup measurements on hardware, by platform. Permission handling
paths. Navigation state on resume.

## 6. Outputs
ACP Response Block only. Facts labeled. A performance claim is `known`
only against a device measurement, and names the platform. Simulator
results are `estimated` and say so.

## 7. Quality Gates
- Every platform difference sits behind one named boundary.
- Every growable list is virtualised with a stable key.
- Every permission has a tested denied path.

## 8. Failure Modes
- One platform shipped untested behind a shared component.
- A list stalling on a device that was smooth in a simulator.
- A secret extracted from the bundle.
- Navigation state lost on resume, returning the user to the start.

## Constraints

Enforceable form lives in `${CLAUDE_PLUGIN_ROOT}/rules/frameworks/react-native/`.
Run `${CLAUDE_PLUGIN_ROOT}/scripts/select-rules <path>` for the files
the task touches; it returns the constraint files to read, applying both
the glob and the stack gate. Read `rules/common/` once per run. Cite a
violated constraint by file and section. Selection rules:
agent-selection-policy §4b.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | a platform check inside a component | one side untested |
| 2 | a growable list without virtualisation | stall on a device |
| 3 | work per item crossing to native | bridge chatter |
| 4 | a permission with no denied path | untested refusal |
| 5 | a secret in the bundle | readable on device |
| 6 | an animation driven from JavaScript | competes with rendering |
| 7 | a measurement from a simulator | not a device claim |

## 9. Worked Example
Claim: "the feed scrolls smoothly." Evidence: the measurement came from
a simulator and the list renders every row. Two paths fire: a growable
list without virtualisation, and a simulator measurement. Verdict:
weakened (Known: component and measurement conditions). Fix: virtualise
the list, then measure frames on the lowest device class supported.
