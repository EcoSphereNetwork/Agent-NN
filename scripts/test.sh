#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/env_check.sh"
source "$SCRIPT_DIR/lib/docker_utils.sh"
LOG_DIR="$SCRIPT_DIR/../logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "🧪 Starte Testdurchlauf..."

if ! command -v python &>/dev/null; then
    echo "Python nicht gefunden. Bitte Python 3.10 oder neuer installieren." >&2
    exit 1
fi

set +e
python - <<'EOF'
import importlib.util, sys
sys.exit(0 if importlib.util.find_spec("torch") else 1)
EOF
HAS_TORCH=$?
set -e

check_module() {
    set +e
    python - "$1" <<'PY'
import importlib.util, sys
sys.exit(0 if importlib.util.find_spec(sys.argv[1]) else 1)
PY
    local code=$?
    set -e
    return $code
}

MISSING=()
for mod in langchain openai pytest ruff; do
    if check_module "$mod"; then
        :
    else
        MISSING+=("$mod")
    fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
    echo "Fehlende Module: ${MISSING[*]}" >&2
    echo "Bitte Setup mit '--preset dev' ausf\u00fchren." >&2
    exit 1
fi

if [[ "$HAS_TORCH" -eq 0 ]]; then
    pytest "$@" -q
else
    echo "torch nicht installiert – Heavy-Tests werden übersprungen"
    pytest -m "not heavy" "$@" -q
fi
