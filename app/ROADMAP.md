# Roadmap

## Phase 0 - Decisions
- SwiftUI menu-bar app (macOS native).
- Runtimes: llama.cpp for Phi-1.5, RWKV runtime for RWKV-430M.
- Model storage: `~/Library/Application Support/RightKey/Models`.

## Workflow
- Push changes to https://github.com/M47HIS/Small-AI-assistant- as soon as possible.

## Phase 1 - Desktop MVP
- Global hotkey listener (customizable).
- Top-right chat bar UI with settings icon.
- First-run model download flow.
- Context collector: clipboard + frontmost app title.
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
