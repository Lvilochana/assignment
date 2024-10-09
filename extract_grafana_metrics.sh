#!/bin/bash

# Configuration
LOG_DIR="/var/log/grafana"   # Grafana logs stored location
OUTPUT_DIR="/home/ec2-user/assignment/logs/grafana_metrics_logs"  # structured logs should stored location
FORMAT="json"  # want output format
OUTPUT_FILE="$OUTPUT_DIR/system_metrics_summary_$(date +%Y-%m-%d).$FORMAT"  # File to store the summary

# Create output directory if it not exist
mkdir -p "$OUTPUT_DIR"

# Initialize variables for performance metrics
total_cpu=0
total_memory=0
total_disk_io=0
log_count=0

# process log files in the Grafana log directory
for log_file in "$LOG_DIR"/*.log; do
    while read -r line; do
        # Extract performance metrics from the log file 
        # Modify jq selectors based on actual Grafana log structure
        cpu_usage=$(echo "$line" | jq '.cpu_usage' 2>/dev/null)
        memory_usage=$(echo "$line" | jq '.memory_usage' 2>/dev/null)
        disk_io=$(echo "$line" | jq '.disk_io' 2>/dev/null)

        # Skip logs with missing or empty values
        if [[ -n $cpu_usage && -n $memory_usage && -n $disk_io ]]; then
            # gettin total values
            total_cpu=$(echo "$total_cpu + $cpu_usage" | bc)
            total_memory=$(echo "$total_memory + $memory_usage" | bc)
            total_disk_io=$(echo "$total_disk_io + $disk_io" | bc)

            # Increment log count
            log_count=$((log_count + 1))
        fi
    done < "$log_file"
done

# Calculate average metrics 
if [[ $log_count -gt 0 ]]; then
    avg_cpu=$(echo "scale=2; $total_cpu / $log_count" | bc)
    avg_memory=$(echo "scale=2; $total_memory / $log_count" | bc)
    avg_disk_io=$(echo "scale=2; $total_disk_io / $log_count" | bc)
else
    avg_cpu=0
    avg_memory=0
    avg_disk_io=0
fi

# Log metrics in JSON format
if [[ "$FORMAT" == "json" ]]; then
    echo "{
  \"timestamp\": \"$(date)\",
  \"average_cpu_usage\": $avg_cpu,
  \"average_memory_usage\": $avg_memory,
  \"average_disk_io\": $avg_disk_io,
  \"logs_processed\": $log_count
}" > "$OUTPUT_FILE"

# Log metrics in CSV format
#elif [[ "$FORMAT" == "csv" ]]; then
#   # Add CSV header if file doesn't exist
#   if [[ ! -f "$OUTPUT_FILE" ]]; then
#       echo "timestamp,average_cpu_usage,average_memory_usage,average_disk_io,logs_processed" > "$OUTPUT_FILE"
#   fi
#   echo "$(date),$avg_cpu,$avg_memory,$avg_disk_io,$log_count" >> "$OUTPUT_FILE"
fi

# Output a success message
echo "Summary of system metrics logged in $FORMAT format at $OUTPUT_FILE"