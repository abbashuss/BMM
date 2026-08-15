# Backup and restore

Back up `data/db/`, `data/originals/`, `data/thumbnails/`, `config/`, and `workflows/`. Handle `.env` separately through a secure manual process. Model weights are excluded by default because registry source revisions and hashes allow reinstalling them.

Restore testing is pending the first database migration and saved image; it is not yet claimed as complete.

