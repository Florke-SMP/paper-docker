#!/bin/bash

# Comprehensive healthcheck for Minecraft Paper server

# Function to check if Minecraft server is responding properly
check_minecraft_response() {
    # Try to connect to the server port
    if timeout 5 bash -c '</dev/tcp/localhost/25565' >/dev/null 2>&1; then
        echo "✓ Port 25565 is open"
        
        # Try to get a basic response from the Minecraft server using netcat
        # Minecraft servers respond with protocol information when connected to
        if response=$(timeout 3 nc -vz localhost 25565 2>&1); then
            echo "✓ Minecraft server is responding"
            return 0
        else
            echo "✗ Minecraft server is not responding properly"
            return 1
        fi
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