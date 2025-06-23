# Deployment Guide

This document explains how to run Agent-NN locally and in production.

## System Requirements

- Docker and Docker Compose
- Node.js 18+
- Python 3.9+

## Building the Frontend

Execute:

```bash
./scripts/deploy/build_frontend.sh
```

The compiled files are stored in `frontend/dist/`.

## Starting Services

1. Copy `.env.example` to `.env` and adjust values.
2. Run the startup script:

```bash
./scripts/deploy/start_services.sh
```

All containers are started in the background. Stop them with `docker compose down`.

### Production

Use the same compose file on a server. Ensure ports 8000 and 3000 are available and the `.env` file contains production credentials.

## Volumes and Network

Docker volumes `vector_data` and `postgres_data` keep persistent data. Services communicate on the default Docker network created by Compose.

Environment variables are loaded from `.env`.

## Troubleshooting

- **Port already in use**: Adjust the exposed ports or stop the service occupying the port.
- **Missing environment variables**: Ensure `.env` exists and contains all required entries from `.env.example`.
- **Frontend not updating**: Rebuild using `build_frontend.sh` and restart the services.

