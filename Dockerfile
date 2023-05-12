# Bare essentials docker image for vlad's automatic and invokeai.
# Only installs packages, no data. Models get downloaded after
# docker image init in onstart.sh. Also automatically syncs latest
# git commit for automatic. Made to run with github actions.

# this image contains the minimum requirments to run the apps correctly
FROM nvidia/cuda:11.8.0-runtime-ubuntu22.04

ARG DEBIAN_FRONTEND noninteractive

# vast.ai uses this script when the docker image finishes loading.
# It downloads the user settings of invoke and automatic,
# and syncs automatics repo to the last version.
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
ARG USER="webui"
RUN useradd -m -g sudo -s /bin/bash $USER && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Switch to the new user, all commands will now be run as webui
USER $USER
ARG USER_HOME="/home/$USER"

# pull in Vlad's automatic and switch to its directory
WORKDIR $USER_HOME
RUN git clone https://github.com/vladmandic/automatic.git
ARG AUTOMATIC_ROOT="$USER_HOME/automatic"

# Create a virtual enviornment and activate it, all commands are now run from here
WORKDIR $AUTOMATIC_ROOT
RUN python3 -m venv $AUTOMATIC_ROOT/venv

# Tried it first with ENV PATH="$AUTOMATIC_ROOT/venv/bin:$PATH" but wasn't working as expected.
# https://pythonspeed.com/articles/activate-virtualenv-dockerfile/
ARG AUTOMATIC_ACTIVATE="$AUTOMATIC_ROOT/venv/bin/activate"

# make sure the latest version of pip is installed inside the venv
RUN . AUTOMATIC_ACTIVATE && \
    python3 -m pip install --upgrade pip

# wheel is used to build packages in python, install it first before anything else
RUN . AUTOMATIC_ACTIVATE && \
    pip install wheel

# There are no GPU's on the github build pods, so CPU will be set as the platform of choise
# if ran with installer.py. This is not what we want. To prevent this we install torch manually,
# then we pass --skip-torch to installer.py to prevent the gpu check and setting to cpu.
RUN . AUTOMATIC_ACTIVATE && \
    pip install \
    torch \
    torchvision \
    torchaudio \
    --index-url https://download.pytorch.org/whl/cu118

# This will install all automatic dependencies minus torch, which is already installed, then clear cache
RUN . AUTOMATIC_ACTIVATE && \
    python3 installer.py --skip-torch

RUN . AUTOMATIC_ACTIVATE && \
    pip cache purge

# Now install InvokeAI. This too only installs the dependencies,
# all user data will be dynamicly loaded in onstart.sh

# create the root dir and switch to it
ARG INVOKEAI_ROOT="$USER_HOME/invokeai"
RUN mkdir $INVOKEAI_ROOT

# Create the invokeai venv
WORKDIR $INVOKEAI_ROOT
RUN python3 -m venv .venv --prompt InvokeAI
ARG INVOKEAI_ACTIVATE="$INVOKEAI_ROOT/.venv/bin/activate"

# make sure the latest version of pip is installed inside the venv
RUN . INVOKEAI_ACTIVATE && \
    python3 -m pip install --upgrade pip

# Not mentioned as a dependencies by the invoke manual, still added it just in case
RUN . INVOKEAI_ACTIVATE && \
    pip install wheel

# Invoke is not tuned like automatic, still uses xformers
RUN . INVOKEAI_ACTIVATE && \
    pip install xformers==0.0.16rc425
    
RUN . INVOKEAI_ACTIVATE && \
    pip install triton

# Install all the invokeai dependencies and clear cache afterwards
RUN . INVOKEAI_ACTIVATE && \
    pip install "InvokeAI[xformers]" --use-pep517 --extra-index-url https://download.pytorch.org/whl/cu117

RUN . INVOKEAI_ACTIVATE && \
    pip cache purge

# Open the invokeai http port
EXPOSE 9090
