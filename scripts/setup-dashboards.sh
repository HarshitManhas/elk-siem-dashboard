#!/bin/bash

# Script to set up Kibana dashboards and visualizations for SIEM

KIBANA_URL="http://localhost:5601"
ELASTICSEARCH_URL="http://localhost:9200"

echo "Setting up SIEM Dashboard in Kibana..."

# Fix Elasticsearch cluster health for single-node
echo "Configuring Elasticsearch for single-node cluster..."
curl -X PUT "$ELASTICSEARCH_URL/_index_template/siem-template" \
  -H 'Content-Type: application/json' \
  -d '{"index_patterns":["siem-logs-*",".kibana*"],"template":{"settings":{"number_of_replicas":0}}}' \
  -s > /dev/null

# Wait for Elasticsearch to be healthy
echo "Waiting for Elasticsearch to be ready..."
while true; do
    status=$(curl -s "$ELASTICSEARCH_URL/_cluster/health" | grep -o '"status":"[^"]*' | cut -d'"' -f4)
    if [[ "$status" == "yellow" || "$status" == "green" ]]; then
        echo "Elasticsearch is ready (status: $status)!"
        break
    fi
    echo "Elasticsearch status: $status - waiting..."
    sleep 10
done

# Wait for Kibana to be ready
echo "Waiting for Kibana to start..."
retries=0
max_retries=20
while [ $retries -lt $max_retries ]; do
    if curl -s "$KIBANA_URL/api/status" | grep -q '"level":"available"'; then
        echo "Kibana is ready!"
        break
    fi
    echo "Waiting for Kibana... (attempt $((retries+1))/$max_retries)"
    sleep 15
    retries=$((retries+1))
done

if [ $retries -eq $max_retries ]; then
    echo "Timeout waiting for Kibana to be ready. You may need to set up dashboards manually."
    echo "Access Kibana at: $KIBANA_URL"
    exit 1
fi

# Create index pattern
echo "Creating index pattern..."
response=$(curl -s -X POST "$KIBANA_URL/api/saved_objects/index-pattern/siem-logs-pattern" \
  -H "Content-Type: application/json" \
  -H "kbn-xsrf: true" \
  -d '{
    "attributes": {
      "title": "siem-logs-*",
      "timeFieldName": "@timestamp"
    }
  }')

if echo "$response" | grep -q '"id"'; then
    echo "Index pattern created successfully!"
else
    echo "Index pattern creation failed or already exists: $response"
fi

# Import dashboard if it exists
if [ -f "dashboards/siem-dashboard.ndjson" ]; then
    echo "Importing dashboard..."
    response=$(curl -s -X POST "$KIBANA_URL/api/saved_objects/_import" \
      -H "kbn-xsrf: true" \
      -H "Content-Type: application/json" \
      --data-binary @dashboards/siem-dashboard.ndjson)
    
    if echo "$response" | grep -q '"success":true'; then
        echo "Dashboard imported successfully!"
    else
        echo "Dashboard import failed: $response"
        echo "You can manually import the dashboard from dashboards/siem-dashboard.ndjson"
    fi
else
    echo "Dashboard file not found, skipping import."
fi

echo "Dashboard setup complete!"
echo "Access your SIEM dashboard at: $KIBANA_URL"
echo "Create some sample logs: logger 'Test SIEM log entry'"
