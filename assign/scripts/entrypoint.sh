#!/bin/bash
set -e

# Start Open vSwitch (required by Mininet)
service openvswitch-switch start 2>/dev/null || true

# Wait for OVS to be ready
for i in $(seq 1 10); do
  ovs-vsctl show >/dev/null 2>&1 && break
  sleep 1
done

# Clean any stale mininet state
mn -c 2>/dev/null || true

exec "$@"
