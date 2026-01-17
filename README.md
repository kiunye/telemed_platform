# Telemedicine Platform

A secure, scalable, and HIPAA-aligned telemedicine platform built with Elixir, Phoenix, Ash Framework, and Oban.

## Overview

This platform enables patients to discover doctors, book appointments, attend virtual consultations, manage medical records, and handle payments seamlessly. It provides role-based access for patients, doctors, and administrators with comprehensive audit logging for compliance.

## Architecture

This project follows Dave Thomas's multi-app structure:

```
telemed_platform/
├── telemed_core/      # Domain logic (Ash resources, pure functions)
├── telemed_api/       # REST/JSON APIs (Phoenix)
├── telemed_admin/     # Admin & Doctor dashboards (LiveView)
├── telemed_jobs/      # Background jobs (Oban workers)
└── docs/              # Architecture documentation
```

## Tech Stack

- **Elixir** 1.19+ with OTP 27+
- **Ash Framework** 3.13.1 - Declarative domain modeling
- **Oban** 2.17+ - Background job processing
- **Phoenix** 1.8+ - Web framework
- **PostgreSQL** 16+ - Primary database (via Docker)
- **Tailwind CSS** - UI styling (per UI kit specification)

## Getting Started

### Prerequisites

- Elixir 1.19+ and OTP 27+
- Docker and Docker Compose
- Node.js (for asset compilation)

### Setup

1. **Start PostgreSQL**:
   ```bash
   docker-compose up -d
   ```

2. **Create `.env` file** (copy from `.env.example`):
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Install dependencies** (from each app directory):
   ```bash
   cd telemed_core && mix deps.get
   cd ../telemed_api && mix deps.get
   cd ../telemed_admin && mix deps.get
   cd ../telemed_jobs && mix deps.get
   ```

4. **Set up database**:
   ```bash
   cd telemed_core
   mix ecto.create
   mix ecto.migrate
   ```

5. **Start applications**:
   ```bash
   # In separate terminals:
   cd telemed_api && mix phx.server
   cd telemed_admin && mix phx.server
   ```

## Development

### Running Tests

```bash
# From each app directory:
mix test
```

### Code Quality

```bash
# Format code:
mix format

# Run pre-commit checks:
mix precommit
```

## Documentation

See `docs/` directory for comprehensive architecture documentation:
- `docs/architecture/` - System architecture and domain models
- `docs/decisions/` - Architecture Decision Records (ADRs)
- `docs/guardrails/` - Development guardrails and best practices

## Project Status

Currently implementing **Milestone A**: Foundation + Accounts/Auth + Audit

See `.cursor/tasks/tasklist.md` for detailed progress tracking.
