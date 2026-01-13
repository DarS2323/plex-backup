# Plex Database Backup System

Automated weekly backup solution for your Plex Media Server database.

## Features

- **Automatic Weekly Backups**: Runs every Sunday at 3:00 AM
- **Safe Shutdown**: Properly stops Tautulli and Plex before backup
- **Watchdog Handling**: Stops Tautulli first to disable its built-in Plex watchdog
- **Automatic Restart**: Restarts both services after backup completes
- **Retention Management**: Automatically deletes backups older than 30 days
- **Detailed Logging**: All operations logged to backup.log

## Installation

1. Run the installation script:
   ```bash
   cd /Volumes/WD_BLACK_SN770_1TB/code_claude/PlexBackups
   ./install_plex_backup.sh
   ```

2. The script will:
   - Make the backup script executable
   - Create the backup directory
   - Install the launchd service
   - Schedule weekly backups

## Configuration

### Backup Settings

Edit `plex_backup.sh` to customize:

- **PLEX_DIR**: Location of Plex database (currently: `/Volumes/WD_BLACK_SN770_1TB/Plex Media Server`)
- **BACKUP_DIR**: Where backups are stored (currently: `/Volumes/media/backup/PlexBackups`)
- **RETENTION_DAYS**: How long to keep backups (currently: 30 days)

### Schedule

Edit `com.plex.backup.plist` to change the schedule:

- **Weekday**: 0=Sunday, 1=Monday, etc.
- **Hour**: 0-23 (24-hour format)
- **Minute**: 0-59

After editing, reload the service:
```bash
launchctl unload ~/Library/LaunchAgents/com.plex.backup.plist
launchctl load ~/Library/LaunchAgents/com.plex.backup.plist
```

## Manual Backup

To run a backup manually:
```bash
/Volumes/WD_BLACK_SN770_1TB/code_claude/PlexBackups/plex_backup.sh
```

## Monitoring

### Check Service Status
```bash
launchctl list | grep com.plex.backup
```

### View Backup Log
```bash
tail -f /Volumes/media/backup/PlexBackups/backup.log
```

### View LaunchD Logs
```bash
cat /Volumes/media/backup/PlexBackups/launchd.log
cat /Volumes/media/backup/PlexBackups/launchd_error.log
```

### List Backups
```bash
ls -lh /Volumes/media/backup/PlexBackups/plex_backup_*.tar.gz
```

## Backup Process

The script follows this sequence:

1. **Stop Tautulli** - Kills Tautulli process (disables watchdog)
2. **Stop Plex** - Uses AppleScript to quit Plex Media Server gracefully
3. **Wait for Shutdown** - Ensures both services are fully stopped
4. **Create Backup** - Compresses Plex directory to timestamped tar.gz file
5. **Restart Plex** - Opens Plex Media Server
6. **Restart Tautulli** - Opens Tautulli (re-enables watchdog)
7. **Cleanup Old Backups** - Removes backups older than retention period

## Restoring from Backup

1. Stop Tautulli and Plex Media Server:
   ```bash
   killall Tautulli
   osascript -e 'quit app "Plex Media Server"'
   ```

2. Navigate to the Plex directory parent:
   ```bash
   cd /Volumes/WD_BLACK_SN770_1TB/
   ```

3. Backup current database (optional but recommended):
   ```bash
   mv "Plex Media Server" "Plex Media Server.old"
   ```

4. Extract the backup:
   ```bash
   tar -xzf /Volumes/media/backup/PlexBackups/plex_backup_YYYYMMDD_HHMMSS.tar.gz
   ```

5. Restart services:
   ```bash
   open -a "Plex Media Server"
   open -a "Tautulli"
   ```

## Troubleshooting

### Backup doesn't run automatically
- Check if launchd service is loaded: `launchctl list | grep com.plex.backup`
- Check launchd error log: `cat /Volumes/media/backup/PlexBackups/launchd_error.log`
- Ensure the backup drive is mounted before scheduled time

### Services don't restart after backup
- Check the backup log for errors
- Manually restart: `open -a "Plex Media Server"` and `open -a "Tautulli"`
- Verify applications are in `/Applications` folder

### Backup drive not mounted
If `/Volumes/media` is not always mounted, you can add a check to the script:
```bash
if [ ! -d "/Volumes/media" ]; then
    log "ERROR: Backup drive not mounted"
    exit 1
fi
```

## Uninstallation

```bash
launchctl unload ~/Library/LaunchAgents/com.plex.backup.plist
rm ~/Library/LaunchAgents/com.plex.backup.plist
```

## Files

- `plex_backup.sh` - Main backup script
- `com.plex.backup.plist` - LaunchD configuration
- `install_plex_backup.sh` - Installation script
- `PLEX_BACKUP_README.md` - This file

## Notes

- Backups are compressed with gzip for space efficiency
- Each backup is timestamped (format: YYYYMMDD_HHMMSS)
- The script will wait up to 30 seconds for services to stop
- If services don't stop gracefully, they will be force-killed
- All operations are logged with timestamps
