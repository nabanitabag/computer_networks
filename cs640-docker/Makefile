# CS 640 — Assignment 3 Makefile
# ================================
#
# Student commands:
#   make docker-build    Build the Docker image (one-time)
#   make build           Compile Java source
#   make start-pair      Start env with pair_rt.topo
#   make start-k4        Start env with k4.topo
#   make routers-pair    Start 2 routers (r1, r2)
#   make routers-k4      Start 4 routers (r1-r4)
#   make cli             Attach to mininet CLI
#   make stop            Tear everything down
#
# TA commands:
#   make grade-setup TEAM=<name> SRC=<path>
#   make grade-pair      Run pair_rt rubric tests
#   make grade-k4        Run k4 rubric tests
#   make grade-reset     Reset between students
#   make grade-all       Run full rubric (pair + k4)

CONTAINER = cs640-router
SHELL := /bin/bash

# ─── Docker ──────────────────────────────────────────────────────

.PHONY: docker-build docker-up docker-down docker-shell

docker-build:
	docker compose build

docker-up:
	docker compose up -d

docker-down:
	docker compose down

docker-shell:
	docker compose exec $(CONTAINER) bash

# ─── Build ───────────────────────────────────────────────────────

.PHONY: build clean

build: docker-up
	docker compose exec $(CONTAINER) ant clean dist
	@echo "✓ Build complete — VirtualNetwork.jar ready"

clean:
	docker compose exec $(CONTAINER) ant clean

# ─── Student: Start Environment ──────────────────────────────────

.PHONY: start-pair start-k4 stop cli

start-pair: docker-up build
	@echo "=== Starting pair_rt.topo environment ==="
	@echo "This will open multiple tmux panes inside the container."
	docker compose exec $(CONTAINER) bash -c '\
		/opt/scripts/stop-all.sh && \
		rm -f ip_config arp_cache rtable.r* && \
		echo "--- Generating config files ---" && \
		timeout 15 python3 run_mininet.py topos/pair_rt.topo -a < /dev/null > /dev/null 2>&1 || true && \
		mn -c 2>/dev/null && \
		echo "--- Starting POX ---" && \
		python3 /opt/pox/pox.py openflow.of_01 --port=6653 cs640.ofhandler cs640.vnethandler & \
		sleep 3 && \
		echo "--- Starting Mininet ---" && \
		echo "Use: make cli (in another terminal) to interact with mininet" && \
		echo "Use: make routers-pair (in another terminal) to start routers" && \
		python3 run_mininet.py topos/pair_rt.topo -a'

start-k4: docker-up build
	@echo "=== Starting k4.topo environment ==="
	docker compose exec $(CONTAINER) bash -c '\
		/opt/scripts/stop-all.sh && \
		rm -f ip_config arp_cache rtable.r* && \
		echo "--- Generating config files ---" && \
		timeout 15 python3 run_mininet.py topos/k4.topo -a < /dev/null > /dev/null 2>&1 || true && \
		mn -c 2>/dev/null && \
		echo "--- Starting POX ---" && \
		python3 /opt/pox/pox.py openflow.of_01 --port=6653 cs640.ofhandler cs640.vnethandler & \
		sleep 3 && \
		echo "--- Starting Mininet ---" && \
		echo "Use: make cli (in another terminal) to interact with mininet" && \
		echo "Use: make routers-k4 (in another terminal) to start routers" && \
		python3 run_mininet.py topos/k4.topo -a'

routers-pair: 
	docker compose exec $(CONTAINER) /opt/scripts/start-routers.sh 2

routers-k4:
	docker compose exec $(CONTAINER) /opt/scripts/start-routers.sh 4

cli:
	@echo "Attaching to mininet CLI..."
	@echo "Tip: type 'h1 ping h2 -c 1' to test connectivity"
	docker compose exec $(CONTAINER) bash -c 'cat /proc/*/cmdline 2>/dev/null | tr "\0" " " | grep -q run_mininet && echo "Mininet is running" || echo "WARNING: Mininet not running. Use make start-pair or make start-k4 first."'

stop:
	docker compose exec $(CONTAINER) /opt/scripts/stop-all.sh 2>/dev/null || true
	docker compose down

# ─── TA: Grading ─────────────────────────────────────────────────

.PHONY: grade-setup grade-pair grade-k4 grade-all grade-reset

# Replace student source and rebuild
# Usage: make grade-setup TEAM=g002-bhargava SRC=~/submissions/g002/src
grade-setup:
ifndef TEAM
	$(error TEAM is required. Usage: make grade-setup TEAM=<name> SRC=<path>)
endif
ifndef SRC
	$(error SRC is required. Usage: make grade-setup TEAM=<name> SRC=<path>)
endif
	@echo "=== Setting up $(TEAM) ==="
	rm -rf src
	cp -R $(SRC) src/
	mkdir -p grading-output
	$(MAKE) build
	@echo "✓ $(TEAM) built successfully"

# Run pair_rt tests interactively
# TA should watch output and record scores
grade-pair:
	@echo "============================================="
	@echo "  PAIR_RT RUBRIC (2.5 pts)"
	@echo "============================================="
	@echo ""
	@echo "Starting environment..."
	docker compose exec $(CONTAINER) bash -c '\
		/opt/scripts/stop-all.sh 2>/dev/null; \
		rm -f ip_config arp_cache rtable.r*; \
		timeout 15 python3 run_mininet.py topos/pair_rt.topo -a < /dev/null > /dev/null 2>&1 || true; \
		mn -c 2>/dev/null; \
		python3 /opt/pox/pox.py openflow.of_01 --port=6653 cs640.ofhandler cs640.vnethandler > /tmp/pox.log 2>&1 & \
		sleep 5; \
		python3 run_mininet.py topos/pair_rt.topo -a < /dev/null > /dev/null 2>&1 & \
		sleep 5; \
		/opt/scripts/start-routers.sh 2; \
		echo ""; \
		echo "=== PAIR TEST 1: h1 ping h2 (0.5pt, expect TTL 63) ==="; \
		sleep 15; \
		mnexec -a h1 ping -c 2 -n $$(grep h2-eth0 ip_config | cut -d" " -f2) 2>&1 || echo "FAILED"; \
		echo ""; \
		echo "=== PAIR TEST 2: h1 ping h3 (1.0pt, expect TTL 62) ==="; \
		mnexec -a h1 ping -c 1 -n $$(grep h3-eth0 ip_config | cut -d" " -f2) 2>&1 || echo "FAILED"; \
		echo ""; \
		echo "=== LINK DOWN: r1 <-> r2 ==="; \
		ip link set r1-eth3 down 2>/dev/null; ip link set r2-eth3 down 2>/dev/null; \
		echo "=== PAIR TEST 3: h1 ping h3 (should fail) ==="; \
		mnexec -a h1 ping -c 1 -n $$(grep h3-eth0 ip_config | cut -d" " -f2) 2>&1 || echo "FAILED (expected)"; \
		echo ""; \
		echo "=== LINK UP: r1 <-> r2 ==="; \
		ip link set r1-eth3 up 2>/dev/null; ip link set r2-eth3 up 2>/dev/null; \
		echo "Waiting 40 seconds for RIP reconvergence..."; \
		sleep 40; \
		echo "=== PAIR TEST 4: h1 ping h3 (1.0pt, expect TTL 62) ==="; \
		mnexec -a h1 ping -c 1 -n $$(grep h3-eth0 ip_config | cut -d" " -f2) 2>&1 || echo "FAILED"; \
		echo ""; \
		echo "=== PAIR TESTS COMPLETE ==="'

# Run k4 tests interactively
grade-k4:
	@echo "============================================="
	@echo "  K4 RUBRIC (7.5 pts)"
	@echo "============================================="
	@echo ""
	@echo "Starting environment..."
	docker compose exec -T $(CONTAINER) bash -c '\
		/opt/scripts/stop-all.sh 2>/dev/null; \
		rm -f ip_config arp_cache rtable.r*; \
		timeout 15 python3 run_mininet.py topos/k4.topo -a < /dev/null > /dev/null 2>&1 || true; \
		mn -c 2>/dev/null; \
		python3 /opt/pox/pox.py openflow.of_01 --port=6653 cs640.ofhandler cs640.vnethandler > /tmp/pox.log 2>&1 & \
		sleep 5; \
		python3 run_mininet.py topos/k4.topo -a < /dev/null > /dev/null 2>&1 & \
		sleep 5; \
		/opt/scripts/start-routers.sh 4; \
		sleep 15; \
		H2=$$(grep h2-eth0 ip_config | cut -d" " -f2); \
		H3=$$(grep h3-eth0 ip_config | cut -d" " -f2); \
		H4=$$(grep h4-eth0 ip_config | cut -d" " -f2); \
		echo "H2=$$H2 H3=$$H3 H4=$$H4"; \
		echo ""; \
		echo "=== K4 STARTUP (0.5pt total, all TTL 62) ==="; \
		for pair in "h1 $$H2" "h1 $$H3" "h1 $$H4" "h2 $$H3" "h2 $$H4" "h3 $$H4"; do \
		  src=$$(echo $$pair | cut -d" " -f1); dst=$$(echo $$pair | cut -d" " -f2); \
		  echo "--- $$src -> $$dst ---"; \
		  mnexec -a $$src ping -c 1 -n $$dst 2>&1 || echo "FAILED"; \
		done; \
		echo ""; \
		echo "=== LINK DOWN: r2 <-> r4 ==="; \
		ip link set r2-eth4 down 2>/dev/null; ip link set r4-eth4 down 2>/dev/null; \
		echo "Waiting 30s..."; sleep 30; \
		echo "=== K4 TEST: h2 ping h4 (1.0pt, expect TTL 61) ==="; \
		mnexec -a h2 ping -c 1 -n $$H4 2>&1 || echo "FAILED"; \
		echo "=== K4 TEST: h1 ping h3 (1.0pt, expect TTL 62) ==="; \
		mnexec -a h1 ping -c 1 -n $$H3 2>&1 || echo "FAILED"; \
		echo ""; \
		echo "=== LINK DOWN: r1 <-> r3 ==="; \
		ip link set r1-eth4 down 2>/dev/null; ip link set r3-eth4 down 2>/dev/null; \
		echo "Waiting 30s..."; sleep 30; \
		echo "=== K4 TEST: h1 ping h3 (1.0pt, expect TTL 61) ==="; \
		mnexec -a h1 ping -c 1 -n $$H3 2>&1 || echo "FAILED"; \
		echo ""; \
		echo "=== LINK DOWN: r1 <-> r4 ==="; \
		ip link set r1-eth3 down 2>/dev/null; ip link set r4-eth3 down 2>/dev/null; \
		echo "Waiting 30s..."; sleep 30; \
		echo "=== K4 TEST: h1 ping h4 (1.0pt, expect TTL 60) ==="; \
		mnexec -a h1 ping -c 1 -n $$H4 2>&1 || echo "FAILED"; \
		echo ""; \
		echo "=== LINK UP: r1 <-> r3 ==="; \
		ip link set r1-eth4 up 2>/dev/null; ip link set r3-eth4 up 2>/dev/null; \
		echo "Waiting 15s..."; sleep 15; \
		echo "=== K4 TEST: h1 ping h4 (1.0pt, expect TTL 61) ==="; \
		mnexec -a h1 ping -c 1 -n $$H4 2>&1 || echo "FAILED"; \
		echo ""; \
		echo "=== FULL RECOVERY: r2<->r4 up, r1<->r4 up ==="; \
		ip link set r2-eth4 up 2>/dev/null; ip link set r4-eth4 up 2>/dev/null; \
		ip link set r1-eth3 up 2>/dev/null; ip link set r4-eth3 up 2>/dev/null; \
		echo "Waiting 15s..."; sleep 15; \
		echo "=== K4 RECOVERY (2.0pt total, all TTL 62) ==="; \
		for pair in "h1 $$H2" "h1 $$H3" "h1 $$H4" "h2 $$H3" "h2 $$H4" "h3 $$H4"; do \
		  src=$$(echo $$pair | cut -d" " -f1); dst=$$(echo $$pair | cut -d" " -f2); \
		  echo "--- $$src -> $$dst ---"; \
		  mnexec -a $$src ping -c 1 -n $$dst 2>&1 || echo "FAILED"; \
		done; \
		echo ""; \
		echo "=== K4 TESTS COMPLETE ==="'

grade-all: grade-pair grade-k4

grade-reset:
	docker compose exec $(CONTAINER) /opt/scripts/stop-all.sh 2>/dev/null || true
	rm -rf src
	@echo "✓ Ready for next submission"

# ─── Utilities ───────────────────────────────────────────────────

.PHONY: logs status

logs:
	docker compose exec $(CONTAINER) cat /tmp/pox.log 2>/dev/null || echo "No POX logs found"

status:
	@echo "=== Container ==="
	docker compose ps
	@echo ""
	@echo "=== Processes ==="
	docker compose exec $(CONTAINER) ps aux --forest 2>/dev/null | grep -E "pox|java|mininet|python" || echo "No relevant processes"
