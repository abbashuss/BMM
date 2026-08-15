# ADR-0001: Monorepo and runtime boundaries

Status: Accepted — 2026-08-15

## Problem

The product needs a maintainable private application whose browser may disconnect while local inference continues.

## Options

Separate services and repositories; a browser-to-engine integration; or a monorepo with one application API and isolated engine processes.

## Decision

Use a React/FastAPI monorepo. FastAPI owns jobs, storage, authentication, and provider communication. Inference engines remain separate loopback-only processes.

## Consequences

The app can recover jobs independently from clients and replace providers without leaking their protocols. Deployment must supervise multiple local processes.

## Migration impact

None; this establishes the initial boundary.

