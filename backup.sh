#!/bin/bash

# Configuration
backup_dir="/path/to/backup/directory"    # Directory to store backups
source_dir="/path/to/source/directory"    # Directory to be backed up
encryption_key="your_encryption_key"      # Encryption key for securing backups
remote_server="username@remote_server:/path/to/remote/backup/directory"  # Remote server details

# Function to log messages
log() {
    local log_message="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $log_message" >> "$backup_dir/backup.log"
}

# Check if backup directory exists, create if not
if [ ! -d "$backup_dir" ]; then
    mkdir -p "$backup_dir"
    log "Backup directory created: $backup_dir"
fi

# Perform incremental backup
if [ -f "$backup_dir/last_backup.txt" ]; then
    last_backup="$(cat "$backup_dir/last_backup.txt")"
    backup_name="incremental_backup_$(date +'%Y%m%d_%H%M%S').tar.gz"
    rsync -a --link-dest="$backup_dir/$last_backup" "$source_dir" "$backup_dir/$backup_name" && \
    echo "$backup_name" > "$backup_dir/last_backup.txt"
else
    backup_name="full_backup_$(date +'%Y%m%d_%H%M%S').tar.gz"
    rsync -a "$source_dir" "$backup_dir/$backup_name" && \
    echo "$backup_name" > "$backup_dir/last_backup.txt"
fi

# Check if backup was successful
if [ $? -eq 0 ]; then
    log "Backup successful: $backup_name"
else
    log "Backup failed: $backup_name"
    exit 1
fi

# Encrypt backup file
openssl enc -aes-256-cbc -salt -in "$backup_dir/$backup_name" -out "$backup_dir/$backup_name.enc" -k "$encryption_key"
if [ $? -eq 0 ]; then
    log "Encryption successful: $backup_name.enc"
    rm "$backup_dir/$backup_name"  # Remove unencrypted backup after encryption
else
    log "Encryption failed: $backup_name"
    exit 1
fi

# Copy encrypted backup to remote server
scp "$backup_dir/$backup_name.enc" "$remote_server"
if [ $? -eq 0 ]; then
    log "Backup copied to remote server: $backup_name.enc"
else
    log "Failed to copy backup to remote server: $backup_name.enc"
    exit 1
fi
