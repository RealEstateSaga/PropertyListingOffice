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

## Build

The project includes a GitHub Actions workflow that:
- Installs PHP dependencies via Composer
- Clears the cache
- Verifies the folder structure
