#!/bin/bash
# -*- coding: utf-8 -*-
# Agent-NN Setup Script - Vollständige Installation und Konfiguration

set -euo pipefail

# Skript-Verzeichnis und Helpers laden
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/lib/log_utils.sh"
source "$SCRIPT_DIR/lib/spinner_utils.sh"
source "$SCRIPT_DIR/helpers/common.sh"
source "$SCRIPT_DIR/helpers/env.sh"
source "$SCRIPT_DIR/helpers/docker.sh"
source "$SCRIPT_DIR/helpers/frontend.sh"

source "$SCRIPT_DIR/lib/env_check.sh"
source "$SCRIPT_DIR/lib/docker_utils.sh"
source "$SCRIPT_DIR/lib/frontend_build.sh"
source "$SCRIPT_DIR/lib/install_utils.sh"
source "$SCRIPT_DIR/lib/menu_utils.sh"
source "$SCRIPT_DIR/lib/args_parser.sh"
source "$SCRIPT_DIR/lib/config_utils.sh"
source "$SCRIPT_DIR/lib/preset_utils.sh"
source "$SCRIPT_DIR/lib/status_utils.sh"

# Globale Variablen
SCRIPT_NAME="$(basename "$0")"
LOG_FILE="$REPO_ROOT/logs/setup.log"
BUILD_FRONTEND=true
START_DOCKER=true
VERBOSE=false
INSTALL_HEAVY=false
WITH_DOCKER=false
AUTO_MODE=false
RUN_MODE="full"
EXIT_ON_FAIL=false
RECOVERY_MODE=false
LOG_ERROR_FILE=""
SUDO_CMD=""
PRESET=""
SETUP_TIMEOUT=300  # 5 Minuten Timeout für einzelne Schritte

usage() {
    cat << EOF
Usage: $SCRIPT_NAME [OPTIONS]

Agent-NN Setup Script - Vollständige Installation und Konfiguration

OPTIONS:
    -h, --help              Diese Hilfe anzeigen
    -v, --verbose           Ausführliche Ausgabe aktivieren
    --no-frontend           Frontend-Build überspringen
    --skip-docker           Docker-Start überspringen
    --check-only            Nur Umgebungsprüfung durchführen
    --check                 Nur Validierung ausführen und beenden
    --install-heavy         Zusätzliche Heavy-Dependencies installieren
    --with-docker          Abbruch wenn docker-compose.yml fehlt
    --with-sudo            Paketinstallation mit sudo ausführen
    --auto-install         Fehlende Abhängigkeiten automatisch installieren
    --full                  Komplettes Setup ohne Nachfragen
    --minimal               Nur Python-Abhängigkeiten installieren
    --no-docker             Setup ohne Docker-Schritte
    --exit-on-fail          Bei Fehlern sofort abbrechen
    --recover               Fehlgeschlagenes Setup wiederaufnehmen
    --preset <name>         Vordefinierte Einstellungen laden (dev|ci|minimal)
    --clean                 Entwicklungsumgebung zurücksetzen
    --timeout <seconds>     Timeout für Benutzer-Eingaben (default: 300)

BEISPIELE:
    $SCRIPT_NAME                    # Vollständiges Setup
    $SCRIPT_NAME --check-only       # Nur Umgebungsprüfung
    $SCRIPT_NAME --skip-docker      # Setup ohne Docker-Start
    $SCRIPT_NAME --verbose          # Mit ausführlicher Ausgabe
    $SCRIPT_NAME --install-heavy    # Heavy-Dependencies installieren
    $SCRIPT_NAME --auto-install    # Keine Rückfragen bei Abhängigkeitsinstallation
    $SCRIPT_NAME --preset dev       # Preset mit Docker und Frontend

VORAUSSETZUNGEN:
    - Python 3.9+
    - Node.js 18+
    - Docker & Docker Compose
    - Poetry
    - Git

EOF
}

# Sichere Eingabe-Funktion mit Timeout
safe_input() {
    local prompt="$1"
    local timeout="${2:-$SETUP_TIMEOUT}"
    local default="${3:-}"
    
    if [[ "$AUTO_MODE" == "true" ]]; then
        echo "$default"
        return 0
    fi
    
    local input=""
    if command -v timeout >/dev/null; then
        if input=$(timeout "$timeout" bash -c "read -rp '$prompt' input; echo \$input" 2>/dev/null); then
            echo "${input:-$default}"
        else
            echo "$default"
        fi
    else
        read -rp "$prompt" input 2>/dev/null || input="$default"
        echo "${input:-$default}"
    fi
}

# Fehlerbehandlung mit Timeout
handle_step_error() {
    local step_name="$1"
    local error_code="$2"
    local retry_count="${3:-0}"
    local max_retries=3
    
    if [[ "$EXIT_ON_FAIL" == "true" ]]; then
        log_err "Schritt '$step_name' fehlgeschlagen. Beende Setup."
        exit "$error_code"
    fi
    
    if [[ "$AUTO_MODE" == "true" ]]; then
        log_warn "Schritt '$step_name' fehlgeschlagen. Überspringe im Auto-Modus."
        return 0
    fi
    
    echo "❌ Schritt '$step_name' fehlgeschlagen."
    
    if [[ $retry_count -lt $max_retries ]]; then
        echo "[1] Wiederholen ($((retry_count + 1))/$max_retries)"
        echo "[2] Überspringen"
        echo "[3] Abbrechen"
        
        local choice
        choice=$(safe_input "Auswahl [1-3]: " 30 "2")
        
        case "$choice" in
            1) return 2 ;;  # Retry
            2) return 0 ;;  # Skip
            3|*) exit 1 ;;  # Exit
        esac
    else
        echo "Maximale Anzahl von Wiederholungen erreicht."
        echo "[1] Überspringen"
        echo "[2] Abbrechen"
        
        local choice
        choice=$(safe_input "Auswahl [1-2]: " 30 "1")
        
        case "$choice" in
            1) return 0 ;;  # Skip
            2|*) exit 1 ;;  # Exit
        esac
    fi
}

setup_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    LOG_ERROR_FILE="$(dirname "$LOG_FILE")/setup_errors.log"
    touch "$LOG_ERROR_FILE"
    
    if [[ "$VERBOSE" == "true" ]]; then
        exec 1> >(tee -a "$LOG_FILE")
        exec 2> >(tee -a "$LOG_FILE" >&2)
    fi
}

print_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   █████╗  ██████╗ ███████╗███╗   ██╗████████╗      ███╗   ██╗███╗   ██╗     ║
║  ██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝      ████╗  ██║████╗  ██║     ║
║  ███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║   █████╗██╔██╗ ██║██╔██╗ ██║     ║
║  ██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║   ╚════╝██║╚██╗██║██║╚██╗██║     ║
║  ██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║         ██║ ╚████║██║ ╚████║     ║
║  ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝         ╚═╝  ╚═══╝╚═╝  ╚═══╝     ║
║                                                                              ║
║                    Multi-Agent System Setup Script                          ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo
    log_info "Agent-NN Setup gestartet ($(date))"
    log_info "Repository: $REPO_ROOT"
    log_info "Log-Datei: $LOG_FILE"
    log_info "Timeout: ${SETUP_TIMEOUT}s"
    if [[ "$AUTO_MODE" == "true" ]]; then
        log_info "Auto-Modus: Aktiv"
    fi
    echo
}

install_python_dependencies() {
    log_info "Installiere Python-Abhängigkeiten mit Poetry..."

    if [[ "$RECOVERY_MODE" == "true" && -d "$REPO_ROOT/.venv" ]]; then
        log_info "Python-Abhängigkeiten bereits installiert - überspringe"
        return 0
    fi
    
    cd "$REPO_ROOT" || {
        log_err "Kann nicht ins Repository-Verzeichnis wechseln"
        return 1
    }
    
    # Poetry-Konfiguration optimieren
    poetry config virtualenvs.in-project true 2>/dev/null || true
    
    # Dependencies installieren
    if timeout "$SETUP_TIMEOUT" poetry install; then
        log_ok "Python-Abhängigkeiten installiert"
    else
        log_error "Fehler bei der Installation der Python-Abhängigkeiten"
        log_err "Versuche: poetry install --no-dev"
        if timeout "$SETUP_TIMEOUT" poetry install --no-dev; then
            log_warn "Python-Abhängigkeiten ohne Dev-Dependencies installiert"
        else
            return 1
        fi
    fi

    if ! poetry show langchain >/dev/null 2>&1; then
        log_warn "langchain nicht installiert – ggf. '--preset dev' nutzen"
    fi
    if [[ "$PRESET" == "minimal" ]]; then
        log_warn "Preset 'minimal' installiert keine Langchain- oder CLI-Abhängigkeiten"
    fi

    # CLI-Test mit Timeout
    if timeout 10 poetry run agentnn --help &>/dev/null; then
        log_ok "CLI verfügbar: poetry run agentnn"
    else
        log_warn "CLI-Test fehlgeschlagen (möglicherweise normale Dev-Installation)"
    fi
    
    if [[ "$INSTALL_HEAVY" == "true" ]]; then
        timeout "$SETUP_TIMEOUT" pip install torch==2.2.0+cpu -f https://download.pytorch.org/whl/torch_stable.html \
            || echo "⚠️ torch konnte nicht installiert werden – Tests evtl. deaktiviert"
    fi

    update_status "python" "ok" "$REPO_ROOT/.agentnn/status.json"
    return 0
}

verify_installation() {
    log_info "Verifiziere Installation..."
    
    local verification_steps=(
        "check_env_file"
        "check_docker"
    )
    
    if [[ "$BUILD_FRONTEND" == "true" ]]; then
        verification_steps+=("check_frontend_build")
    fi
    
    local failed_verifications=()
    
    for step in "${verification_steps[@]}"; do
        case "$step" in
            check_frontend_build)
                if [[ ! -f "$REPO_ROOT/frontend/dist/index.html" ]]; then
                    failed_verifications+=("Frontend-Build")
                fi
                ;;
            check_env_file)
                if [[ ! -f "$REPO_ROOT/.env" ]]; then
                    failed_verifications+=("Umgebungskonfiguration")
                fi
                ;;
            check_docker)
                if [[ "$START_DOCKER" == "true" ]] && ! timeout 10 docker ps &>/dev/null; then
                    failed_verifications+=("Docker-Services")
                fi
                ;;
        esac
    done
    
    if [[ ${#failed_verifications[@]} -gt 0 ]]; then
        log_warn "Verifizierung teilweise fehlgeschlagen: ${failed_verifications[*]}"
        return 1
    fi
    
    log_ok "Installation erfolgreich verifiziert"
    return 0
}

run_project_tests() {
    log_info "Starte Tests..."
    if timeout "$SETUP_TIMEOUT" bash -c "ruff check . && mypy mcp && pytest -m 'not heavy' -q"; then
        log_ok "Tests erfolgreich"
    else
        log_err "Tests fehlgeschlagen"
        return 1
    fi
}

# Verbesserte run_step Funktion mit Retry-Logik
run_step() {
    local msg="$1"
    local cmd="$2"
    local retry_count=0
    local max_retries=3
    
    while [[ $retry_count -le $max_retries ]]; do
        log_info "Führe aus: $msg"
        
        if with_spinner "$msg" "$cmd"; then
            return 0
        fi
        
        local error_code=$?
        
        # Spezielle Behandlung für Poetry-Probleme
        if [[ $error_code -eq 130 ]]; then
            log_warn "Benutzer hat Schritt abgebrochen oder Timeout erreicht"
            return 130
        fi
        
        case $(handle_step_error "$msg" $error_code $retry_count) in
            0) return 0 ;;    # Skip
            2) retry_count=$((retry_count + 1)) ;;  # Retry
            *) exit 1 ;;      # Exit
        esac
    done
    
    log_err "Schritt '$msg' nach $max_retries Versuchen fehlgeschlagen"
    return 1
}

print_next_steps() {
    echo
    log_ok "Setup erfolgreich abgeschlossen!"
    echo
    echo "📋 NÄCHSTE SCHRITTE:"
    echo
    echo "1. Konfiguration anpassen:"
    echo "   nano .env"
    echo
    echo "2. Services starten (falls nicht automatisch gestartet):"
    echo "   docker compose up -d"
    echo
    echo "3. Frontend aufrufen:"
    echo "   http://localhost:3000"
    echo
    echo "4. API testen:"
    echo "   curl http://localhost:8000/health"
    echo
    echo "5. CLI verwenden:"
    echo "   poetry run agentnn --help"
    echo
    echo "📖 WEITERE RESSOURCEN:"
    echo "   - Dokumentation: docs/"
    echo "   - Konfiguration: docs/config_reference.md"
    echo "   - Deployment: docs/deployment.md"
    echo "   - Troubleshooting: docs/troubleshooting.md"
    echo
    echo "🚀 Agent-NN ist bereit!"
    echo
}

show_current_config() {
    ensure_config_file_exists
    echo "┌─────────────────────────────────────┐"
    echo "│        Aktuelle Konfiguration       │"
    echo "├─────────────────────────────────────┤"
    local poetry
    poetry=$(load_config_value "POETRY_METHOD" "venv")
    printf "│ Poetry-Methode: %-18s │\n" "$poetry"
    printf "│ Auto-Modus:     %-18s │\n" "$AUTO_MODE"
    printf "│ Preset:         %-18s │\n" "${PRESET:-none}"
    printf "│ Timeout:        %-18s │\n" "${SETUP_TIMEOUT}s"
    echo "└─────────────────────────────────────┘"
}

return_to_main_menu() {
    local delay="${1:-3}"
    echo
    echo -e "${CYAN}→ Zurück zum Hauptmenü in ${delay} Sekunden (Ctrl+C zum Abbrechen) ...${NC}"
    sleep "$delay" 2>/dev/null || true
}

clean_environment() {
    log_info "Bereinige Entwicklungsumgebung..."
    
    # Docker-Services stoppen
    if docker_compose_down; then
        log_ok "Docker-Services gestoppt"
    fi
    
    # Docker-Volumes entfernen
    local volumes=("postgres_data" "vector_data")
    for vol in "${volumes[@]}"; do
        local full_name="${PWD##*/}_${vol}"
        if docker volume ls -q | grep -q "^${full_name}$"; then
            docker volume rm "$full_name" 2>/dev/null || true
            log_debug "Volume entfernt: $full_name"
        fi
    done
    
    # Lokale Daten bereinigen
    local dirs_to_clean=(
        "data/sessions"
        "data/vectorstore"
        "logs"
        "frontend/dist"
        ".pytest_cache"
        "__pycache__"
    )
    
    for dir in "${dirs_to_clean[@]}"; do
        if [[ -d "$REPO_ROOT/$dir" ]]; then
            rm -rf "$REPO_ROOT/$dir"
            log_debug "Verzeichnis bereinigt: $dir"
        fi
    done
    
    # Frontend bereinigen
    if [[ -d "$REPO_ROOT/frontend/agent-ui" ]]; then
        clean_frontend
    fi
    
    log_ok "Entwicklungsumgebung bereinigt"
}

# Haupt-Setup-Funktion
main() {
    local original_args=("$@")
    local arg_count=$#
    
    # Setup initialisieren
    setup_error_handling
    ensure_utf8
    setup_logging
    load_config || true
    load_project_config || true
    ensure_config_file_exists

    # Ensure POETRY_METHOD is initialized
    POETRY_METHOD=$(load_config_value "POETRY_METHOD" "venv")
    if [ -z "$POETRY_METHOD" ]; then
        log_info "🔧 Kein gespeicherter Wert für POETRY_METHOD – verwende Default: venv"
        POETRY_METHOD="venv"
        save_config_value "POETRY_METHOD" "$POETRY_METHOD"
    fi
    export POETRY_METHOD
    
    # Argumente parsen
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                export DEBUG=1
                shift
                ;;
            --no-frontend)
                BUILD_FRONTEND=false
                shift
                ;;
            --skip-docker)
                START_DOCKER=false
                shift
                ;;
            --check-only)
                BUILD_FRONTEND=false
                START_DOCKER=false
                RUN_MODE="check"
                shift
                ;;
            --check)
                RUN_MODE="check"
                BUILD_FRONTEND=false
                START_DOCKER=false
                shift
                ;;
            --install-heavy)
                INSTALL_HEAVY=true
                shift
                ;;
            --with-docker)
                WITH_DOCKER=true
                shift
                ;;
            --with-sudo)
                SUDO_CMD="sudo"
                shift
                ;;
            --full)
                AUTO_MODE=true
                RUN_MODE="full"
                shift
                ;;
            --minimal)
                START_DOCKER=false
                BUILD_FRONTEND=false
                AUTO_MODE=true
                RUN_MODE="python"
                shift
                ;;
            --no-docker)
                START_DOCKER=false
                shift
                ;;
            --exit-on-fail)
                EXIT_ON_FAIL=true
                shift
                ;;
            --recover)
                RECOVERY_MODE=true
                AUTO_MODE=true
                shift
                ;;
            --auto-install)
                AUTO_MODE=true
                shift
                ;;
            --preset)
                shift
                PRESET="$1"
                case "$PRESET" in
                    dev)
                        RUN_MODE="full"
                        BUILD_FRONTEND=true
                        START_DOCKER=true
                        ;;
                    ci)
                        RUN_MODE="test"
                        BUILD_FRONTEND=false
                        START_DOCKER=false
                        ;;
                    minimal)
                        RUN_MODE="python"
                        BUILD_FRONTEND=false
                        START_DOCKER=false
                        ;;
                    *)
                        log_err "Unbekanntes Preset: $PRESET"
                        exit 1
                        ;;
                esac
                shift
                ;;
            --timeout)
                shift
                SETUP_TIMEOUT="$1"
                shift
                ;;
            --clean)
                clean_environment
                exit 0
                ;;
            *)
                log_err "Unbekannte Option: $1"
                usage >&2
                exit 1
                ;;
        esac
    done
    
    export SUDO_CMD
    export AUTO_MODE

    while true; do
        if [[ $arg_count -eq 0 ]]; then
            echo "📦 Gewählte Installationsmethode: ${POETRY_METHOD:-nicht gesetzt}"
            interactive_menu
            [[ "$RUN_MODE" == "exit" ]] && break
        fi

        # Banner anzeigen
        print_banner

        STATUS_FILE="$REPO_ROOT/.agentnn/status.json"
        ensure_status_file "$STATUS_FILE"
        if [[ -n "$PRESET" ]]; then
            log_preset "$PRESET" "$STATUS_FILE"
        fi

        cd "$REPO_ROOT" || {
            log_err "Kann nicht ins Repository-Verzeichnis wechseln: $REPO_ROOT"
            exit 1
        }

        if [[ "$WITH_DOCKER" == "true" ]]; then
            if [[ ! -f docker-compose.yml ]]; then
                log_err "docker-compose.yml fehlt"
                exit 1
            fi
            if ! has_docker_compose; then
                log_err "Docker Compose nicht ausführbar"
                exit 1
            fi
        fi
    
        # Umgebungsprüfung
        log_info "=== UMGEBUNGSPRÜFUNG ==="
        if ! mapfile -t missing_pkgs < <(check_environment); then
            if [[ ${#missing_pkgs[@]} -gt 0 ]]; then
                log_warn "Fehlende Pakete: ${missing_pkgs[*]}"
                for pkg in "${missing_pkgs[@]}"; do
                    prompt_and_install_if_missing "$pkg" || true
                done
                mapfile -t _ < <(check_environment) || {
                    log_err "Umgebungsprüfung fehlgeschlagen. Setup abgebrochen."
                    exit 1
                }
            else
                log_err "Umgebungsprüfung fehlgeschlagen. Setup abgebrochen."
                exit 1
            fi
        fi

        # Fehlende Komponenten installieren
        run_step "Prüfe Docker" ensure_docker; [[ $? -eq 130 ]] && { RUN_MODE=""; arg_count=0; return_to_main_menu; continue; }
        run_step "Prüfe Node.js" ensure_node; [[ $? -eq 130 ]] && { RUN_MODE=""; arg_count=0; return_to_main_menu; continue; }
        run_step "Prüfe Python" ensure_python; [[ $? -eq 130 ]] && { RUN_MODE=""; arg_count=0; return_to_main_menu; continue; }
        run_step "Prüfe Poetry" ensure_poetry; [[ $? -eq 130 ]] && { RUN_MODE=""; arg_count=0; return_to_main_menu; continue; }
        run_step "Prüfe Tools" ensure_python_tools; [[ $? -eq 130 ]] && { RUN_MODE=""; arg_count=0; return_to_main_menu; continue; }
        
        # Docker-Prüfung
        log_info "=== DOCKER-PRÜFUNG ==="
        if ! has_docker; then
            if [[ "$WITH_DOCKER" == "true" ]]; then
                log_err "Docker erforderlich aber nicht gefunden."
                exit 1
            else
                log_warn "Docker nicht verfügbar – Docker-Start wird übersprungen"
                START_DOCKER=false
            fi
        elif ! has_docker_compose; then
            if [[ "$WITH_DOCKER" == "true" ]]; then
                log_err "Docker Compose nicht gefunden."
                exit 1
            else
                log_warn "Docker Compose fehlt – Docker-Start wird übersprungen"
                START_DOCKER=false
            fi
        fi
        
        case "$RUN_MODE" in
            python)
                run_step "Python-Abhängigkeiten" install_python_dependencies
                ;;
            frontend)
                run_step "Frontend-Build" build_frontend
                ;;
            docker)
                if [[ "$RECOVERY_MODE" == "true" ]] && timeout 10 docker compose ps | grep -q 'Up'; then
                    log_info "Docker-Services laufen bereits - überspringe"
                else
                    run_step "Docker-Services" "start_docker_services \"docker-compose.yml\""
                fi
                ;;
            system)
                run_step "System-Abhängigkeiten" "${SCRIPT_DIR}/install_dependencies.sh ${SUDO_CMD:+--with-sudo} --auto-install"
                ;;
            mcp)
                run_step "Starte MCP" "${SCRIPT_DIR}/start_mcp.sh"
                ;;
            status)
                run_step "Status" "${SCRIPT_DIR}/status.sh" && exit 0
                ;;
            repair)
                run_step "Repariere" "${SCRIPT_DIR}/repair_env.sh"
                ;;
            show_config)
                show_current_config
                ;;
            test)
                run_step "Tests" run_project_tests
                ;;
            check)
                run_step "Validierung" "${SCRIPT_DIR}/validate.sh" && exit 0
                ;;
            full)
                log_info "=== PYTHON-ABHÄNGIGKEITEN ==="
                run_step "Python-Abhängigkeiten" install_python_dependencies

                if [[ "$BUILD_FRONTEND" == "true" ]]; then
                    log_info "=== FRONTEND-BUILD ==="
                    run_step "Frontend-Build" build_frontend
                    cd "$REPO_ROOT"
                fi

                if [[ "$START_DOCKER" == "true" ]]; then
                    log_info "=== DOCKER-SERVICES ==="
                    compose_file="docker-compose.yml"
                    if [[ ! -f "$compose_file" ]]; then
                        compose_file=$(ls docker-compose.*.yml 2>/dev/null | head -n1 || true)
                    fi
                    if [[ -f "$compose_file" ]]; then
                        if [[ "$RECOVERY_MODE" == "true" ]] && timeout 10 docker compose ps | grep -q 'Up'; then
                            log_info "Docker-Services laufen bereits - überspringe"
                        else
                            run_step "Docker-Services" "start_docker_services \"$compose_file\""
                        fi
                    elif [[ "$WITH_DOCKER" == "true" ]]; then
                        log_err "Docker Compose Datei nicht gefunden. Setup abgebrochen."
                        exit 1
                    fi
                fi

                log_info "=== VERIFIZIERUNG ==="
                run_step "Verifizierung" verify_installation || log_warn "Verifizierung mit Problemen abgeschlossen"

                run_step "Tests" run_project_tests || true
                update_status "last_setup" "$(date -u +%FT%TZ)" "$REPO_ROOT/.agentnn/status.json"
                print_next_steps
                ;;
        esac

        if [[ $arg_count -eq 0 ]]; then
            return_to_main_menu 3
        fi

        if [[ $arg_count -gt 0 ]]; then
            break
        fi
        RUN_MODE=""
    done
}

# Script ausführen falls direkt aufgerufen
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
