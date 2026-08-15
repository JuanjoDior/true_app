```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:1aef29ffa335f2aa4e5903fb0eef32e288d88b8de866c9c3bb53bb0ac4f1f687
verdict: fail
blockers: 3
critical_findings: 3
requirements: 21/23
scenarios: 45/48
test_command: flutter test
test_exit_code: 0
test_output_hash: sha256:fe95dd836d6fe89a071405f79795d4cd68a4397d64cad61c1680d38cf7762b50
build_command: flutter analyze
build_exit_code: 0
build_output_hash: sha256:d6643a992b722aebc2d5269c93d8ee8b6f96a158ba7ff04f9557562a55e76bea
```

## Verification Report

**Change**: case-publication-detail
**Version**: N/A (OpenSpec delta specs, 4 capabilities)
**Mode**: Strict TDD
**HEAD**: 0c9016202ee23759a0f734bb688b8d15c0637a9e
**Deployed SHA**: 89cb790f2a26d31b8821b3bc00af4cc6449997de (Pages run 31833902940, success)

### Executive Position

The implementation is real, complete, and deployed. All 23 requirements are implemented in
source; 45 of 48 scenarios carry passing runtime evidence. The three findings that block
archive are evidence-quality failures, not product defects: the scroll and reachability
scenarios are backed by assertions that the specs themselves pre-declare inadmissible. The
product is healthy today (both scroll hosts use default scrollable physics), but nothing in
the suite would catch a regression that kills scrolling.

### Completeness

| Metric | Value |
|--------|-------|
| Tasks total | 131 |
| Tasks complete | 120 |
| Tasks incomplete | 11 |
| of which deliberate rollback checkpoints (RB.0-RB.9) | 10 |
| of which declared verification gaps (9.10) | 1 |
| Genuinely pending implementation work | 0 |

RB.0-RB.9 are a retreat plan, not pending work, and tasks.md states so explicitly. 9.10 is
deliberately unchecked: compact-mobile was not verified in-browser because resize_window does
not reach the Flutter viewport. Both are correctly recorded and neither is a blocker.

### Build & Tests Execution

**Build/Analysis**: PASSED

```text
$ flutter analyze
No issues found! (ran in 36.0s)   # exit 0
```

**Tests**: PASSED - 472 passed, 0 failed, 0 skipped

```text
$ flutter test
00:14 +472: All tests passed!     # exit 0
```

**Coverage**: not available - no coverage tool configured. Skipped, not a failure.

### Spec Compliance Matrix

#### Capability: case-editorial-chapters (7 requirements, 16 scenarios) - 16/16

| Requirement | Scenario | Test | Result |
|---|---|---|---|
| Fixed Optional Chapter Set | Author uses the supported chapter set | chapters_section_test.dart > offers no button at all / offers no icon button either / offers no reordering affordance / renders one field per chapter type | COMPLIANT |
| Fixed Optional Chapter Set | Partially populated chapters retain editorial order | case_chapter_codec_test.dart > returns entries in editorial order regardless of input order; case_publication_chapters_test.dart > exports them in editorial order, not authoring order | COMPLIANT |
| Meaningful Chapter Content | Export contains only meaningful chapters | case_publication_chapters_test.dart > exports only the meaningful chapters; case_chapter_codec_test.dart > omits a whitespace-only chapter | COMPLIANT |
| Meaningful Chapter Content | Export omits an empty chapter collection | case_publication_chapters_test.dart > omits the member when no chapter is meaningful / omits the member for a draft with no chapters at all | COMPLIANT |
| Draft Persistence and Live Preview | Chapters survive draft save and load | case_draft_chapters_test.dart; case_drafts_store_test.dart | COMPLIANT |
| Draft Persistence and Live Preview | Legacy draft remains readable | case_chapter_codec_test.dart > treats a null member as an empty collection; case_draft_chapters_test.dart | COMPLIANT |
| Draft Persistence and Live Preview | Chapter editing updates preview | draft_preview_chapters_test.dart (5 tests); intake_chapter_preview_test.dart | COMPLIANT |
| Publication Round Trip | All chapters complete the publication round trip | case_publication_chapters_test.dart > ida y vuelta hasta el caso publicado (3 tests) | COMPLIANT |
| Additive Published-Case Decoding | A blank earlier entry does not block a later valid one | case_chapter_codec_test.dart > a blank earlier entry does not consume its type slot / a malformed earlier entry does not consume its type slot | COMPLIANT |
| Additive Published-Case Decoding | Legacy published case has no chapters | local_cases_repository_chapters_test.dart > a catalog entry without the member loads / keeps its core fields | COMPLIANT |
| Additive Published-Case Decoding | Malformed optional chapter does not hide a valid case | local_cases_repository_chapters_test.dart > keeps valid chapters around a malformed entry | COMPLIANT |
| Additive Published-Case Decoding | Unsupported or duplicate chapter is ignored individually | local_cases_repository_chapters_test.dart > ignores an unsupported chapter type without losing the case / keeps the first accepted entry when a type repeats | COMPLIANT |
| Additive Published-Case Decoding | Malformed core case is surfaced | local_cases_repository_chapters_test.dart > a malformed core field raises instead of dropping the case / is not rescued by valid chapters | COMPLIANT |
| Manual Publication Boundary | Export preserves deliberate publication control | git log 182003a..HEAD on assets/data/cases.json returns 0 commits (re-verified this session); case_exporter_test.dart | COMPLIANT |
| Strict TDD Evidence | New behavior has RED-before-GREEN evidence | tasks.md per-unit RED/GREEN rows plus mutation probe tables (R1-R5, Q5, and per-unit equivalents) | COMPLIANT |
| Strict TDD Evidence | A compile failure is labelled as such | tasks.md 7.4 records a compile failure naming caseBySlugProvider and CaseDetailPage as absent; same pattern in Units 4a-2 and 6 | COMPLIANT |

#### Capability: case-publication-route (5 requirements, 11 scenarios) - 11/11

| Requirement | Scenario | Test | Result |
|---|---|---|---|
| Stable Hash Route Identity | Navigation emits the case slug route | app_route_parser_test.dart > a case restores to its route; case_directory_test.dart > it opens the case that was tapped | COMPLIANT |
| Stable Hash Route Identity | Mutable title does not define route identity | case_by_slug_provider_test.dart > a known slug resolves its case (lookup compares slug only; title is never read) | COMPLIANT |
| Stable Hash Route Identity | Route identity is the slug, not the selection ID | case_by_slug_provider_test.dart > the id of that same case does NOT resolve | COMPLIANT - falsifiability note SATISFIED: hand-built fixture with id legacy-7 and slug known-case, and the negative test fails under an ID-lookup implementation (mutation probe R1 killed 8 tests) |
| Known-Case Direct Load and Refresh | Known case loads directly | app_routing_activation_test.dart > a case deep link opens its detail page / shows the case itself; browser task 9.7 against deployed /#/casos/zodiac | COMPLIANT |
| Known-Case Direct Load and Refresh | Known case survives refresh | tasks.md 9.7 - hard location.reload() on the deployed URL, hash and dossier identical | COMPLIANT |
| Browser History Coherence | Back and forward traverse case routes coherently | tasks.md 9.8 - hash recorded at each step, root to zodiac to goldenstate to back to back to forward to forward, no duplicate entries; supported by app_router_delegate_test.dart > historial sin duplicados (4 tests) | COMPLIANT |
| Unknown Slug Not-Found State | Unknown slug remains visible | app_routing_activation_test.dart > a case route with an unknown slug says the case is missing; case_detail_page_test.dart > substitutes no fallback case; browser 9.9 | COMPLIANT |
| Unknown Slug Not-Found State | Reader returns from an unknown route | case_detail_page_test.dart > offers a way back to the Situation Room; browser 9.9 | COMPLIANT |
| Browser and Host Verification Evidence | Deployed direct load and refresh are proven | tasks.md 9.7 - Chrome against deployed 89cb790; widget evidence explicitly not credited | COMPLIANT |
| Browser and Host Verification Evidence | Deployed history is proven | tasks.md 9.8 | COMPLIANT |
| Browser and Host Verification Evidence | Host-document precondition is verified at its boundary | tasks.md 9.4 - build/web/index.html read directly (base href at line 17, viewport at line 28); web_index_viewport_test.dart reads the real document rather than a widget override | COMPLIANT |

#### Capability: expanded-case-dossier (6 requirements, 14 scenarios) - 12/14

| Requirement | Scenario | Test | Result |
|---|---|---|---|
| No Duplicated Editorial Renderer | A shared block has one implementation | Structural: CaseDossierContent is constructed in exactly two places (case_dossier_panel.dart:55, case_detail_page.dart:96); intake preview composes CaseDossierPanel (intake_preview_panel.dart:35). Behaviour: case_dossier_content_test.dart, case_dossier_characterization_test.dart | COMPLIANT |
| No Duplicated Editorial Renderer | The expanded page may show more than the compact panel | case_dossier_content_test.dart > cromo de mapa frente a previsualizacion (5 tests); case_detail_page_test.dart > shows no map chrome | COMPLIANT |
| No Duplicated Editorial Renderer | Shared blocks stay consistent where both hosts show them | case_dossier_content_test.dart > renders the four chapters in the fixed editorial order / renders each chapter heading exactly once; case_detail_page_test.dart > renders its chapters in editorial order | COMPLIANT |
| Optional Content Omission and Legacy Presentation | Legacy case renders without empty chapters | case_dossier_content_test.dart > a legacy case without chapters renders no chapter heading / still renders its summary; case_detail_page_test.dart > a legacy case without chapters renders normally | COMPLIANT |
| Optional Content Omission and Legacy Presentation | Meaningful chapters render once in order | case_dossier_content_test.dart > omits a chapter whose content is only whitespace, plus the order and once-only tests | COMPLIANT |
| Contextual Actions Remain Separate | Compact panel retains map actions | case_dossier_content_test.dart > map mode offers the return-to-map affordance / the recenter control; case_dossier_panel_config_test.dart > an unconfigured panel still clears the map selection | COMPLIANT |
| Contextual Actions Remain Separate | Expanded page provides route context | case_detail_page_test.dart > returning goes back to the Situation Room / shows no map chrome | COMPLIANT |
| Contextual Actions Remain Separate | Intake preview remains a preview context | case_dossier_content_test.dart > preview mode suppresses the return-to-map affordance / the recenter control / the follow control / still renders the editorial identity | COMPLIANT |
| Context-Appropriate Related-Case Navigation | Related case opens inside map context | case_dossier_panel_config_test.dart > an unconfigured panel still selects a related case; case_dossier_content_test.dart > a related card calls back with its own case | COMPLIANT |
| Context-Appropriate Related-Case Navigation | Related case opens inside route context | case_detail_page_test.dart > opening a related case routes to its slug (asserts slug, not id; mutation probe R3); browser 9.8 covers the Back leg | COMPLIANT |
| Expanded Reading Experience Across Supported Layouts | Expanded dossier is usable on mobile | case_detail_page_test.dart:369 > scrolling brings the end of the dossier into view | PARTIAL - overflow and not-visible-on-arrival preconditions are correct and position-based, but the scroll is driven by position.jumpTo(maxScrollExtent), a programmatic helper the normative falsifiability note forbids. See CRITICAL-1 |
| Expanded Reading Experience Across Supported Layouts | Expanded dossier is usable on desktop | (none found) | UNTESTED - all four responsive tests run at Size(360, 780); the default harness viewport is Size(1200, 2400), which never overflows. See CRITICAL-2 |
| Situation Room Behavior Remains Intact | Direct route does not require map state | case_by_slug_provider_test.dart > sin dependencia del mapa (3 tests); app_routing_activation_test.dart > opening a case does not touch the map selection | COMPLIANT |
| Situation Room Behavior Remains Intact | Map remains functional after routed reading | app_routing_activation_test.dart > returning preserves an existing map selection; browser 9.11 (map, 15 markers, filters, focus panel intact) | COMPLIANT |

#### Capability: published-case-directory (5 requirements, 7 scenarios) - 6/7

| Requirement | Scenario | Test | Result |
|---|---|---|---|
| Mobile and Desktop Directory Access | Mobile reader opens the directory | case_directory_test.dart > rail-less mobile exposes a directory entry point / can open the directory; a long archive really has something to scroll | PARTIAL - entry point and opening are proven at 500x900. The scrolling half is not: only maxScrollExtent > 0 is asserted, the last-entry-not-visible-on-arrival precondition is absent, no post-scroll reachability is asserted, and no gesture is performed. See CRITICAL-3 |
| Mobile and Desktop Directory Access | Desktop reader opens the directory | case_directory_test.dart > desktop without rail / desktop with rail (entry point plus open, both topologies); browser 9.10 desktop leg | COMPLIANT |
| Complete Deterministic Directory Ordering | Cases are ordered by year and title | case_directory_provider_test.dart > the most recent case comes first / the input order does not decide it / same year falls back to title ascending / same year and title falls back to slug ascending / the tie-break does not override the year | COMPLIANT - all three sort keys independently exercised |
| Complete Deterministic Directory Ordering | Legacy published case remains listed | case_directory_provider_test.dart > a legacy case with a differing id is listed too / every loaded case is listed | COMPLIANT |
| Loaded Catalog Reuse | Directory uses the existing loaded catalog | case_directory_provider_test.dart > reading the directory does not load the catalog again / it loads exactly once for map and directory together | COMPLIANT - falsifiability note SATISFIED: the stub repository exposes a loads counter that can go up, so a second load is observable |
| Directory Route Navigation | Reader opens a directory case | case_directory_test.dart > tapping a case opens its detail page / it opens the case that was tapped | COMPLIANT |
| Situation Room Map Preservation | Existing map discovery still works | case_directory_test.dart > el mapa se queda como estaba (4 tests: selection, filter, recenter tick, no map selection on route open) | COMPLIANT |

**Compliance summary**: 45/48 scenarios compliant, 2 partial, 1 untested.

### Correctness (Static Evidence)

| Requirement | Status | Notes |
|---|---|---|
| Fixed Optional Chapter Set | Implemented | case_chapter.dart - fixed four-type enum, no arbitrary types |
| Meaningful Chapter Content | Implemented | orderedMeaningful; exporter emits chapters only when non-empty |
| Draft Persistence and Live Preview | Implemented | case_drafts_store.dart serialized queue (Unit 3) |
| Publication Round Trip | Implemented | case_exporter.dart:177 delegates to CaseChapters.toJson() |
| Additive Published-Case Decoding | Implemented | Per-entry tolerance; core-field errors still raise |
| Manual Publication Boundary | Implemented | No write path to assets/data/cases.json; asset untouched |
| Stable Hash Route Identity | Implemented | app_route_information_parser.dart - exactly two segments, Uri.encodeComponent on the slug |
| Known-Case Direct Load and Refresh | Implemented | routeInformationProvider is null in production (the Unit 9 fix) |
| Browser History Coherence | Implemented | AppRouteController._moveTo suppresses no-op notifications so Back cannot stick |
| Unknown Slug Not-Found State | Implemented | RouteNotFoundPage keeps the URI verbatim and stays distinct from the missing-case state |
| Browser and Host Verification Evidence | Implemented | Recorded in tasks.md 9.3-9.9 |
| No Duplicated Editorial Renderer | Implemented | One CaseDossierContent, three composing hosts |
| Optional Content Omission | Implemented | Absent sections omitted, no placeholder headings |
| Contextual Actions Remain Separate | Implemented | CaseDossierMode gates map chrome |
| Context-Appropriate Related-Case Navigation | Implemented | Callback in map context, slug route in page context |
| Expanded Reading Experience | Implemented | SingleChildScrollView with default physics - the product is genuinely scrollable |
| Situation Room Behavior Remains Intact | Implemented | _canMoveCamera guard added for the offstage-map crash |
| Mobile and Desktop Directory Access | Implemented | Three topologies wired (mobile, desktop-no-rail, desktop-with-rail) |
| Complete Deterministic Directory Ordering | Implemented | Year desc, then title asc, then slug asc |
| Loaded Catalog Reuse | Implemented | publishedDirectoryProvider derives from casesProvider |
| Directory Route Navigation | Implemented | Navigates by slug |
| Situation Room Map Preservation | Implemented | Directory is additive; map untouched |
| Strict TDD Evidence | Implemented | RED/GREEN plus mutation probes recorded per unit |

### Coherence (Design)

| Decision | Followed? | Notes |
|---|---|---|
| 7.1 Hash strategy, no usePathUrlStrategy | Yes | Zero matches for dart:html, usePathUrlStrategy or setUrlStrategy in lib code; enforced by app_navigation_boundary_test.dart |
| 7.2 Parser translates URI to route state | Yes | AppRouteInformationParser with round-trip tests |
| 7.3 Controller owns route state, never writes workspaceProvider | Yes | AppRouteController does not import it; boundary probe Q5 |
| 7.3 Detail stacks above root, never replaces it | Yes | AppRouterDelegate._pages() returns root plus detail |
| 7.4 Root reveals whatever workspaceProvider held | Yes | app_routing_activation_test.dart 7.11b pair |
| Root creates controller and delegate once | Yes | StatefulWidget field initialisers; asserted by the app root creates its router once, outside build |
| DossierPresentation deferred from 4b to 7 | Deviation, recorded | Design named it in a signature but never defined it; declared in tasks.md 7.9 |
| CaseDossierPanelMode renamed CaseDossierMode | Deviation, recorded | Rename only |
| Map chrome gated by mode rather than nullable callbacks | Deviation, recorded | Declared in Unit 4b |
| Task 4.4 host-chain proof moved to 4c | Deviation, recorded | The proof could only close in 4c |
| Unit 7 at or below 1500 changed lines | VIOLATED, declared | 1,566 measured (489 changed plus 1,077 new; 819 of them tests). Reason recorded: last indivisible seam |
| Unit 9 changes zero source (9.12) | VIOLATED, declared | One source file changed to fix the deep-link defect; Unit 7 formally reopened by 9.12's own rule |

All twelve rows above match what tasks.md already records. No deviation was found that the
artifacts fail to disclose, and none has silently disappeared.

### TDD Compliance

| Check | Result | Details |
|---|---|---|
| TDD Evidence reported | PASS | Per-unit RED/GREEN rows plus mutation-probe tables in tasks.md |
| All tasks have tests | PASS | Every source-bearing unit names its test file |
| RED confirmed (tests exist) | PASS | All named test files exist on disk (46 files in test/) |
| GREEN confirmed (tests pass) | PASS | 472/472 re-executed this session, exit 0 |
| Triangulation adequate | PASS | Mutation probes are the strongest form present: R1 killed 8 tests, R2 killed 2, R3 and R5 killed named tests. Probes recorded as isolated and reverted |
| Safety Net for modified files | PASS | Unit 4a-1 wrote characterization tests before the 4a-2 extraction, which is the correct order |

**TDD Compliance**: 6/6 checks passed.

This is the strongest TDD evidence trail verified in this project so far. Two marks of quality
are worth naming: task 7.3 records rewriting a precondition (findsNothing replaced by a
position check) after discovering it was vacuous, and the Unit 9 note states plainly that all
431 tests passed while production was broken. Both are self-incriminating findings the cycle
chose to record rather than bury.

### Test Layer Distribution

| Layer | Tests | Files | Tools |
|---|---|---|---|
| Unit | ~200 | 22 | flutter_test |
| Integration (widget) | ~272 | 24 | flutter_test plus ProviderContainer overrides |
| E2E (browser) | 0 automated | 0 | not installed - manual Chrome verification only |
| Total | 472 | 46 | |

Browser evidence for this change is manual and recorded, not automated. That is consistent with
the spec, which requires real-browser evidence but does not require it to be automated.

### Changed File Coverage

Coverage analysis skipped - no coverage tool configured in this project.

### Assertion Quality

| File | Line | Assertion | Issue | Severity |
|---|---|---|---|---|
| test/case_detail_page_test.dart | 395 | position.jumpTo(position.maxScrollExtent) | Programmatic scroll bypasses physics; passes against a dead scroll | CRITICAL |
| test/case_directory_test.dart | 352 | expect(position.maxScrollExtent, greaterThan(0)) | Non-vacuity precondition with no reachability assertion following it | CRITICAL |
| test/case_detail_page_test.dart | 328 | expect(tester.takeException(), isNull) | Absence-of-exception only; asserts nothing about what rendered | WARNING |
| test/case_directory_test.dart | 325 | expect(tester.takeException(), isNull) | Same | WARNING |

No tautologies, no orphan empty-collection assertions, no ghost loops, no mock-heavy files and
no smoke-test-only files were found. The two WARNING rows are acceptable as supplements, since
each sits beside a companion test that asserts real content, but neither carries a scenario
alone.

**Assertion quality**: 2 CRITICAL, 2 WARNING.

### Quality Metrics

**Linter/Analyzer**: PASS - flutter analyze, No issues found!, exit 0.
**Type Checker**: PASS - Dart analysis is the type check; clean.

### Issues Found

**CRITICAL**

- **CRITICAL-1 - The expanded-dossier mobile scroll is driven by a programmatic helper the spec forbids.**
  test/case_detail_page_test.dart:395 scrolls with position.jumpTo(position.maxScrollExtent).
  The expanded-case-dossier falsifiability note is normative for verification and states the
  scenario MUST drive the scroll with a real gesture rather than a programmatic helper.
  jumpTo calls forcePixels, which bypasses applyBoundaryConditions and applyPhysicsToUserOffset
  entirely, so this test passes unchanged if someone adds NeverScrollableScrollPhysics to the
  page's SingleChildScrollView. Its companion maxScrollExtent > 0 assertion does not close the
  hole either: maxScrollExtent is computed from content versus viewport and is likewise
  physics-independent. The two preconditions in this test are genuinely good - the
  position-based not-visible-on-arrival check is exactly right - but the actuation is the same
  defect class this project already paid for twice (scrollUntilVisible, and the
  intake_narrow_layout_test.dart:176-177 defect the note itself cites). Fix: replace with
  tester.dragFrom or fling, as intake_narrow_layout_test.dart:212 already does correctly.

- **CRITICAL-2 - The expanded-dossier desktop scroll scenario has no covering test.**
  expanded-case-dossier, scenario "Expanded dossier is usable on desktop", requires a wide
  desktop layout whose content overflows, with the last section reached by scrolling. All four
  tests in the "lectura en cualquier pantalla" group pass Size(360, 780); the harness default is
  Size(1200, 2400), tall enough that the fixtures never overflow. No test exercises this
  scenario at any desktop width. Browser task 9.10 verified the directory on wide desktop, not
  the expanded dossier's desktop scrolling. This scenario is UNTESTED, not merely weakly tested.

- **CRITICAL-3 - The directory mobile scrolling half of its scenario is unasserted.**
  published-case-directory, scenario "Mobile reader opens the directory", requires that the last
  entry is reached by scrolling through the list, and its falsifiability note requires both
  preconditions (maxScrollExtent > 0 AND last item not visible on arrival) followed by a real
  gesture. test/case_directory_test.dart:328 asserts only maxScrollExtent > 0 and then stops:
  there is no arrival-invisibility precondition, no gesture and no post-scroll reachability
  assertion. The requirement's entry-point and open-without-map-gesture halves are properly
  covered; only the scrolling half fails. This is the one place where the declared 9.10
  compact-mobile browser gap and a widget-test gap land on the same scenario, so nothing covers
  it at either layer.

**WARNING**

- **W-1 - The working tree is not clean; the brief asserted it was.**
  openspec/changes/case-publication-detail/tasks.md carries 48 uncommitted insertions and 44
  deletions. The change is benign and in fact corrective: it converts the "Original task text"
  blocks from unchecked checkboxes into blockquote lines, so preserved historical text no longer
  inflates the unchecked-task count. The 120/11 counts in this report are measured against the
  working tree. This must be committed before archive, or the archived artifact will not match
  what was verified.
- **W-2 - Stale commit counts inside tasks.md.** Task 9.1 says nine commits and 9.6 says ten
  commits pushed; the cycle is eleven commits (e1e350d through 0c90162). Documentation drift
  only - the SHAs quoted are correct and were verified.
- **W-3 - Unit 7 exceeded the 1500-line ceiling (1,566).** Declared in tasks.md with reasoning.
  Recorded here so it does not vanish at archive; not treated as a new finding.
- **W-4 - Unit 7 is formally reopened by task 9.12.** The Unit 9 deep-link fix (89cb790) changed
  source during a zero-source unit. Correctly declared. Archive must not silently close Unit 7 as
  if 9.12 had been met.
- **W-5 - Mutation probe numbering skips R4.** The Unit 7 table lists R1, R2, R3 and R5. Either a
  probe was dropped without a note or the numbering is cosmetic. Minor, but this cycle's own
  standard is that evidence gaps get named.
- **W-6 - initialLocation remains a production-visible test-only parameter.** It is now correctly
  defaulted (null selects the platform provider) and guarded by the paired tests "without an
  initialLocation the platform route is used" and "with an initialLocation the test route wins",
  which is the right mitigation. But it is still the seam that hid the original defect, and every
  deep-link widget test still exercises the overridden path rather than the production one.

**SUGGESTION**

- **S-1** - Task 9.10 is correctly left unchecked, and that decision should be preserved verbatim
  through archive. It is the clearest artifact of this cycle's discipline.
- **S-2** - The out-of-scope createDraft millisecond-collision defect (DateTime.now().millisecondsSinceEpoch
  used as draftId) is recorded in PROJECT_CONTEXT.md under Pendiente. Confirmed present and
  correctly not fixed here.
- **S-3** - Consider one automated browser check (for example a Playwright smoke test on the
  deployed hash route) so the two entry-point clicks that could not be actuated by coordinate
  against the Flutter canvas gain a repeatable proof.
- **S-4** - expect(tester.takeException(), isNull) appears as the sole assertion in two layout
  tests. It is a reasonable overflow guard but should not be read as evidence that anything
  rendered.

### Verdict

**FAIL** - 3 CRITICAL findings block archive.

The qualification matters: this is not a failure of the implementation. Every requirement is
implemented, the deployment is real and verified in a browser, the analyzer is clean and 472/472
tests pass. All three blockers are the same species of defect - scroll and reachability evidence
that cannot fail - and each one is forbidden by a falsifiability note the specs themselves wrote
in advance, precisely because this repository has shipped that defect before. Accepting them
would reproduce the exact mistake this cycle was designed to stop.

Remediation is small and well-bounded: one gesture swap (CRITICAL-1), one new desktop-width
overflow test (CRITICAL-2) and one completed scroll assertion (CRITICAL-3). None requires
touching production source.
