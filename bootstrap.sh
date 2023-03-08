#!/usr/bin/env fish
# GitHub codespaces setup.

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
enda

# UPGRADE DISTRO
function apt_upgrade
    sudo add-apt-repository -y ppa:apt-fast/stable
    set -x DEBIAN_FRONTEND noninteractive
    sudo apt update
    sudo apt install -y debconf-utils
    sudo debconf-set-selections < .dpkg-selections.conf
    sudo apt-get install -y apt-fast
    sudo dpkg-reconfigure keyboard-configuration -f noninteractive
    sudo apt-add-repository ppa:fish-shell/release-3 --yes
    sudo apt update --yes
    # sudo apt upgrade --yes
    sudo apt install -y fish
    sudo chsh -s /usr/bin/fish codespace
    source ~/.config/fish/config.fish
end

# CONFIGURE SOFTWARE
function setup_software
    mkdir -p ~/.config/github-copilot
    touch /home/codespace/.config/fish/.fisherinstalled
    rm -rf /home/codespace/.config/fish/.fisherinstalled
    echo '{"joegoldin":{"version":"2021-10-14"}}' > ~/.config/github-copilot/terms.json
    echo (date +"%Y-%m-%d %T")
end

# RUN SCRIPT
echo '🔗 Linking files.' >> ~/install.log;
echo (date +"%Y-%m-%d %T") >> ~/install.log;
link_files

echo '⚙️ Upgrading distro.' >> ~/install.log;
echo (date +"%Y-%m-%d %T") >> ~/install.log;
apt_upgrade

echo '💽 Installing software' >> ~/install.log;
echo (date +"%Y-%m-%d %T") >> ~/install.log;
fish install_software.fish

echo '🔧 configure software' >> ~/install.log;
echo (date +"%Y-%m-%d %T") >> ~/install.log;
setup_software

echo '✅ Done!' >> ~/install.log;
echo (date +"%Y-%m-%d %T") >> ~/install.log;
