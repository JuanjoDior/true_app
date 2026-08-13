# Expanded Case Dossier Specification

## Purpose

Provide a reading-oriented public case page that composes the same dossier content used by the compact Situation Room panel and intake preview while keeping each host's navigation and contextual actions separate.

## Requirements

### Requirement: Single Shared Dossier Content

The system MUST define dossier editorial content once and compose that shared content in the compact `CaseDossierPanel`, intake preview, and expanded public page.

The shared content MUST present applicable case metadata, summary, photos, timeline, sources, related cases, and meaningful editorial chapters consistently. Each applicable content section MUST appear no more than once in a rendered dossier context.

`CaseDossierPanel` MUST remain the compact map-context and preview surface. The expanded page MUST compose the same shared content without copying the compact panel's editorial renderer or duplicating its content.

#### Scenario: All dossier hosts share the same case content

- GIVEN a case contains metadata, summary, photos, timeline entries, sources, related cases, and all four meaningful chapters
- WHEN the case is rendered in the compact panel, intake preview, and expanded page
- THEN each host presents the same applicable editorial data
- AND chapters appear in fixed editorial order
- AND every applicable section appears exactly once within each host

#### Scenario: Composition has no duplicate editorial renderer

- GIVEN the compact panel, intake preview, and expanded page are part of the delivered application
- WHEN their presentation composition is inspected
- THEN they compose the same shared dossier content contract
- AND the expanded page does not maintain a second independent implementation of the editorial sections

### Requirement: Optional Content Omission and Legacy Presentation

Shared dossier presentation MUST omit absent or non-meaningful optional sections rather than render empty headings or placeholders. A legacy published case without chapters MUST continue to render its existing dossier content normally in compact, preview-compatible, and expanded contexts.

#### Scenario: Legacy case renders without empty chapters

- GIVEN a valid published case has no chapter data
- WHEN it is rendered in the compact panel or expanded page
- THEN its existing dossier content is shown normally
- AND no empty chapter headings or chapter-related error state is shown

#### Scenario: Meaningful chapters render once in order

- GIVEN a case has meaningful Background and Investigation content and whitespace-only Events content
- WHEN any dossier host renders the shared content
- THEN Background and Investigation are shown once in that order
- AND Events and Current status are omitted

### Requirement: Contextual Actions Remain Separate

Reusable dossier content MUST remain separate from host-specific actions and page chrome. The compact panel MUST retain its map-context actions, the intake preview MUST retain preview-specific behavior, and the expanded page MUST provide page-level navigation including a clear return action to the Situation Room.

Reusing dossier content MUST NOT cause one host to display another host's contextual actions.

#### Scenario: Compact panel retains map actions

- GIVEN a case is open in the Situation Room compact dossier
- WHEN the reader uses its return-to-map action
- THEN the existing map-context selection is cleared as before
- AND expanded-page chrome is not introduced into the compact panel

#### Scenario: Expanded page provides route context

- GIVEN a known case is open on its expanded hash route
- WHEN the reader views the page actions
- THEN a clear return action to the Situation Room is available
- AND compact map-only actions are not duplicated as part of the shared editorial content

#### Scenario: Intake preview remains a preview context

- GIVEN an editor previews an active draft
- WHEN shared dossier content is rendered
- THEN the preview shows the draft's applicable editorial content
- AND it does not acquire public route-page chrome merely because the content is shared

### Requirement: Context-Appropriate Related-Case Navigation

Related-case actions MUST use navigation appropriate to the current host context. In the Situation Room map context, opening a related case MUST use the existing map-selection behavior. In an expanded route context, opening a related published case MUST navigate by that case's slug and create coherent browser history.

Related-case route navigation MUST NOT require a map gesture.

#### Scenario: Related case opens inside map context

- GIVEN a reader views a case in the Situation Room compact dossier
- WHEN the reader opens a related case
- THEN the related case becomes the active map-context selection
- AND the reader remains in the Situation Room context

#### Scenario: Related case opens inside route context

- GIVEN a reader views case A on its expanded hash route
- AND case B is a published related case
- WHEN the reader opens case B
- THEN the browser navigates to case B's `/#/casos/<slug>` route
- AND browser Back can restore case A
- AND no map gesture is required

### Requirement: Expanded Reading Experience Across Supported Layouts

A known case route MUST render a reading-oriented expanded dossier on supported compact mobile and wide desktop web layouts. All applicable dossier content and page navigation MUST remain reachable without blocking overflow.

#### Scenario: Expanded dossier is usable on mobile

- GIVEN a known case route is opened in a supported compact mobile layout
- AND the case carries enough content that the page overflows the viewport, so its last section is not visible on arrival
- WHEN the expanded dossier is displayed
- THEN the last section is reached by scrolling the page
- AND its related-case and return actions remain operable
- AND no overflow prevents reading or navigation

#### Scenario: Expanded dossier is usable on desktop

- GIVEN a known case route is opened in a supported wide desktop layout
- AND the case carries enough content that the page overflows the viewport, so its last section is not visible on arrival
- WHEN the expanded dossier is displayed
- THEN the last section is reached by scrolling the page
- AND its page actions remain readable and operable
- AND no overflow prevents reading or navigation

**Falsifiability note, normative for verification.** Both scenarios above assert
scrolling, so both MUST first assert that the content overflows
(`maxScrollExtent > 0`) and that the target is not visible on arrival, and MUST
drive the scroll with a real gesture. Without those preconditions the assertion
passes on a page that fits the viewport and on one whose scrolling is disabled —
the defect `test/intake_narrow_layout_test.dart:176-177` was written to close.

### Requirement: Situation Room Behavior Remains Intact

The expanded dossier capability MUST NOT replace the Situation Room map or alter its established marker-selection, recentering, selected-case, or return-to-map behavior.

Opening a direct dossier route MUST be independent of map state. Returning to the Situation Room MUST leave its map discovery and selection behavior available.

#### Scenario: Direct route does not require map state

- GIVEN no case has been selected through the Situation Room map
- WHEN a reader directly opens a known case hash route
- THEN the expanded dossier renders for the routed case
- AND no synthetic map gesture is required

#### Scenario: Map remains functional after routed reading

- GIVEN a reader returns to the Situation Room from an expanded dossier
- WHEN the reader selects a map marker
- THEN the existing selection and recentering behavior occurs
- AND the compact dossier remains available as before
