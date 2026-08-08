# Design: Responsive Intake Workspace

## Technical Approach

Three layers, each with its own trigger:

1. **Naming layer** — one `Breakpoints` token file. It renames the four live thresholds; it does not unify them (see D1/D2).
2. **Workspace layer** — `MediaQuery` width gate in `intake_workspace_screen.dart`: three-pane above `Breakpoints.intakeThreePane`, single scrolling form plus two in-body overlays below. Mirrors `home_page.dart`'s `_DesktopBody`/`_MobileBody` swap.
3. **Row layer** — section rows gate on their **own** `LayoutBuilder` constraints, not on screen width. Sections are nested inside a variable-width column, so screen width is the wrong signal; local constraints make them correct at any nesting, including the still-tight desktop column at 1024–1180px.

## Architecture Decisions

### D1 — The four thresholds do NOT collapse into one scale

| Threshold | Concern | Kind of decision |
|---|---|---|
| 880 | desktop vs mobile body | layout topology |
| 980 | top bar `compact` | content density |
| 1024 | panel 320 vs 362 | size step |
| 1100 | nav rail | chrome affordance |

**Choice**: keep all four values byte-identical, express them as four named tokens in one file. "Shared vocabulary" = shared *source*, not a single number.
**Rejected**: a compact/medium/expanded scale — any single cut point changes rendered output somewhere in 880–1100 on a live screen with 15 published cases. Rejected: leaving them inline — intake would re-derive its own numbers, which is the drift the proposal exists to stop.
**Note for spec**: the proposal's criterion "One shared breakpoint constant" must be read as *one shared breakpoint source, zero inline literals in `home_page.dart`*.

### D2 — Token file lives at `lib/core/layout/breakpoints.dart`, as a class

**Choice**: new `lib/core/layout/` subfolder; `abstract final class Breakpoints` with static consts.
**Rejected**: `lib/core/config/` — that folder is Riverpod *runtime* config (`map_config.dart` exports three providers); breakpoints are compile-time tokens with no provider. `lib/core/theme/` — `app_theme.dart` owns colour/type tokens fed into `ThemeData`; width thresholds are a second concern. Bare `lib/core/breakpoints.dart` — breaks the existing subfolder-per-concern shape. Top-level `k`-prefixed consts (`kTimelineMinYear`, `kIntakeSharedKey`, `kMonoFamily`) — that prior art is for a *single* constant declared beside its one consumer; this is a *set* of related presentation tokens with many consumers, which is the `AppColors` shape.

```dart
abstract final class Breakpoints {
  static const double sidePanel = 880;      // home: mapa + panel lateral
  static const double topBarFull = 980;     // home: métricas + selector global
  static const double widePanel = 1024;     // home: panel 362 en vez de 320
  static const double navRail = 1100;       // home: rail lateral
  static const double intakeThreePane = 1024; // intake: lista + form + preview
  static const double formRowStack = 520;   // fila de campos -> columna
}
```

### D3 — Narrow sheets reuse the `_MobileBody` idiom, not `showModalBottomSheet`

**Choice**: in-body `Stack` + `Positioned` container, visibility driven by two `StateProvider<bool>`.
**Rationale**: `showModalBottomSheet` pushes a route **with a modal barrier**. The confirmed product decision requires the editor to keep typing behind an open preview — a barrier makes that impossible. (Riverpod itself is not the obstacle: `ProviderScope` sits above `MaterialApp`, so a sheet route would still rebuild live; the barrier is.) `showBottomSheet` removes the barrier but needs imperative `ScaffoldState` management and fights the keyboard. The manual idiom is already proven at this exact width in the live product, and keeps `Navigator` out of the widget tests (today every intake test pumps `MaterialApp(home: ...)` with no push flow).
**Consequence**: the preview overlay gets **no scrim** (taps fall through to the form); the draft-list overlay gets an explicit `Positioned.fill` `GestureDetector` scrim so tap-outside dismisses, because picking a draft *is* a terminating modal choice.
**Sizing**: preview `height * 0.5` (not `_MobileBody`'s `0.6`) so ~200px of form stays visible and tappable behind it.

### D4 — `CaseDossierPanel` works as-is at 360px; no change required

Budget: 360 − 24 (sheet margins) = 336 sheet; − 48 (panel padding) = **288px content**.

| Widget | Verdict |
|---|---|
| `_PhotoStrip` | **Safe.** A horizontal `ListView` gives children unbounded main-axis extent — 165px items scroll in a 288px viewport, they never overflow. The exploration's flag is a false positive. |
| `_StatsGrid` | **Safe.** 3 `Expanded` cells + 2×1px dividers ⇒ 95px/cell, 69px after padding. Widest label `CONEXIONES` ≈ 58px at mono 8 + 1 letterSpacing. Values already carry `maxLines: 1, overflow: ellipsis`. |
| `_Header`, `_Footer` | **Safe.** Already `Flexible` + `Expanded` with ellipsis. |

Only degradation: the `COORDS` stat value ellipsizes. Acceptable — the mandatory-readability product decision is satisfied by `_CoordinatesLine` in the form, and the dossier cell is a duplicate of it. **Optional 1-line hardening** (not required): `maxLines: 1, overflow: ellipsis` on `_StatCell`'s label, which removes the clip risk below 320px. Rebuilding stays out of scope; a widget test at 336px pins this verdict.

### D5 — One shared row widget, not six bespoke fallbacks

Four of the five broken sites are the same shape (fields + optional fixed-width dropdown + delete icon). `sections/intake_field_row.dart`:

```dart
IntakeFieldRow(
  fields: [ IntakeFieldSlot.fixed(dateField, width: 120),
            IntakeFieldSlot.flexible(titleField),
            IntakeFieldSlot.fixed(kindDropdown, width: 170) ],
  trailing: removeButton,       // minRowWidth: Breakpoints.formRowStack
)
```

`LayoutBuilder`: `maxWidth >= minRowWidth` → today's exact `Row` (fixed→`SizedBox`, flexible→`Expanded`, 10px gaps). Below → `Column(stretch)` of full-width fields, with `trailing` right-aligned **first**, so a delete tap never sits next to the "Añadir …" button underneath.

`_CoordinatesLine` is the one exception: it is a text line, not fields, and the product decision says *wrap, never truncate* → `Wrap(spacing: 12, runSpacing: 4)`, with the spinner + "Buscando el lugar…" grouped into a single `Row(mainAxisSize: min)` child so they cannot split across runs.

### D6 — "Last edited draft" is approximated, and only on narrow

`CaseDraft` persists no edit timestamp and `editDraft` preserves list order, so "last edited" is not derivable. Narrow body schedules one post-frame callback: if `editingDraftId == null && drafts.isNotEmpty`, select `drafts.last` (most recently created). Desktop keeps its "Crea o selecciona un borrador" placeholder untouched.
**Rejected**: adding `updatedAt` to `CaseDraft` — a domain + JSON-storage + exporter change outside the proposal's affected areas.

### D7 — Export stays in the top bar, compacted

`_WorkspaceTopBar` **also overflows at 360px** (≈476px of content) — a sixth broken row nobody listed. Narrow bar becomes `[back] [Flexible title, ellipsis] [drafts] [preview] [export] [new draft]` = 5×40px icons + ~128px title. `ExportCaseButton` gains `compact: bool`, rendering an `IconButton` with the **same** `Key('intake-export-button')`, same `Tooltip`, same enable rule, same clipboard/snackbar path — so `export_case_button_widget_test.dart` is untouched and the export logic is not duplicated. Same treatment for `intake-new-draft-button`.
**Rejected**: a `PopupMenuButton` overflow menu — hides the meaningful disabled state and adds a new interaction concept.

## Data Flow

```
MediaQuery.width ──> IntakeWorkspaceScreen
        │
        ├─ >= 1024 ──> Row[ _DraftList(260) | _IntakeFormColumn | IntakePreviewPanel(380) ]
        │
        └─ <  1024 ──> Stack
                        ├ Positioned.fill  _IntakeFormColumn        (same widget, keyed)
                        ├ intakePreviewOpen  -> Positioned sheet, NO scrim  (typing continues)
                        └ intakeDraftListOpen-> scrim + Positioned sheet

editingDraftIdProvider ──> editingDraftProvider ──> sections ──┐
                                        └──> draftPreviewCaseProvider ──> IntakePreviewPanel
                                             (rebuilds live while the sheet is open)

LayoutBuilder(constraints.maxWidth) ──> IntakeFieldRow ──> Row | Column
```

`_IntakeFormColumn` is extracted from `_FormAndPreview` and used by **both** branches; both keep `ValueKey(editingDraftId)`, which `intake_draft_switch_test.dart` depends on.

## File Changes

| File | Action | Description |
|---|---|---|
| `lib/core/layout/breakpoints.dart` | Create | The six tokens (D2). |
| `lib/features/home/presentation/home_page.dart` | Modify | 880/980/1024/1100 → tokens. Values identical. |
| `lib/features/cases/presentation/intake/sections/intake_field_row.dart` | Create | `IntakeFieldRow` + `IntakeFieldSlot` (D5). |
| `.../sections/timeline_section.dart` | Modify | Row → `IntakeFieldRow` (120 / flex / 170 + delete). |
| `.../sections/links_section.dart` | Modify | Row → `IntakeFieldRow` (flex / flex / 170 + delete). |
| `.../sections/photos_section.dart` | Modify | Row → `IntakeFieldRow` (flex / flex + delete). |
| `.../sections/location_section.dart` | Modify | `_CoordinatesLine` → `Wrap`; `_FineTuning` → `IntakeFieldRow`. |
| `.../intake/intake_workspace_screen.dart` | Modify | Width gate, `_IntakeFormColumn` extraction, narrow `Stack`, compact top bar, landing callback. |
| `.../intake/export_case_button.dart` | Modify | `compact` flag, same key/tooltip/logic. |
| `.../application/case_draft_providers.dart` | Modify | `intakeDraftListOpenProvider`, `intakePreviewOpenProvider` (`StateProvider<bool>`). |
| `test/situation_breakpoints_test.dart` | Create | Behaviour lock for home at 1440/1050/1000/900/800. |
| `test/intake_field_row_test.dart` | Create | Row above / stacked below `formRowStack`. |
| `test/intake_narrow_layout_test.dart` | Create | 360×780 end-to-end intake. |
| `test/intake_draft_switch_test.dart` | Modify | Delete the `Size(1600, 1200)` override + its comment. |

## Testing Strategy

| Layer | What | How |
|---|---|---|
| Widget (lock) | Home renders identically at 1440/1050/1000/900/800 | `find.byType(SituationNavRail)`, `tester.getSize(find.byType(SituationSidePanel)).width` (362 vs 320), `find.byKey('mobile-case-sheet')`, metrics text present/absent. `MapConfig.testing()`, `tester.pump(Duration(milliseconds: 400))`. |
| Widget (unit-ish) | `IntakeFieldRow` | Pump at 800 → one `Row`, fields side by side; at 360 → stacked, each field full width, trailing right-aligned above. |
| Widget | Narrow intake at 360×780 | `expect(tester.takeException(), isNull)` as the overflow canary after every pump; toggle drafts sheet → tap draft → sheet closes, form shows its values; toggle preview → **type into `intake-field-title` with the sheet still open** → preview text updates and the sheet is still found; `intake-export-button` present and enabled for a complete draft. |
| Widget | `_CoordinatesLine` | At 336px with `resolving: true`, both `intake-coordinates-label` and `intake-geocoding-status` found, no exception. |
| Widget | Dossier at 336px | `CaseDossierPanel` in a 336px box with photos + 3 stats → no exception (pins D4). |
| Regression | Existing 140 | Section tests pump sections directly at 800px, above `formRowStack` → unchanged. Only `intake_draft_switch_test.dart` pumps the whole screen; at 800×600 it now takes the narrow branch, all sections still mounted inside `SingleChildScrollView`, assertions unchanged. |

**TDD note**: commit 1's lock tests are characterization tests — GREEN before *and* after the migration. This is a deliberate, scoped deviation from RED-first, appropriate for a behaviour-preserving rename; commits 2–4 are RED-first.

## Threat Matrix

N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary. Pure Flutter presentation layer.

## Migration / Rollout

Four independently revertible commits, matching the proposal's rollback plan:

| # | Commit | Contents | Revert impact |
|---|---|---|---|
| 1 | `test: fija el comportamiento responsive de la Sala` + `refactor: unifica los breakpoints` | Lock tests, `breakpoints.dart`, `home_page.dart` migration | `git revert` restores inline literals. Intake needs only the constant to *exist*, so commits 2–4 survive. |
| 2 | `fix: las filas del formulario se apilan en pantallas estrechas` | `IntakeFieldRow` + 4 call sites + `_CoordinatesLine` `Wrap` | Independent; no workspace change. |
| 3 | `feat: el formulario de casos funciona en móvil` | Workspace narrow branch, providers, compact top bar, `ExportCaseButton.compact` | Depends on 1 (token) and 2 (rows). |
| 4 | `test: el workspace se prueba en viewport real` | Drop `Size(1600, 1200)` | Trivially revertible. |

No data migration, no feature flag, no schema change.

## Open Questions

- [ ] `LocationPickerMap` inside a `SingleChildScrollView` on touch: a vertical drag pans the map instead of scrolling the page. Pre-existing, but far more visible once the form is the whole screen. Not blocking; flag for a follow-up change.
- [ ] `Breakpoints.formRowStack = 520` is derived from the timeline row's minimum (120 + 10 + ~140 + 10 + 170 + 40 ≈ 490). One shared value means the photos row (needs ~330) stacks earlier than strictly necessary. `IntakeFieldRow.minRowWidth` is the per-call escape hatch if that reads badly.
