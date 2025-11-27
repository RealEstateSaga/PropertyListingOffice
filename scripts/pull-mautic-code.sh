#!/bin/bash
# =============================================================================
# Pull Mautic Code from Live Server (with embedded password for educational purposes)
# =============================================================================

set -euo pipefail

# =============================================================================
# CONFIGURATION - Replace these with your actual server details
# =============================================================================

SERVER_USER="root"
SERVER_PASSWORD="@TheHouseToday1"
SERVER_IP="209.182.227.34"

REMOTE_MAUTIC_PATH="/path/to/mautic"    # Path to Mautic installation on server
LOCAL_REPO_PATH="/path/to/local/repo"   # Path to local repository

GIT_BRANCH="main"                       # Target branch to push to

# =============================================================================
# Script variables
# =============================================================================

ARCHIVE_NAME="mautic-code-$(date +%Y%m%d-%H%M%S).tar.gz"
REMOTE_ARCHIVE="/tmp/${ARCHIVE_NAME}"
LOCAL_ARCHIVE="/tmp/${ARCHIVE_NAME}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

check_prerequisites() {
    log_info "Checking prerequisites..."
    for cmd in sshpass ssh tar git; do
        command -v "$cmd" >/dev/null 2>&1 || { log_error "$cmd is required but not installed"; exit 1; }
    done
    [[ -d "$LOCAL_REPO_PATH" ]] || { log_error "Local repository path does not exist: $LOCAL_REPO_PATH"; exit 1; }
    [[ -d "$LOCAL_REPO_PATH/.git" ]] || { log_error "Local path is not a git repository: $LOCAL_REPO_PATH"; exit 1; }
    log_info "All prerequisites satisfied"
}

create_remote_archive() {
    log_step "Creating archive on server..."
    sshpass -p "$SERVER_PASSWORD" ssh $SERVER_USER@$SERVER_IP "
        cd $(printf '%q' "$REMOTE_MAUTIC_PATH") &&
        DIRS_TO_ARCHIVE=''; 
        for dir in app plugins themes; do [ -d \"\$dir\" ] && DIRS_TO_ARCHIVE=\"\$DIRS_TO_ARCHIVE \$dir\"; done;
        [ -d scripts ] && DIRS_TO_ARCHIVE=\"\$DIRS_TO_ARCHIVE scripts\";
        [ -z \"\$DIRS_TO_ARCHIVE\" ] && echo '[ERROR] No directories to archive' && exit 1;
        tar -czf $(printf '%q' "$REMOTE_ARCHIVE") --exclude='media' --exclude='cache' --exclude='var/cache' --exclude='logs' --exclude='var/logs' --exclude='var/log' --exclude='app/config/local.php' --exclude='vendor' --exclude='node_modules' --exclude='*.log' --exclude='.env' --exclude='.env.local' \$DIRS_TO_ARCHIVE
    "
    log_info "Archive created on server: $REMOTE_ARCHIVE"
}

download_archive() {
    log_step "Downloading archive..."
    sshpass -p "$SERVER_PASSWORD" scp $SERVER_USER@$SERVER_IP:$REMOTE_ARCHIVE $LOCAL_ARCHIVE
    [[ -f "$LOCAL_ARCHIVE" ]] || { log_error "Failed to download archive"; exit 1; }
    log_info "Archive downloaded: $LOCAL_ARCHIVE"
}

extract_archive() {
    log_step "Extracting files..."
    tar -xzf "$LOCAL_ARCHIVE" -C "$LOCAL_REPO_PATH"
    log_info "Extraction complete"
}

cleanup_remote_archive() {
    sshpass -p "$SERVER_PASSWORD" ssh $SERVER_USER@$SERVER_IP "rm -f $(printf '%q' "$REMOTE_ARCHIVE")" || true
    log_info "Remote archive cleaned"
}

cleanup_local_archive() {
    rm -f "$LOCAL_ARCHIVE" || true
    log_info "Local archive cleaned"
}

commit_and_push() {
    log_step "Committing and pushing..."
    cd "$LOCAL_REPO_PATH"
    git add -A
    if git diff --quiet && git diff --staged --quiet; then
        log_warn "No changes to commit"
        return
    fi
    COMMIT_MSG="Sync Mautic code from production server ($(date +'%Y-%m-%d %H:%M:%S'))"
    git commit -m "$COMMIT_MSG"
    git push origin "$GIT_BRANCH"
    log_info "Changes committed and pushed to $GIT_BRANCH"
}

show_summary() {
    echo ""
    echo "=============================================="
    echo -e "${GREEN}Pull Complete!${NC}"
    echo "=============================================="
    echo "[INFO] Server: $SERVER_USER@$SERVER_IP"
    echo "[INFO] Remote path: $REMOTE_MAUTIC_PATH"
    echo "[INFO] Local repo: $LOCAL_REPO_PATH"
    echo "Directories synced: app/, plugins/, themes/, scripts/"
    echo "Excluded: media/, cache/, logs/, app/config/local.php, vendor/"
}

main() {
    check_prerequisites
    create_remote_archive
    download_archive
    extract_archive
    cleanup_remote_archive
    cleanup_local_archive
    commit_and_push
    show_summary
}

main "$@"
