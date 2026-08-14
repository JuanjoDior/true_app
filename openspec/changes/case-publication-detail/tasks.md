# Tasks: Public Case Publication Detail

> **Planning complete; apply unblocked (2026-08-13).**
>
> `intake-responsive` was archived on 2026-08-13 with `blockers: 0`, and its
> six-section `test/intake_narrow_layout_test.dart` baseline is committed on
> `main` in `c351fac`. **Unit 0 was worked and its boxes carry what was actually
> observed on 2026-08-13**, not inherited claims. Everything after Unit 0 is
> authorised. Re-run Unit 0 before resuming if `main` has moved since.

## Review Workload Forecast

| Field | Value |
| --- | --- |
| Estimated changed lines | **2,960–3,890 aggregate**, including tests |
| 1500-line budget risk | Low; the largest unit is 4a-2, forecast up to 1,320 |
| Chained PRs recommended | No |
| Suggested split | Direct-main Units 1–8; no PRs |
| Delivery strategy | Direct commits to `main` in bounded work units |

Decision needed before apply: No

Chained PRs recommended: No

1500-line budget risk: Low; the largest unit is 4a-2, forecast up to 1,320

Delivery is already approved as direct commits to `main`, so no workload decision remains. The `intake-responsive` archive and baseline checks remain an independent apply blocker.

| Unit | Forecast including tests | Forecast maximum | Review boundary |
| --- | ---: | ---: | --- |
| 0 | 0 source lines | 0 | Dependency evidence only |
| 1 | 150–220 | 220 | Dormant chapter domain and draft representation |
| 2 | 170–240 | 240 | Publication and catalog compatibility |
| 3 | 130–180 | 180 | Serialized persistence and preview projection |
| 4a-1 | 200–300 | 300 | Characterization tests, before anything moves |
| 4a-2 | 1,150–1,320 | 1,320 | New files + atomic move + header callback |
| 4b | 220–300 | 300 | Additive panel configuration behind defaults |
| 4c | 180–260 | 260 | Host migration, one host per commit if needed |
| 5 | 150–220 | 220 | Seven-section editor activation |
| 6 | 180–250 | 250 | Dormant Router API foundation |
| 7 | 260–360 | 360 | Router activation and complete detail page |
| 8 | 170–240 | 240 | Published-case directory |
| 9 | 0 source lines | 0 | Verification, deployment, and browser evidence |

The source-bearing forecast is 2,960–3,890 lines, summed directly from the unit table above. Every source-bearing unit is forecast below 1500 changed lines. The per-unit ceiling went 400 → 1000 → 1500 on 2026-08-13 by maintainer decision: this codebase has one developer and no second reviewer, so a low ceiling was protecting a review burden that does not exist here.

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
6. If the total is **1500 or more**, stop before review, staging, commit, or push and split the unit.
7. Review only normalized bytes. Any later byte, path, or mode change invalidates that candidate.
8. Keep tests with the behavior they verify.

Accepted units are committed directly to `main` with Spanish conventional commit messages, no AI attribution, and no PR.

## Anti-regression rules

Every rule below exists because it was broken while planning this change, on
2026-08-13, and an independent audit caught it. They are cheap to check and each
one prevents a defect that actually shipped into a draft.

1. **A number without a command is a defect.** Every figure in these artifacts —
   line counts, file sizes, aggregates, call-site counts — carries the command
   that produced it. An aggregate is summed, never estimated. *Broken once: an
   aggregate was written as 2,110–2,720 when the table summed to 2,510–3,270.*
2. **Scope every "holds" claim to what you enumerated.** Never write "everything
   the plan says about the code is true". Write the list you checked, and say
   that is the list. *Broken once: six items were verified and the claim was
   universal; a seventh claim in the same documents was false.*
3. **After changing any threshold, re-grep the whole change folder for the old
   value before committing.** Rewriting the top of a section and leaving its
   tail is the failure mode. *Broken once: a "under 200 moved lines" cap — the
   old 400 ceiling in disguise — survived twenty-two lines below the paragraph
   announcing the new one.*
4. **A scrolling or reachability assertion is invalid without its
   preconditions.** It MUST assert that the content overflows and that the
   target is not visible on arrival, and MUST scroll with a real gesture. See
   `test/intake_narrow_layout_test.dart:176-177`. *Broken three times in one
   pass, in specs written the same day the original defect was fixed.*
5. **Attribute a RED to the line the failure reports, never to the assertion you
   expected.** When several expectations share one test body, the first mismatch
   aborts it. *Broken once: four mutation probes were credited to four
   assertions; one of them never reached the assertion it was credited with.*
6. **Before slicing a Dart refactor, check whether the symbols are
   library-private.** Privacy is library-scoped, so a file-by-file move of
   private symbols has no compiling intermediate state. *Broken once: a
   three-pass split was planned for nine private widgets and could not compile
   at any step.*
7. **Before implementing a unit, re-read the seams it touches.** Unit 0 is the
   template: measure, then record the command and the result next to the claim.

## Unit 0 — Resolve the Apply Block and Re-read the Baseline

**Depends on:** legitimate completion of `intake-responsive`.

**Finish state:** archived dependency, committed baseline, synchronized `main`, and reconciled post-archive plan are evidenced.

- [x] **0.1 Confirm legitimate archive.** `openspec/changes/` contains only `archive/` and `case-publication-detail/`; `intake-responsive` is gone. `openspec/specs/` holds `responsive-breakpoints` and `intake-responsive-layout`. Archived record at `openspec/changes/archive/2026-08-13-intake-responsive/` with `blockers: 0`.
- [x] **0.2 Confirm archived bytes on `main`.** `git merge-base --is-ancestor eeef7e3 HEAD` and the same against `origin/main` both succeed. `git status -sb` shows `## main...origin/main` with no divergence.
- [x] **0.3 Confirm the six-section baseline.** `git show main:test/intake_narrow_layout_test.dart` carries `_expectedCaseFormSectionTitles` with the six Spanish titles, the non-vacuity preconditions (`maxScrollExtent > 0` at line 176, last section not visible at 177) and the ordered walk (`orderedEquals` at 217). **Executed**, not merely read: the focused test passes.
- [x] **0.4 Require a clean ownership boundary.** Confirmed clean: `git status --short test/intake_narrow_layout_test.dart` is empty and `git diff HEAD -- test/ lib/ web/` produces nothing, so the baseline is committed and unmodified. Later units 4c and 5 each have one authorised edit to that file, named in design §12; this check is about its state on arrival, not a permanent freeze.
- [x] **0.5 Synchronize safely.** `git fetch origin` clean; local `main` level with `origin/main`.
- [x] **0.6 Re-read archived seams.** Measured on 2026-08-13. The six claims enumerated here hold; this is **not** a blanket statement about every claim the plan makes, and one such claim was subsequently found false — design §9.4 asserted that editorial subwidgets perform no direct provider writes, while `case_dossier_panel.dart:113` does exactly that. It is now written as a target state with the conversion assigned to 4a-2. The verified six: `kCaseFormSections` has exactly six entries (`Datos básicos`, `Ubicación`, `Resumen y ficha`, `Cronología`, `Enlaces`, `Fotografías`); `case_dossier_panel.dart` is 636 lines; `CaseDossierPanel(` has **six call sites** — `home_page.dart`, `situation_side_panel.dart`, `intake_preview_panel.dart`, `test/intake_narrow_layout_test.dart`, `test/case_dossier_photos_test.dart`, `test/intake_form_widget_test.dart`; `TrueCrimeApp` is a `StatelessWidget`; and **all 15 catalog cases have `id == slug`, none differ** — which is what makes the slug-identity requirement unfalsifiable without a hand-built fixture.
- [x] **0.7 Reconcile planning.** Three reconciliations applied. (a) The per-unit ceiling went 400 → 1000 → 1500 by maintainer decision: one developer, no second reviewer. (b) An independent audit showed 4a's ~966 was a move-only floor and that slicing it by section group **cannot compile**, because the nine subwidgets are library-private. (c) Measured afterwards: every external reference to those nine lives in the panel composition at `case_dossier_panel.dart:30-71`, so an **atomic** move leaves no dangling reference and they may stay private — which removes the public-rename sub-unit entirely. 4a is now 4a-1 characterization tests, then 4a-2 new files + atomic move + header callback. The 4a/4b/4c structure stays; its reason is compiling intermediate states, not size.
- [x] **0.8 Persist gate evidence.** Archive commit `eeef7e3`; baseline delivered in `c351fac`; `main` at `cbfe028` at gate time, level with `origin/main`; `flutter test` 170/170 and `flutter analyze` clean; `git status` shows no change under `lib/`, `web/` or `test/`.

**Verification:** evidence only; do not run this change’s tests.

## Unit 1 — Dormant Chapter Domain and Draft Representation

**Depends on:** Unit 0.

**Finish state:** chapter data round-trips through drafts without an authoring surface.

- [x] **1.1 RED — Chapter codec.** `test/case_chapter_codec_test.dart`, 30 focused tests. Deliberately one assertion each: with several `expect`s in one body the first failure aborts the rest, which would make mutation attribution dishonest.
- [x] **1.2 RED — Draft compatibility.** `test/case_draft_chapters_test.dart`, 13 tests covering legacy JSON, round trip, omission and field preservation.
- [x] **1.3 Observe RED.** Recorded as a **compile failure**, not credited to any assertion line: `Error when reading 'lib/features/cases/domain/case_chapter.dart'` plus `Undefined name 'CaseChapterType'`. The type did not exist yet.
- [x] **1.4 GREEN — Domain.** `lib/features/cases/domain/case_chapter.dart`: fixed four-value enum, `CaseChapter`, `CaseChapters` with four named slots (so a repeated or reordered type is unrepresentable), tolerant non-throwing `fromJson`, `orderedMeaningful`, `contentFor`, `withContent`.
- [x] **1.5 GREEN — Draft.** `CaseDraft.chapters` defaulting to `const CaseChapters()`, decoded through the tolerant codec, and omitted from `toJson` when nothing is meaningful.
- [x] **1.6 Observe GREEN** on the same focused tests: 40/40 at that point.
- [x] **1.7 TRIANGULATE.** Found a real gap while triangulating: `withResolvedPlace` rebuilds the draft field by field, so it silently dropped chapters. Added `chapters` there and to `copyWith`, plus three tests. Mutation evidence, each isolated and reverted:

  | # | Mutation | Failing test | Proves |
  |---|---|---|---|
  | M1 | drop `chapters` from `withResolvedPlace` | *withResolvedPlace keeps the chapters* — `Expected 'Antes', Actual <null>` | Resolving a map location cannot wipe authored chapters |
  | M2 | remove the `accepted.containsKey` guard | *keeps the first accepted entry when a type repeats* — `Expected 'Primera', Actual 'Segunda'` | First accepted wins, not last |
  | M3 | let an ignored entry occupy its slot | *a blank earlier entry…* and *a malformed earlier entry…* — both `Expected 'Real', Actual ''` | An ignored entry does not consume its type slot |
  | M4 | always emit the `chapters` member | both *toJson omits the member…* — `Expected false, Actual <true>` | A chapterless draft serialises byte-identical to before |

- [x] **1.8 REFACTOR and verify.** `dart format` on the four touched files; `flutter test` 213/213 (170 baseline + 43 new); `flutter analyze` clean.
- [x] **1.9 Apply line-budget gate.** Measured `git diff --numstat 75ac968`: 151 + 18/5 + 299 + 141 = **614 changed lines**, against a 1500 ceiling. No split needed.
- [x] **1.10 Review and deliver** as `feat(casos): incorpora el modelo de capítulos editoriales`.

**Rollback:** restore the original draft schema and remove only dormant chapter types/tests.

## Unit 2 — Publication and Catalog Compatibility

**Depends on:** Unit 1.

**Finish state:** published JSON supports chapters without changing the asset or manual workflow.

- [x] **2.1 RED — Export/read-back.** `test/case_publication_chapters_test.dart`, 9 tests.
- [x] **2.2 RED — Catalog tolerance.** `test/local_cases_repository_chapters_test.dart`, 14 tests.
- [x] **2.3 Observe RED.** Recorded as a **compile failure**: `The getter 'chapters' isn't defined for the type 'TrueCrimeCase'`. Not credited to any assertion line.
- [x] **2.4 GREEN — Published model.** `TrueCrimeCase.chapters` defaulting to `const CaseChapters()` and decoded through the tolerant codec.
- [x] **2.5 GREEN — Exporter.** `draftToCaseJson` emits `chapters` only when something is meaningful, in editorial order, and **verbatim** — the one deliberate exception to the trimming every other exported field gets. A test pins the exception by checking `summary` is still trimmed in the same call.
- [x] **2.6 Preserve fail-fast core errors.** Two tests assert `parseCasesJson` throws on a malformed core field, one of them with valid chapters alongside, so tolerance cannot leak outward. Proven alive by mutation M2.
- [x] **2.7 Prove manual boundary.** Structural, not a test: `case_exporter.dart` imports only `dart:convert` and three domain files. It has no repository, asset, file or network dependency, so it cannot write the catalog or deploy. Asserting "no write happened" in a test would be an assertion that cannot fail.
- [x] **2.8 Observe GREEN** on the focused tests: 20/20 at that point.
- [x] **2.9 TRIANGULATE.** Added a mixed-catalog group — one legacy case and one chapter-bearing case in the same payload — plus a test that parses the **real** `assets/data/cases.json`, which turns red the day the addition stops being additive. Mutation evidence, each isolated and reverted:

  | # | Mutation | Failing test | Proves |
  |---|---|---|---|
  | M1 | exporter always emits `chapters` | both *omits the member…* — `Expected false, Actual <true>` | A chapterless export stays byte-identical |
  | M2 | make core `year` tolerant | both *malformed core field…* — `Expected throws TypeError` | The tolerance boundary holds; a broken case fails loudly instead of vanishing |
  | M3 | published model ignores `chapters` | 6 decoding tests, none of the boundary ones | Chapter decoding is wired, and the boundary tests are independent of it |

- [x] **2.10 REFACTOR and verify.** `dart format`; `flutter test` 236/236; `flutter analyze` clean after fixing one `use_null_aware_elements` info the formatter surfaced in the new fixture.
- [x] **2.11 Apply line-budget gate.** Measured `git diff --numstat cf2293b`: **409 changed lines** against a 1500 ceiling.
- [x] **2.12 Review and deliver** as `feat(casos): publica capítulos con compatibilidad de catálogo`.

**Rollback:** leave Unit 1 dormant draft data intact; restore previous published/export behavior and keep `assets/data/cases.json` unchanged.

## Unit 3 — Serialized Persistence and Preview Projection

**Depends on:** Unit 2.

**Finish state:** dormant chapter edits persist in order and reach preview data without a visible editor.

- [x] **3.1 RED — Serialized mutations.** `test/case_draft_serialized_persistence_test.dart`. `_StaggeredStore` makes the **first** save slow (60 ms) and the second instant, which is the adversarial completion order. **Every assertion reads `store.committed` / `store.lastCommitted`, never in-memory state**: the notifier publishes `state` synchronously before the `await`, so the in-memory half already passes today and crediting the RED to it would falsify the evidence. What the race loses is the disk.
- [x] **3.2 RED — Queue recovery.** Two tests: the caller sees the `StateError`, and a mutation enqueued while that failure is still in flight still persists.
- [x] **3.3 RED — Preview projection.** `test/draft_preview_chapters_test.dart`, 5 tests.
- [x] **3.4 Observe RED.** Real assertion failures, not compile errors: `the last write to land carries both edits` → `Expected <1970> / Actual <null>` (the stale save clobbered the newer one) and `a delete that lands late does not resurrect the draft` → `Expected: not contains 'draft-b' / Actual: ['draft-a', 'draft-b']`. The race is real and reproducible.
- [x] **3.5 GREEN — Persistence queue.** `CaseDraftsNotifier._persist` chains every snapshot behind `_writes`. The returned future carries the failure to the caller; `_writes` stores a neutralized copy so one failed write cannot poison the queue. All four mutations route through it.
- [x] **3.6 GREEN — Projection.** `chapters: draft.chapters` in `draftPreviewCaseProvider`. Deliberately **no placeholder**, unlike `title`/`country`/`regionOrCity` around it: an empty chapter is omitted, never invented.
- [x] **3.7 Observe GREEN.** 11/11 on the focused files.
- [x] **3.8 TRIANGULATE.** Each mutation isolated and reverted:

  | # | Mutation | Failing tests | Proves |
  |---|---|---|---|
  | M1 | `_persist` calls the store directly, no chaining | all 4 race tests — `Expected <1970>`, `Expected ['Primero','Segundo'] ordered`, `not contains 'draft-b'`, `length of <2>` | The queue is what orders the writes |
  | M2 | `_writes = write` (keep the failure in the chain) | *a later mutation still persists after an earlier one failed* | One failed save does not poison the queue |
  | M3 | `_persist` returns the neutralized future | *a failed save surfaces its error* | The recovery of M2 does not swallow the error |
  | M4 | drop `chapters:` from the projection | 4 of the 5 preview tests | Chapters actually cross into the preview |
  | M5 | give chapterless drafts a `'Por redactar'` placeholder | *a draft without chapters previews without them*, and only that one | The no-placeholder rule is pinned |

  **M4 exposed three vacuous assertions of my own.** `omits a whitespace-only chapter`, `clearing a chapter removes it`, and `a draft without chapters previews without them` all asserted bare `isEmpty` — which is also true when no projection exists at all. The first two now carry a meaningful chapter alongside the empty one and assert the surviving set, so M4 kills them. The third is genuinely about emptiness and is instead pinned by M5. This is the project's signature defect (Anti-regression rule 1) caught by mutation rather than by review.

  **Not fixed, logged:** `createDraft` derives its id from `DateTime.now().millisecondsSinceEpoch`, so two creates inside the same millisecond collide on `draftId`. Out of scope for D4 (serialization), real defect, belongs to its own unit.
- [x] **3.9 REFACTOR and verify.** `dart format` on the three touched files only, never `lib/` wide (that reformats ~46 unrelated files); `flutter test` **247/247**, `SUITE_EXIT=0`; `flutter analyze` `ANALYZE_EXIT=0`, "No issues found!".
- [x] **3.10 Apply line-budget gate.** From start SHA `182003a`: 40 changed lines in `lib` plus 205 + 129 new test lines = **374** against the 1500 ceiling.
- [x] **3.11 Review and deliver** as `fix(casos): serializa la persistencia de borradores`.

**Rollback:** revert `_persist` to a direct `await _store.saveDrafts(...)` and drop the projection line; Units 1–2 stay intact and dormant.

## Unit 4 — Shared Dossier Content and Host Contracts

**Depends on:** Unit 3.

**Finish state:** one renderer serves map/preview contracts and can render dormant chapter data; no editor is exposed.

> **Split into 4a, 4b and 4c. This is not optional, and the 1500-line ceiling
> does not change it.** The reason is not size but compiling states: making
> `mode` and `relatedCases` required would break all six call sites at once,
> leaving no state in which the app compiles between the move and the migration.
> Per design D12, new parameters are optional with behaviour-preserving defaults:
>
> - **4a — extraction, in two ordered sub-units.**
>   **4a-1** characterization tests first (~200-300, task 4.1), because they must
>   capture existing behaviour *before* it moves; they are GREEN throughout and
>   are not TDD evidence for anything new.
>   **4a-2** the new files (`DossierSourceGroup`, chapter labels,
>   `CaseDossierContent`) plus the **atomic** move of all nine subwidgets
>   (`case_dossier_panel.dart:93-575`) *together with* the panel's own
>   composition at lines 26-89, plus converting `_Header`'s
>   `selectedCaseIdProvider` write at line 113 into a host callback. Forecast
>   1,150-1,320.
>   **The move must be atomic and that is a Dart constraint, not a preference.**
>   The nine widgets are library-private, so moving them piecemeal breaks the
>   panel's references. Moving them *with* the composition leaves no reference
>   behind, so they may stay private. If the measured total ever exceeds 1500,
>   the only legal slice is to first rename them public — do not slice by
>   section group while they are private.
>   Constructor unchanged, **no call site touched**.
> - **4b — additive configuration.** Optional `mode` (default `map`), optional
>   `relatedCases` (default null, panel keeps deriving it), callbacks, source
>   override, chapter rendering. Defaults keep every host compiling untouched.
>   Tasks 4.2–4.7 and 4.10. **Task 4.2 belongs here, not in 4a**: its
>   chapters-once-and-in-order assertion cannot go GREEN until chapter rendering
>   exists, and no sub-unit may reach its commit gate with a knowingly red test.
> - **4c — host migration.** `IntakePreviewPanel`, `situation_side_panel.dart`,
>   `home_page.dart`, plus the three committed test call sites including
>   `test/intake_narrow_layout_test.dart:452`. Remove the duplicated preview
>   source rendering here, not earlier. **Also migrate
>   `test/intake_preview_panel_test.dart:114-136`**, whose
>   `intake-preview-link-group-*` assertions guard the null-kind bucketing and
>   the `Sin clasificar` relabel; design §9.3 makes that migration normative but
>   the file was missing from both the §12 change plan and this forecast. Task 4.8.
>
> Each of 4a/4b/4c runs its own budget gate, focused tests, `flutter test`,
> `flutter analyze`, review and commit.

- [x] **4.1 CHARACTERIZE** *(sub-unit 4a-1)*. `test/case_dossier_characterization_test.dart`, 18 tests, GREEN from the first run — they prove nothing new, they are the net that catches whatever the 4a-2 move breaks. They assert **observable behaviour only** (labels, order, omissions, actions, composition) and never a private type: a test naming `_Header` would break on a *correct* move, which is the opposite of what a characterization is for.

  Pinned: the four conditional sections and their order; header title/location/victim/status-label precedence; the stats grid's connection count; back-to-map clearing the selection; a related card selecting its case; `Centrar` bumping `mapRecenterTickProvider`; source host vs. full URL; and `IntakePreviewPanel` hosting `CaseDossierPanel` rather than owning a second renderer.

  **Proven falsifiable, because a characterization that cannot die protects nothing.** Probes, each isolated and reverted:

  | # | Probe | Kills | Leaves alive |
  |---|---|---|---|
  | P0 | `CaseDossierPanel.build` returns `SizedBox.shrink()` | 14 of 18 | the 4 absence/composition assertions |
  | P1 | timeline section rendered unconditionally | *a case with nothing renders none of them* | — |
  | P2 | victim block rendered unconditionally | *omits the victim block when there is none* | — |
  | P3 | `IntakePreviewPanel` renders a `Text` instead of the panel | *an editing draft is previewed through CaseDossierPanel* | — |
  | P4 | `draftPreviewCaseProvider` falls back to a placeholder draft | *without an editing draft it invites to pick one* | — |

  **A vacuous assertion caught in the act.** `omits the victim block when there is none` used `find.textContaining('VÍCTIMA(S)')`, which can never match: the block is a `Text.rich`, invisible to the finder without `findRichText: true`. It was passing for the wrong reason. Its positive twin failed first and exposed it — which is why every omission assertion in this file now has a presence twin over the same finder.

  **Forecast exceeded, deliberately.** 423 lines against a 200-300 forecast. Per 4.12 the forecast is not a gate; the 1500 ceiling is, and it is untouched. The overrun is fixtures and the presence/absence twinning above, both of which the net needs.
- [x] **4.2 RED — Shared content** *(sub-unit 4b)*. `test/case_dossier_content_test.dart`, 24 tests. `CaseDossierContent` needs no Riverpod, so it mounts bare — no container, no overrides. That is what 4a-2 bought.
- [x] **4.3 RED — Source overrides and modes.** Same file. Pins the three-state override: `null` = "use the published sources", a non-null list = "I own the sources", and **an empty list is still an override** — the distinction that stops the preview rendering its links twice.
- [x] **4.4 RED — Composition/callbacks.** `test/case_dossier_panel_config_test.dart`, 12 tests: four proving an unconfigured panel behaves exactly as today (D12), the rest proving explicit configuration wins.

  **Planning defect found and corrected.** As written, 4.4 also required proving the `IntakePreviewPanel → CaseDossierPanel(preview) → CaseDossierContent` chain. `IntakePreviewPanel` passing `mode: preview` is **4c** work (4c owns that file), so that assertion cannot go green in 4b and no sub-unit may reach its commit gate with a knowingly red test. The chain half moves to 4c; 4b proves `CaseDossierPanel(preview) → CaseDossierContent` only. This is the same defect class as the earlier 4.2-in-4a misassignment.
- [x] **4.5 Observe RED.** Compile failure — `CaseDossierMode`, `DossierSourceGroup` and `relatedCases` do not exist. Recorded as a compile RED, not credited to any assertion line.
- [x] **4.6a GREEN — Extract the renderer** *(sub-unit 4a-2)*. `CaseDossierContent` in a new `case_dossier_content.dart`, carrying the whole composition plus all ten private subwidgets in **one atomic move**. It is a plain `StatelessWidget`: it reads and writes no state, receives `related` already resolved, and returns actions through `onBack` / `onRelatedTap` / `onCenter`. `CaseDossierPanel` shrinks from 636 lines to 34 — the host that binds those callbacks to `selectedCaseIdProvider` and `mapRecenterTickProvider`.

  **The move had to be atomic and that is Dart, not taste.** The ten subwidgets are library-private; moving them piecemeal would leave the panel referencing symbols it can no longer see. Moving them *together with* the composition leaves no reference behind, so they stay private in their new home and nothing had to be made public.

  **Constructor unchanged, zero call sites touched** — `git status` shows only the panel modified and the new file added. `chapters` rendering is **not** here; it belongs to 4b.

  Verified: `flutter test` **265/265** including the 18 characterization tests, untouched; `flutter analyze` clean. The net was re-proven against the *moved* wiring, not just the old one: dropping `onCenter` in `CaseDossierContent` kills *centering bumps the recenter tick* and nothing else. Measured 18 + 620 changed lines in the tracked file plus 680 new = **1,318** against the 1500 ceiling, inside the 1,150-1,320 forecast.
- [x] **4.6b GREEN — Add contracts.** `dossier_source_group.dart` (21 lines) and `case_chapter_presentation.dart` (16 lines). The chapter labels live in presentation next to `case_category_presentation.dart` and `case_status_presentation.dart`, not in the domain: the chapter *type* is a fact about the case, its *heading* is an editorial decision that must be changeable without touching published data or the codec. Labels chosen here (no spec pins them), in Spanish like the rest of the UI: Antecedentes / Los hechos / La investigación / Estado actual.
- [x] **4.7 GREEN — Refactor panel.** `CaseDossierMode`, chapter rendering between summary and photos, the source override, and six optional panel parameters whose defaults reproduce today's behaviour exactly.

  **Three deviations from design §9.2, recorded rather than silently applied:**

  1. **`DossierPresentation` is not implemented.** The design's `CaseDossierContent` signature names it, but the design never defines it anywhere — there is no enum, no values, no semantics. Its evident purpose (compact vs. expanded spacing) has no consumer until Unit 7 builds the expanded page. Adding it now would ship an untested branch. **Deferred to Unit 7**, which is where `expanded` gets both a second value and a test.
  2. **`CaseDossierPanelMode` renamed `CaseDossierMode`.** It is now carried by the content as well as the panel, so a "Panel"-prefixed name on a content parameter would misdescribe it.
  3. **Map chrome is gated by `mode`, not by nullable callbacks.** Preview must suppress back, star, share, follow *and* recenter as a set; per-callback nullability would have made that four independent decisions that can disagree.
- [x] **4.8 GREEN — Preserve host ownership** *(sub-unit 4c)*. `IntakePreviewPanel` now composes `CaseDossierPanel(mode: preview, relatedCases: const [], sourceGroups: …)` and its own `_LinkGroup` list and `_groupLinksByKind` are gone. The draft's links become source groups rendered by the shared source cards — the same ones a published case gets — instead of a second list appended underneath. It also passes an empty `relatedCases` so the panel stops deriving related cases for a draft from the published catalog.

  **The grouping is now a pure function**, `previewSourceGroups` in `lib/features/cases/presentation/intake/preview_source_groups.dart`, with `test/preview_source_groups_test.dart` (14 tests). The three fragile behaviours design §9.3 warns about are properties of the *derivation*, not of the painting, and testing them through a widget tree only adds ways to fail for unrelated reasons.

  **`test/intake_preview_panel_test.dart` migrated, not deleted.** Its `intake-preview-link-group-*` key assertions had no target left — there is no bespoke renderer to key. They became tree-order assertions over headings and link titles, which is what the grouping actually looks like to a reader. Its `groups unset and "other"…` test now also asserts `'OTRO'` is *absent*, so the relabel cannot silently regress. Added `the preview shows no map chrome`, which is the chain assertion moved here from 4.4.

  **Two hosts deliberately not migrated.** `situation_side_panel.dart` and `home_page.dart` are pure map hosts: migrating them would mean writing `mode: CaseDossierMode.map` — the default — and changing nothing else. D12 makes that migration optional, and the plan's value was in the intake host, which genuinely changes behaviour. Same for `test/intake_narrow_layout_test.dart:452`, which design §12 explicitly permits leaving as-is. Ceremony is not evidence.
- [x] **4.9 Observe GREEN** *(4b)*. 36/36 focused, first run. Full suite **301/301** including the 18 characterization tests, still untouched; `flutter analyze` clean.
- [x] **4.10 TRIANGULATE** *(4b)*. Seven mutations, each isolated and reverted:

  | # | Mutation | Failing tests | Proves |
  |---|---|---|---|
  | M1 | chapters rendered reversed | *renders the four chapters in the fixed editorial order* | Editorial order is enforced, not accidental |
  | M2 | every chapter slot rendered, meaningful or not | 3 filtering tests | Empty and whitespace chapters leave no orphan heading |
  | M3 | override **adds to** the published sources instead of replacing them | 6 tests across both files | The rule that stops the preview showing its links twice |
  | M4 | empty groups not omitted | *a group with no sources is omitted* | No heading without cards under it |
  | M5 | `_showsMapChrome` always true | 4 preview-chrome tests | Preview really drops back/recenter/follow |
  | M6 | panel ignores a supplied `relatedCases` | 3 tests | The override reaches the renderer, empty list included |
  | M7 | panel ignores a host `onReturnToMap` | 2 tests | A host callback replaces the default map write instead of running alongside it |

  Every one of the 36 dies under at least one probe. The absence assertions carry presence twins (`preview mode still renders the editorial identity`, `an override renders its own sources`) so "renders nothing" cannot pass for "suppresses the chrome".
- [x] **4.11 REFACTOR and verify.** Per sub-unit. 4c: `dart format` on the touched files only; `flutter test` **316/316**, `SUITE_EXIT=0`; `flutter analyze` `ANALYZE_EXIT=0`.

  4c triangulation, each mutation isolated and reverted:

  | # | Mutation | Failing tests | Proves |
  |---|---|---|---|
  | N1 | iterate `link.kind` directly instead of `link.kind ?? other` | 8 across both files | An untyped link is not silently dropped from the preview |
  | N2 | label the bucket with `kind.label` (`'Otro'`) | 3 | An unclassified link is not presented as a real type |
  | N3 | trim the title like the exporter does | *a padded title survives verbatim* | Preview and export stay deliberately different |
  | N4 | `IntakePreviewPanel` passes `mode: map` | *the preview shows no map chrome* | The mode survives the whole host chain |
  | N5 | `IntakePreviewPanel` passes no `sourceGroups` | 3 | The groups actually reach the shared renderer |

  One test name was corrected during this pass: `renders no link groups when the draft has no links` had been rewritten to use a draft *with* a link, so the name no longer described it. It is now `a single link still gets its own group heading`, the presence twin of the empty-draft test below it.
- [x] **4.12 Apply the line-budget gate to each sub-unit separately.** Measured, all under the 1500 ceiling: **4a-1** 423 · **4a-2** 1,318 · **4b** 303 changed + 455 new = 758 · **4c** 388 changed + 186 new = 574. The renaming escape hatch below was never needed: the atomic move kept all ten subwidgets private.

  Original wording follows. The only enforced threshold is the one in Execution Rules: 1500 or more stops the unit. The per-row figures are forecasts, not gates — exceeding a forecast is a signal to re-plan, not a stop. If 4a-2 measures 1500 or more, the legal slice is to rename the nine subwidgets public first; slicing by section group while they are private does not compile (design §9.2).
- [x] **4.13 Review and deliver each sub-unit.** `3be1c15` (4a-1), `43646d5` (4a-2), `555f937` (4b), and 4c as `refactor(casos): migra la previsualización al panel configurable`. Original wording: `refactor(casos): extrae el contenido compartido del expediente` (4a), `feat(casos): configura el panel de expediente por contexto` (4b), and `refactor(casos): migra los hosts al panel configurable` (4c).

## Unit 5 — Activate the Seven-Section Chapter Editor

**Depends on:** Units 1–4 and committed Unit 0 baseline.

**Finish state:** the seventh section follows `Fotografías`, and edits update shared preview.

- [x] **5.1 RED — Change registry expectation first.** `_expectedCaseFormSectionTitles` in `test/intake_narrow_layout_test.dart` gains `'Capítulos'` after `'Fotografías'`, with nothing registered yet. This is one of the two edits design §12 authorises on that file.
- [x] **5.2 Observe mandatory registry RED.** `all … form sections are reachable by dragging, in registry order, at 360px` fails on the registry comparison: six titles against seven expected.
- [x] **5.3 RED — Fixed editor.** `test/chapters_section_test.dart`, 14 tests.
- [x] **5.4 RED — Live activation.** `test/intake_chapter_preview_test.dart`, 7 tests. Editor and preview are mounted **together**, which is how someone writing actually uses them; testing them apart would leave exactly the wire between them uncovered.
- [x] **5.5 Observe editor/preview RED.** Compile failure — `chapters_section.dart` does not exist. Recorded as a compile RED.
- [x] **5.6 GREEN — Editor.** `ChaptersSection`: four `TextFormField`s over `CaseChapterType.values`, multiline, keyed `intake-field-chapter-<draftId>-<type>`. The draft id is in the key because `TextFormField` ignores `initialValue` changes — without it, switching drafts would leave the previous draft's text on screen.
- [x] **5.7 GREEN — Registry.** Registered immediately after `Fotografías`.
- [x] **5.8 Observe GREEN.** 31/31 across the three focused files; full suite **337/337**.
- [x] **5.9 TRIANGULATE.** Five probes, each isolated and reverted:

  | # | Probe | Failing tests | Proves |
  |---|---|---|---|
  | P1 | edit the `build`-captured draft instead of `current` | *two edits in the same frame both survive* | Two fast keystrokes in one frame cannot lose the first |
  | P2 | key drops the draft id | 10 across both files | Switching drafts actually reloads the fields |
  | P3 | iterate `CaseChapterType.values.reversed` | *labels them in the fixed editorial order* | Editor order is the editorial order |
  | P4 | section left unregistered | the 360px registry test | The section is registered **and** reachable by dragging at 360px |
  | P5 | add an "Añadir capítulo" button | *offers no button at all* | The absence of arbitrary controls is asserted, not assumed |

  **P1 caught a test of mine that could not fail — the project's signature defect, written by me while believing I was catching it.** The original `two edits in a row without a pump both survive` used `tester.enterText`, which pumps internally. With a rebuild guaranteed between the two edits, editing `current` and editing the captured `draft` are indistinguishable, and the mutation passed green. Rewritten to fire both `onChanged` handlers directly via `EditableText.onChanged`, with no pump between them, it fails as `['Después']` — the first edit lost. The same lie was in the preview test's name; it is now `two edits in a row both reach the preview`, promising only what it checks.
- [x] **5.10 REFACTOR and verify.** `dart format` on touched files; `flutter test` **337/337**, `SUITE_EXIT=0`; `flutter analyze` `ANALYZE_EXIT=0`. The six-section wording in `intake_narrow_layout_test.dart` (test name and two comments) updated to seven.
- [x] **5.11 Apply line-budget gate.** 12 changed lines plus 60 + 342 + 206 new = **620** against the 1500 ceiling.
- [x] **5.12 Review and deliver** as `feat(casos): habilita la edición de capítulos`.

**Rollback:** remove editor and restore committed six-section baseline; Units 1–4 remain dormant.

## Unit 6 — Dormant Router API Foundation

**Depends on:** Unit 5.

**Finish state:** tested routing infrastructure exists, but `TrueCrimeApp` still uses `MaterialApp.home`.

- [ ] **6.1 RED — Parse/restore.** Add parser tests for root, exact case route, encoding, invalid segments, and unknown URI preservation.
- [ ] **6.2 RED — Controller/page stack.** Add tests for root/detail/unknown stacks, open/return, `setNewRoutePath`, and restoration without duplicate history.
- [ ] **6.3 RED — State separation.** Prove routes never access map selection, and that the router never reads or writes `workspaceProvider` (design §7.3). Root restoration must add no history entry and must not clear the map selection.
- [ ] **6.4 Observe RED** while navigation package is absent.
- [ ] **6.5 GREEN — Add navigation package** with route model, parser, controller, delegate, and navigation contract.
- [ ] **6.6 Keep it dormant.** Do not edit `TrueCrimeApp`, activate placeholders, call `usePathUrlStrategy`, or use `dart:html`.
- [ ] **6.7 Observe GREEN** on parser/router tests.
- [ ] **6.8 TRIANGULATE** encoded/unknown routes, repeated restoration, a deep link applied while `workspaceProvider` holds `Workspace.intake`, and preserved map selection.
- [ ] **6.9 REFACTOR and verify** full tests/analyze and unchanged public behavior.
- [ ] **6.10 Apply line-budget gate.** Split at 1500 or more.
- [ ] **6.11 Review and deliver** as `feat(navegacion): prepara las rutas hash de expedientes`.

## Unit 7 — Activate Complete Hash Routing and Expanded Detail

**Depends on:** Units 4 and 6.

**Finish state:** routing activates only with complete loading/error/not-found/known-case responsive detail.

- [ ] **7.1 RED — Slug lookup.** Test loading/error/exact match/missing slug and no map-provider access. **The match tests MUST use a hand-built fixture where `id != slug`** (for example `id: 'legacy-7'`, `slug: 'known-case'`) and MUST assert that the `id` value does *not* resolve. Every case in the real catalog has `id == slug`, so a real or exported fixture cannot tell slug lookup from ID lookup and proves nothing.
- [ ] **7.2 RED — All detail states.** Add `case_detail_page_test.dart` for loading, catalog error, unknown slug, known legacy/chapter case, expanded shared content, return, and related slug navigation.
- [ ] **7.3 RED — Responsive reading.** Prove realistic compact/wide scrolling, reachable actions, and no blocking overflow.
- [ ] **7.4 Observe RED** before provider/page implementation.
- [ ] **7.5 GREEN — Complete detail surface.** Add slug provider and `CaseDetailPage` with all states and direct expanded shared composition.
- [ ] **7.6 GREEN — Route-specific navigation.** Wire related and return actions; keep generic unknown syntax distinct and map state unchanged.
- [ ] **7.7 Observe detail GREEN before root activation.** App root remains old.
- [ ] **7.8 RED — Application activation.** Convert `TrueCrimeApp` to a `StatefulWidget` so controller and delegate are created once; it is a `StatelessWidget` today (`true_crime_app.dart:6`) and "create once" is otherwise impossible. Mount it and require Router ownership for all routes and restoration, while proving the router still never writes `workspaceProvider`.
- [ ] **7.9 GREEN — Activate complete graph.** Switch to `MaterialApp.router`, creating controller/delegate once.
- [ ] **7.10 Observe router GREEN** across parser/router/provider/detail/host tests.
- [ ] **7.11 TRIANGULATE** slug identity against an `id != slug` fixture, no map prerequisite, A→B routes/history, root restoration, and legacy presentation.
- [ ] **7.11b RED — Return from a deep link while intake is open.** Design §7.4 now specifies that the root reveals whatever `workspaceProvider` already held. Assert it directly: with `workspaceProvider` holding `Workspace.intake`, apply a case deep link, then return; the root MUST show `IntakeWorkspaceScreen`, not the Situation Room. This replaced a removed guarantee and would otherwise ship unasserted.
- [ ] **7.12 Verify structural boundaries.** Confirm no `dart:html`/path strategy and inspect `web/index.html` plus deployment workflow at their boundary.
- [ ] **7.13 REFACTOR and verify** full tests/analyze.
- [ ] **7.14 Apply line-budget gate.** Forecast maximum 360; split at 1500.
- [ ] **7.15 Review and deliver** as `feat(navegacion): activa el detalle público por hash`.

## Unit 8 — Published-Case Directory

**Depends on:** Unit 7.

**Finish state:** one adaptive directory reuses loaded catalog and preserves map behavior.

- [ ] **8.1 RED — Ordering/reuse.** Test every loaded case, year-desc/title-asc/slug-asc order, legacy cases, and no independent load.
- [ ] **8.2 RED — States/navigation.** Test loading/error/retry/empty/list, modal close, and exact slug navigation.
- [ ] **8.3 RED — Responsive access.** Test three topologies, not two: rail-less mobile below 880, **desktop-without-rail between 880 and 1099** (`breakpoints.dart:13,22` — `_DesktopBody` with `showRail: false`, so the rail icon entry point does not exist there), and desktop with rail at 1100 or above. Each must expose a reachable entry point, scroll, navigate, and show no blocking overflow.
- [ ] **8.4 RED — Map preservation.** Prove directory actions do not alter filters, selection, recenter, markers, or compact dossier.
- [ ] **8.5 Observe RED** with bounded pumps.
- [ ] **8.6 GREEN — Derived provider.** Derive complete ordered directory only from `casesProvider`.
- [ ] **8.7 GREEN — Adaptive directory.** Add mobile safe-area bottom sheet and constrained wide modal.
- [ ] **8.8 GREEN — Entry points.** Activate rail icon, rail-less map-stage control, and shared home navigation.
- [ ] **8.9 Observe GREEN** on focused tests.
- [ ] **8.10 TRIANGULATE** ordering fallback, excluded ranks, legacy inclusion, scrolling, slug navigation, and map preservation.
- [ ] **8.11 REFACTOR and verify** full tests/analyze.
- [ ] **8.12 Apply line-budget gate.** Split at 1500 or more.
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
- Every source-bearing unit records fewer than 1500 actual changed lines.
- Every unit passes focused tests, `flutter test`, and `flutter analyze`.
- No PR was created; direct-main commits use Spanish conventional messages without AI attribution.
- Built host-document and deployed browser evidence are complete.
- `assets/data/cases.json` remains unchanged unless separately authorized.
- No `intake-responsive` scope was touched before legitimate archive.
