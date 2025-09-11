# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is an ELK Stack-based SIEM (Security Information and Event Management) dashboard for real-time security monitoring, threat detection, and incident response. The system uses Docker containers to deploy Elasticsearch, Logstash, Kibana, Filebeat, and ElastAlert for comprehensive security log analysis.

## Architecture

The system follows a classic ELK pipeline architecture:

1. **Data Collection Layer**: Filebeat collects logs from various sources
2. **Processing Layer**: Logstash parses, enriches, and transforms security logs
3. **Storage Layer**: Elasticsearch stores processed security events with time-series indexing
4. **Visualization Layer**: Kibana provides dashboards and search capabilities
5. **Alerting Layer**: ElastAlert monitors for security threats and sends notifications

Key data flow: `Log Sources → Filebeat → Logstash → Elasticsearch ← Kibana`

## Essential Commands

### Starting the SIEM System
```bash
# Complete startup with health checks
./scripts/start-siem.sh

# Quick start all services
docker-compose up -d

# Start specific services
docker-compose up -d elasticsearch kibana
```

### Service Management
```bash
# Check service status
docker-compose ps

# View service logs
docker-compose logs elasticsearch
docker-compose logs logstash
docker-compose logs kibana
docker-compose logs filebeat
docker-compose logs elastalert

# Restart services
docker-compose restart logstash
docker-compose restart

# Stop all services
docker-compose down
```

### Dashboard Setup
```bash
# Setup Kibana dashboards and index patterns
./scripts/setup-dashboards.sh

# Manual dashboard import
curl -X POST "localhost:5601/api/saved_objects/_import" \
  -H "kbn-xsrf: true" \
  -F file=@dashboards/siem-dashboard.ndjson
```

### Health Checks and Troubleshooting
```bash
# Check Elasticsearch cluster health
curl -X GET "localhost:9200/_cluster/health?pretty"

# List all Elasticsearch indices
curl -X GET "localhost:9200/_cat/indices?v"

# Check Logstash pipeline status
curl -X GET "localhost:9600/_node/stats/pipelines?pretty"

# Verify Kibana API status
curl -X GET "localhost:5601/api/status"

# Test Elasticsearch connectivity
curl -X GET "localhost:9200/"
```

### Configuration Management
```bash
# Reload Logstash configuration (auto-reload enabled)
# Changes to configs/logstash/pipeline/*.conf are picked up automatically

# Restart individual services after config changes
docker-compose restart logstash
docker-compose restart filebeat
docker-compose restart elastalert
```

## Core Components and Configuration

### Logstash Pipeline (`configs/logstash/pipeline/siem-pipeline.conf`)
- **Input Sources**: Beats (port 5044), Syslog (port 5000), TCP (port 5001), File inputs
- **Log Types Parsed**: Firewall, Authentication, IDS/IPS, Web Access logs
- **Enrichment**: GeoIP mapping, threat detection, field normalization
- **Output**: Elasticsearch with daily indices (`siem-logs-YYYY.MM.dd`)

Key parsing patterns:
- Firewall logs: Extract src_ip, dst_ip, action, protocol
- Auth logs: Parse user, auth_result, service, detect failed logins  
- IDS logs: Extract severity, alert_msg, threat indicators
- Web logs: Combined Apache format with SQL injection detection

### ElastAlert Configuration (`alerting/`)
- **Main Config**: `elastalert.yml` - runs every minute, 15-minute buffer
- **Alert Rules**: 
  - `failed_logins.yml`: 5+ failed attempts in 5 minutes
  - `high_severity_threats.yml`: Critical IDS alerts
  - `blacklisted_ips.yml`: Traffic from known malicious IPs
- **Channels**: Email, debug logging, webhook support

### Data Model
Security events are indexed with these key fields:
- `@timestamp`: Event timestamp
- `log_type`: firewall, authentication, ids, web_access
- `event_category`: network, authentication, intrusion_detection, web
- `src_ip`, `dst_ip`: Source and destination IP addresses
- `severity`: low, medium, high, critical
- `security_alert`: failed_login, high_severity_threat, potential_sql_injection
- `src_geoip.*`: Geographic enrichment data

## Service Endpoints

- **Kibana Dashboard**: http://localhost:5601
- **Elasticsearch API**: http://localhost:9200  
- **Logstash Monitoring**: http://localhost:9600
- **Filebeat**: Internal service, no web interface
- **ElastAlert**: Internal service, logs to container output

## Development Workflow

### Adding New Log Sources
1. Update `configs/filebeat/filebeat.yml` with new log file paths
2. Add parsing rules to `configs/logstash/pipeline/siem-pipeline.conf`
3. Define field mappings in the Elasticsearch template
4. Restart services: `docker-compose restart filebeat logstash`
5. Test parsing with sample data

### Creating Custom Alerts
1. Create new rule file in `alerting/rules/`
2. Follow ElastAlert rule format with appropriate filters
3. Configure notification channels (email, webhook)
4. Restart ElastAlert: `docker-compose restart elastalert`
5. Monitor `docker-compose logs elastalert` for rule execution

### Dashboard Modifications
1. Create visualizations in Kibana UI (http://localhost:5601)
2. Export dashboard: Settings → Saved Objects → Export
3. Update `dashboards/siem-dashboard.ndjson`
4. Test import with `./scripts/setup-dashboards.sh`

## Directory Structure Context

```
configs/          # All service configurations
├── elasticsearch/   # ES cluster settings
├── logstash/       # Pipeline definitions and parsing rules
├── kibana/         # Dashboard and UI settings  
├── filebeat/       # Log collection configuration
alerting/         # ElastAlert rules and notifications
├── elastalert.yml  # Main alerting configuration
├── rules/          # Individual alert rule definitions
dashboards/       # Kibana dashboard exports
scripts/          # Automation and setup scripts
data/            # Persistent data storage (auto-created)
logs/sample-data/ # Sample security logs for testing
```

## Performance and Scaling Notes

- Default JVM heap: Elasticsearch (1GB), Logstash (1GB)
- Pipeline workers: 2 (configurable in `logstash.yml`)
- Index strategy: Daily indices with 0 replicas for single-node setup
- Buffer settings: 1000 events per batch, 50ms delay
- Auto-reload: Configuration changes picked up within 3 seconds

## Security Considerations

The current configuration is designed for development/demonstration:
- Security features disabled (`xpack.security.enabled: false`)
- No SSL/TLS encryption
- Default ports exposed

For production deployment, enable:
- Elasticsearch security and authentication
- SSL/TLS encryption for all communications
- Network isolation and firewall rules
- Secure alert notification channels
