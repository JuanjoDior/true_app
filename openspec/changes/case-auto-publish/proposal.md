# Proposal: Batch Case Publication Handoff

Let the maintainer pick which ready drafts to publish, in one action, and get back a complete, drop-in `assets/data/cases.json` — instead of splicing one exported JSON object into the catalog array by hand, once per case.

The rendering pipeline is already finished: a case that reaches `assets/data/cases.json` renders on the map, in "El archivo" directory, at `/#/casos/<slug>`, in search, and in the featured slot with no further code. This change closes the only remaining gap — the handoff between the intake workspace and the catalog asset. It does **not** remove the maintainer's commit and push; it removes the hand-editing.

## Problem

The maintainer currently has more than ten drafts in the intake workspace, each already showing `Listo · sin publicar`, and none of them are on the public site. Publishing them today means repeating this loop once per case:

1. Select the draft, press **Copiar JSON** (`ExportCaseButton`), which copies **one JSON object** to the clipboard.
2. Open `assets/data/cases.json`, which is a JSON **array**, find an insertion point, paste, and fix the surrounding brackets and commas by hand.
3. Save, `git commit`, push, wait for GitHub Pages.

Three consequences follow:

| Consequence | Evidence |
| --- | --- |
| The work is O(n) manual edits, not one | The exporter emits a single object; the target is an array. Ten drafts means ten splices. |
| Every splice is an opportunity to corrupt the catalog | Comma/bracket placement is hand-managed; a mistake breaks `jsonDecode(...) as List<dynamic>` in `LocalCasesRepository.getCases()` and takes the whole catalog down, not one case. |
| The backlog is invisible to readers | The public site shows only what has survived the loop, so finished editorial work sits in browser storage instead of on the map. |

Nothing about the case *data* is the problem. `draftToCaseJson` already emits exactly the keys `TrueCrimeCase.fromJson` expects — chapters, photos, timeline, victim, tags, `featuredRank`, `relevanceRank` included — and `test/case_exporter_test.dart` guards that round trip. The friction is entirely in the array-splice step.

## Goals

- Let the maintainer publish **several** ready drafts in one action instead of one at a time.
- Let the maintainer **choose** which ready drafts go into a given batch; never publish everything implicitly.
- Produce a complete, valid, drop-in `cases.json` array that merges the selected drafts into the catalog the app already loaded, with no hand-editing of JSON.
- Keep slug identity correct across the batch, reusing the collision logic the single-case export already uses.
- Make it visible, after a batch, which drafts were included, so the next batch does not silently re-include them.
- Preserve the deliberate manual publication boundary: the app still never writes the catalog, never deploys, and never acquires a backend.
- Amend the `Manual Publication Boundary` requirement explicitly rather than contradicting it silently.

## User Outcomes

### Maintainer

The maintainer opens the intake workspace, opens the publish action, sees the list of drafts that pass validation with a checkbox each, ticks the ones judged ready, confirms, and receives a browser save-as dialog for a complete `cases.json`. Drafts that do not validate appear in the list disabled, with the reason shown, so nothing disappears without explanation. The remaining work is: move the downloaded file over `assets/data/cases.json`, `git commit`, push.

### Public reader

The reader sees the accumulated editorial backlog reach the map, the directory, and the case detail routes — through the same catalog asset and the same rendering that already exists. No reader-facing surface changes in this cycle.

## Scope and Capabilities

### Batch selection

- Add an intake action that opens an explicit per-draft selector of publishable drafts, placed alongside the existing `ExportCaseButton` / `DraftsBackupButton` controls in `IntakeWorkspaceScreen`.
- Eligibility is decided by the existing `validateDraft(draft).isValid`. Only eligible drafts can be selected.
- Ineligible drafts MUST still be listed, disabled, with the blocking reason visible. They MUST NOT be silently omitted.
- Selection is explicit and per-draft. There is no implicit "publish everything" behaviour, though a select-all affordance over the eligible set is acceptable.
- Confirming with an empty selection MUST NOT produce a file.

### Catalog merge

- Merge the selected drafts into the published catalog the app already loaded through `casesProvider` / `LocalCasesRepository`, producing one complete array in `assets/data/cases.json` shape.
- Reuse `draftToCaseJson`, `caseSlug`, and `uniqueCaseSlug` from `case_exporter.dart`. Do not reimplement slug or collision logic; a second implementation would drift from the single-case export path.
- Slug identity MUST be resolved across the whole batch, not per draft in isolation: each slug assigned inside the batch joins the taken set for the drafts that follow, so two similar titles in one batch cannot collide.
- Emit the same human-readable encoding the current exporter uses (two-space indent, unescaped accents), so the resulting file stays reviewable in a diff.
- Existing published cases MUST survive the merge unchanged.

### File handoff

- Deliver the merged catalog through the existing `DraftsFileTransfer` / `file_picker` pattern already proven by `DraftsBackupButton`, so a browser save-as dialog is the delivery mechanism.
- The abstraction boundary already exists (`draftsFileTransferProvider` overrides the transfer in tests); reuse it rather than adding new file-save plumbing.
- The confirmation copy MUST state the remaining manual steps (replace the asset, commit, push) so the action is not mistaken for publishing to production.

### Post-batch draft state

- The intake draft list currently derives its subtitle purely from validation: `Text(isValid ? 'Listo · sin publicar' : 'Incompleto')` in `intake_workspace_screen.dart`. There is no persisted notion of publication on `CaseDraft` at all, so a draft that was just included in a batch still reads `sin publicar`.
- This change MUST provide a clear before/after distinction so a maintainer running a second batch can tell which drafts were already handed off.
- The exact mechanism — a persisted per-draft marker, a derived match against the loaded catalog by slug, or a batch record — is a design decision routed to `sdd-design`. It is named here as required scope, not resolved.

### Specification amendment

- `openspec/specs/case-editorial-chapters/spec.md`, requirement **Manual Publication Boundary**, currently reads: *"Exporting a case MUST NOT directly update the catalog, publish a deployment, or introduce a backend dependency."* Its scenario asserts that `assets/data/cases.json` remains unchanged until a maintainer updates it.
- That requirement remains true under this change and MUST stay true — the app writes a download, not the repository. But its wording frames export narrowly as a single-case clipboard operation, so it MUST be amended to describe the batch file handoff explicitly while keeping the prohibition on automatic catalog update, deployment, and backend dependency intact.

## Capabilities

> Contract with the `sdd-spec` phase.

### New Capabilities

- `catalog-batch-publication`: explicit per-draft selection of validated drafts, merge into the loaded published catalog with batch-wide slug identity, complete drop-in `cases.json` file handoff, and a visible published/unpublished distinction in the intake draft list.

### Modified Capabilities

- `case-editorial-chapters`: the `Manual Publication Boundary` requirement is amended to cover a multi-draft, complete-catalog file export alongside the existing single-case clipboard export, while retaining the prohibition on automatic catalog update, automatic deployment, and backend dependencies.

## Approach

Build one application-level merge function and one presentation-level selector, and reuse everything else.

1. **Application layer** — add a catalog-merge entry point next to `draftToCaseJson` in `lib/features/cases/application/` that takes the loaded `List<TrueCrimeCase>` plus the selected `List<CaseDraft>` and returns the encoded full array. Slug accumulation is sequential inside this function so the batch is internally consistent. This is pure, Flutter-free logic and is where the strict-TDD evidence concentrates.
2. **Presentation layer** — a selection dialog opened from the intake workspace, listing drafts with eligibility from `validateDraft`, and a confirm action that calls the merge function and hands the result to `draftsFileTransferProvider.save(...)`.
3. **Draft state** — whichever mechanism design selects for the published/unpublished distinction, it must degrade safely for drafts that predate the change and must not break existing draft decoding, which is additive by contract.

The single-case clipboard export stays exactly as it is. This change adds a path; it does not replace one.

## Alternatives Considered

| Alternative | Verdict |
| --- | --- |
| **A1 — clipboard array fragment.** Extend the existing button to copy an array-shaped fragment instead of a bare object. | Rejected as the committed approach. It removes the comma-placement error class but keeps the file open-paste-save loop and stays one case at a time, which is the actual complaint with ten drafts queued. Retained only as a possible emergency fallback if the file path proves unworkable. |
| **A2 — batch selector + merged file download.** | **Committed.** Reuses two patterns already proven in this codebase and removes hand-editing entirely. |
| **B — commit directly from the browser via the GitHub API.** | Rejected; see Non-Goals. |

## Affected Areas

| Area | Impact | Description |
| --- | --- | --- |
| `lib/features/cases/application/case_exporter.dart` | Modified | Add the catalog-merge entry point; reuse `caseSlug` / `uniqueCaseSlug` / `draftToCaseJson` unchanged. |
| `lib/features/cases/presentation/intake/` (new widget) | New | Batch selection dialog and its trigger action. |
| `lib/features/cases/presentation/intake/intake_workspace_screen.dart` | Modified | Host the new action; the `Listo · sin publicar` subtitle gains a published state. |
| `lib/features/cases/domain/case_draft.dart` | Possibly modified | Only if design selects a persisted publication marker. |
| `lib/features/cases/data/drafts_file_transfer.dart` | Reused | Existing `save(fileName:, contents:)` is sufficient; no new plumbing expected. |
| `lib/features/cases/data/local_cases_repository.dart` | Unchanged | Remains read-only; no write path is introduced. |
| `assets/data/cases.json` | Unchanged by the app | Still updated only by a human replacing the file and committing. |
| `openspec/specs/case-editorial-chapters/spec.md` | Modified | `Manual Publication Boundary` amended (delta spec). |
| `test/case_exporter_test.dart`, `test/drafts_backup_button_test.dart` | Extended | Existing guards for slug collision and the file-transfer flow are the patterns to extend. |

## Success Criteria

- [ ] The maintainer can select a subset of validated drafts and receive one complete `cases.json` containing the existing catalog plus exactly those drafts.
- [ ] Drafts failing `validateDraft` are listed but not selectable, and the blocking reason is visible.
- [ ] The produced file parses through `LocalCasesRepository` and every merged case decodes via `TrueCrimeCase.fromJson` with chapters, photos, timeline, ranks, and sources intact.
- [ ] Two drafts in one batch whose titles produce the same base slug receive distinct slugs, and neither collides with a slug already in the catalog.
- [ ] Every case already present in the loaded catalog is present and unmodified in the produced file.
- [ ] Confirming with no selection produces no file.
- [ ] After a batch, the intake draft list distinguishes included drafts from still-unpublished ones.
- [ ] The app performs no write to `assets/data/cases.json`, no network publication call, and acquires no backend dependency.
- [ ] The amended `Manual Publication Boundary` requirement is satisfied by the shipped behaviour, with no requirement left silently contradicted.
- [ ] Every new behaviour has strict-TDD evidence: the behaviour test observed RED for the expected reason before the implementation made it GREEN.
- [ ] `flutter test` and `flutter analyze` pass.

## Non-Goals

- **Real publication automation (Option B).** Committing to the repository from inside the app — for example calling the GitHub REST API from the browser — is explicitly out of scope. It would require a write-scoped credential embedded in a publicly deployed static bundle, protected only by the compile-time constant `kIntakeSharedKey`, which any visitor can read straight out of the shipped bundle. There is no backend to broker the credential safely. This is a firm non-goal, not an open question; revisiting it requires a separate, explicit security decision and a deliberate supersession of the `Manual Publication Boundary` requirement.
- **Removing the maintainer's move / commit / push steps.** On Flutter Web, `file_picker` triggers a browser save-as dialog; there are no filesystem paths, even under `flutter run -d chrome`. No in-app action can write into the git checkout. Any proposal promising otherwise would overpromise against this architecture.
- **Writing `assets/data/cases.json` from the app**, or adding any write method to `CasesRepository`.
- **Changing the single-case clipboard export.** `ExportCaseButton` keeps its current behaviour.
- **Editing or unpublishing already-published cases from intake.** Reverting a published case remains a `git revert` of the catalog commit.
- **Changing directory ordering or rank semantics.** `published-case-directory` deliberately excludes `featuredRank` / `relevanceRank` from directory ordering; that stays.
- **Changing the intake gate, the passphrase, or authentication.**
- **Schema changes to the published case model**, migrations, or reader-facing UI work.
- **Renaming the change key.** `case-auto-publish` overstates the delivered scope — the accurate name is a catalog handoff — but the key is retained for artifact continuity.

## Dependencies

- `openspec/specs/case-editorial-chapters/spec.md` → `Manual Publication Boundary` must be amended by this change's delta spec. Apply work must not land behaviour that contradicts the unamended text.
- `file_picker: ^12.0.0` is already a dependency; no new package is expected.
- `casesProvider` / `LocalCasesRepository` must be reachable from the intake workspace as the merge base. `ExportCaseButton` already watches `casesProvider` for taken slugs, so the wiring precedent exists.
- Working-tree state: `assets/data/cases.json`, `test/case_photo_test.dart`, and `test/draft_editorial_fields_test.dart` were uncommitted at exploration time. Reconcile that WIP before apply so this change does not stomp an in-progress manual paste.
- Project conventions apply: strict TDD (`tdd: true`), `flutter test`, `flutter analyze`, Spanish UI copy and commit messages, English specs.

## Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
| --- | --- | --- | --- |
| **Stale merge base.** The browser session holds the catalog from the bundle it loaded. If a second batch is produced before reloading after the first batch is deployed — or while a service worker still serves the old bundle — the merge base is stale and the produced file silently drops the previously published cases. | Medium | High: published cases disappear from the site with no error. | Show the merge base size and its provenance in the confirmation step; state the reload-after-deploy requirement in the copy; have design consider detecting drafts whose slug is already in the loaded catalog. Call this out explicitly in `sdd-design`. |
| **Corrupted catalog from a bad merge.** A malformed produced array breaks `jsonDecode(...) as List<dynamic>` and takes down the whole catalog, not one case. | Low | High | Cover the merge function with domain-level tests that decode the produced array back through `TrueCrimeCase.fromJson`, mirroring the existing round-trip test. Review the diff before committing. |
| **Slug logic drift.** A separate batch implementation of slug/collision handling diverges from the single-case path. | Medium | Medium | Mandated reuse of `caseSlug` / `uniqueCaseSlug`; add batch cases to `test/case_exporter_test.dart` rather than a parallel suite. |
| **Silent contradiction of `Manual Publication Boundary`.** Shipping batch export without amending the requirement leaves a current, merged requirement contradicted by shipped behaviour. | Medium | Medium | Delta spec is required scope; `sdd-verify` should treat an unamended requirement as a blocker. |
| **Re-publishing an already-published slug.** Resolved: the merge replaces the existing catalog entry with the selected draft's content. | Low today (no drafts are published yet) | Medium | Decided directly with the maintainer: on collision, replace. `sdd-design` must still specify how the collision is surfaced in the selector/confirm step so a replace is never silent — the maintainer should see which selected drafts will overwrite an existing published case before confirming. |
| **Selector unusable at ten-plus drafts or on narrow layouts.** | Medium | Low | Behaviour-focused widget tests at the project's existing breakpoints; per project convention, do not force oversized viewports to dodge overflow. |
| **Mistaken "it is published" belief.** A download is not a deployment; a maintainer who stops after the save dialog sees nothing change on the site. | Medium | Low | Confirmation copy names the remaining steps explicitly. |

## Rollout and Rollback

### Rollout

1. Complete planning artifacts (`sdd-spec`, `sdd-design`, `sdd-tasks`).
2. Implement with strict TDD, recording observed RED before GREEN for each behaviour, attributed to the reported failing line.
3. Validate with `flutter test` and `flutter analyze`.
4. Exercise the real browser path once: produce a batch file from a running web build, confirm the save dialog, and confirm the produced file loads through the app after replacing the asset. Widget tests alone are not accepted as proof of the `file_picker` web behaviour — this project has shipped defects a green widget suite could not see.
5. Deliver by direct commit to `main` per project convention; GitHub Pages deploys.
6. Publish the first real batch of drafts through the new action as the acceptance exercise, reviewing the `assets/data/cases.json` diff before committing it.

### Rollback

Delivery is direct commit to `main`, so rollback must be explicit and fast:

1. Revert the commit(s) introducing the batch action. The single-case clipboard export is untouched, so the previous publication path is immediately available again.
2. If a produced catalog file caused the incident, restore the previous known-good `assets/data/cases.json` from git history — the catalog is versioned, so every prior state is recoverable.
3. Push the revert so GitHub Pages redeploys the previous behaviour.
4. Confirm the Situation Room root, the directory, and a previously valid `/#/casos/<slug>` URL behave as expected after redeployment.
5. If design selected a persisted publication marker on `CaseDraft`, confirm that reverting the code still leaves existing local drafts decodable; draft decoding is additive by contract, and unknown members must not break a load.

Rollback does not modify local draft data. Drafts live in browser storage and are unaffected by a code revert.

## Open Questions for `sdd-design`

1. What mechanism marks a draft as handed off — a persisted field on `CaseDraft`, a derived slug match against the loaded catalog, or a batch record — and how does it degrade for drafts created before this change?
2. How is the merge base surfaced in the confirmation step so a stale-session batch is visible before the file is produced rather than after it is deployed?

## Resolved Decisions

- **Slug collision (was Open Question 2):** decided directly with the maintainer — when a selected draft's slug already exists in the loaded catalog, the merge **replaces** the existing entry with the draft's content. `sdd-design` still owns *how* this is surfaced to the maintainer before confirming (see the "Re-publishing an already-published slug" risk row), but the replace-vs-suffix choice itself is closed.
