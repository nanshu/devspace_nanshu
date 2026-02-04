#!/bin/bash

sudo sh << 'EOF'
add-apt-repository -y ppa:jgmath2000/et
curl -fsSL https://apt.fury.io/wez/gpg.key | gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | tee /etc/apt/sources.list.d/wezterm.list
chmod 644 /usr/share/keyrings/wezterm-fury.gpg
apt update -qq
apt install -y et fzf build-essential libssl-dev ruby-dev wezterm
snap install nvim --classic
snap install kubectx --classic
gem install consul-templaterb
gem install multitrap
EOF

NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew install derailed/k9s/k9s jid pipx visidata bat eza pv btop glow ipcalc tldr atuin k6

curl -L -o /tmp/sapling.deb https://github.com/facebook/sapling/releases/download/0.2.20250521-115337%2B25ed6ac4/sapling_0.2.20250521-115337%2B25ed6ac4_amd64.Ubuntu22.04.deb
sudo dpkg -i /tmp/sapling.deb

# curl -L https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf -
# bash ble-nightly/ble.sh --install ~/.local/share





