#!/bin/bash
set -euo pipefail

check_port() {
    local port=$1
    if timeout 5 bash -c "</dev/tcp/localhost/${port}" >/dev/null 2>&1; then
        echo "Port ${port} is accessible"
        return 0
    fi

    echo "Port ${port} is not accessible"
    echo "The container 'LISTEN' ports (via netstat):"
    netstat -tlnp 2>/dev/null | grep LISTEN || echo "No listeners found"
    return 1
}

check_port 25565

if [ -n "${PAPER_RCON_PASSWORD:-}" ]; then
    check_port 25575
fi
