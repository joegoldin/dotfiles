#!/usr/bin/env fish
# Dotfiles setup - install software and configure.

# Function definitions

set log_file /opt/install.log

# If CODESPACES env var set, then set home_dir to /home/codespace, otherwise set to ~
if set -q CODESPACES
    set home_dir /home/codespace
else
    set home_dir ~
end

function log
    set message $argv[1]
    set currDate (date +"%Y-%m-%d %T")
    set logMessage "$message"\n"$currDate"
    echo $logMessage
    echo $logMessage >> $log_file
end

function brew_upgrade
    log '⚙️ Updating Homebrew...'
    if test (brew -v)
        # Update Homebrew
        brew update
    else
        # Install Homebrew
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        log '✔️ Homebrew installed successfully -- please re-run this script.'
        exit 0
    end
    log '✔️ Homebrew updated successfully.'
end

function apt_upgrade
    log '⚙️ Upgrading packages...'
    set -x DEBIAN_FRONTEND noninteractive
    sudo chmod -R 1777 /tmp
    sudo apt update
    DEBIAN_FRONTEND=noninteractive sudo apt install -y debconf-utils
    sudo debconf-set-selections < .dpkg-selections.conf
    sudo apt-add-repository ppa:fish-shell/release-3 --yes
    sudo apt update --yes
    sudo apt install -y fish
    sudo chsh -s /usr/bin/fish (whoami)
    log '✔️ Packages upgraded successfully.'
end

function install_common_packages
    log '💽 Installing common packages...'
    yes | pip3 install thefuck --upgrade
    yes | npm install -g http-server webpack webpack-cli typescript ts-loader simple-https-proxy@latest
    simple-https-proxy --makeCerts=true
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    cargo install --locked zellij
    go install github.com/baalimago/clai@latest
    log '✔️ Common packages installed successfully.'
end

function install_software_linux
    log '💽 Installing linux software...'
    sudo apt install dpkg -y
    sudo apt update
    sudo apt -o DPkg::Lock::Timeout=800 install golang unzip libgl1-mesa-glx mesa-utils xauth build-essential \
        kitty-terminfo socat ncat bat jq ripgrep thefuck tmux libfuse2 fuse software-properties-common libpng-dev \
        libturbojpeg-dev libvorbis-dev libopenal-dev libsdl2-dev libmbedtls-dev libuv1-dev libsqlite3-dev libncurses-dev \
        automake autoconf xsltproc fop dialog mosh -y
    wget -qO- "https://getbin.io/suyashkumar/ssl-proxy" | tar xvz 
    sudo mv ssl-proxy* /usr/local/bin/ssl-proxy
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz
    fish_add_path /usr/local/go/bin
    curl -sL https://cdn.geekbench.com/Geekbench-6.1.0-Linux.tar.gz | tar xvz && sudo mv Geekbench*/geekbench* /usr/local/bin/. && rm -rf Geekbench*
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O $home_dir/miniconda.sh
    bash $home_dir/miniconda.sh -b -p $home_dir/miniconda
    log '✔️ Linux software installed successfully.'
end

function install_software_mac
    log '💽 Installing mac software...'
    brew install fish go 
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -O ~/miniconda.sh
    bash ~/miniconda.sh -b -p $home_dir/miniconda
    log '✔️ Mac software installed successfully.'
end

function install_software
    sleep 5

    switch (uname -s)
    case "*Darwin*"
        brew_upgrade
        install_software_mac
        install_common_packages
    case "*Linux*"
        apt_upgrade
        install_software_linux
        install_common_packages
        sudo chmod -R 1777 /tmp
        sudo rm -rf /tmp/*
    end
end

function link_files
    log '🔗 Linking files...'
    mkdir -p $home_dir/.config
    # ssh
    mkdir -p $home_dir/.ssh
    touch $home_dir/.ssh/environment
    # tmux
    ln -s (pwd)/tmux.conf $home_dir/.tmux.conf
    # fish
    rm -rf $home_dir/.config/fish
    mkdir -p $home_dir/.config/fish
    ln -s (pwd)/.config/fish/config.fish $home_dir/.config/fish/config.fish
    ln -s (pwd)/.config/fish/fish_plugins $home_dir/.config/fish/fish_plugins
    ln -s (pwd)/.config/fish/functions $home_dir/.config/fish/functions
    ln -s (pwd)/.config/fish/completions $home_dir/.config/fish/completions
    ln -s (pwd)/.config/fish/conf.d $home_dir/.config/fish/conf.d
    # starship
    ln -s (pwd)/.config/starship.toml $home_dir/.config/starship.toml
    # cargo
    ln -s (pwd)/.config/cargo.toml $home_dir/.config/cargo.toml
    # rebar
    ln -s (pwd)/.config/rebar.config $home_dir/.config/rebar.config
    # zellij
    rm -rf $home_dir/.config/zellij
    mkdir -p $home_dir/.config/zellij
    ln -s (pwd)/.config/zellij/config.kdl $home_dir/.config/zellij/config.kdl
    ln -s (pwd)/.config/zellij/plugins $home_dir/.config/zellij/plugins
    log '✔️ Files linked successfully.'
end

function setup_software
    log '🔧 Configuring software...'
    mkdir -p $home_dir/.config/github-copilot
    touch $home_dir/.config/fish/.fisherinstalled
    rm -rf $home_dir/.config/fish/.fisherinstalled
    echo '{"joegoldin":{"version":"2021-10-14"}}' > $home_dir/.config/github-copilot/terms.json
    log '✔️ Software configured successfully.'
end

# Run script
log '==========STARTING INSTALLATION==========='
install_software
link_files
setup_software
log '==========INSTALLATION COMPLETE==========='
