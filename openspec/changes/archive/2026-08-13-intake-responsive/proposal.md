# Proposal: Responsive Intake Workspace

## Intent

The intake form is desktop-only. `_IntakeFormBody` nests two fixed-width `Row`s (260px draft list, 380px preview) and six section-internal rows carry fixed/`Expanded` children with no narrow fallback — `_CoordinatesLine` already throws a live `RenderFlex overflowed`. Editors reach intake from a phone today (the top-bar entry and `IntakeGateScreen` are narrow-safe), then hit a broken screen. `PROJECT_CONTEXT.md` tracks this as open ("El formulario sólo funciona en escritorio"). Success: an editor drafts and publishes a case at 360px wide with no overflow, no lost affordance, and no regression on the public Sala de Situación.

## Scope

### In Scope

- Narrow layout for `intake_workspace_screen.dart`: form full-screen; draft list and live preview open on demand as sheets/overlays, reusing the `_MobileBody` idiom from `home_page.dart`. Desktop three-pane layout unchanged above the breakpoint.
- Narrow fallbacks for the six broken rows: `timeline_section.dart`, `links_section.dart`, `photos_section.dart`, `location_section.dart` (`_CoordinatesLine`, `_FineTuning`).
- A shared breakpoint module holding the four thresholds (880/980/1024/1100) currently inline in `home_page.dart`, plus the new intake ones. Named, not merged — see the decision below.
- Support down to **360px**. Remove the `Size(1600, 1200)` crutch in `test/intake_draft_switch_test.dart`; prove layout at narrow widths instead of avoiding them.

### Out of Scope

- Rebuilding `CaseDossierPanel` — already width-flexible and proven in the mobile sheet; only its 380px container changes.
- `LocationPickerMap.interactionOptions` rotate parity with `situation_map_stage.dart` — real inconsistency, not a blocker; flutter_map's gesture arena already disambiguates tap from pan/pinch.
- Place-name search on the map; mouse-wheel zoom over the map; manual lat/lon edits re-triggering geocoding.
- Widths below 360px; tablet-specific intermediate layout; visual redesign of any section.

## Capabilities

### New Capabilities

- `intake-responsive-layout`: how the intake workspace composes draft list, form and live preview per viewport width, and how each form section behaves when narrow.
- `responsive-breakpoints`: the shared width thresholds both the Sala de Situación and intake obey.

### Modified Capabilities

- None (`openspec/specs/` is empty; this cycle bootstraps it).

## Approach

Width-gated body swap, mirroring the proven precedent. Above the breakpoint the current `Row` composition is untouched. Below it, the form becomes the single scrolling column and the two panels move behind one-tap, state-preserving affordances. Section rows degrade to stacked/`Wrap` forms at narrow widths. Breakpoints move to one constant first, so the migration of `home_page.dart` and the new intake branch share a single source of truth.

## Confirmed Product Decisions

Answered by the user during the proposal question round. Each confirms the
assumption the proposal was already written against, so no rework followed.

| Question | Decision |
|----------|----------|
| Does publishing work from a phone? | **Yes, full parity.** Draft, preview and copy-JSON all work at 360px. The export affordance stays in scope for narrow widths. |
| Preview sheet while typing behind it | **Stays open and updates live.** This is what preserves part of the parity lost by not having the preview permanently visible. |
| Where intake lands on a phone | **The last edited draft.** The form is the full-screen default; the list is on demand. |
| Coordinates line at 360px | **Readable always** — wraps rather than truncates. Coordinates are the only mandatory field with no other visible confirmation of where the case was placed. |

Three further decisions were taken after `sdd-design` reported back:

| Question | Decision |
|----------|----------|
| The four thresholds cannot merge without changing what the live public screen renders somewhere between 880 and 1100. Merge anyway? | **No. Name them, do not merge.** One shared source, four tokens keeping their exact current values, zero inline literals. Four meaningful names instead of four anonymous numbers, and not a pixel changes on the published screen. |
| "Last edited draft" needs an edit timestamp that `CaseDraft` does not store. | **Approximate with the last draft in the list.** Cheap, touches neither the domain nor storage. With few drafts the two almost always coincide. Adding `updatedAt` would reach domain, storage and exporter — outside this change. |
| What a first-time editor sees on a phone with no drafts yet | **A blank draft, ready to type.** One is created automatically and the form opens on it. No intermediate step, consistent with the form being the full-screen default. |

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `lib/features/cases/presentation/intake/intake_workspace_screen.dart` | Modified | Narrow branch; 260px/380px containers become on-demand |
| `lib/features/cases/presentation/intake/sections/*.dart` | Modified | Narrow fallbacks in the six rows |
| `lib/core/` (new breakpoints file) | New | Shared threshold constant |
| `lib/features/home/presentation/home_page.dart` | Modified | Migrate four inline thresholds |
| `test/intake_draft_switch_test.dart` | Modified | Drop forced 1600x1200 viewport |
| `test/` (new) | New | Narrow-viewport intake tests at 360px |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Sala de Situación regresses (live, 15 cases) | Med | Migrate thresholds with identical values first, behavior-preserving; cover `_DesktopBody`/`_MobileBody` selection with tests before touching |
| Removing the viewport crutch breaks unrelated draft-switch assertions | Med | Keep assertions, change only viewport; TDD red first |
| `ensureVisible` in `intake_form_widget_test.dart` masks new overflow | Med | Treat as regression canary; assert no overflow explicitly |
| flutter_map test flakiness | High | `tester.pump(Duration(milliseconds: 400))`, never `pumpAndSettle` |
| Preview no longer always visible while typing | Med | One-tap, state-preserving toggle; verify live updates while sheet is open |
| Unifying breakpoints inflates the diff past the 1000-line budget | Low | Sequence breakpoint migration as its own commit |
| **Unlisted, and it fired.** Every threshold in this change is compared against a width the *browser* reports. Nothing in the plan verified that the host document asks the browser for the device width | — | Added in Phase 7 after the defect reached production: `web/index.html` carries the viewport meta, guarded by `test/web_index_viewport_test.dart`, which reads the built document rather than an injected viewport |

## Rollback Plan

Delivery is direct commits to `main`, no PR flow. Sequence commits so each is independently revertible: (1) shared breakpoint constant + `home_page.dart` migration, (2) section row fallbacks, (3) workspace narrow branch, (4) test viewport cleanup. A regression on the public screen is reverted by `git revert` of commit (1) alone; intake work does not depend on it landing permanently, only on the constant existing.

## Dependencies

- None external. No new packages; `flutter_map` version unchanged.

## Success Criteria

- [x] Intake workspace renders at 360x640 with zero `RenderFlex overflowed` exceptions.
- [x] A draft can be created, edited, previewed and exported entirely at 360px.
- [x] `test/intake_draft_switch_test.dart` passes without a forced oversized viewport.
- [x] One shared breakpoint *source*; no inline width literals left in `home_page.dart`. The four thresholds keep their distinct values — see the decision below. Pinned by direct equality assertions in Phase 6 after verification proved all four could drift with the suite green.
- [x] `flutter test` green (167 passing), `flutter analyze` clean.
- [ ] ~~Sala de Situación desktop and mobile bodies behave identically to before.~~ **Not satisfied, and deliberately left unticked.** See "Correction: the Sala did change on mobile" below.

### Correction: the Sala did change on mobile

This criterion is false as written, and the change delivered anyway. Recording it
honestly rather than quietly re-wording it.

`web/index.html` never declared a viewport meta, so a mobile browser laid the page
out at roughly 980 CSS pixels. `home_page.dart:30` gates the public Sala on
`width >= Breakpoints.sidePanel` (880), and 980 >= 880, so every mobile visitor to
the live Sala was served `_DesktopBody` shrunk to fit. Adding the meta in Phase 7
moved those visitors to `_MobileBody` at 1:1.

That is a user-visible behavioral change to a live screen, and it is the change's
number-one risk firing — just not through the path the risk table anticipated. The
mitigation column reads "migrate thresholds with identical values first,
behavior-preserving; cover `_DesktopBody`/`_MobileBody` selection with tests before
touching". Those tests were written, they pass, and they were structurally incapable
of catching this: they inject `tester.view.physicalSize`, which bypasses browser
viewport negotiation entirely. The threshold values genuinely never moved. What moved
was the width the browser reported to them.

The change is believed to be a strict improvement — a phone rendering the mobile body
at 1:1 rather than a desktop body scaled down — but "believed" is the honest word
until on-device re-triage confirms it. That re-triage is pending and is tracked as a
carried-forward gap in `tasks.md`.
