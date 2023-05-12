# Bare essentials docker image install.
# Only installs packages no data
# Models get downloaded after image init in onstart.sh

# cuda is not really necessary because it will be installed in the venv,
# but manual nvidia driver install is a pain, worth the slight overhead
FROM nvidia/cuda:11.8.0-base-ubuntu22.04

ARG DEBIAN_FRONTEND noninteractive

# Add the onstart script for vast.ai
WORKDIR /root
ADD onstart.sh .
RUN chmod +x onstart.sh

RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-utils \
    software-properties-common \
    sudo \
    wget \
    curl \
    python3-pip \
    python3.10-venv \
    python3-dev \
    libglib2.0-0 \
    libsm6 \
    libgl1 \
    libxrender1 \
    libxext6 \
    git \
    nano \
    psmisc \
    pkg-config \
    build-essential \
    google-perftools

# Clean install dir and set keyboard language
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && \
    bash -c 'echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen'

# Add the default user all commands wil be run under
RUN useradd -m -s /bin/bash webui && \
    usermod -aG sudo webui && \
    chown -R webui:webui /home/webui && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    
USER webui
WORKDIR /home/webui

RUN git clone https://github.com/vladmandic/automatic.git
ARG INSTALLDIR="/home/webui/automatic"
WORKDIR $INSTALLDIR

# This is the correct way to activate venv inside a Dockerfile see https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
ENV VIRTUAL_ENV=$INSTALLDIR/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
RUN pip install wheel

# Install torch manually
RUN pip install \
    torch \
    torchaudio \
    torchvision==0.15.1 \
    --index-url https://download.pytorch.org/whl/cu118
    
# skip automatic torch testing for GPU or else CPU will be set and produce errors later
RUN python3 installer.py --skip-torch
