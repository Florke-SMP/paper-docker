#!/bin/bash

minecraft_healthcheck() {
    # try tcp port 25565
    if timeout 5 bash -c '</dev/tcp/localhost/25565' >/dev/null 2>&1; then
        echo "Port 25565 is accessible"
        return 0
    else
        echo "Port 25565 is not accessible"
        
        echo "The container 'LISTEN' ports (via netstat):"
        netstat -tlnp 2>/dev/null | grep LISTEN || echo "No listeners found"
        
        return 1
    fi
}

if minecraft_healthcheck; then
    exit 0
else
    exit 1
fi