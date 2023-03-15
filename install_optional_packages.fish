#!/usr/bin/env fish

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

function install_rust_packages
    curl https://sh.rustup.rs -sSf | sh
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fish_add_path /home/codespace/.cargo/bin
    rustup target install wasm32-unknown-unknown
    cargo install wasm-server-runner
    cargo install cargo-watch
    cargo install matchbox_server
end

function install_erlang_elixir_packages
    sudo apt update
    sudo apt install erlang-base erlang-crypto erlang-syntax-tools erlang-doc erlang-manpages erlang-tools \
        erlang-dev erlang-inets erlang elixir -y
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

function erlang_tools
    install_erlang_elixir_packages
    install_rebar3
    install_lfe
end

function reset_flags
    rm -f /opt/.erlang_tools_installed
    rm -f /opt/.rust_packages_installed
    rm -f /opt/.haxe_installed
    rm -f /opt/.wine_installed
    rm -f /opt/.apt_upgrade_done
end

if test (count $argv) -gt 0
    if test $argv[1] = "--reset"
        reset_flags
        exit 0
    end
end

function on_sigint --on-signal SIGINT
    clear
    exit 1
end

if not test -e /opt/.erlang_tools_installed
    clear
    set erlang_choice (dialog --stdout --title "Erlang/Elixir Packages" --yesno "Do you want to install Erlang and Elixir packages?" 0 0; echo $status)
    clear
end

if not test -e /opt/.rust_packages_installed
    clear
    set rust_choice (dialog --stdout --title "Rust Packages" --defaultno --yesno "Do you want to install Rust packages?" 0 0; echo $status)
    clear
end

if not test -e /opt/.haxe_installed
    clear
    set haxe_choice (dialog --stdout --title "Haxe Packages" --defaultno --yesno "Do you want to install Haxe packages?" 0 0; echo $status)
    clear
end

if not test -e /opt/.wine_installed
    clear
    set wine_choice (dialog --stdout --title "Wine Packages" --defaultno --yesno "Do you want to install Wine?" 0 0; echo $status)
    clear
end

if not test -e /opt/.apt_upgrade_done
    clear
    set apt_upgrade_choice (dialog --stdout --title "sudo apt-upgrade" --defaultno --yesno "Do you want to apt-upgrade?" 0 0; echo $status)
    clear
end

if test $erlang_choice -eq 0
    erlang_tools
    touch /opt/.erlang_tools_installed
end

if test $rust_choice -eq 0
    install_rust_packages
    touch /opt/.rust_packages_installed
end

if test $haxe_choice -eq 0
    install_haxe
    touch /opt/.haxe_installed
end

if test $wine_choice -eq 0
    install_wine
    touch /opt/.wine_installed
end

if test $apt_upgrade_choice -eq 0
    sudo apt upgrade -y
    touch /opt/.apt_upgrade_done
end

sudo chmod -R 1777 /tmp
sudo rm -rf /tmp/*
