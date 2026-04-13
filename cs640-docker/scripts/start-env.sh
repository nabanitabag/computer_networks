#!/bin/bash
# Usage: start-env.sh <topo_file> [num_routers]
#
# Starts Mininet and POX in the correct order, waits for readiness.
# Designed to be run inside the Docker container.

set -e

TOPO=${1:?Usage: start-env.sh <topo_file> [num_routers]}
NUM_ROUTERS=${2:-2}
WORKDIR=/opt/assign3

cd "$WORKDIR"

# Clean previous state
mn -c 2>/dev/null || true
rm -f ip_config arp_cache rtable.r* /tmp/*.pcap
find . -name "*.pyc" -delete 2>/dev/null || true

echo "=== Starting Mininet with $TOPO ==="

# Start Mininet in background to generate config files
python3 /opt/assign3/run_mininet.py "$TOPO" -a &
MININET_PID=$!

# Wait for ip_config to be generated
echo "Waiting for ip_config..."
for i in $(seq 1 30); do
  [ -f ip_config ] && break
  sleep 1
done

if [ ! -f ip_config ]; then
  echo "ERROR: ip_config not generated after 30s"
  exit 1
fi
echo "ip_config generated."

# Kill mininet (we'll restart it after POX)
sleep 2
kill $MININET_PID 2>/dev/null || true
wait $MININET_PID 2>/dev/null || true
mn -c 2>/dev/null || true

echo "=== Starting POX ==="
cd "$WORKDIR"
python3 /opt/pox/pox.py openflow.of_01 --port=6653 cs640.ofhandler cs640.vnethandler &
POX_PID=$!

# Wait for POX to be ready
sleep 3

echo "=== Restarting Mininet ==="
python3 /opt/assign3/run_mininet.py "$TOPO" -a &
MININET_PID=$!

# Wait for OF connections
echo "Waiting for $NUM_ROUTERS OpenFlow connections..."
for i in $(seq 1 30); do
  CONNECTIONS=$(grep -c "connected" /proc/$POX_PID/fd/1 2>/dev/null || echo "0")
  sleep 1
done

# Give extra time for all switches to connect
sleep 5

echo "=== Environment ready ==="
echo "POX PID: $POX_PID"
echo "Mininet PID: $MININET_PID"

# Save PIDs for later cleanup
echo "$POX_PID" > /tmp/pox.pid
echo "$MININET_PID" > /tmp/mininet.pid

# Keep running
wait
