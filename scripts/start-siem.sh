#!/bin/bash

# ELK SIEM Dashboard Startup Script
# This script starts the complete SIEM system and waits for all services to be ready

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a service is healthy
check_service() {
    local service_name=$1
    local health_url=$2
    local max_attempts=60
    local attempt=1

    print_status "Waiting for $service_name to be ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "$health_url" > /dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        
        printf "."
        sleep 5
        ((attempt++))
    done
    
    print_error "$service_name failed to start within expected time"
    return 1
}

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    print_error "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

print_status "Starting ELK SIEM Dashboard..."
print_status "This will take a few minutes on first run..."

# Pull latest images
print_status "Pulling Docker images..."
docker-compose pull

# Start services in background
print_status "Starting all services..."
docker-compose up -d

# Wait for services to be ready
print_status "Waiting for services to initialize..."

# Check Elasticsearch
if check_service "Elasticsearch" "http://localhost:9200/_cluster/health"; then
    # Check cluster health
    health_status=$(curl -s "http://localhost:9200/_cluster/health" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
    if [ "$health_status" = "green" ] || [ "$health_status" = "yellow" ]; then
        print_success "Elasticsearch cluster is healthy (status: $health_status)"
    else
        print_warning "Elasticsearch cluster status: $health_status"
    fi
fi

# Check Logstash
if check_service "Logstash" "http://localhost:9600"; then
    print_success "Logstash is processing data"
fi

# Check Kibana
if check_service "Kibana" "http://localhost:5601/api/status"; then
    print_success "Kibana dashboard is accessible"
fi

# Display service status
print_status "Checking service status..."
docker-compose ps

echo ""
print_success "🎉 ELK SIEM Dashboard is ready!"
echo ""
print_status "Access your services at:"
echo -e "  ${GREEN}Kibana Dashboard:${NC} http://localhost:5601"
echo -e "  ${GREEN}Elasticsearch:${NC}    http://localhost:9200"
echo -e "  ${GREEN}Logstash:${NC}         http://localhost:9600"
echo ""
print_status "Next steps:"
echo "  1. Open Kibana at http://localhost:5601"
echo "  2. Go to 'Discover' to explore your security logs"
echo "  3. Check pre-built dashboards for security insights"
echo "  4. Configure alerting for your environment"
echo ""
print_status "To setup dashboards, run:"
echo "  ./scripts/setup-dashboards.sh"
echo ""
print_status "To stop the SIEM system, run:"
echo "  docker-compose down"
echo ""
print_warning "Note: Sample data is included for demonstration purposes"
