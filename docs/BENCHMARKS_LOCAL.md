# Local benchmarks

No benchmark has been run yet.

Initial inspection on 2026-08-15 could not find `nvidia-smi`, Ollama, Tailscale, ComfyUI, or stable-diffusion.cpp in PATH. No expected engine port (`11434`, `8188`, or `7861`) was listening.

Windows `dxdiag` and Plug and Play diagnostics reported:

- GPU: Intel(R) Iris(R) Xe Graphics
- Dedicated display memory: 128 MB
- Shared/display memory reported by Windows: 8147 MB
- Driver: 31.0.101.5334, dated 2024-03-05
- NVIDIA device: not detected

This is not the specified RTX 3060 6 GB target. GPU/model smoke tests are therefore **blocked**, not failed. They must run on the intended home AI server and record actual model, quantization, resolution, steps, time, peak VRAM/RAM, and status.
