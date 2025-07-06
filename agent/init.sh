#!/bin/bash

# Agent Stack Initialization Script
echo "Initializing agent stack..."

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    echo "Please provide the following configuration values:"
    echo ""

    # Prompt for monitoring instance IP
    read -p "Enter monitoring instance IP address (where the monitoring stack is running) [localhost]: " MONITORING_INSTANCE_IP
    MONITORING_INSTANCE_IP=${MONITORING_INSTANCE_IP:-localhost}

    # Get docker group ID dynamically
    echo "Detecting docker group ID..."
    if command -v getent >/dev/null 2>&1; then
        DOCKER_GID=$(getent group docker | cut -d: -f3)
        if [ -n "$DOCKER_GID" ]; then
            echo "✓ Docker group ID detected: $DOCKER_GID"
        else
            echo "⚠ Could not detect docker group ID, using default 998"
            DOCKER_GID=998
        fi
    else
        echo "⚠ getent not available, using default docker group ID 998"
        DOCKER_GID=998
    fi

    # Create .env file with user input
    cat > .env << EOF
MONITORING_INSTANCE_IP='${MONITORING_INSTANCE_IP}'
DOCKER_GID=${DOCKER_GID}
EOF
    echo "✓ .env file created with your configuration"
else
    echo "✓ .env file already exists"
fi

# Get the monitoring instance IP from .env file
MONITORING_IP=$(grep "MONITORING_INSTANCE_IP=" .env | cut -d"'" -f2)

if [ -z "$MONITORING_IP" ]; then
    echo "⚠ Could not find MONITORING_INSTANCE_IP in .env file"
    exit 1
fi

# Get current hostname for agent name
AGENT_HOSTNAME=$(hostname)
echo "Using hostname '$AGENT_HOSTNAME' as Wazuh agent name"

# Download and install Wazuh agent
echo "Downloading and installing Wazuh agent..."
if command -v curl >/dev/null 2>&1; then
    # Download the Wazuh agent package
    echo "Downloading Wazuh agent package..."
    curl -o wazuh-agent-4.12.0-1.x86_64.rpm https://packages.wazuh.com/4.x/yum/wazuh-agent-4.12.0-1.x86_64.rpm

    if [ $? -eq 0 ]; then
        echo "✓ Wazuh agent package downloaded successfully"

        # Install the Wazuh agent
        echo "Installing Wazuh agent with manager IP: $MONITORING_IP and agent name: $AGENT_HOSTNAME"
        sudo WAZUH_MANAGER="$MONITORING_IP" WAZUH_AGENT_NAME="$AGENT_HOSTNAME" rpm -ihv wazuh-agent-4.12.0-1.x86_64.rpm

        if [ $? -eq 0 ]; then
            echo "✓ Wazuh agent installed successfully"

            # Start and enable the Wazuh agent service
            echo "Starting Wazuh agent service..."
            sudo systemctl daemon-reload
            sudo systemctl enable wazuh-agent
            sudo systemctl start wazuh-agent

            if [ $? -eq 0 ]; then
                echo "✓ Wazuh agent service started successfully"

                # Check agent status
                echo "Checking Wazuh agent status..."
                sudo systemctl status wazuh-agent --no-pager

                echo ""
                echo "📋 Agent Information:"
                echo "  - Manager IP: $MONITORING_IP"
                echo "  - Agent Name: $AGENT_HOSTNAME"
                echo "  - Service Status: $(sudo systemctl is-active wazuh-agent)"
                echo ""
                echo "💡 To check agent logs: sudo tail -f /var/ossec/logs/ossec.log"
                echo "💡 To restart agent: sudo systemctl restart wazuh-agent"
            else
                echo "⚠ Failed to start Wazuh agent service"
                echo "  You can manually start it with: sudo systemctl start wazuh-agent"
            fi
        else
            echo "⚠ Failed to install Wazuh agent"
            echo "  Make sure you have sudo privileges and rpm is available"
        fi
    else
        echo "⚠ Failed to download Wazuh agent package"
        echo "  Please check your internet connection and try again"
    fi
else
    echo "⚠ curl not available - you'll need to download the agent manually:"
    echo "  curl -o wazuh-agent-4.12.0-1.x86_64.rpm https://packages.wazuh.com/4.x/yum/wazuh-agent-4.12.0-1.x86_64.rpm"
    echo "  sudo WAZUH_MANAGER='$MONITORING_IP' WAZUH_AGENT_NAME='$AGENT_HOSTNAME' rpm -ihv wazuh-agent-4.12.0-1.x86_64.rpm"
fi

# Start Telegraf if docker-compose is available
echo ""
echo "Starting Telegraf monitoring..."

if command -v docker-compose >/dev/null 2>&1; then
    docker-compose up -d
    echo "✓ Telegraf started with Docker Compose (using group ID: $DOCKER_GID)"
else
    echo "⚠ docker-compose not available - you'll need to start manually:"
    echo "  docker-compose up -d"
fi

echo ""
echo "🚀 Agent initialization complete!"
echo ""
