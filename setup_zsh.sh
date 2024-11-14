#!/bin/bash

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install zsh completions
git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions

# Install zsh theme
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Install configuration
curl https://raw.githubusercontent.com/mickvdv/toolbox/refs/heads/master/assets/.zshrc -o ~/.zshrc
curl https://raw.githubusercontent.com/mickvdv/toolbox/refs/heads/master/assets/.p10k.zsh -o ~/.p10k.zsh