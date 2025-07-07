#!/bin/bash

# Top-Level Monitoring Infrastructure Initialization Script
echo "🔧 Monitoring Infrastructure Manager"
echo "=================================="

# Parse command line arguments
RUN_MONITORING=false
RUN_AGENT=false
SKIP_WAZUH_SECURITY=false
SKIP_CONFIRMATION=false

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -m, --monitoring             Initialize and run monitoring stack only"
    echo "  -a, --agent                  Initialize and run agent stack only"
    echo "  -b, --both                   Initialize and run both monitoring and agent stacks"
    echo "  -s, --skip-wazuh-security    Skip Wazuh indexer security configuration (monitoring stack)"
    echo "  -y, --yes                    Skip confirmation prompts (for automation)"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -m                        # Run monitoring stack only"
    echo "  $0 -a                        # Run agent stack only"
    echo "  $0 -b                        # Run both stacks"
    echo "  $0 -m -s                     # Run monitoring stack, skip security config"
    echo "  $0 -b -y                     # Run both stacks without confirmation"
    echo "  $0 --both --skip-wazuh-security --yes  # Run both, skip security config and confirmation"
    echo ""
    echo "Stack Information:"
    echo "  Monitoring Stack: Wazuh Manager, OpenSearch, Grafana, Logstash"
    echo "  Agent Stack:      Wazuh Agent, Fluent Bit"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--monitoring)
            RUN_MONITORING=true
            shift
            ;;
        -a|--agent)
            RUN_AGENT=true
            shift
            ;;
        -b|--both)
            RUN_MONITORING=true
            RUN_AGENT=true
            shift
            ;;
        -s|--skip-wazuh-security)
            SKIP_WAZUH_SECURITY=true
            shift
            ;;
        -y|--yes)
            SKIP_CONFIRMATION=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "❌ Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# If no specific stack is chosen, ask the user
if [ "$RUN_MONITORING" = false ] && [ "$RUN_AGENT" = false ]; then
    echo ""
    echo "Which stack(s) would you like to initialize?"
    echo "1) Monitoring stack only (Wazuh Manager, OpenSearch, Grafana, Logstash)"
    echo "2) Agent stack only (Wazuh Agent, Fluent Bit)"
    echo "3) Both stacks"
    echo ""
    read -p "Enter your choice (1-3): " choice

    case $choice in
        1)
            RUN_MONITORING=true
            ;;
        2)
            RUN_AGENT=true
            ;;
        3)
            RUN_MONITORING=true
            RUN_AGENT=true
            ;;
        *)
            echo "❌ Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Function to run monitoring stack
run_monitoring_stack() {
    echo ""
    echo "🏗️  Initializing Monitoring Stack..."
    echo "===================================="

    cd monitoring

    if [ ! -f "init.sh" ]; then
        echo "❌ monitoring/init.sh not found!"
        exit 1
    fi

    # Make init.sh executable
    chmod +x init.sh

    # Run with appropriate arguments
    if [ "$SKIP_WAZUH_SECURITY" = true ]; then
        echo "🔍 Debug: SKIP_WAZUH_SECURITY is true, passing -s flag"
        echo "Running monitoring stack initialization (skipping Wazuh security)..."
        ./init.sh -s
    else
        echo "🔍 Debug: SKIP_WAZUH_SECURITY is false, running without -s flag"
        echo "Running monitoring stack initialization..."
        ./init.sh
    fi

    if [ $? -eq 0 ]; then
        echo "✅ Monitoring stack initialization completed successfully!"
    else
        echo "❌ Monitoring stack initialization failed!"
        return 1
    fi

    cd ..
}

# Function to run agent stack
run_agent_stack() {
    echo ""
    echo "🤖 Initializing Agent Stack..."
    echo "=============================="

    cd agent

    if [ ! -f "init.sh" ]; then
        echo "❌ agent/init.sh not found!"
        exit 1
    fi

    # Make init.sh executable
    chmod +x init.sh

    echo "Running agent stack initialization..."
    ./init.sh

    if [ $? -eq 0 ]; then
        echo "✅ Agent stack initialization completed successfully!"
    else
        echo "❌ Agent stack initialization failed!"
        return 1
    fi

    cd ..
}

# Display initialization plan
echo ""
echo "📋 Initialization Plan:"
if [ "$RUN_MONITORING" = true ]; then
    echo "  ✓ Monitoring Stack (Wazuh Manager, OpenSearch, Grafana, Logstash)"
    if [ "$SKIP_WAZUH_SECURITY" = true ]; then
        echo "    - Wazuh security configuration will be skipped"
    fi
fi
if [ "$RUN_AGENT" = true ]; then
    echo "  ✓ Agent Stack (Wazuh Agent, Fluent Bit)"
fi
echo ""

# Debug output
echo "🔍 Debug Info:"
echo "  SKIP_WAZUH_SECURITY = $SKIP_WAZUH_SECURITY"
echo ""

# Confirm before proceeding (unless skipped)
if [ "$SKIP_CONFIRMATION" = false ]; then
    read -p "Do you want to continue with this initialization? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        echo "❌ Initialization cancelled."
        exit 0
    fi
else
    echo "⚡ Skipping confirmation (--yes flag used)"
fi

# Track overall success
OVERALL_SUCCESS=true

# Run monitoring stack if requested
if [ "$RUN_MONITORING" = true ]; then
    run_monitoring_stack
    if [ $? -ne 0 ]; then
        OVERALL_SUCCESS=false
    fi
fi

# Run agent stack if requested
if [ "$RUN_AGENT" = true ]; then
    run_agent_stack
    if [ $? -ne 0 ]; then
        OVERALL_SUCCESS=false
    fi
fi

echo ""
echo "🚀 Monitoring infrastructure setup complete!"
