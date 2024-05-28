#!/usr/bin/env fish
# Dotfiles setup - install software and configure.

# Function definitions


# If CODESPACES env var set, then set home_dir to /home/codespace, otherwise set to ~
if set -q CODESPACES
    set home_dir /home/codespace
    set log_file /opt/install.log
else
    set home_dir ~
    set log_file (pwd)/install.log
end

function log
    set message $argv[1]
    set currDate (date +"%Y-%m-%d %T")
    set logMessage "[$currDate] $message"
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

function check_and_or_install
    set cmd $argv[1]
    # rest of args for install cmd
    if not test (which $cmd)
        log "❌ $cmd not installed. Installing..."
        eval $argv[2..-1]
    else
        log "✅ $cmd already installed."
    end
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
    check_and_or_install fish brew install fish
    check_and_or_install go brew install go
    check_and_or_install conda "wget https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -O $home_dir/miniconda.sh && conda bash $home_dir/miniconda.sh -b -p $home_dir/miniconda"
    log '✔️ Mac software installed successfully.'
end

function install_common_packages
    log '💽 Installing common packages...'
    python -m poetry --version &> /dev/null
    if not test $status -eq 0
        yes | pip install poetry --upgrade
    end
    check_and_or_install rustc "curl https://sh.rustup.rs -sSf | sh -s -- -y"
    check_and_or_install zellij cargo install --locked zellij
    check_and_or_install clai go install github.com/baalimago/clai@latest
    log '✔️ Common packages installed successfully.'
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
    # fish
    mkdir -p $home_dir/.config/fish
    rm -rf $home_dir/.config/fish/functions
    rm -rf $home_dir/.config/fish/completions
    rm -rf $home_dir/.config/fish/conf.d
    mkdir -p $home_dir/.config/fish/functions
    mkdir -p $home_dir/.config/fish/completions
    mkdir -p $home_dir/.config/fish/conf.d
    if test -f $home_dir/.config/fish/config.fish
        rm -rf $home_dir/.config/fish/.config.fish.bak
        mv -f $home_dir/.config/fish/config.fish $home_dir/.config/fish/.config.fish.bak
    end
    ln -s (pwd)/.config/fish/config.fish $home_dir/.config/fish/config.fish
    rm -rf $home_dir/.config/fish/fish_plugins
    cp -f (pwd)/.config/fish/fish_plugins $home_dir/.config/fish/fish_plugins
    ln -s (pwd)/.config/fish/functions/assemblai.fish $home_dir/.config/fish/functions/assemblai.fish
    ln -s (pwd)/.config/fish/functions/clai.fish $home_dir/.config/fish/functions/clai.fish
    # starship
    if test -f $home_dir/.config/starship.toml
        rm -rf $home_dir/.config/.starship.toml.bak
        mv -f $home_dir/.config/starship.toml $home_dir/.config/.starship.toml.bak
    end
    ln -s (pwd)/.config/starship.toml $home_dir/.config/starship.toml
    # cargo
    if test -f $home_dir/.config/cargo.toml
        rm -rf $home_dir/.config/.cargo.toml.bak
        mv -f $home_dir/.config/cargo.toml $home_dir/.config/.cargo.toml.bak
    end
    ln -s (pwd)/.config/cargo.toml $home_dir/.config/cargo.toml
    # zellij
    if test -d $home_dir/.config/zellij
        rm -rf $home_dir/.config/.zellij.bak
        mv -f $home_dir/.config/zellij $home_dir/.config/.zellij.bak
    end
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
