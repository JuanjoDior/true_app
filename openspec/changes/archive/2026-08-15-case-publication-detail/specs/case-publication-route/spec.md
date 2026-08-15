# Case Publication Route Specification

## Purpose

Provide stable, shareable hash routes for published cases with coherent direct loading, refresh, browser history, and unknown-case behavior under static GitHub Pages hosting.

## Requirements

### Requirement: Stable Hash Route Identity

Public case detail URLs MUST use the fragment route `#/casos/<slug>`, appearing as `/#/casos/<slug>` from the application root. The system MUST resolve the route against the loaded published catalog by the case's stable slug, not by mutable title or map-selection ID.

Opening a case route MUST NOT require a prior map gesture. Clean paths, server rewrites, redirects, and server-rendered routes are not required by this capability.

#### Scenario: Navigation emits the case slug route

- GIVEN a published case has slug `known-case`
- WHEN a reader opens that case from a public navigation surface
- THEN the browser URL uses the hash route `/#/casos/known-case`
- AND the route resolves the case by `known-case`
- AND no map selection gesture is required

#### Scenario: Mutable title does not define route identity

- GIVEN a published case retains its slug but its displayed title changes
- WHEN `/#/casos/<slug>` is opened with the retained slug
- THEN the route resolves that published case
- AND route identity does not depend on the displayed title

#### Scenario: Route identity is the slug, not the selection ID

- GIVEN a published case whose `id` and `slug` differ, for example `id` `legacy-7` and `slug` `known-case`
- WHEN `/#/casos/known-case` is opened
- THEN the route resolves that case
- WHEN `/#/casos/legacy-7` is opened
- THEN the in-app not-found state is shown
- AND no case is resolved by its `id`

**Falsifiability note, normative for verification.** Every case in
`assets/data/cases.json` currently has `id` equal to `slug`, and
`case_exporter.dart` emits both from the same value. A test built from real or
exported fixtures therefore passes whether resolution is by slug or by ID, and
proves nothing. The scenario above MUST be verified with a hand-built fixture in
which the two differ; a fixture where they are equal MUST NOT be accepted as
evidence for this requirement.

### Requirement: Known-Case Direct Load and Refresh

A direct browser load of a known case hash route MUST render the expanded dossier for the matching published case after catalog resolution. Refreshing that URL MUST preserve the hash and render the same case without redirecting to the Situation Room or requiring prior in-app navigation.

Legacy published cases without editorial chapters MUST be resolvable through their existing slug.

#### Scenario: Known case loads directly

- GIVEN the published catalog contains a case with slug `known-case`
- WHEN a reader directly opens `/#/casos/known-case`
- THEN the application renders the expanded dossier for that case
- AND the visible hash remains `#/casos/known-case`

#### Scenario: Known case survives refresh

- GIVEN the expanded dossier for `known-case` is visible at `/#/casos/known-case`
- WHEN the reader refreshes the browser
- THEN the application resolves `known-case` again
- AND renders the same expanded dossier
- AND does not require a map selection or directory navigation

### Requirement: Browser History Coherence

In-app navigation from the Situation Room to a known case and from one routed case to another MUST create coherent browser history entries. Browser back and forward actions MUST update the visible hash and rendered content to match the active history entry.

#### Scenario: Back and forward traverse case routes coherently

- GIVEN a reader starts in the Situation Room
- AND opens case A through its hash route
- AND then opens related case B through its hash route
- WHEN the reader uses browser Back once
- THEN case A's hash and expanded dossier are restored
- WHEN the reader uses browser Back again
- THEN the Situation Room is restored
- WHEN the reader uses browser Forward twice
- THEN case A and then case B are restored in sequence
- AND the rendered case always matches the visible hash

### Requirement: Unknown Slug Not-Found State

When a case-detail hash contains an unknown or stale slug, the system MUST render an in-app not-found state. It MUST NOT display another case, silently select a map case, or rewrite the unknown hash while the not-found state is visible.

The not-found state MUST provide a clear action that returns the reader to the Situation Room. Invoking that action MUST leave the unknown detail route and remove its case-detail state from the visible URL.

#### Scenario: Unknown slug remains visible

- GIVEN the published catalog does not contain slug `missing-case`
- WHEN a reader opens `/#/casos/missing-case`
- THEN an in-app case-not-found state is shown
- AND the visible hash remains `#/casos/missing-case`
- AND no other case dossier is substituted

#### Scenario: Reader returns from an unknown route

- GIVEN the not-found state for `/#/casos/missing-case` is visible
- WHEN the reader activates its return action
- THEN the Situation Room is shown
- AND the unknown case-detail hash is no longer the active route

### Requirement: Browser and Host Verification Evidence

Acceptance of hash routing MUST include source-level or structural evidence for hash parsing and emission plus real-browser evidence against the deployed web application.

Real-browser evidence MUST demonstrate direct loading and refresh of a deployed known-case URL and MUST exercise browser back and forward behavior for history written by the application. Widget tests MAY supplement this evidence but MUST NOT be accepted as sufficient proof of deployed direct loading, refresh, browser history, or GitHub Pages integration.

Any routing or responsive-layout precondition supplied by the host document MUST be verified by reading the relevant built or deployed document. A widget viewport override MUST NOT be treated as proof of a host-document precondition.

#### Scenario: Deployed direct load and refresh are proven

- GIVEN automated widget tests for route behavior pass
- WHEN delivery evidence is evaluated
- THEN the evidence also includes a real browser opening a deployed known-case hash URL directly
- AND refreshing that URL
- AND confirming that the same case remains rendered
- AND widget evidence alone is rejected as incomplete

#### Scenario: Deployed history is proven

- GIVEN the application writes history while navigating between known cases
- WHEN browser verification is performed against the deployed application
- THEN Back and Forward are exercised in a real browser
- AND the visible hash and rendered dossier are confirmed at each step

#### Scenario: Host-document precondition is verified at its boundary

- GIVEN a required web behavior depends on markup or configuration in the host document
- WHEN verification evidence is collected
- THEN the built or deployed host document is read and checked directly
- AND injecting a widget test viewport is not accepted as proof of that document-level precondition
