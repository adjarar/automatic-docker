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

WORKDIR /home/webui/automatic

# This is the correct way to activate venv inside Dockerfile see https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
ENV VIRTUAL_ENV=/home/webui/automatic/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip install wheel gdown pycairo

ADD install.py .
RUN python3 install.py --skip-torch-cuda-test

RUN sudo apt-get clean && sudo rm -rf /var/lib/apt/lists/* && \
    sudo bash -c 'echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen' && \
    sudo apt-get update
    
USER root

WORKDIR /root
ADD onstart.sh .
RUN chmod +x onstart.sh
