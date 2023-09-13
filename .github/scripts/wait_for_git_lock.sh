#!/bin/bash
# Required variable: $GIT_REPO_DIR

# Function to check if .git/index.lock exists and wait until it's gone
function wait_for_git_lock {
    while [ -f "$GIT_REPO_DIR/.git/index.lock" ]; do
        echo "A Git lock file (.git/index.lock) is present. Waiting..."
        sleep 5
    done
    echo "No Git lock file found. Proceeding."
}
