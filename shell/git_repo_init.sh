#!/bin/bash

set -e

# 检查 git 是否已安装
check_git_installed() {
    if command -v git &> /dev/null; then
        echo "Git 已安装: $(git --version)"
        return 0
    fi
    return 1
}

# 检测操作系统类型
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian)
                echo "debian"
                ;;
            centos|rhel|fedora|rocky|almalinux)
                echo "redhat"
                ;;
            arch|manjaro)
                echo "arch"
                ;;
            opensuse*)
                echo "suse"
                ;;
            alpine)
                echo "alpine"
                ;;
            *)
                echo "unknown"
                ;;
        esac
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# 在 macOS 上安装 git
install_git_macos() {
    echo "检测到 macOS 系统"
    if command -v brew &> /dev/null; then
        echo "使用 Homebrew 安装 git..."
        brew install git
    else
        echo "Homebrew 未安装，建议先安装 Homebrew: https://brew.sh/"
        echo "或者通过 Xcode Command Line Tools 安装 git"
        xcode-select --install 2>/dev/null || true
        echo "请按照提示完成安装，然后重新运行此脚本"
        exit 1
    fi
}

# 在 Debian/Ubuntu 上安装 git
install_git_debian() {
    echo "检测到 Debian/Ubuntu 系统"
    sudo apt-get update
    sudo apt-get install -y git
}

# 在 RedHat/CentOS/Fedora 上安装 git
install_git_redhat() {
    echo "检测到 RedHat/CentOS/Fedora 系统"
    if command -v dnf &> /dev/null; then
        sudo dnf install -y git
    else
        sudo yum install -y git
    fi
}

# 在 Arch Linux 上安装 git
install_git_arch() {
    echo "检测到 Arch Linux 系统"
    sudo pacman -S --noconfirm git
}

# 在 openSUSE 上安装 git
install_git_suse() {
    echo "检测到 openSUSE 系统"
    sudo zypper install -y git
}

# 在 Alpine Linux 上安装 git
install_git_alpine() {
    echo "检测到 Alpine Linux 系统"
    sudo apk add --no-cache git
}

# 检查 git 是否已配置
check_git_configured() {
    local name=$(git config --global user.name 2>/dev/null || true)
    local email=$(git config --global user.email 2>/dev/null || true)
    if [ -n "$name" ] && [ -n "$email" ]; then
        echo "Git 已配置:"
        echo "  用户名: $name"
        echo "  邮箱: $email"
        return 0
    fi
    return 1
}

# 检查 jq 是否安装，没有则尝试安装
check_jq() {
    if command -v jq &> /dev/null; then
        return 0
    fi
    echo "jq 未安装，尝试安装..."
    local os_type=$(detect_os)
    case "$os_type" in
        macos)
            if command -v brew &> /dev/null; then
                brew install jq
            else
                echo "请手动安装 jq: https://stedolan.github.io/jq/download/"
                return 1
            fi
            ;;
        debian)
            sudo apt-get install -y jq
            ;;
        redhat)
            if command -v dnf &> /dev/null; then
                sudo dnf install -y jq
            else
                sudo yum install -y jq
            fi
            ;;
        arch)
            sudo pacman -S --noconfirm jq
            ;;
        suse)
            sudo zypper install -y jq
            ;;
        alpine)
            sudo apk add --no-cache jq
            ;;
        *)
            echo "请手动安装 jq: https://stedolan.github.io/jq/download/"
            return 1
            ;;
    esac
    return 0
}

# 克隆所有未归档的项目
clone_repos() {
    local token="$1"
    local target_dir="./github_repos"

    echo ""
    echo "🚀 开始克隆仓库到目录：$target_dir"
    mkdir -p "$target_dir"

    local page=1
    local per_page=100
    local total_cloned=0

    while true; do
        echo "获取第 $page 页仓库..."
        local response=$(curl -s -w "\n%{http_code}" \
            -H "Authorization: token $token" \
            -H "Accept: application/vnd.github+json" \
            "https://api.github.com/user/repos?per_page=$per_page&page=$page&visibility=all&affiliation=owner")

        local http_code=$(echo "$response" | tail -n1)
        local body=$(echo "$response" | head -n -1)

        if [ "$http_code" != "200" ]; then
            echo "❌ 请求失败: $http_code"
            echo "$body"
            return 1
        fi

        # 检查是否有仓库
        local repo_count=$(echo "$body" | jq -r 'length')
        if [ "$repo_count" == "0" ] || [ "$repo_count" == "null" ]; then
            echo "✅ 所有仓库处理完毕。共克隆 $total_cloned 个仓库。"
            break
        fi

        # 遍历每个仓库
        for i in $(seq 0 $((repo_count - 1))); do
            local archived=$(echo "$body" | jq -r ".[$i].archived")
            local repo_name=$(echo "$body" | jq -r ".[$i].name")
            local clone_url=$(echo "$body" | jq -r ".[$i].clone_url")

            # 跳过归档的仓库
            if [ "$archived" == "true" ]; then
                echo "⏭ 跳过归档仓库：$repo_name"
                continue
            fi

            local target_path="$target_dir/$repo_name"

            # 跳过已存在的
            if [ -d "$target_path" ]; then
                echo "🔁 已存在，跳过：$repo_name"
                continue
            fi

            echo "🔄 克隆：$clone_url → $target_path"
            git clone "$clone_url" "$target_path"
            total_cloned=$((total_cloned + 1))
        done

        page=$((page + 1))
    done
}

# 配置 GitHub 账号
configure_github() {
    echo ""
    echo "========================================="
    echo "       GitHub 账号配置流程"
    echo "========================================="
    echo ""

    # 检查是否已配置
    if check_git_configured; then
        echo ""
        read -p "是否要重新配置? (y/N): " reconfig
        if [[ ! "$reconfig" =~ ^[Yy]$ ]]; then
            echo "保持现有配置。"
        else
            echo ""
            echo "请输入您的 GitHub 用户名:"
            read -p "> " git_user

            echo ""
            echo "请输入您的 GitHub 邮箱:"
            read -p "> " git_email

            # 配置 git
            git config --global user.name "$git_user"
            git config --global user.email "$git_email"

            echo ""
            echo "✅ Git 配置已保存!"
            echo "  用户名: $(git config --global user.name)"
            echo "  邮箱: $(git config --global user.email)"
        fi
    else
        echo ""
        echo "请输入您的 GitHub 用户名:"
        read -p "> " git_user

        echo ""
        echo "请输入您的 GitHub 邮箱:"
        read -p "> " git_email

        # 配置 git
        git config --global user.name "$git_user"
        git config --global user.email "$git_email"

        echo ""
        echo "✅ Git 配置已保存!"
        echo "  用户名: $(git config --global user.name)"
        echo "  邮箱: $(git config --global user.email)"
    fi

    echo ""

    # SSH Key 配置提示
    echo "========================================="
    echo "       SSH Key 配置 (可选)"
    echo "========================================="
    echo ""

    local ssh_key="$HOME/.ssh/id_ed25519"
    if [ -f "$ssh_key" ] || [ -f "$HOME/.ssh/id_rsa" ]; then
        echo "✅ SSH Key 已存在。"
        if [ -f "$ssh_key" ]; then
            echo ""
            echo "您的公钥是:"
            cat "$ssh_key.pub"
        else
            echo ""
            echo "您的公钥是:"
            cat "$HOME/.ssh/id_rsa.pub"
        fi
    else
        read -p "是否要生成 SSH Key? (Y/n): " gen_ssh
        if [[ ! "$gen_ssh" =~ ^[Nn]$ ]]; then
            local git_email=$(git config --global user.email)
            echo ""
            echo "生成 SSH Key (ed25519)..."
            ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key" -N ""

            echo ""
            echo "✅ SSH Key 已生成!"
            echo ""
            echo "您的公钥是:"
            cat "$ssh_key.pub"
            echo ""
        fi
    fi

    echo ""
    echo "========================================="
    echo "       GitHub Token 配置"
    echo "========================================="
    echo ""
    echo "请在 GitHub 上创建 Personal Access Token:"
    echo "1. 访问: https://github.com/settings/tokens/new"
    echo "2. 选择 'repo' 权限范围"
    echo "3. 生成并复制 token (以 ghp_ 开头)"
    echo ""

    read -p "请输入您的 GitHub Token: " github_token

    if [ -n "$github_token" ]; then
        echo ""
        echo "✅ Token 已设置!"

        # 检查 jq
        if ! check_jq; then
            echo "⚠️  无法安装 jq，跳过克隆步骤。"
            return 0
        fi

        echo ""
        echo "========================================="
        echo "       克隆所有未归档项目"
        echo "========================================="
        echo ""

        read -p "是否现在开始克隆所有未归档的项目? (Y/n): " do_clone
        if [[ ! "$do_clone" =~ ^[Nn]$ ]]; then
            # 获取脚本所在目录
            SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            cd "$SCRIPT_DIR/.."
            clone_repos "$github_token"
            echo ""
            echo "✅ 克隆完成!"
        else
            echo "稍后可以重新运行此脚本进行克隆。"
        fi
    else
        echo "未输入 Token，跳过克隆步骤。"
    fi

    echo ""
    echo "配置完成!"
}

# 主函数
main() {
    if check_git_installed; then
        configure_github
        return 0
    fi

    echo "Git 未安装，开始安装..."
    local os_type=$(detect_os)

    case "$os_type" in
        macos)
            install_git_macos
            ;;
        debian)
            install_git_debian
            ;;
        redhat)
            install_git_redhat
            ;;
        arch)
            install_git_arch
            ;;
        suse)
            install_git_suse
            ;;
        alpine)
            install_git_alpine
            ;;
        *)
            echo "不支持的操作系统: $os_type"
            echo "请手动安装 git"
            exit 1
            ;;
    esac

    # 验证安装
    if check_git_installed; then
        echo "Git 安装成功!"
        configure_github
    else
        echo "Git 安装失败，请检查错误信息"
        exit 1
    fi
}

main "$@"
