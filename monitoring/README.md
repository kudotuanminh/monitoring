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

1.  **Make the initialization script executable:**

    ```bash
    chmod +x init.sh
    ```

2.  **Generate hashed passwords for Wazuh Indexer authentication:**
    You can use the provided Docker command to generate a bcrypt hash for your Wazuh indexer password:

    ```bash
    docker run --rm -it wazuh/wazuh-indexer:4.12.0 bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh
    ```

    This will prompt you to enter your password and return a bcrypt hash that you can use for the initialization script.

    ### Example Hash Generation

        ```bash
        $ docker run --rm -it wazuh/wazuh-indexer:4.12.0 bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh
        Please enter the password:
        $2y$12$K/SpwjtB.wOHJ/Nc6GVRDuc1h0rM1DfvziFRNPtk27P.c4yDr9njO
        ```

3.  **Initialize the monitoring stack:**

    ```bash
    ./init.sh
    ```

    The script will prompt you for:

    - OpenSearch admin password
    - Grafana endpoint, username, and password
    - Wazuh indexer password (plain text)
    - Wazuh indexer hashed password (bcrypt hash)
    - Wazuh API username and password

4.  **Start the services:**

    ```bash
    docker-compose up -d
    ```

5.  **Access the services:**
    - Grafana: http://localhost:3000
    - OpenSearch Dashboards: http://localhost:5601
    - Wazuh Dashboard: http://localhost:5602
    - VictoriaMetrics: http://localhost:8428

## Generating Hashed Passwords

### For Wazuh Indexer Authentication

The Wazuh indexer requires bcrypt hashed passwords for authentication. You can generate these using Docker:

#### Method 1: Using Wazuh Indexer Container

```bash
docker run --rm -it wazuh/wazuh-indexer:4.12.0 bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh
```

This will prompt you to enter your password and return a bcrypt hash that you can use during initialization.

### Example Hash Generation

```bash
# Example using Docker method
$ docker run --rm -it wazuh/wazuh-indexer:4.12.0 bash /usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh
Please enter the password:
$2y$12$K/SpwjtB.wOHJ/Nc6GVRDuc1h0rM1DfvziFRNPtk27P.c4yDr9njO
```

## Configuration Files

### Directory Structure

```
monitoring/
├── config/
│   ├── grafana/
│   │   ├── datasources/          # Grafana datasource configurations
│   │   ├── dashboards/           # Dashboard provisioning
│   │   └── grafana.ini          # Grafana main configuration
│   └── wazuh/
│       ├── wazuh_dashboard/      # Wazuh dashboard configuration
│       ├── wazuh_indexer/        # Wazuh indexer configuration
│       └── certs.yml            # Certificate generation configuration
├── data/                        # Persistent data volumes (auto-created)
├── docker-compose.yml           # Docker services definition
├── init.sh                     # Initialization script
└── .env                        # Environment variables (auto-created)
```

### Environment Variables

The `.env` file contains sensitive configuration:

-   `OPENSEARCH_ADMIN_PASSWORD` - OpenSearch admin password
-   `GF_ENDPOINT` - Grafana endpoint
-   `GF_ADMIN_USER` - Grafana admin username
-   `GF_ADMIN_PASSWORD` - Grafana admin password
-   `WAZUH_INDEXER_PASSWORD` - Wazuh indexer plain password
-   `WAZUH_INDEXER_HASHED_PASSWORD` - Wazuh indexer bcrypt hash
-   `WAZUH_API_USERNAME` - Wazuh API username
-   `WAZUH_API_PASSWORD` - Wazuh API password

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

## Initialization Process

The `init.sh` script performs the following actions:

1. **Prompts for configuration** - Collects all necessary passwords and settings
2. **Creates .env file** - Stores configuration securely
3. **Creates data directories** - Sets up persistent storage
4. **Sets ownership and permissions** - Configures proper file permissions
5. **Configures system parameters** - Sets `vm.max_map_count` for OpenSearch
6. **Generates SSL certificates** - Creates Wazuh indexer certificates
7. **Creates internal users** - Sets up Wazuh indexer authentication

## Troubleshooting

### Common Issues

1. **vm.max_map_count too low**

    ```bash
    sudo sysctl -w vm.max_map_count=262144
    ```

2. **Permission denied errors**

    - Ensure you run `init.sh` with appropriate privileges
    - Check that data directories have correct ownership

3. **Certificate issues**

    - Verify that `config/wazuh/certs.yml` exists
    - Ensure Docker is running for certificate generation

4. **Password authentication fails**
    - Verify that hashed passwords are properly formatted bcrypt hashes
    - Check that passwords in `.env` are properly quoted

### Logs

View service logs:

```bash
# All services
docker-compose logs

# Specific service
docker-compose logs grafana
docker-compose logs wazuh.manager
docker-compose logs opensearch
```

## Security Considerations

-   All passwords are stored in `.env` file - keep it secure
-   SSL certificates are generated automatically for Wazuh components
-   Change default passwords immediately after setup
-   Consider using Docker secrets for production deployments

## Backup

Important directories to backup:

-   `data/` - All persistent data
-   `config/` - Configuration files
-   `.env` - Environment variables
