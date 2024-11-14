FROM alpine:latest

RUN apk update && apk add \
    git \
    curl \
    wget \
    vim \
    zsh \
    bash \
    openssl

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && \
    mv kubectl /usr/local/bin/

# Install helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Install flux
RUN curl -s https://fluxcd.io/install.sh | bash

# Add user with sudo rights
RUN adduser -s /bin/zsh mick sudo -u 1338 -D

# User number in case of securityContext in k8s
USER 1338

COPY setup_zsh.sh /tmp/setup_zsh.sh
RUN bash /tmp/setup_zsh.sh

ENTRYPOINT ["zsh"]