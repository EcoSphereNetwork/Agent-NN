#!/bin/bash
# Docker Build Script with Fallback
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/lib/log_utils.sh"

build_docker_image() {
    local dockerfile="${1:-Dockerfile}"
    local tag="${2:-agent-nn:latest}"
    
    log_info "Building Docker image with $dockerfile..."
    
    cd "$REPO_ROOT" || {
        log_err "Cannot change to repository directory: $REPO_ROOT"
        return 1
    }
    
    if docker build -f "$dockerfile" -t "$tag" .; then
        log_ok "Docker build successful: $tag"
        return 0
    else
        log_err "Docker build failed with $dockerfile"
        return 1
    fi
}

main() {
    log_info "Agent-NN Docker Build Script"
    
    # Check if Docker is available
    if ! command -v docker >/dev/null; then
        log_err "Docker is not installed or not in PATH"
        exit 1
    fi
    
    # Try main Dockerfile first
    if build_docker_image "Dockerfile" "agent-nn:latest"; then
        log_ok "Main build successful"
        exit 0
    fi
    
    # Fallback to alternative Dockerfile
    log_warn "Main build failed, trying fallback..."
    if [[ -f "$REPO_ROOT/Dockerfile.fallback" ]]; then
        if build_docker_image "Dockerfile.fallback" "agent-nn:fallback"; then
            log_ok "Fallback build successful"
            log_info "Tagged as: agent-nn:fallback"
            exit 0
        else
            log_err "Both main and fallback builds failed"
            exit 1
        fi
    else
        log_err "No fallback Dockerfile found"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
