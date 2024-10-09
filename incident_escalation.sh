#!/bin/bash

# Grafana server details
GRAFANA_URL="http://<your-grafana-server>/api/alerts"
API_KEY="Bearer <your-grafana-api-key>"

# Thresholds for escalation based on alert severity
HIGH_SEVERITY_THRESHOLD=3600     # 1 hour for high severity incidents
MEDIUM_SEVERITY_THRESHOLD=14400  # 4 hours for medium severity incidents
LOW_SEVERITY_THRESHOLD=28800     # 8 hours for low severity incidents

# Log file to track escalations
ESCALATION_LOG="escalation_log.txt"

# Get current timestamp
CURRENT_TIME=$(date +%s)

# Fetch alerts from Grafana API
response=$(curl -s -H "Authorization: $API_KEY" "$GRAFANA_URL")

# Process the response to extract relevant data
# Assume response is in JSON format containing "id", "state", "newStateDate", "severity"
alerts=$(echo "$response" | jq -c '.[]')

# Define the escalation logic based on severity and time
escalate_incident() {
  local alert_id=$1
  local severity=$2
  local logged_time=$3
  local elapsed_time=$((CURRENT_TIME - logged_time))

  case $severity in
    "critical")
      if [ $elapsed_time -ge $HIGH_SEVERITY_THRESHOLD ]; then
        echo "Alert ID: $alert_id is high severity and has exceeded the escalation threshold. Escalating now."
        echo "$(date) - Alert ID: $alert_id (Severity: $severity) has been escalated." >> $ESCALATION_LOG
        # You can add an email or SMS alert here
      fi
      ;;
    "warning")
      if [ $elapsed_time -ge $MEDIUM_SEVERITY_THRESHOLD ]; then
        echo "Alert ID: $alert_id is medium severity and has exceeded the escalation threshold. Escalating now."
        echo "$(date) - Alert ID: $alert_id (Severity: $severity) has been escalated." >> $ESCALATION_LOG
        # Add an email or SMS alert here
      fi
      ;;
    "info")
      if [ $elapsed_time -ge $LOW_SEVERITY_THRESHOLD ]; then
        echo "Alert ID: $alert_id is low severity and has exceeded the escalation threshold. Escalating now."
        echo "$(date) - Alert ID: $alert_id (Severity: $severity) has been escalated." >> $ESCALATION_LOG
        # Add an email or SMS alert here
      fi
      ;;
  esac
}

# Iterate over the alerts and apply escalation logic
for alert in $alerts; do
  alert_id=$(echo $alert | jq -r '.id')
  severity=$(echo $alert | jq -r '.severity')  # Assume "critical", "warning", or "info"
  logged_time=$(date -d "$(echo $alert | jq -r '.newStateDate')" +%s)

  escalate_incident "$alert_id" "$severity" "$logged_time"
done
