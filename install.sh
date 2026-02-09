#!/bin/bash

set -euo pipefail

# ==================== CONFIGURATION ====================

# Package metadata: package_name -> "type:package_spec[:repo_setup_func]"
declare -A PACKAGE_META=(
    [et]="apt:et:setup_et_repo"
    [fzf]="apt:fzf"
    [build_essential]="apt:build-essential"
    [libssl_dev]="apt:libssl-dev"
    [ruby_dev]="apt:ruby-dev"
    [wezterm]="apt:wezterm:setup_wezterm_repo"
    [consul_templaterb]="gem:consul-templaterb"
    [multitrap]="gem:multitrap"
    [k9s]="brew:derailed/k9s/k9s"
    [jid]="brew:jid"
    [pipx]="brew:pipx"
    [visidata]="brew:visidata"
    [bat]="brew:bat"
    [eza]="brew:eza"
    [pv]="brew:pv"
    [btop]="brew:btop"
    [glow]="brew:glow"
    [ipcalc]="brew:ipcalc"
    [tldr]="brew:tldr"
    [atuin]="brew:atuin"
    [k6]="brew:k6"
    [nvim]="brew:nvim"
    [kubectx]="brew:kubectx"
    [sapling]="dpkg:https://github.com/facebook/sapling/releases/download/0.2.20250521-115337%2B25ed6ac4/sapling_0.2.20250521-115337%2B25ed6ac4_amd64.Ubuntu22.04.deb"
)

# Map hostnames to their packages
declare -A HOSTNAME_MODULES=(
    # [default]="et fzf build_essential libssl_dev ruby_dev wezterm consul_templaterb multitrap k9s jid pipx visidata bat eza pv btop glow ipcalc tldr atuin k6 nvim kubectx sapling"
    [default]="fzf wezterm k9s jid pipx bat eza pv btop glow ipcalc tldr atuin k6 nvim kubectx sapling"
)

# ==================== UTILITY FUNCTIONS ====================

log_info() {
    echo "[INFO] $*"
}

log_error() {
    echo "[ERROR] $*" >&2
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    fi
    return 1
}

# Track if apt update has been run
APT_UPDATED=false
BREW_ENV_SET=false

ensure_apt_updated() {
    if [[ "$APT_UPDATED" == "false" ]]; then
        log_info "Updating APT cache..."
        sudo apt update -qq
        APT_UPDATED=true
    fi
}

ensure_brew_env() {
    if [[ "$BREW_ENV_SET" == "false" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        BREW_ENV_SET=true
    fi
}

# ==================== APT REPOSITORIES SETUP ====================

setup_et_repo() {
    log_info "Setting up et PPA..."
    sudo add-apt-repository -y ppa:jgmath2000/et || true
}

setup_wezterm_repo() {
    log_info "Setting up wezterm repository..."
    curl -fsSL https://apt.fury.io/wez/gpg.key | gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
    echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list
    sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg
}

# ==================== BREW SETUP ====================

setup_brew() {
    if check_command brew; then
        log_info "Homebrew already installed"
        return 0
    fi
    
    log_info "Setting up Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ensure_brew_env
}

# ==================== BATCH INSTALLATION FUNCTIONS ====================

batch_install_apt() {
    local -a packages=("$@")
    local -a apt_packages=()
    local -a repo_functions=()
    
    # Parse package metadata and collect repo setup functions
    for pkg in "${packages[@]}"; do
        local meta="${PACKAGE_META[$pkg]}"
        if [[ -z "$meta" ]]; then
            log_error "Unknown package: $pkg"
            continue
        fi
        
        IFS=':' read -r type spec repo_func <<< "$meta"
        if [[ "$type" == "apt" ]]; then
            apt_packages+=("$spec")
            if [[ -n "$repo_func" ]]; then
                repo_functions+=("$repo_func")
            fi
        fi
    done
    
    if [[ ${#apt_packages[@]} -eq 0 ]]; then
        return 0
    fi
    
    # Setup required repos
    for repo_func in "${repo_functions[@]}"; do
        if declare -f "$repo_func" > /dev/null; then
            "$repo_func"
        fi
    done
    
    # Update apt cache once
    ensure_apt_updated
    
    # Install all apt packages in one command
    log_info "Installing APT packages: ${apt_packages[*]}"
    sudo apt install -y "${apt_packages[@]}"
}

batch_install_gem() {
    local -a packages=("$@")
    local -a gem_packages=()
    
    for pkg in "${packages[@]}"; do
        local meta="${PACKAGE_META[$pkg]}"
        if [[ -z "$meta" ]]; then
            continue
        fi
        
        IFS=':' read -r type spec _ <<< "$meta"
        if [[ "$type" == "gem" ]]; then
            gem_packages+=("$spec")
        fi
    done
    
    if [[ ${#gem_packages[@]} -eq 0 ]]; then
        return 0
    fi
    
    log_info "Installing GEM packages: ${gem_packages[*]}"
    for gem_pkg in "${gem_packages[@]}"; do
        gem install "$gem_pkg"
    done
}

batch_install_brew() {
    local -a packages=("$@")
    local -a brew_packages=()
    
    for pkg in "${packages[@]}"; do
        local meta="${PACKAGE_META[$pkg]}"
        if [[ -z "$meta" ]]; then
            continue
        fi
        
        IFS=':' read -r type spec _ <<< "$meta"
        if [[ "$type" == "brew" ]]; then
            brew_packages+=("$spec")
        fi
    done
    
    if [[ ${#brew_packages[@]} -eq 0 ]]; then
        return 0
    fi
    
    # Ensure brew environment is set once
    ensure_brew_env
    
    # Install all brew packages in one command
    log_info "Installing Brew packages: ${brew_packages[*]}"
    brew install "${brew_packages[@]}"
}

batch_install_dpkg() {
    local -a packages=("$@")
    
    for pkg in "${packages[@]}"; do
        local meta="${PACKAGE_META[$pkg]}"
        if [[ -z "$meta" ]]; then
            continue
        fi
        
        IFS=':' read -r type url _ <<< "$meta"
        if [[ "$type" == "dpkg" ]]; then
            local filename=$(basename "$url" | cut -d'?' -f1)
            local temp_file="/tmp/$filename"
            
            log_info "Installing $pkg via dpkg..."
            log_info "  Downloading: $url"
            curl -L -o "$temp_file" "$url"
            
            log_info "  Installing: $filename"
            sudo dpkg -i "$temp_file"
            rm -f "$temp_file"
        fi
    done
}

# ==================== MAIN EXECUTION ====================

main() {
    local hostname=$(hostname -s)
    local modules=${HOSTNAME_MODULES[$hostname]:-${HOSTNAME_MODULES[default]}}
    
    log_info "Starting installation for hostname: $hostname"
    
    if [[ -z "$modules" ]]; then
        log_error "No modules configured for hostname: $hostname"
        return 1
    fi
    
    # Convert space-separated string to array
    local -a packages=($modules)
    
    # Validate all packages exist in metadata
    for pkg in "${packages[@]}"; do
        if [[ -z "${PACKAGE_META[$pkg]}" ]]; then
            log_error "Unknown package: $pkg"
            return 1
        fi
    done
    
    # Setup brew once if needed
    setup_brew
    
    # Batch install by type
    batch_install_apt "${packages[@]}"
    batch_install_gem "${packages[@]}"
    batch_install_brew "${packages[@]}"
    batch_install_dpkg "${packages[@]}"
    
    log_info "Installation complete!"
}

main "$@"





