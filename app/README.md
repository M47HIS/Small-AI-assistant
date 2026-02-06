# RightKey

Menu-bar macOS hotkey assistant that runs tiny local models. It opens a top-right chat bar, streams responses, and uses the clipboard plus frontmost app metadata for context. Only one model stays in RAM, and it unloads after idle to keep memory near zero.

## Goals
- Global hotkey opens a minimal overlay.
- Local LLM with fast cold start and low idle memory.
- Context limited to clipboard + frontmost app metadata when the overlay is active.

## MVP Scope
- Menu-bar app with customizable hotkey.
- Top-right chat bar with model dropdown + settings.
- First-run model download flow.
- Context capture: clipboard + frontmost app name/title.
- Overlay can appear above the current app so the user can interact without switching apps.

## Models
- Built-in catalog: Phi-1.5 Q4, TinyLlama 1.1B Q4, Phi-1.5 HF base (auto-converted to GGUF).
- Managed from Preferences (download, use, delete).
- Stored at `~/Library/Application Support/RightKey/Models` by default.
- Override with `RIGHTKEY_MODELS_DIR` (useful for a repo-local cache like `./MODELS`; `~` paths are supported).
- Only one model loaded in RAM at a time.

## Runtime
- Requires the `llama.cpp` CLI (`llama` or `llama-cli`) on your PATH.
- Install: `brew install llama.cpp` or set `LLAMA_BIN` to the CLI path (also configurable in Preferences).
- `LLAMA_BIN` and the Preferences binary path both support `~` expansion.
- Hugging Face downloads may require `HF_TOKEN` if the model is gated.
- HF conversion uses `convert_hf_to_gguf.py` and `llama-quantize` (from llama.cpp).
- Set `LLAMA_CONVERT_PATH` or `LLAMA_QUANTIZE_BIN` if auto-detection fails.
- Set `PYTHON_BIN` to a python3 with transformers/torch/safetensors installed (for conversion).
- For best performance, enable the persistent server and GPU layers in Preferences.
- Invalid persisted tuning values are auto-normalized to safe ranges on startup.

## Architecture Sketch
- Hotkey manager -> overlay controller.
- Context collector -> prompt builder.
- Model manager -> runtime backend -> response stream.
- Chat bar UI -> response display + Preferences.

## Memory Strategy
- Load model on demand, unload after 90s idle.
- One active model at a time (per selection).
- Small context window and conservative batch sizes.

## Usage
- Default hotkey: Option+Space (customizable in Preferences).
- Use the model menu or menu bar item for Preferences.

## Setup
- Open `Package.swift` in Xcode 15+ and run the app.
- Tests: `swift test`.

### Dev note (local models in repo)
- If you keep models in the repo (e.g., `./MODELS`), set `RIGHTKEY_MODELS_DIR` in your Xcode scheme:
  - Product -> Scheme -> Edit Scheme -> Run -> Arguments -> Environment Variables.
  - Example value: `/Users/mathis.naud/Desktop/DEV/Small AI assistant/app/MODELS`.

## Status
- llama.cpp GGUF flow + HF conversion are supported; RWKV is not yet integrated.

## Security & Privacy
- Models are stored and run locally on your Mac; prompts never leave the device.
- Network access is only for downloading models (no cloud inference).
- Clipboard + frontmost app metadata are captured only when the overlay is active.
- No background indexing without consent.
