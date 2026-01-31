#!/bin/bash

# --- Configuration (Based on your docker-compose) ---
NGINX_CONTAINER="nginx-proxy"
RABBIT_CONTAINER="rabbitmq-order"
RABBIT_USER="morzaa"
RABBIT_PASS="morzaa123"
DB_CONTAINERS=("postgres-inventory" "postgres-ordering" "postgres-cms" "postgres-delivery" "postgres-auth")

echo "=========================================================="
echo " MORZAA SYSTEM INVESTIGATION REPORT - $(date)"
echo "=========================================================="

# 1. PERFORMANCE: Container Resource Consumption
echo -e "\n[1/5] PERFORMANCE: Resource Usage"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

# 2. SESSIONS: Web Traffic
echo -e "\n[2/5] SESSIONS: Unique Visitors (Last 1k Requests)"
if docker ps | grep -q $NGINX_CONTAINER; then
    docker logs --tail 1000 $NGINX_CONTAINER 2>&1 | awk '{print $1}' | sort | uniq -c | sort -nr | head -n 5
else
    echo "Warning: Nginx container not found."
fi

# 3. SECURITY: External Port Exposure
echo -e "\n[3/5] SECURITY: Exposed Port Check"
# Checks for DB and RabbitMQ ports exposed to 0.0.0.0 (public)
ss -tulpn | grep LISTEN | grep -E '5432|5433|5434|5435|5436|5672|15672' | awk '{print "Alert: Port " $5 " is open to the host."}'

# 4. DATABASE: Active Connection Count
echo -e "\n[4/5] DATABASE: Connection Health"
for db in "${DB_CONTAINERS[@]}"; do
    if docker ps | grep -q $db; then
        # Dynamically determine the DB name based on container name
        db_name=$(echo $db | cut -d'-' -f2)
        count=$(docker exec $db psql -U morzaa_${db_name:0:3}_user -d ${db_name^}DB -t -c "SELECT count(*) FROM pg_stat_activity;" 2>/dev/null || echo "N/A")
        echo "--- $db: $count connections"
    fi
done

# 5. NEW: RABBITMQ HEALTH (Stuck Orders)
echo -e "\n[5/5] MESSAGE QUEUE: RabbitMQ Health & Stuck Orders"
if docker ps | grep -q $RABBIT_CONTAINER; then
    echo "Checking for stuck messages in queues..."
    
    # Extract queue stats: Name, Ready Messages (Waiting), Unacknowledged (Processing), Consumers (Active workers)
    docker exec $RABBIT_CONTAINER rabbitmqctl list_queues name messages_ready messages_unacknowledged consumers | grep -v "Timeout" | column -t
    
    # Logic to flag alerts
    STUCK_ORDERS=$(docker exec $RABBIT_CONTAINER rabbitmqctl list_queues messages_ready --quiet | awk '{s+=$1} END {print s}')
    if [ "$STUCK_ORDERS" -gt 0 ]; then
        echo -e "\n [!] ALERT: There are $STUCK_ORDERS messages waiting in the queue."
        echo "     If 'consumers' is 0, your worker services (Ordering/Delivery) are likely DOWN."
    else
        echo " [OK] No backlog in queues."
    fi
else
    echo "Critical: RabbitMQ container ($RABBIT_CONTAINER) is OFFLINE."
fi

echo -e "\n=========================================================="
echo " INVESTIGATION COMPLETE"
echo "=========================================================="
