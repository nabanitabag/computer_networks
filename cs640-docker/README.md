# Docker containerized environment for Lab Assignments

No VM images, no manual POX patching, no Python version maintenance.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Mac, Windows, Linux)
  - Windows users: ensure WSL2 backend is enabled
- Java JDK 11+ and `ant` on your host (for compiling your code)

## Quick Start

```bash
# 1. Download the assignment repo
cd ~/assign

# 2. Build the Docker images (one-time)
make docker-build

# 3. Compile your Java code
make build

# 4. Start the environment with a topology
make start TOPO=pair_rt   # pair_rt.topo (2 routers)

# 5. In a separate terminal, start your routers
make routers-pair      # starts r1 and r2

# 6. Run pings from the mininet CLI
make cli               # attach to mininet CLI

# 7. Tear everything down
make stop
```

## Architecture

```
┌──────────────────────────────────────────────────┐
│  Host Machine                                    │
│  ┌────────────────┐                              │
│  │      src/      │ ← student edits src here     │
│  └───────┬────────┘                              │
│          │ mounted into container                │
│  ┌───────▼──────────────────────────────────┐    │
│  │  Docker Container (privileged)           │    │
│  │                                          │    │
│  │  ┌──────────┐  ┌─────┐  ┌────────────┐   │    │
│  │  │ Mininet  │  │ POX │  │ Java Router│   │    │
│  │  │ (py3)    │←→│(py3)│←→│ (JDK 11)   │   │    │
│  │  └──────────┘  └─────┘  └────────────┘   │    │
│  └──────────────────────────────────────────┘    │
└──────────────────────────────────────────────────┘
```

All three components run in a single privileged container because Mininet
requires host-level network namespace access. Docker Compose orchestrates
startup order via the `scripts/` helpers.

## File Structure

```
assign/
├── docker/
│   └── Dockerfile            # Container image definition
├── docker-compose.yml        # Container orchestration
├── Makefile                  # Student commands
├── scripts/
│   ├── start-env.sh          # Starts mininet + POX
│   ├── start-routers.sh      # Starts Java routers
│   └── run-tests.sh          # Automated grading tests
├── pox_module/cs640/         # POX modules (Python 3 compatible)
├── topos/                    # Topology files
├── http_server/              # Web server for hosts
├── src/                      # ← Student Java source code
├── build.xml                 # Ant build file
└── README.md                 # This file
```

## Troubleshooting

**"Cannot connect to Docker daemon"**
→ Make sure Docker Desktop is running.

**"Permission denied" on Linux**
→ Add yourself to the docker group: `sudo usermod -aG docker $USER` then log out/in.

**Windows: "mininet requires privileged mode"**
→ Ensure WSL2 backend is enabled in Docker Desktop settings.

**Routers fail to connect (KeyError: 'r1')**
→ Wait for POX to show all `connected` lines before starting routers.
   The Makefile handles this automatically with `scripts/start-env.sh`.
