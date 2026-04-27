#!/bin/bash
# Usage: start-routers.sh <num_routers>
# Starts Java VirtualNetwork routers r1..rN in background

NUM_ROUTERS=${1:?Usage: start-routers.sh <num_routers>}
WORKDIR=/opt/assign

cd "$WORKDIR"

if [ ! -f VirtualNetwork.jar ]; then
  echo "ERROR: VirtualNetwork.jar not found. Run 'ant dist' first."
  exit 1
fi

if [ ! -f arp_cache ]; then
  echo "ERROR: arp_cache not found. Start mininet first."
  exit 1
fi

echo "=== Starting $NUM_ROUTERS routers ==="

for i in $(seq 1 "$NUM_ROUTERS"); do
  echo "Starting router r$i..."
  java -jar VirtualNetwork.jar -v "r$i" -a arp_cache &
  echo $! > "/tmp/router_r${i}.pid"
  sleep 1
done

# Wait for routers to connect
echo "Waiting for routers to initialize..."
sleep 10

echo "=== All routers started ==="
echo "Router PIDs:"
for i in $(seq 1 "$NUM_ROUTERS"); do
  echo "  r$i: $(cat /tmp/router_r${i}.pid)"
done
