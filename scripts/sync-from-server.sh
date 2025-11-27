#!/bin/bash
# =============================================================================
# Mautic Server Sync Script
# =============================================================================
# This script syncs operational Mautic code from the live server to this
# repository. It excludes media/, cache/, logs/, and local.php as specified.
#
# Prerequisites:
#   - SSH key configured for passwordless access to the server
#   - rsync installed on both local and remote systems
#   - Proper permissions to read from the server directories
#
# Usage:
#   ./scripts/sync-from-server.sh [options]
#
# Options:
#   -n, --dry-run    Show what would be transferred without making changes
#   -v, --verbose    Increase verbosity
#   -h, --help       Show this help message
#
# Environment Variables:
#   MAUTIC_SERVER_HOST    - SSH host (e.g., user@server.example.com)
#   MAUTIC_SERVER_PATH    - Path to Mautic installation on server
#                           (default: /var/www/mautic)
#   MAUTIC_SSH_KEY        - Path to SSH key (optional)
#
# Example:
#   MAUTIC_SERVER_HOST=deploy@mautic.example.com \
#   MAUTIC_SERVER_PATH=/var/www/mautic \
#   ./scripts/sync-from-server.sh --dry-run
#
# =============================================================================

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Configuration with defaults
MAUTIC_SERVER_HOST="${MAUTIC_SERVER_HOST:-}"
MAUTIC_SERVER_PATH="${MAUTIC_SERVER_PATH:-/var/www/mautic}"
MAUTIC_SSH_KEY="${MAUTIC_SSH_KEY:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default options
DRY_RUN=""
VERBOSE=""

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    head -50 "$0" | grep -E "^#" | sed 's/^# \?//'
    exit 0
}

check_prerequisites() {
    # Check for rsync
    if ! command -v rsync &> /dev/null; then
        log_error "rsync is required but not installed."
        exit 1
    fi

    # Check for ssh
    if ! command -v ssh &> /dev/null; then
        log_error "ssh is required but not installed."
        exit 1
    fi

    # Check server host is set
    if [[ -z "$MAUTIC_SERVER_HOST" ]]; then
        log_error "MAUTIC_SERVER_HOST environment variable is not set."
        log_error "Please set it to your server SSH address (e.g., user@server.example.com)"
        exit 1
    fi

    # Check exclude file exists
    if [[ ! -f "${REPO_ROOT}/.rsync-exclude" ]]; then
        log_error "Exclude file not found: ${REPO_ROOT}/.rsync-exclude"
        exit 1
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -n|--dry-run)
                DRY_RUN="--dry-run"
                shift
                ;;
            -v|--verbose)
                VERBOSE="-v"
                shift
                ;;
            -h|--help)
                show_help
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                ;;
        esac
    done
}

build_ssh_options() {
    local ssh_opts=""
    if [[ -n "$MAUTIC_SSH_KEY" ]]; then
        ssh_opts="-i ${MAUTIC_SSH_KEY}"
    fi
    echo "$ssh_opts"
}

sync_directory() {
    local src_dir="$1"
    local dest_dir="$2"
    local description="$3"

    log_info "Syncing ${description}..."

    local ssh_opts
    ssh_opts=$(build_ssh_options)

    local rsync_opts="-avz --delete --exclude-from=${REPO_ROOT}/.rsync-exclude"
    if [[ -n "$DRY_RUN" ]]; then
        rsync_opts="${rsync_opts} ${DRY_RUN}"
    fi
    if [[ -n "$VERBOSE" ]]; then
        rsync_opts="${rsync_opts} ${VERBOSE}"
    fi

    # Build SSH command for rsync
    local rsh_opt=""
    if [[ -n "$ssh_opts" ]]; then
        rsh_opt="-e \"ssh ${ssh_opts}\""
    fi

    # Ensure destination exists
    mkdir -p "${dest_dir}"

    # Execute rsync
    if [[ -n "$rsh_opt" ]]; then
        eval rsync ${rsync_opts} ${rsh_opt} "${MAUTIC_SERVER_HOST}:${src_dir}/" "${dest_dir}/"
    else
        rsync ${rsync_opts} "${MAUTIC_SERVER_HOST}:${src_dir}/" "${dest_dir}/"
    fi

    log_info "Completed syncing ${description}"
}

main() {
    parse_args "$@"

    echo "=============================================="
    echo "  Mautic Server Sync"
    echo "=============================================="
    echo ""

    if [[ -n "$DRY_RUN" ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
        echo ""
    fi

    check_prerequisites

    log_info "Server: ${MAUTIC_SERVER_HOST}"
    log_info "Remote path: ${MAUTIC_SERVER_PATH}"
    log_info "Local repository: ${REPO_ROOT}"
    echo ""

    # Sync app/ directory
    sync_directory "${MAUTIC_SERVER_PATH}/app" "${REPO_ROOT}/app" "app/ directory"

    # Sync plugins/ directory
    sync_directory "${MAUTIC_SERVER_PATH}/plugins" "${REPO_ROOT}/plugins" "plugins/ directory"

    # Sync themes/ directory
    sync_directory "${MAUTIC_SERVER_PATH}/themes" "${REPO_ROOT}/themes" "themes/ directory"

    # Sync custom scripts if they exist on server
    log_info "Checking for custom scripts on server..."
    if ssh ${ssh_opts:-} "${MAUTIC_SERVER_HOST}" "test -d ${MAUTIC_SERVER_PATH}/scripts" 2>/dev/null; then
        sync_directory "${MAUTIC_SERVER_PATH}/scripts" "${REPO_ROOT}/scripts" "scripts/ directory"
    else
        log_info "No scripts/ directory found on server, skipping..."
    fi

    echo ""
    echo "=============================================="
    log_info "Sync completed successfully!"
    echo "=============================================="
    echo ""

    if [[ -z "$DRY_RUN" ]]; then
        log_info "Next steps:"
        echo "  1. Review the changes with: git status"
        echo "  2. Stage changes: git add -A"
        echo "  3. Commit: git commit -m 'Sync Mautic code from production server'"
        echo "  4. Push: git push origin main"
    fi
}

main "$@"
