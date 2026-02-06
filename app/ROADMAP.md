# Roadmap

## Phase 0 - Decisions
- SwiftUI menu-bar app (macOS native).
- Privacy-first: local-only inference with on-device models.
- Runtimes: llama.cpp (current) for Phi-1.5; RWKV runtime planned for RWKV-430M.
- Model storage: `~/Library/Application Support/RightKey/Models` (override via `RIGHTKEY_MODELS_DIR`).

## Workflow
- Push changes to https://github.com/M47HIS/Small-AI-assistant- as soon as possible.

## Phase 1 - Desktop MVP
- Global hotkey listener (customizable).
- Top-right chat bar UI with model dropdown + settings.
- Overlay stays above the current app for quick interaction.
- First-run model download flow.
- Context collector: clipboard + frontmost app name/title.
- Model switching with single-model-in-RAM rule.
- Idle unload after 90s.

## Phase 2 - Interaction
- Prompt templates for task types.
- Streaming responses + cancel.
- Quick actions (copy, paste, re-run).

## Phase 3 - Reliability
- Telemetry-free diagnostics.
- Crash recovery + safe mode.
- Performance profiling and model benchmarks.
