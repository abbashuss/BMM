# ADR-0002: Conservative dependency baseline

Status: Accepted — 2026-08-15

## Problem

The Vite 8.2 line became stable during Phase 0, while the verified specification baseline used the 8.1 line.

## Options

Adopt 8.2.0 immediately, stay on an older major, or pin the supported 8.1.5 patch and evaluate 8.2 after scaffold tests mature.

## Decision

Pin Vite 8.1.5 for Phase 0. Pin React 19.2.7 and FastAPI 0.141.1. Use lockfiles and review upgrades deliberately.

## Consequences

The frontend avoids a same-day toolchain change while staying on a supported security-maintenance line. A later Vite 8.2 upgrade needs normal lint, test, and build gates.

## Migration impact

No application migration is needed; only toolchain validation.
