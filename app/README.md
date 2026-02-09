# RightKey

Menu-bar macOS hotkey assistant with tiny local models plus optional cloud AI providers. It opens a top-right chat bar, streams responses, and uses OCR/app context to answer directly from what is on screen.

## Product Goals
- Global hotkey opens a minimal UI overlay.
- First-run mode selection: privacy-focused local mode or cloud-connected mode.
- Better answers from local context, including real-time on-screen OCR/vision context.
- Allow users to switch modes at any time in Preferences.

## Modes
- `Privacy Mode (Local)`:
  - Inference runs with local models only.
  - Network usage limited to model downloads and optional updates.
- `Cloud Mode (BYO Provider)`:
  - User connects their own provider/API key (for example ChatGPT/OpenAI or Gemini).
  - OCR text + app context are sent to the selected provider to generate responses.
  - RightKey remains the interface; users do not need to paste screenshots into provider web UIs.

## Permanent Constraints
- No hidden cloud relay.
- No provider lock-in (user controls provider and credentials).
- No browser automation features.
- No deep filesystem indexing/background crawling.

## Current Scope (Implemented)
- Menu-bar app with customizable hotkey.
- Top-right chat bar with model dropdown + settings.
- First-run model download flow.
- Context capture: clipboard + frontmost app name/title.
- Model switching with single-model-in-RAM behavior.
- Idle unload after 90 seconds.

## Next Scope (Priority)
- Mode selector on onboarding (`Privacy Mode` vs `Cloud Mode`).
- Mode switcher in Preferences with safe runtime transition.
- Real-time on-screen context capture (OCR/vision), processed locally.
- Prompt enrichment from OCR text + current app context.
- Provider adapters and key management for cloud mode.
- Real-time suggestions from OCR/app context in the overlay.

## Models
- Built-in catalog: Phi-1.5 Q4, TinyLlama 1.1B Q4, Phi-1.5 HF base (auto-converted).
- Managed from Preferences (download, use, delete).
- Stored at `~/Library/Application Support/RightKey/Models`.
- Only one local model loaded in RAM at a time.

## Runtime
- Requires the `llama.cpp` CLI (`llama-cli` or `llama`) on your PATH.
- Install: `brew install llama.cpp` or set `LLAMA_BIN` to the CLI path.
- You can also set the binary path in Preferences.
- Hugging Face downloads may require `HF_TOKEN` if the model is gated.
- Conversion requires `convert_hf_to_gguf.py` and `llama-quantize` (from llama.cpp).
- Set `LLAMA_CONVERT_PATH` or `LLAMA_QUANTIZE_BIN` if auto-detection fails.
- Set `PYTHON_BIN` to a python3 with transformers/torch/safetensors installed.
- For best performance, enable the persistent server and GPU layers in Preferences.

## Architecture Sketch
- Hotkey manager -> overlay controller.
- Context collector (clipboard/app/ocr) -> prompt builder.
- Mode router (local/cloud) -> runtime backend -> response stream.
- Chat bar UI -> response display + preferences.

## Memory Strategy
- Load local model on demand, unload after 90s idle.
- One active local model at a time.
- Small context window and conservative batch sizes.

## Usage
- Default hotkey: Option+Space (customizable in Preferences).
- Use Preferences to manage model/provider settings and switch modes.

## Setup
- Open `Package.swift` in Xcode 15+ and run the app.
- Tests: `swift test`.

## Status
- llama.cpp GGUF flow + HF conversion are supported.
- Mode selector, cloud-provider integration, and OCR/vision capture are planned and prioritized.

## Security & Privacy
- Privacy mode keeps inference local.
- Cloud mode is explicit and user-configured.
- Context capture is user-scoped and should run only while assistant capture is active.
- No deep filesystem indexing.
