# Workflow contracts

Only ComfyUI API-format exports belong in `workflows/comfy/`. Each app-controlled node has one unique `_meta.title`, such as `APP_PROMPT`, `APP_SEED`, and `APP_SAVE`.

Every registry record includes workflow ID, version, task, provider, compatible models, required titles, and SHA-256. Content changes require a version bump; jobs retain the exact version used.

