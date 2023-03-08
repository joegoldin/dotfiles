#!/usr/bin/env fish
# GitHub codespaces setup.

# UPGRADE DISTRO
function apt_upgrade
    sudo apt install -y debconf-utils
    sudo debconf-set-selections < .dpkg-selections.conf
    sudo dpkg-reconfigure keyboard-configuration -f noninteractive
    sudo apt-add-repository ppa:fish-shell/release-3 --yes
    sudo apt update --yes
    # sudo apt upgrade --yes
    sudo apt install -y fish
end

# LINK CONFIG FILES
function link_files
    mkdir -p /home/codespace/.config
    mkdir -p /home/codespace/.ssh
    touch /home/codespace/.ssh/environment
    ln -s (pwd)/tmux.conf /home/codespace/.tmux.conf
    rm -rf /home/codespace/.config/fish
    mkdir -p /home/codespace/.config/fish
    ln -s (pwd)/.config/fish/config.fish /home/codespace/.config/fish/config.fish
    ln -s (pwd)/.config/starship.toml /home/codespace/.config/starship.toml
    ln -s (pwd)/.config/cargo.toml /home/codespace/.config/cargo.toml
    echo (date +"%Y-%m-%d %T")
end

# INSTALLER FUNCTIONS
function install_exa
    set -x EXA_VERSION (curl -s "https://api.github.com/repos/ogham/exa/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
    curl -Lo exa.zip "https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-v$EXA_VERSION.zip"
    sudo unzip -q exa.zip bin/exa -d /usr/local
    rm -rf exa.zip
end

function install_subl
    sudo wget -O /usr/local/bin/rmate https://raw.github.com/aurora/rmate/master/rmate
    sudo chmod a+x /usr/local/bin/rmate
    sudo mv /usr/local/bin/rmate /usr/local/bin/subl
end

function install_haxe
    sudo add-apt-repository ppa:haxe/releases -y
    sudo apt-get update
    sudo apt-get install haxe -y
    mkdir ~/.haxelib_home && haxelib setup ~/.haxelib_home
end

function install_lfe
    cd /opt
    git clone https://github.com/lfe/lfe.git
    make compile
    sudo make install
end

function install_rebar3
    git clone https://github.com/erlang/rebar3.git
    cd rebar3
    ./bootstrap
    ./rebar3 local install
    fish_add_path /home/codespace/.cache/rebar3/bin
end

# INSTALL SOFTWARE
function install_software
    sleep 20
    sudo apt -o DPkg::Lock::Timeout=600 install golang unzip libgl1-mesa-glx mesa-utils xauth x11-apps build-essential kitty-terminfo socat ncat bat jq ripgrep thefuck tmux libfuse2 fuse software-properties-common libpng-dev libturbojpeg-dev libvorbis-dev libopenal-dev libsdl2-dev libmbedtls-dev libuv1-dev libsqlite3-dev erlang elixir -y
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
    curl https://sh.rustup.rs -sSf | sh
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fish_add_path /home/codespace/.cargo/bin
    rustup target install wasm32-unknown-unknown
    cargo install wasm-server-runner
    cargo install cargo-watch
    cargo install matchbox_server
    install_exa
    npm install -g http-server webpack webpack-cli typescript ts-loader
    install_lfe
    install_rebar3
    echo (date +"%Y-%m-%d %T")
end

# CONFIGURE SOFTWARE
function setup_software
    sudo chsh -s /usr/bin/fish codespace
    mkdir -p ~/.config/github-copilot
    touch /home/codespace/.config/fish/.fisherinstalled
    rm -rf /home/codespace/.config/fish/.fisherinstalled
    echo '{"joegoldin":{"version":"2021-10-14"}}' > ~/.config/github-copilot/terms.json
    echo (date +"%Y-%m-%d %T")
end

# RUN SCRIPT
echo '⚙️ Upgrading distro.' >> ~/install.log;
echo (date +"%Y-%m-%d %T") >> ~/install.log;
apt_upgrade
echo '🔗 Linking files.' >> ~/install.log;
echo (date +"%Y-%m-%d %T") >> ~/install.log;
link_files
echo '💽 Installing software' >> ~/install.log;
echo (date +"%Y-%m-%d %T") >> ~/install.log;
install_software
echo '🔧 configure software' >> ~/install.log;
echo (date +"%Y-%m-%d %T") >> ~/install.log;
setup_software
echo '✅ Done!' >> ~/install.log;
echo (date +"%Y-%m-%d %T") >> ~/install.log;
