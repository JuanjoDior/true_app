```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:8f5b63ea02099fcf9e1553b6402d9d91a9e76a4d2c3442d2cb46c79f6ed1ed3a
verdict: pass_with_warnings
blockers: 0
critical_findings: 0
requirements: 23/23
scenarios: 48/48
test_command: flutter test
test_exit_code: 0
test_output_hash: sha256:60bc0b967a6af2e2377647353e7c410739e26b424f16599fe4de7ff63b0a7b02
build_command: flutter analyze
build_exit_code: 0
build_output_hash: sha256:20c2cf748f904218a476c70dcbbecc936e63023edd53cb075b8cb04cbc5ebf73
```

## Verification Report (re-verification after remediation)

**Change**: case-publication-detail
**Version**: N/A (OpenSpec delta specs, 4 capabilities)
**Mode**: Strict TDD
**HEAD**: 645334ce49fd8ab4d73bea0453c805f3245e76fe (working tree clean)
**Deployed SHA**: 89cb790f2a26d31b8821b3bc00af4cc6449997de (Pages run 31833902940, success)
**Supersedes**: the FAIL report at evidence_revision sha256:1aef29ff... (3 CRITICAL, 3 blockers)

### Executive Position

All three CRITICAL blockers are closed, and closed correctly. I did not take the remediation
report on trust: I re-ran both mutation probes myself, and both reproduce exactly as claimed.
Every requirement and every scenario now carries passing runtime evidence. Remaining items are
declared deviations and known gaps that archive must carry forward, not defects.

### Remediation Verification (independent)

The decisive check was reproducing the falsifiability probes rather than accepting them.

**Probe P1 - inject NeverScrollableScrollPhysics into CaseDetailPage's SingleChildScrollView.**
Result: exactly 2 tests fail, and both fail on the *reachability* assertion rather than the
precondition.

```text
lectura en cualquier pantalla scrolling brings the end of the dossier into view [E]
  Expected: a value less than <780>
    Actual: <3467.0>
lectura en escritorio a long case still scrolls on a desktop window [E]
  Expected: a value less than <900.0>
    Actual: <1697.0>
```

The content did not move at all under a dead scroll - which is precisely what the old
position.jumpTo implementation would have hidden, because forcePixels moves the viewport
without consulting physics. Probe reverted.

**Probe P2 - inject NeverScrollableScrollPhysics into the directory's ListView.builder.**
Result: exactly 1 test fails.

```text
lectura de una lista larga dragging reaches a case near the end of a long archive [E]
  Expected: exactly one matching candidate
    Actual: _TextWidgetFinder:<Found 0 widgets with text "Caso 0": []>
```

Probe reverted; `git diff --quiet` confirmed clean afterwards, and the full suite re-run on the
restored tree returned 477/477 exit 0.

This contrast is the evidence that matters. These three tests can now fail for the right
reason, which is the property the previous report found missing.

**Scope check**: commit 645334c touches 0 files under lib/. The claim "test-only, no production
source changed" is verified, not assumed.

### The C-3 precondition reasoning: CONFIRMED CORRECT

The coordinator asked for this to be checked rather than accepted, which is the right instinct.
The reasoning holds, and the asymmetry is real:

- **Directory - `expect(last, findsNothing)` is honest.** `ListView.builder` builds lazily
  through `SliverChildBuilderDelegate`. `shrinkWrap: true` does not defeat this: the
  shrink-wrapping viewport is still bounded by the parent's `maxHeight`, so children are built
  only within the paint extent plus cache extent. Row 60 of 60 genuinely is not built, so its
  absence carries information. Probe P2 confirms it empirically: under a dead scroll the row is
  still never built after 40 real drags.
- **Dossier - the same line would be inadmissible.** `SingleChildScrollView` lays out its single
  child against an unbounded main-axis constraint, so every descendant exists regardless of
  scroll offset. There `findsNothing` would not discriminate, which is why the position-based
  `getRect(end).top > viewportHeight` precondition is the correct one. tasks.md 7.3 already
  records discovering exactly this.

Same words, opposite meaning, depending on the widget. The two helpers correctly diverge.

### Helper design review

Both `_dragUntilVisible` (bounded at 20 drags) and `_dragUntilFound` (bounded at 40) are
correctly built: **neither helper asserts**. They return silently on exhaustion and let the
*caller* assert afterwards. That is the right split - a dead scroll exhausts the loop and then
fails on a clear expectation, rather than hanging or swallowing the failure. Both probes
confirm this behaviour in practice. The desktop scroll test correctly passes
`viewportHeight: desktop.height` rather than inheriting the 780 default.

### Completeness

| Metric | Value |
|--------|-------|
| Tasks total | 131 |
| Tasks complete | 120 |
| Tasks incomplete | 11 |
| of which deliberate rollback checkpoints (RB.0-RB.9) | 10 |
| of which declared verification gaps (9.10) | 1 |
| Genuinely pending implementation work | 0 |

### Build & Tests Execution

**Build/Analysis**: PASSED

```text
$ flutter analyze
No issues found! (ran in 1.4s)    # exit 0
```

**Tests**: PASSED - 477 passed, 0 failed, 0 skipped (was 472; +5 from remediation)

```text
$ flutter test
00:11 +477: All tests passed!     # exit 0
```

**Coverage**: not available - no coverage tool configured. Skipped, not a failure.

### Spec Compliance Matrix - changes since the FAIL report

The 45 scenarios that were COMPLIANT previously were re-confirmed by the 477/477 run and are
unchanged; their evidence is unchanged from evidence_revision sha256:1aef29ff. Only the three
previously non-compliant rows are restated here.

| Capability | Requirement | Scenario | Test | Previous | Now |
|---|---|---|---|---|---|
| expanded-case-dossier | Expanded Reading Experience Across Supported Layouts | Expanded dossier is usable on mobile | case_detail_page_test.dart > scrolling brings the end of the dossier into view, via _dragUntilVisible (real tester.dragFrom) | PARTIAL | COMPLIANT - position-based arrival precondition retained; actuation is now a real gesture; killed by probe P1 |
| expanded-case-dossier | Expanded Reading Experience Across Supported Layouts | Expanded dossier is usable on desktop | case_detail_page_test.dart > lectura en escritorio (4 tests at Size(1440, 900)): no overflow, bounded reading column, a long case still scrolls on a desktop window, return action reachable | UNTESTED | COMPLIANT - overflow precondition asserted against desktop.height, real gesture, killed by probe P1 |
| published-case-directory | Mobile and Desktop Directory Access | Mobile reader opens the directory | case_directory_test.dart > dragging reaches a case near the end of a long archive, via _dragUntilFound (real tester.dragFrom) | PARTIAL | COMPLIANT - ListView.builder-appropriate absence precondition, real gesture, reachability asserted, killed by probe P2 |

**Compliance summary**: 48/48 scenarios compliant, 0 partial, 0 untested.

| Capability | Reqs | Scenarios |
|---|---|---|
| case-editorial-chapters | 7/7 | 16/16 |
| case-publication-route | 5/5 | 11/11 |
| expanded-case-dossier | 6/6 | 14/14 |
| published-case-directory | 5/5 | 7/7 |

### Bonus coverage gained

`the reading column is bounded, not stretched to the window` asserts that the detail-panel width
is strictly less than the 1440px window. This pins a max-width reading decision that **nothing
previously asserted** and that could have regressed silently. It was not required to close any
CRITICAL; it is a genuine addition.

### Correctness (Static Evidence)

Unchanged from the previous report: all 23 requirements implemented. No production source was
modified by the remediation, so no correctness row changes.

### Coherence (Design)

Unchanged from the previous report, with two rows worth restating because archive must carry
them forward:

| Decision | Followed? | Notes |
|---|---|---|
| Unit 7 at or below 1500 changed lines | VIOLATED, declared | 1,566 measured. Reason recorded: last indivisible seam |
| Unit 9 changes zero source (9.12) | VIOLATED, declared | The deep-link fix changed source; Unit 7 formally reopened by 9.12's own rule |

The remediation did not touch production source, so it does not reopen any further unit.

### TDD Compliance

| Check | Result | Details |
|---|---|---|
| TDD Evidence reported | PASS | Per-unit RED/GREEN rows plus mutation-probe tables; new Remediation section at tasks.md:529 |
| All tasks have tests | PASS | Every source-bearing unit names its test file |
| RED confirmed (tests exist) | PASS | All named test files exist on disk |
| GREEN confirmed (tests pass) | PASS | 477/477 re-executed this session on a confirmed-clean tree, exit 0 |
| Triangulation adequate | PASS | Unit 7 probes renumbered R1-R4 with an explicit note that no fifth probe ever existed; remediation probes P1/P2 independently reproduced by verify |
| Safety Net for modified files | PASS | Characterization tests preceded the 4a-2 extraction |

**TDD Compliance**: 6/6 checks passed.

### Assertion Quality

| File | Line | Assertion | Issue | Severity |
|---|---|---|---|---|
| test/case_detail_page_test.dart | 450 | expect(tester.takeException(), isNull) | Absence-of-exception only; supplements a companion test that asserts content | WARNING |
| test/case_directory_test.dart | 325 | expect(tester.takeException(), isNull) | Same | WARNING |

The two CRITICAL rows from the previous report are resolved: position.jumpTo no longer appears
anywhere in the suite (it survives only inside explanatory comments in both helpers, documenting
why it is banned), and the directory's bare maxScrollExtent assertion now has a companion test
that asserts reachability through a real gesture.

No tautologies, no orphan empty-collection assertions, no ghost loops, no mock-heavy files and
no smoke-test-only files were found.

**Assertion quality**: 0 CRITICAL, 2 WARNING.

### Quality Metrics

**Linter/Analyzer**: PASS - flutter analyze, No issues found!, exit 0.
**Type Checker**: PASS - Dart analysis is the type check; clean.

### Issues Found

**CRITICAL**: None. All three prior blockers verified closed by independent probe.

**WARNING** (all declared, none new; archive must carry them forward)

- **W-1 - Task 9.10 remains unchecked, correctly.** Compact-mobile was never verified in-browser
  because resize_window does not reach the Flutter viewport (window.innerWidth stays 1920). The
  new desktop group at 1440x900 does **not** close this gap and the row does not claim it does -
  it still reads "Coverage for compact comes from automated tests at 500px and 360px only".
  Verified as accurately recorded and not silently resolved.
- **W-2 - Two entry-point clicks remain widget-test-only.** The top-bar directory button and the
  detail page's return action could not be actuated by coordinate against the Flutter canvas.
  Task 9.13 still states this, still declines to claim browser verification, and still does not
  claim them broken. Verified as accurately recorded.
- **W-3 - Unit 7 exceeded the 1500-line ceiling (1,566).** Declared with reasoning.
- **W-4 - Unit 7 is formally reopened by task 9.12.** The Unit 9 deep-link fix changed source
  during a zero-source unit. Archive must not close Unit 7 as though 9.12 had been met.
- **W-5 - initialLocation remains a production-visible test-only parameter.** Correctly defaulted
  (null selects the platform provider) and guarded by a paired presence/absence test, which is
  the right mitigation. It remains the seam that once hid a production defect.

Resolved since the previous report: the uncommitted tasks.md working-tree warning (now committed
in 645334c), the stale nine-versus-eleven commit count in task 9.1, the false clean-tree claim in
that same row, and the Unit 7 probe table skipping R4. Each correction is stated in place rather
than silently overwritten, which is the right way to amend an evidence record.

**SUGGESTION**

- **S-1** - `_dragUntilFound` proves the target was *built*, not strictly that it is *visible*;
  a ListView row is built within roughly 250px of cache extent. Combined with the real drag this
  is sound proof of reach, but the assertion could be tightened to also check
  getRect(last).top < viewportHeight, matching the dossier helper's strictness.
- **S-2** - Consider one automated browser check (for example Playwright against the deployed
  hash route) so the two un-actuatable entry-point clicks and the compact-mobile gap in 9.10 gain
  a repeatable proof instead of remaining permanent declared gaps.
- **S-3** - The out-of-scope createDraft millisecond-collision defect
  (DateTime.now().millisecondsSinceEpoch used as draftId) remains recorded in PROJECT_CONTEXT.md
  under Pendiente. Correctly not fixed here.
- **S-4** - expect(tester.takeException(), isNull) appears as the sole assertion in two layout
  tests. A reasonable overflow guard, but not evidence that anything rendered.

### Verdict

**PASS WITH RECOMMENDATIONS** - 0 blockers, 0 CRITICAL findings.

The change is archive-ready. All 23 requirements and all 48 scenarios carry passing runtime
evidence; 477/477 tests pass and the analyzer is clean on a verified-clean tree at 645334c.

The remediation deserves its verdict for a specific reason: it did not merely make three tests
greener, it made them *capable of failing*. I confirmed that myself by injecting dead scroll
physics into both hosts and watching exactly the three intended tests fall over - two in the
dossier, one in the directory - while everything else stayed green. Under the previous jumpTo
implementation those same probes passed. That contrast, not the passing suite, is the evidence.

The remaining WARNINGs are all pre-declared gaps and accepted deviations. Two of them - the
unchecked 9.10 and the two un-actuatable clicks - were specifically checked this round and are
still recorded honestly rather than quietly absorbed into the new desktop coverage.
