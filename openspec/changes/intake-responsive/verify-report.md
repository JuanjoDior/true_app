```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:d150c7d036c31acea63f46cd083c220bb101acec5fefd956b53b168af76b1b37
verdict: fail
blockers: 1
critical_findings: 1
requirements: 10/11
scenarios: 23/25
test_command: flutter test
test_exit_code: 0
test_output_hash: sha256:055784b7172b0591ada4a58e9ed7aab91c678ce3807dd6d5b61dbae578c1def1
build_command: flutter analyze
build_exit_code: 0
build_output_hash: sha256:66a885d98e3588891637aacfb163947f5577d165ce5eb033311957b75f460c4e
```

## Verification Report (fourth verification, after Phase 8)

**Change**: intake-responsive
**Mode**: Strict TDD (`openspec/config.yaml` `apply.tdd: true`)
**Base**: 3af24d7 to HEAD 4e59ef4c4e91e257aa399c3d578f11b15bd8a501
**Artifact store**: hybrid (OpenSpec files authoritative)
**Supersedes**: the report at evidence_revision sha256:ce69dde1..., written at 401ed03,
which predates Phase 8.

Both CRITICAL blockers from the superseded report are **genuinely CLOSED**. Phase 8's
self-caught zoom-coverage gap is closed by a test proven non-vacuous here by two
independent mutations, one of which is stronger than the mutation Phase 8 reported.

The verdict is nonetheless FAIL, on one new blocker introduced by the remediation itself:
the third scenario of the new requirement cannot be verified by any test in this
repository, cannot be verified by the method its own requirement mandates, and asserts as
established fact an on-device outcome that `proposal.md` and `tasks.md` simultaneously
record as an unconfirmed hypothesis.

### Counting rule

Unchanged across all four reports, so the deltas stay comparable. A scenario counts toward
the scenarios total only when COMPLIANT (PARTIAL does not count). A requirement counts
toward the requirements total when no scenario under it is UNTESTED (PARTIAL still counts).

The totals moved from 10/22 to 11/25 because Phase 8 added one requirement with three
scenarios. `requirements: 10/11` and `scenarios: 23/25` both reflect the single new
blocker plus the one carried-forward PARTIAL.

### Completeness

| Metric | Value |
|--------|-------|
| Tasks total | 61 (37 original + 6 Phase 5 + 5 Phase 6 + 6 Phase 7 + 7 Phase 8) |
| Tasks complete | 61 |
| Tasks incomplete | 0 |
| Tasks marked done but not substantiated | 0 |

`git diff 3af24d7 HEAD -- lib web` is **empty**, confirming Phase 8's central claim: no
`lib/` and no `web/` file changed. The four files touched are `proposal.md`,
`specs/responsive-breakpoints/spec.md`, `tasks.md` and `test/web_index_viewport_test.dart`
(`4 files changed, 120 insertions(+), 6 deletions(-)`).

`git status --porcelain` was empty before the evidence run, after every probe, and at the
close of this verification.

### Build and Tests Execution

**Build (static analysis)**: PASSED. `flutter analyze` returned "No issues found! (ran in
1.7s)", exit 0. The hashed output includes the `pub` dependency-resolution preamble emitted
by this invocation.

**Tests**: PASSED. `flutter test` returned "00:08 +168: All tests passed!", exit 0.
168 tests, 0 failed, 0 skipped (was 167; +1 from Phase 8's zoom case).

**Coverage**: Not available. No coverage tool configured. Skipped, not a failure.

Both figures in the orchestrator's brief (168 passing, analyze clean) were reproduced
independently on a clean tree, not accepted.

### Independent Mutation Evidence (this verification)

Four probes. Each applied to a clean tree, run, then reverted with `git checkout --`. The
working tree is clean at HEAD 4e59ef4 with no file left modified.

| # | Probe | Observed output | Conclusion |
|---|---|---|---|
| 1a | `maximum-scale=1.0` appended to the viewport `content` | `+2 -1`, exit 1. `Expected: not contains 'maximum-scale'` / `Actual: 'width=device-width,initial-scale=1.0,maximum-scale=1.0'` | Zoom guard's first assertion is **live**. Reproduces Phase 8's own claim exactly |
| 1b | `user-scalable=no` appended **alone** (no `maximum-scale`) | `+2 -1`, exit 1. `Expected: not contains 'user-scalable=no'` / `Actual: 'width=device-width,initial-scale=1.0,user-scalable=no'` | Zoom guard's second assertion is **independently live**. Phase 8's combined mutation could not establish this |
| 1c | `user-scalable=0` appended (semantic equivalent of `=no` in browsers) | `+3 -0`, exit 0. All three tests pass | **Narrow hole**: the guard misses a non-canonical spelling that also disables zoom. See SUGGESTION 8 |
| 2 | `content` weakened to `"initial-scale=1.0"` (drops `width=device-width`) | `+2 -1`, exit 1. `Expected: contains 'width=device-width'` | Device-width scenario's guard is **non-vacuous**, re-proven this run |

Probe 1b is the reason this run does not simply accept Phase 8's account. The zoom test
holds two `expect` calls in one `test`, so the first mismatch aborts the body: Phase 8's
mutation injected `maximum-scale` **and** `user-scalable=no` together and observed only
`Expected: not contains 'maximum-scale'`. That output proves the first assertion fires and
says nothing about the second. Probe 1b isolates it and confirms it fires too. The claim
was true; the evidence offered for it was incomplete. This is the same
sequential-assertion narrowing recorded as SUGGESTION 6 in the previous report, now
observed in a second test file.

Probes A-F from the previous report are not repeated: no `lib/` file changed since, so
their conclusions carry forward with provenance marked in the matrix below.

### Spec Compliance Matrix

Authoritative counts read from the delta specs at HEAD: **11 requirements, 25 scenarios**
(`responsive-breakpoints` 4/9, `intake-responsive-layout` 7/16).

**responsive-breakpoints** (4 requirements, 9 scenarios)

| Requirement | Scenario | Test / Evidence | Result | Delta |
|---|---|---|---|---|
| Centralized Breakpoint Constants | No inline width literals remain in home_page.dart | static: `home_page.dart:29,30,36,57` reference `Breakpoints` tokens | COMPLIANT (static-only; source-property scenario with no meaningful runtime form) | unchanged |
| Centralized Breakpoint Constants | Existing threshold values are preserved unchanged | `situation_breakpoints_test.dart:137-142`; previous run's probes A and B | COMPLIANT | unchanged |
| Sala Layout Selection Behavior-Preserving | Desktop body at or above 880 | `situation_breakpoints_test.dart:185-196` (900px) | COMPLIANT | unchanged |
| Sala Layout Selection Behavior-Preserving | Mobile body at 879 or less | `situation_breakpoints_test.dart:198-209` (800px) | COMPLIANT | unchanged |
| Sala Layout Selection Behavior-Preserving | Top bar compact at 980 or less | `situation_breakpoints_test.dart:185-196` (900px, metrics absent) | COMPLIANT | unchanged |
| Minimum Supported Width | 360px is the floor | `intake_narrow_layout_test.dart:39,66` (360x780) | COMPLIANT | unchanged |
| **Host Document Viewport Precondition** | Host document declares a device-width viewport | `web_index_viewport_test.dart:27-57`; **probe 2** | **COMPLIANT** | **NEW** |
| **Host Document Viewport Precondition** | Zoom remains available | `web_index_viewport_test.dart:59-80`; **probes 1a and 1b** | **COMPLIANT** | **NEW** |
| **Host Document Viewport Precondition** | The precondition governs every width-gated screen, not only intake | none - no test in the repository can enter its GIVEN | **UNTESTED** | **NEW - this is CRITICAL-1** |

**intake-responsive-layout** (7 requirements, 16 scenarios)

Unchanged from the previous report in every row; no `lib/` and no `test/` file in this
capability changed since. 15 COMPLIANT, 1 PARTIAL ("All six sections reachable at 360px",
still static-only - re-confirmed this run that `kCaseFormSections` appears in
`intake_form_widget_test.dart` only, inside that test's own harness tree, and nowhere in
`intake_narrow_layout_test.dart`).

**Compliance summary**: 23/25 scenarios compliant (was 21/22), 1 PARTIAL, 1 UNTESTED.
Requirements 10/11 (was 10/10). Two scenarios gained, one added untested.

### Correctness (Static Evidence)

| Requirement | Status | Notes |
|---|---|---|
| Host Document Viewport Precondition | Implemented, specified, partly verifiable | `web/index.html:28` carries `content="width=device-width, initial-scale=1.0"`; the requirement now describes it, mandates document-level verification, and records the WCAG 1.4.4 trade-off with its accepted cost. Scenario 3 is the exception - see CRITICAL-1 |

No other row moved; no `lib/` file changed since the previous report.

### Coherence (Design)

Design decisions D1-D7 all remain followed; no `lib/` change since the previous assessment.

`design.md` was still not extended for Phases 7 or 8. The previous report flagged this as
part of CRITICAL-1; Phase 8 closed the gap in the **spec** rather than in `design.md`. That
is an acceptable resolution - the requirement's own prose now carries the rationale, the
verification mandate and the accepted cost, which is where a future contributor will look -
and the WCAG omission is no longer recorded only in an HTML comment. Treated as closed, not
downgraded to a warning.

### TDD Compliance

| Check | Result | Details |
|---|---|---|
| TDD Evidence reported | Partial | Still no prescribed TDD Cycle Evidence table. The `apply-progress` artifact (Engram #446) is stale, covering Phases 1-3 only. Phases 5-8 of `tasks.md` carry explicit per-fix RED and mutation evidence instead |
| All tasks have tests | Yes | 61/61 tasks checked; every named test file exists |
| RED confirmed (tests exist) | Yes | Phase 8's new case exists at `web_index_viewport_test.dart:59-80` |
| GREEN confirmed (tests pass) | Yes | 168/168 at HEAD 4e59ef4 |
| Triangulation adequate | Yes | The viewport guard now tests presence, positive content and negative content - three distinct expectation shapes over one artifact |
| Safety Net for modified files | Yes | `web_index_viewport_test.dart` was modified, not new; the 2 pre-existing cases still pass (probes 1a/1b show `+2` before the failure) |

Phase 8 continues the pattern established in Phase 5: it found its own uncovered scenario
before verification did, named the defect family explicitly, and closed it. That is the
right direction of travel, and it is why the remaining blocker is a scenario-design defect
rather than another missing test.

### Assertion Quality

Re-audit focused on the single test file modified since the previous report.

`test/web_index_viewport_test.dart:59-80` - the new zoom case. Reads a real build input,
asserts two negative conditions, and lowercases plus strips whitespace before matching, so
it tolerates reformatting without tolerating semantic loss. Probes 1a and 1b prove both
assertions fail on real regressions. **Not vacuous.** Its only weakness is coverage of
spelling variants (probe 1c), recorded as a SUGGESTION rather than a defect because the
test matches its scenario's literal wording exactly - the under-specification is in the
scenario, not in the test.

| File | Line | Assertion | Issue | Severity |
|---|---|---|---|---|
| `test/intake_narrow_layout_test.dart` | 353 | `takeException` isNull as the only assertion for the 336px D4 case | Sole assertion; nothing asserts the panel rendered content | SUGGESTION (carried) |

**Assertion quality**: 0 CRITICAL, 0 WARNING, 1 SUGGESTION carried forward.

### Test Layer Distribution

| Layer | Tests | Files | Tools |
|---|---|---|---|
| Unit (pure Dart) | 91 | 11 | flutter_test |
| Static-artifact (reads a build input) | 3 | 1 | flutter_test + dart:io |
| Widget / integration | 73 | 14 | flutter_test |
| Value-pinning (non-widget test inside a widget file) | 1 | (shared) | flutter_test |
| E2E / real browser | 0 | 0 | not installed |
| **Total** | **168** | **25** | |

The static-artifact layer grew from 2 to 3 tests. It remains the only layer that can
observe the deployed document, and `.github/workflows/deploy-pages.yml:41,44` still runs
`flutter test` before `flutter build web`, so the guard gates production.

### Quality Metrics

**Linter / Analyzer**: `flutter analyze`, "No issues found!", exit 0.
**Type Checker**: covered by `flutter analyze`, no errors.

### Resolution of the Two Previous Blockers

**Previous CRITICAL-1 (host document load-bearing and unspecified): CLOSED.**
`### Requirement: Host Document Viewport Precondition` now exists in
`specs/responsive-breakpoints/spec.md:57-83`. It is placed in the shared capability rather
than in intake, which is correct - the host document affects both consuming screens. It
covers what `web/index.html:28` actually does (the `width=device-width` declaration), states
in prose why a widget test cannot verify it (`tester.view.physicalSize` bypasses viewport
negotiation), mandates that verification read the host document directly, and records the
deliberate `maximum-scale` / `user-scalable=no` omission together with its WCAG 1.4.4
rationale and its named accepted cost. Two of its three scenarios have non-vacuous covering
tests, proven by probes 1a, 1b and 2. The requirement is what the previous report asked for.

**Previous CRITICAL-2 (undocumented behavioral change to the live public Sala): CLOSED.**
`proposal.md:96` leaves the sixth Success Criterion unticked and struck through;
`proposal.md:98-121` adds "Correction: the Sala did change on mobile", which states the
mechanism (980 >= 880 so `_DesktopBody` was served shrunk-to-fit), what changed, why the
covering tests were structurally incapable of catching it, and that the improvement is
"believed" rather than confirmed pending on-device re-triage. `proposal.md:79` adds the
risk-table row for the unlisted risk that fired. The five satisfied criteria are ticked.

**Explicit ruling on the unticked criterion**: it does **not** block archive. A Success
Criterion is a planning-time prediction, not a normative requirement; no requirement in
either delta spec asserts Sala mobile-body parity, so nothing in the spec of record is
falsified by leaving it unticked. Its purpose is to be judged honestly at the end, and an
unticked, struck-through criterion carrying a written correction is that artifact working
as designed. Blocking on it would create pressure to re-word criteria until they read true,
which is exactly the dishonesty Phase 8 declined. What *would* block is an unticked
criterion left silently unexplained, or one whose falsity revealed an unshipped
requirement; neither applies here. Phase 8 did precisely what the previous report
prescribed, and did it without gaming the wording.

### Issues Found

**CRITICAL**

1. **The new requirement's third scenario cannot be verified, and contradicts two other
   artifacts in the same change.** `specs/responsive-breakpoints/spec.md:77-83`, "The
   precondition governs every width-gated screen, not only intake". Three defects compound
   in one scenario:

   *It cannot enter its own GIVEN.* "GIVEN a mobile browser lacking the device-width
   viewport declaration" describes a configuration the very same requirement forbids ("The
   web host document MUST declare..."). No test can legitimately establish that state; only
   a mutation probe can, and a probe is a verification technique, not a covering test.

   *Its mandated verification method cannot reach it.* The requirement states that
   "Verification of this requirement MUST read the host document (or its built output)
   directly". Reading `web/index.html` establishes that the meta is declared. It cannot
   establish anything about which branch the Sala or intake selects on a phone. The
   requirement therefore prescribes a method that settles scenarios 1 and 2 and is
   structurally incapable of settling scenario 3.

   *Its final clause asserts as fact what the change elsewhere records as unconfirmed.*
   Line 82 reads "AND declaring the viewport correctly moves every such screen to its
   narrow-width branch **on real devices**". `proposal.md:118-121` says the opposite about
   the same claim: "The change is believed to be a strict improvement ... but 'believed' is
   the honest word until on-device re-triage confirms it. That re-triage is pending".
   `tasks.md:206-208` carries the same pending item. A THEN clause asserts an established
   outcome. Archive merges all three files into an `openspec/specs/` tree this change is
   bootstrapping from empty, so it would write a spec that states as verified the one thing
   the proposal is careful to mark unverified.

   Why this is CRITICAL and not a warning: the decision gate is that a spec scenario with
   no passing covering test is CRITICAL `UNTESTED`, and `openspec/config.yaml` grants no
   manual-verification allowance. More concretely, marking it COMPLIANT on the strength of
   the 900px and 1000px samples in `situation_breakpoints_test.dart` would repeat the exact
   error the previous report identified as CRITICAL-1: inferring production behavior from
   widget tests that inject `physicalSize`. Those samples prove the Sala selects its wide
   branch at 900 and 1000; they say nothing about what a browser reports, and they would
   pass identically with the meta deleted. Recording that as coverage would be the third
   consecutive verification to call a scenario COMPLIANT while its production claim went
   unchecked.

   This is the same defect family Phase 8 itself named in task 8.5, a spec scenario with
   no passing covering test, caught for the zoom scenario and missed for this one.

   **Cheapest close (artifact-only, no code change, no test change):** demote scenario 3 to
   requirement prose. It introduces no MUST that scenarios 1 and 2 do not already carry;
   its content is explanatory scoping, and the requirement body already says that the
   precondition is shared by every screen consuming `Breakpoints` and is not
   intake-specific. Deleting the `#### Scenario:` heading and folding the two clauses into
   that sentence closes the blocker outright. If it is kept as a scenario, it must be
   narrowed to its testable core (at a reported width near 980 the Sala selects
   `_DesktopBody`, which `situation_breakpoints_test.dart` can cover directly with a 980px
   sample) and its "on real devices" clause reworded to match the proposal's
   pending-re-triage language rather than contradict it.

**WARNING**

1. **Form rows stack across the whole 1024-1199px desktop band, still untested and still
   absent from the proposal.** **OPEN**, unchanged, as anticipated. Arithmetic re-verified
   at HEAD: the desktop form column is `width - 260 - 380`
   (`intake_workspace_screen.dart:58,250`) minus `EdgeInsets.all(20)` per side (`:269`), so
   available row width reaches `formRowStack` 520 only at `width >= 1200`. Across 1024-1199
   every intake form row renders stacked while the three-pane layout is active.
   `design.md:9` anticipates it, so it is intended, not a defect.
   `intake_desktop_layout_test.dart:35` declares `const _desktopSize = Size(1440, 900)` and
   it remains the sole viewport in that file, so the band stays uncovered, and the "Desktop
   Three-Pane Layout Unchanged" requirement still reads as though desktop rendering is
   untouched.
2. **`isExpanded: true` changes desktop dropdowns cosmetically with no test.** OPEN,
   unchanged. `basic_data_section.dart:46,84`. Known and accepted.
3. **Apply phase never emitted the prescribed TDD Cycle Evidence table.** OPEN, partly
   moot. The `apply-progress` artifact is now five phases stale (Engram #446 stops at Phase
   3); Phases 4-8 evidence lives in `tasks.md` and was reproduced independently for Phases
   6, 7 and 8 across this run and the previous one.
4. **Delivered size exceeds the accepted exception, and widened again.** OPEN, worse.
   `git diff --shortstat ca9acc6 HEAD` is now 25 files, 2322 insertions, 238 deletions =
   2560 changed lines against a 1000-line session budget, up from 2309. Phase 8 contributed
   120 lines, of which 97 are artifact text and 23 are test code. Not a defect and not a
   blocker, but recorded because the figure keeps drifting from the number the exception
   was granted against.
5. **Scenario "All six sections reachable at 360px" is still only statically evidenced.**
   OPEN, unchanged. Re-confirmed this run: `kCaseFormSections` appears only in
   `intake_form_widget_test.dart`, inside that test's own harness tree, and nowhere in
   `intake_narrow_layout_test.dart`. PARTIAL in the matrix.
6. **No test layer exercises the app in a real browser; on-device re-triage still pending.**
   OPEN, and now load-bearing. This gap was a WARNING in the previous report; Phase 8 made
   it heavier by writing a spec scenario whose THEN asserts precisely the real-device
   outcome that no layer here observes. It is the direct cause of CRITICAL-1's third defect.
   Closing CRITICAL-1 by rewording does not close this; only the pending on-device re-triage
   does.

**SUGGESTION**

1. **The workspace-level narrow test uses 360x780; the spec says 360x640.** OPEN,
   unchanged. `intake_narrow_layout_test.dart:39`.
2. **`home_page.dart:57` still contains the literals 320.0 and 362.0.** OPEN, unchanged.
   Panel widths, not width comparisons, so the spec wording is satisfied.
3. **The proposal Success Criteria checklist is unchecked.** **CLOSED.** Five ticked, the
   sixth deliberately unticked and struck through with a written correction. Resolved
   exactly as prescribed, and resolved honestly.
4. **The 260 and 380 pane widths are magic literals in production.** OPEN, unchanged.
   `intake_workspace_screen.dart:58,250`.
5. **The 336px D4 test asserts no rendered content.** OPEN, unchanged.
   `intake_narrow_layout_test.dart:353`.
6. **The Phase 6 pinning test aborts on its first mismatch.** OPEN, unchanged, and now
   observed a second time: the Phase 8 zoom test has the same shape (probe 1b was needed
   precisely because of it). Splitting multi-assertion guards into one `test` per assertion
   would make both diagnostics complete. Neither guard is unsound.
7. **The Sala is never pumped at 360px.** OPEN, unchanged. Now cheaper to justify than
   before: narrowing CRITICAL-1's scenario 3 to its testable core would want a Sala sample
   near 980 anyway, and a 360px sample alongside it would close this at the same time.
8. **NEW: the zoom guard misses `user-scalable=0`.** Probe 1c injected `user-scalable=0`,
   which browsers treat the same as `user-scalable=no`, and all three tests stayed green.
   The test is faithful to its scenario, which says the content contains neither
   `maximum-scale` nor `user-scalable=no`, so the under-specification is in the scenario's
   wording. Asserting on the `user-scalable` key regardless of value would close both.
9. **NEW: `tasks.md`'s carried-forward gaps list contradicts Phase 8.** `tasks.md:202`
   still reads that the proposal Success Criteria checklist is unchecked, which task 8.4
   made false in the same commit. A one-line stale entry, but it sits in an artifact about
   to be archived permanently.

### Verdict

**FAIL.** Both declared commands are green (168/168 tests, clean analyze), the working tree
is clean, Phase 8 changed no `lib/` and no `web/` file exactly as it claims, and **no
product defect exists anywhere in this change**. Both previous blockers are genuinely
closed: the host-document requirement is present, correctly placed, honestly reasoned and
non-vacuously tested on two of its three scenarios; the Sala correction is recorded without
the criterion being re-worded to make it true, which was the right call and is explicitly
ruled non-blocking above. Phase 8's self-caught zoom gap is real work, and its test is
stronger than the evidence Phase 8 offered for it.

The single blocker is that the remediation's third scenario is not a verifiable acceptance
criterion. It cannot enter its own GIVEN, its requirement's mandated verification method
cannot settle it, and its final clause states as an established outcome the very real-device
result that `proposal.md:118-121` and `tasks.md:206-208` both record as pending. Archive
would write that contradiction permanently into an `openspec/specs/` tree bootstrapped from
empty.

`blockers` is reported as 1, not 0. It is closable with an artifact-only edit of a few
lines, deleting one `#### Scenario:` heading and folding its content into the requirement
prose that already says the same thing, and it needs no code change, no test change and no
re-run of any earlier phase.
