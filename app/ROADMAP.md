# Roadmap

## Phase 0 - Product Decisions
- SwiftUI menu-bar app (macOS native).
- Two runtime modes:
  - `Privacy Mode`: local model inference.
  - `Cloud Mode`: user-supplied provider/API credentials.
- Users must be able to switch modes any time in Preferences.
- No browser automation and no deep filesystem indexing.
- Local OCR/vision context collection for screen-aware answers.
- Runtimes: llama.cpp for local mode.
- Model storage: `~/Library/Application Support/RightKey/Models`.

## Workflow
- Push changes to https://github.com/M47HIS/Small-AI-assistant- as soon as possible.

## Phase 1 - Desktop Core (Current)
- Global hotkey listener (customizable).
- Top-right chat bar UI with settings icon.
- First-run model download flow.
- Context collector: clipboard + frontmost app title.
- Model switching with single-model-in-RAM rule.
- Idle unload after 90s.

## Phase 2 - Mode System (Priority)
- First-run mode choice (`Privacy Mode` vs `Cloud Mode`).
- Preferences mode switcher with clear active-state indicator.
- Provider configuration UI (OpenAI/ChatGPT, Gemini, extensible adapters).
- Local secure credential storage and validation.

## Phase 3 - OCR/Screen Intelligence (Priority)
- Real-time on-screen OCR/vision capture pipeline (local processing).
- Source selection: active screen/window/region.
- Prompt fusion: OCR text + app metadata + user prompt.
- Real-time suggestion engine from OCR/app context.
- Capture controls: explicit enable, quick pause, visible capture status.

## Phase 4 - Reliability
- Telemetry-free diagnostics.
- Crash recovery + safe mode.
- OCR and mode-switch performance profiling.
- Local-vs-cloud behavior tests and benchmarks.
