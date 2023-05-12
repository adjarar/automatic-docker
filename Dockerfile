# Bare essentials docker image for vlad's automatic and invokeai.
# Only installs packages, no data. Models get downloaded after
# docker image init in onstart.sh. Also automatically syncs latest
# git commit for automatic. Made to run with github actions.

# this image contains the minimum requirments to run the apps correctly
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND noninteractive

# vast.ai uses this script when docker image finishes loading.
# It downloads the user settings and syncs automatic's repo with the latest version.
WORKDIR /root
ADD onstart.sh .
RUN chmod +x onstart.sh

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    software-properties-common \
    sudo \
    wget \
    curl \
    git \
    nano \
    psmisc \
    python3-pip \
    python3.10-venv \
    python3-dev \
    libglib2.0-0 \
    libsm6 \
    libgl1 \
    libxrender1 \
    libxext6 \
    pkg-config \
    build-essential \
    google-perftools

# Clean the install dir and set keyboard language
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && \
    bash -c 'echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen'

# Add the default user all commands wil be run under
RUN useradd -m -g sudo -s /bin/bash webui && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to the new user, all commands will now be run as webui
USER webui
WORKDIR /home/$(whoami)

# pull in Vlad's automatic and switch to its directory
RUN git clone https://github.com/vladmandic/automatic.git
ARG AUTOMATIC_ROOT="/home/$(whoami)/automatic"
WORKDIR $AUTOMATIC_ROOT

# Create a virtual enviornment and activate it, all commands are now run from here
RUN python3 -m venv $AUTOMATIC_ROOT/venv
ENV PATH="$AUTOMATIC_ROOT/venv/bin:$PATH"

# wheel is used to build packages in python, install it first before anything else
RUN pip install wheel

# There are no GPU's on the github build pods, so CPU will be set as the platform of choise
# if ran with installer.py. This is not what we want. To prevent this we install torch manually,
# then we pass --skip-torch to installer.py to prevent the gpu check and setting to cpu.
RUN pip install \
    torch \
    torchaudio \
    torchvision==0.15.1 \
    --index-url https://download.pytorch.org/whl/cu118

# This will install all automatic dependencies minus torch, which we already installed
RUN python3 installer.py --skip-torch

# Install invokeai

# Set the systems bin back in its place
ENV PATH="/usr/local/bin:$PATH"
