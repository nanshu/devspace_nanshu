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
brew install derailed/k9s/k9s
brew install jid
