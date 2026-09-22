# Catalog Batch Publication Specification

## Purpose

Let the maintainer select several ready drafts from the intake workspace and receive, in one action, a complete drop-in `assets/data/cases.json` array that merges those drafts into the catalog the app already loaded — replacing the one-case-at-a-time clipboard-then-hand-splice loop with an explicit, reviewable file handoff. This capability does not remove the maintainer's manual `git commit`/push step; it removes the hand-editing of the JSON array.

## Requirements

### Requirement: Eligible Draft Selection Surface

The system MUST provide a batch publication selector, reachable from `IntakeWorkspaceScreen`. On the wide layout, its trigger MUST be placed alongside the existing `ExportCaseButton` and `DraftsBackupButton` controls. On the narrow/compact layout, where the top bar has no room for a seventh control without overflowing the project's narrow baseline, the trigger MUST instead be placed within the draft-list header, using the same key so both layouts remain testable as the same feature. The selector MUST list every draft currently held by the intake workspace, regardless of which layout opened it.

Each listed draft's eligibility MUST be decided by `validateDraft(draft).isValid`. A draft that fails validation MUST still appear in the list — it MUST NOT be silently omitted — and MUST be rendered disabled, with its blocking validation reason visible next to it.

#### Scenario: Selector lists both eligible and ineligible drafts

- GIVEN the intake workspace holds three drafts, two of which pass `validateDraft` and one of which is missing a required field
- WHEN the maintainer opens the batch publication selector
- THEN all three drafts appear in the list
- AND the two valid drafts are shown as selectable
- AND the invalid draft is shown disabled, with its validation error visible

#### Scenario: Ineligible draft cannot be selected

- GIVEN a draft in the selector fails `validateDraft`
- WHEN the maintainer attempts to select that draft
- THEN the draft remains unselected
- AND no selection state change occurs for that draft

#### Scenario: Selector trigger relocates on the narrow layout without losing functionality

- GIVEN the intake workspace is rendered at the project's narrow-layout breakpoint
- WHEN the maintainer looks for the batch publication selector trigger
- THEN it is not present among the top bar's icon buttons
- AND it is present within the draft-list header instead
- AND opening it lists the same eligible/ineligible drafts as the wide-layout trigger would

### Requirement: Explicit Per-Draft Selection

The system MUST require an explicit, per-draft selection action before a draft is included in a batch. The system MUST NOT treat opening the selector as selecting any draft, and MUST NOT publish a draft the maintainer did not explicitly select. There is no implicit "publish everything" behaviour.

A select-all affordance over the eligible subset MAY be offered, but it MUST operate only on eligible drafts and MUST itself be an explicit maintainer action distinct from merely opening the selector.

#### Scenario: Only explicitly selected drafts are merged

- GIVEN the selector lists four eligible drafts
- WHEN the maintainer selects two of them and confirms the batch
- THEN the produced catalog contains exactly those two drafts
- AND the two unselected eligible drafts are absent from the produced catalog

#### Scenario: Select-all affects only the eligible subset

- GIVEN the selector lists two eligible drafts and one ineligible draft
- WHEN the maintainer triggers the select-all affordance
- THEN both eligible drafts become selected
- AND the ineligible draft remains unselected and disabled

### Requirement: Empty Selection Yields No File

Confirming the batch publication action with no draft selected MUST NOT produce or offer a file.

#### Scenario: Confirming with no selection produces nothing

- GIVEN the maintainer has opened the batch publication selector and selected no draft
- WHEN the maintainer confirms the batch action
- THEN no file is produced
- AND no save-as dialog is offered

### Requirement: Batch-Wide Sequential Slug Resolution

The system MUST resolve slug identity for a batch using `caseSlug` and `uniqueCaseSlug` from `case_exporter.dart`, and MUST NOT introduce a second, independent slug-assignment or collision-detection implementation for the batch path.

Slug resolution MUST be sequential across the batch: the slug assigned to a draft earlier in the batch MUST be added to the taken-slugs set considered when resolving the slug for every later draft in the same batch. Two drafts in the same batch whose titles produce the same base slug MUST therefore receive distinct slugs from each other.

#### Scenario: Two similarly titled drafts in one batch get distinct slugs

- GIVEN a batch selection contains two drafts whose titles both produce the base slug `el-caso`
- WHEN the batch is confirmed
- THEN the produced catalog contains two entries with distinct slugs derived from `el-caso`
- AND neither entry overwrites the other

### Requirement: Collision Replacement Against Loaded Catalog

When a selected draft's resolved slug matches the slug of an entry already present in the catalog loaded through `casesProvider` / `LocalCasesRepository` at the time the batch is built, the merge MUST replace that existing catalog entry's content with the selected draft's content. The merge MUST NOT rename the draft's slug to avoid the collision, and MUST NOT emit two catalog entries sharing that slug.

#### Scenario: Selected draft replaces an already-published case with the same slug

- GIVEN the loaded catalog contains a published case with slug `known-case`
- AND a selected draft's title resolves to the same slug `known-case`
- WHEN the batch is confirmed
- THEN the produced catalog contains exactly one entry with slug `known-case`
- AND that entry's content is the selected draft's content, not the previously published content

### Requirement: Round-Trip-Safe Merge Output

The system MUST produce merged catalog output such that every case it contains — preserved existing entries, collision-replaced entries, and newly merged drafts alike — decodes successfully through `TrueCrimeCase.fromJson`, with chapters, photos, timeline, ranks (`featuredRank`, `relevanceRank`), and sources intact.

#### Scenario: Produced catalog round-trips through the published-case decoder

- GIVEN a batch merges two selected drafts, one of which has chapters, photos, a timeline, and both ranks populated, into a loaded catalog of three existing cases
- WHEN the produced catalog file is decoded case-by-case through `TrueCrimeCase.fromJson`
- THEN every one of the five resulting entries decodes without error
- AND the drafted case's chapters, photos, timeline entries, `featuredRank`, and `relevanceRank` are all present on the decoded case

### Requirement: Catalog Preservation for Unselected Entries

Every case present in the catalog loaded at batch time whose slug is not replaced under the Collision Replacement Against Loaded Catalog requirement MUST appear unmodified — with the same content it had in the loaded catalog — in the produced merged catalog.

#### Scenario: Non-colliding existing cases survive the batch unchanged

- GIVEN the loaded catalog contains published cases with slugs `case-a` and `case-b`
- AND a batch selects one draft whose resolved slug is `case-c`, which collides with neither
- WHEN the batch is confirmed
- THEN the produced catalog contains `case-a` and `case-b` with the same content they had in the loaded catalog
- AND `case-c` is additionally present

### Requirement: File Handoff via Existing Transfer Pattern

The system MUST deliver the produced merged catalog to the maintainer through the existing `DraftsFileTransfer` abstraction — the same `draftsFileTransferProvider.save(fileName:, contents:)` pattern already used by `DraftsBackupButton` — rather than adding new file-save plumbing. The delivery mechanism MUST be a browser save-as dialog; the system MUST NOT write to a filesystem path or to the git repository directly.

The merged catalog MUST be encoded using the same human-readable JSON shape the existing single-case exporter produces: two-space indentation and unescaped accented characters, so the resulting file stays reviewable in a diff.

#### Scenario: Confirmed batch is delivered through the file transfer abstraction

- GIVEN a test overrides `draftsFileTransferProvider` with a fake transfer, following the same override pattern `DraftsBackupButton` tests already use
- WHEN the maintainer selects at least one eligible draft and confirms the batch
- THEN the fake transfer's `save` is invoked with the merged catalog contents
- AND the produced text is two-space indented JSON with accented characters left unescaped

### Requirement: Confirmation Copy States Remaining Manual Steps

Confirming a batch with at least one draft selected MUST present copy that explicitly names the remaining manual steps: replacing `assets/data/cases.json` with the produced file, `git commit`, and push. The copy MUST make clear that confirming the batch does not itself publish the selected cases to the live site.

#### Scenario: Confirmation names the remaining manual steps

- GIVEN the maintainer has selected at least one eligible draft in the batch publication selector
- WHEN the maintainer confirms the batch
- THEN the presented confirmation copy states that the maintainer must still replace `assets/data/cases.json`, commit, and push
- AND the copy does not claim that the cases are now published

### Requirement: Post-Batch Draft Publication State Distinction

The system MUST derive each draft's publication state from a pure function combining the draft's validation result, its persisted handoff marker (`handoffSlug` and `handoffAt` on `CaseDraft`), and the set of slugs present in the catalog loaded via `casesProvider` at evaluation time. The derivation MUST yield exactly one of four states, rendered in the intake draft list as: `Incompleto` when the draft fails `validateDraft`; `Publicado` when the draft is valid and its effective slug (`handoffSlug` if non-null, otherwise the title-derived slug) is present in the loaded catalog's slug set; `Entregado · pendiente de publicar` when the draft is valid, its effective slug is absent from the loaded catalog, and `handoffSlug` is non-null; and `Listo · sin publicar` when the draft is valid, its effective slug is absent from the loaded catalog, and no handoff marker is set. A draft persisted before this change decodes with `handoffSlug` and `handoffAt` both null and MUST be indistinguishable, in this derivation, from a draft that has never gone through a batch.

#### Scenario: Never handed-off draft reads as ready

- GIVEN a valid draft that has never been included in a batch
- AND its title-derived slug is absent from the currently loaded catalog
- WHEN the intake draft list renders its state
- THEN the draft's subtitle reads `Listo · sin publicar`

#### Scenario: Handed-off draft not yet in the loaded catalog reads as delivered

- GIVEN a valid draft whose `handoffSlug` is set from a previous batch
- AND that slug is absent from the currently loaded catalog
- WHEN the intake draft list renders its state
- THEN the draft's subtitle reads `Entregado · pendiente de publicar`

#### Scenario: Handed-off draft whose slug now appears in the catalog reads as published

- GIVEN a valid draft whose `handoffSlug` is set from a previous batch
- AND that same slug is present in the currently loaded catalog's slug set
- WHEN the intake draft list renders its state
- THEN the draft's subtitle reads `Publicado`

#### Scenario: Pre-change draft with a null marker behaves exactly as today

- GIVEN a draft decoded from storage predating this change, with `handoffSlug` and `handoffAt` both null
- AND the draft is valid and its title-derived slug is absent from the loaded catalog
- WHEN the intake draft list renders its state
- THEN the draft's subtitle reads `Listo · sin publicar`, identical to a draft that has never been handed off

### Requirement: Collision Replacement Reports Dropped Keys Before Confirm

When a selected draft's resolved slug collides with an existing catalog entry under Collision Replacement Against Loaded Catalog, the merge MUST compute, per affected draft, the set of keys present on the replaced catalog entry that the replacement draft-derived JSON does not contain (`droppedKeys`). The batch publication selector MUST render, on that draft's own row and before the maintainer confirms the batch, both the replaced entry's title and its non-empty `droppedKeys` set. A replace-on-collision merge MUST NOT be silent at field granularity: the maintainer MUST be able to see what content the replacement discards before any file is generated. The rendered preview MUST be derived from the same merge computation that is later encoded into the produced file, so the preview cannot disagree with the saved output.

#### Scenario: Replacing a richer published entry surfaces the fields it would lose

- GIVEN the loaded catalog contains a published case with slug `known-case` carrying a `statusLabel` and a `featuredRank`
- AND a selected draft resolves to the same slug `known-case` and expresses neither `statusLabel` nor `featuredRank`
- WHEN the batch selector renders the preview for that draft, before confirmation
- THEN the draft's row states that it replaces the published case `known-case` by title
- AND the row lists `statusLabel` and `featuredRank` among the keys that will be dropped

#### Scenario: Replacement that drops nothing still names the replaced entry

- GIVEN a selected draft's resolved slug collides with a published entry
- AND the draft-derived JSON contains every key the replaced entry had
- WHEN the batch selector renders the preview for that draft
- THEN the row identifies the replaced entry by title
- AND no dropped-keys list is shown for that row

#### Scenario: The confirmed file matches the previewed dropped-keys computation

- GIVEN the selector has rendered a replacement preview with a non-empty `droppedKeys` set for a draft
- WHEN the maintainer confirms the batch without changing the selection
- THEN the produced catalog entry for that slug is the exact replacement described in the preview
- AND no additional merge computation runs between preview and confirm

### Requirement: Merge-Base Staleness Detection and Confirmation Gate

The system MUST derive a merge-base staleness signal from drafts in state `Entregado · pendiente de publicar` — a draft carrying a non-null `handoffSlug` whose slug is absent from the catalog currently loaded via `casesProvider`. The presence of at least one such draft MUST be treated as evidence that the merge base predates a previously produced batch that has not yet been reloaded into this tab. The confirmation step MUST state the merge base's size and provenance (the number of cases in the catalog loaded in this session) and the resulting produced file's size before the maintainer can confirm. Drafts exhibiting the staleness signal MUST be listed first in the selector and MUST NOT be pre-selected. When the staleness signal is present, the confirm action MUST remain disabled until the maintainer explicitly ticks an acknowledgement checkbox; when the signal is absent, the warning and the checkbox MUST NOT be rendered, and confirm MUST NOT be gated by this requirement.

#### Scenario: Stale merge base blocks confirm until acknowledged

- GIVEN a draft carries a `handoffSlug` whose slug is absent from the currently loaded catalog
- WHEN the maintainer opens the batch publication selector
- THEN a warning is shown stating that this draft was already delivered in a previous batch and is not yet in the loaded catalog
- AND that draft is listed before other drafts in the selector
- AND that draft is not pre-selected
- AND the confirm action is disabled until the maintainer ticks the acknowledgement checkbox

#### Scenario: No stale drafts means no staleness gate

- GIVEN no draft in the intake workspace is in state `Entregado · pendiente de publicar`
- WHEN the maintainer opens the batch publication selector
- THEN no staleness warning or acknowledgement checkbox is rendered
- AND confirm is not gated by this requirement

#### Scenario: Ticking the acknowledgement unblocks confirm

- GIVEN the staleness signal is present and the acknowledgement checkbox is unticked
- AND the maintainer has otherwise selected at least one eligible draft
- WHEN the maintainer ticks the acknowledgement checkbox
- THEN the confirm action becomes enabled

#### Scenario: Confirmation states merge-base and resulting file size regardless of staleness

- GIVEN the maintainer has opened the batch publication selector with a catalog of N loaded cases
- WHEN the confirmation step renders, whether or not the staleness signal is present
- THEN the confirmation step states that the catalog loaded in this tab holds N cases
- AND the confirmation step states how many cases the produced file will contain
