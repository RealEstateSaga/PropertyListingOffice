# PropertyListingOffice

A Mautic-based marketing automation platform for PropertyListingOffice.com.

## Project Structure

```
├── app/                    # Main application directory
│   └── config/             # Configuration files
│       └── local.php.example  # Example local configuration
├── plugins/                # Custom plugins
├── themes/                 # Custom themes
├── scripts/                # Utility scripts
│   └── sync-from-server.sh # Server sync script
├── .rsync-exclude          # Exclusion patterns for sync
└── .github/workflows/      # CI/CD workflows
```

## Getting Started

1. Clone this repository
2. Copy `app/config/local.php.example` to `app/config/local.php`
3. Update `local.php` with your credentials
4. Run `composer install` to install dependencies

## Configuration

Copy the example configuration file and update with your credentials:

```bash
cp app/config/local.php.example app/config/local.php
```

Never commit `local.php` to version control as it contains sensitive credentials.

## Syncing from Live Server

This repository is configured to sync operational Mautic code from a live server while excluding sensitive and unnecessary files.

### What Gets Synced

- `app/` - Main application directory (excluding local.php)
- `plugins/` - Custom plugins
- `themes/` - Custom themes  
- `scripts/` - Custom utility scripts

### What Gets Excluded

- `media/` - User uploads and media files
- `cache/` - Runtime cache files
- `logs/` - Log files
- `local.php` - Server-specific configuration with credentials
- `vendor/` - Composer dependencies (reinstall with `composer install`)

### Running a Sync

1. Set the required environment variables:

```bash
export MAUTIC_SERVER_HOST="user@your-server.com"
export MAUTIC_SERVER_PATH="/var/www/mautic"  # Optional, defaults to /var/www/mautic
export MAUTIC_SSH_KEY="/path/to/ssh/key"     # Optional, if using non-default key
```

2. Run a dry-run first to see what would be synced:

```bash
./scripts/sync-from-server.sh --dry-run
```

3. Execute the actual sync:

```bash
./scripts/sync-from-server.sh
```

4. Review, commit, and push the changes:

```bash
git status
git add -A
git commit -m "Sync Mautic code from production server"
git push origin main
```

### Prerequisites

- SSH key configured for passwordless access to the server
- `rsync` installed on both local and remote systems
- Read permissions for the Mautic directories on the server

## Build

The project includes a GitHub Actions workflow that:
- Installs PHP dependencies via Composer
- Clears the cache
- Verifies the folder structure

## Development Workflow

1. Sync latest code from production server
2. Create a feature branch
3. Make changes locally
4. Test changes
5. Create a pull request
6. Deploy to production server
7. Sync changes back to repository to keep it up-to-date
