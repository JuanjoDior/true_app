# Exploration: intake-responsive

> Source: Engram observation `sdd/intake-responsive/explore` (#438), persisted to the
> repository as part of the switch from Engram-backed to file-based SDD artifacts.

## Current State

**Responsive precedent (Sala de Situación, `lib/features/home/presentation/home_page.dart`)**
- Breakpoints are inline magic numbers in `TrueCrimeHomePage.build`, not a shared constant: `showRail = width >= 1100`, `showSidePanel = width >= 880`, top bar `compact = width < 980`. Three distinct thresholds, no `kBreakpoint*` file exists anywhere in `lib/` (verified via grep — only three `MediaQuery.sizeOf` call sites total, all in home_page.dart).
- Desktop body (`_DesktopBody`, showSidePanel branch) = `Row([rail?, Expanded(map), SituationSidePanel(width: panelWidth)])`, panelWidth itself narrows from 362 to 320 at width<1024 (a 4th ad hoc threshold).
- Mobile body (`_MobileBody`, width<880) = full-bleed map (`Stack` + `Positioned.fill`) with the selected case's `CaseDossierPanel` shown as a floating rounded "sheet" (`Positioned` with 12px margins, `height: MediaQuery.height*0.6`), not a real `showModalBottomSheet` — it's a manually positioned `Container`, always mounted (conditionally built), animated only via presence/absence of `selected`.
- `SituationTopBar(compact: width<980)` hides the metrics row and global pill but keeps search + intake entry button always visible, so the intake entry point (`_IntakeEntryButton`, key `top-bar-intake-entry`) is reachable at any width, including phone widths — the top bar itself has no responsive `Row` overflow guard beyond that `compact` flag.
- `SituationNavRail` (64px fixed) also has its own `add_box` intake entry (`nav-rail-intake-entry`), but it's gone below 1100px, so on mobile the top-bar button is the only entry.
- Conclusion: there is a real, working pattern (width-gated body swap + reused detail panel as an overlay) but it is not extracted into shared breakpoint constants or a reusable widget — each screen re-derives its own numbers.

**What breaks in intake (`lib/features/cases/presentation/intake/intake_workspace_screen.dart`)**
- `_IntakeFormBody.build` (~line 45): outer `Row` = `SizedBox(width: 260, child: _DraftList)` + `Expanded(child: _FormAndPreview or placeholder)`. No responsive branch at all — always a 3-way desktop layout attempt.
- `_FormAndPreview` (line 172-202): inner `Row` = `Expanded(SingleChildScrollView(form))` + `SizedBox(width: 380, child: IntakePreviewPanel())`. This is the second fixed width that guarantees overflow under ~1000px combined with the 260px list.
- `TimelineSection` (`sections/timeline_section.dart` lines 46-127): per-row `Row` = `SizedBox(width:120, date field)` + `Expanded(title field)` + `SizedBox(width:170, kind dropdown)` + `IconButton` delete — four fixed/flex children with no wrap.
- `LinksSection` (`sections/links_section.dart` lines 41-115) and `PhotosSection` (`sections/photos_section.dart` lines 41-86): same shape — `Expanded` title/url + (Links only) `SizedBox(width:170)` kind dropdown + `IconButton`. Links has 3 columns, Photos has 2, both fail once column widths shrink because the two `Expanded` fields must share whatever is left after fixed widths.
- `LocationSection._CoordinatesLine` (`sections/location_section.dart` lines 143-193): `Row` with a mono coordinate label + conditional spinner + "Buscando el lugar…" text, no `Flexible`/`Wrap` — this is the widget the user's PROBLEM statement says threw the observed `RenderFlex overflowed` exception, because it's nested inside the already-too-narrow form column.
- `LocationSection._FineTuning` (lines 219-281): three `Expanded` fields (ISO code, latitude, longitude) side by side inside an `ExpansionTile` — same squeeze pattern once the parent column is narrow.
- `LocationPickerMap` (`location_picker_map.dart`): fixed `height: 240` (not width — width already comes from its narrow parent), so this one is not itself an overflow source, but it inherits whatever width the (broken) parent gives it.

**Map interaction config**
- `LocationPickerMap`'s `MapOptions` sets `initialCenter/Zoom/min/maxZoom/onTap` but **does not set `interactionOptions` at all**, so flutter_map 8.2.2 defaults apply: `InteractiveFlag.all` (drag pan + pinch zoom + two-finger rotate + double-tap zoom) plus the custom `onTap` for placing the marker.
- By contrast, the *browse* map (`situation_map_stage.dart` line 107) explicitly sets `interactionOptions: InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate)` — rotate is deliberately disabled there. The intake map has no equivalent, so it is the only map in the app where two-finger rotate is still live, which is an inconsistency (not obviously an overflow bug, but a touch-affordance risk: accidental rotation while trying to pinch-place a pin precisely).
- flutter_map's own gesture arena already disambiguates single tap (→ `onTap`) from drag/pinch, so there's no confirmed conflict between "tap to place" and pan — this is a lower-severity finding than the layout overflow.

**Testing patterns**
- `test/location_section_widget_test.dart` documents the flutter_map gotcha directly in a comment (lines 93-101): `pumpAndSettle` never resolves because flutter_map's tap recognizer waits to disambiguate from double-tap, so tests must `await tester.tap(...); await tester.pump(const Duration(milliseconds: 400));` — codified as a private `_tapMap` helper. `PROJECT_CONTEXT.md` calls this out explicitly as a known trap.
- `test/intake_draft_switch_test.dart` forces `tester.view.physicalSize = Size(1600, 1200)` (with `addTearDown(tester.view.reset)`) specifically because the default 800x600 test viewport overflows the current 3-pane desktop layout — comment says this literally ("El workspace es de escritorio: en el viewport por defecto de 800x600 desborda, y ese es otro asunto").
- No test in the repo currently pumps a narrow/phone-sized viewport against the intake screen — there is no existing responsive-test precedent to imitate; `home_page` responsive branches (_DesktopBody/_MobileBody) also appear untested at a glance (not confirmed with a full test-file read, but no `_MobileBody`/`showRail` assertions were seen).

**Mobile reachability of intake (adjacent, not core)**
- Confirmed reachable: `_IntakeEntryButton` in `SituationTopBar` is unconditionally rendered (not gated behind `!compact`), so a phone user CAN tap into `Workspace.intake` today. The break happens *inside* the intake screen, not at the entry point.
- `IntakeGateScreen` (`intake_gate_screen.dart`) is already narrow-safe: `ConstrainedBox(maxWidth: 360)` + `Column` — no fixed-width `Row`, no responsive work needed there.
- `CaseDossierPanel` (reused for both preview and published detail) is itself already width-flexible: it uses `Expanded`/`Flexible` throughout, and today survives being squeezed into the mobile bottom "sheet" (`_MobileBody`, effectively ~`calc(100vw-24px)` wide on a phone) without special-casing. This is strong evidence the preview panel itself does NOT need a rewrite for narrow widths — only its *container* (the 380px `SizedBox`) needs to change.

## Affected Areas

- `lib/features/cases/presentation/intake/intake_workspace_screen.dart` — the two nested fixed-width `Row`s (draft list 260px, preview 380px) that must become responsive.
- `lib/features/cases/presentation/intake/sections/location_section.dart` — `_CoordinatesLine` (unguarded `Row`, the one with the reported overflow exception) and `_FineTuning` (3 `Expanded` fields).
- `lib/features/cases/presentation/intake/sections/timeline_section.dart` — per-event `Row` with 120px date + expanded title + 170px kind dropdown + delete button.
- `lib/features/cases/presentation/intake/sections/links_section.dart` — per-link `Row` with 2 `Expanded` fields + 170px kind dropdown + delete button.
- `lib/features/cases/presentation/intake/sections/photos_section.dart` — per-photo `Row` with 2 `Expanded` fields + delete button.
- `lib/features/cases/presentation/intake/location_picker_map.dart` — no `interactionOptions` set; candidate for parity with `situation_map_stage.dart`'s rotate-disabled config.
- `lib/features/home/presentation/home_page.dart` — the only existing responsive precedent; breakpoints (1100 / 980 / 880 / 1024) are inline, not shared, so the intake redesign either reuses these ad hoc or the change introduces the first shared breakpoint constant in the app.
- `lib/features/home/presentation/widgets/situation/case_dossier_panel.dart` — already width-flexible; low risk, likely untouched, but its display mode (side panel vs sheet vs tab) inside intake is the crux of the Approach comparison below.
- `test/intake_draft_switch_test.dart` — currently masks the desktop-only overflow by forcing a 1600x1200 viewport; will need a companion narrow-viewport test once fixed, and this existing test's forced size should probably shrink back toward realistic desktop dimensions once the layout no longer needs it.
- `test/location_section_widget_test.dart`, `test/intake_form_widget_test.dart` — establish the `_tapMap`/400ms-pump and `ensureVisible`-before-tap patterns any new responsive test must reuse.
- `PROJECT_CONTEXT.md` "Pendiente" table — literally lists "El formulario sólo funciona en escritorio" as open/tracked; this change resolves that line item.

## Approaches

Core question: what happens to the three panes (draft list, form, live preview) on a phone. All four options below assume the same underlying breakpoint strategy as `home_page.dart` (width-gated body swap), differing only in how the *narrow* body is composed.

1. **Tabs (list / form / preview as three tab views)** — a `TabBar` swaps between the three regions inside one screen.
   - Pros: preview stays "live" and always one tap away; matches the existing pattern of swapping bodies wholesale (least novel interaction concept); straightforward to keep `CaseDossierPanel` untouched since it just becomes one tab's content.
   - Cons: hides the draft list behind a tab, so switching drafts requires two taps (open list tab, tap draft) instead of one; adds `TabController`/`DefaultTabController` state that doesn't exist anywhere else in intake; "Expediente Preview Parity" spec intent (preview always visible while editing) is broken since form and preview can't be seen simultaneously.
   - Effort: Medium.

2. **Stepper/wizard through the 6 form sections** — one section visible at a time with next/back, list and preview reachable via separate affordances (e.g. buttons/sheet).
   - Pros: solves the *form* overflow cleanly section-by-section (sections are already discrete via `kCaseFormSections`, so a stepper is a near-drop-in reuse of that registry); reduces cognitive load per screen.
   - Cons: biggest behavior change — turns a free-scrolling form into a linear flow, which the desktop version explicitly is not; live preview becomes awkward (no natural "current step" to show it next to); risks regressions in existing widget tests that assume all sections are simultaneously mounted (`intake_form_widget_test.dart` pumps all `kCaseFormSections` in one `Column` and expects fields visible without stepping) — those tests would need rework, not just a new mobile test.
   - Effort: High.

3. **Collapse the preview into a bottom sheet/toggle, keep form scrolling; draft list collapses similarly** — the form remains the single scrollable column at all widths (already how the form itself renders, since it's inside `SingleChildScrollView` today), sections' internal `Row`s get `Wrap`/stacked fallbacks, and the 380px preview + 260px list panels move into on-demand sheets/toggles.
   - Pros: smallest structural change — form section internals (timeline/links/photos rows, coordinates line, fine-tuning fields) need their own narrow-width fallback regardless of which option is chosen for the outer 3-pane question, so this approach adds the least *additional* work on top of that unavoidable baseline; matches the existing `_MobileBody` bottom-sheet idiom in `home_page.dart` almost exactly (reuse, not invention); `CaseDossierPanel` is proven to survive being squeezed into a sheet already.
   - Cons: preview-on-demand means the user doesn't see live updates unless they open the sheet, partially diluting "Expediente Preview Parity" (mitigated if the toggle is cheap/one-tap and state-preserving); draft list as a sheet/drawer needs its own interaction affordance (e.g. an app-bar icon) that doesn't exist today.
   - Effort: Medium.

4. **Push list and/or preview to separate routes (`Navigator.push`)** — draft list becomes its own screen you navigate to/from; selecting a draft pushes the form screen; preview becomes a separate route reached via a button.
   - Pros: cleanest mobile IA (one full-screen concern per route), no squeezing/overflow logic needed inside any single screen, most "native app" feeling.
   - Cons: biggest departure from current architecture — `IntakeWorkspaceScreen`/`_IntakeFormBody` currently hold `editingDraftIdProvider` state in one screen and never navigate; introducing routes means deciding how form-autosave-on-every-keystroke (`CaseDraftsNotifier.editDraft`) interacts with route lifecycle/back-button, and how the preview route stays "live" while editing happens on a different route (would need to watch the same providers, which works with Riverpod, but is more moving parts than a same-screen toggle); largest testing footprint change since existing tests pump one `MaterialApp(home: ...)` without a `Navigator` push flow to assert against.
   - Effort: High.

## Recommendation

Not chosen here — this is what `sdd-propose` should resolve with the user. Given the codebase evidence, Approach 3 (collapse preview/list into sheets or toggles, keep the form itself as the single responsive scrolling column with per-section `Row`→`Wrap`/stack fallbacks) has the shallowest diff relative to the existing width-gated-body-swap pattern already proven in `home_page.dart`, and it's the only option where the *baseline* work (fixing the six broken `Row`s) isn't thrown away no matter which outer-pane strategy is picked. Options 1 and 4 both cost more without clearly buying more parity with "Expediente Preview Parity." Option 2 (stepper) is the most invasive and risks silently changing tested desktop behavior if section-registry reuse isn't scoped carefully.

## Risks

- No shared breakpoint constant exists today (`home_page.dart` uses four different inline thresholds: 880, 980, 1024, 1100) — the proposal phase must decide whether to introduce one shared constant now (touches home_page.dart, a file outside intake) or keep magic numbers duplicated (drifts from precedent further).
- `test/intake_draft_switch_test.dart`'s forced `Size(1600, 1200)` viewport currently *hides* the overflow bug for its own test purposes; whatever fix ships must not accidentally rely on that oversized viewport remaining, and the existing test's viewport override may need to shrink/be removed once the layout is fixed, without breaking its actual assertions (draft-switch field refresh) which are unrelated to responsiveness.
- `intake_form_widget_test.dart`'s "the link kind dropdown offers the typed kinds" test already needs `tester.ensureVisible` before tapping a dropdown because the form "no longer fits the test viewport" — any responsive layout change should be checked against this test not regressing (or intentionally updated).
- `LocationPickerMap` has no `interactionOptions`, unlike the browse map; if the proposal touches the map at all for touch-target reasons, decide whether to also add `& ~InteractiveFlag.rotate` for parity — but this is a secondary/optional finding, not a blocker for the layout work.
- `CaseDossierPanel`'s internal fixed-width children (`_PhotoStrip` items 165px, `_StatCell`/`_StatDivider` in a `Row` of 3) were not exhaustively stress-tested at very narrow widths (e.g. <320px) in this exploration; it survives the current ~`calc(100vw-24px)` mobile sheet in `home_page.dart`, which is the best evidence available, but an extremely narrow device (e.g. 320px) was not verified.

## Ready for Proposal

Yes. The overflow sources are fully enumerated with file/line specificity, the existing responsive precedent is documented with its actual (non-uniform) breakpoints, and four concrete approaches with trade-offs are ready for the user to pick from in `sdd-propose`. Open decision for propose: which of the four approaches (or a hybrid) to commit to, and whether to introduce a shared breakpoint constant as part of this change or defer it.
