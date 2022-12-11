#!/usr/bin/env bash
# GitHub codespaces setup.

# LINK CONFIG FILES
function link_files() {
    mkdir -p /home/codespace/.config
    mkdir -p /home/codespace/.ssh
    touch /home/codespace/.ssh/environment
    ln -s $(pwd)/tmux.conf /home/codespace/.tmux.conf
    rm -rf /home/codespace/.config/fish
    mkdir -p /home/codespace/.config/fish
    ln -s $(pwd)/.config/fish/config.fish /home/codespace/.config/fish/config.fish
    ln -s $(pwd)/.config/starship.toml /home/codespace/.config/starship.toml
}

# INSTALLER FUNCTIONS
function install_exa() {
    EXA_VERSION=$(curl -s "https://api.github.com/repos/ogham/exa/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
    curl -Lo exa.zip "https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-v${EXA_VERSION}.zip"
    sudo unzip -q exa.zip bin/exa -d /usr/local
    rm -rf exa.zip
}

function install_subl {
    sudo wget -O /usr/local/bin/rmate https://raw.github.com/aurora/rmate/master/rmate
    sudo chmod a+x /usr/local/bin/rmate
    sudo mv /usr/local/bin/rmate /usr/local/bin/subl
}

function install_haxe {
    sudo add-apt-repository ppa:haxe/releases -y
    sudo apt-get update
    sudo apt-get install haxe -y
    mkdir ~/haxelib && haxelib setup ~/haxelib
}

# INSTALL SOFTWARE
function install_software() {
    sleep 20
    sudo apt-get update
    sudo apt -o DPkg::Lock::Timeout=600 install unzip libgl1-mesa-glx mesa-utils xauth x11-apps build-essential kitty-terminfo socat ncat bat jq ripgrep thefuck tmux libfuse2 fuse software-properties-common -y
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
    install_exa
    install_haxe
}

# RUN IN FISH
function run_in_fish() {
    cmd="$*"
    fish -c "$cmd"
}

# CONFIGURE SOFTWARE
function setup_software() {
    sudo chsh -s /usr/bin/fish codespace    
    run_in_fish curl -sL https://git.io/fisher \| source \&\& fisher install jorgebucaran/fisher
    run_in_fish "fisher install jorgebucaran/nvm.fish"
    run_in_fish fisher install danhper/fish-ssh-agent
    run_in_fish fisher install jethrokuan/z
    run_in_fish fisher install jorgebucaran/autopair.fish
    run_in_fish fisher install nickeb96/puffer-fish
    run_in_fish fisher install halostatue/fish-docker
    run_in_fish fisher install halostatue/fish-macos
    run_in_fish fisher install halostatue/fish-elixir
    run_in_fish fisher install eth-p/fish-plugin-sudo
    run_in_fish nvm install lts
    run_in_fish npm install -g http-server webpack webpack-cli typescript ts-loader
    mkdir -p ~/.config/github-copilot
    echo '{"joegoldin":{"version":"2021-10-14"}}' > ~/.config/github-copilot/terms.json
    echo `date +"%Y-%m-%d %T"` >> ~/install.log;
}

# RUN SCRIPT
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
