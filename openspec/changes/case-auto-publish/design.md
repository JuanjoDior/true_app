# Design: Batch Case Publication Handoff

This change adds one pure catalog-merge function in the application layer, one raw-payload read of the published catalog, one additive handoff marker on `CaseDraft`, and one selector dialog in the intake workspace. Everything else is reused: `caseSlug` / `uniqueCaseSlug` / `draftToCaseJson` produce the case objects, `draftsFileTransferProvider.save(...)` delivers the file, and `LocalCasesRepository` stays read-only. The app still writes nothing into the repository; it hands the maintainer a complete `cases.json` to drop in, commit and push.

> **Two deviations from the proposal are recorded here, not hidden.** The proposal's `## Approach` says the merge function "takes the loaded `List<TrueCrimeCase>`". `TrueCrimeCase` has **no** `toJson` (`lib/features/cases/domain/true_crime_case.dart` ends at line 131 with `fromJson` as its only codec) and its decoding is deliberately lossy. See §4 — the merge base is the **undecoded** catalog payload instead. The second deviation is the compact-layout placement of the trigger; see §8.2.

---

## 1. Decisions at a glance

| ID | Decision |
| --- | --- |
| **D1** | The merge base is the **raw, undecoded** `assets/data/cases.json` payload (`List<Map<String, dynamic>>`), not `List<TrueCrimeCase>`. A decode→encode round trip through the published model is lossy and rewrites the whole file. |
| **D2** | Read that payload through a new `publishedCatalogPayloadProvider` (`FutureProvider<String>`) backed by a small `PublishedCatalogSource` in `data/`. `CasesRepository` is **not** extended — adding a method to it would break 11 existing test fakes and the proposal marks it Unchanged. |
| **D3** | **An unreadable catalog is never treated as an empty catalog.** Payload load/parse failure renders an error state and disables confirm. Merging into `[]` is the exact failure this change exists to prevent. |
| **D4** | Add `mergeDraftsIntoCatalog(...) → CatalogMergeResult` and `encodeMergedCatalog(result) → String` to `case_exporter.dart`, mirroring the existing `draftToCaseJson` / `encodeDraftAsCaseJson` map+string pair. Pure, Flutter-free, no second slug implementation. |
| **D5** | A collision-replaced entry keeps the **array index** of the entry it replaced. Array order carries no semantics, but a minimal diff is a stated goal of this change. |
| **D6** | The merge result carries a per-draft `CatalogMergeEntry` (`added` \| `replaced`, replaced title, `droppedKeys`). The dialog renders that same result it later encodes — one computation, so the preview cannot disagree with the file. |
| **D7** | Replacement is wholesale, as the proposal locked. Keys the draft cannot express (`statusLabel`, and `featuredRank`/`relevanceRank` when unset) are reported per draft as `droppedKeys` **before** confirm. A replace is never silent at field granularity. |
| **D8** | Unselected drafts' prospective slugs do **not** join the taken set. A slug is taken when it is published, not when someone is drafting it. This deliberately differs from `ExportCaseButton` (`export_case_button.dart:41-47`); see §5.4. |
| **D9** | Mark handoff with two additive nullable fields on `CaseDraft`: `handoffSlug` (the slug actually assigned in the batch) and `handoffAt`. Answer to Open Question 1. |
| **D10** | `copyWith` and `withResolvedPlace` **carry the marker through** without exposing it as a parameter. `markHandedOff` is the single writer. Omitting the pass-through would silently erase the marker on the next keystroke. |
| **D11** | The draft list subtitle becomes a four-state derivation `incomplete / ready / handedOff / published` from one pure function plus the loaded catalog's slug set. Pre-change drafts decode with a null marker and behave exactly as today. |
| **D12** | Stale-merge-base detection is **derived, not session state**: a draft carrying a handoff marker whose slug is absent from the loaded catalog is the signal. It survives a browser restart, which a session counter does not. Answer to Open Question 2. |
| **D13** | When that signal fires, confirm is gated behind an explicit acknowledgement checkbox. Zero friction in the normal case; a hard stop exactly when published cases could silently disappear. |
| **D14** | Drafts are marked handed off **only after** `save(...)` returns `true`, in one batched `markHandedOff` mutation — one state publish, one persist. A cancelled save-as marks nothing. |
| **D15** | The produced file is offered as `cases.json`, deliberately **without** the date that `draftsBackupFileName` adds. A backup accumulates; a drop-in replacement must carry the target file's name. |
| **D16** | No in-app "reload the page" action. `dart:html` is prohibited by the archived routing design's rejected alternatives; the copy instructs the reload instead. |

---

## 2. Existing seams and constraints

Verified against current source on 2026-09-22, not inherited from the exploration.

| Seam | Location | What it gives this change |
| --- | --- | --- |
| Slug identity | `case_exporter.dart:61` `caseSlug`, `:85` `uniqueCaseSlug` | Reused verbatim. No second implementation. |
| Draft → case JSON | `case_exporter.dart:100` `draftToCaseJson`, `:182` `encodeDraftAsCaseJson` | Reused verbatim; the encoder pair is the shape the new functions mirror. |
| Published decoder | `true_crime_case.dart:91` `fromJson` — **no `toJson` exists** | Round-trip target for tests; unusable as an encoder (§4). |
| Tolerant sub-decoders | `case_photo.dart:12-22`, `case_chapter.dart:111-130` | Deliberately drop unusable entries — which makes model→JSON lossy (§4.1). |
| Catalog read | `local_cases_repository.dart:18-28`; `cases_repository.dart:3-5` (one method) | Stays untouched. 11 test fakes implement this interface. |
| Catalog providers | `cases_providers.dart:24` `casesRepositoryProvider`, `:32` `casesProvider` | `casesProvider` remains the typed catalog for the rest of the app. |
| Second-read warning | `cases_providers.dart:89-102` | An explicit in-repo principle against re-reading the catalog. Addressed head-on in §4.3. |
| File transfer | `drafts_file_transfer.dart:12-20`; provider at `case_draft_providers.dart:26` | Reused as-is. `save` returns `false` on cancel. |
| Save idiom | `drafts_backup_button.dart:68-84` (`if (!saved) return;` at `:76-78`) | The exact control flow the confirm handler copies. |
| Draft mutation | `case_draft_providers.dart:67` `_persist` (serialized write queue), `:106` `editDraft` | New batched mutation enters the same queue. |
| Draft codec | `case_draft.dart:76` `copyWith`, `:123` `withResolvedPlace`, `:147` `fromJson`, `:186` `toJson` | Additive-only, named-key decoding: unknown members are ignored, missing members decode to null. |
| Intake top bar | `intake_workspace_screen.dart:136-165` (compact), `:166-182` (wide) | Host for the wide trigger; capacity analysed in §8.2. |
| Draft list | `intake_workspace_screen.dart:189-245`, subtitle at `:223` | Where the four-state subtitle lands; also the compact trigger host. |
| Narrow baseline | `breakpoints.dart:39` (`intakeThreePane = 1200`); `test/intake_narrow_layout_test.dart:42` (`Size(360, 780)`) | The viewport every narrow assertion uses. |
| Real-asset test precedent | `test/local_cases_repository_chapters_test.dart:52` | `File('assets/data/cases.json').readAsString()` is already idiomatic here. |
| Fakes to copy | `test/drafts_backup_button_test.dart:19-31` (`_FakeStore`), `:56-79` (`_FakeFileTransfer`) | The override pattern the new widget tests reuse. |

Project rules that constrain implementation (`openspec/config.yaml`): strict TDD, `flutter test` + `flutter analyze`, Spanish UI copy and comments, English artifacts, **`copyWith` does not clear fields — use explicit methods such as `withResolvedPlace`**, no `pumpAndSettle` with animated widgets, and no oversized test viewports to dodge overflow.

---

## 3. Architecture and data flow

```text
assets/data/cases.json  (build-time asset, immutable within a page load)
        │
        ├──────────────────────────────┐
        ▼                              ▼
LocalCasesRepository.getCases()   PublishedCatalogSource.loadPayload()
        │  (decoded, lossy)            │  (raw text, lossless)
        ▼                              ▼
   casesProvider                publishedCatalogPayloadProvider
   List<TrueCrimeCase>                 String
        │                              │
        │ slugs only                   ▼
        │                    decodeCatalogPayload(payload)
        │                    List<Map<String, dynamic>>
        │                              │
        ▼                              ▼
 publishedSlugsProvider        mergeDraftsIntoCatalog(catalog:, drafts:)
        │                              │
        │                              ├── caseSlug / uniqueCaseSlug  (reused)
        │                              ├── draftToCaseJson            (reused)
        │                              ▼
        │                       CatalogMergeResult
        │                        ├── cases:   full array, order preserved
        │                        └── entries: added | replaced, droppedKeys
        │                              │
        │            ┌─────────────────┴─────────────────┐
        │            ▼                                   ▼
        │   PublishBatchDialog preview          encodeMergedCatalog(result)
        │   (same result object)                         │
        │                                                ▼
        │                              draftsFileTransferProvider.save(
        │                                  fileName: 'cases.json', contents: …)
        │                                                │
        │                                     saved == true ─┐
        ▼                                                    ▼
draftPublicationState(draft, publishedSlugs)   CaseDraftsNotifier.markHandedOff(
        │                                          {draftId: assignedSlug})
        ▼                                                    │
 _DraftList subtitle  ◄──────── CaseDraft.handoffSlug ◄──────┘
 Incompleto / Listo · sin publicar /
 Entregado · pendiente de publicar / Publicado
```

Nothing in this flow writes the repository, calls the network, or touches `CasesRepository`.

---

## 4. The merge base: raw payload, not `List<TrueCrimeCase>` (D1–D3)

### 4.1 Why the proposal's shape does not work

The proposal assumes a `TrueCrimeCase → JSON` path. There is none, and adding one would not be safe:

| Loss | Evidence |
| --- | --- |
| Unknown keys vanish | `TrueCrimeCase.fromJson` (`:91-130`) reads a fixed key set; anything else is dropped on decode and cannot be re-emitted. |
| Photos without a usable URL vanish | `CasePhoto.tryFromJson` returns `null` for an empty URL (`case_photo.dart:12-17`), and `fromJson` filters with `.nonNulls`. |
| Malformed / duplicate / blank chapters vanish | `CaseChapters.fromJson` (`case_chapter.dart:111-130`) silently ignores them by design. |
| Key order is rewritten across the whole file | The catalog carries **two** key orders today: hand-authored entries (`cases.json:3-53`, `tags → featuredRank → relevanceRank → status → statusLabel → victim → timeline → sources`) and exporter-produced entries (`cases.json:744-789`, `tags → sources → status → victim → timeline`, no ranks, no `statusLabel`). A model round trip normalises all of them at once. |
| Explicit `null` members are rewritten | `"featuredRank": null` (`cases.json:71`) survives a raw round trip; the model emits nothing for a null rank. |
| Numeric formatting is normalised | `latitude: (json['latitude'] as num).toDouble()` turns an integer coordinate into `40.0`. |

Each of those makes the produced file differ from the one on disk in entries **nobody selected**, which directly contradicts the spec requirement *Catalog Preservation for Unselected Entries* ("the same content it had in the loaded catalog") and destroys the reviewable diff the proposal asks for.

### 4.2 What the raw base buys

`jsonDecode` yields `LinkedHashMap`s, so key order is preserved per entry, and `JsonEncoder.withIndent('  ')` does not escape non-ASCII — which is exactly the encoding the current asset already uses (`"actuó"` at `cases.json:13`). Re-encoding an unmodified catalog therefore reproduces the file, and the git diff of a produced `cases.json` shows only the entries that were added or replaced. §11 pins this with a characterization test against the **real** asset.

### 4.3 Answering the repo's own "second read" warning

`cases_providers.dart:89-102` states plainly that a second catalog read "sería un segundo origen de verdad que puede discrepar del primero". That warning is about `publishedDirectoryProvider`, which needs *the same decoded cases* the map already holds; re-parsing there would buy nothing. This case is different on both counts:

1. The typed provider structurally **cannot** supply what the merge needs (the undecoded bytes). This is not a duplicate read of the same value; it is a read of a different value.
2. Divergence is impossible in production: both reads go through `rootBundle`, a `CachingAssetBundle`, against the same build-time asset key within one page load.

The one place they can diverge is a **test** that overrides one provider and not the other. §11 makes consistent overrides an explicit rule for the new widget tests.

### 4.4 Rejected: extend `CasesRepository`

Adding `Future<String> getRawCatalog()` to `CasesRepository` (`cases_repository.dart:3-5`) would force edits to 11 files that `implements CasesRepository` (`test/case_by_slug_provider_test.dart`, `test/app_routing_activation_test.dart`, `test/case_detail_page_test.dart`, `test/case_directory_provider_test.dart` ×2, `test/case_directory_test.dart` ×2, `test/map_tooltip_navigation_test.dart`, `test/test_support/sample_cases.dart`, and both stub/failing variants), none of which have anything to do with this change. The proposal also lists `local_cases_repository.dart` as **Unchanged**. A standalone source keeps that promise.

---

## 5. Catalog merge contract

### 5.1 Types

Added to `lib/features/cases/application/case_exporter.dart`. `final class` without `@immutable`, matching `CaseChapter`/`CaseChapters` and keeping the file Flutter-free (it imports only `dart:convert` and domain models today).

```dart
/// Qué le pasó a un borrador seleccionado dentro del lote.
enum CatalogMergeOutcome { added, replaced }

/// El destino de un borrador dentro del catálogo fundido.
final class CatalogMergeEntry {
  const CatalogMergeEntry({
    required this.draftId,
    required this.title,
    required this.slug,
    required this.outcome,
    this.replacedTitle,
    this.droppedKeys = const <String>[],
  });

  final String draftId;
  final String title;

  /// Identidad pública asignada dentro de ESTE lote.
  final String slug;
  final CatalogMergeOutcome outcome;

  /// Título de la entrada publicada que se sustituye. Null si [outcome] es
  /// [CatalogMergeOutcome.added].
  final String? replacedTitle;

  /// Claves que la entrada publicada tenía y el borrador no puede expresar
  /// (`statusLabel`, un `featuredRank` que el borrador no rellena…). Se
  /// pierden al sustituirla, y por eso se enseñan ANTES de confirmar.
  final List<String> droppedKeys;
}

/// Catálogo completo más la traza de qué hizo el lote.
final class CatalogMergeResult {
  const CatalogMergeResult({required this.cases, required this.entries});

  /// Array completo, listo para sustituir `assets/data/cases.json`.
  final List<Map<String, dynamic>> cases;

  /// Un elemento por borrador seleccionado, en orden de selección.
  final List<CatalogMergeEntry> entries;

  Iterable<CatalogMergeEntry> get replacements =>
      entries.where((e) => e.outcome == CatalogMergeOutcome.replaced);
}
```

### 5.2 Functions

```dart
/// Decodifica el asset publicado sin perder nada: cada caso viaja tal y como
/// está escrito en el fichero.
///
/// Lanza [FormatException] si el texto no es un array de objetos. NO devuelve
/// una lista vacía ante un fallo: fundir sobre un catálogo vacío borraría todo
/// lo publicado [D3].
List<Map<String, dynamic>> decodeCatalogPayload(String payload);

/// Funde los borradores seleccionados en el catálogo cargado.
///
/// [catalog] llega decodificado por [decodeCatalogPayload]; [drafts] en el
/// orden en que se seleccionaron. Es pura: mismas entradas, mismo resultado.
CatalogMergeResult mergeDraftsIntoCatalog({
  required List<Map<String, dynamic>> catalog,
  required List<CaseDraft> drafts,
});

/// Texto listo para sustituir `assets/data/cases.json`: dos espacios de
/// sangría y acentos sin escapar, como el resto del catálogo.
String encodeMergedCatalog(CatalogMergeResult result);
```

`mergeDraftsIntoCatalog` takes the decoded list rather than the payload string so the dialog decodes once and merges on every selection change without re-parsing. `decodeCatalogPayload` is the single documented decoder; there is no convenience overload that takes a `String`, because two entry points is how the two paths start to drift.

### 5.3 Algorithm

```text
taken      := { entry['slug'] for entry in catalog, where it is a String }
batchSlugs := {}                      # slugs this batch has already claimed
cases      := [...catalog]            # positional copy
entries    := []

for draft in drafts (selection order):
    base := caseSlug(draft.title.trim())

    if base ∈ taken and base ∉ batchSlugs:
        # replace: the maintainer deliberately re-publishes this identity
        index := position of the catalog entry whose slug == base
        json  := draftToCaseJson(draft, takenSlugs: const {})   # claims `base`
        dropped := cases[index].keys where not json.containsKey(key)
        entries += CatalogMergeEntry(replaced, slug: base,
                                     replacedTitle: cases[index]['title'],
                                     droppedKeys: dropped)
        cases[index] := json                                    # index kept [D5]
    else:
        slug := uniqueCaseSlug(base, taken)
        json := draftToCaseJson(draft, takenSlugs: taken)
        entries += CatalogMergeEntry(added, slug: slug)
        cases += json

    taken      += slug
    batchSlugs += slug
```

Three consequences worth stating explicitly:

- **`base ∉ batchSlugs` is what stops a double replace.** Two selected drafts that both slugify to `known-case`: the first replaces the published entry; the second falls to the `added` branch, where `uniqueCaseSlug` sees `known-case` in `taken` and returns `known-case-2`. Exactly one entry per slug, and the first draft is not silently overwritten by the second — which is both spec requirements (*Batch-Wide Sequential Slug Resolution* and *Collision Replacement Against Loaded Catalog*) satisfied by one rule.
- **`takenSlugs: const {}` in the replace branch is deliberate.** `draftToCaseJson` internally calls `uniqueCaseSlug(caseSlug(title), takenSlugs)`; passing the populated set there would suffix the slug we are intentionally claiming.
- **A catalog entry without a `String` slug is preserved but never matched.** Such an entry cannot exist in a catalog the app loaded — `TrueCrimeCase.fromJson` does `json['slug'] as String` and would have thrown — so this is defensive only and needs no diagnostic surface.

### 5.4 Which slugs count as taken (D8)

`ExportCaseButton` (`export_case_button.dart:41-47`) includes *other drafts'* prospective slugs in its taken set. The batch path deliberately does not: a slug is taken when it is published, not when someone is drafting it. Reserving identities for unpublished drafts would produce `-2` suffixes for cases that may never be published, permanently disfiguring a public URL.

The cost of that choice is real and is handled in the UI, not hidden: drafts *A* and *B* that both slugify to `el-caso`, published in two separate batches, make the second batch a **replace** of the first. The maintainer sees `Sustituye al caso publicado «A»` on that row before confirming (§7.3). That is precisely why the replaced entry's **title** is surfaced rather than a bare "replaces an existing case" flag.

### 5.5 Encoding rules

`encodeMergedCatalog` is `const JsonEncoder.withIndent('  ').convert(result.cases)`, identical to `encodeDraftAsCaseJson` (`case_exporter.dart:186-188`), plus a single trailing newline so the produced file is a well-formed POSIX text file and the final line does not show as changed in a diff. Apply MUST verify the current asset's trailing byte and match it; the characterization test in §11 pins whichever it is.

---

## 6. Post-batch draft state — Open Question 1 answered (D9–D11)

**Decision: a persisted marker on `CaseDraft`, read together with the loaded catalog to produce four states.**

### 6.1 Why neither pure alternative works

| Candidate | Verdict |
| --- | --- |
| Derived slug match against the loaded catalog, nothing persisted | **Insufficient alone.** The loaded catalog cannot contain a case that was handed off thirty seconds ago and not yet committed, so the list would still read `Listo · sin publicar` right after a batch — failing the proposal's success criterion "After a batch, the intake draft list distinguishes included drafts from still-unpublished ones". |
| Persisted marker alone | **Insufficient alone.** It records "a file was produced", which is not "the case is live". A maintainer who never commits would see `Publicado` forever — the proposal's "Mistaken 'it is published' belief" risk, promoted into the data model. |
| Separate batch record (a persisted list of batches) | **Rejected.** A second persisted entity with its own schema, its own migration story and its own way of drifting from the drafts it points at, to answer a question a per-draft field answers directly. |

Neither signal is the truth on its own, so the design keeps both and lets them mean different things.

### 6.2 The marker

Two additive fields on `CaseDraft`:

```dart
/// Slug con el que este borrador salió en el último lote entregado.
/// `null` = nunca ha entrado en un lote. Es el slug REALMENTE asignado,
/// que puede llevar sufijo y no coincidir con `caseSlug(title)`.
final String? handoffSlug;

/// Cuándo se entregó ese lote. Tolerante: una fecha ilegible decodifica a
/// `null` y el borrador sigue abriéndose.
final DateTime? handoffAt;
```

Storing the **assigned** slug rather than re-deriving `caseSlug(title)` is what makes the later catalog match exact for a draft that received a `-2` suffix.

Codec, following `case_draft.dart`'s existing additive contract to the letter:

| Direction | Behaviour |
| --- | --- |
| `fromJson` | `handoffSlug: json['handoffSlug'] as String?`; `handoffAt:` guarded `is String` then `DateTime.tryParse`, so garbage degrades to `null` instead of throwing — the same tolerance `DraftTimelineEvent.fromJson` applies to `kind` (`case_draft.dart:247-248`). |
| `toJson` | Both emitted only when non-null, so a draft that never entered a batch is byte-for-byte what it is today. |
| Pre-change drafts | Missing members decode to `null` → state falls back to exactly today's behaviour. No migration, no schema bump; `SharedPreferencesCaseDraftsStore` keeps `schemaVersion: 1`. |
| Code revert | `CaseDraft.fromJson` reads named keys only, so a stored `handoffSlug` an older build does not know is ignored, not fatal. The marker is dropped on that build's next save — the degradation the proposal's Rollback step 5 already anticipates. |

### 6.3 The single writer (D10)

```dart
/// Deja constancia de que este borrador salió en un lote, con la identidad
/// que se le asignó. A diferencia de `copyWith`, construye el borrador
/// entero: el marcador no es un campo más del formulario.
CaseDraft markHandedOff({required String slug, required DateTime at});
```

Full-constructor shape, matching `withResolvedPlace` (`case_draft.dart:123-145`) and the project rule "`copyWith` does not clear fields; use explicit methods".

**`copyWith` and `withResolvedPlace` MUST pass the two fields through unchanged, without adding them as parameters.** Both build a fresh `CaseDraft` field by field; a field the constructor call omits is erased. Because the intake form autosaves through `editDraft(… current.copyWith(…))` on every keystroke, omitting the pass-through would wipe the marker on the first character typed after a batch. §11 makes this a named RED test rather than a code-review hope.

Application-layer writer, batched:

```dart
// CaseDraftsNotifier
/// Marca de una vez todos los borradores que acaban de salir en un lote.
/// Una sola publicación de estado y una sola escritura en la cola de
/// `_persist`, en vez de N ediciones sueltas.
Future<void> markHandedOff(Map<String, String> slugByDraftId, {DateTime? now});
```

It takes a plain `Map<String, String>` rather than `List<CatalogMergeEntry>` so the notifier does not depend on the exporter's types and stays trivially testable.

### 6.4 The four states (D11)

New file `lib/features/cases/application/draft_publication_state.dart`:

```dart
enum DraftPublicationState { incomplete, ready, handedOff, published }

/// Estado de publicación de un borrador, combinando su validación, el
/// marcador de entrega y el catálogo que esta pestaña cargó.
DraftPublicationState draftPublicationState(
  CaseDraft draft, {
  required Set<String> publishedSlugs,
});
```

| Condition | State | Subtitle in `_DraftList` |
| --- | --- | --- |
| `!validateDraft(draft).isValid` | `incomplete` | `Incompleto` *(unchanged)* |
| valid, effective slug ∈ `publishedSlugs` | `published` | `Publicado` |
| valid, not published, `handoffSlug != null` | `handedOff` | `Entregado el 12/09 · pendiente de publicar` |
| valid, not published, no marker | `ready` | `Listo · sin publicar` *(unchanged)* |

Effective slug is `draft.handoffSlug ?? caseSlug(draft.title.trim())`, and a blank title matches nothing. Deriving it from the title when there is no marker is deliberate: a brand-new draft whose title collides with a published case is shown as `Publicado`, which is the earliest possible warning that publishing it will replace something.

Spanish labels live in presentation, not in the enum — the same split the chapters design fixed (`Technical identity stays in the domain… Spanish headings are supplied later by a presentation extension`). The enum is technical; `intake_workspace_screen.dart` maps it to copy.

**Editing a draft after a handoff does not clear the marker.** The marker answers "did this draft already go out in a batch?", which stays true regardless of later edits, and the form autosaves per keystroke — a marker that cleared on edit would flicker constantly and would be gone exactly when a maintainer re-edits before re-publishing. Detecting "edited since handoff" would need a stored content hash; that is a follow-up, not this change.

---

## 7. Merge base provenance and the stale session — Open Question 2 answered (D12, D13, D16)

**The failure to prevent:** a tab holds the catalog from the bundle it loaded. Produce batch #1, deploy it, then produce batch #2 from the same tab, and batch #2's merge base still lacks batch #1's cases — so the produced file silently drops them, and the site loses published cases with no error anywhere.

### 7.1 The signal is derived, and it survives a restart (D12)

```dart
/// Borradores ya entregados en un lote cuyo caso todavía no aparece en el
/// catálogo que esta pestaña cargó.
final pendingHandoffDraftsProvider = Provider<List<CaseDraft>>(…);
```

A draft in state `handedOff` (§6.4) **is** the stale-base evidence. A session counter ("batches produced since page load") was considered and rejected: it resets when the browser restarts, and the dangerous sequence — hand off today, reopen tomorrow without deploying, hand off again — is exactly the one it would miss. The persisted marker does not reset.

The same signal reads correctly in both underlying situations, which is why one signal is enough:

| Situation | What the maintainer is told | Why it is right |
| --- | --- | --- |
| Batch #1 produced, never committed | "These are not in the catalog you loaded" | True. They are still unpublished; including them again is correct. |
| Batch #1 committed and deployed, tab not reloaded | "These are not in the catalog you loaded" | Also true — of *this tab's* catalog. The reload instruction resolves it, and after reloading they read `Publicado`. |

### 7.2 What the confirmation step shows

```text
┌─ Preparar publicación ───────────────────────────────────────────┐
│ Catálogo cargado en esta pestaña: 16 casos.                      │
│                                                                  │
│ ⚠ Hay 3 borradores que ya entregaste en un lote anterior y       │
│   todavía no están en este catálogo. Si ya los publicaste,       │
│   recarga la página antes de generar otro lote: si no, este      │
│   fichero los dejará fuera.                                      │
│   ☐ Entiendo que este lote parte del catálogo que ya tenía       │
│     cargado                                                      │
│                                                                  │
│ ☑ Zodiac                          Sustituye al caso publicado    │
│                                   «Zodiac» · se perderán:        │
│                                   etiqueta de estado, destacado  │
│ ☑ El caso del faro                Nuevo · el-caso-del-faro       │
│ ☐ Caso sin ubicación   La latitud es obligatoria     (deshabilitado) │
│                                                                  │
│ 2 casos seleccionados · el fichero tendrá 17 casos               │
│                        [ Cancelar ]  [ Generar cases.json ]      │
└──────────────────────────────────────────────────────────────────┘
```

- **Merge-base size and provenance** are stated as a fact, not a number floating in a corner: *"Catálogo cargado en esta pestaña: N casos"*.
- **The resulting size** (`el fichero tendrá 17 casos`) lets the maintainer sanity-check the merge arithmetic before saving. A produced file smaller than the loaded catalog is the visible symptom of the disaster this section prevents.
- Drafts in state `handedOff` are **listed first** in the selector, marked `Entregado · pendiente`, because leaving one out of this batch drops it from the produced file. They are **not** pre-selected — the spec forbids treating the selector's opening as a selection.

### 7.3 Replace flagging (the proposal's explicit sdd-design assignment)

Every selected draft whose outcome is `replaced` renders, on its own row and before confirm:

1. `Sustituye al caso publicado «{replacedTitle}»` — the title, not a generic flag, because the collision may be with a case the maintainer published from a *different* draft (§5.4).
2. `se perderán: {droppedKeys}` when non-empty, mapped to Spanish through a small presentation table (`statusLabel → etiqueta de estado`, `featuredRank → destacado`, `relevanceRank → relevancia`, `victim → víctima`, `timeline → cronología`, `photos → fotografías`, `chapters → capítulos`) with the raw key as fallback for anything unmapped.

`droppedKeys` is not decoration. Replacing `zodiac` (`cases.json:3-53`) with a draft that has no `featuredRank` removes `"featuredRank": 2`, which drops that case out of the home "EN EL FOCO" slot served by `featuredCaseProvider`, and removes `"statusLabel": "Sin resolver"`, after which `case_dossier_content.dart:295` falls back to the enum label. Those are visible, silent regressions that no draft field can express — so the merge reports them and the maintainer decides.

### 7.4 The acknowledgement gate (D13)

When `pendingHandoffDrafts` is non-empty, **confirm is disabled until the acknowledgement checkbox is ticked**. When it is empty, the warning and the checkbox are absent entirely and confirm behaves normally. Proportionate: the friction appears only in the state where published cases can disappear.

### 7.5 No in-app reload (D16)

A "recargar la página" button would need `window.location.reload()`. The archived routing design rejects `dart:html` outright ("web-only, bypasses Flutter route lifecycle, creates manual listener ownership and second truth source"), and `test/app_navigation_boundary_test.dart` enforces the absence of that import structurally. The copy instructs the reload instead.

---

## 8. Selector composition and placement

### 8.1 Widgets

| File | Class | Role |
| --- | --- | --- |
| `presentation/intake/publish_batch_button.dart` | `PublishBatchButton extends ConsumerWidget` | The trigger. `compact` flag, `Key('intake-publish-batch-button')`, same tooltip in both forms — the idiom `ExportCaseButton` documents at `export_case_button.dart:20-25`. Opens the dialog via `showDialog`. |
| `presentation/intake/publish_batch_dialog.dart` | `PublishBatchDialog extends ConsumerStatefulWidget` | The selector, the merge preview, the warnings, and the confirm action. |

Two files, not one. `drafts_backup_button.dart` keeps its `_RestoreDialog` private in the same library, but that dialog is 60 lines; this one carries the selection list, the merge preview and the staleness gate. A **public** dialog class can be pumped directly in its own focused widget test without building the whole workspace — and Dart privacy is library-scoped, so splitting it later (the archived design's §9.2 lesson) would break every reference at once.

Dialog state is local `State`, not Riverpod:

```dart
final Set<String> _selectedDraftIds = {};   // draftId
bool _acknowledgedStaleBase = false;
```

It must die with the dialog. A provider would keep a stale selection alive after the dialog closes and silently reopen with it — the same reasoning that keeps `_RestoreDialog`'s `TextEditingController` local. Riverpod owns the *data* (drafts, catalog payload, transfer, published slugs); the dialog owns its ephemeral choice.

**One computation, no drift (D6).** `build` derives `merge = mergeDraftsIntoCatalog(catalog: decoded, drafts: selectedDrafts)` and renders the preview from it; confirm encodes *that same result*. The preview cannot describe a file different from the one that is saved.

### 8.2 Placement — and where it deviates from the spec

The spec requires the action "alongside the existing `ExportCaseButton` and `DraftsBackupButton` controls in `IntakeWorkspaceScreen`". **Wide layout complies literally.** Compact does not, for an arithmetic reason:

The compact top bar (`intake_workspace_screen.dart:136-165`) already holds six `IconButton`s — back, draft-list toggle, preview toggle, backup, export, new draft — plus a `Flexible` title, inside a `Container` with `EdgeInsets.symmetric(horizontal: 16)`. Under the default `MaterialTapTargetSize.padded`, each is 48 logical pixels:

```
6 × 48 + 32 = 320  → 40 px left for the title at 360 px   (today)
7 × 48 + 32 = 368  → 8 px over the viewport, title at zero width  (with a 7th)
```

The narrow baseline is `Size(360, 780)` (`test/intake_narrow_layout_test.dart:42`), and this repository has already paid for this exact failure once — `Breakpoints.topBarFull` was raised 980 → 1040 because "con el botón nuevo, la barra desbordaba 45px". The project rule forbids dodging it with an oversized test viewport.

**Decision:**

| Layout | Placement |
| --- | --- |
| Wide (≥ `Breakpoints.intakeThreePane`) | Top bar, immediately after `ExportCaseButton` — literal spec compliance. |
| Compact | A header row at the top of `_DraftList`, which in the narrow layout lives inside the draft-list sheet. |

Same `Key('intake-publish-batch-button')` in both; the two layouts are exclusive branches, so only one is ever mounted. The relocation is the same responsive idiom `intake-responsive` already applied to the draft list and the preview themselves, and it puts a list-scoped action where the list is. Cost: two taps in compact. Acceptable for a deliberate, occasional operation — and it leaves the compact top bar composition untouched, so `test/intake_narrow_layout_test.dart` needs no edit.

> **Flagged for `sdd-spec` / `sdd-verify`:** a literal reading of *Eligible Draft Selection Surface* is not satisfied in the compact layout. If the placement requirement is relaxed, the better design is the draft-list header in **both** layouts — one location, one mental model. This design does not adopt that unilaterally because the spec is already written.

### 8.3 Dialog sizing

`ConstrainedBox(maxWidth: 460, maxHeight: viewportHeight * 0.7)` around a scrollable list — **not** the `SizedBox(width: 460)` that `_RestoreDialog` uses (`drafts_backup_button.dart:177`). `AlertDialog`'s default `insetPadding` leaves 280 px of width at a 360 px viewport, so a fixed 460 child overflows by 180. (That makes the existing restore dialog a latent narrow-layout defect; it is out of scope here and is recorded, not fixed.)

Ineligible rows render disabled with the first non-null error from `validateDraft` beside them. Ten-plus drafts scroll; the confirm row stays pinned outside the scroll area so it is reachable without scrolling to the bottom.

### 8.4 Confirm handler

Control flow copied from `drafts_backup_button.dart:68-84`, with the messenger captured before the first `await`:

```
1. merge already computed in build          → no recomputation
2. if selection is empty → confirm is disabled; no file, no dialog  [spec: Empty Selection Yields No File]
3. saved := await transfer.save(fileName: 'cases.json', contents: encodeMergedCatalog(merge))
4. if (!saved) return;                       → cancelling marks nothing  [D14]
5. await notifier.markHandedOff({ for e in merge.entries: e.draftId: e.slug })
6. pop the dialog, then SnackBar:
   «cases.json generado. Sustituye assets/data/cases.json con ese fichero,
    haz commit y push. Hasta entonces, nada cambia en la web.»
```

Step 6's copy names all three remaining manual steps and never claims publication — the spec's *Confirmation Copy States Remaining Manual Steps*, and the mitigation for the "Mistaken 'it is published' belief" risk.

---

## 9. Riverpod state map

| Provider | Kind | Status | Purpose |
| --- | --- | --- | --- |
| `publishedCatalogPayloadProvider` | `FutureProvider<String>` | **New** (`application/cases_providers.dart`) | Raw catalog payload. Overridden in tests with `overrideWith`; that override *is* the seam, so no abstract port is introduced. |
| `publishedSlugsProvider` | `Provider<Set<String>>` | **New** (`application/cases_providers.dart`) | Slug set derived from `casesProvider`, for `draftPublicationState`. |
| `pendingHandoffDraftsProvider` | `Provider<List<CaseDraft>>` | **New** (`application/case_draft_providers.dart`) | Drafts in state `handedOff`; drives the staleness warning (§7.1). |
| `casesProvider` | `FutureProvider<List<TrueCrimeCase>>` | Reused, unchanged | Typed catalog for the rest of the app and for `publishedSlugsProvider`. |
| `caseDraftsProvider` | `AsyncNotifierProvider` | Reused, **one method added** | `markHandedOff(Map<String,String>, {DateTime? now})`. |
| `draftsFileTransferProvider` | `Provider<DraftsFileTransfer>` | Reused, unchanged | Save-as delivery. |
| `editingDraftIdProvider`, `intakeDraftListOpenProvider` | `StateProvider` | Reused, unchanged | Untouched by this change. |

`PublishedCatalogSource` lives in `data/published_catalog_source.dart` with the same constructor shape as `LocalCasesRepository` (`AssetBundle? bundle`, `String assetPath = 'assets/data/cases.json'`), keeping `rootBundle` out of the application layer.

No provider is added for the dialog's selection (§8.1), and no session-scoped provider is added for staleness (§7.1).

---

## 10. File change plan

| Path | Action | Description |
| --- | --- | --- |
| `lib/features/cases/application/case_exporter.dart` | Modify | Add `CatalogMergeOutcome`, `CatalogMergeEntry`, `CatalogMergeResult`, `decodeCatalogPayload`, `mergeDraftsIntoCatalog`, `encodeMergedCatalog`. `caseSlug` / `uniqueCaseSlug` / `draftToCaseJson` / `encodeDraftAsCaseJson` unchanged. Also correct the stale comment at `:166-167` claiming photos are not rendered — `case_dossier_content.dart:160-164` renders them. |
| `lib/features/cases/data/published_catalog_source.dart` | Create | Raw payload read of the catalog asset, injectable bundle. |
| `lib/features/cases/application/cases_providers.dart` | Modify | Add `publishedCatalogPayloadProvider` and `publishedSlugsProvider`. Nothing existing is rewired. |
| `lib/features/cases/domain/case_draft.dart` | Modify | Add `handoffSlug` / `handoffAt` + codec; add `markHandedOff`; **pass both through `copyWith` and `withResolvedPlace`**. |
| `lib/features/cases/application/draft_publication_state.dart` | Create | `DraftPublicationState` enum + pure derivation function. |
| `lib/features/cases/application/case_draft_providers.dart` | Modify | `CaseDraftsNotifier.markHandedOff(...)`; `pendingHandoffDraftsProvider`. |
| `lib/features/cases/presentation/intake/publish_batch_button.dart` | Create | Trigger, compact + wide forms. |
| `lib/features/cases/presentation/intake/publish_batch_dialog.dart` | Create | Selector, merge preview, staleness gate, confirm. |
| `lib/features/cases/presentation/intake/intake_workspace_screen.dart` | Modify | Host the wide trigger in `_WorkspaceTopBar`; add the `_DraftList` header for the compact trigger; replace the `:223` subtitle with the four-state mapping + Spanish labels. |
| `lib/features/cases/data/local_cases_repository.dart`, `data/cases_repository.dart` | **Unchanged** | No write path, no new interface member (§4.4). |
| `lib/features/cases/presentation/intake/export_case_button.dart` | **Unchanged** | Non-goal. Its inline taken-slug computation is not refactored to `publishedSlugsProvider` in this change; recorded as a deferred cleanup. |
| `assets/data/cases.json` | Unchanged by the app | Replaced only by a human. |
| `test/catalog_merge_test.dart` | Create | Merge behaviour + real-asset characterization. |
| `test/case_draft_handoff_test.dart` | Create | Marker codec, tolerance, pass-through. |
| `test/draft_publication_state_test.dart` | Create | Four-state derivation. |
| `test/publish_batch_dialog_test.dart` | Create | Selector, warnings, confirm, persistence, cancel. |
| `test/publish_batch_button_test.dart` | Create | Trigger reachable at 360×780 and in the wide layout, no overflow. |
| `test/case_exporter_test.dart` | Extend | Batch slug cases live here, beside the single-case slug guards, per the proposal's anti-drift mandate. |

---

## 11. Strict-TDD test strategy

`tdd: true`. Every behaviour below records an observed RED attributed to the reported failing line, then GREEN. Characterization tests that are green from the start are labelled as such and are **not** TDD evidence.

### 11.1 RED evidence units

| # | Focused test | Required initial RED |
| --- | --- | --- |
| 1 | `test/catalog_merge_test.dart` — non-colliding merge | `mergeDraftsIntoCatalog` does not exist; a selected draft is not appended and existing entries are not preserved. |
| 2 | `test/catalog_merge_test.dart` — batch-wide slugs | Two drafts both titled to base `el-caso` do not receive `el-caso` / `el-caso-2`. |
| 3 | `test/catalog_merge_test.dart` — collision replaces in place | A draft colliding with a published slug does not replace that entry, or does not keep its array index, or emits two entries with that slug. |
| 4 | `test/catalog_merge_test.dart` — double collision | Two batch drafts colliding with the same published slug: the second overwrites the first instead of becoming `-2`. |
| 5 | `test/catalog_merge_test.dart` — `entries` reporting | `outcome`, `replacedTitle` and `droppedKeys` (expect `statusLabel` and `featuredRank` when replacing a zodiac-shaped entry with a draft that has neither) are absent. |
| 6 | `test/catalog_merge_test.dart` — round trip | `LocalCasesRepository.parseCasesJson(encodeMergedCatalog(result))` does not decode every entry, or the drafted case loses chapters / photos / timeline / ranks / sources. |
| 7 | `test/catalog_merge_test.dart` — encoding | Output is not two-space indented, or escapes accents. |
| 8 | `test/catalog_merge_test.dart` — unreadable payload | `decodeCatalogPayload` returns `[]` (or the merge proceeds) for a malformed payload instead of throwing. **This is the D3 guard.** |
| 9 | `test/case_draft_handoff_test.dart` — codec | Marker does not survive `toJson`/`fromJson`; a missing member does not decode to `null`; a garbage `handoffAt` throws. |
| 10 | `test/case_draft_handoff_test.dart` — **pass-through** | After `markHandedOff`, a subsequent `copyWith(title: …)` (and `withResolvedPlace`) erases the marker. **This is the D10 guard and the highest-value single test in the change.** |
| 11 | `test/draft_publication_state_test.dart` | The four states are not distinguished; a marker-less pre-change draft does not behave as today; `handoffSlug` does not win over the title-derived slug for a suffixed case. |
| 12 | `test/publish_batch_dialog_test.dart` — selection surface | Ineligible drafts are omitted rather than listed disabled with their reason; select-all touches ineligible drafts. |
| 13 | `test/publish_batch_dialog_test.dart` — empty selection | Confirming with nothing selected still calls `save`. |
| 14 | `test/publish_batch_dialog_test.dart` — delivery | `save` is not called with the merged contents and `fileName: 'cases.json'`; or the confirmation copy does not name replace-the-asset / commit / push. |
| 15 | `test/publish_batch_dialog_test.dart` — replace flagged before confirm | The replaced case's title and the dropped keys are not visible before the confirm action. |
| 16 | `test/publish_batch_dialog_test.dart` — staleness gate | With a `handedOff` draft present, confirm is enabled without the acknowledgement; and the merge-base size is not shown. |
| 17 | `test/publish_batch_dialog_test.dart` — marking | After a successful save, the fake store does not hold the markers; **and** after a cancelled save (`_FakeFileTransfer.cancelSave = true`) the store holds markers it should not. |
| 18 | `test/publish_batch_button_test.dart` | The trigger is missing at 360×780, or the compact layout overflows. |
| 19 | `test/intake_*` draft-list subtitle | A handed-off draft still reads `Listo · sin publicar`. No existing test asserts that string today, so this is new coverage, not an edited expectation. |

### 11.2 Characterization test (green from the start — not TDD evidence)

`test/catalog_merge_test.dart`, following the precedent at `test/local_cases_repository_chapters_test.dart:52`:

```
payload := await File('assets/data/cases.json').readAsString()
result  := mergeDraftsIntoCatalog(catalog: decodeCatalogPayload(payload), drafts: [])
expect(encodeMergedCatalog(result), payload)
```

One assertion proving, against the **real** catalog rather than a fixture, that a batch changes nothing it was not asked to change. It is also a canary: if it fails, the asset is not in the canonical two-space encoding.

> **If it fails, the fix is a one-time normalisation commit landed BEFORE this feature, not a weakened assertion.** Otherwise the first real batch produces a whole-file diff that hides the actual editorial change inside reformatting noise. `assets/data/cases.json` is uncommitted in the working tree right now (proposal `## Dependencies`); reconcile that WIP before running this test for the first time, because it reads the working-tree bytes.

### 11.3 Widget-test rules

- Override `publishedCatalogPayloadProvider` **and** `casesRepositoryProvider` consistently in every widget test that renders the dialog. Overriding one and not the other is the only way the two reads can disagree (§4.3), and a test that does it is asserting against a state production cannot reach.
- Reuse `_FakeStore` and `_FakeFileTransfer` from `test/drafts_backup_button_test.dart:19-79` — including `cancelSave`, which unit 17 needs.
- No `pumpAndSettle` with animated widgets; bounded `await tester.pump(const Duration(milliseconds: 400))`.
- Use `Size(360, 780)` for narrow assertions. Do not raise the viewport to make an overflow disappear.

### 11.4 Layer coverage

| Layer | What is covered | Where |
| --- | --- | --- |
| Pure / domain | Merge, slug identity, encoding, replace semantics, dropped keys, payload failure, marker codec and pass-through, state derivation | Units 1–11 + §11.2 |
| Widget | Selection surface, eligibility, empty selection, delivery through the fake transfer, replace and staleness surfacing, persistence on success and its absence on cancel, narrow reachability | Units 12–19 |
| Real browser (mandatory, not substitutable) | Produce a batch from a running web build; confirm the save-as dialog actually appears; replace `assets/data/cases.json` with the produced file and confirm the app loads it; confirm a merged case renders on the map, in the directory and at `/#/casos/<slug>` | Proposal `## Rollout` step 4 |

The browser step is not optional and widget tests do not substitute for it: `file_picker`'s web save path is a platform plugin that a widget test replaces wholesale with `_FakeFileTransfer`, and this project has shipped defects a green widget suite could not see.

---

## 12. Threat matrix

**N/A — no routing, shell, subprocess, VCS/PR automation, executable-file classification, or process-integration boundary is introduced.** Per boundary:

| Boundary | Status | Reason |
| --- | --- | --- |
| Routing | N/A | No route, parser, delegate or hash behaviour is touched. The dialog is a `showDialog` overlay. |
| Shell / subprocess | N/A | No process is started. Dart-only, plus one existing Flutter plugin call. |
| VCS / PR automation | N/A | Explicit firm non-goal. The app performs no git, no GitHub API call, no network request of any kind for this feature. |
| Executable-file classification | N/A | The produced artefact is declared `application/json` by the existing `FilePickerDraftsFileTransfer.save` (`drafts_file_transfer.dart:34`) and is inert data. |
| Process integration | N/A | Delivery is a browser save-as through an already-shipped dependency; no new plugin, permission or capability. |

The one genuinely destructive path in this change — a merge that drops published cases — is a **data** risk, not a boundary risk, and is handled by D3 (never merge into an empty catalog), D12/D13 (staleness signal and gate) and §11.2 (real-asset characterization).

---

## 13. Rollout and rollback additions

Additions to the proposal's plan, not replacements:

1. **Before unit 1:** reconcile the uncommitted `assets/data/cases.json`, `test/case_photo_test.dart` and `test/draft_editorial_fields_test.dart`. §11.2 reads the working-tree asset.
2. **Before unit 1:** run §11.2's characterization assertion against the reconciled asset. If it fails, land the normalisation commit first (§11.2).
3. Implement in dependency order: merge function → raw payload provider → draft marker and state → dialog and trigger → browser evidence.
4. Rollback of the marker: code revert leaves stored `handoffSlug` / `handoffAt` members in browser storage; `CaseDraft.fromJson` reads named keys only, so an older build ignores them and the draft still loads. The marker is dropped on that build's next save. This is the proposal's Rollback step 5, now backed by the actual decoder shape.
5. Rollback of a bad produced catalog: restore the prior `assets/data/cases.json` from git history. The catalog is versioned; every prior state is recoverable.

**Slicing.** Indicative forecast including tests: merge function ≈ 300–400 changed lines; raw payload provider + characterization ≈ 80–120; draft marker + state + subtitle ≈ 250–350; dialog + trigger + widget tests ≈ 450–600. Aggregate ≈ 1,100–1,500. Against this session's 400-line review policy, the dialog unit must be split further (structure and selection first; merge preview and warnings second; handoff marking third). Note the tension for `sdd-tasks` to resolve: the archived `case-publication-detail` design raised this repository's per-unit ceiling to 1,500 (its D11) with a documented rationale — one developer, no second reviewer. `sdd-tasks` owns the final forecast and the guard lines; this design only sizes the units.

---

## 14. Spec coverage gaps found while designing

`openspec/changes/case-auto-publish/specs/catalog-batch-publication/spec.md` currently has no requirement for three behaviours the proposal puts in scope and this design specifies. `sdd-verify` would have nothing to check them against:

| Behaviour | Proposal source | Design section |
| --- | --- | --- |
| Post-batch published/unpublished distinction in the draft list | Goals; Success Criteria; the `catalog-batch-publication` capability description itself ("a visible published/unpublished distinction in the intake draft list") | §6 |
| Replace-collision surfaced before confirm | Risks — "Re-publishing an already-published slug… `sdd-design` must still specify how the collision is surfaced… so a replace is never silent" | §7.3 |
| Merge-base provenance and stale-session defence | Risks — "Stale merge base… Show the merge base size and its provenance in the confirmation step" | §7.1–7.4 |

Also flagged: §8.2's compact-layout placement does not satisfy a literal reading of *Eligible Draft Selection Surface*.

---

## 15. Rejected alternatives

| Alternative | Why rejected |
| --- | --- |
| Merge base as `List<TrueCrimeCase>` + a new `TrueCrimeCase.toJson` | Lossy in six documented ways and rewrites every entry's key order, breaking the spec's preservation requirement and the reviewable diff (§4.1). |
| Add `getRawCatalog()` to `CasesRepository` | Breaks 11 test fakes; the proposal lists the repository as Unchanged (§4.4). |
| Make `casesProvider` derive from the raw payload provider (one read, two shapes) | Rewires the app's core catalog load — and invalidates those same 11 repository fakes — for a maintenance-only feature. |
| An abstract `PublishedCatalogSource` port with its own `Provider` | `FutureProvider.overrideWith` already is the test seam. An abstract class plus an impl plus a second provider buys nothing. |
| Session counter for staleness | Resets on browser restart, missing the hand-off-today / hand-off-again-tomorrow sequence. The persisted marker does not (§7.1). |
| Pre-select `handedOff` drafts in the selector | The spec forbids treating the selector's opening as a selection. They are surfaced first and labelled instead. |
| Field-preserving merge (carry `statusLabel` etc. forward on replace) | Reinterprets the maintainer's locked "on collision, replace" as something subtler, and makes the produced entry a blend of two sources that no test fixture describes. Reporting `droppedKeys` gives the same protection without hidden semantics (§7.3). |
| Clear the handoff marker when the draft is edited | The form autosaves per keystroke, so the marker would flicker; "edited since handoff" needs a stored content hash, which is a follow-up. |
| Dialog selection in a Riverpod provider | Outlives the dialog and silently reopens with a stale selection. |
| Seventh icon in the compact top bar | Overflows 360 px by 8 px with the title at zero width (§8.2). |
| A "recargar la página" button in the dialog | Requires `dart:html`, which the archived routing design rejects and `test/app_navigation_boundary_test.dart` structurally enforces (§7.5). |
| Dated filename (`cases-2026-09-22.json`) | The maintainer must drop this file over `assets/data/cases.json`; the target name is the point. Dating serves backups, not replacements (D15). |
| A parallel batch slug implementation | Explicitly forbidden by the proposal and the spec; drift between the two export paths is the failure mode. |

---

## 16. Requirement traceability

| Spec requirement (`catalog-batch-publication`) | Design coverage |
| --- | --- |
| Eligible Draft Selection Surface | §8.1, §8.2 *(compact placement flagged in §14)*, §8.3 |
| Explicit Per-Draft Selection | §8.1 (local selection state), §7.2 (no pre-selection) |
| Empty Selection Yields No File | §8.4 step 2 |
| Batch-Wide Sequential Slug Resolution | §5.3, §5.4 |
| Collision Replacement Against Loaded Catalog | §5.3 (`base ∉ batchSlugs`), D5, D7 |
| Round-Trip-Safe Merge Output | §4.2, §11.1 unit 6 |
| Catalog Preservation for Unselected Entries | §4 (raw base), §11.2 (real-asset characterization) |
| File Handoff via Existing Transfer Pattern | §8.4, §5.5, D15 |
| Confirmation Copy States Remaining Manual Steps | §8.4 step 6 |
| `case-editorial-chapters` — Manual Publication Boundary (amended) | §3 (no write path anywhere in the flow), §12 |

---

## 17. Open questions

- [ ] Does `assets/data/cases.json` already round-trip byte-for-byte through the two-space encoder, and does it end with a trailing newline? Decided in principle (§5.5, §11.2: match the asset, and normalise once if it does not); the empirical answer must be taken from the reconciled working tree before unit 1.
- [ ] Should `sdd-spec` add requirements for the three behaviours in §14, and relax the compact-layout placement wording? Orchestrator decision; the design is written to be verifiable either way.

Neither blocks `sdd-tasks`.
