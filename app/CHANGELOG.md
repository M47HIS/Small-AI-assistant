# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - Unreleased
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
