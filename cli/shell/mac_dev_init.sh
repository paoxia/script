#!/usr/bin/env bash

# Interactive macOS development environment setup with optional CLI installers.
# Run this script with Bash; restart the terminal to load persisted shell settings.

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Shared logging helpers use consistent colors; errors are written to stderr.
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

# Check PATH without printing the executable location.
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Install Homebrew when absent and load the Apple Silicon or Intel executable path.
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

# Skip installed formulae and forward any extra installation options.
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

# Install desktop applications through Homebrew casks only when absent.
brew_cask_install() {
    local package="$1"

    if brew list --cask "$package" &>/dev/null; then
        log_info "$package (cask) already installed"
        return 0
    fi

    log_step "Installing $package (cask)..."
    brew install --cask "$package"
}

# Install Git and initialize user settings and an SSH key only when absent.
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

# Install GitHub CLI through Homebrew and display its login command.
install_github_cli() {
    if check_command gh; then
        log_info "GitHub CLI already installed"
        return
    fi

    brew_install gh
    gh --version
    log_info "GitHub login: gh auth login"
}

# Reuse an available Node.js environment or install LTS for npm-based CLIs.
ensure_cli_node() {
    if ! check_command node || ! check_command npm; then
        export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            # Load an existing nvm installation before installing Node.js.
            . "$NVM_DIR/nvm.sh"
        elif check_command brew && [[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ]]; then
            . "$(brew --prefix)/opt/nvm/nvm.sh"
        fi
    fi

    if ! check_command node || ! check_command npm || ! node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 16 ? 0 : 1)'; then
        log_info "CLI tools require Node.js 16+ and npm; installing Node.js LTS..."
        install_node
    fi
}

# Install a missing CLI globally and verify its executable. Arguments: command, package, version flag.
install_npm_cli() {
    local command_name="$1"
    local package="$2"
    local version_arg="${3:---version}"

    if check_command "$command_name"; then
        log_info "$command_name already installed"
        return
    fi

    ensure_cli_node
    # Loading nvm may also make an existing CLI available.
    if check_command "$command_name"; then
        log_info "$command_name already installed"
        return
    fi

    log_step "Installing $command_name..."
    npm install -g "$package"
    "$command_name" "$version_arg"
}

# Install dws and display the separate login command.
install_dingtalk_cli() {
    install_npm_cli dws dingtalk-workspace-cli version
    log_info "DingTalk login: dws auth login"
}

# Install lark-cli and display the app configuration and login commands.
install_feishu_cli() {
    install_npm_cli lark-cli @larksuite/cli
    log_info "Feishu setup: lark-cli config init"
    log_info "Feishu login: lark-cli auth login --recommend"
}

# Install Codex CLI and display the command used for interactive sign-in.
install_codex_cli() {
    install_npm_cli codex @openai/codex
    log_info "Start Codex and sign in: codex"
}

# Install JDK 21 and build tools, then register the JDK and persist JAVA_HOME.
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

# Install Go and persist a user-owned GOPATH for future shell sessions.
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

# Install Node.js LTS through nvm and activate it in this script's shell.
install_node() {
    log_step "Setting up Node.js..."

    brew_install nvm

    local nvm_dir="${HOME}/.nvm"
    local nvm_script
    # Homebrew keeps nvm.sh in its opt directory, separate from NVM_DIR's Node versions.
    nvm_script="$(brew --prefix)/opt/nvm/nvm.sh"
    mkdir -p "$nvm_dir"

    if ! grep -q "NVM_DIR" ~/.zshrc 2>/dev/null; then
        echo "" >> ~/.zshrc
        echo "export NVM_DIR=\"\$HOME/.nvm\"" >> ~/.zshrc
        log_info "Added NVM to ~/.zshrc"
    fi

    # Persist the Homebrew nvm loader without duplicating it on repeated runs.
    if ! grep -Fq "$nvm_script" ~/.zshrc 2>/dev/null; then
        echo "[ -s \"$nvm_script\" ] && \. \"$nvm_script\"" >> ~/.zshrc
    fi

    export NVM_DIR="$nvm_dir"
    . "$nvm_script"

    nvm install --lts
    nvm use --lts

    log_info "Node.js (via nvm) installed"
}

# Install Docker Desktop; the user starts the application separately.
install_docker() {
    log_step "Setting up Docker..."

    brew_cask_install docker

    log_info "Docker Desktop installed. Please start it from Applications."
}

# Install database clients and the DBeaver desktop application.
install_databases() {
    log_step "Setting up database tools..."

    brew_install mysql-client
    brew_install postgresql
    brew_install redis

    brew_cask_install dbeaver-community

    log_info "MySQL client, PostgreSQL, Redis, DBeaver installed"
}

# Install development utilities and request fzf key bindings and completion.
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

# Install IntelliJ IDEA Community Edition as a Homebrew cask.
install_ide() {
    log_step "Setting up IDE..."

    brew_cask_install "intellij-idea-ce"

    log_info "IntelliJ IDEA CE installed"
}

# Install Zsh helpers and append startup hooks only when not already configured.
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

# Install Python, then collect and install optional environment and package managers.
install_python_tools() {
    log_step "Setting up Python tools..."

    brew_install python@3.12

    echo ""
    printf "${YELLOW}Select Python tools to install:${NC}\n"
    echo "  1) pyenv      - Python version manager"
    echo "  2) poetry     - Dependency management"
    echo "  3) uv         - Fast Python package installer"
    echo "  4) conda      - Miniconda (Anaconda distribution)"
    echo "  5) pipenv     - Pipenv virtualenv manager"
    echo "  a) All        - Install all Python tools"
    echo "  n) None       - Skip additional tools"
    echo ""

    # Collect choices before running any optional Python tool installers.
    local py_selections=()
    while true; do
        read -rp "Enter your choice (1-5, a, n): " py_choice
        case "$py_choice" in
            1) py_selections+=("pyenv") ;;
            2) py_selections+=("poetry") ;;
            3) py_selections+=("uv") ;;
            4) py_selections+=("conda") ;;
            5) py_selections+=("pipenv") ;;
            a|A)
                py_selections=(pyenv poetry uv conda pipenv)
                break
                ;;
            n|N)
                break
                ;;
            *)
                log_error "Invalid choice: $py_choice"
                continue
                ;;
        esac
        read -rp "Select more? (y/n): " more
        [[ "$more" != "y" && "$more" != "Y" ]] && break
    done

    for tool in "${py_selections[@]}"; do
        case "$tool" in
            pyenv)
                brew_install pyenv
                if ! grep -q "pyenv" ~/.zshrc 2>/dev/null; then
                    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
                    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
                    echo 'eval "$(pyenv init -)"' >> ~/.zshrc
                fi
                log_info "pyenv installed"
                ;;
            poetry)
                brew_install poetry
                log_info "poetry installed"
                ;;
            uv)
                brew_install uv
                log_info "uv installed"
                ;;
            conda)
                if [[ -d "${HOME}/miniconda3" ]]; then
                    log_info "Miniconda already installed"
                else
                    log_step "Installing Miniconda..."
                    curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh -o /tmp/miniconda.sh
                    bash /tmp/miniconda.sh -b -p "${HOME}/miniconda3"
                    rm -f /tmp/miniconda.sh
                    if ! grep -q "miniconda3" ~/.zshrc 2>/dev/null; then
                        echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> ~/.zshrc
                    fi
                    log_info "Miniconda installed"
                fi
                ;;
            pipenv)
                brew_install pipenv
                log_info "pipenv installed"
                ;;
        esac
    done

    log_info "Python tools setup complete"
}

# Install the AWS, Kubernetes, Helm, and Terraform command-line tools.
install_cloud_tools() {
    log_step "Setting up cloud tools..."

    brew_install awscli
    brew_install kubectl
    brew_install helm
    brew_install terraform

    log_info "AWS CLI, kubectl, helm, terraform installed"
}

# Require Node.js, then collect and install the selected frontend tools.
install_frontend_tools() {
    log_step "Setting up frontend tools..."

    if ! check_command node; then
        log_warn "Node.js not found. Please install Node.js first (option 4)."
        return 1
    fi

    echo ""
    printf "${YELLOW}Select frontend tools to install:${NC}\n"
    echo "  1) pnpm         - Fast, disk space efficient package manager"
    echo "  2) yarn         - Fast and reliable package manager"
    echo "  3) bun          - Fast all-in-one JavaScript runtime"
    echo "  4) typescript   - TypeScript compiler"
    echo "  5) vite         - Next generation frontend tooling"
    echo "  6) prettier     - Code formatter"
    echo "  7) eslint       - JavaScript linter"
    echo "  8) @angular/cli - Angular CLI"
    echo "  9) create-vue   - Vue.js project scaffolding"
    echo " 10) create-react-app - React project scaffolding"
    echo "  a) All          - Install all frontend tools"
    echo "  n) None         - Skip frontend tools"
    echo ""

    # Collect choices before installing global npm packages or the Bun runtime.
    local fe_selections=()
    while true; do
        read -rp "Enter your choice (1-10, a, n): " fe_choice
        case "$fe_choice" in
            1) fe_selections+=("pnpm") ;;
            2) fe_selections+=("yarn") ;;
            3) fe_selections+=("bun") ;;
            4) fe_selections+=("typescript") ;;
            5) fe_selections+=("vite") ;;
            6) fe_selections+=("prettier") ;;
            7) fe_selections+=("eslint") ;;
            8) fe_selections+=("angular") ;;
            9) fe_selections+=("vue") ;;
            10) fe_selections+=("react") ;;
            a|A)
                fe_selections=(pnpm yarn bun typescript vite prettier eslint angular vue react)
                break
                ;;
            n|N)
                break
                ;;
            *)
                log_error "Invalid choice: $fe_choice"
                continue
                ;;
        esac
        read -rp "Select more? (y/n): " more
        [[ "$more" != "y" && "$more" != "Y" ]] && break
    done

    for tool in "${fe_selections[@]}"; do
        case "$tool" in
            pnpm)
                log_step "Installing pnpm..."
                npm install -g pnpm
                log_info "pnpm installed"
                ;;
            yarn)
                log_step "Installing yarn..."
                npm install -g yarn
                log_info "yarn installed"
                ;;
            bun)
                log_step "Installing bun..."
                curl -fsSL https://bun.sh/install | bash
                if ! grep -q "bun" ~/.zshrc 2>/dev/null; then
                    echo 'export BUN_INSTALL="$HOME/.bun"' >> ~/.zshrc
                    echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> ~/.zshrc
                fi
                log_info "bun installed"
                ;;
            typescript)
                log_step "Installing TypeScript..."
                npm install -g typescript ts-node
                log_info "TypeScript installed"
                ;;
            vite)
                log_step "Installing Vite..."
                npm install -g vite
                log_info "Vite installed"
                ;;
            prettier)
                log_step "Installing Prettier..."
                npm install -g prettier
                log_info "Prettier installed"
                ;;
            eslint)
                log_step "Installing ESLint..."
                npm install -g eslint
                log_info "ESLint installed"
                ;;
            angular)
                log_step "Installing Angular CLI..."
                npm install -g @angular/cli
                log_info "Angular CLI installed"
                ;;
            vue)
                log_step "Installing create-vue..."
                npm install -g create-vue
                log_info "create-vue installed"
                ;;
            react)
                log_step "Installing create-react-app..."
                npm install -g create-react-app
                log_info "create-react-app installed"
                ;;
        esac
    done

    log_info "Frontend tools setup complete"
}

# Display component numbers used by the selection dispatcher in main.
show_menu() {
    echo ""
    printf "${CYAN}========================================${NC}\n"
    printf "${CYAN}   Mac Developer Environment Setup       ${NC}\n"
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
    echo " 10) Python Tools           - Python 3.12 + optional: pyenv, poetry, uv, conda, pipenv"
    echo " 11) Cloud Tools            - AWS CLI, kubectl, helm, terraform"
    echo " 12) Frontend Tools         - pnpm, yarn, bun, typescript, vite, prettier, eslint, etc."
    echo " 13) GitHub CLI             - GitHub from the terminal (gh)"
    echo " 14) DingTalk CLI           - DingTalk Workspace CLI (dws)"
    echo " 15) Feishu CLI             - Official Lark/Feishu CLI (lark-cli)"
    echo " 16) Codex CLI              - OpenAI coding agent (codex)"
    echo ""
    echo "  a) All                    - Install all components"
    echo "  q) Quit                   - Exit without installation"
    echo ""
}

# Read a value and return the supplied default when the input is empty.
read_selection() {
    local prompt="$1"
    local default="$2"
    local result

    read -rp "$prompt" result
    echo "${result:-$default}"
}

# Validate the platform, collect choices, and install components after confirmation.
main() {
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is designed for macOS only."
        exit 1
    fi

    log_info "Starting Mac development environment setup..."

    ensure_homebrew
    brew update

    # Preserve selection order; the All preset installs Node.js before npm-based tools.
    local selections=()

    while true; do
        show_menu
        local choice
        read -rp "Enter your choice (1-16, a, q): " choice

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
            12) selections+=("frontend") ;;
            13) selections+=("github_cli") ;;
            14) selections+=("dingtalk_cli") ;;
            15) selections+=("feishu_cli") ;;
            16) selections+=("codex_cli") ;;
            a|A)
                selections=(git java go node docker databases dev_tools ide terminal python cloud frontend github_cli dingtalk_cli feishu_cli codex_cli)
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

    # Confirm the complete component list before applying installation changes.
    local confirm
    read -rp "Proceed? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log_info "Installation cancelled."
        exit 0
    fi

    # Dispatch each selected component to its installer in the collected order.
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
            frontend) install_frontend_tools ;;
            github_cli) install_github_cli ;;
            dingtalk_cli) install_dingtalk_cli ;;
            feishu_cli) install_feishu_cli ;;
            codex_cli) install_codex_cli ;;
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

# Execute the interactive setup when this script is invoked.
main "$@"
