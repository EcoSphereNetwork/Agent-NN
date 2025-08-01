# TODO-Liste für Agent-NN Entwicklungsplan

## Phase 1: Codebase-Konsolidierung & Architektur-Refaktor

### 1.1 Architektur-Grundlagen
- [x] Legacy-Code identifizieren und Struktur vorbereiten: Alte Module analysieren und in `archive/` verschieben.
- [x] ModelContext-Datentyp definieren: zentralen Typ für Modell- und Kontextinformationen erstellen.
- [x] Grundservices als Microservices anlegen: Dispatcher-, Registry-, Session-Manager-, Vector-Store- und LLM-Gateway-Service.
- [x] Docker-Umgebung einrichten: `docker-compose.yml` für alle Services.
- [x] Ersten End-to-End-Test durchführen: Dummy-Request über alle Services schleusen.

### 1.2 Kernservices & Kontext-Integration
- [x] MCP-SDK integrieren & Basis-Routing implementieren.
- [x] LLM-Gateway-Anbindung umsetzen.
- [x] VectorStore-Service integrieren.
- [x] Session-Manager mit persistentem Kontext.

### 1.3 Infrastruktur & Sicherheit
- [x] Monitoring- und Logging-Infrastruktur einführen.
- [x] Sicherheits-Layer implementieren.
- [x] Persistente Speicherpfade & Konfiguration festlegen.

### 1.4 Entwickler-Tools & Release-Vorbereitung
- [x] Developer-SDK und CLI bereitstellen.
- [x] Erste Beta-Release vorbereiten.

## Phase 2: Feature-Integration & Harmonisierung

### 2.1 Meta-Learning-Integration
- [x] MetaLearner aktivieren.
- [x] AutoTrainer und Feedback-Schleife implementieren.
- [x] Capability-basiertes Routing prototypisieren.
- [x] Evaluationsmetriken sammeln.

### 2.2 LLM-Provider-Integration & konfigurierbare KI
- [x] Provider-System erweitern.
- [x] Dynamische Konfiguration über `llm_config.yaml`.
- [x] SDK-Beispiele und Tests hinzufügen.
- [x] OpenHands API Anbindung produktiv aktivieren.

### 2.3 System-Harmonisierung & Legacy-Migration
- [x] Bestehende Funktionen angleichen.
- [x] Konsistenz und Abwärtskompatibilität prüfen.
- [x] Legacy-Code schrittweise stilllegen.

### 2.6 Feature-Konsolidierung
- [x] Gemeinsame Module in `core/` überführt.
- [x] Konfigurationsvalidierung implementiert.

## Phase 3: Konsolidiertes Frontend & User Experience

### 3.1 Vollständige Frontend-Implementierung
- [x] Alle UI-Seiten/Panels fertigstellen.
- [x] Frontend mit Backend-APIs verbinden.
- [x] Einheitliche Benutzeroberfläche konsolidieren.

### 3.2 UX-Optimierungen
- [x] Authentifizierungs-Flow verbessern.
- [x] Fehlerbehandlung und Ladeindikatoren.
- [x] Responsive Design & Dark-Mode sicherstellen.
- [x] Zugänglichkeit (Accessibility) erhöhen.
- [x] Formularvalidierung und Usability verbessern.
- [x] (Optional) Erweiterte UI-Funktionen integrieren.

## Phase 4: Testabdeckung, CI/CD und Dokumentation

### 4.1 Testabdeckung & CI-Pipeline
- [x] Umfassende Test-Suite entwickeln.
- [x] Regressionsprüfung & Bugfixing.
- [x] Continuous Integration einrichten.
- [x] Qualitätsmetriken beobachten.

### 4.2 Deployment & Dokumentation
- [x] Deployment-Skripte finalisieren.
- [x] Dokumentation aktualisieren.
- [x] SDK- und API-Dokumentation ergänzen.
- [x] Abschließender Usability-Test.
- [x] Release-Vorbereitung.
- [x] Legacy-Code endgültig archivieren.
