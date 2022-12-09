#!/usr/bin/env bash
# GitHub codespaces setup.

function link_files() {
    mkdir -p ~/.config
    ln -s $(pwd)/tmux.conf ~/.tmux.conf
    rm ~/.gitconfig
    ln -s $(pwd)/gitconfig ~/.gitconfig
    ln -s $(pwd)/fish ~/.config/
    ln -s $(pwd)/starship.toml ~/.config/
}

function install_software() {
    sleep 20
    sudo apt -o DPkg::Lock::Timeout=600 install build-essential python3-venv kitty-terminfo socat ncat ruby-dev bat exa jq ripgrep thefuck tmux libfuse2 fuse software-properties-common -y
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
    # curl -sL https://deb.nodesource.com/setup_16.x | sudo bash -
    # sudo apt-get install -y nodejs
    # curl -L https://github.com/dandavison/delta/releases/download/0.14.0/git-delta_0.14.0_amd64.deb > ~/git-delta_0.14.0_amd64.deb
    # sudo dpkg -i ~/git-delta_0.14.0_amd64.deb
    # sudo npm install -g typescript-language-server typescript vscode-langservers-extracted eslint_d
}

function setup_software() {
    sudo chsh -s /usr/bin/fish vscode
    mkdir -p ~/.config/github-copilot
    echo '{"joegoldin":{"version":"2021-10-14"}}' > ~/.config/github-copilot/terms.json
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    ~/.tmux/plugins/tpm/scripts/install_plugins.sh
    echo "TMUX plugins installed" >> ~/install.log
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
