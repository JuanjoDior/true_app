# Tasks: Public Case Publication Detail

> **Planning complete; apply unblocked (2026-08-13).**
>
> `intake-responsive` was archived on 2026-08-13 with `blockers: 0`, and its
> six-section `test/intake_narrow_layout_test.dart` baseline is committed on
> `main` in `c351fac`. Unit 0 below is the evidence step for that gate: work it
> first and record what you actually observe, rather than inheriting these
> claims. Everything after Unit 0 is authorised once its checks pass.

## Review Workload Forecast

| Field | Value |
| --- | --- |
| Estimated changed lines | **1,450–2,100 aggregate**, including tests |
| 400-line budget risk | High |
| Chained PRs recommended | No |
| Suggested split | Direct-main Units 1–8; no PRs |
| Delivery strategy | Direct commits to `main` in bounded work units |

Decision needed before apply: No

Chained PRs recommended: No

400-line budget risk: High

Delivery is already approved as direct commits to `main`, so no workload decision remains. The `intake-responsive` archive and baseline checks remain an independent apply blocker.

| Unit | Forecast including tests | Maximum | Review boundary |
| --- | ---: | ---: | --- |
| 0 | 0 source lines | 0 | Dependency evidence only |
| 1 | 150–220 | 220 | Dormant chapter domain and draft representation |
| 2 | 170–240 | 240 | Publication and catalog compatibility |
| 3 | 130–180 | 180 | Serialized persistence and preview projection |
| 4 | 260–350 | 350 | Shared dossier extraction and host contracts |
| 5 | 150–220 | 220 | Seven-section editor activation |
| 6 | 180–250 | 250 | Dormant Router API foundation |
| 7 | 260–360 | 360 | Router activation and complete detail page |
| 8 | 170–240 | 240 | Published-case directory |
| 9 | 0 source lines | 0 | Verification, deployment, and browser evidence |

The source-bearing forecast is 1,470–2,060 lines. Every source-bearing unit is forecast below 400 changed lines.

## Execution Rules

Execute Units 0–9 strictly in order. Units 1–4 are dormant prerequisites; they MUST NOT expose the chapter editor. Unit 5 alone activates the seventh intake section. Unit 6 MUST remain dormant. Unit 7 activates routing only after every detail state and the complete known-case page exist.

For every new behavior:

1. Write the focused behavior test before production implementation.
2. Run it and record the exact command, expected failure, and why it proves the behavior is missing.
3. Implement only enough behavior to make that same test pass.
4. Record GREEN from the same focused test.
5. Triangulate edge cases.
6. Refactor, normalize, and run the broader suite.

A test observed only GREEN is invalid evidence for new behavior. Characterization tests may begin GREEN only when preserving existing behavior during the Unit 4 extraction.

Tests involving `flutter_map` or animated home widgets MUST use bounded pumps such as `await tester.pump(const Duration(milliseconds: 400))`; they MUST NOT use `pumpAndSettle`. Responsive tests use realistic widths, including 360px intake, compact mobile, and wide desktop.

For every source-bearing unit:

1. Record the unit-start SHA.
2. Normalize all source before candidate freeze.
3. Enumerate exact paths with `git status --short`.
4. Count additions plus deletions from `git diff --numstat <unit-start-sha>`, including untracked files.
5. Record actual lines in apply progress.
6. If the total is **400 or more**, stop before review, staging, commit, or push and split the unit.
7. Review only normalized bytes. Any later byte, path, or mode change invalidates that candidate.
8. Keep tests with the behavior they verify.

Accepted units are committed directly to `main` with Spanish conventional commit messages, no AI attribution, and no PR.

## Unit 0 — Resolve the Apply Block and Re-read the Baseline

**Depends on:** legitimate completion of `intake-responsive`.

**Finish state:** archived dependency, committed baseline, synchronized `main`, and reconciled post-archive plan are evidenced.

- [ ] **0.1 Confirm legitimate archive.** Require authoritative native/OpenSpec archive state with no blocker or unresolved review transition.
- [ ] **0.2 Confirm archived bytes on `main`.** Verify final commit is an ancestor of local and `origin/main`.
- [ ] **0.3 Confirm the six-section baseline.** Read `main:test/intake_narrow_layout_test.dart` and verify its runtime test reaches all six sections at 360px in order.
- [ ] **0.4 Require a clean ownership boundary.** The baseline test MUST be committed and unmodified. Otherwise stop without stashing, resetting, staging, moving, or editing it.
- [ ] **0.5 Synchronize safely.** Fetch and fast-forward to exact post-archive `main`.
- [ ] **0.6 Re-read archived seams.** Inspect draft model/providers, exporter, intake registry/workspace/preview, dossier panel, home page, responsive baseline test, and every additional path changed by `intake-responsive`.
- [ ] **0.7 Reconcile planning.** Return to design/tasks if archived bytes invalidate a seam or forecast.
- [ ] **0.8 Persist gate evidence.** Record archive identity, baseline SHA, main SHA, clean-path proof, and re-read findings.

**Verification:** evidence only; do not run this change’s tests.

## Unit 1 — Dormant Chapter Domain and Draft Representation

**Depends on:** Unit 0.

**Finish state:** chapter data round-trips through drafts without an authoring surface.

- [ ] **1.1 RED — Chapter codec.** Add `test/case_chapter_codec_test.dart` for exactly four types, fixed order, whitespace meaningfulness with verbatim preservation, absent/null/non-array input, malformed entries, unsupported types, and duplicate policy.
- [ ] **1.2 RED — Draft compatibility.** Add `test/case_draft_chapters_test.dart` for legacy JSON, chapter round-trip, empty omission, and preservation of existing fields.
- [ ] **1.3 Observe RED** from missing domain/draft behavior.
- [ ] **1.4 GREEN — Domain.** Add `case_chapter.dart` with fixed enum, immutable value objects, tolerant codec, ordering, `contentFor`, and `withContent`.
- [ ] **1.5 GREEN — Draft.** Add default-empty chapters and additive JSON handling to `CaseDraft`.
- [ ] **1.6 Observe GREEN** on the same focused tests.
- [ ] **1.7 TRIANGULATE** malformed-entry, duplicate, ordering, and whitespace vectors.
- [ ] **1.8 REFACTOR and verify** with `flutter test` and `flutter analyze`.
- [ ] **1.9 Apply line-budget gate.** Split at 400 or more lines.
- [ ] **1.10 Review and deliver** as `feat(casos): incorpora el modelo de capítulos editoriales`.

**Rollback:** restore the original draft schema and remove only dormant chapter types/tests.

## Unit 2 — Publication and Catalog Compatibility

**Depends on:** Unit 1.

**Finish state:** published JSON supports chapters without changing the asset or manual workflow.

- [ ] **2.1 RED — Export/read-back.** Add `test/case_publication_chapters_test.dart` for ordered meaningful export, empty omission, verbatim content, and `TrueCrimeCase.fromJson(draftToCaseJson(...))`.
- [ ] **2.2 RED — Catalog tolerance.** Add `test/local_cases_repository_chapters_test.dart` for legacy entries, valid chapters around malformed optional entries, unsupported/duplicates, and malformed core errors.
- [ ] **2.3 Observe RED** from missing published-model/export support.
- [ ] **2.4 GREEN — Published model.** Add default-empty tolerant chapters to `TrueCrimeCase`.
- [ ] **2.5 GREEN — Exporter.** Export only meaningful ordered chapters; omit `chapters` when empty.
- [ ] **2.6 Preserve fail-fast core errors.** Never silently omit a malformed core case.
- [ ] **2.7 Prove manual boundary.** Export MUST NOT write the catalog, deploy, or add a backend.
- [ ] **2.8 Observe GREEN** on focused tests.
- [ ] **2.9 TRIANGULATE** mixed legacy/chapter-bearing fixtures.
- [ ] **2.10 REFACTOR and verify** full tests/analyze.
- [ ] **2.11 Apply line-budget gate.** Include fixtures and tests.
- [ ] **2.12 Review and deliver** as `feat(casos): publica capítulos con compatibilidad de catálogo`.

**Rollback:** leave Unit 1 dormant draft data intact; restore previous published/export behavior and keep `assets/data/cases.json` unchanged.

## Unit 3 — Serialized Persistence and Preview Projection

**Depends on:** Unit 2.

**Finish state:** dormant chapter edits persist in order and reach preview data without a visible editor.

- [ ] **3.1 RED — Serialized mutations.** Add delayed fake-store tests proving adversarial completion cannot overwrite newer combined values.
- [ ] **3.2 RED — Queue recovery.** Prove one failed save reports its error while later mutations still persist.
- [ ] **3.3 RED — Preview projection.** Prove meaningful chapters, order, and clearing reach `draftPreviewCaseProvider`.
- [ ] **3.4 Observe RED** from stale-write and missing-projection behavior.
- [ ] **3.5 GREEN — Persistence queue.** Serialize create/update/edit/delete snapshots while publishing latest state synchronously and keeping queue usable after failure.
- [ ] **3.6 GREEN — Projection.** Project chapters without exposing an intake field.
- [ ] **3.7 Observe GREEN** on the same focused tests.
- [ ] **3.8 TRIANGULATE** operation ordering, rapid edits, clearing, and failure recovery.
- [ ] **3.9 REFACTOR and verify** full tests/analyze.
- [ ] **3.10 Apply line-budget gate.** Split at 400 or more lines.
- [ ] **3.11 Review and deliver** as `fix(casos): serializa la persistencia de borradores`.

## Unit 4 — Shared Dossier Content and Host Contracts

**Depends on:** Unit 3.

**Finish state:** one renderer serves map/preview contracts and can render dormant chapter data; no editor is exposed.

- [ ] **4.1 CHARACTERIZE** existing panel, side-panel, mobile dossier, and intake preview behavior. GREEN characterization cannot prove new behavior.
- [ ] **4.2 RED — Shared content.** Add `case_dossier_content_test.dart` for metadata, summary, chapters once/in order, photos, timeline, sources, related cases, optional omission, and legacy cases.
- [ ] **4.3 RED — Source overrides and modes.** Prove null/empty/grouped override semantics and map/preview chrome separation.
- [ ] **4.4 RED — Composition/callbacks.** Prove map callbacks and the required `IntakePreviewPanel → CaseDossierPanel(preview) → CaseDossierContent` chain.
- [ ] **4.5 Observe RED** for missing contracts.
- [ ] **4.6 GREEN — Add contracts.** Add chapter labels, `DossierSourceGroup`, and `CaseDossierContent`.
- [ ] **4.7 GREEN — Refactor panel.** Add map/preview modes, callbacks, source overrides, and shared composition.
- [ ] **4.8 GREEN — Preserve host ownership.** Inject actions from side panel/home/preview and remove only duplicated preview source rendering.
- [ ] **4.9 Observe GREEN** on new and characterization tests.
- [ ] **4.10 TRIANGULATE** override states, legacy/partial chapters, callbacks, preview suppression, and group order.
- [ ] **4.11 REFACTOR and verify** full tests/analyze.
- [ ] **4.12 Apply line-budget gate.** Forecast maximum 350; split at 400.
- [ ] **4.13 Review and deliver** as `refactor(casos): comparte el contenido del expediente`.

## Unit 5 — Activate the Seven-Section Chapter Editor

**Depends on:** Units 1–4 and committed Unit 0 baseline.

**Finish state:** the seventh section follows `Fotografías`, and edits update shared preview.

- [ ] **5.1 RED — Change registry expectation first.** Update `test/intake_narrow_layout_test.dart` from six to seven sections and assert `Capítulos` after `Fotografías`; do not create/register the section yet.
- [ ] **5.2 Observe mandatory registry RED** because only six sections exist.
- [ ] **5.3 RED — Fixed editor.** Add `chapters_section_test.dart` for four fields, fixed order, no arbitrary controls, stable draft/type keys, switching, editing, and clearing.
- [ ] **5.4 RED — Live activation.** Add `intake_chapter_preview_test.dart` for current-state transformations, rapid edits without pumps, shared preview order, and no map chrome.
- [ ] **5.5 Observe editor/preview RED** before creating the section.
- [ ] **5.6 GREEN — Editor.** Add fixed four-field `ChaptersSection` using current-state transformations.
- [ ] **5.7 GREEN — Registry.** Register it immediately after `Fotografías`.
- [ ] **5.8 Observe GREEN** on registry, editor, and preview tests.
- [ ] **5.9 TRIANGULATE** partial/whitespace content, switching, rapid edits, 360px reachability, and absence of arbitrary controls.
- [ ] **5.10 REFACTOR and verify** full tests/analyze.
- [ ] **5.11 Apply line-budget gate.** Split at 400 or more.
- [ ] **5.12 Review and deliver** as `feat(casos): habilita la edición de capítulos`.

**Rollback:** remove editor and restore committed six-section baseline; Units 1–4 remain dormant.

## Unit 6 — Dormant Router API Foundation

**Depends on:** Unit 5.

**Finish state:** tested routing infrastructure exists, but `TrueCrimeApp` still uses `MaterialApp.home`.

- [ ] **6.1 RED — Parse/restore.** Add parser tests for root, exact case route, encoding, invalid segments, and unknown URI preservation.
- [ ] **6.2 RED — Controller/page stack.** Add tests for root/detail/unknown stacks, open/return, `setNewRoutePath`, and restoration without duplicate history.
- [ ] **6.3 RED — State separation.** Prove routes never access map selection and root restoration activates `Workspace.situationRoom` without clearing selection or adding history.
- [ ] **6.4 Observe RED** while navigation package is absent.
- [ ] **6.5 GREEN — Add navigation package** with route model, parser, controller, delegate, and navigation contract.
- [ ] **6.6 Keep it dormant.** Do not edit `TrueCrimeApp`, activate placeholders, call `usePathUrlStrategy`, or use `dart:html`.
- [ ] **6.7 Observe GREEN** on parser/router tests.
- [ ] **6.8 TRIANGULATE** encoded/unknown routes, repeated restoration, root workspace correction, and preserved map selection.
- [ ] **6.9 REFACTOR and verify** full tests/analyze and unchanged public behavior.
- [ ] **6.10 Apply line-budget gate.** Split at 400 or more.
- [ ] **6.11 Review and deliver** as `feat(navegacion): prepara las rutas hash de expedientes`.

## Unit 7 — Activate Complete Hash Routing and Expanded Detail

**Depends on:** Units 4 and 6.

**Finish state:** routing activates only with complete loading/error/not-found/known-case responsive detail.

- [ ] **7.1 RED — Slug lookup.** Test loading/error/exact match/missing slug and no map-provider access.
- [ ] **7.2 RED — All detail states.** Add `case_detail_page_test.dart` for loading, catalog error, unknown slug, known legacy/chapter case, expanded shared content, return, and related slug navigation.
- [ ] **7.3 RED — Responsive reading.** Prove realistic compact/wide scrolling, reachable actions, and no blocking overflow.
- [ ] **7.4 Observe RED** before provider/page implementation.
- [ ] **7.5 GREEN — Complete detail surface.** Add slug provider and `CaseDetailPage` with all states and direct expanded shared composition.
- [ ] **7.6 GREEN — Route-specific navigation.** Wire related and return actions; keep generic unknown syntax distinct and map state unchanged.
- [ ] **7.7 Observe detail GREEN before root activation.** App root remains old.
- [ ] **7.8 RED — Application activation.** Mount `TrueCrimeApp` and require Router ownership for all routes, restoration, and root workspace correction.
- [ ] **7.9 GREEN — Activate complete graph.** Switch to `MaterialApp.router`, creating controller/delegate once.
- [ ] **7.10 Observe router GREEN** across parser/router/provider/detail/host tests.
- [ ] **7.11 TRIANGULATE** slug identity, no map prerequisite, A→B routes/history, root restoration, and legacy presentation.
- [ ] **7.12 Verify structural boundaries.** Confirm no `dart:html`/path strategy and inspect `web/index.html` plus deployment workflow at their boundary.
- [ ] **7.13 REFACTOR and verify** full tests/analyze.
- [ ] **7.14 Apply line-budget gate.** Forecast maximum 360; split at 400.
- [ ] **7.15 Review and deliver** as `feat(navegacion): activa el detalle público por hash`.

## Unit 8 — Published-Case Directory

**Depends on:** Unit 7.

**Finish state:** one adaptive directory reuses loaded catalog and preserves map behavior.

- [ ] **8.1 RED — Ordering/reuse.** Test every loaded case, year-desc/title-asc/slug-asc order, legacy cases, and no independent load.
- [ ] **8.2 RED — States/navigation.** Test loading/error/retry/empty/list, modal close, and exact slug navigation.
- [ ] **8.3 RED — Responsive access.** Test rail-less mobile/map action, desktop rail icon, scroll, navigation, and no blocking overflow.
- [ ] **8.4 RED — Map preservation.** Prove directory actions do not alter filters, selection, recenter, markers, or compact dossier.
- [ ] **8.5 Observe RED** with bounded pumps.
- [ ] **8.6 GREEN — Derived provider.** Derive complete ordered directory only from `casesProvider`.
- [ ] **8.7 GREEN — Adaptive directory.** Add mobile safe-area bottom sheet and constrained wide modal.
- [ ] **8.8 GREEN — Entry points.** Activate rail icon, rail-less map-stage control, and shared home navigation.
- [ ] **8.9 Observe GREEN** on focused tests.
- [ ] **8.10 TRIANGULATE** ordering fallback, excluded ranks, legacy inclusion, scrolling, slug navigation, and map preservation.
- [ ] **8.11 REFACTOR and verify** full tests/analyze.
- [ ] **8.12 Apply line-budget gate.** Split at 400 or more.
- [ ] **8.13 Review and deliver** as `feat(casos): añade el directorio público de expedientes`.

## Unit 9 — Verification, Deployment, and Browser Proof

**Depends on:** Units 1–8 committed.

**Finish state:** automated, structural, built-host, deployed, and browser evidence agree. Unit 9 changes no source.

- [ ] **9.1 Confirm final scope** and unchanged catalog unless separately authorized.
- [ ] **9.2 Run `flutter test` and `flutter analyze`.**
- [ ] **9.3 Build web** with `/true_app/` base href.
- [ ] **9.4 Read `build/web/index.html`** for base href and viewport; confirm workflow publishes build output.
- [ ] **9.5 Record structural route proof:** parser/restorer, default hash strategy, no `dart:html`/path strategy, exact slug lookup, map separation.
- [ ] **9.6 Confirm exact deployment SHA** through approved direct-main gate and successful Pages workflow.
- [ ] **9.7 Prove deployed direct entry/refresh** in a real browser, recording browser/version, SHA, URL, hash, and title.
- [ ] **9.8 Prove deployed history:** Situation Room → A → B → Back twice → Forward twice, recording hash/content each step.
- [ ] **9.9 Prove unknown slug:** hash preserved, no substituted case, return to Situation Room.
- [ ] **9.10 Prove responsive directory/detail** on compact mobile and wide desktop with scrolling and actions.
- [ ] **9.11 Smoke-check map preservation** after route/directory use.
- [ ] **9.12 Confirm zero source lines.** Any corrective edit reopens its owning unit and evidence.
- [ ] **9.13 Hand off complete verification evidence** without inferring PASS from widget tests.
- [ ] **9.14 Fail safely.** Preserve failure and execute approved rollback instead of fabricating acceptance.

## Rollback Verification Checkpoints

Only after explicit rollback approval, revert source units in strict reverse order:

- [ ] **RB.9** Invalidate evidence for reverted SHA; no source revert.
- [ ] **RB.8** Revert directory; verify routes/map remain.
- [ ] **RB.7** Revert route activation; verify `MaterialApp.home` restores Situation Room.
- [ ] **RB.6** Revert dormant routing; verify non-routed app compiles.
- [ ] **RB.5** Revert editor activation; rerun restored six-section 360px baseline.
- [ ] **RB.4** Revert shared dossier extraction; run characterization tests.
- [ ] **RB.3** Revert queue/projection; verify dormant chapter data remains valid.
- [ ] **RB.2** Revert publication support; verify legacy catalog/export and unchanged catalog asset.
- [ ] **RB.1** Revert chapter representation; verify original application.
- [ ] **RB.0** Reconfirm archived `intake-responsive` baseline remains committed.

Restore a prior catalog separately if later manual publication introduced problematic data. During full rollback, editors must not reopen/save affected drafts until browser JSON is backed up or forward-compatible recovery exists.

## Requirement Coverage Matrix

| Capability | Tasks |
| --- | --- |
| Fixed optional chapters, order, meaningful content | 1.1–1.7, 5.1–5.9 |
| Draft persistence, compatibility, and live preview | 1.2–1.7, 3.1–3.8, 5.3–5.9 |
| Publication round-trip and malformed-entry policy | 2.1–2.9, 4.2–4.10 |
| Manual publication boundary | 2.5–2.7, 9.1 |
| Apply gate and strict TDD | 0.1–0.8 and all RED/GREEN tasks |
| Stable hash identity and slug lookup | 6.1–6.8, 7.1–7.12, 9.5–9.8 |
| Direct load, refresh, and browser history | 7.1–7.11, 9.6–9.8 |
| Unknown slug and return | 7.2–7.11, 9.9 |
| Browser/host evidence | 7.12, 9.3–9.10 |
| Directory mobile/desktop access, order, reuse, navigation | 8.1–8.10, 9.10 |
| Map preservation | 8.4–8.10, 9.11 |
| Single shared dossier content and omission | 4.1–4.10, 5.3–5.9, 7.2–7.11 |
| Contextual host actions and related navigation | 4.3–4.10, 7.2–7.11, 9.8, 9.11 |
| Expanded responsive dossier | 7.2–7.11, 9.10 |
| Situation Room remains intact | 6.3–6.8, 7.1–7.11, 8.4–8.10, 9.11 |

## Completion Conditions

The change is ready for verification only when:

- Units 0–8 are complete in order.
- Every new behavior has recorded RED-before-GREEN evidence.
- Every source-bearing unit records fewer than 400 actual changed lines.
- Every unit passes focused tests, `flutter test`, and `flutter analyze`.
- No PR was created; direct-main commits use Spanish conventional messages without AI attribution.
- Built host-document and deployed browser evidence are complete.
- `assets/data/cases.json` remains unchanged unless separately authorized.
- No `intake-responsive` scope was touched before legitimate archive.
