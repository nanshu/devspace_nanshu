#!/bin/bash

sudo sh -c '
add-apt-repository -y ppa:jgmath2000/et
apt update -qq
apt install -y et fzf build-essential libssl-dev ruby-dev 
snap install nvim --classic
snap install kubectx --classic
gem install consul-templaterb
gem install multitrap
'
NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install derailed/k9s/k9s jid pipx visidata bat eza pv btop glow ipcalc tldr

curl -L -o /tmp/sapling.deb https://github.com/facebook/sapling/releases/download/0.2.20250521-115337%2B25ed6ac4/sapling_0.2.20250521-115337%2B25ed6ac4_amd64.Ubuntu22.04.deb
sudo dpkg -i /tmp/sapling.deb



