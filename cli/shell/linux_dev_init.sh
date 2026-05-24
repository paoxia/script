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

detect_package_manager() {
    if check_command apt-get; then
        echo "apt"
    elif check_command dnf; then
        echo "dnf"
    elif check_command yum; then
        echo "yum"
    elif check_command pacman; then
        echo "pacman"
    elif check_command zypper; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

PKG_MANAGER=""
SUDO_CMD=""

setup_sudo() {
    if [[ "${EUID}" -eq 0 ]]; then
        SUDO_CMD=""
        return
    fi

    if check_command sudo; then
        SUDO_CMD="sudo"
    else
        log_error "This script requires sudo privileges."
        exit 1
    fi
}

pkg_install() {
    local packages=("$@")
    local pkg

    case "$PKG_MANAGER" in
        apt)
            $SUDO_CMD apt-get update
            $SUDO_CMD apt-get install -y "${packages[@]}"
            ;;
        dnf)
            $SUDO_CMD dnf install -y "${packages[@]}"
            ;;
        yum)
            $SUDO_CMD yum install -y "${packages[@]}"
            ;;
        pacman)
            $SUDO_CMD pacman -Sy --noconfirm --needed "${packages[@]}"
            ;;
        zypper)
            $SUDO_CMD zypper --non-interactive install "${packages[@]}"
            ;;
        *)
            log_error "Unsupported package manager: $PKG_MANAGER"
            exit 1
            ;;
    esac
}

install_git() {
    log_step "Setting up Git..."

    pkg_install git

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

    case "$PKG_MANAGER" in
        apt)
            $SUDO_CMD apt-get update
            $SUDO_CMD apt-get install -y openjdk-21-jdk maven gradle
            ;;
        dnf|yum)
            $SUDO_CMD dnf install -y java-21-openjdk-devel maven gradle
            ;;
        pacman)
            $SUDO_CMD pacman -Sy --noconfirm --needed jdk-openjdk maven gradle
            ;;
        zypper)
            $SUDO_CMD zypper --non-interactive install java-21-openjdk-devel maven gradle
            ;;
    esac

    local java_home=""
    if [[ -d /usr/lib/jvm/java-21-openjdk ]]; then
        java_home="/usr/lib/jvm/java-21-openjdk"
    elif [[ -d /usr/lib/jvm/java-21-openjdk-amd64 ]]; then
        java_home="/usr/lib/jvm/java-21-openjdk-amd64"
    elif [[ -d /usr/lib/jvm/java-21-openjdk-arm64 ]]; then
        java_home="/usr/lib/jvm/java-21-openjdk-arm64"
    fi

    if [[ -n "$java_home" ]]; then
        if ! grep -q "JAVA_HOME" ~/.bashrc 2>/dev/null; then
            echo "" >> ~/.bashrc
            echo "export JAVA_HOME=\"${java_home}\"" >> ~/.bashrc
            echo "export PATH=\"\$JAVA_HOME/bin:\$PATH\"" >> ~/.bashrc
            log_info "Added JAVA_HOME to ~/.bashrc"
        fi
    fi

    log_info "Java 21, Maven, Gradle installed"
}

install_go() {
    log_step "Setting up Go..."

    pkg_install golang-go 2>/dev/null || pkg_install go

    local go_path="${HOME}/go"
    mkdir -p "${go_path}/bin" "${go_path}/pkg" "${go_path}/src"

    if ! grep -q "GOPATH" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "export GOPATH=\"${go_path}\"" >> ~/.bashrc
        echo "export PATH=\"\$GOPATH/bin:\$PATH\"" >> ~/.bashrc
        log_info "Added GOPATH to ~/.bashrc"
    fi

    log_info "Go installed. GOPATH: ${go_path}"
}

install_node() {
    log_step "Setting up Node.js..."

    if ! check_command curl; then
        pkg_install curl
    fi

    log_info "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    nvm install --lts
    nvm use --lts

    log_info "Node.js (via nvm) installed"
}

install_docker() {
    log_step "Setting up Docker..."

    if check_command docker; then
        log_info "Docker already installed"
        return
    fi

    case "$PKG_MANAGER" in
        apt)
            $SUDO_CMD apt-get update
            $SUDO_CMD apt-get install -y ca-certificates curl gnupg
            $SUDO_CMD install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO_CMD gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            $SUDO_CMD chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | $SUDO_CMD tee /etc/apt/sources.list.d/docker.list > /dev/null
            $SUDO_CMD apt-get update
            $SUDO_CMD apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        dnf|yum)
            $SUDO_CMD dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            $SUDO_CMD dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            $SUDO_CMD systemctl enable --now docker
            ;;
        pacman)
            $SUDO_CMD pacman -Sy --noconfirm --needed docker docker-compose
            $SUDO_CMD systemctl enable --now docker
            ;;
        zypper)
            $SUDO_CMD zypper --non-interactive install docker docker-compose
            $SUDO_CMD systemctl enable --now docker
            ;;
    esac

    $SUDO_CMD usermod -aG docker "$USER" 2>/dev/null || true

    log_info "Docker installed. You may need to logout and login again for group changes."
}

install_databases() {
    log_step "Setting up database tools..."

    local packages=()

    case "$PKG_MANAGER" in
        apt)
            packages=(mysql-client postgresql-client redis-tools)
            ;;
        dnf|yum)
            packages=(mysql postgresql redis)
            ;;
        pacman)
            packages=(mariadb-clients postgresql redis)
            ;;
        zypper)
            packages=(mysql-client postgresql redis)
            ;;
    esac

    pkg_install "${packages[@]}"

    log_info "Database clients installed"
}

install_dev_tools() {
    log_step "Installing development tools..."

    local packages=(
        curl
        wget
        jq
        tree
        htop
        tmux
        vim
        git
        unzip
        zip
        build-essential
    )

    case "$PKG_MANAGER" in
        apt)
            packages+=("yq" "fzf" "ripgrep" "fd-find" "bat" "exa" "httpie")
            ;;
        dnf|yum)
            packages+=("fzf" "ripgrep" "fd-find" "bat" "httpie")
            $SUDO_CMD dnf group install -y "Development Tools" 2>/dev/null || true
            ;;
        pacman)
            packages+=("yq" "fzf" "ripgrep" "fd" "bat" "exa" "httpie")
            packages=("curl" "wget" "jq" "tree" "htop" "tmux" "vim" "git" "unzip" "zip" "base-devel" "yq" "fzf" "ripgrep" "fd" "bat" "exa" "httpie")
            ;;
        zypper)
            packages+=("fzf" "ripgrep" "bat" "httpie")
            ;;
    esac

    pkg_install "${packages[@]}"

    log_info "Development tools installed"
}

install_ide() {
    log_step "Setting up IDE..."

    if check_command idea; then
        log_info "IntelliJ IDEA already installed"
        return
    fi

    log_info "Installing IntelliJ IDEA via Snap..."
    if check_command snap; then
        $SUDO_CMD snap install intellij-idea-community --classic
    else
        log_warn "Snap not available. Please install IntelliJ IDEA manually from https://www.jetbrains.com/idea/download/"
    fi
}

install_terminal_tools() {
    log_step "Setting up terminal tools..."

    pkg_install zsh

    if [[ ! -d "${HOME}/.oh-my-zsh" ]]; then
        log_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    local zsh_plugins="${HOME}/.oh-my-zsh/custom/plugins"

    if [[ ! -d "${zsh_plugins}/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "${zsh_plugins}/zsh-autosuggestions"
    fi

    if [[ ! -d "${zsh_plugins}/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "${zsh_plugins}/zsh-syntax-highlighting"
    fi

    if ! grep -q "starship" ~/.bashrc 2>/dev/null && ! grep -q "starship" ~/.zshrc 2>/dev/null; then
        log_info "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sh
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    fi

    if ! check_command zoxide; then
        log_info "Installing zoxide..."
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
        echo 'eval "$(zoxide init zsh)"' >> ~/.zshrc
    fi

    log_info "Terminal tools installed"
}

install_python_tools() {
    log_step "Setting up Python tools..."

    case "$PKG_MANAGER" in
        apt)
            pkg_install python3 python3-pip python3-venv
            ;;
        dnf|yum)
            pkg_install python3 python3-pip python3-virtualenv
            ;;
        pacman)
            pkg_install python python-pip python-virtualenv
            ;;
        zypper)
            pkg_install python3 python3-pip python3-virtualenv
            ;;
    esac

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

    local rc_file="$HOME/.bashrc"
    if [[ -f "$HOME/.zshrc" ]]; then
        rc_file="$HOME/.zshrc"
    fi

    for tool in "${py_selections[@]}"; do
        case "$tool" in
            pyenv)
                if check_command pyenv; then
                    log_info "pyenv already installed"
                else
                    log_step "Installing pyenv..."
                    curl https://pyenv.run | bash
                    if ! grep -q "pyenv" "$rc_file" 2>/dev/null; then
                        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$rc_file"
                        echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> "$rc_file"
                        echo 'eval "$(pyenv init -)"' >> "$rc_file"
                    fi
                    export PYENV_ROOT="$HOME/.pyenv"
                    export PATH="$PYENV_ROOT/bin:$PATH"
                fi
                log_info "pyenv installed"
                ;;
            poetry)
                if check_command poetry; then
                    log_info "poetry already installed"
                else
                    log_step "Installing poetry..."
                    curl -sSL https://install.python-poetry.org | python3 -
                    export PATH="$HOME/.local/bin:$PATH"
                fi
                log_info "poetry installed"
                ;;
            uv)
                if check_command uv; then
                    log_info "uv already installed"
                else
                    log_step "Installing uv..."
                    curl -LsSf https://astral.sh/uv/install.sh | sh
                    export PATH="$HOME/.cargo/bin:$PATH"
                fi
                log_info "uv installed"
                ;;
            conda)
                if [[ -d "${HOME}/miniconda3" ]]; then
                    log_info "Miniconda already installed"
                else
                    log_step "Installing Miniconda..."
                    local arch="x86_64"
                    if [[ "$(uname -m)" == "aarch64" ]]; then
                        arch="aarch64"
                    fi
                    curl -fsSL "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-${arch}.sh" -o /tmp/miniconda.sh
                    bash /tmp/miniconda.sh -b -p "${HOME}/miniconda3"
                    rm -f /tmp/miniconda.sh
                    if ! grep -q "miniconda3" "$rc_file" 2>/dev/null; then
                        echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> "$rc_file"
                    fi
                    log_info "Miniconda installed"
                fi
                ;;
            pipenv)
                if check_command pipenv; then
                    log_info "pipenv already installed"
                else
                    log_step "Installing pipenv..."
                    pip3 install --user pipenv
                fi
                log_info "pipenv installed"
                ;;
        esac
    done

    log_info "Python tools setup complete"
}

install_cloud_tools() {
    log_step "Setting up cloud tools..."

    if ! check_command aws; then
        log_info "Installing AWS CLI..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
        unzip -o /tmp/awscliv2.zip -d /tmp
        $SUDO_CMD /tmp/aws/install
        rm -rf /tmp/aws /tmp/awscliv2.zip
    fi

    if ! check_command kubectl; then
        log_info "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        $SUDO_CMD install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm -f kubectl
    fi

    if ! check_command helm; then
        log_info "Installing helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi

    if ! check_command terraform; then
        log_info "Installing terraform..."
        curl -Lo /tmp/terraform.zip "https://releases.hashicorp.com/terraform/1.8.0/terraform_1.8.0_linux_amd64.zip"
        unzip -o /tmp/terraform.zip -d /tmp
        $SUDO_CMD mv /tmp/terraform /usr/local/bin/
        rm -f /tmp/terraform /tmp/terraform.zip
    fi

    log_info "Cloud tools installed"
}

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

    local rc_file="$HOME/.bashrc"
    if [[ -f "$HOME/.zshrc" ]]; then
        rc_file="$HOME/.zshrc"
    fi

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
                if ! grep -q "bun" "$rc_file" 2>/dev/null; then
                    echo 'export BUN_INSTALL="$HOME/.bun"' >> "$rc_file"
                    echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> "$rc_file"
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

show_menu() {
    echo ""
    printf "${CYAN}========================================${NC}\n"
    printf "${CYAN}   Linux Developer Environment Setup    ${NC}\n"
    printf "${CYAN}========================================${NC}\n"
    echo ""
    printf "${YELLOW}Detected package manager: ${PKG_MANAGER}${NC}\n"
    echo ""
    printf "${YELLOW}Select components to install:${NC}\n"
    echo ""
    echo "  1) Git                    - Version control with SSH key setup"
    echo "  2) Java (JDK 21)          - Java development with Maven & Gradle"
    echo "  3) Go                     - Go programming language"
    echo "  4) Node.js                - Node.js via nvm"
    echo "  5) Docker                 - Docker Engine & Docker Compose"
    echo "  6) Database Tools         - MySQL client, PostgreSQL client, Redis"
    echo "  7) Development Tools      - curl, wget, jq, tree, htop, tmux, etc."
    echo "  8) IDE                    - IntelliJ IDEA Community Edition"
    echo "  9) Terminal Tools         - Oh My Zsh, Starship, zoxide"
    echo " 10) Python Tools           - Python 3 + optional: pyenv, poetry, uv, conda, pipenv"
    echo " 11) Cloud Tools            - AWS CLI, kubectl, helm, terraform"
    echo " 12) Frontend Tools         - pnpm, yarn, bun, typescript, vite, prettier, eslint, etc."
    echo ""
    echo "  a) All                    - Install all components"
    echo "  q) Quit                   - Exit without installation"
    echo ""
}

main() {
    if [[ "$(uname)" == "Darwin" ]]; then
        log_error "This script is for Linux only. Use mac_dev_init.sh for macOS."
        exit 1
    fi

    PKG_MANAGER=$(detect_package_manager)
    if [[ "$PKG_MANAGER" == "unknown" ]]; then
        log_error "Unsupported system: no supported package manager found."
        exit 1
    fi

    setup_sudo

    log_info "Starting Linux development environment setup..."
    log_info "Package manager: $PKG_MANAGER"

    local selections=()

    while true; do
        show_menu
        local choice
        read -rp "Enter your choice (1-12, a, q): " choice

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
            a|A)
                selections=(git java go node docker databases dev_tools ide terminal python cloud frontend)
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
            frontend) install_frontend_tools ;;
        esac
    done

    echo ""
    printf "${GREEN}========================================${NC}\n"
    printf "${GREEN}   Installation Complete!               ${NC}\n"
    printf "${GREEN}========================================${NC}\n"
    echo ""
    log_info "Please restart your terminal or run: source ~/.bashrc"
    echo ""
}

main "$@"
