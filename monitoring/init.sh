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

    # Prompt for Wazuh indexer password
    read -s -p "Enter Wazuh indexer password (will be hidden): " WAZUH_INDEXER_PASSWORD
    echo ""

    # Prompt for Wazuh indexer hashed password
    read -s -p "Enter Wazuh indexer hashed password (bcrypt hash, will be hidden): " WAZUH_INDEXER_HASHED_PASSWORD
    echo ""

    # Prompt for Wazuh API username
    read -p "Enter Wazuh API username [wazuh-wui]: " WAZUH_API_USERNAME
    WAZUH_API_USERNAME=${WAZUH_API_USERNAME:-wazuh-wui}

    # Prompt for Wazuh API password
    read -s -p "Enter Wazuh API password (will be hidden): " WAZUH_API_PASSWORD
    echo ""
    echo ""

    # Create .env file with user input
    cat > .env << EOF
OPENSEARCH_ADMIN_PASSWORD='${OPENSEARCH_PASSWORD}'
GF_ENDPOINT='${GF_ENDPOINT}'
GF_ADMIN_USER='${GF_ADMIN_USER}'
GF_ADMIN_PASSWORD='${GF_ADMIN_PASSWORD}'
WAZUH_INDEXER_PASSWORD='${WAZUH_INDEXER_PASSWORD}'
WAZUH_INDEXER_HASHED_PASSWORD='${WAZUH_INDEXER_HASHED_PASSWORD}'
WAZUH_API_USERNAME='${WAZUH_API_USERNAME}'
WAZUH_API_PASSWORD='${WAZUH_API_PASSWORD}'
EOF
    echo "✓ .env file created with your configuration"
else
    echo "✓ .env file already exists"
fi

# Set vm.max_map_count for OpenSearch/Elasticsearch
echo "Setting vm.max_map_count for OpenSearch..."
if command -v sysctl >/dev/null 2>&1; then
    if sudo sysctl -w vm.max_map_count=262144 >/dev/null 2>&1; then
        echo "✓ vm.max_map_count set to 262144"
    else
        echo "⚠ Failed to set vm.max_map_count - you may need to run the script with sudo:"
        echo "  sudo ./init.sh"
        echo "  Or manually run: sudo sysctl -w vm.max_map_count=262144"
        echo "  Or add 'vm.max_map_count=262144' to /etc/sysctl.conf for persistence"
    fi
else
    echo "⚠ sysctl not available - you may need to set vm.max_map_count manually:"
    echo "  On Linux: sudo sysctl -w vm.max_map_count=262144"
fi

# Generate indexer certificates
echo "Generating indexer certificates..."
if command -v docker >/dev/null 2>&1; then
    # Check if required files exist
    if [ -f config/wazuh/certs.yml ]; then
        # Create certificates directory if it doesn't exist
        mkdir -p data/wazuh/wazuh_indexer_ssl_certs

        # Run certificate generator directly with Docker
        docker run --rm \
            --hostname wazuh-certs-generator \
            -v "$(pwd)/data/wazuh/wazuh_indexer_ssl_certs:/certificates/" \
            -v "$(pwd)/config/wazuh/certs.yml:/config/certs.yml" \
            wazuh/wazuh-certs-generator:0.0.2

        echo "✓ Indexer certificates generated"
    else
        echo "⚠ config/wazuh/certs.yml not found - skipping certificate generation"
        echo "  Make sure the certificate configuration file exists"
    fi
else
    echo "⚠ Docker not available - you may need to generate certificates manually"
    echo "  Run: docker run --rm --hostname wazuh-certs-generator \\"
    echo "       -v \"\$(pwd)/data/wazuh/wazuh_indexer_ssl_certs:/certificates/\" \\"
    echo "       -v \"\$(pwd)/config/wazuh/certs.yml:/config/certs.yml\" \\"
    echo "       wazuh/wazuh-certs-generator:0.0.2"
fi

# Generate wazuh.yml with actual values from .env file
echo "Generating wazuh.yml configuration..."
# Get API credentials from .env file (remove quotes)
WAZUH_API_USERNAME_VALUE=$(grep "WAZUH_API_USERNAME=" .env | cut -d"'" -f2)
WAZUH_API_PASSWORD_VALUE=$(grep "WAZUH_API_PASSWORD=" .env | cut -d"'" -f2)

mkdir -p data/wazuh/wazuh_dashboard
mkdir -p data/wazuh/wazuh_indexer

cat > data/wazuh/wazuh_dashboard/wazuh.yml << EOF
hosts:
- 1513629884013:
    url: "https://wazuh.manager"
    port: 55000
    username: ${WAZUH_API_USERNAME_VALUE}
    password: "${WAZUH_API_PASSWORD_VALUE}"
    run_as: false
EOF
echo "✓ wazuh.yml configuration generated"

# Generate Wazuh indexer internal_users.yml with admin password
echo "Generating Wazuh indexer internal_users.yml..."
# Get the hashed password from .env file (remove quotes)
INDEXER_HASHED_PASSWORD=$(grep "WAZUH_INDEXER_HASHED_PASSWORD=" .env | cut -d"'" -f2)

if [ -n "$INDEXER_HASHED_PASSWORD" ]; then
    # Generate the complete internal_users.yml file
    cat > data/wazuh/wazuh_indexer/internal_users.yml << EOF
---
# This is the internal user database
# The hash value is a bcrypt hash and can be generated with plugin/tools/hash.sh

_meta:
  type: "internalusers"
  config_version: 2

# Define your internal users here

## Demo users

admin:
  hash: "$INDEXER_HASHED_PASSWORD"
  reserved: true
  backend_roles:
  - "admin"
  description: "Demo admin user"

kibanaserver:
  hash: "\$2a\$12\$4AcgAt3xwOWadA5s5blL6ev39OXDNhmOesEoo33eZtrq2N0YrU3H."
  reserved: true
  description: "Demo kibanaserver user"

kibanaro:
  hash: "\$2a\$12\$JJSXNfTowz7Uu5ttXfeYpeYE0arACvcwlPBStB1F.MI7f0U9Z4DGC"
  reserved: false
  backend_roles:
  - "kibanauser"
  - "readall"
  attributes:
    attribute1: "value1"
    attribute2: "value2"
    attribute3: "value3"
  description: "Demo kibanaro user"

logstash:
  hash: "\$2a\$12\$u1ShR4l4uBS3Uv59Pa2y5.1uQuZBrZtmNfqB3iM/.jL0XoV9sghS2"
  reserved: false
  backend_roles:
  - "logstash"
  description: "Demo logstash user"

readall:
  hash: "\$2a\$12\$ae4ycwzwvLtZxwZ82RmiEunBbIPiAmGZduBAjKN0TXdwQFtCwARz2"
  reserved: false
  backend_roles:
  - "readall"
  description: "Demo readall user"

snapshotrestore:
  hash: "\$2y\$12\$DpwmetHKwgYnorbgdvORCenv4NAK8cPUg8AI6pxLCuWf/ALc0.v7W"
  reserved: false
  backend_roles:
  - "snapshotrestore"
  description: "Demo snapshotrestore user"
EOF

    echo "✓ Wazuh indexer internal_users.yml generated with hashed admin password"
else
    echo "⚠ Could not find WAZUH_INDEXER_HASHED_PASSWORD in .env file"
fi

echo ""
echo "🚀 Initialization complete!"
echo ""
