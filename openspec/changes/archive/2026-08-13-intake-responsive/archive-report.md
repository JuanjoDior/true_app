# Archive Report: intake-responsive

**Change**: `intake-responsive`  
**Archived to**: `openspec/changes/archive/2026-08-13-intake-responsive/`  
**Archived**: 2026-08-13  
**Status**: Complete  
**Verdict**: PASS WITH RECOMMENDATIONS

## Executive Summary

The `intake-responsive` SDD change has completed all 75 tasks across 10 phases of implementation and verification. The intake workspace now renders correctly at 360px and below without regression to the live Sala de Situación. Phase 10 added workspace-level runtime coverage for the six-section reachability scenario, closing the final blocker from generation-8 verification. All 11 requirements and 24 scenarios are compliant. Everything is committed and pushed to `main`; `lib/` and `web/` are byte-identical to HEAD — this cycle's delta is test-only. Two bounded Gentle AI reviews are approved and bound to this change, with `pre-commit` gates returning `allow`.

## Artifact Traceability

### Engram Observations (all required artifacts retrieved and recorded)

| Artifact | Observation ID | Sync ID | Timestamp | Status |
|----------|---|---|---|---|
| proposal | #439 | obs-c01b5a0e71aa9f1f | 2026-08-08 22:52:53 | active |
| spec | #441 | obs-178543dd6c8cfc80 | 2026-08-08 22:57:59 | active |
| design | #442 | obs-3fd60298cbb61f9f | 2026-08-08 23:02:42 | active |
| tasks | #443 | obs-e150fedeb6e43410 | 2026-08-08 23:07:44 | active |
| verify-report | #453 | obs-1faae3d720df50b0 | 2026-08-09 18:53:25 | active |

### Filesystem Artifacts (OpenSpec hybrid mode)

- `openspec/specs/responsive-breakpoints/spec.md` — copied from delta
- `openspec/specs/intake-responsive-layout/spec.md` — copied from delta
- `openspec/changes/archive/2026-08-13-intake-responsive/` — moved, verified by empty diff

## Final State Authority

The archive report describes the state of the change **at close**. The following hierarchy applies to reconciling sources:

1. **Native review authority** (highest): two Gentle AI reviews approved and bound (lineages `review-0b070be74363facd` and `review-b48751f74424915c`, both returned `allow` on `pre-commit` gate)
2. **Persisted tasks artifact**: `openspec/changes/archive/2026-08-13-intake-responsive/tasks.md` records 75/75 tasks checked across 10 phases
3. **Explicit final-state facts in launch prompt** (orchestrator): Phase 10 complete, everything committed and pushed, all 75 tasks done, verification generation 9 passed
4. **Intermediate snapshots** (lowest rank): `verify-report.md` (#453) is a point-in-time snapshot at verification time and carries three stale claims

### Reconciliation of Stale Claims

Per the Final-State Authority hierarchy, this section records where snapshot claims were superseded:

**Stale Claim 1 — "tasks.md has no Phase 10 entry and the work is uncommitted"**
- **Source**: `verify-report.md` (#453), generation-9 verification time (2026-08-09 18:53:25)
- **Current state** (confirmed by orchestrator): Phase 10 exists and is complete (tasks 10.1-10.8, all checked). Commits `c351fac` and `ad0fc7a` are pushed to `main`. Verification generation 9 verdict is `pass`, blockers: 0.
- **What changed**: Phase 10 added workspace-level runtime coverage for the "All six sections reachable at 360px" scenario, closing the generation-8 blocker. The test spans `test/intake_narrow_layout_test.dart:135-218` and uses `tester.dragFrom` to walk all six sections through real scroll physics, with four mutation probes recorded in `tasks.md` §10.5.
- **Evidence**: `git log` shows `c351fac` and `ad0fc7a` on `main`; the archived `tasks.md` carries Phase 10 with all eight items checked; per-phase task counts read directly from that file are 6+12+14+5+6+5+6+7+6+8 = 75.

**Stale Claim 2 — "Tasks complete 67 / Tasks incomplete 0"**
- **Source**: `verify-report.md` (#453), completeness table
- **Current state**: Tasks complete 75 / Tasks incomplete 0 (all 10 phases recorded: 6+12+14+5+6+5+6+7+6+8 = 75)
- **What changed**: Phases 5–10 were added after the initial four-phase plan. Phases 5 and 6 closed two CRITICAL blockers (missed desktop coverage, threshold bracketing instead of pinning). Phase 7 added the viewport meta guard. Phase 8 wrote the Host Document Viewport requirement. Phase 9 corrected an unfalsifiable scenario. Phase 10 added runtime walk coverage. All are recorded in the archived `tasks.md` with complete evidence trails.

**Stale Claim 3 — "Candidate Scope (independently confirmed)" table lists only four paths**
- **Source**: `verify-report.md` (#453), independently confirmed section
- **Current state**: the candidate that carried Phase 10 spanned six paths — `.gitignore`, `HANDOFF.md`, `PROJECT_CONTEXT.md`, `openspec/changes/intake-responsive/tasks.md`, `openspec/changes/intake-responsive/verify-report.md` and `test/intake_narrow_layout_test.dart`. `lib/` and `web/` are **not** among them: they are byte-identical to HEAD across this whole generation.
- **What changed**: Phase 7 touched `web/index.html` (viewport meta). Phase 10 touched `test/intake_narrow_layout_test.dart` (+153/-22). The metadata files (`HANDOFF.md`, `PROJECT_CONTEXT.md`) were updated to record verification progress and the binding of reviews. The verify-report snapshot listed scope at an earlier point in the cycle; the final scope expanded as later phases completed.
- **Note on .gitignore and out-of-scope**: The candidate picked up `.gitignore` (+3, `.claude/settings.local.json`). This is unrelated to intake-responsive scope and rode along as part of the apply-phase working tree. It is recorded here as a known out-of-scope addition that survived into the final candidate.

## Verification

### Task Completion Gate — PASSED

All 75 implementation tasks are marked checked in the archived `tasks.md`:
- Phase 1: 6/6 (Shared Breakpoints)
- Phase 2: 12/12 (Section Row Fallbacks)
- Phase 3: 14/14 (Workspace Narrow Branch)
- Phase 4: 5/5 (Test Viewport Cleanup)
- Phase 5: 6/6 (Verification Remediation — CRITICAL-1, CRITICAL-2)
- Phase 6: 5/5 (Threshold Pinning — CRITICAL-3)
- Phase 7: 6/6 (Host Document Viewport)
- Phase 8: 7/7 (Spec Remediation — two CRITICAL blockers from unfalsifiable scenario)
- Phase 9: 6/6 (Unfalsifiable Scenario Correction)
- Phase 10: 8/8 (Runtime Walk Coverage — closes generation-8 blocker)

No unchecked implementation tasks remain. The gate PASSES.

### Specs Synced — PASSED

Two new domains bootstrapped into `openspec/specs/`:
| Domain | Requirements | Scenarios | Action |
|--------|---|---|---|
| responsive-breakpoints | 4 | 8 | Created; 5762 bytes copied mechanically |
| intake-responsive-layout | 7 | 16 | Created; 5971 bytes copied mechanically |

Total: 11 requirements, 24 scenarios, counted directly from the merged specs
(`rg -c '^### Requirement:'` and `rg -c '^#### Scenario:'`). This matches
`verify-report.md` exactly: 11/11 requirements and 24/24 scenarios. There is no
discrepancy between the specs and the verification totals and none should be
explained away.

### Verification Evidence

Per orchestrator's explicit final-state facts and `verify-report.md` (#453):

- **Verdict**: PASS (per native review receipt). Generation 9 completed after Phase 10 additions.
- **Requirements**: 11/11 COMPLIANT
- **Scenarios**: 24/24 COMPLIANT
- **Blockers**: 0 (down from 1 at generation 8; Phase 10 closed it)
- **Test suite**: 170 tests pass, exit 0 (`flutter test`)
- **Analysis**: clean exit 0 (`flutter analyze`)
- **Code delta**: `lib/` and `web/` byte-identical to HEAD; test-only change
- **Review bindings**: Two approved reviews bound to this change

## Archive Contents Verified

Mechanical diff completed successfully. All artifacts present in archived folder:
- proposal.md
- exploration.md
- design.md
- tasks.md (75/75 tasks complete)
- verify-report.md
- specs/responsive-breakpoints/spec.md
- specs/intake-responsive-layout/spec.md

## Follow-ups Opened by Phase 10 (NOT closed by this change)

These are SUGGESTIONS and architectural notes recorded by bounded review and Phase 10 evidence, not blockers:

1. **`intake_narrow_layout_test.dart`: `isFullyVisible` measurement precision** (SUGGESTION from bounded review)
   - Measures against the `intake-form-column` rect rather than one derived from the scroll viewport
   - Benign today because the key sits on the `SingleChildScrollView` itself
   - Candidate for future hardening

2. **Scenario "and editable" clause coverage**
   - The scenario "All six sections reachable at 360px" includes the clause "and editable"
   - Covered only indirectly through the drag-and-readability assertions

## Known Gaps Carried Forward (NOT closed by this change)

These are pre-existing or out-of-scope items recorded for future work:

1. **Desktop band 1024–1199px untested** — Rows stack in this band by design; no test covers it
2. **Success Criteria checklist in proposal.md** — Deliberate unchecked; recorded why in Phase 8
3. **`SituationTopBar` overflow in two width bands** — Pre-existing, out of scope
4. **On-device re-triage after Phase 7 still pending** — Viewport meta fixed; device validation needed
5. **No real-browser E2E layer** — Widget tests cannot observe browser viewport negotiation
6. **Magic literals in intake_workspace_screen.dart** — `260` and `380` should become tokens in `lib/core/layout/breakpoints.dart`
7. **`.gitignore` change is out of scope** — Rode along during apply-phase working tree edits

## Durable Lessons Worth Recording

1. **`tester.scrollUntilVisible` does not prove scrollability** — It only drags while finder matches nothing. Use `tester.dragFrom` for "user scrolls" scenarios.
2. **Characterization tests can discharge behavior-preservation risk** — Phase 1 ran tests GREEN before and after migration to prove byte-identical behavior.
3. **Widget test injection of `tester.view.physicalSize` is structurally blind to browser viewport negotiation** — Verification of viewport-dependent requirements must read the host document directly.
4. **Vacuous assertions hide in shared test bodies** — First mismatch aborts; split into independent test blocks to collect evidence for all assertions.
5. **Threshold bracketing ≠ threshold pinning** — Sampling a range constrains constants to ranges; add direct equality checks to pin values.
6. **Mutation evidence requires clean trees and per-probe reversion** — Each probe on a clean tree, reverted via `git checkout --`.

## Review Authority

Two bounded Gentle AI reviews are approved and bound to this change:

1. **Review lineage `review-0b070be74363facd`** — six paths, `pre-commit` gate: `allow`
2. **Review lineage `review-b48751f74424915c`** — tasks.md edit, `pre-commit` gate: `allow`

Both reviews cleared the native post-apply verification gate.

## Spec Merge Summary

| Action | Domain | Requirements | Scenarios |
|--------|--------|---|---|
| Create | responsive-breakpoints | 4 | 8 |
| Create | intake-responsive-layout | 7 | 16 |

Both specs are complete domain-bootstrapping specs (not deltas). Mechanical copy verified by empty `diff -r` output.

## Mechanical Archive Verification

**Snapshot created**: Source folder cached before any operations  
**Archive moved to**: `openspec/changes/archive/2026-08-13-intake-responsive/`  
**Verification command**: `diff -r <snapshot> <archive>`  
**Verification result**: **PASSED** — no differences (empty diff output)

This is the mandatory readback per the Mechanical Copy Contract. An empty diff is the only passing evidence.

## SDD Cycle Complete

The `intake-responsive` change has been:
- Proposed (observation #439)
- Specified (observation #441)
- Designed (observation #442)
- Tasked (observation #443)
- Applied across the whole cycle; Phase 10 delivered in `c351fac` and `ad0fc7a`, both pushed to `main`
- Verified (observation #453, generation 9, PASS)
- Reviewed (two approved bounded reviews, both gates: `allow`)
- Archived (2026-08-13)

Ready for the next change.
