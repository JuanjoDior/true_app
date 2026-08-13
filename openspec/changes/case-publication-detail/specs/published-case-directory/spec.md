# Published Case Directory Specification

## Purpose

Make the loaded published catalog directly navigable from the Situation Room on compact mobile and wide desktop web layouts while preserving the map as the primary spatial discovery surface.

## Requirements

### Requirement: Mobile and Desktop Directory Access

The Situation Room MUST expose a clear, operable entry point to the published-case directory in both compact mobile and wide desktop layouts. Readers MUST be able to reach and open directory entries without first selecting a map marker.

Directory presentation MUST keep its entry point, entries, and navigation actions reachable without blocking overflow at supported mobile and desktop widths.

#### Scenario: Mobile reader opens the directory

- GIVEN the Situation Room is displayed in a supported compact mobile layout
- WHEN the reader uses the directory entry point
- THEN the published-case directory becomes available
- AND its entries can be reached through normal scrolling
- AND an entry can be opened without a map gesture
- AND no overflow prevents access to directory navigation

#### Scenario: Desktop reader opens the directory

- GIVEN the Situation Room is displayed in a supported wide desktop layout
- WHEN the reader uses the directory entry point
- THEN the published-case directory becomes available
- AND its entries can be reached and opened
- AND no overflow prevents access to directory navigation

### Requirement: Complete Deterministic Directory Ordering

The directory MUST represent every successfully loaded published case, including legacy cases without chapters.

Entries MUST be ordered by case year descending. Cases with the same year MUST be ordered by published title ascending as the deterministic tie-breaker. The directory MUST NOT substitute `featuredRank`, `relevanceRank`, or a new ranking algorithm for this ordering.

#### Scenario: Cases are ordered by year and title

- GIVEN the loaded catalog contains cases titled Alpha and Bravo from 2020 and a case titled Zulu from 2022
- WHEN the directory is displayed
- THEN Zulu appears before the 2020 cases
- AND Alpha appears before Bravo among the 2020 cases

#### Scenario: Legacy published case remains listed

- GIVEN the loaded catalog contains a valid published case without a `chapters` member
- WHEN the directory is displayed
- THEN that case appears as a normal directory entry
- AND it remains navigable by its slug

### Requirement: Loaded Catalog Reuse

The directory MUST derive its entries from the application's already loaded published-case catalog. Opening or rendering the directory MUST NOT independently parse the catalog asset, create a separate catalog source, or require a second catalog load.

#### Scenario: Directory uses the existing loaded catalog

- GIVEN a catalog loader that records how many times it is invoked
- AND the published catalog has already been loaded once for the Situation Room
- WHEN the reader opens the directory
- THEN the directory displays cases from that same loaded catalog state
- AND the recorded invocation count is still one

**Falsifiability note, normative for verification.** Asserting merely that "no
independent parse is initiated" passes before the directory exists, and would
still pass if the directory were deleted. The assertion MUST be made against an
instrumented loader whose invocation count can go up, so that a second load is
observable. A test that cannot count loads MUST NOT be accepted as evidence for
this requirement.

### Requirement: Directory Route Navigation

Activating a directory entry MUST navigate to the selected case's `/#/casos/<slug>` route using its published slug. Navigation MUST NOT derive route identity from the case title or map-selection ID.

#### Scenario: Reader opens a directory case

- GIVEN the directory contains a case whose slug is `known-case`
- WHEN the reader activates that case entry
- THEN the browser navigates to `/#/casos/known-case`
- AND the expanded dossier resolves the case by `known-case`

### Requirement: Situation Room Map Preservation

Adding and using the directory MUST preserve the existing Situation Room map, marker-selection, recentering, and compact-dossier behavior. The directory MUST be an additional catalog discovery path rather than a replacement for the map.

Returning from or closing the directory MUST leave the Situation Room available as the spatial discovery surface.

#### Scenario: Existing map discovery still works

- GIVEN the reader has opened and left the published-case directory
- WHEN the reader selects a case marker on the Situation Room map
- THEN the existing map-context case selection and dossier behavior occur
- AND the map remains available for further spatial discovery
