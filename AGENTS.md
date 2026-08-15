# Repository rules

- Read `MASTER_BUILD_SPEC.md` and `PLANS.md` before architectural work.
- Backend checks: `uv run ruff check .`, `uv run mypy app`, and `uv run pytest` from `backend/`.
- Frontend checks: `pnpm lint`, `pnpm typecheck`, `pnpm test`, and `pnpm build` from `frontend/`.
- Never expose Ollama, ComfyUI, stable-diffusion.cpp, SQLite, or internal admin endpoints publicly.
- Local compute is the default. Paid cloud compute may never activate or receive a request automatically.
- Jobs and progress are server-owned and must survive client disconnects.
- ComfyUI workflows use API format and stable `_meta.title` contracts.
- Record architecture changes in `docs/adr/` before implementation.
- Never commit secrets, user data, generated images, or model binaries.
- Do not claim hardware or engine checks passed unless they ran on the target machine.

