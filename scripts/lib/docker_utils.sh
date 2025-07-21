#!/bin/bash

__docker_utils_init() {
    local dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    DOCKER_UTILS_DIR="$dir"
    source "$dir/log_utils.sh"
    source "$dir/../helpers/common.sh"
    source "$dir/status_utils.sh"
}

__docker_utils_init

has_docker() {
    if command -v docker &>/dev/null; then
        log_ok "Docker gefunden"
        return 0
    else
        log_err "Docker fehlt"
        return 1
    fi
}

has_docker_compose() {
    if docker compose version &>/dev/null; then
        log_ok "Docker Compose Plugin gefunden"
        return 0
    elif command -v docker-compose &>/dev/null; then
        log_ok "docker-compose gefunden"
        return 0
    fi
    log_err "Docker Compose fehlt"
    return 1
}

docker_compose() {
    if docker compose version &>/dev/null; then
        docker compose "$@"
    else
        docker-compose "$@"
    fi
}

load_compose_file() {
    local file="${1:-docker-compose.yml}"
    if [[ -f "$file" ]]; then
        echo "$file"
        return 0
    elif [[ -f "docker/$file" ]]; then
        echo "docker/$file"
        return 0
    fi
    log_err "Compose-Datei $file fehlt"
    return 1
}

docker_compose_up() {
    local compose_file="$1"
    local extra_args="${2:-}"
    
    if [[ ! -f "$compose_file" ]]; then
        log_err "Docker Compose Datei nicht gefunden: $compose_file"
        return 1
    fi
    
    log_info "Erkenne Docker Compose..."
    
    # Determine which Docker Compose command to use
    local compose_cmd=""
    if docker compose version &>/dev/null; then
        compose_cmd="docker compose"
        log_ok "Docker Compose Plugin erkannt ($(docker compose version --short))"
    elif command -v docker-compose &>/dev/null; then
        compose_cmd="docker-compose"
        log_ok "Docker Compose Classic erkannt ($(docker-compose version --short))"
    else
        log_err "Kein Docker Compose gefunden"
        return 1
    fi
    
    log_info "Starte Docker-Services mit $compose_cmd..."
    
    # Try to start services with build
    if [[ "$extra_args" == *"--build"* ]]; then
        log_info "Baue Docker Images..."
        if ! $compose_cmd -f "$compose_file" build; then
            log_warn "Docker Build fehlgeschlagen - versuche Fallback..."
            
            # Try with fallback Dockerfile if it exists
            if [[ -f "$(dirname "$compose_file")/Dockerfile.fallback" ]]; then
                log_info "Verwende Fallback Dockerfile..."
                # Create temporary compose file with fallback dockerfile
                local temp_compose
                temp_compose="$(mktemp).yml"
                sed 's|dockerfile: Dockerfile|dockerfile: Dockerfile.fallback|g' "$compose_file" > "$temp_compose"
                
                if $compose_cmd -f "$temp_compose" build; then
                    log_ok "Fallback Build erfolgreich"
                    compose_file="$temp_compose"
                else
                    log_err "Auch Fallback Build fehlgeschlagen"
                    rm -f "$temp_compose"
                    return 1
                fi
            else
                log_err "Docker Build fehlgeschlagen und kein Fallback verfügbar"
                return 1
            fi
        fi
    fi
    
    # Start the services
    if $compose_cmd -f "$compose_file" up -d $extra_args; then
        log_ok "Docker-Services gestartet"
        
        # Service-Status prüfen
        log_info "Service-Status:"
        $compose_cmd -f "$compose_file" ps
        
        # Clean up temporary compose file if created
        if [[ "$compose_file" == *"tmp"* ]]; then
            rm -f "$compose_file"
        fi
        
        return 0
    else
        log_err "Fehler beim Starten der Docker-Services"
        # Clean up temporary compose file if created
        if [[ "$compose_file" == *"tmp"* ]]; then
            rm -f "$compose_file"
        fi
        return 1
    fi
}

start_docker_services() {
    local compose
    compose=$(load_compose_file "${1:-docker-compose.yml}") || return 1
    docker_compose_up "$compose" "--build"
}

export -f has_docker has_docker_compose docker_compose load_compose_file start_docker_services docker_compose_up
