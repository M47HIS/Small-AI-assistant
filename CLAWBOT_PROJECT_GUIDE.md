# Clawbot Project Guide

This file is the operating manual for Clawbot on the **Small AI Assistant / RightKey** project.

## 1) Mission
Build and ship a production-ready macOS hotkey assistant with a tiny local LLM.

Primary product requirements:
- Local-only inference.
- No cloud inference at any point.
- No browser automation features.
- No deep filesystem indexing/background crawling.
- Prioritized next capability: real-time on-screen context capture via OCR/vision (processed locally).

## 2) Repository Layout
- `app/` -> canonical desktop app workspace (Swift package).
- `website/` -> website/marketing assets. Ignore unless explicitly requested.
- `README.md` (repo root) -> pointer file.
- `app/README.md` -> product and technical source of truth for app scope.
- `app/ROADMAP.md` -> delivery phases.
- `app/CHANGELOG.md` -> release notes.
- `AGENTS.md` -> collaboration and quality constraints.

## 3) Mandatory Branching Policy (Non-Negotiable)
For **every user interaction that changes code/docs**, Clawbot MUST:
1. Create a new branch before making changes.
2. Do all iteration and commits only on that branch.
3. Never work directly on `main`.
4. Push the branch after major change sets.

Recommended branch format:
- `clawbot/<short-task-name>-<yyyymmdd-hhmm>`

Example:
- `clawbot/ocr-context-pipeline-20260208-1530`

## 4) Delivery Workflow
For each request:
1. Read relevant files first (`app/README.md`, `app/ROADMAP.md`, impacted code/tests).
2. Keep changes minimal and reversible.
3. Update docs when behavior or scope changes.
4. Add or update tests when behavior changes.
5. Run verification commands before handoff.
6. Commit with clear message and push branch.

## 5) App Build/Test Commands
Run commands from `app/` unless explicitly stated otherwise.

- Build:
  - `swift build`
- Clean + test:
  - `swift package clean && swift test`
- Fast test pass:
  - `swift test`

## 6) Engineering Constraints
- Prefer modular, composable code.
- Avoid heavy dependencies unless justified.
- No secrets in repo.
- Explicit behavior over magic.
- Keep RAM usage tight (single-model-in-RAM strategy + idle unload).

## 7) OCR/Vision Direction (Next Priority)
When implementing screen-aware context:
- Keep processing local.
- Add explicit user-controlled capture toggles.
- Expose visible capture state in UI.
- Restrict capture to active intent/session (no silent background collection).
- Feed OCR/vision context into prompt builder in a bounded, auditable way.

## 8) Definition of Done (Per Change Set)
A change set is done only if:
- Code builds.
- Tests pass.
- Docs are aligned.
- Branch is pushed.
- Summary includes what changed, why, and what was verified.

## 9) Out of Scope Unless Explicitly Requested
- Website work.
- Cloud inference integrations.
- Browser automation features.
- Background filesystem indexing.

