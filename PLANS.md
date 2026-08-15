# Execution plan

Updated: 2026-08-15

## Plan record format

Every phase records: Goal, Context, Files, Implementation steps, Validation commands, Acceptance criteria, Risks, and Result. A phase advances only when its gate is green; unavailable hardware checks are recorded as blocked.

## Phase 0 — repository and verification (complete)

**Goal:** Establish a reproducible, documented monorepo with passing scaffold checks.

**Context:** The remote repository was empty. The master specification is the product source of truth. The target is Windows, Arabic RTL-first, local compute, and 6 GB VRAM.

**Files:** Root policy/config files, `docs/`, `backend/`, `frontend/`, `config/`, `workflows/`, `tests/`, and `scripts/windows/`.

**Implementation steps:**

1. Import the master specification and write durable repository rules.
2. Verify current stable dependency lines against primary sources.
3. Scaffold FastAPI and React/Vite with tests, lint, and type checks.
4. Document architecture, development, security, and operations.
5. Run all locally available Phase 0 checks and record blockers.

**Validation commands:** See `docs/DEVELOPMENT.md`.

**Acceptance criteria:** Dependency lockfiles exist; no secrets are tracked; backend and frontend scaffold checks pass; documentation describes architecture and current environment truthfully.

**Risks:** Python 3.12 and `uv` are not currently installed; GPU tools and engine executables are not visible in PATH; the target engines cannot be smoke-tested during Phase 0.

**Result:** Complete on 2026-08-15. Backend lint, format, strict mypy, pytest, and a live loopback health request passed. Frontend peer checks, ESLint, TypeScript, Vitest, and production build passed. Dependency lockfiles were generated. Hardware/engine checks remain correctly deferred to Phase 1 because their executables are unavailable.

## Phase 1 — engine smoke tests (blocked on target hardware)

**Goal:** Prove actual GPU, ComfyUI API-workflow, stable-diffusion.cpp, and memory behavior on the target machine.

**Result:** Blocked on 2026-08-15. Windows diagnostics on the current machine report only Intel Iris Xe Graphics (128 MB dedicated memory, driver 31.0.101.5334). No NVIDIA device, `nvidia-smi`, Ollama, Tailscale, ComfyUI, stable-diffusion.cpp process, or expected engine listener was found. Real RTX 3060 smoke tests must run on the intended home AI server.

**Acceptance criteria:** Real commands and observations are recorded in `docs/BENCHMARKS_LOCAL.md`; unavailable components remain explicitly blocked.

## Phase 2 — backend core and durable JobManager (pending)

Implement migrations, SQLite WAL, state transitions, fake provider, cancellation, recovery, and app-level events.

## Phase 3 — structured local LLM router (pending)

Implement Ollama structured output, Arabic routing tests, immediate unload, validation retry, and deterministic fallback.

## Phase 4 — Arabic React chat UI (pending)

Implement conversations, composer, upload, local/cloud choice, progress, cancellation, reconnect, and PWA shell.

## Phases 5–10 (pending)

Follow `MASTER_BUILD_SPEC.md`: early Tailscale/mobile testing, real providers, editing/gallery, operations, optional cloud, then optional Tauri.
