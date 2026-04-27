# CS 640 — Assignment Makefile
# ================================
#
# Student commands:
#   make docker-build    Build the Docker image (one-time)
#   make build           Compile Java source
#   make start TOPO=<name>  Start env with specified topo (e.g., TOPO=pair_rt or TOPO=inclass_sw)
#   make routers NUM=<n> Start n routers (e.g., NUM=2 for pair_rt)
#   make cli             Attach to mininet CLI
#   make stop            Tear everything down

CONTAINER = cs640
SHELL := /bin/bash
TOPO ?= pair_rt  # Default topology; override with make start TOPO=linear5_sw

# Infer number of routers based on topology (customize as needed for new topos)
ifeq ($(TOPO),pair_rt)
    NUM_ROUTERS ?= 2
else ifeq ($(TOPO),inclass_sw)
    NUM_ROUTERS ?= 4
else
    NUM_ROUTERS ?= 2  # Default fallback
endif

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

.PHONY: start stop cli

start: docker-up build
	@echo "=== Starting $(TOPO).topo environment ==="
	@echo "This will open multiple tmux panes inside the container."
	docker compose exec $(CONTAINER) bash -c '\
		/opt/scripts/stop-all.sh && \
		rm -f ip_config arp_cache rtable.r* && \
		echo "--- Generating config files ---" && \
		timeout 15 python3 run_mininet.py topos/$(TOPO).topo -a < /dev/null > /dev/null 2>&1 || true && \
		mn -c 2>/dev/null && \
		echo "--- Starting POX ---" && \
		python3 /opt/pox/pox.py openflow.of_01 --port=6653 cs640.ofhandler cs640.vnethandler & \
		sleep 3 && \
		echo "--- Starting Mininet ---" && \
		echo "Use: make cli (in another terminal) to interact with mininet" && \
		echo "Use: make routers NUM=$(NUM_ROUTERS) (in another terminal) to start routers" && \
		python3 run_mininet.py topos/$(TOPO).topo -a'

routers: 
	docker compose exec $(CONTAINER) /opt/scripts/start-routers.sh $(NUM_ROUTERS)

cli:
	@echo "Attaching to mininet CLI..."
	@echo "Tip: type 'h1 ping h2 -c 1' to test connectivity"
	docker compose exec $(CONTAINER) bash -c 'cat /proc/*/cmdline 2>/dev/null | tr "\0" " " | grep -q run_mininet && echo "Mininet is running" || echo "WARNING: Mininet not running. Use make start TOPO=<name> first."'

stop:
	docker compose exec $(CONTAINER) /opt/scripts/stop-all.sh 2>/dev/null || true
	docker compose down