FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago

# ── System packages ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Mininet + Open vSwitch
    mininet openvswitch-switch openvswitch-common \
    # Python 3 + deps for POX and Twisted
    python3 python3-pip python3-dev \
    # Java 11 for student router code
    default-jdk ant \
    # Networking tools
    net-tools iputils-ping tcpdump curl wget iproute2 \
    # Misc
    git sudo vim nano procps psmisc tmux \
    && rm -rf /var/lib/apt/lists/*

# ── Python 3 packages ────────────────────────────────────────────
RUN pip3 install --no-cache-dir twisted zope.interface ltprotocol

# ── POX (Python 3 compatible branch) ─────────────────────────────
RUN git clone -b gar-experimental https://github.com/noxrepo/pox.git /opt/pox


# ── cs640 POX modules (pre-patched for Python 3) ────────────────
COPY pox_module/cs640/ /opt/pox/ext/cs640/

# ── Working directory ────────────────────────────────────────────
RUN mkdir -p /opt/assign3
WORKDIR /opt/assign3

# ── Helper scripts ───────────────────────────────────────────────
COPY scripts/ /opt/scripts/
RUN chmod +x /opt/scripts/*.sh

# ── Default topology files ───────────────────────────────────────
COPY topos/ /opt/assign3/topos/

# ── HTTP server for hosts ────────────────────────────────────────
COPY http_server/ /opt/assign3/http_server/

# ── OVS needs to be started inside the container ─────────────────
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
