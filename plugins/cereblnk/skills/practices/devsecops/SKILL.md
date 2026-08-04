---
name: devsecops
description: How to reason about security controls in a pipeline — controls proven by planting a violation, the gap between scanned and deployed, ownership of findings. Use for pipeline security work.
---

# DevSecOps Skill

## 1. Identity
name: devsecops · domain: practices
complements: owasp-threat-modeling · github-actions · artifact-management
escalate_to: security-agent (finding severity) · compliance-agent (policy obligations)

## 2. Mission
A control nobody owns does not exist. Prove each one by planting the
violation it claims to catch.

## 3. Philosophy

**Reading requests.** "Add security scanning" hides three questions.
Which risks does this system carry, given that a scanner is not a
threat model? Who triages findings, within what deadline? What happens
when it goes red — a blocked gate, or a dashboard nobody opens?

**Where risk lives.** The pipeline itself as attack surface: build
credentials, tampering, dependency substitution. The gap between the
scanned code and the deployed artifact, where what runs is not what
was reviewed. Secrets spread across environments and manifests. Alert
fatigue converting real findings into background.

**Verification here.** Prove the control fires. Plant a known-bad
dependency, a test credential, a violating configuration, and watch
the gate block. A green pipeline proves nothing about a control that
never triggered. Then trace the artifact chain: the identity that
passed the gate is the identity that deployed.

**False-competence traps.** Tool count reported as maturity. Gates set
to the highest severity only, then exceptions granted with no expiry.
Findings aging in a dashboard with no owner. Scanning the source while
deploying an artifact built elsewhere.

**Instincts.** Every control has an owner and a deadline. Every
exception has an expiry. Prove gates by planting violations. Compare
what was scanned against what deployed, by identity.

## 4. Decision Strategy — the paths

**A control is added**
→ Name its owner and its triage deadline. An unowned control
  generates findings that nobody converts into fixes.

**A gate is configured**
→ Plant a violation and confirm it blocks. Configuration is intent;
  only a blocked build is evidence.

**An exception is granted**
→ Give it an expiry. Permanent temporary exceptions are how a gate
  becomes decoration over one quarter.

**Scanned code and deployed artifact differ**
→ Compare identities. Reviewing one artifact and shipping another is
  the failure that every control above it cannot catch.

**Secrets are configured**
→ Enumerate where they exist. Sprawl across environments and files
  makes rotation impossible and exposure permanent.

**Findings accumulate**
→ Ask which were fixed. Volume without resolution trains the team to
  scroll past the one that mattered.

**The pipeline holds credentials**
→ Treat it as production. Build systems reach everything, and their
  compromise skips every other control.

## 5. Inputs
Pipeline configuration and control definitions. Planted-violation test
results. Artifact identities at gate and at deploy. Secret locations.
Finding age and resolution data.

## 6. Outputs
ACP Response Block only. Facts labeled. Control effectiveness is
`known` only against a planted violation. A green pipeline alone
supports no control claim.

## 7. Quality Gates
- Every control names an owner and a triage deadline.
- Every gate has blocked a planted violation at least once.
- Every exception carries an expiry date.

## 8. Failure Modes
- A gate that has never blocked anything and never would.
- An artifact deployed that no scan ever examined.
- A permanent exception granted as a temporary unblock.
- Real findings scrolled past in a list nobody triages.

## Detection Table

| # | Observe | Concern |
|---|---|---|
| 1 | control with no named owner | findings never resolved |
| 2 | gate never proven with a planted violation | untested control |
| 3 | exception with no expiry | gate quietly disabled |
| 4 | scanned identity differing from deployed | review bypassed |
| 5 | secrets present in several stores | rotation impossible |
| 6 | tool count offered as maturity | activity, not assurance |
| 7 | build credentials with production reach | pipeline as attack path |

## 9. Worked Example
Claim: "dependency scanning protects us." Evidence: the gate is
configured, and no build has ever failed it. Path fires: a gate never
proven with a planted violation. Verdict: weakened (Known: gate
config; Assumed: it would block). Fix: introduce a known-vulnerable
dependency on a branch and confirm the build fails. Until then the
control is Assumed.
