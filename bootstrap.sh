#!/usr/bin/env bash
# GitHub codespaces setup.

function link_files() {
    mkdir -p ~/.config
    mkdir -p /home/codespace/.config
    mkdir -p /home/codespace/.ssh
    touch /home/codespace/.ssh/environment
    ln -s $(pwd)/tmux.conf ~/.tmux.conf
    ln -s $(pwd)/.config/fish ~/.config
    ln -s $(pwd)/.config/starship.toml ~/.config/starship.toml
}

function install_software() {
    sleep 20
    sudo apt-get update
    sudo apt -o DPkg::Lock::Timeout=600 install build-essential kitty-terminfo socat ncat bat jq ripgrep thefuck tmux libfuse2 fuse software-properties-common -y
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
}

function setup_software() {
    sudo chsh -s /usr/bin/fish codespace
    mkdir -p ~/.config/github-copilot
    echo '{"joegoldin":{"version":"2021-10-14"}}' > ~/.config/github-copilot/terms.json
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
}

echo '🔗 Linking files.' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
link_files
echo '💽 Installing software' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
install_software
echo '👩<200d>🔧 configure software' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
setup_software
echo '✅ Done!' >> ~/install.log;
echo `date +"%Y-%m-%d %T"` >> ~/install.log;
