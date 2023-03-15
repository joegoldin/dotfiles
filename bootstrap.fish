#!/usr/bin/env fish
# GitHub codespaces setup - install software and configure.

# Variables
set log_file ~/install.log

# Functions
function log
    set message $argv[1]
    echo $message >> $log_file
    echo (date +"%Y-%m-%d %T") >> $log_file
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

function install_exa
    log '📥 Installing exa.'
    set -x EXA_VERSION (curl -s "https://api.github.com/repos/ogham/exa/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
    curl -Lo exa.zip "https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-v$EXA_VERSION.zip"
    sudo unzip -q exa.zip bin/exa -d /usr/local
    rm -rf exa.zip
    log '✔️ exa installed successfully.'
end

function install_subl
    log '📥 Installing subl.'
    sudo wget -O /usr/local/bin/rmate https://raw.github.com/aurora/rmate/master/rmate
    sudo chmod a+x /usr/local/bin/rmate
    sudo mv /usr/local/bin/rmate /usr/local/bin/subl
    log '✔️ subl installed successfully.'
end

function install_haxe
    log '📥 Installing haxe.'
    sudo add-apt-repository ppa:haxe/releases -y
    sudo apt-get update
    sudo apt install haxe -y
    mkdir ~/.haxelib_home && haxelib setup ~/.haxelib_home
    log '✔️ haxe installed successfully.'
end

function install_lfe
    log '📥 Installing lfe.'
    cd /opt
    git clone https://github.com/lfe/lfe.git
    cd lfe
    make compile
    sudo make install
    log '✔️ lfe installed successfully.'
end

function install_rebar3
    log '📥 Installing rebar3.'
    git clone https://github.com/erlang/rebar3.git
    cd rebar3
    ./bootstrap
    ./rebar3 local install
    fish_add_path /home/codespace/.cache/rebar3/bin
    log '✔️ rebar3 installed successfully.'
end

function install_software
    log '💽 Installing software.'
    sleep 5
    sudo apt install dpkg -y
    yes | sudo dpkg --add-architecture i386
    sudo apt -o DPkg::Lock::Timeout=600 install golang unzip libgl1-mesa-glx mesa-utils xauth build-essential \
        kitty-terminfo socat ncat bat jq ripgrep thefuck tmux libfuse2 fuse software-properties-common libpng-dev \
        libturbojpeg-dev libvorbis-dev libopenal-dev libsdl2-dev libmbedtls-dev libuv1-dev libsqlite3-dev libncurses-dev \
        automake autoconf xsltproc fop erlang-base erlang-crypto erlang-syntax-tools erlang-doc erlang-manpages erlang-tools \
        erlang-dev erlang-inets erlang elixir dpkg fakeroot wine64 mono-devel fakeroot -y
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
    curl https://sh.rustup.rs -sSf | sh
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fish_add_path /home/codespace/.cargo/bin
    rustup target install wasm32-unknown-unknown
    cargo install wasm-server-runner
    cargo install cargo-watch
    cargo install matchbox_server
    install_exa
    yes | npm install -g http-server webpack webpack-cli typescript ts-loader @githubnext/github-copilot-cli
    install_lfe
    install_rebar3
    yes | pip3 install thefuck --upgrade
    sudo chmod -R 1777 /tmp
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
