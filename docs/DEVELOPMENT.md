# Development

## Prerequisites

- Node.js 22.12 or newer (22.17.0 was detected).
- pnpm 11 through Corepack.
- Python 3.12 or 3.13; Python 3.13.14 was detected.
- uv (not detected during initial inspection).

## Backend

From `backend/`:

```powershell
uv sync --locked
uv run ruff check .
uv run ruff format --check .
uv run mypy app
uv run pytest
uv run fastapi dev app/main.py --host 127.0.0.1
```

## Frontend

From `frontend/`:

```powershell
pnpm install --frozen-lockfile
pnpm lint
pnpm typecheck
pnpm test
pnpm build
pnpm dev --host 127.0.0.1
```

Never bind internal engines to a LAN address for convenience. Use the application API and documented private remote-access layer.

