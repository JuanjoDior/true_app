# Responsive Breakpoints Specification

## Purpose

Single shared source of width-threshold constants that both the public Sala de Situación (`lib/features/home/presentation/home_page.dart`) and the intake workspace use to select between desktop and narrow layouts. Bootstraps `openspec/specs/` for this domain.

## Requirements

### Requirement: Centralized Breakpoint Constants

The system MUST expose all layout width thresholds from a single shared module, not per-screen inline literals. `home_page.dart` MUST NOT contain any inline numeric width-comparison literal after migration; every threshold comparison MUST reference a named constant from the shared module.

#### Scenario: No inline width literals remain in home_page.dart

- GIVEN the migrated `home_page.dart` source
- WHEN searching for width comparisons against raw numeric literals
- THEN zero such literals are found; every threshold check references a named constant from the shared breakpoints module

#### Scenario: Existing threshold values are preserved unchanged

- GIVEN the shared breakpoints module
- WHEN reading the constants that replace the former inline values
- THEN the rail threshold is 1100, the side-panel threshold is 880, the top-bar compact threshold is 980, and the side-panel narrow-width threshold is 1024

### Requirement: Sala de Situación Layout Selection Is Behavior-Preserving

After migrating to the shared constants, the Sala de Situación MUST select `_DesktopBody`/`_MobileBody` and the compact top bar at exactly the same widths as before the migration.

#### Scenario: Desktop body selected at or above the side-panel threshold

- GIVEN the Sala de Situación rendered at width 880 or greater
- WHEN the layout builds
- THEN `_DesktopBody` (rail/map/side-panel row) is selected, same as pre-migration

#### Scenario: Mobile body selected below the side-panel threshold

- GIVEN the Sala de Situación rendered at width 879 or less
- WHEN the layout builds
- THEN `_MobileBody` (full-bleed map with floating dossier sheet) is selected, same as pre-migration

#### Scenario: Top bar compact mode unchanged

- GIVEN the Sala de Situación top bar rendered at width 980 or less
- WHEN the layout builds
- THEN the top bar renders compact (metrics row and global pill hidden; search and intake entry button visible), same as pre-migration

### Requirement: Minimum Supported Width

The shared breakpoints module MUST treat 360px as the minimum width any consuming screen is required to support without layout overflow. Widths below 360px are out of scope for both consuming screens.

#### Scenario: 360px is the floor for narrow-layout guarantees

- GIVEN any screen consuming the shared breakpoints module
- WHEN rendered at width 360
- THEN the screen's narrow layout applies with no `RenderFlex overflowed` exception, and no guarantee is made below 360
