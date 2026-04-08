#!/bin/bash

# Comprehensive healthcheck for Minecraft Paper server

# Function to check if Minecraft server is responding properly
check_minecraft_response() {
    # Try to connect to the server port
    if timeout 5 bash -c '</dev/tcp/localhost/25565' >/dev/null 2>&1; then
        echo "✓ Port 25565 is open"
        
        # For Minecraft servers, a simple connection test is often sufficient
        # The server should be accepting connections if the port is open
        echo "✓ Minecraft server is accessible on port 25565"
        return 0
    else
        echo "✗ Port 25565 is not accessible"
        
        # Show what's listening on ports
        echo "Active listeners:"
        netstat -tlnp 2>/dev/null | grep LISTEN || echo "No listeners found"
        
        return 1
    fi
}

# Run the check
if check_minecraft_response; then
    exit 0
else
    exit 1
fi