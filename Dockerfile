FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND noninteractive


RUN apt-get update && apt-get install -y --no-install-recommends \
apt-utils \
software-properties-common \
sudo \
wget \
python3-pip \
python3.10-venv \
python3-dev \
libglib2.0-0 \
libsm6 \
libgl1 \
libxrender1 \
libxext6 \
ffmpeg \
git \
nano \
curl \
psmisc \
pkg-config \
libcairo2-dev \
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

# Setup venv and pip cache
RUN python3 -m venv venv && \
    mkdir -p cache/pip
ENV PIP_CACHE_DIR=$INSTALLDIR/cache/pip

# Install dependencies (pip, wheel)
RUN pip install -U pip wheel gdown pycairo

# Install dependencies (torch)
RUN pip install torch torchaudio torchvision --index-url https://download.pytorch.org/whl/cu118

# This shouldn't be necessary, should be installed by installer.py.
# Install dependencies (requirements.txt)
# RUN pip install -r requirements.txt

# Install automatic111 dependencies (installer.py)
RUN python installer.py --skip-torch

RUN sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* && \
    sudo bash -c 'echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen' && \
    sudo apt-get update
    
USER root

WORKDIR /root
ADD onstart.sh .
RUN chmod +x onstart.sh
