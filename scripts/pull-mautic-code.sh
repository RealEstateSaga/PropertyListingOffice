#!/bin/bash
# =============================================================================
# Pull Mautic Code from Live Server
# =============================================================================
# This script pulls operational Mautic code from a live server into this
# repository using a temporary archive approach.
#
# The script:
#   1. Creates a temporary archive on the server excluding unwanted files
#   2. Downloads the archive to the local repository
#   3. Extracts the files into the repo
#   4. Stages, commits with a clear message, and pushes to main
#
# What gets pulled:
#   - app/          Main application directory (excluding local.php)
#   - plugins/      Custom plugins
#   - themes/       Custom themes
#   - scripts/      Custom utility scripts (if present on server)
#
# What gets excluded:
#   - media/        User uploads and media files
#   - cache/        Runtime cache files
#   - logs/         Log files
#   - app/config/local.php  Server-specific configuration with credentials
#
# Usage:
#   1. Update the placeholder variables below with your actual values
#   2. Run: ./scripts/pull-mautic-code.sh
#
# Prerequisites:
#   - SSH key configured for passwordless access to the server
#   - tar installed on both local and remote systems
#   - git installed locally
#   - Read permissions for the Mautic directories on the server
#
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION - Replace these placeholders with your actual values
# =============================================================================

# Server connection details
SERVER_USER="SERVER_USER"           # SSH username for the server
SERVER_IP="SERVER_IP"               # Server hostname or IP address

# Paths
REMOTE_MAUTIC_PATH="/path/to/mautic"    # Path to Mautic installation on server
LOCAL_REPO_PATH="/path/to/local/repo"   # Path to local repository

# =============================================================================
# Script variables (do not modify unless necessary)
# =============================================================================

ARCHIVE_NAME="mautic-code-$(date +%Y%m%d-%H%M%S).tar.gz"
REMOTE_ARCHIVE="/tmp/${ARCHIVE_NAME}"
LOCAL_ARCHIVE="/tmp/${ARCHIVE_NAME}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Functions
# =============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

check_placeholder() {
    local var_name="$1"
    local var_value="$2"
    local placeholder="$3"
    
    if [[ "$var_value" == "$placeholder" ]]; then
        log_error "Placeholder '${placeholder}' has not been replaced for ${var_name}"
        log_error "Please update the configuration section at the top of this script"
        return 1
    fi
    return 0
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local has_errors=0

    # Check for required commands
    for cmd in ssh tar git; do
        if ! command -v "$cmd" &> /dev/null; then
            log_error "'$cmd' is required but not installed."
            has_errors=1
        fi
    done

    # Check placeholders have been replaced
    check_placeholder "SERVER_USER" "$SERVER_USER" "SERVER_USER" || has_errors=1
    check_placeholder "SERVER_IP" "$SERVER_IP" "SERVER_IP" || has_errors=1
    check_placeholder "REMOTE_MAUTIC_PATH" "$REMOTE_MAUTIC_PATH" "/path/to/mautic" || has_errors=1
    check_placeholder "LOCAL_REPO_PATH" "$LOCAL_REPO_PATH" "/path/to/local/repo" || has_errors=1

    if [[ $has_errors -eq 1 ]]; then
        exit 1
    fi

    # Check local repository path exists
    if [[ ! -d "$LOCAL_REPO_PATH" ]]; then
        log_error "Local repository path does not exist: $LOCAL_REPO_PATH"
        exit 1
    fi

    # Check if local path is a git repository
    if [[ ! -d "$LOCAL_REPO_PATH/.git" ]]; then
        log_error "Local path is not a git repository: $LOCAL_REPO_PATH"
        exit 1
    fi

    log_info "All prerequisites satisfied"
}

create_remote_archive() {
    log_step "Step 1: Creating temporary archive on server..."
    
    log_info "Connecting to ${SERVER_USER}@${SERVER_IP}"
    log_info "Creating archive of: ${REMOTE_MAUTIC_PATH}"
    log_info "Archive location: ${REMOTE_ARCHIVE}"
    
    # Create tar archive on remote server, excluding unwanted files
    # Using printf %q to safely quote paths for the remote shell
    ssh "${SERVER_USER}@${SERVER_IP}" "cd $(printf '%q' "${REMOTE_MAUTIC_PATH}") && tar -czf $(printf '%q' "${REMOTE_ARCHIVE}") \
        --exclude='media' \
        --exclude='media/*' \
        --exclude='cache' \
        --exclude='cache/*' \
        --exclude='var/cache' \
        --exclude='var/cache/*' \
        --exclude='logs' \
        --exclude='logs/*' \
        --exclude='var/logs' \
        --exclude='var/logs/*' \
        --exclude='var/log' \
        --exclude='var/log/*' \
        --exclude='app/config/local.php' \
        --exclude='vendor' \
        --exclude='vendor/*' \
        --exclude='node_modules' \
        --exclude='node_modules/*' \
        --exclude='*.log' \
        --exclude='.env' \
        --exclude='.env.local' \
        app plugins themes 2>/dev/null || true"
    
    # Also include scripts directory if it exists
    ssh "${SERVER_USER}@${SERVER_IP}" "if [ -d $(printf '%q' "${REMOTE_MAUTIC_PATH}/scripts") ]; then \
        cd $(printf '%q' "${REMOTE_MAUTIC_PATH}") && tar -rzf $(printf '%q' "${REMOTE_ARCHIVE}") scripts 2>/dev/null || true; \
    fi"
    
    log_info "Archive created successfully on server"
}

download_archive() {
    log_step "Step 2: Downloading archive to local machine..."
    
    log_info "Downloading from: ${SERVER_USER}@${SERVER_IP}:${REMOTE_ARCHIVE}"
    log_info "Downloading to: ${LOCAL_ARCHIVE}"
    
    scp "${SERVER_USER}@${SERVER_IP}:${REMOTE_ARCHIVE}" "${LOCAL_ARCHIVE}"
    
    # Verify the download
    if [[ ! -f "$LOCAL_ARCHIVE" ]]; then
        log_error "Failed to download archive"
        exit 1
    fi
    
    local archive_size
    archive_size=$(du -h "$LOCAL_ARCHIVE" | cut -f1)
    log_info "Archive downloaded successfully (${archive_size})"
}

extract_archive() {
    log_step "Step 3: Extracting files into repository..."
    
    log_info "Extracting to: ${LOCAL_REPO_PATH}"
    
    # Extract the archive into the local repository
    tar -xzf "${LOCAL_ARCHIVE}" -C "${LOCAL_REPO_PATH}"
    
    log_info "Files extracted successfully"
}

cleanup_remote_archive() {
    log_info "Cleaning up remote archive..."
    
    ssh "${SERVER_USER}@${SERVER_IP}" "rm -f $(printf '%q' "${REMOTE_ARCHIVE}")" || true
    
    log_info "Remote archive cleaned up"
}

cleanup_local_archive() {
    log_info "Cleaning up local archive..."
    
    rm -f "${LOCAL_ARCHIVE}" || true
    
    log_info "Local archive cleaned up"
}

commit_and_push() {
    log_step "Step 4: Staging, committing, and pushing changes..."
    
    cd "${LOCAL_REPO_PATH}"
    
    # Check if there are any changes to commit
    if git diff --quiet && git diff --staged --quiet; then
        log_warn "No changes detected, nothing to commit"
        return 0
    fi
    
    # Stage all changes
    log_info "Staging changes..."
    git add -A
    
    # Show what's being committed
    log_info "Changes to be committed:"
    git --no-pager status --short
    
    # Commit with a descriptive message
    local commit_date
    commit_date=$(date +"%Y-%m-%d %H:%M:%S")
    local commit_message="Sync Mautic code from production server (${commit_date})"
    
    log_info "Committing with message: ${commit_message}"
    git commit -m "${commit_message}"
    
    # Push to main branch
    log_info "Pushing to main branch..."
    git push origin main
    
    log_info "Changes committed and pushed successfully"
}

show_summary() {
    echo ""
    echo "=============================================="
    echo -e "${GREEN}  Pull Complete!${NC}"
    echo "=============================================="
    echo ""
    log_info "Summary:"
    echo "  - Server: ${SERVER_USER}@${SERVER_IP}"
    echo "  - Remote path: ${REMOTE_MAUTIC_PATH}"
    echo "  - Local repo: ${LOCAL_REPO_PATH}"
    echo ""
    log_info "Directories synced:"
    echo "  - app/"
    echo "  - plugins/"
    echo "  - themes/"
    echo "  - scripts/ (if present on server)"
    echo ""
    log_info "Files excluded:"
    echo "  - media/"
    echo "  - cache/"
    echo "  - logs/"
    echo "  - app/config/local.php"
    echo "  - vendor/"
    echo ""
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    echo "=============================================="
    echo "  Pull Mautic Code from Live Server"
    echo "=============================================="
    echo ""
    
    check_prerequisites
    
    echo ""
    log_info "Server: ${SERVER_USER}@${SERVER_IP}"
    log_info "Remote Mautic path: ${REMOTE_MAUTIC_PATH}"
    log_info "Local repository: ${LOCAL_REPO_PATH}"
    echo ""
    
    # Step 1: Create archive on server
    create_remote_archive
    
    # Step 2: Download archive
    download_archive
    
    # Step 3: Extract files
    extract_archive
    
    # Cleanup archives
    cleanup_remote_archive
    cleanup_local_archive
    
    # Step 4: Git operations
    commit_and_push
    
    # Show summary
    show_summary
}

# Run main function
main "$@"
