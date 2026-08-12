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

### Requirement: Host Document Viewport Precondition

Every width-gated layout decision in this app reads `MediaQuery.sizeOf(context).width`, which reflects the viewport the host browser reports to the Flutter web engine, not the physical device width. The web host document (`web/index.html`) MUST declare a `<meta name="viewport">` tag whose `content` attribute includes `width=device-width`. Without it, a mobile browser falls back to a desktop-width viewport (approximately 980 CSS px), which clears every threshold in this module and selects the wide-layout branch on a phone. This precondition is shared by every screen that consumes `Breakpoints` — it is not intake-specific.

The viewport meta MUST NOT suppress the browser's native zoom: it MUST NOT include `maximum-scale`, nor `user-scalable` set to any disabling value (`no` and `0` are equivalent to browsers). Suppressing pinch-zoom is a WCAG 1.4.4 regression that this app deliberately avoids; native zoom MUST remain available at every width. Known accepted cost of this trade-off: iOS may still trigger a zoom-in when a text field receives focus; on-device confirmation of a mitigation for that residual cost is pending.

Because this precondition is shared by every `Breakpoints`-consuming screen, declaring it correctly changes what the public Sala de Situación (`home_page.dart`) renders on a phone, not only the intake workspace. That consequence is asserted here as the reason the precondition is scoped app-wide; it is **not** stated as a verified acceptance criterion. No scenario below claims it, because the verification method this requirement mandates — reading the host document — cannot establish which branch a screen selects on a real device, and the widget suite injects `physicalSize` and so cannot either. On-device re-triage is tracked as an open gap in `tasks.md`.

Because the browser negotiates the viewport before Flutter runs, a widget test cannot observe this precondition: `tester.view.physicalSize` injects the rendered size directly, bypassing viewport negotiation entirely. A widget test can prove a layout is correct for a given reported width; it cannot prove the browser will ever report that width on a real device. Verification of this requirement MUST read the host document (or its built output) directly, not exercise a widget tree.

#### Scenario: Host document declares a device-width viewport

- GIVEN the built web host document (`web/index.html`)
- WHEN its `<head>` is inspected
- THEN it contains a `<meta name="viewport">` tag whose `content` attribute contains `width=device-width`

#### Scenario: Zoom remains available

- GIVEN the built web host document (`web/index.html`)
- WHEN its viewport meta `content` attribute is inspected
- THEN it contains no `maximum-scale`
- AND it contains no `user-scalable` set to a disabling value, in any spelling browsers honour (`no` or `0`)
