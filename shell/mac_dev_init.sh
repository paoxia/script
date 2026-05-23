#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    printf "${GREEN}[INFO]${NC} %s\n" "$*"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC} %s\n" "$*"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$*" >&2
}

log_step() {
    printf "${CYAN}==>${NC} ${BLUE}%s${NC}\n" "$*"
}

check_command() {
    command -v "$1" >/dev/null 2>&1
}

ensure_homebrew() {
    if check_command brew; then
        log_info "Homebrew already installed"
        return 0
    fi

    log_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    if check_command brew; then
        log_info "Homebrew installed successfully"
    else
        log_error "Failed to install Homebrew"
        exit 1
    fi
}

brew_install() {
    local package="$1"
    shift
    local options=("$@")

    if brew list "$package" &>/dev/null; then
        log_info "$package already installed"
        return 0
    fi

    log_step "Installing $package..."
    if [[ ${#options[@]} -gt 0 ]]; then
        brew install "$package" "${options[@]}"
    else
        brew install "$package"
    fi
}

brew_cask_install() {
    local package="$1"

    if brew list --cask "$package" &>/dev/null; then
        log_info "$package (cask) already installed"
        return 0
    fi

    log_step "Installing $package (cask)..."
    brew install --cask "$package"
}

install_git() {
    log_step "Setting up Git..."

    brew_install git

    if [[ ! -f ~/.gitconfig ]]; then
        log_info "Configuring Git..."
        read -rp "Enter your Git username: " git_username
        read -rp "Enter your Git email: " git_email

        git config --global user.name "$git_username"
        git config --global user.email "$git_email"
        git config --global init.defaultBranch main
        git config --global pull.rebase false
        git config --global core.editor vim
        git config --global alias.st status
        git config --global alias.co checkout
        git config --global alias.br branch
        git config --global alias.ci commit
        git config --global alias.lg "log --oneline --graph --all"

        log_info "Git configured successfully"
    else
        log_info "Git already configured"
    fi

    if [[ ! -f ~/.ssh/id_ed25519 ]] && [[ ! -f ~/.ssh/id_rsa ]]; then
        log_info "Generating SSH key..."
        read -rp "Enter your email for SSH key: " ssh_email
        ssh-keygen -t ed25519 -C "$ssh_email" -f ~/.ssh/id_ed25519 -N ""
        log_info "SSH key generated. Public key:"
        cat ~/.ssh/id_ed25519.pub
        log_info "Add this key to your GitHub/GitLab account"
    fi
}

install_java() {
    log_step "Setting up Java..."

    brew_install openjdk@21
    brew_install maven
    brew_install gradle

    local java_path
    java_path="$(brew --prefix openjdk@21)"

    if [[ ! -L /opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home && ! -L /usr/local/opt/openjdk/libexec/openjdk.jdk/Contents/Home ]]; then
        sudo ln -sfn "${java_path}/libexec/openjdk.jdk" /Library/Java/JavaVirtualJDKs/openjdk-21.jdk 2>/dev/null || true
    fi

    if ! grep -q "JAVA_HOME" ~/.zshrc 2>/dev/null; then
        echo "" >> ~/.zshrc
        echo "export JAVA_HOME=\"\${JAVA_HOME:-${java_path}}\"" >> ~/.zshrc
        echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> ~/.zshrc
        log_info "Added JAVA_HOME to ~/.zshrc"
    fi

    log_info "Java 21, Maven, Gradle installed"
}

install_go() {
    log_step "Setting up Go..."

    brew_install go

    local go_path="${HOME}/go"
    mkdir -p "${go_path}/bin" "${go_path}/pkg" "${go_path}/src"

    if ! grep -q "GOPATH" ~/.zshrc 2>/dev/null; then
        echo "" >> ~/.zshrc
        echo "export GOPATH=\"${go_path}\"" >> ~/.zshrc
        echo "export PATH=\"\$GOPATH/bin:\$PATH\"" >> ~/.zshrc
        log_info "Added GOPATH to ~/.zshrc"
    fi

    log_info "Go installed. GOPATH: ${go_path}"
}

install_node() {
    log_step "Setting up Node.js..."

    brew_install nvm

    local nvm_dir="${HOME}/.nvm"
    mkdir -p "$nvm_dir"

    if ! grep -q "NVM_DIR" ~/.zshrc 2>/dev/null; then
        echo "" >> ~/.zshrc
        echo "export NVM_DIR=\"\$HOME/.nvm\"" >> ~/.zshrc
        echo "[ -s \"\$NVM_DIR/nvm.sh\" ] && \. \"\$NVM_DIR/nvm.sh\"" >> ~/.zshrc
        log_info "Added NVM to ~/.zshrc"
    fi

    export NVM_DIR="$nvm_dir"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    nvm install --lts
    nvm use --lts

    log_info "Node.js (via nvm) installed"
}

install_docker() {
    log_step "Setting up Docker..."

    brew_cask_install docker

    log_info "Docker Desktop installed. Please start it from Applications."
}

install_databases() {
    log_step "Setting up database tools..."

    brew_install mysql-client
    brew_install postgresql
    brew_install redis

    brew_cask_install dbeaver-community

    log_info "MySQL client, PostgreSQL, Redis, DBeaver installed"
}

install_dev_tools() {
    log_step "Installing development tools..."

    local tools=(
        curl
        wget
        jq
        yq
        tree
        htop
        tmux
        vim
        neovim
        fzf
        ripgrep
        fd
        bat
        exa
        tldr
        httpie
        protobuf
        grpcurl
    )

    for tool in "${tools[@]}"; do
        brew_install "$tool"
    done

    if [[ -d $(brew --prefix fzf) ]]; then
        "$(brew --prefix fzf)/install" --key-bindings --completion --no-update-rc --no-bash --no-fish 2>/dev/null || true
    fi

    log_info "Development tools installed"
}

install_ide() {
    log_step "Setting up IDE..."

    brew_cask_install "intellij-idea-ce"

    log_info "IntelliJ IDEA CE installed"
}

install_terminal_tools() {
    log_step "Setting up terminal tools..."

    brew_install zsh
    brew_install zsh-autosuggestions
    brew_install zsh-syntax-highlighting
    brew_install starship
    brew_install zoxide

    if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
        log_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    if ! grep -q "starship" ~/.zshrc 2>/dev/null; then
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    fi

    if ! grep -q "zoxide" ~/.zshrc 2>/dev/null; then
        echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
    fi

    log_info "Terminal tools installed"
}

install_python_tools() {
    log_step "Setting up Python tools..."

    brew_install python@3.12
    brew_install pyenv
    brew_install poetry

    log_info "Python 3.12, pyenv, poetry installed"
}

install_cloud_tools() {
    log_step "Setting up cloud tools..."

    brew_install awscli
    brew_install kubectl
    brew_install helm
    brew_install terraform

    log_info "AWS CLI, kubectl, helm, terraform installed"
}

show_menu() {
    echo ""
    printf "${CYAN}========================================${NC}\n"
    printf "${CYAN}   Mac Backend Developer Environment    ${NC}\n"
    printf "${CYAN}========================================${NC}\n"
    echo ""
    printf "${YELLOW}Select components to install:${NC}\n"
    echo ""
    echo "  1) Git                    - Version control with SSH key setup"
    echo "  2) Java (JDK 21)          - Java development with Maven & Gradle"
    echo "  3) Go                     - Go programming language"
    echo "  4) Node.js                - Node.js via nvm"
    echo "  5) Docker                 - Docker Desktop"
    echo "  6) Database Tools         - MySQL client, PostgreSQL, Redis, DBeaver"
    echo "  7) Development Tools      - curl, wget, jq, tree, htop, tmux, etc."
    echo "  8) IDE                    - IntelliJ IDEA Community Edition"
    echo "  9) Terminal Tools         - Oh My Zsh, Starship, zoxide"
    echo " 10) Python Tools           - Python 3.12, pyenv, poetry"
    echo " 11) Cloud Tools            - AWS CLI, kubectl, helm, terraform"
    echo ""
    echo "  a) All                    - Install all components"
    echo "  q) Quit                   - Exit without installation"
    echo ""
}

read_selection() {
    local prompt="$1"
    local default="$2"
    local result

    read -rp "$prompt" result
    echo "${result:-$default}"
}

main() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is designed for macOS only."
        exit 1
    fi

    log_info "Starting Mac development environment setup..."

    ensure_homebrew
    brew update

    local selections=()

    while true; do
        show_menu
        local choice
        read -rp "Enter your choice (1-11, a, q): " choice

        case "$choice" in
            1) selections+=("git") ;;
            2) selections+=("java") ;;
            3) selections+=("go") ;;
            4) selections+=("node") ;;
            5) selections+=("docker") ;;
            6) selections+=("databases") ;;
            7) selections+=("dev_tools") ;;
            8) selections+=("ide") ;;
            9) selections+=("terminal") ;;
            10) selections+=("python") ;;
            11) selections+=("cloud") ;;
            a|A)
                selections=(git java go node docker databases dev_tools ide terminal python cloud)
                break
                ;;
            q|Q)
                log_info "Exiting..."
                exit 0
                ;;
            *)
                log_error "Invalid choice: $choice"
                continue
                ;;
        esac

        local more
        read -rp "Select more? (y/n): " more
        if [[ "$more" != "y" && "$more" != "Y" ]]; then
            break
        fi
    done

    if [[ ${#selections[@]} -eq 0 ]]; then
        log_warn "No components selected. Exiting."
        exit 0
    fi

    echo ""
    log_info "Will install the following components:"
    printf "  - %s\n" "${selections[@]}"
    echo ""

    local confirm
    read -rp "Proceed? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Installation cancelled."
        exit 0
    fi

    for selection in "${selections[@]}"; do
        case "$selection" in
            git) install_git ;;
            java) install_java ;;
            go) install_go ;;
            node) install_node ;;
            docker) install_docker ;;
            databases) install_databases ;;
            dev_tools) install_dev_tools ;;
            ide) install_ide ;;
            terminal) install_terminal_tools ;;
            python) install_python_tools ;;
            cloud) install_cloud_tools ;;
        esac
    done

    echo ""
    printf "${GREEN}========================================${NC}\n"
    printf "${GREEN}   Installation Complete!               ${NC}\n"
    printf "${GREEN}========================================${NC}\n"
    echo ""
    log_info "Please restart your terminal or run: source ~/.zshrc"
    echo ""
}

main "$@"
