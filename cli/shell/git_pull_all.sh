#!/bin/bash

# Git Repository Batch Update Tool
# Pull each Git repository found in an immediate subdirectory of this script's directory.

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

# Inspect immediate child directories only; repositories with a .git file are not selected.
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
    
    # Each update runs in a background job, so this directory change stays in that job.
    cd "$SCRIPT_DIR/$repo"
    
    if git pull 2>&1; then
        echo -e "${GREEN}[SUCCESS] $repo${NC}"
    else
        echo -e "${RED}[FAILED] $repo${NC}"
    fi
    
    echo ""
}

# Launch a pull in the background and wait for a slot before launching another.
update_repo_parallel() {
    local repo="$1"
    
    update_repo "$repo" &
    
    # Throttle background jobs to the configured parallelism limit.
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

# Schedule every repository, then wait for the final background jobs to finish.
for repo in "${repos[@]}"; do
    update_repo_parallel "$repo"
done

wait_all

echo "============================================================"
echo -e "${BLUE}All updates completed${NC}"
echo "============================================================"
