#!/bin/bash

# Installation script for Plex Backup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="${SCRIPT_DIR}/plex_backup.sh"
PLIST_FILE="${SCRIPT_DIR}/com.plex.backup.plist"
PLIST_DEST="${HOME}/Library/LaunchAgents/com.plex.backup.plist"

echo "Installing Plex Backup Service..."
echo ""

# Step 1: Make backup script executable
echo "1. Making backup script executable..."
chmod +x "${BACKUP_SCRIPT}"

# Step 2: Create backup directory
echo "2. Creating backup directory..."
mkdir -p "/Volumes/media/backup/PlexBackups"

# Step 3: Copy plist to LaunchAgents
echo "3. Installing launch agent..."
mkdir -p "${HOME}/Library/LaunchAgents"
cp "${PLIST_FILE}" "${PLIST_DEST}"

# Step 4: Unload if already loaded (in case of reinstall)
echo "4. Checking for existing service..."
launchctl unload "${PLIST_DEST}" 2>/dev/null || true

# Step 5: Load the launch agent
echo "5. Loading launch agent..."
launchctl load "${PLIST_DEST}"

echo ""
echo "✓ Installation complete!"
echo ""
echo "Backup Details:"
echo "  - Schedule: Every Sunday at 3:00 AM"
echo "  - Backup Location: /Volumes/media/backup/PlexBackups"
echo "  - Retention: 30 days"
echo "  - Log File: /Volumes/media/backup/PlexBackups/backup.log"
echo ""
echo "To test the backup manually, run:"
echo "  ${BACKUP_SCRIPT}"
echo ""
echo "To check the service status:"
echo "  launchctl list | grep com.plex.backup"
echo ""
echo "To uninstall:"
echo "  launchctl unload ${PLIST_DEST}"
echo "  rm ${PLIST_DEST}"
echo ""
