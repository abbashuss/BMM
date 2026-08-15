# Operations

Production-like Windows startup will use Task Scheduler scripts under `scripts/windows/`, with restart-on-failure and loopback bindings. Those scripts are a Phase 8 deliverable; no global startup or power settings are changed in Phase 0.

Operational order is: database directory, internal engines, FastAPI health, then Tailscale Serve. Failures go to rotating files under `data/logs/` without secrets.

Sleep prevents the PC from serving a phone. The operator must explicitly choose an appropriate Windows power policy; installers must not change it silently.

