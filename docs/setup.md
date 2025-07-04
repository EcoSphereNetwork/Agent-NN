# Setup Guide

Dieser Leitfaden beschreibt die Installation von Agent-NN Schritt für Schritt.

## \ud83d\udd27 Schnelles Setup
```bash
# Voraussetzung: Docker, Node.js, Python 3.10+, Poetry
git clone https://github.com/EcoSphereNetwork/Agent-NN
cd Agent-NN
./scripts/setup.sh
```

Das Skript wurde unter Ubuntu, macOS und Windows/WSL getestet.

## Vorbereitung

* Node.js 18+
* Docker mit Docker Compose
* Python 3.10+
* [Poetry](https://python-poetry.org/)

Kopiere die Datei `.env.example` zu `.env` und passe Werte wie Ports oder Tokens an.

## Python / Poetry

```bash
poetry install
```

Die CLI steht anschließend über `poetry run agentnn` bereit.

## Frontend bauen

```bash
./scripts/deploy/build_frontend.sh
```

Die statischen Dateien landen in `frontend/dist/`.

## Dienste starten

```bash
./scripts/deploy/start_services.sh --build
```

Die Container laufen im Hintergrund. Beende sie mit `docker compose down`.

### Docker Compose vs. lokal

Alle Services lassen sich auch direkt mit `docker compose up` starten. Für eine rein lokale Ausführung müssen Redis und Postgres installiert sein.
Bei älteren Docker-Versionen heißt der Befehl `docker-compose`. Stelle sicher, dass das Compose-Plugin installiert ist oder verwende den Legacy-Befehl.

## Umgebungsvariablen

Alle benötigten Variablen sind in `.env.example` dokumentiert. Kopiere diese Datei nach `.env` und passe sie an deine Umgebung an.

## FAQ

**Fehler `unknown flag: -d`**
: Stelle sicher, dass `docker compose` statt `docker` verwendet wird und deine Docker-Version aktuell ist.

**Ports bereits belegt**
: Passe die Ports in `.env` an oder stoppe den blockierenden Dienst.

**Dienste starten nicht**
: Prüfe mit `docker ps`, ob die Container laufen. F\u00fchre `npm run build` im Frontend aus und nutze `poetry shell` f\u00fcr weitere Python-Befehle.

