#!/bin/bash
# Automated grading for Assignment 3
# Usage: run-tests.sh <pair|k4>
#
# Runs rubric tests inside mininet and reports results.
# Must be run after start-env.sh and start-routers.sh.

MODE=${1:?Usage: run-tests.sh <pair|k4>}
SCORE=0
TOTAL=0
COMMENTS=""

# Helper: run a ping from mininet and capture TTL
# Usage: do_ping <src> <dst> <count> <expected_ttl> <points> <description>
do_ping() {
  local src=$1 dst=$2 count=$3 expected_ttl=$4 points=$5 desc=$6
  TOTAL=$(echo "$TOTAL + $points" | bc)

  echo ""
  echo "--- TEST: $desc ($points pt) ---"
  echo "    $src ping $dst -c $count (expecting TTL $expected_ttl)"

  # Run ping via mininet's py command
  local result
  result=$(python3 -c "
import subprocess
p = subprocess.run(['mnexec', '-a', '$src', 'ping', '-c', '$count', '-n', '$dst'],
                   capture_output=True, text=True, timeout=15)
print(p.stdout)
print(p.stderr)
" 2>&1)

  # Extract TTL from ping output
  local ttl
  ttl=$(echo "$result" | grep -oP 'ttl=\K\d+' | head -1)
  local loss
  loss=$(echo "$result" | grep -oP '\d+(?=% packet loss)' | head -1)

  if [ -z "$loss" ]; then
    loss="100"
  fi

  if [ "$expected_ttl" = "fail" ]; then
    # Expecting failure
    if [ "$loss" = "100" ]; then
      echo "    PASS: ping failed as expected"
      SCORE=$(echo "$SCORE + $points" | bc)
    else
      echo "    FAIL: ping should have failed but got TTL=$ttl"
      COMMENTS="$COMMENTS\n$desc: expected failure but ping succeeded (TTL=$ttl)"
    fi
  else
    # Expecting success with specific TTL
    if [ "$loss" != "0" ] && [ "$loss" != "" ]; then
      echo "    FAIL: $loss% packet loss (expected 0%)"
      COMMENTS="$COMMENTS\n$desc: $loss% packet loss"
    elif [ "$ttl" = "$expected_ttl" ]; then
      echo "    PASS: TTL=$ttl as expected"
      SCORE=$(echo "$SCORE + $points" | bc)
    elif [ -n "$ttl" ]; then
      echo "    PARTIAL: TTL=$ttl (expected $expected_ttl) — suboptimal path"
      half=$(echo "$points / 2" | bc -l)
      SCORE=$(echo "$SCORE + $half" | bc)
      COMMENTS="$COMMENTS\n$desc: TTL=$ttl (expected $expected_ttl, suboptimal path)"
    else
      echo "    FAIL: no response"
      COMMENTS="$COMMENTS\n$desc: no response"
    fi
  fi
}

# Helper: bring a link up or down
link_action() {
  local node1=$1 node2=$2 action=$3
  echo ""
  echo ">>> link $node1 $node2 $action"
  # Use mininet's Python API
  python3 -c "
from mininet.net import Mininet
from mininet.cli import CLI
import subprocess
subprocess.run(['ovs-vsctl', '--if-exists', 'del-port', 'todo'], capture_output=True)
" 2>/dev/null || true

  # Direct OVS link manipulation
  if [ "$action" = "down" ]; then
    ip link set "${node1}-${node2}" down 2>/dev/null || true
    ip link set "${node2}-${node1}" down 2>/dev/null || true
  else
    ip link set "${node1}-${node2}" up 2>/dev/null || true
    ip link set "${node2}-${node1}" up 2>/dev/null || true
  fi
}

wait_seconds() {
  local secs=$1
  echo ""
  echo ">>> Waiting ${secs}s for RIP convergence..."
  sleep "$secs"
}

# =====================================================================
# PAIR_RT TESTS (2.5 pts)
# =====================================================================
if [ "$MODE" = "pair" ]; then
  echo "============================================="
  echo "  PAIR_RT.TOPO TESTS (2.5 pts total)"
  echo "============================================="

  wait_seconds 15

  do_ping h1 h2 2 63 0.5 "pair: h1↔h2 base connectivity"
  do_ping h1 h3 1 62 1.0 "pair: h1↔h3 startup route exchange"

  link_action r1 r2 down
  do_ping h1 h3 1 fail 0.0 "pair: h1↔h3 should fail after link down"

  link_action r1 r2 up
  wait_seconds 40

  do_ping h1 h3 1 62 1.0 "pair: h1↔h3 recovery after link restored"

# =====================================================================
# K4 TESTS (7.5 pts)
# =====================================================================
elif [ "$MODE" = "k4" ]; then
  echo "============================================="
  echo "  K4.TOPO TESTS (7.5 pts total)"
  echo "============================================="

  wait_seconds 15

  echo ""
  echo "--- STARTUP CONNECTIVITY (0.5 pt) ---"
  # ¼ pt per pair, 6 pairs = 1.5 total but rubric says 0.5 total
  # so approximately 1/12 per pair
  do_ping h1 h2 3 62 0.083 "k4 startup: h1↔h2"
  do_ping h1 h3 1 62 0.083 "k4 startup: h1↔h3"
  do_ping h1 h4 1 62 0.083 "k4 startup: h1↔h4"
  do_ping h2 h3 1 62 0.083 "k4 startup: h2↔h3"
  do_ping h2 h4 1 62 0.083 "k4 startup: h2↔h4"
  do_ping h3 h4 1 62 0.083 "k4 startup: h3↔h4"

  echo ""
  echo "--- DEGRADATION: r2↔r4 DOWN (2.0 pt) ---"
  link_action r2 r4 down
  wait_seconds 30

  do_ping h2 h4 1 61 1.0 "k4 degrade: h2↔h4 via alternate path"
  do_ping h1 h3 1 62 1.0 "k4 degrade: h1↔h3 still direct"

  echo ""
  echo "--- BREAK RING: r1↔r3 DOWN (1.0 pt) ---"
  link_action r1 r3 down
  wait_seconds 30

  do_ping h1 h3 1 61 1.0 "k4 ring break: h1↔h3 alternate path"

  echo ""
  echo "--- LONGER PATH: r1↔r4 DOWN (1.0 pt) ---"
  link_action r1 r4 down
  wait_seconds 30

  do_ping h1 h4 1 60 1.0 "k4 long path: h1↔h4 via 4 hops"

  echo ""
  echo "--- PARTIAL RECOVERY: r1↔r3 UP (1.0 pt) ---"
  link_action r1 r3 up
  wait_seconds 15

  do_ping h1 h4 1 61 1.0 "k4 partial recovery: h1↔h4 shorter path"

  echo ""
  echo "--- FULL RECOVERY (2.0 pt) ---"
  link_action r2 r4 up
  link_action r1 r4 up
  wait_seconds 15

  do_ping h1 h2 1 62 0.333 "k4 recovery: h1↔h2"
  do_ping h1 h3 1 62 0.333 "k4 recovery: h1↔h3"
  do_ping h1 h4 1 62 0.333 "k4 recovery: h1↔h4"
  do_ping h2 h3 1 62 0.333 "k4 recovery: h2↔h3"
  do_ping h2 h4 1 62 0.333 "k4 recovery: h2↔h4"
  do_ping h3 h4 1 62 0.333 "k4 recovery: h3↔h4"

else
  echo "Unknown mode: $MODE"
  echo "Usage: run-tests.sh <pair|k4>"
  exit 1
fi

# =====================================================================
# SUMMARY
# =====================================================================
echo ""
echo "============================================="
echo "  RESULTS"
echo "============================================="
echo "  Score: $SCORE / $TOTAL"
echo ""
if [ -n "$COMMENTS" ]; then
  echo "  Issues found:"
  echo -e "$COMMENTS"
fi
echo "============================================="
