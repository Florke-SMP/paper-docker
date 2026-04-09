#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

cd "$TEST_DIR"

# Export this so it's guaranteed to be available to the sourced functions
export SERVER_PROPERTIES_FILE="server.properties"

source "${SCRIPT_DIR}/entrypoint.sh"

# --- Test Helpers ---
# Added basic ANSI colors for better CLI readability
pass() { echo -e "[\033[32mPASS\033[0m] $1"; }
fail() { echo -e "[\033[31mFAIL\033[0m] $1"; exit 1; }

# Extracted assertions using grep -F (Fixed string).
# Standard grep evaluates characters like '.', '*', or '[' as regex. 
# grep -F ensures special characters in test strings are treated literally.
assert_contains() { 
    grep -Fq "$1" "$SERVER_PROPERTIES_FILE" || fail "${2:-"Expected file to contain: $1"}"
}
assert_not_contains() { 
    ! grep -Fq "$1" "$SERVER_PROPERTIES_FILE" || fail "${2:-"Expected file to NOT contain: $1"}"
}

# Wrapper to DRY up the file creation block
setup_file() {
    cat > "$SERVER_PROPERTIES_FILE"
}

echo "=== Testing write_server_property function ==="

echo "--- Test 1: Add new property to empty file ---"
> "$SERVER_PROPERTIES_FILE"
write_server_property "test-key" "test-value"
assert_contains "test-key=test-value" "Test 1: Property not added"
pass "Test 1"

echo "--- Test 2: Update existing property ---"
setup_file <<'EOF'
server-port=25565
server-ip=
max-players=100
test-key=old-value
EOF
write_server_property "test-key" "new-value"
assert_contains "test-key=new-value" "Test 2: Property not updated"
assert_not_contains "test-key=old-value" "Test 2: Old value still present"
pass "Test 2"

echo "--- Test 3: Add property when not present ---"
setup_file <<'EOF'
server-port=25565
server-ip=
EOF
write_server_property "new-property" "new-value"
assert_contains "new-property=new-value" "Test 3: New property not added"
pass "Test 3"

echo "--- Test 4: Multiple occurrences of same key (keep only first) ---"
setup_file <<'EOF'
duplicate=value1
server-port=25565
duplicate=value2
duplicate=value3
EOF
write_server_property "duplicate" "new-value"
# Anchor with ^ to ensure we don't accidentally count keys like "non-duplicate="
count=$(grep -c "^duplicate=" "$SERVER_PROPERTIES_FILE" || echo "0")
[ "$count" -eq 1 ] || fail "Test 4: Expected 1 occurrence, got $count"
assert_contains "duplicate=new-value" "Test 4: Value not updated"
pass "Test 4"

echo "--- Test 5: Special characters in value ---"
> "$SERVER_PROPERTIES_FILE"
# Added regex-breaking characters (., *, [, \) to prove grep -F works correctly here
write_server_property "motd" "A # Mine.craft > [Server] < & '\Quotes\*'"
assert_contains "motd=A # Mine.craft > [Server] < & '\Quotes\*'" "Test 5: Special characters not preserved"
pass "Test 5"

echo "--- Test 6: Empty value ---"
> "$SERVER_PROPERTIES_FILE"
write_server_property "empty-prop" ""
assert_contains "empty-prop=" "Test 6: Empty value not set"
pass "Test 6"

echo "--- Test 7: Preserve other properties order ---"
setup_file <<'EOF'
first_key=value1
second-key=value2
thirdKey=value3
EOF
write_server_property "fourth_key" "value4"
# Improved regex: ^[^=]*= captures everything up to the first equals sign.
# The old ^[a-z-]*= would fail on keys containing underscores, numbers, or uppercase letters.
order=$(grep -o '^[^=]*=' "$SERVER_PROPERTIES_FILE" | tr '\n' ' ' | xargs)
expected="first_key= second-key= thirdKey= fourth_key="
[ "$order" = "$expected" ] || fail "Test 7: Order not preserved (got: $order)"
pass "Test 7"

echo "--- Test 8: Missing trailing newline (Edge Case) ---"
# printf explicitly avoids adding the trailing \n that echo/cat usually provide
printf "server-port=25565\nno-newline=true" > "$SERVER_PROPERTIES_FILE"
write_server_property "no-newline" "false"
assert_contains "no-newline=false" "Test 8: Failed to update line missing trailing newline"
pass "Test 8"

echo ""
echo -e "[\033[32mSUCCESS\033[0m] All tests passed."