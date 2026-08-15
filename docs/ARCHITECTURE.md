# Architecture

## System boundary

The Windows PC is the home AI server. React is a disconnectable client; FastAPI owns application state. Ollama, ComfyUI, stable-diffusion.cpp, and SQLite remain behind the application boundary and bind to loopback.

## Runtime flow

1. The client sends an Arabic message to the versioned application API.
2. The router converts it to a validated typed intent and unloads immediately.
3. The JobManager persists the request before dispatch.
4. The ResourceCoordinator serializes local GPU-heavy work.
5. The ProviderRouter selects a provider and compute-target configuration; local is default.
6. Provider progress is normalized into app events and persisted.
7. Storage saves the original, checksum, thumbnail, and metadata before completion.
8. Reconnecting clients rebuild state from the server, never browser memory.

## Module boundaries

- `backend/app/api`: versioned HTTP/WebSocket boundary and Pydantic contracts.
- `backend/app/services`: jobs, routing, resources, events, and storage policies.
- `backend/app/providers`: small protocol plus Comfy and sd.cpp implementations.
- `backend/app/registries`: model/workflow metadata and compatibility.
- `frontend/src/features`: chat, jobs, gallery, models, and settings.
- `config` and `workflows`: versioned declarative registries and API-format workflows.

## Invariants

- Local GPU concurrency is one image job until measurements justify otherwise.
- Cloud is a compute target configuration, disabled by default, never an automatic fallback.
- Application job IDs and database records are authoritative.
- Workflow mutation uses unique stable `_meta.title` values, never unscoped numeric IDs.
- Large image bytes never live in SQLite.

