#!/usr/bin/env fish
# GitHub codespaces setup - install software and configure.

# Function definitions

set log_file /opt/install.log
function log
    set message $argv[1]
    set currDate (date +"%Y-%m-%d %T")
    set logMessage "$message"\n"$currDate"
    echo $logMessage
    echo $logMessage >> $log_file
end

function create_log_header
    log '==========STARTING INSTALLATION==========='
end

function create_log_footer
    log '==========INSTALLATION COMPLETE==========='
end

function create_flag_file
    touch /opt/.codespaces_setup_complete
end

function link_files
    log '🔗 Linking files.'
    mkdir -p /home/codespace/.config
    mkdir -p /home/codespace/.ssh
    touch /home/codespace/.ssh/environment
    ln -s (pwd)/tmux.conf /home/codespace/.tmux.conf
    rm -rf /home/codespace/.config/fish
    mkdir -p /home/codespace/.config/fish
    ln -s (pwd)/.config/fish/config.fish /home/codespace/.config/fish/config.fish
    ln -s (pwd)/.config/starship.toml /home/codespace/.config/starship.toml
    ln -s (pwd)/.config/cargo.toml /home/codespace/.config/cargo.toml
    ln -s (pwd)/.config/rebar.config /home/codespace/.config/rebar.config
    ln -s (pwd)/install_optional_packages.fish /opt/install_optional_packages.fish
    sudo chmod +x (pwd)/install_optional_packages.fish
    log '✔️ Files linked successfully.'
end

function apt_upgrade
    log '⚙️ Upgrading packages.'
    set -x DEBIAN_FRONTEND noninteractive
    sudo chmod -R 1777 /tmp
    sudo apt update
    DEBIAN_FRONTEND=noninteractive sudo apt install -y debconf-utils
    sudo debconf-set-selections < .dpkg-selections.conf
    sudo apt-add-repository ppa:fish-shell/release-3 --yes
    sudo apt update --yes
    sudo apt install -y fish
    sudo chsh -s /usr/bin/fish codespace
    log '✔️ Packages upgraded successfully.'
end

function install_common_packages
    sudo apt install dpkg -y
    yes | sudo dpkg --add-architecture i386
    sudo apt update
    sudo apt -o DPkg::Lock::Timeout=800 install golang unzip libgl1-mesa-glx mesa-utils xauth build-essential \
        kitty-terminfo socat ncat bat jq ripgrep thefuck tmux libfuse2 fuse software-properties-common libpng-dev \
        libturbojpeg-dev libvorbis-dev libopenal-dev libsdl2-dev libmbedtls-dev libuv1-dev libsqlite3-dev libncurses-dev \
        automake autoconf xsltproc fop dialog -y
    yes | pip3 install thefuck --upgrade
    yes | npm install -g http-server webpack webpack-cli typescript ts-loader @githubnext/github-copilot-cli simple-https-proxy@latest
    simple-https-proxy --makeCerts=true
    set -x EXA_VERSION (curl -s "https://api.github.com/repos/ogham/exa/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
    curl -Lo exa.zip "https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-v$EXA_VERSION.zip"
    sudo unzip -q exa.zip bin/exa -d /usr/local
    rm -rf exa.zip
end

function install_software
    log '💽 Installing software.'
    sleep 5
    install_common_packages
    sudo chmod -R 1777 /tmp
    sudo rm -rf /tmp/*
    log '✔️ Software installed successfully.'
end

function setup_software
    log '🔧 Configuring software.'
    mkdir -p ~/.config/github-copilot
    touch /home/codespace/.config/fish/.fisherinstalled
    rm -rf /home/codespace/.config/fish/.fisherinstalled
    echo '{"joegoldin":{"version":"2021-10-14"}}' > ~/.config/github-copilot/terms.json
    log '✔️ Software configured successfully.'
end

# Run script
create_log_header
link_files
apt_upgrade
install_software
setup_software
create_flag_file
create_log_footer
