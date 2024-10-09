#!/bin/bash

# Define log directory and directory where the atchived logs shoud store
LOG_DIR="/var/log/httpd"       # Directory where the logs are stored
ARCHIVE_DIR="/home/ec2-user/assignment/logs/archive"  # Directory where logs should archived
DAYS_TO_KEEP=30                 # Number of days to keep logs before deleting

# Log errors for find issues in the script
exec 2>/home/ec2-user/assignment/logs/rotation_error.log

# Create archive directory if it not exist
mkdir -p $ARCHIVE_DIR

# Archive logs older than 1 day
find $LOG_DIR -type f -name "*_log-*" -mtime +1 -exec gzip {} \;

# Move gzipped logs to the archive directory
find $LOG_DIR -type f -name "*.gz" -exec mv {} $ARCHIVE_DIR \;

# Delete archived logs older than 30 days
find $ARCHIVE_DIR -type f -name "*.gz" -mtime +$DAYS_TO_KEEP -exec rm -f {} \;

# Optional: Restart log-generating service
sudo systemctl restart httpd

echo "Log rotation completed successfully."
