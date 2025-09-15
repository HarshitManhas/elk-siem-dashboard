#!/bin/bash

echo " Starting Complete ELK SIEM with PC Log Collection!"
echo "=================================================="
echo ""

# Navigate to project directory
cd /home/harshit-manhas/elk-siem-dashboard

# Check if stack is already running
if docker-compose ps | grep -q "Up"; then
    echo "ℹ  ELK Stack is already running!"
    echo ""
docker-compose
    echo ""
else
    echo "🚀 Starting ELK Stack with complete log collection..."
    docker-compose up -d
    
    echo "⏳ Waiting for services to start..."
    sleep 60
fi

# Display current status
echo " Service Status:"
docker-compose ps

echo ""
echo "🔍 Health Checks:"
ES_STATUS=$(curl -s http://localhost:9200/_cluster/health 2>/dev/null | grep -o '"status":"[^"]*' | cut -d'"' -f4)
KB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5601/api/status 2>/dev/null)

echo "   • Elasticsearch: $ES_STATUS"
echo "   • Kibana:        HTTP $KB_STATUS"

# Check log collection
echo ""
echo " Log Collection Status:"
LOG_COUNT=$(curl -s "localhost:9200/siem-logs-*/_count" 2>/dev/null | grep -o '"count":[0-9]*' | cut -d':' -f2)
if [ ! -z "$LOG_COUNT" ]; then
    echo "   • Total Logs:    $LOG_COUNT events indexed"
    
    # Show recent logs
    echo ""
    echo "🔍 Recent Log Types:"
    curl -s -X GET "localhost:9200/siem-logs-*/_search" \
      -H 'Content-Type: application/json' \
      -d '{
        "size": 0,
        "aggs": {
          "log_types": {
            "terms": {
              "field": "log_type.keyword",
              "size": 10
            }
          },
          "log_sources": {
            "terms": {
              "field": "tags.keyword",
              "size": 10
            }
          }
        }
      }' 2>/dev/null | jq -r '
        .aggregations.log_types.buckets[] | 
        "   • " + .key + ": " + (.doc_count | tostring) + " events"
      ' 2>/dev/null || echo "   • Log analysis in progress..."
    
else
    echo "   • Log collection starting up..."
fi

echo ""
echo " Access Points:"
echo "   • Kibana Dashboard: http://localhost:5601"
echo "   • Elasticsearch:    http://localhost:9200"
echo "   • Log Ingestion:    localhost:5044 (Filebeat) & localhost:5000 (Syslog)"

echo ""
echo "  SIEM Features Now Active:"
echo "    Real-time log collection from your PC"
echo "    Authentication log monitoring"
echo "    System log analysis"
echo "    Kernel security events"
echo "    Application log tracking"
echo "    Kibana dashboards and visualizations"
echo "    Search and filtering capabilities"
echo "    Alert correlation and analysis"

echo ""
echo " Next Steps:"
echo "   1. Open http://localhost:5601 in your browser"
echo "   2. Go to Stack Management > Index Patterns"
echo "   3. Create pattern: 'siem-logs-*'"
echo "   4. Set time field: '@timestamp'"
echo "   5. Go to Discover to explore your PC's logs"
echo "   6. Create security dashboards in Dashboard section"

echo ""
echo " Management Commands:"
echo "   • View logs:  docker-compose logs [service]"
echo "   • Stop SIEM:  docker-compose down"
echo "   • Restart:    docker-compose restart [service]"

echo ""
echo " Your complete ELK SIEM is monitoring your PC in real-time!"