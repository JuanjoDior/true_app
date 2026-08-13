# Proposal: Public Case Publication Detail

Enable public readers to open, share, and navigate complete case dossiers while preserving the current editorial publication model: authors create a case in intake, copy exported JSON into `assets/data/cases.json`, commit it, and GitHub Pages publishes it.

The change adds fixed editorial chapters, stable hash-based case URLs, a published-case directory inside the Situation Room, and a reading-oriented detail page. It extends the existing shared dossier representation rather than creating a second source of truth.

## Problem

The public Situation Room currently makes the map the only meaningful way to find and inspect a case. A reader cannot reliably navigate a complete published catalog, share a stable URL for a specific case, or return to a case through a browser refresh or history action.

The internal intake flow also has no structured long-form editorial chapter model that can travel consistently from local draft storage to exported catalog JSON and the public dossier. Adding that content only to intake or only to a new public page would create divergent representations of the same case.

## Goals

- Preserve the versioned JSON catalog and deliberate manual publication workflow.
- Add four optional, fixed-order editorial chapters to a case:
  1. Background
  2. Events
  3. Investigation
  4. Current status
- Allow authors to create, edit, persist, preview, export, and publish those chapters.
- Make each published case addressable at a stable hash URL: `/#/casos/<slug>`.
- Provide a reading-oriented public detail page built from shared dossier content.
- Keep `CaseDossierPanel` as the compact summary, preview, and map-context surface.
- Add a navigable directory of published cases to the Situation Room on mobile and desktop.
- Keep existing draft and catalog JSON without chapters compatible.
- Provide coherent behavior for direct known-case URLs, refresh, and browser back/forward navigation.
- Show an in-app not-found state for unknown or stale slugs, retaining the hash for visibility and offering return navigation to the Situation Room.

## User Outcomes

### Internal editor

An editor can add content to the four supported editorial chapters while preparing a case. The content remains available in local drafts, appears in the intake preview, and is included in exported JSON when meaningful.

### Public reader

A reader can open a published case from the Situation Room directory or a stable shared link, read an expanded dossier, navigate to another case, and return to the Situation Room without losing the ability to orient themselves.

### Maintainer

A maintainer continues publishing through the existing clipboard-to-asset-to-commit workflow. Existing catalog entries need no mass migration and remain readable after the change.

## Scope and Capabilities

### Editorial chapters

- Introduce an ordered chapter collection to both draft and published case representations.
- Support only the four approved chapter types in the fixed editorial order: background, events, investigation, and current status.
- Provide intake editing for those fixed chapters.
- Persist chapter data in local drafts using additive, backward-compatible decoding.
- Include chapters in draft preview through the shared dossier content.
- Export meaningful chapter content to catalog JSON and parse it from `assets/data/cases.json`.
- Render non-empty chapters once and in their fixed editorial order in both compact/preview and expanded contexts as appropriate.
- Treat missing chapter data in legacy drafts or catalog entries as an empty chapter collection.

### Public case detail route

- Interpret `/#/casos/<slug>` as a published-case detail route.
- Resolve published cases by stable slug rather than mutable title or map-selection ID.
- Render a reading-oriented expanded dossier for known slugs.
- Preserve coherent direct-load, refresh, and back/forward behavior for known routes.
- Render an in-app not-found state for an unknown or stale slug, keep the hash visible, and offer a clear return action to the Situation Room.
- Keep clean-path routing deferred until the hosting environment supports SPA rewrites.

### Published-case directory

- Add a navigable directory of published cases within the Situation Room on both mobile and desktop.
- Order directory entries by year descending, then title as a deterministic tie-breaker.
- Navigate from a directory entry to the published case hash route.
- Reuse loaded case data rather than independently parsing catalog assets or duplicating catalog-selection logic.

### Shared dossier presentation

- Extract or compose reusable dossier content so the compact `CaseDossierPanel`, intake preview, and expanded public page present the same case content consistently.
- Retain compact panel actions and map-context behavior in `CaseDossierPanel`.
- Allow route/page contexts to open related cases through route navigation without requiring a map gesture.
- Do not replace the Situation Room map as the primary spatial discovery surface.

## Success Criteria

- [ ] An editor can author the four fixed editorial chapters in intake, and no free-form additional chapter type is available in v1.
- [ ] Chapter content persists across local draft save/load and legacy drafts without chapter data load successfully.
- [ ] Draft preview, JSON export, catalog parsing, and public dossier rendering preserve supported chapter content and order.
- [ ] Exports omit empty or meaningless chapter data according to the schema rules defined in design and specs.
- [ ] Existing catalog entries without chapters continue to render normally in map, compact dossier, directory, and expanded detail contexts.
- [ ] A known `/#/casos/<slug>` URL resolves the correct published case by slug on direct load and refresh.
- [ ] Browser back and forward navigation behave coherently with known case routes.
- [ ] Unknown or stale slugs show an in-app not-found state, preserve the hash, and provide return navigation to the Situation Room.
- [ ] Mobile and desktop Situation Room layouts expose a usable published-case directory without overflow.
- [ ] The directory is ordered by year descending and title tie-breaker.
- [ ] Compact dossier, intake preview, and expanded dossier compose shared content rather than maintaining duplicate editorial renderers.
- [ ] New behavior follows strict TDD: each behavior test is observed RED before the corresponding implementation becomes GREEN.
- [ ] Verification includes proportional real-browser evidence for deployed hash routing, direct entry, refresh, and browser history behavior; widget tests alone are not accepted as proof for those browser/host behaviors.

## Non-Goals

- Backend, CMS, shared drafts, authentication changes, or author attribution.
- Publication automation or changes to the manual clipboard → asset → commit → GitHub Pages publication circuit.
- Editing `featuredRank` or `relevanceRank`.
- Native Android or iOS platform support.
- Clean paths, SPA rewrite configuration, redirects, SEO work, server rendering, or server-side rendering.
- Rich-text editing, uploads, arbitrary chapter types, or free-form additional chapters.
- A new ranking algorithm, backend search, pagination service, or independent catalog source.
- Replacing or duplicating `CaseDossierPanel`.
- Changes to what `intake-responsive` delivered, **except** two edits to `test/intake_narrow_layout_test.dart` (committed in `c351fac`): its section-registry expectation, which registering the seventh section genuinely forces (unit 5), and optionally its `CaseDossierPanel` construction, which unit 4c may migrate to explicit configuration. Both are named in design §12 and confined to those units; no other edit to that file is in scope.

## Dependencies

### Blocking dependency — SATISFIED (2026-08-13)

`intake-responsive` was archived on 2026-08-13 with `blockers: 0`, 11/11 requirements and 24/24 scenarios. Its record is in `openspec/changes/archive/2026-08-13-intake-responsive/` and its merged specs are the baseline in `openspec/specs/`. **Apply work for this change is unblocked.**

The two changes overlap in `CaseDraft`, the intake section registry and composition, draft preview, draft persistence, catalog export, and shared dossier/public presentation. That overlap is why apply was gated; re-read the archived state and the merged specs before design or apply work so this change builds on what was actually delivered, not on what was planned.

### Runtime and platform dependencies

- Flutter web for mobile and desktop remains the supported target.
- Existing Riverpod, local draft persistence, asset loading, and GitHub Pages deployment are sufficient for the approved scope.
- GitHub Pages hash routing works under the existing project base path because the server receives the application root while the browser retains the fragment.
- No additional routing package is assumed by this proposal; design will select the smallest compatible route coordination mechanism.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Overlap with `intake-responsive` | Concurrent changes may conflict across draft, intake, preview, exporter, and dossier seams. | Mitigated: apply was gated until `intake-responsive` archived on 2026-08-13. Residual action — re-read the archived state and merged specs before design/apply work. |
| Route and map-selection divergence | The hash route, selected map case, and browser history could display inconsistent case state. | Design one explicit route/navigation coordination boundary and test known-route transitions separately from map gestures. |
| Duplicated dossier rendering | Intake preview, compact panel, and expanded page could drift in content and ordering. | Define and implement shared dossier content; keep shells/contextual actions separate from editorial rendering. |
| Legacy JSON compatibility | Existing drafts and published catalog entries lack chapter data. | Default absent chapter collections to empty and add regression coverage at draft and catalog parsing boundaries. |
| Malformed chapter entries | Invalid catalog data could break the public page or render misleading content. | Define an explicit malformed-entry policy in design/specs before implementation. |
| Browser-only route behavior | Widget tests cannot prove deployed hash navigation, refresh, history, or Pages integration. | Require source-level route coverage plus proportional real-browser evidence against the deployed site. |
| Mobile navigation or layout regressions | The directory and expanded page may compete with map controls or overflow at narrow widths. | Specify visible mobile/desktop entry and return paths; use behavior-focused layout tests and real-browser checks. |
| Direct commits to main | A faulty change may become public immediately after deployment. | Keep commits small, preserve the manual publication boundary, validate before commit, and retain a documented rollback procedure. |

## Rollout and Rollback

### Rollout

1. Planning artifacts complete.
2. `intake-responsive` archived on 2026-08-13 — gate satisfied.
3. Implement with strict TDD, recording observed RED before GREEN for each new behavior.
4. Validate domain/data, widget, and static route behavior with the project test and analysis commands.
5. Validate deployed known-case hash navigation, refresh, and browser back/forward behavior in a real browser before considering delivery complete.
6. Publish through the existing manual workflow: export JSON, update `assets/data/cases.json`, commit directly to `main`, and allow GitHub Pages to deploy.

### Rollback

Delivery is direct commit to `main`; rollback must therefore be explicit and fast:

1. Revert the deployment commit(s) that introduced the route, directory, shared dossier changes, or chapter-bearing catalog content.
2. Restore the prior known-good `assets/data/cases.json` if newly published chapter data contributes to the incident.
3. Push the revert so GitHub Pages redeploys the previous public behavior.
4. Confirm the Situation Room root and a previously valid published case URL behave as expected after redeployment.
5. Preserve the incident evidence and reopen planning only after identifying whether the defect is in route handling, shared rendering, catalog data, or deployment behavior.

Rollback does not modify local draft data unless a separate, explicitly scoped recovery decision is made.

## Future Migration Trigger

Hash URLs are the approved v1 routing strategy because GitHub Pages does not provide the SPA rewrite behavior needed for clean paths. Revisit clean-path routing only when hosting is changed or configured to support reliable SPA rewrites, direct deep-link requests, and redirects without fragment routing.

This migration is deferred work, not an implementation allowance in this change.

## Implementation Block

```text
APPLY UNBLOCKED — intake-responsive archived 2026-08-13

Read before implementing. These areas were touched by the change that just
closed, so build on its delivered state, not on this document's assumptions:
- CaseDraft and local draft persistence
- intake section registry and chapter editor composition
- draft preview projection and IntakePreviewPanel
- case exporter and catalog JSON compatibility
- CaseDossierPanel and shared public dossier presentation

Implementation MUST use strict TDD with observed RED before GREEN, and each RED
must be attributed to the assertion it is credited with by reading the reported
failing line.

Widget tests alone MUST NOT be treated as proof of deployed hash/deep-link,
refresh, or browser-history behavior; proportional real-browser evidence is
required. This project has shipped two production defects that a green widget
suite could not see.
```
