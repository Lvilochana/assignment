#!/bin/bash

# Define log directory and rotation settings
LOG_DIR="/var/log/httpd"       # Directory where your logs are stored
ARCHIVE_DIR="/home/ec2-user/assignment/logs/archive"  # Directory where logs will be archived
DAYS_TO_KEEP=30                 # Number of days to keep logs before deleting

# Create archive directory if it doesn't exist
mkdir -p $ARCHIVE_DIR

# Archive logs older than 1 day (compressing them into .gz files)
find $LOG_DIR -type f -name "*.log" -mtime +7 -exec gzip {} \;
find $LOG_DIR -type f -name "*.log.gz" -mtime +7 -exec mv {} $ARCHIVE_DIR \;

# Delete archived logs older than $DAYS_TO_KEEP days
find $ARCHIVE_DIR -type f -name "*.log.gz" -mtime +$DAYS_TO_KEEP -exec rm -f {} \;

# Optional: Rotate current logs by renaming (e.g., app.log -> app.log.1)
for logfile in $LOG_DIR/*.log; do
    mv "$logfile" "${logfile}.1"
done

# Optional: Restart log-generating service if needed (replace with your service)
# service myapp restart

echo "Log rotation completed successfully."
