# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - Unreleased
- Documentation update: product now specifies two user-selectable modes (`Privacy Mode` and `Cloud Mode`).
- Documentation update: users can switch modes at runtime from Preferences.
- Documentation update: cloud mode uses user-provided provider/API credentials (for example ChatGPT/OpenAI or Gemini).
- Documentation update: OCR/vision-based screen context and real-time suggestions are prioritized capabilities.
- Documentation update: browser automation and deep filesystem indexing remain out of scope.
- Added RightKey SwiftUI menu-bar scaffold and overlay chat bar.
- Added settings, preferences UI, and hotkey capture.
- Added model metadata, downloader, and prompt builder stubs.
- Added basic tests for settings and prompt assembly.
- Wired Phi-1.5 responses through llama.cpp CLI with streaming output.
- Added runtime and generation controls (binary path, max tokens, temperature, top-p).
- Improved model download flow with size validation, status, and optional HF token support.
- Added persistent llama-server mode with GPU layer controls to reduce load time.
- Added a simple model catalog UI with HF downloads and auto-conversion to GGUF.
- Store downloaded models in Application Support.
