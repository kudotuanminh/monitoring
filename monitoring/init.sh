#!/bin/bash

# Monitoring Stack Initialization Script
echo "Initializing monitoring stack..."

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    echo "Please provide the following configuration values:"
    echo ""

    # Prompt for OpenSearch admin password
    read -s -p "Enter OpenSearch admin password (will be hidden): " OPENSEARCH_PASSWORD
    echo ""

    # Prompt for Grafana endpoint
    read -p "Enter Grafana endpoint (e.g., [localhost:3000], IP address or domain): " GF_ENDPOINT
    GF_ENDPOINT=${GF_ENDPOINT:-localhost:3000}

    # Prompt for Grafana admin user
    read -p "Enter Grafana admin username [admin]: " GF_ADMIN_USER
    GF_ADMIN_USER=${GF_ADMIN_USER:-admin}

    # Prompt for Grafana admin password
    read -s -p "Enter Grafana admin password (will be hidden): " GF_ADMIN_PASSWORD
    echo ""
    echo ""

    # Create .env file with user input
    cat > .env << EOF
OPENSEARCH_ADMIN_PASSWORD='${OPENSEARCH_PASSWORD}'
GF_ENDPOINT='${GF_ENDPOINT}'
GF_ADMIN_USER='${GF_ADMIN_USER}'
GF_ADMIN_PASSWORD='${GF_ADMIN_PASSWORD}'
EOF
    echo "✓ .env file created with your configuration"
else
    echo "✓ .env file already exists"
fi

# Create data directory structure
echo "Creating data directories..."
mkdir -p data/grafana
mkdir -p data/opensearch
mkdir -p data/victoriametrics

# Set ownership for Grafana (472:472)
echo "Setting Grafana data ownership (472:472)..."
if command -v chown >/dev/null 2>&1; then
    sudo chown -R 472:472 data/grafana
    echo "✓ Grafana data ownership set"
else
    echo "⚠ chown not available - you may need to set ownership manually"
fi

# Set ownership for OpenSearch (1000:1000)
echo "Setting OpenSearch data ownership (1000:1000)..."
if command -v chown >/dev/null 2>&1; then
    sudo chown -R 1000:1000 data/opensearch
    echo "✓ OpenSearch data ownership set"
else
    echo "⚠ chown not available - you may need to set ownership manually"
fi

# Set permissions
echo "Setting directory permissions..."
chmod -R 755 data/
echo "✓ Directory permissions set"

echo ""
echo "🚀 Initialization complete!"
echo ""
