# Case Editorial Chapters Specification

## Purpose

Define a backward-compatible editorial chapter model that travels consistently from local draft authoring through preview, manual JSON publication, catalog decoding, and public dossier presentation.

## Requirements

### Requirement: Fixed Optional Chapter Set

The system MUST support exactly four optional editorial chapter types: Background, Events, Investigation, and Current status. A case MUST contain no more than one chapter of each type, and meaningful chapters MUST appear in that fixed editorial order regardless of the order in which they were authored or decoded.

Intake authoring MUST allow an editor to create, edit, and clear content for those four types. It MUST NOT allow arbitrary chapter types or user-defined chapter ordering.

#### Scenario: Author uses the supported chapter set

- GIVEN an editor is authoring a case
- WHEN the editor reviews the available editorial chapters
- THEN Background, Events, Investigation, and Current status are available
- AND no action is available to create an additional chapter type
- AND the editor cannot reorder the four chapter types

#### Scenario: Partially populated chapters retain editorial order

- GIVEN an editor enters meaningful content for Current status and Background in that sequence
- WHEN the case is previewed, exported, or decoded for publication
- THEN Background appears before Current status
- AND absent chapter types do not create empty sections

### Requirement: Meaningful Chapter Content

A chapter MUST be considered meaningful only when its textual content contains at least one non-whitespace character. Preview, export, and public dossier presentation MUST omit non-meaningful chapters.

Exported case JSON MUST contain only meaningful chapters in the fixed editorial order. When no chapter is meaningful, the exporter MUST omit the `chapters` member entirely.

#### Scenario: Export contains only meaningful chapters

- GIVEN a draft has meaningful Background content, whitespace-only Events content, and no content for the remaining chapters
- WHEN the draft is previewed and exported
- THEN the preview shows Background exactly once
- AND the exported chapter collection contains Background only
- AND no empty Events, Investigation, or Current status chapter is emitted

#### Scenario: Export omits an empty chapter collection

- GIVEN a draft has no meaningful chapter content
- WHEN the draft is exported
- THEN the exported case JSON does not contain a `chapters` member

### Requirement: Draft Persistence and Live Preview

The system MUST persist meaningful chapter type and content through local draft save and load operations. Draft decoding MUST treat an absent `chapters` member as an empty chapter collection.

The intake preview MUST reflect the current meaningful chapter content and fixed order through the shared dossier presentation.

#### Scenario: Chapters survive draft save and load

- GIVEN a draft contains meaningful content in all four supported chapters
- WHEN the draft is saved locally and loaded again
- THEN every chapter type and its authored content are preserved
- AND the chapters are available in the fixed editorial order

#### Scenario: Legacy draft remains readable

- GIVEN locally persisted draft JSON predates editorial chapters and has no `chapters` member
- WHEN the draft is loaded
- THEN the draft loads successfully
- AND its chapter collection is empty
- AND all existing draft fields remain available

#### Scenario: Chapter editing updates preview

- GIVEN an editor has an active draft and visible intake preview
- WHEN the editor adds, edits, or clears chapter content
- THEN the preview reflects the current meaningful content
- AND cleared or whitespace-only chapters are not displayed

### Requirement: Publication Round Trip

Chapter-bearing draft data MUST survive the complete supported publication round trip: draft authoring, local persistence, intake preview, JSON export, published-case decoding, and public read-back. Supported chapter types, content, and fixed order MUST NOT be lost or changed during that round trip.

#### Scenario: All chapters complete the publication round trip

- GIVEN an editor authors meaningful content for all four supported chapters
- WHEN the draft is saved, loaded, previewed, exported, and decoded as a published case
- THEN the decoded published case contains the same four chapter types and authored content
- AND their order is Background, Events, Investigation, and Current status
- AND the data is available to the public dossier presentation

### Requirement: Additive Published-Case Decoding

Published-case decoding MUST treat an absent `chapters` member as an empty chapter collection. Existing published cases without chapter data MUST remain valid without catalog migration.

Optional malformed chapter entries MUST be ignored individually when the case's required core fields remain valid. An entry is malformed when it is structurally invalid, has a non-textual content value, uses an unsupported chapter type, has content that is not meaningful under the meaningfulness rule above, or repeats a chapter type already **accepted** from an earlier entry. Valid chapter entries and valid core case fields MUST continue to load.

An ignored entry MUST NOT consume its type slot: a whitespace-only or otherwise malformed entry earlier in the array does not prevent a later valid entry of the same type from being accepted. Only an entry that was actually accepted makes a later entry of that type a duplicate.

Meaningfulness is therefore evaluated at decode time as well as at presentation time, and the two MUST agree.

#### Scenario: A blank earlier entry does not block a later valid one

- GIVEN a catalog entry whose `chapters` array is `[{background, "   "}, {background, "Real text."}]`
- WHEN the catalog entry is decoded
- THEN the case has exactly one Background chapter
- AND its content is `Real text.`

A malformed required core case field MUST NOT be reclassified as an optional chapter error or silently hidden. Catalog loading MUST surface the malformed-core condition through its catalog error behavior rather than return a successful catalog result that merely omits the malformed case.

#### Scenario: Legacy published case has no chapters

- GIVEN a valid catalog entry has no `chapters` member
- WHEN the catalog entry is decoded
- THEN the case loads successfully
- AND its chapter collection is empty
- AND its existing core and optional case data remain available

#### Scenario: Malformed optional chapter does not hide a valid case

- GIVEN a catalog entry has valid required core fields, one valid Background chapter, one malformed chapter entry, and one valid Investigation chapter
- WHEN the catalog entry is decoded
- THEN the case loads successfully
- AND the malformed chapter entry is ignored
- AND the valid Background and Investigation chapters remain available in fixed editorial order

#### Scenario: Unsupported or duplicate chapter is ignored individually

- GIVEN a catalog entry has a valid supported chapter, an unsupported chapter type, and a later duplicate of the accepted supported type
- WHEN the catalog entry is decoded
- THEN the supported chapter is retained once
- AND the unsupported and duplicate entries are ignored
- AND the valid core case remains loaded

#### Scenario: Malformed core case is surfaced

- GIVEN a catalog entry has a malformed required core case field
- WHEN the catalog is loaded
- THEN catalog loading reports the malformed-core condition
- AND it does not report successful loading while silently excluding that case as though only optional chapter data were malformed

### Requirement: Manual Publication Boundary

Chapter support MUST extend the existing draft-to-catalog JSON export without automating publication. Exporting a case MUST NOT directly update the catalog, publish a deployment, or introduce a backend dependency.

#### Scenario: Export preserves deliberate publication control

- GIVEN an editor exports a chapter-bearing draft
- WHEN export completes
- THEN compatible catalog JSON is made available through the existing export workflow
- AND `assets/data/cases.json` remains unchanged until a maintainer updates it
- AND no publication or deployment occurs automatically

### Requirement: Strict TDD Evidence

Every new behavior introduced by this change MUST have strict-TDD evidence showing that its behavior test was observed failing for the expected reason before the corresponding implementation made it pass. A test observed only in a passing state MUST NOT be accepted as strict-TDD evidence.

The observed failure MUST be attributed to the assertion the evidence credits, read off the reported failing line rather than assumed. When several expectations share one test body, the first mismatch aborts it, so an isolated probe proves only the first assertion it reaches.

> Historical note, non-normative: this change was planned while `intake-responsive` was still open, and carried a temporal gate blocking apply work until that change was archived. `intake-responsive` was archived on 2026-08-13, so the gate is spent. It is recorded here rather than kept as a requirement because its scenario could only be exercised while the gate was unsatisfied, which is now permanently false — an assertion that cannot fail is a defect this project has paid for repeatedly.

#### Scenario: New behavior has RED-before-GREEN evidence

- GIVEN a new behavior specified by this change
- WHEN it is implemented
- THEN the implementation evidence records the relevant test failing for the expected missing behavior
- AND records the same behavior passing after implementation
- AND a test observed only in a passing state is not accepted as strict-TDD evidence

#### Scenario: A compile failure is labelled as such

- GIVEN a new behavior whose test cannot compile because the type it exercises does not exist yet
- WHEN the RED observation is recorded
- THEN it is recorded as a compile failure naming the missing symbol
- AND it is not credited to any assertion line
- AND once the type exists, the behavior is re-observed failing on its own assertion before that assertion is satisfied
