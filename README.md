# ELK Stack SIEM Dashboard

A comprehensive Security Information and Event Management (SIEM) solution built with the ELK Stack (Elasticsearch, Logstash, Kibana) for real-time security monitoring, threat detection, and incident response.

## 🚀 Features

- **Real-time Log Collection**: Collect security logs from multiple sources (firewalls, IDS, servers, applications)
- **Advanced Parsing**: Intelligent log parsing with Grok patterns and field normalization
- **GeoIP Enrichment**: Geographic location mapping of IP addresses
- **Interactive Dashboards**: Pre-built Kibana visualizations for security monitoring
- **Automated Alerting**: Real-time alerts for security threats and anomalies
- **Threat Detection**: Built-in rules for common attack patterns
- **Scalable Architecture**: Docker-based deployment for easy scaling

## 📋 Prerequisites

- Docker and Docker Compose installed
- At least 4GB of available RAM
- 20GB of available disk space
- Basic knowledge of security logs and SIEM concepts

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Log Sources   │───▶│    Filebeat     │───▶│    Logstash     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
┌─────────────────┐    ┌─────────────────┐              │
│   ElastAlert    │◀───│ Elasticsearch   │◀─────────────┘
└─────────────────┘    └─────────────────┘
                                │
                       ┌─────────────────┐
                       │     Kibana      │
                       └─────────────────┘
```

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd elk-siem-dashboard
```

### 2. Start the ELK Stack

```bash
# Start all services
docker-compose up -d

# Check service status
docker-compose ps
```

### 3. Verify Services

- **Elasticsearch**: http://localhost:9200
- **Kibana**: http://localhost:5601
- **Logstash**: http://localhost:9600

### 4. Setup Dashboards

```bash
# Wait for services to be ready (2-3 minutes)
# Then setup Kibana dashboards
./scripts/setup-dashboards.sh
```

### 5. View Your SIEM Dashboard

Navigate to http://localhost:5601 and explore your security data!

## 📊 Dashboards and Visualizations

### Pre-built Dashboards

1. **Security Overview**: High-level security metrics and KPIs
2. **Geographic Threat Map**: World map showing attack origins
3. **Top Attackers**: Most active malicious IP addresses
4. **Failed Login Attempts**: Authentication failure analysis
5. **Firewall Activity**: Network traffic patterns and blocks
6. **IDS Alerts**: Intrusion detection system alerts

### Key Visualizations

- **Top Source IP Addresses**: Bar chart of most active IPs
- **Failed Login Trends**: Time-series of authentication failures
- **Geographic Attack Distribution**: Heat map of threat sources
- **Security Alert Severity**: Pie chart of alert priorities
- **Network Protocol Analysis**: Traffic breakdown by protocol

## 🔔 Alerting Rules

### Configured Alerts

1. **Multiple Failed Logins**: 5+ failed attempts in 5 minutes
2. **High Severity Threats**: Critical IDS alerts
3. **Blacklisted IP Traffic**: Traffic from known malicious IPs

### Alert Channels

- Email notifications
- Console logging
- Custom webhooks (configurable)

### Customizing Alerts

Edit the alerting rules in `alerting/rules/`:

```bash
vim alerting/rules/failed_logins.yml
vim alerting/rules/high_severity_threats.yml
vim alerting/rules/blacklisted_ips.yml
```

## 📝 Log Sources and Parsing

### Supported Log Types

| Log Type | Source | Parser | Fields Extracted |
|----------|---------|---------|------------------|
| Firewall | iptables, pfSense | Grok | src_ip, dst_ip, action, protocol |
| Authentication | SSH, Web apps | Grok | user, src_ip, result, service |
| IDS/IPS | Snort, Suricata | Grok | severity, alert_msg, src_ip, dst_ip |
| Web Access | Apache, Nginx | Combined Log | request, response, user_agent |

### Adding New Log Sources

1. Update `configs/filebeat/filebeat.yml` with new log paths
2. Add parsing rules to `configs/logstash/pipeline/siem-pipeline.conf`
3. Restart services: `docker-compose restart`

## ⚙️ Configuration

### Directory Structure

```
elk-siem-dashboard/
├── configs/
│   ├── elasticsearch/    # Elasticsearch configuration
│   ├── logstash/         # Logstash pipeline configs
│   ├── kibana/           # Kibana settings
│   └── filebeat/         # Log collection config
├── logs/
│   └── sample-data/      # Sample security logs
├── dashboards/           # Kibana dashboard exports
├── alerting/
│   ├── elastalert.yml    # AlertAlert main config
│   └── rules/            # Alert rules
├── scripts/              # Setup and utility scripts
└── data/                 # Persistent data storage
```

### Environment Variables

Create a `.env` file for custom configuration:

```bash
# Elasticsearch
ES_JAVA_OPTS=-Xmx2g -Xms2g

# Logstash
LS_JAVA_OPTS=-Xmx1g -Xms1g

# Kibana
KIBANA_ENCRYPTION_KEY=your-32-character-encryption-key

# ElastAlert
SMTP_HOST=your.smtp.server
SMTP_PORT=587
ALERT_EMAIL=security@yourcompany.com
```

## 🔧 Troubleshooting

### Common Issues

#### Services won't start
```bash
# Check Docker resources
docker system df
docker system prune

# Increase VM memory for Docker Desktop
# Recommended: 4GB+ RAM
```

#### Elasticsearch yellow/red status
```bash
# Check cluster health
curl -X GET "localhost:9200/_cluster/health?pretty"

# Fix by adjusting replica settings
curl -X PUT "localhost:9200/_settings" -H 'Content-Type: application/json' -d'
{
  "index" : {
    "number_of_replicas" : 0
  }
}'
```

#### No logs appearing in Kibana
```bash
# Check Logstash processing
docker-compose logs logstash

# Verify Filebeat is sending data
docker-compose logs filebeat

# Check Elasticsearch indices
curl -X GET "localhost:9200/_cat/indices?v"
```

### Log Files

- Elasticsearch: `data/elasticsearch/logs/`
- Logstash: Container logs via `docker-compose logs logstash`
- Kibana: Container logs via `docker-compose logs kibana`
- ElastAlert: `alerting/elastalert.log`

## 🔒 Security Considerations

### Production Deployment

1. **Enable Security Features**:
   - Enable Elasticsearch security (`xpack.security.enabled: true`)
   - Configure SSL/TLS encryption
   - Set up user authentication and authorization

2. **Network Security**:
   - Use firewalls to restrict access
   - Configure VPNs for remote access
   - Implement network segmentation

3. **Data Protection**:
   - Encrypt data at rest and in transit
   - Regular backups and snapshots
   - Implement data retention policies

4. **Monitoring**:
   - Monitor the SIEM system itself
   - Set up resource usage alerts
   - Regular security assessments

## 🎯 Use Cases

### Threat Hunting
- Search for indicators of compromise (IoCs)
- Analyze attack patterns and TTPs
- Correlate events across multiple systems

### Incident Response
- Real-time alerting on security events
- Forensic analysis of security incidents
- Timeline reconstruction of attacks

### Compliance Monitoring
- Log retention and archival
- Audit trail generation
- Regulatory compliance reporting

### Security Operations
- Continuous security monitoring
- Threat intelligence integration
- Security metrics and KPIs

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-parser`)
3. Commit your changes (`git commit -am 'Add new log parser'`)
4. Push to the branch (`git push origin feature/new-parser`)
5. Create a Pull Request

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Elastic Stack team for the amazing ELK tools
- Security community for sharing threat intelligence
- Open source contributors

## 📞 Support

For support and questions:
- Create an issue in this repository
- Join our community discussions
- Check the troubleshooting section

---

**⚠️ Disclaimer**: This SIEM solution is designed for educational and development purposes. For production use, ensure proper security hardening and compliance with your organization's security policies.
