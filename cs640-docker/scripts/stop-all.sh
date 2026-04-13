#!/bin/bash
# Clean shutdown of all assignment components

echo "=== Stopping all components ==="

# Kill Java routers
pkill -f VirtualNetwork.jar 2>/dev/null || true

# Kill POX
pkill -f pox.py 2>/dev/null || true

# Kill mininet
pkill -f run_mininet 2>/dev/null || true

# Clean mininet state
mn -c 2>/dev/null || true

# Clean temp files
rm -f /tmp/*.pid /tmp/*.pcap

echo "=== All components stopped ==="
