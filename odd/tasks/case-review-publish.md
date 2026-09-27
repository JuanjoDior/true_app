# Case review and publish — ODD

## Objective
Let Iván create cases in his browser and send them for review with one button, and let the developer approve them so they appear on the public site immediately — no files, downloads, commits or deploys per case. Content lives in Supabase; GitHub Pages keeps serving the static app and redeploys only on code changes.

## Context and authority
- Origin: conversation of 2026-09-27. Iván is non-technical, works from home in his own browser, has no fixed publishing rhythm and must never handle files. The developer works from another home, owns code commits and must approve every case before it goes live. Rejections are discussed by phone: no note field in the app.
- Supersedes the file handoff of `odd/tasks/case-auto-publish.md` (branch `case-auto-publish-pr4-dialog-selection`, frozen at the pause note, unpushed). Reuse from `main`: `validateDraft`, `draftToCaseJson`, `caseSlug`/`uniqueCaseSlug`, `CaseDraft` and the intake form. Do not port the batch dialog, merge function or handoff marker unless a task needs them.
- Baseline: branch `case-review-publish` from local `main` `94e5157` (two commits ahead of remote `main` `faec1ee`); `flutter test` 530 passed on 2026-09-27.
- Seams already present: `CasesRepository.getCases()` (`lib/features/cases/data/cases_repository.dart`) and `CaseDraftsStore.loadDrafts/saveDrafts` (`lib/features/cases/data/case_drafts_store.dart`). Supabase implementations plug in behind them; screens should not know about Supabase.
- Hosting: GitHub Pages via `.github/workflows/deploy-pages.yml` with `--base-href "/<repo>/"`. Supabase is called from the browser with the public anon key; **row-level security is the only thing protecting data** and is the highest-risk part of the change.
- Draft photos are URLs (`DraftPhoto.url`), so no Supabase Storage is needed.
- Project conventions: Spanish UI copy, code comments and Conventional Commit messages; this document in English. TDD with `flutter test <paths>` RED→GREEN, `flutter analyze` clean. Work-unit commits with tests; no push, PR or merge without a separate delivery decision.

## Proposed data model (to confirm in CRP-01)
- `cases`: `slug` (pk), `payload jsonb` (the exact case object the app already reads from `cases.json`, stored raw to avoid lossy model round trips), `published_at`, `published_by`. Public read; write only by the reviewer.
- `drafts`: `id` (pk), `owner` (auth user), `payload jsonb` (`CaseDraft.toJson()`), `status` (`draft | in_review | returned | published`), `updated_at`. Read/write by owner while `draft`/`returned`; owner cannot edit while `in_review`; reviewer reads all `in_review` and changes status.
- `reviewers`: user ids allowed to approve (the developer). Approval = upsert into `cases` + set draft `published`, in one database function so it is atomic and enforced server-side.

## Tasks
- [ ] **CRP-01 — Supabase project and security rules.** Developer creates the project (manual, outside the repo). Versioned SQL in `supabase/` for tables, RLS policies and the approve/return functions. Prove each policy against the real project with an anonymous client, Iván's account and the reviewer account (anon can read `cases` only; Iván cannot publish, cannot edit in review, cannot read other owners' drafts). Record the evidence here.
- [ ] **CRP-02 — Public site reads published cases from Supabase.** `SupabaseCasesRepository` behind `CasesRepository`; one-time seed of the 16 current `cases.json` entries. Loading and failure states must not render an empty catalog as if it were real. Map, "El archivo" and `/#/casos/<slug>` keep working.
- [ ] **CRP-03 — Sign-in for the intake.** Invite / magic link with PKCE (`?code=`) so the callback does not collide with `/#/` hash routing; Pages URL with base href registered as redirect. Intake requires a session; visitors never see it.
- [ ] **CRP-04 — Drafts in the cloud.** `SupabaseCaseDraftsStore` behind `CaseDraftsStore` with per-draft saves (current `saveDrafts` writes the whole list — decide whether to change the interface). On Iván's first sign-in, upload drafts already in his browser automatically and keep the local copy until the upload is confirmed.
- [ ] **CRP-05 — Send to review and states for Iván.** "Enviar a revisión" enabled only for valid drafts; list shows Borrador / En revisión / Devuelto / Publicado; in-review drafts are read-only.
- [ ] **CRP-06 — Reviewer inbox.** Pending count, preview rendered with the same dossier visitors see (with a replacement diff when the slug exists), Aprobar (publishes immediately) and Devolver.
- [ ] **CRP-07 — Integration and two-account walkthrough.** Full suite and analyze; real browser on the deployed Pages site with Iván's and the reviewer's accounts from different browsers: create → send → approve → visible to an anonymous visitor; and send → return → edit → resend.
- [ ] **CRP-08 — Delivery.** User decides push/PR strategy and what happens to the frozen case-auto-publish branches.

## Open decisions
- Unpublishing: who can withdraw a published case (reviewer only?) and whether it needs its own button in this change.
- Free-plan pause after 7 days without activity and no downloadable automatic backups: accept, add a periodic export, or pay.
- Whether `assets/data/cases.json` stays as an offline fallback or is removed after the seed.
- Editing a published case: new draft cycle (edit → send → approve) is assumed; confirm.

## Progress / next step
- 2026-09-27: direction agreed with the user; branch and this document created. Next: CRP-01, starting with confirming the data model and the open decisions that affect it.
