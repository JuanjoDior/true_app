# Tasks: Responsive Intake Workspace

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~750-950 (4 new files, 8 modified files, 3 new test files) |
| 400-line budget risk | High (single-pr session budget is 1000 lines, not the 400-line PR guard) |
| Chained PRs recommended | No — delivery is direct commits to `main`, no PR flow |
| Suggested split | Single delivery, 4 independently revertible commits (see Commit Sequence) |
| Delivery strategy | single-pr |
| Chain strategy | not applicable — no PR workflow; direct commits to `main` |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: pending
400-line budget risk: High

Note: this repo delivers via direct commits to `main` (no PR flow), so the 400-line PR guard does not apply. The governing budget is the session's 1000 changed-line ceiling. Estimated total stays under it; the 4-commit sequence below exists for independent revertibility (per the proposal's rollback plan), not to satisfy a PR-size guard.

### Suggested Work Units

| Unit | Goal | Likely Commit | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Shared `Breakpoints` + `home_page.dart` migration, behavior-preserving | Commit 1 | `flutter test test/situation_breakpoints_test.dart` | N/A — pure widget-test coverage, no external runtime | `git revert` of commit 1 alone restores inline literals; commits 2-4 unaffected |
| 2 | `IntakeFieldRow` + 4 call sites + `_CoordinatesLine` `Wrap` | Commit 2 | `flutter test test/intake_field_row_test.dart test/location_section_widget_test.dart test/photos_section_widget_test.dart` | N/A — pure widget-test coverage | Independent of workspace change; revertible alone |
| 3 | Workspace narrow branch, providers, compact top bar, `ExportCaseButton.compact` | Commit 3 | `flutter test test/intake_narrow_layout_test.dart test/export_case_button_widget_test.dart` | N/A — pure widget-test coverage | Depends on commits 1 and 2 landing first |
| 4 | Drop forced `Size(1600, 1200)` viewport in draft-switch test | Commit 4 | `flutter test test/intake_draft_switch_test.dart` | N/A — pure widget-test coverage | Trivially revertible, single-file diff |

## Phase 1: Shared Breakpoints (Commit 1 — characterization tests, byte-identical migration)

- [x] 1.1 **[CHARACTERIZATION — GREEN before and after, not RED-first]** Create `test/situation_breakpoints_test.dart`: lock `_DesktopBody`/`_MobileBody` and top-bar compact selection at widths 1440/1050/1000/900/800, asserting `find.byType(SituationNavRail)` presence, `tester.getSize(find.byType(SituationSidePanel)).width` (362 vs 320), `find.byKey('mobile-case-sheet')`, metrics-row/global-pill presence. Use `MapConfig.testing()` and `tester.pump(const Duration(milliseconds: 400))`, never `pumpAndSettle`. Run and confirm GREEN against current `home_page.dart` (pre-migration) — satisfies Requirement: Sala de Situación Layout Selection Is Behavior-Preserving.
- [x] 1.2 Create `lib/core/layout/breakpoints.dart`: `abstract final class Breakpoints` with `static const double sidePanel = 880`, `topBarFull = 980`, `widePanel = 1024`, `navRail = 1100`, `intakeThreePane = 1024`, `formRowStack = 520` — satisfies Requirement: Centralized Breakpoint Constants.
- [x] 1.3 Modify `lib/features/home/presentation/home_page.dart`: replace all four inline literals (880/980/1024/1100) with `Breakpoints.sidePanel`/`.topBarFull`/`.widePanel`/`.navRail`. Verify zero remaining inline width-comparison literals.
- [x] 1.4 Re-run `flutter test test/situation_breakpoints_test.dart` — confirm still GREEN post-migration (characterization proves byte-identical behavior; no RED cycle required per design's deliberate TDD deviation).
- [x] 1.5 Run `flutter analyze` — confirm clean.
- [ ] 1.6 Commit as its own independently revertible unit: `test: fija el comportamiento responsive de la Sala` + `refactor: unifica los breakpoints`.

## Phase 2: Section Row Fallbacks (Commit 2)

- [ ] 2.1 RED: create `test/intake_field_row_test.dart` — pump `IntakeFieldRow` at width 800 (above `formRowStack`) expecting one `Row` with fields side by side; pump at width 360 (below `formRowStack`) expecting a stacked `Column` with each field full width and `trailing` right-aligned above the fields. Confirm RED (widget does not exist yet).
- [ ] 2.2 GREEN: create `lib/features/cases/presentation/intake/sections/intake_field_row.dart` with `IntakeFieldRow` + `IntakeFieldSlot.fixed(width)`/`.flexible()`. `LayoutBuilder`: `maxWidth >= minRowWidth` (default `Breakpoints.formRowStack`) → `Row` (fixed→`SizedBox`, flexible→`Expanded`, 10px gaps, matching today's exact layout); below → `Column(stretch)` with `trailing` right-aligned first, fields full-width below. Confirm test 2.1 GREEN.
- [ ] 2.3 RED: extend `test/location_section_widget_test.dart` (or a dedicated case) asserting `_CoordinatesLine` at 336px with `resolving: true` shows both `intake-coordinates-label` and `intake-geocoding-status`, wraps instead of truncating, and `tester.takeException()` is `isNull`. Confirm RED against current fixed-width `Row`.
- [ ] 2.4 GREEN: modify `.../sections/location_section.dart` — `_CoordinatesLine` becomes `Wrap(spacing: 12, runSpacing: 4)`, spinner + "Buscando el lugar…" grouped in a single `Row(mainAxisSize: min)` child so they never split across runs. Confirm test 2.3 GREEN.
- [ ] 2.5 GREEN (same commit, no separate RED — reuses 2.1's proven `IntakeFieldRow`): migrate `.../sections/timeline_section.dart` row to `IntakeFieldRow` (date 120 fixed / title flexible / kind dropdown 170 fixed / delete trailing).
- [ ] 2.6 GREEN: migrate `.../sections/links_section.dart` row to `IntakeFieldRow` (title flexible / URL flexible / kind dropdown 170 fixed / delete trailing).
- [ ] 2.7 GREEN: migrate `.../sections/photos_section.dart` row to `IntakeFieldRow` (fields flexible / delete trailing).
- [ ] 2.8 GREEN: migrate `_FineTuning` in `.../sections/location_section.dart` (ISO code, latitude, longitude fields) to `IntakeFieldRow`.
- [ ] 2.9 Extend `test/photos_section_widget_test.dart` (and equivalent timeline/links coverage as needed) at 360x640 asserting zero `RenderFlex overflowed` via `expect(tester.takeException(), isNull)` — satisfies spec scenarios "Timeline row does not overflow", "Links row does not overflow", "Photos row does not overflow", "Fine-tuning fields do not overflow".
- [ ] 2.10 Regression check: run existing section tests (which pump at 800px, above `formRowStack`) — confirm unchanged `Row` behavior preserved.
- [ ] 2.11 Run `flutter test` (full suite) + `flutter analyze` — confirm green/clean.
- [ ] 2.12 Commit: `fix: las filas del formulario se apilan en pantallas estrechas`.

## Phase 3: Workspace Narrow Branch (Commit 3)

- [ ] 3.1 RED: create `test/intake_narrow_layout_test.dart` at 360x780 (`tester.view.physicalSize` + `tester.view.devicePixelRatio`, `addTearDown(tester.view.reset)`). Assert: form shows full-screen by default, draft list and preview not permanently visible; `expect(tester.takeException(), isNull)` after every pump as the overflow canary. Confirm RED (narrow branch does not exist yet).
- [ ] 3.2 Add to the same RED file: tapping the draft-list affordance opens an overlay with scrim, every draft selectable, tap-outside dismisses; tapping the preview affordance opens a sheet with **no scrim** at `height * 0.5`; typing into `intake-field-title` with the preview sheet still open updates the preview text live and the sheet remains found (satisfies Requirement: Live Preview Behind an Open Sheet).
- [ ] 3.3 Add to the same RED file: with zero drafts, opening the workspace auto-creates a blank draft and the form opens on it, no intermediate screen; with existing drafts, opening lands on `drafts.last` (approximated "last edited"), not the draft list.
- [ ] 3.4 Add to the same RED file: `intake-export-button` present and enabled for a complete draft at 360px; create/delete draft and export all complete with the same outcome as desktop (satisfies Requirement: Full Affordance Parity at Narrow Width).
- [ ] 3.5 Add to the same RED file (or a focused addition): `CaseDossierPanel` rendered inside a 336px-wide container (preview sheet content) produces no `RenderFlex overflowed` exception — pins design decision D4 (no code change needed in `CaseDossierPanel` itself).
- [ ] 3.6 GREEN: modify `.../application/case_draft_providers.dart` — add `intakeDraftListOpenProvider` and `intakePreviewOpenProvider` (`StateProvider<bool>`).
- [ ] 3.7 GREEN: modify `.../intake/intake_workspace_screen.dart` — extract `_IntakeFormColumn` from `_FormAndPreview`, reused by both desktop and narrow branches, both keeping `ValueKey(editingDraftId)` (required by `intake_draft_switch_test.dart`). Add `MediaQuery`-width gate at `Breakpoints.intakeThreePane`: `>= 1024` keeps the current `Row[_DraftList(260) | _IntakeFormColumn | IntakePreviewPanel(380)]` untouched; `< 1024` renders a `Stack` with `Positioned.fill _IntakeFormColumn`, a no-scrim `Positioned` preview sheet at `height * 0.5` gated by `intakePreviewOpenProvider`, and a scrim + `Positioned` draft-list sheet gated by `intakeDraftListOpenProvider`.
- [ ] 3.8 GREEN: add the landing behavior — one post-frame callback in the narrow branch: if `editingDraftId == null && drafts.isEmpty`, create a blank draft and select it; if `editingDraftId == null && drafts.isNotEmpty`, select `drafts.last`. Desktop's "Crea o selecciona un borrador" placeholder stays untouched.
- [ ] 3.9 GREEN: compact the narrow top bar to `[back] [Flexible title, ellipsis] [drafts] [preview] [export] [new draft]` (5×40px icons + ~128px title), gated at `Breakpoints.topBarFull`-equivalent narrow-workspace check per design D7.
- [ ] 3.10 GREEN: modify `.../intake/export_case_button.dart` — add `compact: bool` flag rendering an `IconButton` with the **same** `Key('intake-export-button')`, same `Tooltip`, same enable rule, same clipboard/snackbar path. Do not change `test/export_case_button_widget_test.dart`.
- [ ] 3.11 Confirm all Phase 3 RED assertions (3.1-3.5) now GREEN.
- [ ] 3.12 Regression check: run `test/intake_draft_switch_test.dart` as-is (still forcing `Size(1600, 1200)` at this point) — confirm the `ValueKey(editingDraftId)`-dependent draft-switch assertions still pass through the extracted `_IntakeFormColumn`.
- [ ] 3.13 Run `flutter test` (full suite) + `flutter analyze` — confirm green/clean.
- [ ] 3.14 Commit: `feat: el formulario de casos funciona en móvil`.

## Phase 4: Test Viewport Cleanup (Commit 4)

- [ ] 4.1 RED: temporarily note that `test/intake_draft_switch_test.dart` still forces `Size(1600, 1200)`; this task's RED is verifying the test currently depends on the oversized viewport being removable without narrowing its assertions (design decision, not new behavior — the GREEN state before this edit already passes at 1600x1200; the RED/GREEN pair here is: remove the override, confirm behavior at the default 800x600 test viewport).
- [ ] 4.2 GREEN: modify `test/intake_draft_switch_test.dart` — remove the `Size(1600, 1200)` override (`tester.view.physicalSize` / `devicePixelRatio` forcing call) and its associated comment; keep every draft-switch assertion (`ValueKey(editingDraftId)` behavior) unchanged. At the default 800x600 viewport this now exercises the narrow branch (below `Breakpoints.intakeThreePane = 1024`) — confirm all sections still mount inside `SingleChildScrollView` and assertions pass unmodified.
- [ ] 4.3 Confirm `test/intake_form_widget_test.dart`'s `tester.ensureVisible` call before dropdown taps is still present and still needed — do not silently delete it; it remains the overflow-masking regression canary per the design.
- [ ] 4.4 Run `flutter test` (full suite, expect 140 + new tests green) + `flutter analyze` — confirm green/clean, satisfying the proposal's Success Criteria checklist.
- [ ] 4.5 Commit: `test: el workspace se prueba en viewport real`.
