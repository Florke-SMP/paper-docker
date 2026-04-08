#!/bin/bash

# Test script to verify healthcheck functionality

echo "Testing healthcheck command..."

# Test 1: Check if netcat is installed
echo "Test 1: Checking if netcat is installed..."
if command -v nc &> /dev/null; then
    echo "✓ netcat is installed"
else
    echo "✗ netcat is not installed"
fi

# Test 2: Check if we can connect to port 25565
echo -e "\nTest 2: Checking port 25565 connectivity..."
if timeout 5 bash -c '</dev/tcp/localhost/25565' &>/dev/null; then
    echo "✓ Port 25565 is accessible"
else
    echo "✗ Port 25565 is not accessible"
fi

# Test 3: Check if netcat can connect to port 25565
echo -e "\nTest 3: Testing with netcat..."
if nc -zv localhost 25565 2>/dev/null; then
    echo "✓ netcat connection successful"
else
    echo "✗ netcat connection failed"
fi

# Test 4: Check listening ports
echo -e "\nTest 4: Checking listening ports..."
netstat -tlnp 2>/dev/null | grep :25565 || echo "No process listening on port 25565"

echo -e "\nHealthcheck test completed."