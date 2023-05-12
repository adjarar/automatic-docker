FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND noninteractive

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

RUN useradd -m -s /bin/bash webui && \
    usermod -aG sudo webui && \
    chown -R webui:webui /home/webui && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER webui
WORKDIR /home/webui

RUN git clone https://github.com/vladmandic/automatic.git
ARG INSTALLDIR="/home/webui/automatic"
WORKDIR $INSTALLDIR

# This is the correct way to activate venv inside Dockerfile see https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
ENV VIRTUAL_ENV=$INSTALLDIR/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Install torch manually and skip automatic torch testing for GPU or else CPU will be set and produce errors later
RUN pip install \
wheel \
torch \
torchaudio \
torchvision

RUN python installer.py --skip-torch

# Clean install dir and set keyboard
RUN sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* && \
    sudo bash -c 'echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen' && \
    sudo apt-get update
    
USER root
WORKDIR /root

# Add the onstart script for vast.ai
ADD onstart.sh .
RUN chmod +x onstart.sh
