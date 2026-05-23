#!/bin/bash

# Git Repository Batch Update Tool
# Automatically pull latest code from all git repositories in current directory

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Maximum parallel pulls
max_parallel=4

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================================"
echo -e "${BLUE}Git Repository Batch Update Tool${NC}"
echo "============================================================"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}[ERROR] Git not found. Please install Git first.${NC}"
    exit 1
fi

echo "Current directory: $SCRIPT_DIR"
echo "Max parallel pulls: $max_parallel"
echo ""

# Find all git repositories
repos=()
for dir in "$SCRIPT_DIR"/*/; do
    if [ -d "$dir/.git" ]; then
        repos+=("$(basename "$dir")")
    fi
done

if [ ${#repos[@]} -eq 0 ]; then
    echo -e "${YELLOW}[INFO] No git repository found.${NC}"
    echo "Make sure there are subdirectories with .git folder."
    exit 0
fi

echo "Found ${#repos[@]} repositories:"
for repo in "${repos[@]}"; do
    echo "  - $repo"
done
echo ""

# Update a single repository
update_repo() {
    local repo="$1"
    
    echo "--------------------------------------------------"
    echo -e "Updating: ${YELLOW}$repo${NC}"
    echo "--------------------------------------------------"
    
    cd "$SCRIPT_DIR/$repo"
    
    if git pull 2>&1; then
        echo -e "${GREEN}[SUCCESS] $repo${NC}"
    else
        echo -e "${RED}[FAILED] $repo${NC}"
    fi
    
    echo ""
}

# Update repositories in parallel
update_repo_parallel() {
    local repo="$1"
    
    update_repo "$repo" &
    
    while [ $(jobs | wc -l) -ge $max_parallel ]; do
        sleep 1
    done
}

# Wait for all background jobs to complete
wait_all() {
    echo ""
    echo "Waiting for all updates to complete..."
    wait
}

echo "Starting parallel updates..."
echo ""

for repo in "${repos[@]}"; do
    update_repo_parallel "$repo"
done

wait_all

echo "============================================================"
echo -e "${BLUE}All updates completed${NC}"
echo "============================================================"