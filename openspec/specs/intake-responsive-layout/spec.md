# Intake Responsive Layout Specification

## Purpose

How the intake workspace (`intake_workspace_screen.dart` and its six form sections) composes the draft list, form and live preview across viewport widths, reusing the width-gated body-swap idiom from the Sala de Situación and the shared breakpoints module. Bootstraps `openspec/specs/` for this domain.

## Requirements

### Requirement: Desktop Three-Pane Layout Unchanged

Above the shared narrow-layout breakpoint, the intake workspace MUST keep its current three-pane `Row` composition: draft list, form and preview simultaneously visible.

#### Scenario: All three panes visible above the breakpoint

- GIVEN the intake workspace rendered above the narrow-layout breakpoint
- WHEN the layout builds
- THEN the draft list, the scrollable form and the live preview are all visible at once, matching pre-change behavior

### Requirement: Narrow Workspace Composition

At or below the narrow-layout breakpoint, the intake workspace MUST render the form as a single full-screen scrolling column by default. The draft list and the live preview MUST be reachable through one-tap, on-demand affordances (sheet/overlay), not permanently visible panes.

#### Scenario: Form is the default narrow view

- GIVEN the intake workspace rendered at width 360
- WHEN the screen first builds
- THEN the form shows full-screen and the draft list and preview are not permanently visible

#### Scenario: Draft list opens on demand

- GIVEN the intake workspace rendered at width 360
- WHEN the user taps the draft-list affordance
- THEN the draft list becomes visible as an overlay/sheet with every draft selectable

#### Scenario: Preview opens on demand

- GIVEN the intake workspace rendered at width 360
- WHEN the user taps the preview affordance
- THEN the preview sheet becomes visible over the form

### Requirement: Live Preview Behind an Open Sheet

While the preview sheet is open at narrow widths, it MUST keep updating live as the user edits form fields behind it, without closing and reopening the sheet.

#### Scenario: Preview reflects a field edit without closing

- GIVEN the preview sheet is open at width 360
- WHEN the user edits a form field while the sheet stays open
- THEN the preview content updates to reflect the new value and the sheet remains open

### Requirement: Landing on the Last Edited Draft

Opening the intake workspace at a narrow width MUST land the user on the form for the last edited draft, not the draft list, whenever at least one draft exists.

#### Scenario: Reopening intake with an existing draft

- GIVEN at least one draft was previously edited
- WHEN the intake workspace opens at width 360
- THEN the form shows the last edited draft, not the draft list

#### Scenario: Reopening intake with no drafts

- GIVEN no draft exists yet
- WHEN the intake workspace opens at width 360
- THEN a blank draft is created automatically and the form opens on it, ready to type, with no intermediate list or empty-state screen

### Requirement: No Layout Overflow at Minimum Supported Width

The intake workspace and all six previously broken rows (timeline row, links row, photos row, `_CoordinatesLine`, and `_FineTuning`'s three fields) MUST render at 360x640 with zero `RenderFlex overflowed` exceptions. This MUST also hold at the default Flutter widget-test viewport (800x600), so no test needs to force an oversized viewport to avoid overflow.

#### Scenario: Timeline row does not overflow

- GIVEN a timeline entry with date, title, kind and delete control
- WHEN rendered at 360x640
- THEN no `RenderFlex overflowed` exception is thrown

#### Scenario: Links row does not overflow

- GIVEN a link entry with title, URL and kind fields plus delete control
- WHEN rendered at 360x640
- THEN no `RenderFlex overflowed` exception is thrown

#### Scenario: Photos row does not overflow

- GIVEN a photo entry with its fields and delete control
- WHEN rendered at 360x640
- THEN no `RenderFlex overflowed` exception is thrown

#### Scenario: Coordinates line wraps instead of truncating

- GIVEN a resolved or in-progress coordinate lookup with label, spinner and status text
- WHEN rendered at 360x640
- THEN the text wraps onto additional lines, stays fully readable, and no `RenderFlex overflowed` exception is thrown

#### Scenario: Fine-tuning fields do not overflow

- GIVEN the ISO code, latitude and longitude fields in `_FineTuning`
- WHEN rendered at 360x640
- THEN no `RenderFlex overflowed` exception is thrown

#### Scenario: Default test viewport needs no forced resize

- GIVEN the intake workspace under the default Flutter widget-test viewport (800x600), no forced `tester.view.physicalSize` override
- WHEN the widget tree builds
- THEN no `RenderFlex overflowed` exception is thrown

### Requirement: Full Affordance Parity at Narrow Width

Every affordance available at desktop width MUST remain reachable at 360px: the draft list, creating a draft, deleting a draft, all six form sections, the preview, and the export (copy JSON) action.

#### Scenario: Create, delete and export at 360px

- GIVEN the intake workspace at width 360
- WHEN the user creates a new draft, deletes a draft, then triggers export on a valid draft
- THEN each action completes with the same outcome as at desktop width

#### Scenario: All six sections reachable at 360px

- GIVEN the intake workspace at width 360
- WHEN the user scrolls the form
- THEN every form section is reachable and editable, in the same order as desktop

### Requirement: Preview Panel Survives Minimum Width

`CaseDossierPanel`, reused as preview content, MUST render without overflow when its container is constrained to 360px width — a width it has not previously been stress-tested against.

#### Scenario: Preview panel at 360px container width

- GIVEN the preview sheet is open at width 360
- WHEN `CaseDossierPanel` renders inside the narrow container
- THEN no `RenderFlex overflowed` exception is thrown
