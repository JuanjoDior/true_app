# Expanded Case Dossier Specification

## Purpose

Provide a reading-oriented public case page. It reuses the editorial blocks the compact Situation Room panel and intake preview already render, and it is free to add page-only structure and content that those compact surfaces do not have.

## Requirements

### Requirement: No Duplicated Editorial Renderer

The system MUST define each shared editorial block once and compose it in every host that shows it. The shared set is case metadata, summary, photos, timeline, sources, related cases, and meaningful editorial chapters. Each applicable block MUST appear no more than once within a single rendered host.

**The expanded page is a superset, not a mirror.** An earlier version of this specification required all three hosts to present *the same* content; that was wrong and is corrected here. `CaseDossierPanel` stays the compact map-context and preview surface and shows the compact subset. The expanded page composes the same shared blocks — it MUST NOT re-implement them — and MAY add page-only structure and content that the compact surfaces never show. Adding to the expanded page is not a violation; re-implementing a shared block is.

#### Scenario: A shared block has one implementation

- GIVEN summary, photos, timeline, sources, related cases and chapters are rendered by both the compact panel and the expanded page
- WHEN the presentation composition is inspected
- THEN each of those blocks resolves to a single shared implementation
- AND the expanded page maintains no second independent implementation of any of them

#### Scenario: The expanded page may show more than the compact panel

- GIVEN the expanded page renders page-only structure that the compact panel does not
- WHEN both are rendered for the same case
- THEN the compact panel shows only its compact subset
- AND the expanded page additionally shows its page-only structure
- AND that difference is not treated as a defect

#### Scenario: Shared blocks stay consistent where both hosts show them

- GIVEN a case with meaningful content in all four chapters
- WHEN it is rendered in the compact panel, the intake preview and the expanded page
- THEN every host that shows chapters shows them in the fixed editorial order
- AND no host shows an applicable block twice

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
