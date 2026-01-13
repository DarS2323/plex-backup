#!/bin/bash

# Plex Database Backup Script
# Backs up Plex Media Server database with proper shutdown/startup sequence

set -e

# Configuration
PLEX_DIR="/Volumes/WD_BLACK_SN770_1TB/Plex Media Server"
BACKUP_DIR="/Volumes/media/backup/PlexBackups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_NAME="plex_backup_${TIMESTAMP}.tar.gz"
LOG_FILE="${BACKUP_DIR}/backup.log"
RETENTION_DAYS=30

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Function to check if a process is running
is_running() {
    pgrep -x "$1" > /dev/null 2>&1
}

# Function to wait for process to stop
wait_for_stop() {
    local process_name=$1
    local max_wait=30
    local count=0

    while is_running "$process_name" && [ $count -lt $max_wait ]; do
        sleep 1
        count=$((count + 1))
    done

    if is_running "$process_name"; then
        log "WARNING: $process_name did not stop after ${max_wait} seconds"
        return 1
    fi
    return 0
}

log "========== Starting Plex Backup =========="

# Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# Step 1: Stop Tautulli (this also stops the watchdog)
log "Stopping Tautulli..."
if is_running "Tautulli"; then
    killall Tautulli 2>/dev/null || true
    if wait_for_stop "Tautulli"; then
        log "Tautulli stopped successfully"
    else
        log "ERROR: Failed to stop Tautulli"
        exit 1
    fi
else
    log "Tautulli is not running"
fi

# Step 2: Stop Plex Media Server using AppleScript
log "Stopping Plex Media Server..."
if is_running "Plex Media Server"; then
    osascript -e 'quit app "Plex Media Server"' 2>/dev/null || true
    if wait_for_stop "Plex Media Server"; then
        log "Plex Media Server stopped successfully"
    else
        log "WARNING: Plex Media Server did not stop gracefully, forcing quit..."
        killall "Plex Media Server" 2>/dev/null || true
        sleep 5
    fi
else
    log "Plex Media Server is not running"
fi

# Step 3: Verify both services are stopped
sleep 3
if is_running "Plex Media Server" || is_running "Tautulli"; then
    log "ERROR: Services still running, aborting backup"
    exit 1
fi

# Step 4: Perform the backup
log "Creating backup: ${BACKUP_NAME}"
if [ -d "${PLEX_DIR}" ]; then
    cd "$(dirname "${PLEX_DIR}")"
    tar -czf "${BACKUP_DIR}/${BACKUP_NAME}" "$(basename "${PLEX_DIR}")" 2>&1 | tee -a "${LOG_FILE}"

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}" | cut -f1)
        log "Backup completed successfully: ${BACKUP_NAME} (${BACKUP_SIZE})"
    else
        log "ERROR: Backup failed"
        # Still try to restart services
    fi
else
    log "ERROR: Plex directory not found: ${PLEX_DIR}"
fi

# Step 5: Restart Plex Media Server
log "Starting Plex Media Server..."
open -a "Plex Media Server"
sleep 10

if is_running "Plex Media Server"; then
    log "Plex Media Server started successfully"
else
    log "WARNING: Plex Media Server may not have started"
fi

# Step 6: Restart Tautulli
log "Starting Tautulli..."
open -a "Tautulli"
sleep 5

if is_running "Tautulli"; then
    log "Tautulli started successfully"
else
    log "WARNING: Tautulli may not have started"
fi

# Step 7: Clean up old backups
log "Cleaning up backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "plex_backup_*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete 2>&1 | tee -a "${LOG_FILE}"

log "========== Backup Complete =========="
log ""
