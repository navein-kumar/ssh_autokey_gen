#!/bin/bash

# SSH Key Generator and Setup Script
# This script generates SSH keys, updates authorized_keys, and creates a PEM file

set -e  # Exit on any error

# Configuration
KEY_NAME="server_key_$(date +%Y%m%d_%H%M%S)"
SSH_DIR="$HOME/.ssh"
CURRENT_DIR=$(pwd)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== SSH Key Setup Script ===${NC}"
echo

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Create .ssh directory if it doesn't exist
if [ ! -d "$SSH_DIR" ]; then
    print_status "Creating .ssh directory..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
fi

# Generate SSH key pair
print_status "Generating SSH key pair..."
ssh-keygen -t rsa -b 4096 -f "$SSH_DIR/$KEY_NAME" -N "" -C "Generated on $(hostname) - $(date)"

if [ $? -eq 0 ]; then
    print_status "SSH key pair generated successfully!"
else
    print_error "Failed to generate SSH key pair"
    exit 1
fi

# Add public key to authorized_keys
print_status "Adding public key to authorized_keys..."
cat "$SSH_DIR/$KEY_NAME.pub" >> "$SSH_DIR/authorized_keys"

# Set proper permissions
chmod 600 "$SSH_DIR/authorized_keys"
chmod 600 "$SSH_DIR/$KEY_NAME"
chmod 644 "$SSH_DIR/$KEY_NAME.pub"

# Copy private key as PEM file to current directory
print_status "Creating PEM file in current directory..."
cp "$SSH_DIR/$KEY_NAME" "$CURRENT_DIR/$KEY_NAME.pem"
chmod 400 "$CURRENT_DIR/$KEY_NAME.pem"

# Get server information
SERVER_IP=$(hostname -I | awk '{print $1}')
SERVER_USER=$(whoami)

# Create connection info file
cat > "$CURRENT_DIR/connection_info.txt" << EOF
SSH Connection Information
=========================

Server IP: $SERVER_IP
Username: $SERVER_USER
PEM File: $KEY_NAME.pem

Connection Commands:
-------------------

From your local machine:
1. Copy the PEM file to your local machine
2. Set proper permissions: chmod 400 $KEY_NAME.pem
3. Connect using: ssh -i $KEY_NAME.pem $SERVER_USER@$SERVER_IP

Alternative connection (if you copy to ~/.ssh/):
ssh -i ~/.ssh/$KEY_NAME.pem $SERVER_USER@$SERVER_IP

SCP Example:
scp -i $KEY_NAME.pem local_file.txt $SERVER_USER@$SERVER_IP:/remote/path/

Generated on: $(date)
EOF

echo
print_status "Setup completed successfully!"
echo
echo -e "${BLUE}Files created in current directory:${NC}"
echo "  - $KEY_NAME.pem (Private key for connection)"
echo "  - connection_info.txt (Connection details)"
echo
echo -e "${BLUE}Files created in $SSH_DIR:${NC}"
echo "  - $KEY_NAME (Private key)"
echo "  - $KEY_NAME.pub (Public key)"
echo "  - authorized_keys (Updated with new public key)"
echo
echo -e "${GREEN}Next Steps:${NC}"
echo "1. Copy $KEY_NAME.pem to your local machine"
echo "2. Set permissions: chmod 400 $KEY_NAME.pem"
echo "3. Connect: ssh -i $KEY_NAME.pem $SERVER_USER@$SERVER_IP"
echo
echo -e "${YELLOW}Security Note:${NC}"
echo "Keep the PEM file secure and never share it!"

# Optional: Test the key locally
echo
read -p "Do you want to test the SSH connection locally? (y/N): " test_connection
if [[ $test_connection =~ ^[Yy]$ ]]; then
    print_status "Testing SSH connection..."
    ssh -i "$CURRENT_DIR/$KEY_NAME.pem" -o StrictHostKeyChecking=no $SERVER_USER@localhost "echo 'SSH connection test successful!'"
    if [ $? -eq 0 ]; then
        print_status "Local SSH test passed!"
    else
        print_warning "Local SSH test failed, but keys are set up correctly"
    fi
fi

echo
print_status "Script execution completed!"
