#!/bin/bash

# Replace these variables with your values
INSTANCE_IP=$(terraform output -raw fashion_assistant_public_ip)
KEY_PATH="${HOME}/.ssh/fashion-assistant"
REPO_URL="git@github.com:Slash-Org/Slash-Fashion-Assistant-Backend.git"
APP_NAME="fashion-assistant-backend"

# First, verify we can connect
echo "Testing SSH connection..."
ssh -i "$KEY_PATH" ubuntu@"$INSTANCE_IP" "whoami"

# Generate and show GitHub SSH key
echo "Generating GitHub SSH key on the instance..."
ssh -i "$KEY_PATH" ubuntu@"$INSTANCE_IP" <<'EOF'
if [ ! -f ~/.ssh/id_rsa ]; then
    mkdir -p ~/.ssh
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    echo -e "\n\n=== COPY THIS PUBLIC KEY TO GITHUB DEPLOY KEYS ===\n"
    cat ~/.ssh/id_rsa.pub
    echo -e "\n=== END OF PUBLIC KEY ===\n"
    
    # Configure SSH to trust GitHub
    echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
    chmod 600 ~/.ssh/config
fi
EOF

# Ask user if they've added the key to GitHub
read -p "Have you added the public key to GitHub deploy keys? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please add the public key to GitHub deploy keys before continuing:"
    echo "1. Go to https://github.com/Slash-Org/Slash-Fashion-Assistant-Backend/settings/keys"
    echo "2. Click 'Add deploy key'"
    echo "3. Paste the public key shown above"
    echo "4. Enable 'Allow write access'"
    echo "5. Click 'Add key'"
    exit 1
fi

# Continue with deployment
echo "Proceeding with deployment..."
ssh -i "$KEY_PATH" ubuntu@"$INSTANCE_IP" <<EOF
    # Clean up existing directories
    rm -rf ~/fashion-assistant
    
    echo "Creating directory..."
    mkdir -p ~/fashion-assistant
    cd ~/fashion-assistant

    echo "Cloning repository..."
    # First ensure GitHub's host key is trusted
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
    
    echo "Cloning from ${REPO_URL} into ${APP_NAME}..."
    git clone "${REPO_URL}" "${APP_NAME}"
    
    if [ ! -d "${APP_NAME}" ]; then
        echo "Failed to clone repository"
        exit 1
    fi

    cd "${APP_NAME}"
    echo "Current directory: \$(pwd)"
    echo "Directory contents:"
    ls -la

    echo "Installing dependencies..."
    if [ -f "package.json" ]; then
        npm install
        
        echo "Starting application with PM2..."
        pm2 delete "${APP_NAME}" || true
        pm2 start npm --name "${APP_NAME}" --cwd "/home/ubuntu/fashion-assistant/${APP_NAME}" --env PORT=3000 -- start
        pm2 save
        
        echo "Application started successfully!"
    else
        echo "Error: package.json not found in \$(pwd)"
        exit 1
    fi

    echo "Deployment complete!"
EOF
