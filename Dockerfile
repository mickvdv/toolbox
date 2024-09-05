FROM ubuntu:latest

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    sudo && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

    # apt-transport-https ca-certificates \
    # gnupg && \
    # Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl
    
# Add user with sudo rights
RUN useradd -ms /bin/bash mick -p mick -u 1337 && \
    adduser mick sudo

# Copy bashrc
COPY ./.bashrc /home/mick/

# User number in case of securityContext in k8s
USER 1337
