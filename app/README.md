# RightKey

Menu-bar macOS hotkey assistant with tiny local models. It opens a top-right chat bar, streams responses, and uses clipboard + frontmost app context. Only one model is loaded at a time, and it unloads after idle to keep RAM near-zero.

## Goals
- Global hotkey opens a minimal UI overlay.
- Local LLM with fast cold-start and low idle memory.
- Safe access to user data via clipboard + app context.

## Non-goals (for MVP)
- Cloud inference.
- Full browser automation.
- Deep filesystem indexing.

## MVP Scope
- Menu-bar app with customizable hotkey.
- Top-right chat bar with model dropdown + settings.
- First-run model download flow.
- Context capture: clipboard + frontmost app name.

## Models
- Built-in catalog: Phi-1.5 Q4, TinyLlama 1.1B Q4, Phi-1.5 HF base (auto-converted).
- Managed from Preferences (download, use, delete).
- Stored at `~/Library/Application Support/RightKey/Models`.
- Only one model loaded in RAM at a time.

## Runtime
- Requires the `llama.cpp` CLI (`llama-cli` or `llama`) on your PATH.
- Install: `brew install llama.cpp` or set `LLAMA_BIN` to the CLI path.
- You can also set the binary path in Preferences.
- Hugging Face downloads may require `HF_TOKEN` if the model is gated.
- Conversion requires `convert_hf_to_gguf.py` and `llama-quantize` (from llama.cpp).
- Set `LLAMA_CONVERT_PATH` or `LLAMA_QUANTIZE_BIN` if they are not auto-detected.
- Set `PYTHON_BIN` to a python3 with transformers/torch/safetensors installed.
- For best performance, enable the persistent server and GPU layers in Preferences.

## Architecture Sketch
- Hotkey manager -> overlay controller.
- Context collector -> prompt builder.
- Model manager -> runtime backend -> response stream.
- Chat bar UI -> response display + preferences.

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

## Status
- Llama.cpp GGUF flow + HF conversion are supported; RWKV is not yet integrated.

## Security & Privacy
- Local inference only.
- Explicit access to clipboard and app context.
- No background indexing without consent.
