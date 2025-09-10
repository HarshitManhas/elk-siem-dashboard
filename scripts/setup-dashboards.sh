#!/bin/bash

# Script to set up Kibana dashboards and visualizations for SIEM

KIBANA_URL="http://localhost:5601"
ELASTICSEARCH_URL="http://localhost:9200"

echo "Setting up SIEM Dashboard in Kibana..."

# Wait for Kibana to be ready
echo "Waiting for Kibana to start..."
while ! curl -s "$KIBANA_URL/api/status" > /dev/null; do
    echo "Waiting for Kibana..."
    sleep 5
done

echo "Kibana is ready!"

# Create index pattern
echo "Creating index pattern..."
curl -X POST "$KIBANA_URL/api/saved_objects/index-pattern/siem-logs-*" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "siem-logs-*",
      "timeFieldName": "@timestamp"
    }
  }'

# Import dashboard
echo "Importing dashboard..."
curl -X POST "$KIBANA_URL/api/saved_objects/_import" \
  -H "kbn-xsrf: true" \
  -F file=@../dashboards/siem-dashboard.ndjson

echo "Dashboard setup complete!"
echo "Access your SIEM dashboard at: $KIBANA_URL"
