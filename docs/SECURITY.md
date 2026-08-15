# Security

- Bind FastAPI and every engine to `127.0.0.1` unless an ADR documents otherwise.
- Expose only the application through Tailscale Serve over HTTPS.
- Validate exact Tailscale identity at the app boundary; do not treat network membership alone as authorization.
- Keep secrets in `.env`, never frontend code, logs, or Git.
- Decode and validate uploaded images, enforce MIME/size limits, generate server filenames, and reject traversal.
- Use same-origin production delivery, strict CORS in development, and PWA security headers.
- Cloud credentials stay server-side; cloud compute is disabled and cannot auto-fallback.

