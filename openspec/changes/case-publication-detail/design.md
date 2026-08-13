# Design: Public Case Publication Detail

This change extends the existing versioned-JSON publication circuit with four fixed editorial chapters, shareable hash dossier URLs, a catalog directory, and an expanded reading page. It retains the Situation Room map and defines dossier editorial content once for compact, preview, and routed contexts.

> **APPLY UNBLOCKED — `intake-responsive` archived 2026-08-13**
>
> The gate that held this change is satisfied: `intake-responsive` was archived
> with `blockers: 0`, and its `test/intake_narrow_layout_test.dart` baseline is
> committed on `main` in `c351fac`. That test pins the six-section registry
> contract, so adding a chapters section to `kCaseFormSections` **will** turn it
> red. Updating its expectation is required work, and it MUST go through the
> strict-TDD sequence defined in Sections 13–15 — observe the red, then change
> the expectation with the implementation, never the expectation alone.

## 1. Decisions at a glance

| ID | Decision |
| --- | --- |
| D1 | Represent chapters with a fixed `CaseChapterType` enum and an immutable `CaseChapters` value object, not a free-form list authored by UI code. |
| D2 | Use the same `chapters` JSON array shape for local drafts and published cases. Decode each optional entry independently and retain the first valid occurrence of each supported type. |
| D3 | Treat content as meaningful when `content.trim().isNotEmpty`; omit whitespace-only entries while preserving meaningful authored text verbatim. |
| D4 | Update chapters through `CaseDraftsNotifier.editDraft` transformations and serialize draft-store writes so rapid edits cannot persist an older snapshot after a newer one. |
| D5 | Replace `MaterialApp.home` with `MaterialApp.router`, a small custom `RouteInformationParser`, and a `RouterDelegate`. Keep Flutter’s default hash URL strategy. |
| D6 | The app route controller is the only source of routed slug state. `selectedCaseIdProvider` remains exclusively the Situation Room map selection. |
| D7 | Extract `CaseDossierContent` as the single editorial renderer while preserving the host chain: `IntakePreviewPanel` composes a preview-configured `CaseDossierPanel`, and `CaseDossierPanel` composes `CaseDossierContent`. Map and preview hosts supply panel configuration, callbacks, and source overrides; only the expanded route composes `CaseDossierContent` directly. |
| D8 | Derive the directory from the existing `casesProvider`, sorted by year descending, title ascending, then slug as a total-order fallback. |
| D9 | Present the directory as an adaptive modal surface over the Situation Room; it does not replace the map and does not create a second catalog route. |
| D10 | Distinguish catalog loading, catalog error, unknown slug, and valid dossier states without changing the active hash implicitly. |
| D11 | Implement through independently releasable direct-main work units, targeting at most 400 changed lines per unit and never exceeding the 1000-line review budget. |

## 2. Existing seams and constraints

The design builds on these concrete seams:

- `lib/app/true_crime_app.dart`: `TrueCrimeApp` currently creates a `MaterialApp` with only `home: const TrueCrimeHomePage()`.
- `lib/features/cases/domain/case_draft.dart`: `CaseDraft` already uses additive list fields and tolerant missing-member decoding.
- `lib/features/cases/application/case_draft_providers.dart`: `CaseDraftsNotifier.editDraft` applies a transformation to current draft state; `draftPreviewCaseProvider` projects a draft into `TrueCrimeCase`.
- `lib/features/cases/application/case_exporter.dart`: `draftToCaseJson` and `encodeDraftAsCaseJson` are the only supported draft-to-catalog bridge.
- `lib/features/cases/domain/true_crime_case.dart`: `TrueCrimeCase.fromJson` is the published-case decoding boundary.
- `lib/features/cases/data/local_cases_repository.dart`: `LocalCasesRepository.parseCasesJson` currently surfaces malformed core entries by allowing decoding failures to escape.
- `lib/features/cases/application/cases_providers.dart`: `casesProvider` owns the loaded catalog; `selectedCaseIdProvider` and `selectedCaseProvider` own map-context selection.
- `lib/features/cases/presentation/intake/case_form_section.dart`: `kCaseFormSections` is the ordered intake registry.
- `lib/features/home/presentation/widgets/situation/case_dossier_panel.dart`: `CaseDossierPanel` currently combines editorial content with map-specific provider writes and controls.
- `lib/features/home/presentation/home_page.dart`: `TrueCrimeHomePage` selects `_DesktopBody` or `_MobileBody` using shared `Breakpoints`.
- `lib/features/home/presentation/widgets/situation/situation_nav_rail.dart`: the existing list icon is inert and can become the wide-layout directory entry.
- `.github/workflows/deploy-pages.yml`: Flutter is built with the repository base href.
- `web/index.html`: the required mobile viewport declaration already exists and must remain host-document evidence rather than be inferred from widget viewports.

No routing package is present in `pubspec.yaml`, and none is required.

## 3. End-to-end architecture

### 3.1 Editorial data flow

```text
Fixed chapter fields
    │
    ▼
CaseDraftsNotifier.editDraft(draftId, current => ...)
    │
    ├── synchronous current-state transformation
    ├── serialized local-store save
    │
    ▼
CaseDraft.chapters: CaseChapters
    │
    ├── CaseDraft.toJson / CaseDraft.fromJson
    ├── draftPreviewCaseProvider
    └── draftToCaseJson
             │
             ▼
      assets/data/cases.json
             │
             ▼
LocalCasesRepository.parseCasesJson
             │
             ▼
TrueCrimeCase.chapters
             │
             ├── Situation Room
             │       └── CaseDossierPanel (map configuration)
             │               └── CaseDossierContent
             ├── IntakePreviewPanel
             │       └── CaseDossierPanel (preview configuration + source overrides)
             │               └── CaseDossierContent
             └── CaseDetailPage
                                       └── CaseDossierContent (expanded presentation)
```

### 3.2 Route data flow

```text
Browser hash / Back / Forward
             │
             ▼
AppRouteInformationParser
             │
             ▼
AppRouteController  ←── directory and related-case callbacks
             │
             ▼
AppRouterDelegate.currentConfiguration
             │
             ▼
Navigator pages
    ├── Situation Room
    ├── known/unknown case-detail route
    └── syntactically unknown route
             │
             ▼
caseBySlugProvider(slug)
    ├── loading
    ├── catalog error
    ├── null → case not found
    └── case → expanded dossier
```

Map selection does not participate in this flow.

## 4. Chapter domain and JSON contract

### 4.1 Domain types

Add `lib/features/cases/domain/case_chapter.dart` with these conceptual types:

```dart
enum CaseChapterType {
  background,
  events,
  investigation,
  currentStatus,
}

final class CaseChapter {
  const CaseChapter({
    required this.type,
    required this.content,
  });

  final CaseChapterType type;
  final String content;
}

final class CaseChapters {
  const CaseChapters({
    this.background,
    this.events,
    this.investigation,
    this.currentStatus,
  });

  final String? background;
  final String? events;
  final String? investigation;
  final String? currentStatus;

  List<CaseChapter> get orderedMeaningful;
  String? contentFor(CaseChapterType type);
  CaseChapters withContent(CaseChapterType type, String content);

  factory CaseChapters.fromJson(Object? value);
  List<Map<String, dynamic>> toJson();
}
```

`CaseChapters` is deliberately not an arbitrary public list:

- The four named slots enforce at most one chapter per type.
- `orderedMeaningful` always iterates in this order: `background`, `events`, `investigation`, `currentStatus`.
- The UI cannot insert another type or reorder the collection.
- Technical identity stays in the domain. Spanish headings are supplied later by a presentation extension and are never persisted as editable titles.

Both models receive an additive `CaseChapters chapters` field with `this.chapters = const CaseChapters()` in `CaseDraft` and `TrueCrimeCase`.

### 4.2 Wire representation

Draft and published JSON use the same optional shape:

```json
{
  "chapters": [
    {"type": "background", "content": "Meaningful authored text."},
    {"type": "events", "content": "Meaningful authored text."},
    {"type": "investigation", "content": "Meaningful authored text."},
    {"type": "currentStatus", "content": "Meaningful authored text."}
  ]
}
```

The only accepted wire identifiers are:

| Type | Wire value | Editorial position |
| --- | --- | ---: |
| Background | `background` | 1 |
| Events | `events` | 2 |
| Investigation | `investigation` | 3 |
| Current status | `currentStatus` | 4 |

There is no `title`, `heading`, ordering index, or arbitrary identifier in the schema. Extra object members are ignored and cannot override the heading.

`CaseDraft.toJson` and `draftToCaseJson` omit `chapters` when `orderedMeaningful` is empty.

### 4.3 Meaningful whitespace policy

A chapter is meaningful only when `content.trim().isNotEmpty`.

- Empty and whitespace-only values are absent from `orderedMeaningful`, preview, export, and public rendering.
- `withContent` removes the slot when the new value is whitespace-only.
- For meaningful content, the original string is preserved verbatim, including intentional internal newlines and leading or trailing whitespace.
- No layer collapses spaces, rewrites line endings deliberately, or applies rich-text interpretation.
- The meaningfulness check controls inclusion; it does not silently rewrite editorial prose.

### 4.4 Safe per-entry decoding

`CaseChapters.fromJson` is non-throwing because chapters are optional:

1. `null` or an absent member becomes `const CaseChapters()`.
2. A `chapters` value that is not a JSON array becomes empty.
3. Each array element is inspected independently.
4. An element is ignored when it is not an object; `type` or `content` is not a string; the type is unsupported; content is not meaningful; or the type duplicates an already accepted valid entry.
5. The first valid, meaningful entry for a supported type wins.
6. An invalid or whitespace-only earlier entry does not prevent a later valid entry of the same type from being accepted.
7. Accepted entries are returned through the fixed editorial order, regardless of input order.

This tolerant decoder is used by both `CaseDraft.fromJson` and `TrueCrimeCase.fromJson`.

Malformed required core fields remain outside this tolerance boundary. `LocalCasesRepository.parseCasesJson` MUST NOT catch a core decoding error and silently omit the case. Its existing fail-fast catalog behavior remains: `casesProvider` becomes an `AsyncError`, which the directory and route render as a catalog error rather than as “case not found.”

### 4.5 Persistence and migration

`SharedPreferencesCaseDraftsStore` keeps its existing schema envelope and `schemaVersion: 1`.

No migration is required because old drafts omit `chapters` and decode to an empty value, new empty drafts also omit it, old application versions ignore unknown members when decoding, and existing catalog entries need no mass update.

The manual publication circuit remains unchanged:

```text
Intake → copied JSON → assets/data/cases.json → commit → GitHub Pages
```

Export never writes the asset or starts deployment.

## 5. Draft editing and stale-write prevention

### 5.1 Fixed editor

Add a single intake section such as `sections/chapters_section.dart` to
`kCaseFormSections`, but only after the archived responsive baseline has
supplied the required RED.

Once `intake-responsive` is archived and its
`test/intake_narrow_layout_test.dart` is committed on `main`, the first
intake-registry mutation for this change MUST update that test from the
existing six-section expectation to the approved seven-section expectation,
with `Chapters` after `Fotografías`. The focused test MUST then be observed
RED because `kCaseFormSections` still exposes only six sections and lacks
`Chapters`. Only after recording that RED may implementation create and
register `ChaptersSection`; the same test must then become GREEN.

The section renders exactly four long-form fields by iterating
`CaseChapterType.values`. It provides no add, remove, drag, reorder, or
free-title controls. Clearing a field clears that chapter.

Each edit captures only the stable `draftId`, chapter type, and current text:

```dart
notifier.editDraft(draft.draftId, (current) {
  return current.copyWith(
    chapters: current.chapters.withContent(type, value),
  );
});
```

It MUST NOT build a replacement from the `draft` captured during `build`. Rapid edits to two chapter fields therefore merge into current state instead of overwriting one another.

### 5.2 Controller lifecycle

The fields follow the established `SummarySection` pattern without a shared external controller map:

- Each `TextFormField` uses an identity key containing both `draftId` and chapter wire type.
- `initialValue` comes from `draft.chapters.contentFor(type)`.
- Rebuilds for the same draft/type preserve internal editing state.
- Switching drafts changes the key and recreates the field with selected-draft content.
- No post-frame controller assignment races against a user keystroke.
- Clearing occurs through normal field editing.

### 5.3 Serialized persistence

The transformation pattern protects in-memory state, but concurrent asynchronous saves can finish out of order. Extend `CaseDraftsNotifier` with one private persistence queue used by `createDraft`, `updateDraft`, `editDraft`, and `deleteDraft`.

Each mutation:

1. computes and publishes latest state synchronously;
2. enqueues its immutable list snapshot after the prior store operation;
3. returns the future for its own save;
4. keeps the queue usable after a failed operation while still reporting that operation’s error.

This guarantees that a later save cannot be overwritten by an older save completing later. No debounce or background synchronization is added.

A behavior test must delay the first fake-store save, perform two edits without an intervening widget pump, release the saves, and prove that in-memory and persisted state contain the latest combined values.

## 6. Catalog providers

Extend `lib/features/cases/application/cases_providers.dart` with derived providers only.

### `caseBySlugProvider`

A family provider derives `AsyncValue<TrueCrimeCase?>` from `casesProvider` and performs exact slug matching. Loading remains loading; catalog failure remains an error; loaded catalog without match returns `null`; it never accesses `selectedCaseIdProvider`.

### `publishedDirectoryCasesProvider`

A derived provider transforms the same loaded catalog into a sorted immutable list. Comparator: year descending, title ascending, slug ascending only when both year and title match. Search, category, status, timeline, `featuredRank`, and `relevanceRank` do not affect directory order.

Because it watches `casesProvider`, opening the directory neither parses the asset again nor creates a second load.

## 7. Framework hash routing

### 7.1 Selected architecture

Replace `MaterialApp(home: ...)` with `MaterialApp.router` and add an app-level navigation package under `lib/app/navigation/`:

- `app_route_path.dart`
- `app_route_information_parser.dart`
- `app_route_controller.dart`
- `app_router_delegate.dart`
- `app_navigation.dart`

Conceptual route state:

```dart
sealed class AppRoutePath {
  const AppRoutePath();
}

final class SituationRoomPath extends AppRoutePath {
  const SituationRoomPath();
}

final class CaseDetailPath extends AppRoutePath {
  const CaseDetailPath(this.slug);
  final String slug;
}

final class UnknownAppPath extends AppRoutePath {
  const UnknownAppPath(this.uri);
  final Uri uri;
}
```

`TrueCrimeApp` creates controller and delegate once for the widget lifecycle.

### 7.2 Parser contract

`AppRouteInformationParser` recognizes:

| Route-information path | Result |
| --- | --- |
| empty or `/` | `SituationRoomPath` |
| exactly `/casos/<non-empty-single-segment>` | `CaseDetailPath(slug)` |
| everything else | `UnknownAppPath(uri)` |

Restoration emits `/`, `/casos/${Uri.encodeComponent(slug)}`, or the original unknown URI. Flutter web’s default URL strategy places these paths after the fragment, producing `/#/casos/<slug>`. The implementation MUST NOT call `usePathUrlStrategy` or access `dart:html`.

The existing Pages base-href build continues unchanged and needs no rewrite rule.

### 7.3 Router delegate and browser history

`AppRouterDelegate` builds a page stack:

```text
SituationRoomPath
└── Situation Room page

CaseDetailPath
├── Situation Room page
└── Case detail page keyed by slug

UnknownAppPath
├── Situation Room page
└── generic in-app route-not-found page
```

The controller exposes an injectable contract:

```dart
abstract interface class AppNavigation {
  void openCase(String slug);
  void showSituationRoom();
}
```

`openCase` changes route state and notifies the delegate. Back/Forward enters through `setNewRoutePath` without creating duplicate history. Applying `SituationRoomPath` through either `showSituationRoom` or `setNewRoutePath` MUST set `workspaceProvider` to `Workspace.situationRoom` before rendering the root page; platform restoration MUST NOT leave the root URL displaying `IntakeWorkspaceScreen`. This workspace correction creates no new history entry and does not clear `selectedCaseIdProvider`. No other route operation changes map selection; marker selection changes only selected map ID and does not rewrite URL.

### 7.4 Route and map state boundary

| Action | Route state | Map selection |
| --- | --- | --- |
| Tap map marker | Unchanged root route | Set selected case ID |
| Return to map from compact panel | Unchanged root route | Clear selected case ID |
| Open directory case | Set routed slug | Unchanged |
| Open related case from compact panel | Unchanged | Set related case ID |
| Open related case from expanded page | Set related routed slug | Unchanged |
| Directly load case hash | Set routed slug | Not required |
| Return from expanded page | Situation Room route | Preserve existing map selection |
| Browser Back/Forward | Restore platform route; root restoration also activates `Workspace.situationRoom` without adding history | Unchanged |

There is intentionally no provider mirroring routed slug.

## 8. Detail route states

`CaseDetailPage` watches `caseBySlugProvider(slug)` and renders:

| Catalog state | Page state |
| --- | --- |
| Loading | Reading-page shell with bounded progress indicator |
| Error | Catalog load error, retry, and return actions |
| Loaded, no matching slug | Case-not-found page |
| Loaded, matching case | Expanded dossier |

Unknown slug leaves its hash visible, substitutes no fallback case, does not touch map selection, and offers return to Situation Room. Generic unknown syntax is separate from a valid case route with a missing slug.

## 9. Shared dossier composition

### 9.1 Required composition chain

Extract editorial rendering from `case_dossier_panel.dart` into
`case_dossier_content.dart` without bypassing the existing preview host.

The composition invariant is:

```text
SituationSidePanel / mobile case sheet
    └── CaseDossierPanel(map configuration)
            └── CaseDossierContent(compact)

IntakePreviewPanel
    └── CaseDossierPanel(preview configuration, preview source overrides)
            └── CaseDossierContent(compact)

CaseDetailPage
    └── CaseDossierContent(expanded)
```

`IntakePreviewPanel` MUST continue composing `CaseDossierPanel`; it MUST NOT
become a parallel shell that composes `CaseDossierContent` directly. The
expanded detail page is the only host that composes shared content without
`CaseDossierPanel`.

### 9.2 Panel and content contracts

`case_dossier_panel.dart` defines a compact host configuration with map and
preview presets:

```dart
enum CaseDossierPanelMode { map, preview }

class CaseDossierPanel extends StatelessWidget {
  const CaseDossierPanel({
    required this.crimeCase,
    required this.relatedCases,
    required this.mode,
    this.onReturnToMap,
    this.onCenterMap,
    this.onOpenRelatedCase,
    this.sourceGroups,
  });

  final TrueCrimeCase crimeCase;
  final List<RelatedCase> relatedCases;
  final CaseDossierPanelMode mode;
  final VoidCallback? onReturnToMap;
  final VoidCallback? onCenterMap;
  final ValueChanged<TrueCrimeCase>? onOpenRelatedCase;
  final List<DossierSourceGroup>? sourceGroups;
}
```

Map mode renders existing return-to-map and compact footer controls and
receives callbacks that clear/recenter map state. Preview mode suppresses
return-to-map, recenter, follow, share, and other map/public chrome while
retaining compact dossier presentation. It receives no map callbacks.

In both modes, the panel composes:

```dart
class CaseDossierContent extends StatelessWidget {
  const CaseDossierContent({
    required this.crimeCase,
    required this.relatedCases,
    required this.presentation,
    this.onOpenRelatedCase,
    this.sourceGroups,
  });

  final TrueCrimeCase crimeCase;
  final List<RelatedCase> relatedCases;
  final DossierPresentation presentation;
  final ValueChanged<TrueCrimeCase>? onOpenRelatedCase;
  final List<DossierSourceGroup>? sourceGroups;
}
```

`CaseDossierContent` owns each editorial section exactly once:
identity/status, location/victim, stats, meaningful summary, meaningful
chapters, photos, timeline, sources, and related cases. Compact and expanded
presentations may vary spacing, typography, and constraints but invoke the
same section implementations.

### 9.3 Concrete source-group contract

Add
`lib/features/home/presentation/widgets/situation/dossier_source_group.dart`
with this presentation value:

```dart
@immutable
final class DossierSourceGroup {
  const DossierSourceGroup({
    required this.label,
    required this.sources,
  });

  final String label;
  final List<CaseSource> sources;
}
```

Callers provide an immutable source list. `CaseDossierContent` applies these
rules:

- When `sourceGroups == null`, it derives the normal published source
  presentation from `crimeCase.sources`.
- When `sourceGroups` is non-null, including an empty list, it renders only
  those groups and does not separately render `crimeCase.sources`.
- Empty groups are omitted.
- Every source card is rendered by the same shared source-section
  implementation.

`IntakePreviewPanel` derives preview groups by iterating
`DraftLinkKind.values` in enum order. For each draft link with a meaningful
URL, it creates the same `CaseSource` projection used by publication preview:
trimmed URL as `id` and `url`, meaningful trimmed title or URL fallback as
`title`, podcast links as `CaseSourceKind.podcast`, and all other draft link
kinds as `CaseSourceKind.investigation`. The group label comes from the
corresponding `DraftLinkKind` presentation label.

`IntakePreviewPanel` passes those groups to
`CaseDossierPanel(mode: CaseDossierPanelMode.preview, sourceGroups: groups)`.
The panel forwards them to `CaseDossierContent`. The current appended
`_LinkGroup` list is removed, but the preview-configured panel remains. This
override rule prevents projected `crimeCase.sources` and grouped draft links
from being rendered twice.

### 9.4 Host-specific actions

| Host | Required composition | Host-owned behavior |
| --- | --- | --- |
| Situation Room compact dossier | `CaseDossierPanel(map) → CaseDossierContent(compact)` | Clear selection, recenter, existing compact actions, and related-case callback that sets selected ID |
| Intake preview | `IntakePreviewPanel → CaseDossierPanel(preview) → CaseDossierContent(compact)` | Preview framing and source overrides; no map or routed-page chrome |
| Expanded detail page | `CaseDetailPage → CaseDossierContent(expanded)` | Page return action and related-case callback that navigates by slug |

Editorial subwidgets perform no direct provider writes. Desktop and mobile
map hosts inject map callbacks into the panel. The expanded route injects
routed navigation directly into shared content and cannot inherit map-only
controls.

### 9.5 Chapter presentation

Headings derive from `CaseChapterType` through a presentation extension.
Spanish labels and comments are added only during implementation. Shared
content iterates `orderedMeaningful`, guaranteeing fixed order, no empty
heading, no duplicate section, and normal legacy rendering.

## 10. Expanded responsive page

Add `lib/features/home/presentation/case_detail_page.dart` using `Scaffold`, `SafeArea`, page return action, one vertical scroll surface, centered desktop reading width, compact mobile padding, responsive metadata, horizontally scrollable photo strips as appropriate, and reachable related-case controls. It must not depend on a desktop-only row or oversized test viewport.

## 11. Published-case directory

### 11.1 Presentation

Add `published_case_directory.dart`, watching `publishedDirectoryCasesProvider` and rendering loading, catalog error/retry, empty catalog, or ordered `ListView`. Mobile uses a scroll-controlled `SafeArea` bottom sheet; desktop uses constrained dialog/side sheet over mounted Situation Room. Opening an entry closes modal then navigates by slug.

### 11.2 Entry points

- Activate existing list icon where `SituationNavRail` is visible.
- Where rail is hidden, expose the same action through a map-stage trailing-control slot alongside overlays, avoiding another fixed-width action in `SituationTopBar`.
- Keep it clear of the respect badge and mobile case sheet.
- Both entry points use the same modal and provider.

### 11.3 Map preservation

The modal overlays existing home body; it does not replace the map, alter filters, recenter, or change selection. It derives from complete `casesProvider`, not filtered cases.

## 12. File change plan

| Path | Planned change |
| --- | --- |
| `lib/features/cases/domain/case_chapter.dart` | New fixed chapter enum, value object, ordering, and tolerant codec. |
| `lib/features/cases/domain/case_draft.dart` | Add chapters and additive JSON handling. |
| `lib/features/cases/domain/true_crime_case.dart` | Add default-empty published chapters. |
| `lib/features/cases/application/case_exporter.dart` | Export meaningful ordered chapters. |
| `lib/features/cases/application/case_draft_providers.dart` | Project chapters and serialize saves. |
| `lib/features/cases/application/cases_providers.dart` | Add slug resolver and directory providers. |
| `lib/features/cases/presentation/intake/sections/chapters_section.dart` | Add the fixed four-field editor only after the seven-section registry test has been observed RED. |
| `lib/features/cases/presentation/intake/case_form_section.dart` | Register `Chapters` after `Fotografías` only after the required registry RED. |
| `lib/features/cases/presentation/intake/intake_preview_panel.dart` | Continue composing a preview-configured `CaseDossierPanel`, pass grouped source overrides, and remove only the appended duplicate source list. |
| `lib/features/cases/presentation/case_chapter_presentation.dart` | Spanish presentation labels. |
| `lib/features/home/presentation/widgets/situation/dossier_source_group.dart` | Define the immutable `DossierSourceGroup` source-rendering contract. |
| `lib/features/home/presentation/widgets/situation/case_dossier_content.dart` | New single editorial renderer used through the panel and directly by the expanded page. |
| `lib/features/home/presentation/widgets/situation/case_dossier_panel.dart` | Retain the compact shell, add map/preview configuration, forward callbacks and source overrides, and compose `CaseDossierContent`. |
| `lib/features/home/presentation/widgets/situation/situation_side_panel.dart` | Supply desktop map-context panel configuration and callbacks. |
| `lib/features/home/presentation/home_page.dart` | Supply mobile map-context panel callbacks and add directory opening/navigation injection. |
| `lib/features/home/presentation/widgets/situation/situation_map_stage.dart` | Add rail-less directory affordance slot. |
| `lib/features/home/presentation/widgets/situation/situation_nav_rail.dart` | Activate list icon. |
| `lib/features/home/presentation/widgets/situation/published_case_directory.dart` | New adaptive directory. |
| `lib/features/home/presentation/case_detail_page.dart` | New route state and expanded page host that composes `CaseDossierContent` directly. |
| `lib/app/navigation/*` | New route model, parser, controller, delegate, navigation contract. |
| `lib/app/true_crime_app.dart` | Switch to `MaterialApp.router`. |
| `.github/workflows/deploy-pages.yml` | No planned behavior change. |
| `web/index.html` | No planned behavior change. |
| `assets/data/cases.json` | No automatic migration/change. |
| `test/intake_narrow_layout_test.dart` | Do not touch while `intake-responsive` is open. After archive and baseline commit, update its registry expectation from six to seven before registering `Chapters`; record the required RED, then register the section and obtain GREEN. |

## 13. Strict-TDD test strategy

No test for this change may be edited or executed before dependency archive.
After archive, `test/intake_narrow_layout_test.dart` must first exist as a
committed six-section baseline inherited from `intake-responsive`.

The intake registry remains unchanged while dormant chapter data, persistence,
export, preview projection, and shared rendering infrastructure are delivered.
Only after those prerequisites are available may the authoring surface be
activated. Its registry RED is mandatory and ordered:

1. Before creating or registering `ChaptersSection`, update the baseline test
   from six to seven sections and assert `Chapters` after `Fotografías`.
2. Run that focused test and record RED because the registry still has only
   six sections and lacks `Chapters`.
3. Add and register `ChaptersSection`.
4. Run the same focused test and record GREEN with all seven sections
   reachable in order.
5. Run the focused editor and live-preview tests to prove the newly activated
   surface has persistence, export, projection, and shared rendering behind it.

Every behavior unit records the exact focused command, expected RED, why it
proves missing behavior, the same test becoming GREEN, and the broader suite
after refactoring.

### 13.1 RED evidence units

| Unit | Planned focused test | Required initial RED |
| --- | --- | --- |
| Intake registry activation — after dormant prerequisites | `test/intake_narrow_layout_test.dart` | After changing the committed expectation from six to seven before registration, the workspace exposes only six sections and `Chapters` is missing after `Fotografías`. |
| Chapter codec | `test/case_chapter_codec_test.dart` | Fixed types/order or tolerant decoding absent. |
| Draft compatibility | `test/case_draft_chapters_test.dart` | Round trip or legacy behavior absent. |
| Serialized editing | `test/case_draft_chapter_editing_test.dart` | Delayed older save overwrites or loses a rapid edit. |
| Export round trip | `test/case_publication_chapters_test.dart` | Meaningful export, omission, or round trip fails. |
| Catalog tolerance | `test/local_cases_repository_chapters_test.dart` | Optional malformed chapter breaks case or core error is hidden. |
| Intake editor | `test/chapters_section_test.dart` | Four fixed fields, no free action, or edit/clear behavior is absent. |
| Live preview and panel chain | `test/intake_chapter_preview_test.dart` | Current changes are not shown once/in order through `IntakePreviewPanel → CaseDossierPanel → CaseDossierContent`, or preview mode leaks map chrome. |
| Dossier extraction and source override | `test/case_dossier_content_test.dart` | Sections duplicate/omit, grouped preview sources render alongside projected sources, or hosts diverge. |
| Host navigation | `test/dossier_host_navigation_test.dart` | Map and route callbacks cannot remain independent. |
| Route parser | `test/app_route_parser_test.dart` | Parse/restore symmetry is absent. |
| Routed states | `test/case_detail_page_test.dart` | Loading/error/not-found/legacy/known states are not distinguished. |
| Framework history | `test/app_router_test.dart` | Platform route changes fail to restore the page stack. |
| Directory | `test/published_case_directory_test.dart` | Entries are incomplete, wrongly ordered, independently reloaded, or use the wrong identity. |
| Responsive access | `test/home_directory_layout_test.dart` | Mobile/desktop actions overflow or are unreachable. |

Existing behavior characterization may be green before extraction, but every
new chapter, panel-configuration, source-override, or host-callback behavior
still requires observed RED.

### 13.2 Widget rules

- Never use `pumpAndSettle` with `flutter_map` or animated home widgets.
- Use bounded 400ms pumps.
- Rapid-edit tests issue changes without a pump between input events.
- Use realistic compact/wide dimensions.
- Override providers with fake repositories/stores.
- Inject fake navigation and assert exact slug.
- Direct route tests must not write selected map ID first.

### 13.3 Structural and host evidence

Verification must inspect parser/restorer and absence of `dart:html` or clean path strategy; build with Pages base href; read `build/web/index.html`; confirm base href and viewport; and confirm workflow publishes build output. Widget viewport overrides prove none of these.

### 13.4 Real-browser boundary

After deployment, record browser/version, deployed commit SHA, URL, visible hash, and title while checking direct known route, refresh, A→B navigation, Back twice, Forward twice, unknown slug preservation and return, and directory use in compact/mobile and wide/desktop layouts.

Because Pages deploys after direct-main commits, failed evidence triggers rollback rather than fabricated completion.

## 14. Implementation gate and post-archive rebase

Before the first apply unit:

1. Confirm native/OpenSpec status says `intake-responsive` is legitimately
   archived.
2. Confirm its archived delta and final source are present on `main`.
3. Confirm `test/intake_narrow_layout_test.dart` is committed on `main` as
   the archived six-section baseline. If it remains uncommitted or archive is
   incomplete, stop without stashing, resetting, staging, or modifying it.
4. Fetch and fast-forward to the archived revision; rebase any temporary
   branch onto that exact post-archive `main`.
5. Re-read the draft model/providers, intake registry/composition/preview,
   exporter, dossier panel, home layouts, and all tests changed by
   `intake-responsive`.
6. Reconcile the design and tasks against those archived bytes.
7. Begin Unit 1 with its focused chapter-domain RED; do not edit the intake
   registry or its responsive expectation yet.
8. Deliver Units 1–4 as dormant prerequisites: chapter data/codec, publication
   compatibility, serialized persistence/preview projection, and shared dossier
   rendering. None exposes the chapter editor.
9. At Unit 5 activation, update the committed narrow-layout test from six to
   seven expected sections and assert `Chapters` after `Fotografías`, without
   yet creating or registering `ChaptersSection`.
10. Run the focused registry test and record RED for the missing seventh
    section.
11. Only then create/register `ChaptersSection`, prove its editor/live-preview
    behavior, and rerun the registry test to GREEN.

## 15. Review workload forecast and direct-main slicing

- Estimated aggregate changed lines including tests: **1,450–2,100**.
- **400-line budget risk: High** for an unsliced aggregate change.
- Every source-bearing unit below is forecast below 400 changed lines,
  including its focused tests.
- Aggregate full-change review is unsuitable.
- **Chained PRs recommended: No**, because the repository delivers direct
  commits to `main` without PRs.
- Equivalent staged direct-main work units are mandatory.
- Apply is authorised; Unit 0 still runs first to evidence the gate rather than assume it.

| Unit | Scope | Forecast including tests | Releasable state |
| --- | --- | ---: | --- |
| 0 | Archive confirmation, baseline-commit check, fast-forward/rebase, source re-read, task revalidation | 0 source lines | No source change |
| 1 | Chapter enum/value object, tolerant codec, additive `CaseDraft` field, and focused domain/draft tests; no intake registration | 150–220 | Dormant local chapter representation; no authoring surface |
| 2 | Published model decoding, export omission/round trip, malformed optional-entry policy, and catalog tests | 170–240 | Dormant publication-data support with legacy compatibility |
| 3 | Serialized draft persistence, preview projection, and rapid-edit projection tests; no visible chapter field | 130–180 | Race-safe dormant chapter persistence and preview data |
| 4 | `DossierSourceGroup`, shared-content extraction, map/preview panel configurations, explicit callbacks, preview source override, chapter rendering, and characterization tests | 260–350 | One editorial renderer; chapter data can render but no editor is exposed |
| 5 | Update registry expectation to seven for RED, then add fixed chapter editor/registry entry and live-preview activation tests | 150–220 | Complete authoring circuit activated only after its prerequisites |
| 6 | Dormant route foundation: route model, parser, controller/delegate, restoration/history model tests; do not switch the app root yet | 180–250 | Tested routing infrastructure with public behavior unchanged |
| 7 | Route activation: `MaterialApp.router`, complete `CaseDetailPage` loading/error/not-found/known-case composition, expanded responsive layout, and direct-route tests | 260–360 | Stable hash routes with a complete valid-case experience |
| 8 | Directory provider/order, adaptive modal, mobile/desktop entry points, map-preservation and navigation tests | 170–240 | Complete public discovery path |
| 9 | Full verification, web-build readback, deployment, and real-browser proof | 0 source lines; evidence only | Eligible for completion/archive |

Forecast range across source-bearing units is **1,470–2,060 changed
lines**. The aggregate estimate is therefore revised to **1,450–2,100** lines. If an
actual unit reaches 400 changed lines before normalization, stop and split it
before review or direct-main commit.

Each source-bearing unit gets focused RED/GREEN evidence, suite/analyze,
bounded review, and a direct-main commit. No production chapter data is
required to land infrastructure.

## 16. Rollout

1. Design/tasks complete.
2. `intake-responsive` archived legitimately on 2026-08-13.
3. Fast-forward/rebase and re-read source (Unit 0).
4. Apply work units in dependency order.
5. Keep existing catalog unchanged unless a maintainer separately publishes chapters.
6. Let Pages workflow test/build/deploy each direct-main commit.
7. Smoke-check Situation Room after each deploy.
8. Collect browser evidence after route/directory deploy.
9. Complete only when domain/widget/static checks and deployed evidence agree.

## 17. Rollback

Revert source-bearing work units in strict reverse dependency order:

1. Unit 8 — directory provider, adaptive directory, and entry points.
2. Unit 7 — route activation, complete detail page, and expanded responsive composition.
3. Unit 6 — dormant router model, parser, controller, and delegate.
4. Unit 5 — chapter editor and seven-section registry activation.
5. Unit 4 — shared dossier extraction, panel configurations, callbacks, source overrides, and chapter rendering.
6. Unit 3 — serialized draft persistence and preview projection.
7. Unit 2 — published chapter decoding, export, and catalog compatibility.
8. Unit 1 — chapter domain/draft representation.

After each revert, run its bounded verification and confirm the Situation Room remains usable before reverting the next prerequisite. Restore the prior known-good `assets/data/cases.json` separately if a manual editorial publication introduced problematic chapter data; catalog recovery is not a substitute for reverting application units. Push the approved revert sequence and verify the Situation Room after each Pages redeploy.

Older code may strip unknown local chapter fields on a later save. During full rollback, editors must not reopen or save affected drafts until local draft JSON is backed up or a forward-compatible recovery exists. Rollback itself does not mutate browser storage.

## 18. Rejected alternatives

- **Direct `dart:html`:** web-only, bypasses Flutter route lifecycle, creates manual listener ownership and second truth source.
- **Named routes only:** weaker explicit bidirectional parsing/restoration and platform route ownership than Router API.
- **External router:** unnecessary dependency for root/detail/unknown graph.
- **Clean paths on Pages:** refresh requests non-existent static paths without rewrites.
- **Duplicated expanded dossier:** allows compact/preview/page drift.
- **Mirroring routed slug into map selection:** couples direct routes to map and creates conflicting mutable sources.
- **Backend/CMS:** violates approved versioned JSON workflow.
- **Free-form chapters:** weakens consistency and violates approved fixed model.

## 19. Requirement traceability

| Capability | Design coverage |
| --- | --- |
| Fixed chapter set/order | D1–D3; Section 4 |
| Meaningful content/omission | Sections 4.3–4.4 |
| Draft persistence/live preview | Sections 5 and 13 |
| Publication round trip | Sections 3–4 and 13 |
| Additive/malformed decoding | Section 4.4 |
| Manual publication boundary | Section 4.5 |
| Implementation gate/strict TDD | Sections 13–14 |
| Stable hash identity | Section 7 |
| Direct load/refresh/history | Sections 7 and 13.4 |
| Unknown slug behavior | Section 8 |
| Browser/host evidence | Sections 13.3–13.4 |
| Directory access/order/reuse/navigation | Sections 6 and 11 |
| Map preservation | Sections 7.4 and 11.3 |
| Shared dossier and host actions | Section 9 |
| Responsive expanded experience | Section 10 |
| Direct-main rollout/rollback | Sections 15–17 |
