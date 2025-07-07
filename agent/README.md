# Agent Stack

Monitoring agents for collecting and forwarding logs and security events to the central monitoring infrastructure.

## Overview

The agent stack consists of two main components:

- **Wazuh Agent**: Collects security events, system logs, and performs integrity monitoring
- **Telegraf**: Collects system metrics and forwards them to the monitoring stack
- **Fluent Bit**: Lightweight log processor and forwarder for structured log collection

## Components

### Wazuh Agent
- **Purpose**: Security monitoring, log collection, file integrity monitoring, vulnerability detection
- **Communication**: Connects to Wazuh Manager on port 1514

### Fluent Bit
- **Purpose**: Log parsing, processing, and forwarding to Logstash
- **Output**: HTTP to Logstash on port 12345
- **Configuration**: `config/fluent-bit/fluent-bit.conf`

### Telegraf
- **Purpose**: Collects system metrics (CPU, memory, disk, network)
- **Output**: Sends metrics to VictoriaMetrics for storage and visualization
- **Configuration**: `config/telegraf/telegraf.conf`

## Quick Start

### Prerequisites

- Docker and Docker Compose
- Linux environment with sudo access
- Network connectivity to monitoring stack
- Monitoring instance IP address

### Installation

1. **Make the init script executable:**
   ```bash
   chmod +x init.sh
   ```

2. **Run the initialization:**
   ```bash
   ./init.sh
   ```

## Configuration

### Environment Variables

The initialization script will prompt for:

- **Monitoring Instance IP**: IP address where the monitoring stack is running

### Configuration Files

#### Wazuh Agent Configuration
The Wazuh agent is configured during installation with:
- Manager IP address
- Agent name (hostname)
- Default configuration from Wazuh package
