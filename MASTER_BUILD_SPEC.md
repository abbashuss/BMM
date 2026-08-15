# Private AI Studio
## Master Build Specification + Coding-Agent Execution Contract

**Verified baseline date:** 2026-08-15  
**Primary target:** Windows PC, NVIDIA RTX 3060 6 GB VRAM, 16 GB system RAM, Intel 13th-gen CPU  
**Primary UI language:** Arabic, RTL-first  
**Primary use:** Private, self-hosted AI image generation/editing app accessible from PC and phone  
**Default compute:** Local GPU, no paid generation service required  
**Optional compute:** User-selected cloud GPU only; never automatic  
**Intended coding agents:** OpenAI Codex / GPT-5.6 Sol, Claude Code, or another strong repo-editing coding agent

---

# 0. Read This First — Agent Operating Contract

You are the principal engineer responsible for implementing this repository.

Do **not** treat this document as a one-shot prompt. Treat it as the product specification, architecture contract, implementation plan seed, and acceptance rubric.

Before changing code:

1. Read this entire file.
2. Inspect the current repository and machine environment.
3. Verify the current stable versions and official documentation for any dependency that may have changed since **2026-08-15**.
4. Create:
   - `AGENTS.md` — short, durable repo rules only.
   - `PLANS.md` — execution-plan format and current multi-phase plan.
   - `docs/ARCHITECTURE.md`
   - `docs/DECISIONS.md` or ADRs.
   - `docs/DEVELOPMENT.md`
   - `docs/OPERATIONS.md`
5. Create a baseline git commit if the repository is already under git and the working tree is clean.
6. Implement incrementally. Do not attempt the entire system in one uncontrolled pass.
7. After every phase:
   - run tests,
   - run lint/type checks,
   - run a smoke test,
   - update the plan,
   - summarize what changed and remaining risks.
8. Never claim “zero bugs.” The goal is **high confidence through tests, validation, observability, rollback paths, and minimal architecture drift**.
9. Never invent a successful result. If a GPU/model/tool is unavailable, mark the test as blocked and explain exactly why.
10. Do not silently change the architecture in this document. If a change is genuinely better, record it in an ADR with:
    - problem,
    - options,
    - decision,
    - consequences,
    - migration impact.
11. Do not expose ComfyUI, Ollama, stable-diffusion.cpp, SQLite, or an internal admin endpoint directly to the public internet.
12. Do not add a paid cloud dependency to the default path.
13. Never activate paid cloud compute automatically. It must require an explicit user action.
14. Keep the MVP maintainable. Prefer boring, well-tested code over clever abstractions.

---

# 1. Product Goal

Build a private AI image application with a conversation-style experience similar to modern chat applications.

The user should be able to:

- open the app from a Windows PC or Android phone;
- type requests naturally in Arabic;
- generate images locally;
- upload an image and request an edit;
- see progress;
- close the browser or lock the phone without losing the job;
- reopen the app and resume viewing active/completed jobs;
- browse chat history and a fast image gallery;
- choose between supported local models;
- optionally choose a cloud GPU later;
- use the local path without per-image API fees;
- keep the AI engines hidden behind a clean app UI.

The phone is a **remote client**. The Windows PC is the **home AI server**.

---

# 2. Non-Goals for MVP

Do not add these to the initial MVP unless required by another section:

- public multi-user SaaS;
- subscriptions or billing;
- automatic cloud provisioning;
- payment processing;
- social features;
- public sharing links;
- complex RBAC;
- Kubernetes;
- microservices;
- Redis/Celery unless measurements prove they are necessary;
- PostgreSQL unless local SQLite becomes a demonstrated limitation;
- Tauri native packaging before the PWA is stable;
- training/fine-tuning models;
- automatic downloading of arbitrary third-party models without explicit user approval.

---

# 3. Verified Technology Baseline — 2026-08-15

The implementation must re-check official sources before pinning versions, but the following is the verified baseline as of this specification date.

| Component | Verified baseline | Project decision |
|---|---:|---|
| React | 19.2 | Use React + TypeScript |
| Vite | 8.1 | Use Vite for frontend build |
| FastAPI | 0.141.1 | Use FastAPI for local application API |
| ComfyUI | 0.33.1 | Main visual-AI workflow engine |
| Tauri | 2.11.x ecosystem | Optional after PWA is stable |
| Tailscale | current stable | Private remote access |
| Ollama | current stable | Local LLM router/runtime |
| Qwen | Qwen3.5 2B/4B available | Local intent/prompt router |
| stable-diffusion.cpp | current master/release | Low-VRAM inference provider |
| SQLite | current stable | App state DB, WAL mode |

Do not blindly install “latest” without compatibility checks. Resolve current stable compatible versions, then **pin/lock them**.

Frontend must have a lockfile. Backend must have a reproducible lock strategy.

Recommended:
- JS package manager: `pnpm`
- Python environment/package manager: `uv`
- Python runtime for the app backend: Python 3.12 unless current compatibility testing shows a better supported version.
- Keep ComfyUI's Python/runtime isolated from the FastAPI backend environment.

---

# 4. Hardware Reality

Primary machine:

```text
GPU: NVIDIA RTX 3060
VRAM: 6 GB
System RAM: 16 GB
CPU: Intel 13th generation
OS: Windows
```

This constraint is architectural, not cosmetic.

Do not design as if 12 GB or 24 GB VRAM is available.

Requirements:

1. Preserve GPU VRAM for image generation.
2. The local routing LLM must not remain resident in GPU memory while an image job runs.
3. Prefer the router LLM on CPU or ensure it is unloaded before image inference.
4. Use low-VRAM model variants/quantization where appropriate.
5. Maintain model capability metadata so the app can warn before starting an incompatible configuration.
6. Expose a resource state such as:
   - `idle`
   - `routing`
   - `unloading_llm`
   - `loading_image_model`
   - `generating`
   - `releasing_vram`
7. Never freeze the UI while a model is loading.

---

# 5. Final Architecture

```text
                     ┌─────────────────────────┐
                     │  Phone / Windows Client │
                     │ React + TS + PWA        │
                     │ Arabic RTL-first        │
                     └────────────┬────────────┘
                                  │ HTTPS
                                  │ Tailscale Serve
                                  ▼
                     ┌─────────────────────────┐
                     │ FastAPI App             │
                     │ 127.0.0.1 only          │
                     └────────────┬────────────┘
                                  │
          ┌───────────────────────┼────────────────────────┐
          │                       │                        │
          ▼                       ▼                        ▼
 ┌────────────────┐     ┌──────────────────┐     ┌─────────────────┐
 │ LLM Router     │     │ Job Manager      │     │ Gallery/Storage │
 │ Ollama         │     │ SQLite WAL       │     │ thumbs + full   │
 │ Qwen3.5 2B/4B │     │ server-owned     │     │ metadata        │
 └───────┬────────┘     └────────┬─────────┘     └─────────────────┘
         │                       │
         └──────────────┬────────┘
                        ▼
              ┌──────────────────────┐
              │ Workflow Registry    │
              │ + Model Registry     │
              │ + Resource Manager   │
              └──────────┬───────────┘
                         │
                 ┌───────┴────────┐
                 │ ProviderRouter │
                 └───┬─────────┬──┘
                     │         │
          ┌──────────▼──┐   ┌──▼────────────────┐
          │ ComfyProvider│   │ SdCppProvider     │
          │             │   │ stable-diffusion │
          │ base_url    │   │ .cpp / GGUF      │
          └──────┬──────┘   └────────┬──────────┘
                 │                   │
        ┌────────┴────────┐          │
        │                 │          │
 Local ComfyUI      Optional Cloud   │
 127.0.0.1:8188     Comfy-compatible │
        │                 │          │
        └──────────┬──────┴──────────┘
                   ▼
             RTX 3060 6 GB
             (local default)
```

---

# 6. Correct Abstractions

## 6.1 Do NOT model Local and Cloud as separate AI engines

They are **compute targets**.

Correct:

```python
ComfyProvider(base_url="http://127.0.0.1:8188")
ComfyProvider(base_url="https://optional-cloud-comfy.example")
```

Incorrect:

```text
LocalEngine
CloudEngine
ComfyEngine
```

unless they truly have different protocols.

## 6.2 Providers

Create a small interface:

```python
class InferenceProvider(Protocol):
    async def health(self) -> ProviderHealth: ...
    async def submit(self, request: InferenceRequest) -> ProviderJob: ...
    async def cancel(self, provider_job_id: str) -> bool: ...
    async def get_job(self, provider_job_id: str) -> ProviderJobStatus: ...
    async def release_resources(self) -> None: ...
```

Implement:

- `ComfyProvider`
- `SdCppProvider`

Cloud is configuration for a provider, not a separate engine class.

## 6.3 Keep interfaces small

Do not create an enterprise abstraction hierarchy before it has two real implementations.

---

# 7. LLM Router

Without this layer, a “chat UI” is only a prompt box.

Use a small local LLM to convert natural language into a typed command.

Default candidate:
- `qwen3.5:2b`

Optional:
- `qwen3.5:4b`

Choose the smallest model that passes routing tests on Arabic.

The router performs:

1. intent classification;
2. Arabic → model-friendly prompt normalization/translation when useful;
3. parameter extraction;
4. short clarification-free interpretation using sensible defaults;
5. chat context summarization relevant to image operations.

Supported intent schema:

```json
{
  "intent": "generate_image | edit_image | variation | upscale | describe | app_help",
  "original_text": "...",
  "normalized_prompt": "...",
  "negative_prompt": null,
  "width": 768,
  "height": 768,
  "count": 1,
  "model_preference": "auto",
  "style": null,
  "seed": null,
  "source_image_ids": [],
  "requires_image": false
}
```

Use **Ollama structured outputs / JSON schema**, not “please return JSON” string parsing.

Validate the response with Pydantic.

If validation fails:
1. retry once with the validation errors;
2. fall back to deterministic defaults;
3. record the router error in logs.

Resource rule:

- set Ollama `keep_alive: 0` after the router result so the model unloads immediately;
- verify memory is released before a GPU-heavy image task begins;
- the app must not assume the router can coexist in VRAM with image inference.

The router must never silently activate paid cloud compute.

---

# 8. Resource Coordinator

Create an explicit `ResourceCoordinator`.

Responsibilities:

- prevent simultaneous local jobs that exceed memory;
- serialize GPU-heavy local jobs by default;
- allow low-cost CPU tasks concurrently when safe;
- unload the router LLM before image generation;
- release ComfyUI VRAM when switching heavy model families if supported;
- expose state to the UI;
- avoid thrashing between models.

Initial policy:

```text
Local GPU concurrency: 1 image job
LLM routing: complete first, then unload
Cloud jobs: separate queue/limit if added later
```

Do not attempt parallel local image generation on a 6 GB card in MVP.

---

# 9. Model Registry

Do not hard-code models in UI components.

Create a registry with records like:

```yaml
id: z-image-turbo-gguf-q4
display_name: Z-Image Turbo Q4
family: z-image
provider: sdcpp
local_supported: true
recommended: true
tasks:
  - text_to_image
quantization: Q4_0
estimated_vram_gb: 4.0
estimated_ram_gb: 8.0
default_width: 768
default_height: 768
max_safe_width_local: 1024
requires_cloud: false
license_name: Apache-2.0
source: official-or-approved
workflow_id: null
```

For Comfy models, add `workflow_id`.

The registry must support:

- compatibility check;
- installed/not installed;
- file existence;
- model hash;
- model version/source revision;
- task support;
- expected VRAM/RAM;
- load state;
- recommended settings.

The UI must show:

```text
Recommended
Local — Fast
Local — Slow
Cloud recommended
Not installed
Incompatible
```

Do not present estimates as guaranteed measurements.

---

# 10. Initial Local Image Strategy

Because the machine has 6 GB VRAM:

## Primary low-VRAM path

Use `stable-diffusion.cpp` with a supported quantized image model, initially:

- Z-Image Turbo GGUF Q4_0 or Q3_K, after current official compatibility verification.

The official stable-diffusion.cpp documentation has demonstrated Z-Image operation around 4 GB VRAM with quantized weights.

## Main workflow path

Use ComfyUI for:

- models that fit;
- editing workflows;
- workflows that need multiple nodes;
- future models;
- optional cloud compute.

Do not force every model through one provider if another provider is materially better on 6 GB.

---

# 11. ComfyUI Contract

Verified baseline: ComfyUI `v0.33.1` as of 2026-08-13.

Treat ComfyUI as an internal service.

Default:

```text
http://127.0.0.1:8188
```

Do not expose it directly to LAN/public internet in the production setup.

## 11.1 Workflows

Workflows submitted programmatically **must use ComfyUI API format**.

Create/edit a workflow in the UI, then:

```text
File → Export Workflow (API)
```

Store exported API workflows in:

```text
workflows/comfy/
```

Never depend on visual workflow-save JSON for API submission.

## 11.2 Node references

Do not mutate workflows through brittle numeric node IDs alone.

Every app-controlled node must have a stable `_meta.title`.

Use explicit titles:

```text
APP_PROMPT
APP_NEGATIVE_PROMPT
APP_WIDTH
APP_HEIGHT
APP_SEED
APP_MODEL
APP_INPUT_IMAGE
APP_SAVE
```

The workflow adapter searches by `_meta.title`.

At startup/tests:
- assert each required title exists exactly once;
- fail with a clear error if a workflow contract is broken.

## 11.3 Prompt IDs / Job IDs

Generate the app job UUID before submission.

When current ComfyUI supports supplying `prompt_id`, use the same UUID where practical.

The app DB remains source of truth for application metadata.

## 11.4 Job API

Feature-detect current ComfyUI endpoints.

Current verified versions include job cancellation endpoints:

```text
POST /api/jobs/{job_id}/cancel
POST /api/jobs/cancel
```

Prefer current job APIs when available.

Do not implement obsolete interrupt/queue logic as the only path.

If supporting older ComfyUI is desired, add a tested compatibility adapter, not scattered conditionals.

## 11.5 WebSocket

The backend maintains the ComfyUI WebSocket connection.

Do not make each phone/browser client connect directly to ComfyUI.

The backend:

1. connects to ComfyUI using a stable backend `client_id`;
2. receives progress/execution events;
3. maps them to app jobs;
4. updates server-side job state;
5. fans events out to connected frontend clients.

Implement reconnect with exponential backoff and jitter.

On reconnect:
- query active jobs;
- reconcile local DB with provider state;
- never silently mark a job “failed” solely because WebSocket disconnected.

---

# 12. Job Manager — Source of Truth

This is core infrastructure.

The browser is **not** the source of truth.

A phone may:
- switch Wi-Fi/4G;
- sleep;
- kill the browser tab;
- disconnect from Tailscale.

The generation must continue.

## 12.1 Job states

Use an enum:

```text
queued
routing
preparing
waiting_for_resources
loading_model
running
saving
completed
failed
cancel_requested
cancelled
```

## 12.2 Required persisted fields

```text
id
conversation_id
message_id
intent
status
progress
status_message
provider
compute_target
provider_job_id
model_id
workflow_id
workflow_version
original_prompt
normalized_prompt
negative_prompt
seed
width
height
steps
sampler
scheduler
source_image_ids
output_image_ids
error_code
error_message
created_at
queued_at
started_at
finished_at
cancel_requested_at
metadata_json
```

## 12.3 Recovery

At backend startup:

1. load jobs left in non-terminal states;
2. query provider state;
3. reconcile;
4. mark truly orphaned jobs explicitly;
5. preserve outputs if they exist.

Never discard a completed provider output because the frontend was offline.

---

# 13. Database

Use SQLite for MVP.

Enable WAL immediately.

At startup/migration:

```sql
PRAGMA journal_mode=WAL;
PRAGMA foreign_keys=ON;
```

Use SQLAlchemy 2.x + Alembic.

Do not use `create_all()` as the long-term migration system.

Suggested tables:

```text
conversations
messages
jobs
images
models
workflows
app_settings
audit_events
```

Do **not** add a full users table for the private single-user MVP unless there is a demonstrated need.

---

# 14. Image Storage

Do not store large image binaries inside SQLite.

Directory structure:

```text
data/
  db/
    app.sqlite3
  uploads/
  originals/
    YYYY/
      MM/
  thumbnails/
    YYYY/
      MM/
  temp/
  logs/
```

For each saved output:

1. save original;
2. compute checksum;
3. create WebP thumbnail;
4. write DB metadata;
5. only then mark the job complete.

Thumbnail recommendation:

```text
max dimension: 512 px
format: WebP
quality: ~75–85
```

Use thumbnails in:
- gallery;
- conversation history previews;
- mobile lists.

Load the full original only when opened/downloaded.

Metadata per image:

```text
id
job_id
file_path
thumbnail_path
mime_type
width
height
file_size
sha256
seed
model_id
model_hash
workflow_id
workflow_version
original_prompt
normalized_prompt
negative_prompt
generation_parameters_json
created_at
```

Reproducibility requires more than the seed.

---

# 15. Backend API

Use versioned endpoints:

```text
/api/v1/...
```

Minimum contract:

```text
GET    /api/v1/health
GET    /api/v1/system
GET    /api/v1/capabilities

GET    /api/v1/models
GET    /api/v1/models/{id}

GET    /api/v1/conversations
POST   /api/v1/conversations
GET    /api/v1/conversations/{id}
DELETE /api/v1/conversations/{id}

POST   /api/v1/messages

POST   /api/v1/uploads
GET    /api/v1/images/{id}
GET    /api/v1/images/{id}/thumbnail
GET    /api/v1/images/{id}/original

POST   /api/v1/jobs
GET    /api/v1/jobs
GET    /api/v1/jobs/{id}
POST   /api/v1/jobs/{id}/cancel

GET    /api/v1/gallery

WS     /api/v1/events
```

The public app API must be documented through OpenAPI.

Use Pydantic request/response models.

Avoid leaking provider-specific response structures to the frontend.

---

# 16. Event Protocol

Frontend event messages must be app-level, not raw ComfyUI messages.

Example:

```json
{
  "type": "job.progress",
  "job_id": "uuid",
  "status": "running",
  "progress": 0.62,
  "message": "Generating image",
  "updated_at": "2026-08-15T13:30:00+03:00"
}
```

Other event types:

```text
job.created
job.updated
job.progress
job.completed
job.failed
job.cancelled
engine.health
resource.state
model.loading
model.loaded
server.notice
```

On frontend reconnect:

1. reconnect event socket;
2. call `GET /api/v1/jobs?active=true`;
3. reconcile UI state;
4. fetch missed terminal jobs.

The event stream is an optimization; REST state is authoritative.

---

# 17. Frontend

Stack:

- React 19.2 baseline
- TypeScript strict mode
- Vite 8.1 baseline
- React Router
- TanStack Query (or equivalent current stable server-state library)
- lightweight local state store only where needed
- PWA support after verifying the current Vite 8-compatible plugin/tooling
- CSS architecture that supports RTL cleanly

Avoid a giant global state store.

## 17.1 Arabic RTL first

Requirements:

- `<html dir="rtl" lang="ar">` by default;
- components must support RTL without one-off hacks;
- English technical values/numbers may remain LTR where appropriate;
- use logical CSS properties (`margin-inline`, `padding-inline`, etc.).

## 17.2 UI

Desktop:

```text
┌───────────────┬────────────────────────────────────────────┐
│ + New Chat    │ Private AI Studio                         │
│ Conversations │                                            │
│ Gallery       │ User message                              │
│ Models        │                                            │
│ Settings      │ Generated image / progress                │
│               │                                            │
│               │ [attach] [prompt................] [send]  │
└───────────────┴────────────────────────────────────────────┘
```

Mobile:
- collapsible navigation;
- input fixed safely above keyboard;
- large tap targets;
- no horizontal overflow;
- original images loaded only on demand.

## 17.3 Generation controls

Default UI stays simple.

Basic:
- prompt;
- attach image;
- model;
- local/cloud target;
- generate.

Advanced drawer:
- width/height;
- seed;
- steps;
- sampler/scheduler if relevant;
- negative prompt if supported.

Do not expose irrelevant controls for a model that does not support them.

---

# 18. PWA

PWA is the first mobile delivery method.

Requirements:

- installable manifest;
- HTTPS production access;
- service worker;
- offline shell for basic navigation;
- do not falsely imply generation works when the home server is offline;
- clear server-online indicator.

Offline behavior:

```text
Server offline
- browse cached UI
- optionally browse cached thumbnails
- generation unavailable
```

Do not cache private full-resolution images indiscriminately in service-worker storage.

---

# 19. Tailscale Remote Access

Use Tailscale for private remote access.

Production flow:

```text
Phone
  ↓ HTTPS
Tailscale Serve
  ↓
FastAPI / frontend on localhost
```

FastAPI should listen on loopback only in the private production configuration.

Example conceptual target:

```text
127.0.0.1:8000
```

Do not use Tailscale Funnel for this private MVP.

## 19.1 Identity

Tailscale Serve can inject identity headers.

The backend must:

1. trust identity headers **only** when the request arrived through the intended local Tailscale proxy path;
2. check the exact allowed Tailscale login/account;
3. reject unexpected identities;
4. never accept a user-supplied spoofed identity header from a directly exposed network path.

Configuration:

```env
AUTH_MODE=tailscale
TAILSCALE_ALLOWED_LOGIN=user@example.com
```

For local development only:

```env
AUTH_MODE=dev-local
```

Dev-local auth must be unavailable when binding beyond loopback.

---

# 20. Cloud Compute — Interface Only in MVP

MVP local generation must work without cloud.

Create the minimal interface necessary for a future cloud ComfyUI target, but do not implement billing/provisioning unless explicitly requested later.

Rules:

- Cloud disabled by default.
- User must explicitly switch from Local to Cloud.
- If cloud is unavailable, no automatic fallback that spends money.
- Before first cloud submission, show the selected target/provider.
- Do not store cloud credentials in frontend code or git.

Future:

```text
Local ComfyUI target
RunPod/Vast/custom target
Comfy Cloud target
```

but only through adapters/configuration.

---

# 21. Security Requirements

1. Bind internal services to loopback unless there is a documented reason not to.
2. Never expose:
   - Ollama,
   - ComfyUI,
   - stable-diffusion.cpp server,
   - SQLite,
   directly to the public internet.
3. Secrets:
   - `.env` ignored by git;
   - `.env.example` contains no real values;
   - no API key in logs;
   - no credential in frontend bundle.
4. Upload validation:
   - allowlisted image MIME types;
   - validate decoded image, not filename only;
   - file-size limit;
   - random server-side filenames;
   - no path traversal.
5. Output paths must be generated server-side.
6. Use strict CORS; ideally same-origin frontend/backend in production.
7. Set security headers appropriate for a PWA.
8. Sanitize filenames and user-visible metadata.
9. Do not render arbitrary HTML from model text.
10. Dependency scanning must be part of release checks.

---

# 22. Windows Reliability

Do not depend only on `Startup` folder batch files.

Provide:

```text
scripts/windows/install_tasks.ps1
scripts/windows/uninstall_tasks.ps1
scripts/windows/start_dev.ps1
scripts/windows/health.ps1
```

Use Windows Task Scheduler (or a justified service manager) for production-like autostart.

Requirements:

- run backend on login/start as appropriate;
- restart on failure;
- start Tailscale through its supported mechanism;
- start ComfyUI;
- start optional local provider services;
- verify dependencies through health checks;
- log startup failures.

Document how to disable Sleep while the machine is serving remotely.

Do not silently change the user's global power settings during install. Provide explicit instructions or an opt-in script.

---

# 23. Observability

Use structured logs.

Each request/job should include:

```text
request_id
job_id
conversation_id
provider
model_id
```

Log levels:
- DEBUG
- INFO
- WARNING
- ERROR

Use rotating files under `data/logs`.

Do not log:
- secrets;
- raw auth tokens;
- full sensitive request headers.

Health response should include:

```json
{
  "app": "ok",
  "database": "ok",
  "comfyui": "ok|offline",
  "sdcpp": "ok|offline",
  "ollama": "ok|offline",
  "gpu": {
    "name": "RTX 3060",
    "vram_total_mb": 6144,
    "vram_free_mb": 0
  }
}
```

GPU metrics may be unavailable; handle that gracefully.

---

# 24. Repository Structure

Target:

```text
private-ai-studio/
│
├── AGENTS.md
├── PLANS.md
├── README.md
├── .env.example
├── .gitignore
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DEVELOPMENT.md
│   ├── OPERATIONS.md
│   ├── SECURITY.md
│   ├── MODEL_REGISTRY.md
│   └── adr/
│
├── frontend/
│   ├── package.json
│   ├── pnpm-lock.yaml
│   ├── vite.config.ts
│   └── src/
│       ├── app/
│       ├── api/
│       ├── components/
│       ├── features/
│       │   ├── chat/
│       │   ├── jobs/
│       │   ├── gallery/
│       │   ├── models/
│       │   └── settings/
│       ├── routes/
│       └── styles/
│
├── backend/
│   ├── pyproject.toml
│   ├── uv.lock
│   ├── alembic.ini
│   ├── alembic/
│   └── app/
│       ├── main.py
│       ├── api/
│       ├── core/
│       ├── db/
│       ├── schemas/
│       ├── services/
│       │   ├── jobs/
│       │   ├── routing/
│       │   ├── storage/
│       │   ├── resources/
│       │   └── events/
│       ├── providers/
│       │   ├── base.py
│       │   ├── comfy.py
│       │   └── sdcpp.py
│       └── registries/
│
├── workflows/
│   └── comfy/
│
├── config/
│   ├── models.yaml
│   └── workflows.yaml
│
├── tests/
│   ├── contract/
│   ├── integration/
│   └── e2e/
│
├── scripts/
│   └── windows/
│
└── data/                 # gitignored
```

---

# 25. Code Quality Rules

## Python

- type hints on public functions;
- Pydantic models at API boundaries;
- SQLAlchemy 2 style;
- async only where it provides real value;
- no blocking model/network call on the event loop;
- `ruff` for lint/format;
- type checker: choose current stable `mypy` or `pyright` and enforce it consistently;
- `pytest`.

## TypeScript

- `strict: true`;
- no routine `any`;
- typed API client generated from OpenAPI if practical;
- ESLint;
- formatter;
- Vitest;
- Testing Library;
- Playwright for E2E.

## General

- no dead code;
- no swallowed exceptions;
- no empty `except`;
- no production TODO placeholders in required paths;
- error messages must be actionable;
- comments explain why, not obvious syntax.

---

# 26. Testing Strategy

A feature is not complete because it “looks right.”

## 26.1 Backend unit tests

Test:
- router schema validation;
- workflow title lookup;
- job state transitions;
- cancellation;
- retry rules;
- filename/path safety;
- thumbnail generation;
- model compatibility rules;
- auth identity validation.

## 26.2 Contract tests

Create fake/mocked provider servers.

Test:
- Comfy submit;
- progress events;
- disconnect/reconnect;
- job cancellation;
- unknown provider job;
- completed job reconciliation;
- old/new Comfy endpoint feature detection.

## 26.3 Integration tests

With local services where available:
- SQLite migrations;
- Ollama structured output;
- ComfyUI API-format workflow smoke test;
- stable-diffusion.cpp smoke test.

Tests requiring the real GPU should be marked separately.

## 26.4 Frontend tests

Test:
- RTL layout;
- job progress;
- reconnect;
- active job restoration;
- offline server notice;
- gallery thumbnail behavior;
- explicit Local/Cloud selection;
- cancellation.

## 26.5 E2E

Playwright:
1. create conversation;
2. submit generation via fake engine;
3. see progress;
4. reload page;
5. job remains active;
6. complete;
7. image appears;
8. gallery shows thumbnail;
9. original opens on demand.

Add a real-engine E2E smoke test that is opt-in.

---

# 27. Job State Machine Invariants

Enforce transitions.

Example:

```text
queued
  → routing
  → preparing
  → waiting_for_resources
  → loading_model
  → running
  → saving
  → completed
```

Failure can happen from non-terminal states:

```text
* → failed
```

Cancellation:

```text
queued/routing/preparing/waiting/loading/running
  → cancel_requested
  → cancelled
```

Never allow:

```text
completed → running
failed → completed
cancelled → running
```

unless creating a new retry job.

A retry is a new job referencing the original.

---

# 28. Workflow Versioning

Every workflow must have:

```text
workflow_id
version
task
provider
required_node_titles
compatible_models
sha256
```

Do not overwrite an in-use workflow silently.

If workflow content changes:
- bump its version;
- preserve version info in jobs/images.

This is necessary for reproducibility.

---

# 29. Model Download Policy

Do not auto-download huge model files without user visibility.

Implement:

- model status;
- source;
- expected download size when known;
- required disk space;
- explicit install action.

Verify licenses before including a model in the default registry.

Record:
- source URL/repository identifier;
- license;
- file hash;
- revision/tag.

The app must remain usable with only installed models.

---

# 30. Performance Rules for 6 GB VRAM

1. Default batch size: 1.
2. Conservative default resolution.
3. Do not preload multiple image model families.
4. Router LLM unloads immediately after routing.
5. Maintain a short model-switch status.
6. Do not advertise 2K as a default local target.
7. Add `safe`, `balanced`, `quality` profiles only after measurement.
8. Benchmark the actual machine and store observations separately from model metadata estimates.

Create:

```text
docs/BENCHMARKS_LOCAL.md
```

Record:
- model;
- quantization;
- resolution;
- steps;
- generation time;
- peak VRAM;
- peak RAM;
- result/status.

Never fabricate benchmark values.

---

# 31. Error UX

User-facing errors must be understandable.

Bad:

```text
CUDA OOM
```

Better:

```text
ذاكرة كرت الشاشة غير كافية لهذا الإعداد.
جرّب دقة أقل أو نموذجًا أخف.
```

Keep technical details available under an expandable debug section.

Map errors into codes:

```text
ENGINE_OFFLINE
MODEL_NOT_INSTALLED
MODEL_INCOMPATIBLE
OUT_OF_VRAM
OUT_OF_RAM
ROUTER_FAILED
WORKFLOW_INVALID
UPLOAD_INVALID
JOB_CANCELLED
STORAGE_FULL
REMOTE_AUTH_FAILED
```

---

# 32. MVP Features

Required:

- [ ] Arabic RTL chat UI
- [ ] create conversation
- [ ] message history
- [ ] local image generation
- [ ] upload image
- [ ] at least one image-edit path when technically supported
- [ ] JobManager persisted in SQLite
- [ ] progress
- [ ] cancel
- [ ] reconnect/resume
- [ ] gallery
- [ ] WebP thumbnails
- [ ] model registry
- [ ] Local compute default
- [ ] Cloud interface disabled by default
- [ ] Tailscale private access
- [ ] Tailscale identity verification
- [ ] PWA installation over HTTPS
- [ ] Windows autostart/restart documentation
- [ ] unit/integration/E2E tests
- [ ] backup/restore instructions
- [ ] logs and health page

---

# 33. Implementation Phases

## Phase 0 — Repo and Verification

Deliver:
- dependency/version verification;
- `AGENTS.md`;
- `PLANS.md`;
- architecture docs;
- project scaffolding;
- lint/test commands;
- `.env.example`.

Gate:
- all empty scaffold tests pass;
- versions are pinned/locked;
- no secrets.

## Phase 1 — Engine Smoke Tests

Verify on the actual machine:

1. GPU visible.
2. ComfyUI starts and health/connectivity works.
3. API-format test workflow can be submitted.
4. stable-diffusion.cpp supported low-VRAM image model runs if installed.
5. measure actual VRAM/RAM behavior.
6. document results.

Do not continue assuming an engine works if it has not passed a smoke test.

## Phase 2 — Backend Core + JobManager

Implement:
- FastAPI;
- SQLite WAL;
- migrations;
- job state machine;
- provider interfaces;
- fake provider;
- cancellation;
- recovery;
- event fan-out.

Gate:
- backend tests pass;
- reload/recovery test passes.

## Phase 3 — LLM Router

Implement:
- Ollama client;
- Qwen3.5 2B default candidate;
- structured output schema;
- Pydantic validation;
- `keep_alive: 0`;
- deterministic fallback.

Gate:
- Arabic routing test suite;
- no malformed JSON escapes into core app.

## Phase 4 — React Chat UI

Implement:
- conversations;
- prompt composer;
- upload;
- model selector;
- local/cloud selector;
- job progress;
- cancel;
- status badges;
- responsive RTL.

Gate:
- frontend unit tests;
- Playwright fake-provider E2E.

## Phase 5 — Tailscale + Mobile Test Early

Implement/document:
- Tailscale Serve;
- HTTPS;
- exact login allowlist;
- loopback backend;
- phone access.

Test:
- Wi-Fi → cellular switch;
- screen off/on;
- page reload during generation;
- reconnect.

Gate:
- job survives all client disconnect tests.

## Phase 6 — Real Generation Integration

Connect frontend/backend to:
- low-VRAM local provider;
- ComfyUI provider.

Add:
- resource coordinator;
- model loading state;
- job progress mapping.

Gate:
- actual image generation from app;
- no direct engine exposure.

## Phase 7 — Image Editing + Gallery

Implement:
- upload validation;
- edit workflow;
- thumbnails;
- originals;
- gallery pagination;
- metadata.

Gate:
- 300 synthetic thumbnail records do not load 300 full-size originals.

## Phase 8 — Resilience / Operations

Implement:
- Task Scheduler scripts;
- restart-on-failure;
- health checks;
- rotating logs;
- backup/restore;
- disk-space warning.

Gate:
- reboot PC;
- services recover;
- phone app becomes available without manually starting dev terminals.

## Phase 9 — Optional Cloud Target

Only after local MVP is stable.

Implement:
- configurable Comfy target;
- credentials server-side;
- explicit user activation;
- no automatic paid fallback.

## Phase 10 — Optional Tauri

Only after PWA is stable and requested.

Reuse the frontend.

Do not fork product logic into a second app.

---

# 34. AGENTS.md Requirements

The coding agent must create a **short** root `AGENTS.md`, not duplicate this whole document.

It should contain only durable rules such as:

```text
- Read MASTER_BUILD_SPEC.md and PLANS.md before architectural work.
- Backend: run `uv run pytest`, lint, type check.
- Frontend: run `pnpm test`, lint, type check, build.
- Never expose internal AI services publicly.
- Local compute is the default; paid cloud cannot activate automatically.
- Job state is server-owned.
- Workflows use API format and stable `_meta.title` app contracts.
- Any architecture change requires an ADR.
- Do not commit secrets or model binaries.
```

Use path-scoped agent instructions only if they materially improve correctness.

---

# 35. PLANS.md Requirements

For multi-hour implementation, maintain an execution plan.

Each phase/task should include:

```text
Goal
Context
Files
Implementation steps
Validation commands
Acceptance criteria
Risks
Result
```

Update it as work progresses.

Do not let a stale plan contradict the repository.

---

# 36. Definition of Done for Every Feature

A feature is done only when:

1. implementation is complete;
2. tests are added;
3. tests pass;
4. type checks pass;
5. lint passes;
6. production build passes;
7. error behavior is tested;
8. docs/config are updated;
9. no secret or machine-specific hardcoded path is committed;
10. no unreviewed TODO remains in the required path.

---

# 37. Release Gate

Before declaring MVP complete, run:

## Backend

```text
lint
format check
type check
unit tests
integration tests
migration from empty DB
migration from previous schema
```

## Frontend

```text
lint
type check
unit tests
production build
Playwright E2E
```

## Security

```text
dependency audit
secret scan
upload validation tests
auth spoof test
path traversal test
```

## Real system

```text
cold boot
local generation
cancel queued job
cancel running job
browser reload mid-job
phone disconnect/reconnect
gallery thumbnail load
original image open
low disk simulation or warning path
engine offline/recovery
```

No release if required gates are red.

---

# 38. Acceptance Scenarios

## Scenario A — Arabic local generation

Given:
- home PC online,
- supported local model installed,
- user authenticated through Tailscale,

When the user writes in Arabic:

```text
اصنع صورة واقعية لسيارة سوداء في شارع ليلي في بغداد
```

Then:
- router produces valid structured intent;
- LLM is unloaded;
- job is persisted;
- image provider runs;
- progress survives page reload;
- result is saved;
- thumbnail is shown;
- full image opens on demand;
- generation uses local compute.

## Scenario B — Phone disconnect

When:
- a generation is running;
- Android kills the browser tab;

Then:
- server job continues;
- reopening the PWA shows the active/completed job correctly.

## Scenario C — Cloud safety

Given:
- Cloud compute is configured but Local is selected,

Then:
- no request may reach cloud.

If Local fails:
- show a local failure;
- offer Cloud as an explicit option;
- do not auto-submit.

## Scenario D — Workflow break

If a Comfy workflow loses the `APP_PROMPT` node title:

Then:
- startup/contract validation reports a clear workflow error;
- no request mutates an arbitrary node ID.

---

# 39. Backup / Restore

Provide an easy documented backup of:

```text
data/db/
data/originals/
data/thumbnails/
config/
workflows/
.env (manual/secure; not included in normal public archive)
```

Do not back up downloaded model weights by default unless the user opts in; they are large and can usually be reinstalled from recorded sources/hashes.

Restore must be tested once before MVP sign-off.

---

# 40. Documentation Deliverables

Required:

```text
README.md
docs/ARCHITECTURE.md
docs/DEVELOPMENT.md
docs/OPERATIONS.md
docs/SECURITY.md
docs/MODELS.md
docs/WORKFLOWS.md
docs/BENCHMARKS_LOCAL.md
docs/REMOTE_ACCESS.md
docs/BACKUP_RESTORE.md
```

`README.md` should be concise.

Operational detail belongs under `docs/`.

---

# 41. Current Source-of-Truth References

Before coding, re-check these official/primary sources because APIs and versions may change.

- OpenAI Codex best practices  
  https://developers.openai.com/codex/learn/best-practices

- OpenAI Codex AGENTS.md  
  https://developers.openai.com/codex/agent-configuration/agents-md

- OpenAI PLANS.md / Exec Plans guidance  
  https://developers.openai.com/cookbook/articles/codex_exec_plans

- Claude Code overview  
  https://docs.anthropic.com/en/docs/claude-code/overview

- Claude Code project memory/instructions  
  https://docs.anthropic.com/en/docs/claude-code/memory

- ComfyUI docs  
  https://docs.comfy.org/

- ComfyUI Workflow API Format  
  https://docs.comfy.org/development/api-development/workflow-api-format

- ComfyUI Server Routes / WebSocket  
  https://docs.comfy.org/development/comfyui-server/comms_routes

- ComfyUI repository / server implementation  
  https://github.com/Comfy-Org/ComfyUI

- stable-diffusion.cpp  
  https://github.com/leejet/stable-diffusion.cpp

- Z-Image low-VRAM guide in stable-diffusion.cpp  
  https://github.com/leejet/stable-diffusion.cpp/blob/master/docs/z_image.md

- Tailscale Serve  
  https://tailscale.com/docs/features/tailscale-serve

- Ollama structured outputs  
  https://docs.ollama.com/capabilities/structured-outputs

- Ollama model lifetime / keep_alive  
  https://docs.ollama.com/faq

- Qwen official repositories  
  https://github.com/QwenLM

- React  
  https://react.dev/

- Vite  
  https://vite.dev/

- FastAPI  
  https://fastapi.tiangolo.com/

- Tauri  
  https://v2.tauri.app/

---

# 42. First Message to the Coding Agent

After placing this file in the repository, give the coding agent this instruction:

> Read `MASTER_BUILD_SPEC.md` completely before editing code. Inspect the repository and local environment. Verify the 2026-08-15 technology baseline against current official documentation. Then create a concise `AGENTS.md`, an execution-oriented `PLANS.md`, and the Phase 0 architecture/development documents. Do not implement the whole product in one pass. Start with Phase 0, run all validations you can run locally, record any blocked hardware/model checks instead of inventing results, and continue phase-by-phase only when the previous gate is green. Preserve the architecture constraints: server-owned jobs, private loopback AI engines, Local compute as default, no automatic paid cloud fallback, API-format ComfyUI workflows, structured local LLM routing, and 6 GB VRAM resource coordination.

---

# 43. Final Engineering Principle

The core product is not “React connected to ComfyUI.”

It is:

```text
A durable private AI application
with persistent server-side jobs,
a natural-language router,
resource-aware inference providers,
versioned workflows/models,
private remote access,
and a frontend that can disconnect safely.
```

Optimize for:
- correctness;
- recoverability;
- privacy;
- low-VRAM practicality;
- maintainability;
- explicit user control over paid compute.

Do not optimize for architectural cleverness.
