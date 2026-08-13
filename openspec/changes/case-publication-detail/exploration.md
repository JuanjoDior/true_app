# Exploration: Public Case Publication Detail

## Outcome

`case-publication-detail` can extend the existing versioned-JSON publication flow with editorial chapters, shareable hash dossier URLs, a navigable published-case list, and a full dossier page. The implementation MUST reuse dossier rendering rather than creating a second divergent representation of case content.

**Implementation block: LIFTED (2026-08-13).** The overlapping `intake-responsive` change was archived on 2026-08-13 with `blockers: 0`, 11/11 requirements and 24/24 scenarios; its record is in `openspec/changes/archive/2026-08-13-intake-responsive/` and its specs are the baseline in `openspec/specs/`. Apply work may begin.

The earlier wording of this block cited a "native Gentle AI runtime deadlock" and pointed at `HANDOFF.md`. Both are obsolete: that document has been deleted, and the deadlock was never a runtime defect — the approved review simply had not been bound to the change with `gentle-ai review bind-sdd`. See `PROJECT_CONTEXT.md` → "Pendiente".

## Confirmed product constraints

- Published cases remain in `assets/data/cases.json`; there is no backend, CMS, authentication, shared drafts, author attribution, or publication automation.
- Each public case needs a stable hash URL: `/#/casos/<slug>`.
- Clean-path routing is deferred until hosting supports SPA rewrites.
- Editorial chapters must be authored in intake, stored in local drafts, previewed, exported, parsed from JSON, and rendered in the public expanded dossier.
- Existing published JSON without chapters MUST remain readable.
- Flutter web mobile and desktop are the only supported targets.
- UI copy and code comments are deferred to implementation and remain Spanish; planning artifacts are English.
- Strict TDD applies during implementation: each new behavior test must be observed RED before its implementation turns GREEN.

## Current-state end-to-end flow

### Draft domain and local persistence

- `lib/features/cases/domain/case_draft.dart` defines `CaseDraft`. Its additive JSON persistence defaults absent lists to empty lists. Chapters should use the same tolerant behavior.
- `lib/features/cases/data/case_drafts_store.dart` stores drafts in a `shared_preferences` envelope. Additive chapters do not require a schema migration if missing data decodes as `[]`.
- `CaseDraftsNotifier.editDraft` in `lib/features/cases/application/case_draft_providers.dart` applies transformations to current state before saving. Chapter editors must preserve this pattern rather than mutating captured drafts.

### Intake composition and preview

- `kCaseFormSections` in `lib/features/cases/presentation/intake/case_form_section.dart` is the ordered intake registry. Chapters can be introduced as one additional registered section.
- `SummarySection` establishes the provider/text-field pattern for editorial input.
- `TimelineSection` is the closest precedent for an ordered add/remove editor, although chapters require long-form content and semantic headings.
- `draftPreviewCaseProvider` projects the active draft into `TrueCrimeCase`; chapters must pass through this projection.
- `IntakePreviewPanel` already uses `CaseDossierPanel`. Chapter preview must enter through the shared dossier surface, not through a separate intake-only renderer.

### Export and published JSON boundary

- `draftToCaseJson` and `encodeDraftAsCaseJson` in `lib/features/cases/application/case_exporter.dart` are the only draft-to-catalog bridge. They should export non-empty ordered chapters and omit empty chapter data.
- Existing `caseSlug` and `uniqueCaseSlug` output is suitable for route identity. Routes must resolve by `slug`, not mutable titles.
- `ExportCaseButton` preserves the manual publication flow: clipboard JSON, asset edit, commit, and Pages deployment.
- Existing entries in `assets/data/cases.json` have no chapters and must not require a mass migration.

### Published model, repository, providers, and map selection

- `TrueCrimeCase` in `lib/features/cases/domain/true_crime_case.dart` should gain an ordered chapter collection defaulting to `[]` when absent.
- `LocalCasesRepository.parseCasesJson` in `lib/features/cases/data/local_cases_repository.dart` is the asset parsing boundary and needs regression coverage for both legacy and chapter-bearing cases.
- `casesProvider`, `selectedCaseIdProvider`, and `selectedCaseProvider` in `lib/features/cases/application/cases_providers.dart` currently select by ID. Add a slug lookup or route resolver without disturbing map selection semantics.
- `SituationMapStage` writes selected IDs and recenters the map. Opening a dossier route must not depend on a map gesture.

### Public dossier rendering

- `CaseDossierPanel` in `lib/features/home/presentation/widgets/situation/case_dossier_panel.dart` is the canonical summary and preview surface. It renders metadata, summary, photos, timeline, sources, related cases, and contextual actions.
- `SituationSidePanel` uses it on desktop; `_MobileBody` in `home_page.dart` uses it in the mobile sheet; `IntakePreviewPanel` uses it for draft preview.
- The expanded page must compose shared dossier content instead of copying `CaseDossierPanel`.

## Current navigation and deployment

`lib/app/true_crime_app.dart` creates `MaterialApp` with only `home: const TrueCrimeHomePage()`. There is no route table, Router API delegate, URL strategy, or hash coordinator.

`workspaceProvider` switches between the Situation Room and intake. `selectedCaseIdProvider` switches map-context dossier selection. Marker taps and related-case cards write selected IDs directly, and “VOLVER AL MAPA” clears the selection. Direct hash entry, refresh preservation, and browser back/forward do not yet exist.

`SituationNavRail` shows an inert list icon, and narrow layouts have no rail. The published directory therefore needs explicit desktop and mobile entry points.

`.github/workflows/deploy-pages.yml` builds with `--base-href "/${GITHUB_REPOSITORY#*/}/"`, so the app lives under `/true_app/`. Hash URLs work because the server receives `/true_app/` while the browser retains `#/casos/<slug>`. Clean paths remain deferred because GitHub Pages has no SPA rewrite configuration.

## Reusable presentation seams

### Shared dossier content

Split current dossier responsibilities conceptually into:

- A reusable `CaseDossierContent`-like surface that renders editorial sections once, including chapters.
- `CaseDossierPanel`, which retains compact/map-context actions and composes shared content.
- The expanded dossier page, which supplies route/page chrome and composes the same content in a reading-oriented layout.
- `IntakePreviewPanel`, which keeps live preview parity through the shared surface.

### Related-case navigation

Related cards currently write `selectedCaseIdProvider` directly. Shared content should receive an `onOpenCase` callback or navigation abstraction: map contexts set selection, while route contexts navigate by slug.

### Published list

The list should consume `casesProvider` or a derived ordered provider and navigate with `crimeCase.slug`. It must not parse the asset independently or duplicate filtering/search rules.

## Proposed capability boundaries

### `case-editorial-chapters`

Define ordered chapter data in `CaseDraft` and `TrueCrimeCase`; persist, preview, export, parse, and render it. Excludes shared synchronization, author identity, uploads, rich text, and backend work.

### `case-publication-route`

Parse and emit `/#/casos/<slug>`, resolve loaded cases, render a valid expanded page, and handle unknown cases safely. Excludes clean paths, rewrites, server rendering, and native routes.

### `published-case-directory`

Provide a navigable list of published cases in the Situation Room with mobile and desktop entry points. Excludes backend search, pagination services, new ranking algorithms, and publication automation.

### `expanded-case-dossier`

Render a reading-oriented dossier page through shared content while preserving compact panel behavior. Excludes duplicate dossier renderers and replacement of the map.

## Backward compatibility

- `TrueCrimeCase.fromJson` and `CaseDraft.fromJson` MUST treat missing `chapters` as an empty list.
- Legacy cases must render normally in the map panel, mobile sheet, list, and expanded route.
- Chapter parsing needs an explicit malformed-entry policy during design.
- New exports SHOULD omit `chapters` when there is no meaningful chapter content.
- Draft persistence remains additive; no migration framework should be introduced unless design chooses a non-additive representation.
- Routes MUST resolve by `slug`; unknown or stale slugs need an in-app not-found state with a way back to the Situation Room.

## Test seams and proof boundaries

Strict TDD requires observed RED before GREEN for every new behavior.

### Domain and data

- Draft chapter JSON round trip and legacy draft without chapters.
- Exported chapter structure, omission rules, and `TrueCrimeCase.fromJson(draftToCaseJson(draft))` round trip.
- Legacy and chapter-bearing catalogue JSON through `LocalCasesRepository`.
- Draft preview projection includes chapters.
- Shared dossier content renders chapters once, in order, and omits empty sections.

### Widget and integration-like tests

- Chapter editor add/edit/remove/order behavior through fake draft persistence.
- Live preview updates after chapter editing.
- Published list renders cases and navigates with the correct slug.
- Mobile and desktop layouts expose list/page affordances without overflow.
- Expanded page, compact panel, and preview compose the same content.
- Unknown-slug behavior behind an injectable route/navigation adapter.

Tests involving `flutter_map` must use bounded `pump` calls rather than `pumpAndSettle`.

### Browser and host evidence

Widget tests cannot prove browser history, direct deployed navigation, refresh behavior, or GitHub Pages integration.

Implementation verification must include:

- Structural or source-level proof of route/hash parsing.
- Real-browser proof that a deployed known-case URL loads and survives refresh.
- Browser back/forward verification if history is written.
- Host-document preconditions verified by document readback, not widget viewport injection.

## Dependencies and non-goals

Existing Flutter, Riverpod, `shared_preferences`, and GitHub Pages are sufficient. No routing package is currently installed or required by the approved scope.

Non-goals:

- Android/iOS support.
- Backend, CMS, shared drafts, publication automation, authentication changes, or author attribution.
- Clean paths, server rewrites, redirects, or SEO/server rendering.
- Changing the manual publication circuit.
- Capturing `featuredRank` or `relevanceRank` unless scope is explicitly expanded later.
- Replacing or duplicating `CaseDossierPanel`.
- Incorporating `test/intake_narrow_layout_test.dart` into this change; it belongs to the archived `intake-responsive` cycle and was committed in `c351fac`.

## Risks and open technical questions

- **Route/state divergence:** a route coordinator should own synchronization between hash state and selected-case state.
- **Chapter schema:** proposal/design must define minimum fields, ordering, blank-entry export policy, and whether headings use a controlled vocabulary.
- **Dossier extraction:** shared content and contextual shell APIs must be designed before page implementation.
- **List ordering:** define deterministic behavior when `relevanceRank` is absent.
- **Mobile navigation:** specify a visible list entry and return path without competing with map controls.
- **Unknown deep links:** define not-found behavior and whether the hash remains visible.
- **Browser proof:** do not claim widget-only proof for deployed URL behavior.
- **Existing intake block:** resolved — `intake-responsive` was archived on 2026-08-13 through its native lifecycle, so apply is authorised.

## Recommended next phase

Proceed to proposal using this exploration and the approved product decisions. The apply block that gated this change is satisfied: `intake-responsive` was archived on 2026-08-13.
