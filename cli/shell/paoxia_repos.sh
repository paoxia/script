#!/bin/bash

set -e

GITHUB_USER="paoxia"
GITHUB_API="https://api.github.com/users/${GITHUB_USER}/repos"

echo "============================================================"
echo "  Paoxia GitHub Repositories Clone Tool"
echo "============================================================"
echo ""

TARGET_DIR="${1:-$(pwd)}"
mkdir -p "$TARGET_DIR"

echo "Target directory: $TARGET_DIR"
echo "Fetching repositories for user: ${GITHUB_USER}"
echo ""

fetch_repos() {
    local page=1
    local repos=()

    while true; do
        local response
        response=$(curl -s "${GITHUB_API}?page=${page}&per_page=100&type=all")

        if echo "$response" | grep -q "API rate limit"; then
            echo "Error: GitHub API rate limit exceeded"
            exit 1
        fi

        local page_repos
        page_repos=$(echo "$response" | jq -r '.[].name' 2>/dev/null || echo "")

        if [ -z "$page_repos" ]; then
            break
        fi

        while IFS= read -r repo; do
            repos+=("$repo")
        done <<< "$page_repos"

        local count
        count=$(echo "$response" | jq 'length')
        if [ "$count" -lt 100 ]; then
            break
        fi

        ((page++))
    done

    printf '%s\n' "${repos[@]}"
}

show_usage() {
    echo "Usage: $0 [target_directory] [options]"
    echo ""
    echo "Options:"
    echo "  -l, --list      List all repositories"
    echo "  -c, --clone     Clone all repositories"
    echo "  -p, --public    Clone public repositories only"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ~/projects -l          List all repos"
    echo "  $0 ~/projects -c          Clone all repos to ~/projects"
    echo "  $0 ~/projects -c -p       Clone public repos only"
    echo ""
}

list_repos() {
    echo "Repositories for ${GITHUB_USER}:"
    echo "----------------------------------------"
    local repos
    repos=$(fetch_repos)
    local count=1
    while IFS= read -r repo; do
        printf "  %2d. %s\n" "$count" "$repo"
        ((count++))
    done <<< "$repos"
    echo ""
    echo "Total: $((count-1)) repositories"
}

clone_repos() {
    local public_only="$1"
    echo "Cloning repositories..."
    echo "----------------------------------------"

    local repos
    repos=$(fetch_repos)

    while IFS= read -r repo; do
        local repo_url="https://github.com/${GITHUB_USER}/${repo}.git"
        local target_path="${TARGET_DIR}/${repo}"

        if [ -d "$target_path" ]; then
            echo "  [SKIP] ${repo} (already exists)"
        else
            echo "  [CLONE] ${repo}"
            git clone "$repo_url" "$target_path" 2>/dev/null || echo "  [ERROR] Failed to clone ${repo}"
        fi
    done <<< "$repos"

    echo ""
    echo "Done!"
}

if ! command -v jq &> /dev/null; then
    echo "Error: jq is required. Install it with: brew install jq"
    exit 1
fi

if ! command -v curl &> /dev/null; then
    echo "Error: curl is required"
    exit 1
fi

case "${2:-}" in
    -l|--list)
        list_repos
        ;;
    -c|--clone)
        clone_repos false
        ;;
    -cp|-pc)
        clone_repos true
        ;;
    -h|--help)
        show_usage
        ;;
    *)
        show_usage
        echo "Select action:"
        echo "  1) List repositories"
        echo "  2) Clone all repositories"
        echo "  3) Exit"
        echo ""
        read -p "Enter choice (1-3): " action

        case "$action" in
            1) list_repos ;;
            2) clone_repos false ;;
            3) exit 0 ;;
            *) echo "Invalid choice"; exit 1 ;;
        esac
        ;;
esac

echo ""
echo "============================================================"
echo "  GitHub: https://github.com/${GITHUB_USER}"
echo "============================================================"
