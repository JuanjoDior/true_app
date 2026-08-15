# Archive Report: case-publication-detail

**Archived**: 2026-08-15
**Archived to**: `openspec/changes/archive/2026-08-15-case-publication-detail/`
**Artifact store mode**: hybrid (filesystem + Engram)
**Status at close**: complete, delivered, deployed, verified.

This report is the terminal record of the cycle. It describes the state **at
close**, not the state at any intermediate snapshot.

---

## 1. Gates

| Gate | Result | Evidence |
| --- | --- | --- |
| Native review receipt | **Not applicable** | `reviewGate` is structurally absent — receipt-driven development was never started for this candidate. Archive proceeds under ordinary repository policy. No receipt was sought or manufactured. |
| Action context | **Normal repo work** | Not `workspace-planning`. All operations stayed inside the repository. |
| Verification | **PASS WITH RECOMMENDATIONS** | 0 CRITICAL, 0 blockers, 5 WARNING, 4 SUGGESTION. 23/23 requirements, 48/48 scenarios compliant. |
| Task completion | **Pass** | 120 checked. 11 unchecked rows, all legitimately unchecked — see §4. No checkbox was reconciled, edited, or tidied by this phase. |
| Mechanical copy readback | **Pass** | Every `diff -r` empty. See §6. |

### Verify gate detail

`sdd-verify` returned **FAIL with 3 CRITICAL** on its first pass. Not one was an
implementation defect: every requirement was implemented and the deployment was
real. All three were **evidence quality**, and all three were the same species as
the defect this cycle existed to eliminate — assertions that could not fail:

| # | Defect in the evidence | Remediation |
| --- | --- | --- |
| C-1 | `case_detail_page_test.dart` scrolled with `position.jumpTo`, which calls `forcePixels` and bypasses `applyBoundaryConditions` / `applyPhysicsToUserOffset`. It passed against a dead scroll — while the specs declared programmatic helpers inadmissible in writing. | Replaced with `_dragUntilVisible`, a real `dragFrom` gesture. |
| C-2 | "Expanded dossier is usable on desktop" was **untested**. All four responsive tests used `Size(360, 780)`; the harness default height of 2400 never overflows. | New desktop reading group at 1440x900: no overflow, bounded reading column, real scroll, reachable return. |
| C-3 | The directory asserted `maxScrollExtent > 0` and stopped — half an assertion. Nothing proved anything was *reachable*. | New `dragging reaches a case near the end of a long archive`, with a `ListView.builder`-appropriate absence precondition. |

Remediated **test-only** in `645334c` and `7c7c2d4`; `git diff` confirms zero
files under `lib/` in either. The re-verification pass did not accept those
claims: **the verifier reproduced both mutation probes independently**.

- **P1** — `NeverScrollableScrollPhysics` injected into `CaseDetailPage`'s
  `SingleChildScrollView`: exactly 2 tests fail, both on the *reachability*
  assertion (`Expected <780, Actual 3467.0` and `Expected <900, Actual 1697.0`).
  Content did not move at all.
- **P2** — the same injected into the directory's `ListView.builder`: exactly 1
  test fails (`Found 0 widgets with text Caso 0`).
- Under the old `jumpTo` implementation those same probes passed green. **That
  contrast, not the passing suite, is the evidence.**

A precondition subtlety worth preserving: `expect(x, findsNothing)` before
scrolling is **honest for the directory and dishonest for the dossier**. A
`ListView.builder` genuinely has not built distant rows; a `SingleChildScrollView`
lays its single child against an unbounded main-axis constraint and builds
everything regardless of offset, so there the precondition must be
position-based. Same words, opposite meaning, depending on the widget.

---

## 2. Final state at close

| Fact | Value | Source |
| --- | --- | --- |
| HEAD | `7c7c2d4` | repository |
| Branch | `main`, working tree clean before archive | repository |
| `flutter test` | **477/477**, exit 0 | orchestrator final-state facts, corroborated by verify-report #519 |
| `flutter analyze` | clean, exit 0 | same |
| Baseline | `182003a` | repository |
| `assets/data/cases.json` | **untouched** for the whole cycle | `git log --oneline 182003a..HEAD -- assets/data/cases.json` returns 0 commits |
| Deployed | https://juanjodior.github.io/true_app/ at SHA `89cb790f2a26d31b8821b3bc00af4cc6449997de`, Pages run 31833902940, `success` | Unit 9 evidence |

### Deployment currency — stated precisely

The deployed SHA `89cb790` **predates HEAD**. Four commits landed after it:

| Commit | Kind | Paths |
| --- | --- | --- |
| `56f6ec3` | docs | `openspec/changes/case-publication-detail/tasks.md` |
| `0c90162` | docs | `HANDOFF.md`, `PROJECT_CONTEXT.md` |
| `645334c` | test-only | `test/case_detail_page_test.dart`, `test/case_directory_test.dart`, two openspec artifacts |
| `7c7c2d4` | test-only | `test/case_directory_test.dart`, one openspec artifact |

`git diff --name-only 89cb790..HEAD -- lib/ web/ assets/` returns **zero files**.
The deployed behaviour is therefore current — but the deployment does **not**
include those four commits, and no claim here should be read as saying it does.

---

## 3. Recorded contradictions (not resolved silently)

Two statements in the archive launch prompt are not corroborated by repository
evidence. Both are recorded rather than resolved in either direction; neither
affects any gate.

1. **Commit count.** The launch prompt states "Thirteen commits, `e1e350d`
   through `7c7c2d4`". Repository: `git rev-list --count 182003a..HEAD` = **14**,
   and `git log --oneline 182003a..HEAD` lists 14 commits with `e1e350d` oldest
   and `7c7c2d4` newest. `git rev-list --count e1e350d..7c7c2d4` = **13**, i.e.
   thirteen is correct only for the exclusive range that omits `e1e350d` itself.
   The inclusive span `e1e350d`→`7c7c2d4` is fourteen commits.
2. **Commits after the deployed SHA.** The launch prompt states the deployed SHA
   predates "the final three commits (`645334c`, `7c7c2d4` and the docs commit)".
   Repository: `git rev-list --count 89cb790..HEAD` = **4**, and there are **two**
   docs commits (`56f6ec3`, `0c90162`), not one. The substantive claim — that
   nothing under `lib/` changed since the deployed SHA — **is** corroborated.

---

## 4. Unchecked rows — legitimate, deliberate, and preserved

11 rows remain `- [ ]`. Every one of them is correct as it stands. This phase
performed **no** stale-checkbox reconciliation and edited `tasks.md` not at all.

### 9.10 — deliberately unchecked

"Prove responsive directory/detail" is **PARTIAL, declared not fabricated**. Wide
desktop was verified in-browser; the directory opens from the rail and lists every
case year-descending with the two 2007 cases correctly tie-broken by title.
**Compact mobile was never verified in a real browser**: `resize_window` does not
reach Flutter's viewport in this setup — `window.innerWidth` stays at 1920
regardless. Compact coverage is automated tests at 500px and 360px only.

Checking this row would falsify the record. Task 9.14 ("Fail safely — nothing
fabricated") explicitly depends on it staying unchecked, and the verifier
confirmed it is still honestly recorded rather than silently resolved.

### RB.0–RB.9 — rollback checkpoints, not work

These are the withdrawal plan. They are unmarked because **no rollback happened**:
the cycle was delivered and deployed. `tasks.md` states this explicitly above the
list. They would be marked only if the change ever had to be undone.

### Quoted history

Lines under the headings `Original task list follows.` and `Original task text:`
are `> -` block quotes preserving superseded task wording. They carry no checkbox
and are not tasks.

**Every actual implementation task is checked.**

---

## 5. What this cycle actually cost and taught

The value of this record is in the following; do not flatten it.

### Three production defects, none caught by the test suite

1. **`situation_map_stage` crashed with `LateInitializationError` on every deep
   link.** It moved the camera from `onMapReady` guarded only by `_ready`, but
   `onMapReady` fires even when the Situation Room is **offstage underneath a
   route**, while flutter_map's interactive viewer only initialises when actually
   painted. The guard became `_canMoveCamera`, which also requires the widget to
   be mounted with a non-empty size. Without this fix the routes could not be
   activated at all.
2. **No deep link worked in the built app.** `TrueCrimeApp` always passed an
   explicit `routeInformationProvider` seeded from `initialLocation ?? '/'`, and
   `initialLocation` exists only for tests. In production the app ignored the
   address bar and started at `/`: opening `#/casos/zodiac` landed on the
   Situation Room with the hash wiped. **All 431 tests passed** because every one
   of them passed that parameter — the seam added for testability was the thing
   hiding the bug. Fixed in `89cb790` by passing `null` unless a test supplies a
   location, with two new tests (null-by-default plus its presence twin).
3. **`SituationTopBar` already overflowed in measured bands** — 21px at 980,
   1.2px at 1000, 59 to 9.4px across 1030–1080 — tolerated by an explicit
   `overflowingWidths` list. Raising `topBarFull` from 980 to 1040 for the
   directory entry point trimmed the metrics exactly where the row ran out of
   room; **every measured width now pumps clean** and the list is empty, so any
   overflow anywhere is now a regression. Declared cost: between 980 and 1040 the
   top-bar metrics no longer show. Metrics are decorative; the archive entry point
   is functional, and between 880 and 1100 there is no rail to put it in.

Defects 1 and 2 were revealed **only by mounting the whole application**. Widget
tests could not have found either.

### Unit 7 is formally REOPENED

Task 9.12 required Unit 9 to change zero source lines. Browser verification found
defect 2 above, so one source file changed in `89cb790` and **Unit 7 is reopened
by 9.12's own rule**. Recorded, not waived.

### Unit 7 exceeded the 1500-line ceiling

Measured **489 changed + 1,077 new = 1,566 lines**, over the ceiling. Declared
with reasoning rather than hidden: the overrun is 819 lines of new tests against
258 of source, and the unit was already at its last indivisible seam — the detail
page cannot ship without the slug provider, and activating the router without the
page would put a broken route in production. The forecast of "maximum 360" was
wrong by a factor of four; that is a planning error, recorded, not a reason to
under-test.

### Seven design deviations, all recorded in `tasks.md`

The verifier confirmed all are accurately described and none silently dropped.
Principal ones: `DossierPresentation` deferred from 4b to Unit 7 (the design named
it but never defined it — adding it early would have shipped an untested branch);
`CaseDossierPanelMode` renamed `CaseDossierMode` (it is carried by the content as
well as the panel); map chrome gated by `mode` rather than by nullable callbacks
(preview must suppress back/star/share/follow **and** recenter as a set, and
per-callback nullability would have made that four decisions that can disagree);
task 4.4's chain assertion half-moved to 4c (it cannot go green in 4b, and no
sub-unit may reach its commit gate with a knowingly red test); and two hosts
deliberately **not** migrated (`situation_side_panel.dart` and `home_page.dart`
are pure map hosts — migrating them would mean writing the default and changing
nothing; ceremony is not evidence).

---

## 6. Mechanical archive operations — readback evidence

All copies and moves used the shell only (`cp`, `mv`, `git mv`). No artifact
content passed through model Read/Write. `diff -r` output was empty in every case;
an empty diff is the only passing evidence.

### 6.1 Spec merge — four NEW capabilities

Main specs held two capabilities from the previous cycle (`intake-responsive-layout`,
`responsive-breakpoints`). None of the four delta specs targets an existing
capability: each is a full spec for a new capability containing only
`## Purpose` / `## Requirements`, with no `ADDED` / `MODIFIED` / `REMOVED` /
`RENAMED` delta sections. The merge therefore **added four new directories and
modified no existing spec**. Nothing was destructive; `rules.archive`
("Warn before merging destructive deltas") had nothing to warn about.

```
=== diff -r .../specs/case-editorial-chapters/spec.md openspec/specs/case-editorial-chapters/spec.md ===
(no differences)
=== diff -r .../specs/case-publication-route/spec.md openspec/specs/case-publication-route/spec.md ===
(no differences)
=== diff -r .../specs/expanded-case-dossier/spec.md openspec/specs/expanded-case-dossier/spec.md ===
(no differences)
=== diff -r .../specs/published-case-directory/spec.md openspec/specs/published-case-directory/spec.md ===
(no differences)
FINAL_PLACEMENT_STATUS=0
```

Requirement totals per capability: `case-editorial-chapters` 7,
`case-publication-route` 5, `expanded-case-dossier` 6,
`published-case-directory` 5 — **23 total**, matching the verifier's 23/23.

### 6.2 Archive move

Performed with `git mv`, verified against a recursive `cp -R` snapshot taken
**before** the move, with the source confirmed gone before comparison.

```
MOVED_WITH=git mv
=== diff -r /tmp/sdd-archive.OqLIUI/source openspec/changes/archive/2026-08-15-case-publication-detail ===
(no differences)
ARCHIVE_DIFF_STATUS=0
```

`archive-report.md` (this file) is additive and did not exist in the source
snapshot, so it is excluded from that comparison by contract.

### 6.3 Post-archive structure

- `openspec/changes/` now contains only `archive/`.
- `openspec/specs/` holds six capabilities: the two prior plus the four merged here.
- Archived folder contains `proposal.md`, `design.md`, `tasks.md`,
  `exploration.md`, `verify-report.md`, `specs/` (4 domains), and this report.

---

## 7. Carried forward — open items at close

These close the cycle **as declared gaps**, not as pending work inside it.

| # | Open item | Why it is open |
| --- | --- | --- |
| 1 | **Compact-mobile browser verification (task 9.10)** | Never verified in a real browser. `resize_window` does not reach Flutter's viewport; `window.innerWidth` stayed 1920. Automated coverage exists at 500px and 360px only. |
| 2 | **Two entry-point clicks not actuatable** | The top-bar directory button and the detail page's return action could not be actuated by coordinate against Flutter's canvas. They are covered by widget tests and are explicitly **not** claimed browser-verified — nor claimed broken. |
| 3 | **Unit 7 reopened** | By task 9.12's own rule, because Unit 9 had to change one source file. |
| 4 | **Unit 7 line overrun** | 1,566 measured against a 1500 ceiling. Declared. |
| 5 | **`createDraft` id collision** | `createDraft` derives its id from `DateTime.now().millisecondsSinceEpoch`, so two creations inside the same millisecond collide on `draftId`. Found while triangulating Unit 3, **logged not fixed** — out of scope for D4 (serialization). A real defect that belongs to its own change. |
| 6 | **Remaining SUGGESTION from verify** | `_dragUntilFound` proves the row was *built* (within ~250px cache extent), not strictly visible; could be tightened with a `getRect().top` check to match the dossier helper. |

---

## 8. Artifact traceability

| Artifact | Location |
| --- | --- |
| proposal | `openspec/changes/archive/2026-08-15-case-publication-detail/proposal.md` |
| design | `.../design.md` |
| tasks | `.../tasks.md` |
| exploration | `.../exploration.md` |
| delta specs (4) | `.../specs/{case-editorial-chapters,case-publication-route,expanded-case-dossier,published-case-directory}/spec.md` |
| verify-report (file) | `.../verify-report.md` |
| **verify-report (Engram)** | topic `sdd/case-publication-detail/verify-report`, **observation id 519**, type `architecture`, project `true_app` |
| archive-report (file) | `.../archive-report.md` (this file) |
| archive-report (Engram) | topic `sdd/case-publication-detail/archive-report` |

Planning artifacts (`proposal`, `design`, `tasks`, `exploration`) were never
persisted to Engram in this cycle — `openspec/config.yaml` records the deliberate
switch to file-based artifacts, because Engram artifacts leave no repository trace
and an in-flight cycle once stayed invisible for three weeks after the project
directory was moved. Artifacts travel with the repo. Observation id **519** is the
only Engram artifact id for this change prior to this report.

---

## 9. Delivery note

The archive operations are left **uncommitted** in the working tree at the
maintainer's explicit instruction. Staged renames (`git mv`) plus four untracked
spec directories plus this report await review and commit.

## SDD Cycle Complete

Planned, implemented under strict TDD, verified (with one FAIL and a genuine
remediation on the way), deployed, browser-verified where the tooling allowed,
and archived. Open items above are declared gaps carried forward, not unfinished
work inside this change.
