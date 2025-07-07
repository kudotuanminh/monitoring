# Monitoring Infrastructure

A comprehensive monitoring solution using Wazuh, OpenSearch, Grafana, and Logstash for security monitoring and log analysis.

## Overview

This project provides a complete monitoring infrastructure with two main components:

- **Monitoring Stack**: Central monitoring services (Wazuh Manager, OpenSearch, Grafana, Logstash)
- **Agent Stack**: Monitoring agents deployed on target systems (Wazuh Agent, Fluent Bit, Telegraf)


## Quick Start

### Prerequisites

- Docker and Docker Compose
- Linux/Unix environment with sudo access
- Minimum 4GB RAM, 8GB recommended
- 10GB free disk space

### Installation

1. **Clone or download this repository**
2. **Make the init script executable:**
   ```bash
   chmod +x init.sh
   ```
3. **Run the initialization script:**
   ```bash
   ./init.sh --both
   ```

### Command Options

```bash
# Run monitoring stack only
./init.sh --monitoring

# Run agent stack only
./init.sh --agent

# Run both stacks
./init.sh --both

# Skip Wazuh security configuration (for development)
./init.sh --monitoring --skip-wazuh-security

# Skip confirmation prompts (for automation)
./init.sh --both --yes

# Combined options
./init.sh --both --skip-wazuh-security --yes
```

### Short Arguments

```bash
# Short form arguments
./init.sh -b          # Both stacks
./init.sh -m          # Monitoring only
./init.sh -a          # Agent only
./init.sh -s          # Skip Wazuh security
./init.sh -y          # Skip confirmation
./init.sh -h          # Help

# Combined short arguments
./init.sh -b -s -y    # Both stacks, skip security, skip confirmation
```

## Directory Structure

```
monitoring/
├── init.sh                 # Top-level initialization script
├── README.md              # This file
├── monitoring/            # Monitoring stack components
│   ├── init.sh
│   ├── docker-compose.yml
│   ├── config/           # Service configurations
│   ├── dashboards/       # Pre-built dashboards
│   └── data/            # Persistent data
└── agent/                # Agent stack components
    ├── init.sh
    ├── docker-compose.yml
    ├── config/           # Agent configurations
    └── README.md         # Agent-specific documentation
```
