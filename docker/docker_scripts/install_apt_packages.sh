#!/bin/bash -l

set -Eeuxo pipefail

apt-get update 1>/dev/null

# sudo is not needed but still installed for compatibility
apt-get install --yes --no-install-recommends \
    ca-certificates \
    gawk \
    libabsl-dev \
    libcairo2-dev \
    libgdal-dev \
    libpng-dev \
    libssl-dev \
    libudunits2-dev \
    pandoc \
    python-is-python3 \
    python3 \
    r-base \
    r-base-dev \
    sshpass \
    sudo \
1>/dev/null

rm -rf /var/lib/apt/lists/*
