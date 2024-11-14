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
RUN adduser -s /bin/zsh mick sudo -u 1337 -D

# User number in case of securityContext in k8s
USER 1337

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install ZSH completions
RUN git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions

# Install ZSH theme
RUN wget https://raw.githubusercontent.com/DylanDelobel/agnoster-timestamp-newline-zsh-theme/refs/heads/master/agnoster-timestamp-newline.zsh-theme -P /home/mick/.oh-my-zsh/themes/


COPY assets/.zshrc /home/mick/.zshrc

ENTRYPOINT ["zsh"]