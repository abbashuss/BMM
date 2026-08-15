# Dependency baseline

Verified: 2026-08-15 against primary project documentation and registries.

## Selected pins

- React and React DOM: 19.2.7. React documents 19.2 as the current line; the project keeps the verified patch from the master specification snapshot.
- Vite: 8.1.5. Vite 8.2 was released during Phase 0; 8.1 remains supported for important/security fixes and avoids a same-day minor upgrade.
- FastAPI: 0.141.1, the latest entry in official release notes at verification time.
- Pydantic: 2.13.4, stable; 2.14 was pre-release.
- SQLAlchemy: 2.0.51 is the stable line reserved for Phase 2; 2.1 was beta.
- Python app support: 3.12–3.13. Phase 0 passed on CPython 3.13.14.
- Node.js: 22.17.0 detected, satisfying Vite's Node 22.12+ requirement.
- pnpm: 11.21.0 through Corepack; uv: 0.12.5 local executable.

## Primary references

- React versions: https://react.dev/versions
- Vite releases/support: https://vite.dev/releases
- Vite npm package: https://www.npmjs.com/package/vite
- FastAPI release notes: https://fastapi.tiangolo.com/release-notes/
- Pydantic package releases: https://pypi.org/project/pydantic/
- SQLAlchemy package releases: https://pypi.org/project/SQLAlchemy/
- ComfyUI documentation: https://docs.comfy.org/
- Ollama structured outputs: https://docs.ollama.com/capabilities/structured-outputs
- Tailscale Serve: https://tailscale.com/docs/features/tailscale-serve

Engine versions are not pinned until Phase 1 proves installation and compatibility on the target machine. This avoids recording an untested inference stack as operational.
