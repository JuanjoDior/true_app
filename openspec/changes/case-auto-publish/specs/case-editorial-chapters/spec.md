# Delta for Case Editorial Chapters

## MODIFIED Requirements

### Requirement: Manual Publication Boundary

Chapter support MUST extend the existing draft-to-catalog JSON export without automating publication, whether that export is the single-case clipboard export (`ExportCaseButton`) or the multi-draft batch file export that merges selected drafts into a complete catalog array (`catalog-batch-publication`). Neither export path MUST directly update the catalog, publish a deployment, or introduce a backend dependency. Both remain a maintainer-triggered handoff — a clipboard copy for a single case, or a browser-saved file for a batch — that still requires an explicit manual step (replacing `assets/data/cases.json`, `git commit`, and push) before any change reaches the published site.

(Previously: scoped only to the single-case clipboard export produced by `ExportCaseButton`; now explicitly covers the multi-draft batch file handoff produced by the batch publication action, alongside the unchanged single-case export.)

#### Scenario: Export preserves deliberate publication control

- GIVEN an editor exports a chapter-bearing draft
- WHEN export completes
- THEN compatible catalog JSON is made available through the existing export workflow
- AND `assets/data/cases.json` remains unchanged until a maintainer updates it
- AND no publication or deployment occurs automatically

#### Scenario: Batch file handoff preserves deliberate publication control

- GIVEN a maintainer selects one or more validated drafts in the batch publication action
- WHEN the maintainer confirms the batch and receives the produced catalog file
- THEN the file is delivered as a browser save-as download, not written into the repository
- AND `assets/data/cases.json` remains unchanged until the maintainer manually replaces it
- AND no publication, deployment, or backend call occurs automatically as part of producing or confirming the batch
