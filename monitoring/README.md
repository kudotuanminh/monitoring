# Monitoring Stack

A comprehensive monitoring stack using Docker Compose with Grafana, OpenSearch, Wazuh, and VictoriaMetrics.

## Overview

This monitoring stack provides:

-   **Grafana** - Data visualization and dashboards
-   **OpenSearch** - Search and analytics engine
-   **VictoriaMetrics** - Time series database for metrics
-   **Wazuh** - Security monitoring and threat detection
    -   Wazuh Manager - Core security platform
    -   Wazuh Indexer - Data indexing and storage
    -   Wazuh Dashboard - Web interface

## Prerequisites

-   Docker and Docker Compose installed
-   At least 4GB of available RAM
-   Administrator/sudo privileges (for setting system parameters)

## Quick Start

1. **Make the initialization script executable:**
   ```bash
   chmod +x init.sh
   ```

2. **Generate hashed passwords for Wazuh authentication:**
   Before running the initialization script, you'll need to generate bcrypt hashes for both the Wazuh indexer admin and kibanaserver users:

   ```bash
   # Generate hash for Wazuh indexer admin password
   docker run --rm -it wazuh/wazuh-indexer:4.12.0 bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh

   # Generate hash for Wazuh kibanaserver password
   docker run --rm -it wazuh/wazuh-indexer:4.12.0 bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh
   ```

   **Warning**: Don't use the `$` or `&` characters in your passwords. These characters can cause errors during deployment.

3. **Run the initialization script:**
   ```bash
   ./init.sh
   ```

   The script will prompt you for:
   - OpenSearch admin password
   - Grafana endpoint, username, and password
   - Wazuh indexer password (plain text) and hashed password (bcrypt hash)
   - Wazuh kibanaserver password (plain text) and hashed password (bcrypt hash)
   - Wazuh API username and password

4. **Automatic startup:**
   The initialization script will automatically:
   - Create all configuration files
   - Set up proper permissions and ownership
   - Generate SSL certificates for Wazuh
   - Start all services with `docker-compose up -d`
   - Configure Wazuh indexer security settings

5. **Access the services:**
   - Grafana: http://localhost:3000
   - OpenSearch Dashboards: http://localhost:5601
   - Wazuh Dashboard: https://localhost:5602
   - VictoriaMetrics: http://localhost:8428

## Important Notes
-   The initialization script will create a `.env` file containing sensitive information. Ensure this file is kept secure.
-   By default, Grafana does not get OpenSearch's version information. You may need to manually configure the OpenSearch data source in Grafana after the initial setup.
-   Manually import Grafana dashboards from `dashboards/`.

## Manual Startup (Alternative)

If you prefer to start services manually or if the automatic startup fails:

1. **Run initialization without startup:**
   The init.sh script will handle startup automatically, but if you need to start manually:

2. **Start services:**
   ```bash
   docker-compose up -d
   ```

3. **Apply Wazuh security configuration:**
   ```bash
   # Wait for services to initialize (2-5 minutes), then run:
   docker exec -it monitoring-wazuh.indexer-1 bash -c 'INSTALLATION_DIR=/usr/share/wazuh-indexer; CACERT=$INSTALLATION_DIR/certs/root-ca.pem; KEY=$INSTALLATION_DIR/certs/admin-key.pem; CERT=$INSTALLATION_DIR/certs/admin.pem; JAVA_HOME=/usr/share/wazuh-indexer/jdk bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh -cd /usr/share/wazuh-indexer/opensearch-security/ -nhnv -cacert $CACERT -cert $CERT -key $KEY -p 9200 -icl'
   ```

## Configuration Files

### Directory Structure

```
monitoring/
├── config/
│   ├── grafana/
│   │   ├── datasources/         # Grafana datasource configurations
│   │   └── grafana.ini          # Grafana main configuration
│   └── wazuh/
│       ├── wazuh_dashboard/     # Wazuh dashboard configuration
│       ├── wazuh_indexer/       # Wazuh indexer configuration
│       └── certs.yml            # Certificate generation configuration
├── data/                        # Persistent data volumes (auto-created)
├── docker-compose.yml           # Docker services definition
├── init.sh                      # Initialization script
└── .env                         # Environment variables (auto-created)
```

### Environment Variables

The `.env` file contains sensitive configuration:

- `OPENSEARCH_ADMIN_PASSWORD` - OpenSearch admin password
- `GF_ENDPOINT` - Grafana endpoint
- `GF_ADMIN_USER` - Grafana admin username
- `GF_ADMIN_PASSWORD` - Grafana admin password
- `WAZUH_INDEXER_PASSWORD` - Wazuh indexer plain password
- `WAZUH_INDEXER_HASHED_PASSWORD` - Wazuh indexer bcrypt hash
- `WAZUH_KIBANA_PASSWORD` - Wazuh kibanaserver plain password
- `WAZUH_KIBANA_HASHED_PASSWORD` - Wazuh kibanaserver bcrypt hash
- `WAZUH_API_USERNAME` - Wazuh API username
- `WAZUH_API_PASSWORD` - Wazuh API password

## Services and Ports

| Service               | Internal Port              | External Port              | Description                 |
| --------------------- | -------------------------- | -------------------------- | --------------------------- |
| Grafana               | 3000                       | 3000                       | Web interface               |
| OpenSearch            | 9200                       | 9200                       | REST API                    |
| OpenSearch Dashboards | 5601                       | 5601                       | Web interface               |
| VictoriaMetrics       | 8428                       | 8428                       | HTTP API                    |
| Wazuh Manager         | 1514, 1515, 514/udp, 55000 | 1514, 1515, 514/udp, 55000 | Agent communication and API |
| Wazuh Indexer         | 9201                       | 9201                       | Internal indexing           |
| Wazuh Dashboard       | 5602                       | 5602                       | Web interface               |
