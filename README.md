#For eMorzaa TEAM
When you are using localhost :-
SSH Access:
ssh morzaa@localhost -p 2222
# Password: morzaa123

PostgreSQL Access:
psql -h localhost -p 5432 -U morzaa -d morzaa_db
# Password: morzaa123
Web Access:
Open your browser and go to http://localhost:8080
For pgAdmin (if working): http://localhost:8080/pgadmin4/

**How do you modify network :-**
I see you have two network interfaces in your container:
- `eth0`: 172.17.0.2 (default Docker bridge network)
- `eth1`: 192.168.56.2 (your additional network - likely a host-only or custom network)

To access your container from external networks using the `eth1` (192.168.56.2) interface, you have several options:

## Option 1: Use Host Network Mode (Simplest)

Stop your current container and run it with host networking:

```bash
# Stop current container
docker stop morzaa-dev
docker rm morzaa-dev

# Run with host network (container uses host's network directly)
docker run -d \
  --name morzaa-dev \
  --network host \
  -v morzaa_postgres:/var/lib/postgresql/14/main \
  -v morzaa_pgadmin:/var/lib/pgadmin \
  -v morzaa_home:/home/morzaa \
  emorzadoker-ub24
```

With host networking, you can access services directly on your host's IP addresses using standard ports (22, 5432, 80).

## Option 2: Create a Custom Bridge Network

```bash
# Create a custom network that can route to your 192.168.56.x network
docker network create --driver bridge \
  --subnet=192.168.56.0/24 \
  --gateway=192.168.56.1 \
  morzaa-network

# Run container on this network
docker run -d \
  --name morzaa-dev \
  --network morzaa-network \
  --ip 192.168.56.10 \
  -p 192.168.56.10:22:22 \
  -p 192.168.56.10:5432:5432 \
  -p 192.168.56.10:80:80 \
  -v morzaa_postgres:/var/lib/postgresql/14/main \
  -v morzaa_pgadmin:/var/lib/pgadmin \
  -v morzaa_home:/home/morzaa \
  emorzadoker-ub24
```

## Option 3: Connect Container to Existing Network

If you already have the 192.168.56.x network configured on your host:

```bash
# Find your network name
docker network ls

# Connect your running container to additional network
docker network connect <your_network_name> morzaa-dev --ip 192.168.56.10
```

## Option 4: Port Binding on Specific Interface

Bind ports to your specific host interface:

```bash
docker stop morzaa-dev
docker rm morzaa-dev

# Bind to specific host IP (replace with your host's 192.168.56.x IP)
docker run -d \
  --name morzaa-dev \
  -p 192.168.56.1:2222:22 \
  -p 192.168.56.1:5432:5432 \
  -p 192.168.56.1:8080:80 \
  -v morzaa_postgres:/var/lib/postgresql/14/main \
  -v morzaa_pgadmin:/var/lib/pgadmin \
  -v morzaa_home:/home/morzaa \
  emorzadoker-ub24
```

## Check Your Host Network Configuration

First, check your Docker host's network configuration:

```bash
# On your Docker host (not in container)
ip addr show
ifconfig
```

Find which interface has the 192.168.56.x network and note its IP address.

## Recommended Approach

I'd suggest **Option 1 (Host Network)** for simplicity, or **Option 4** if you want more control. With host networking, external clients can access your services using your host's IP addresses directly:

- SSH: `ssh morzaa@<your_host_192.168.56.x_ip> -p 22`
- PostgreSQL: `psql -h <your_host_192.168.56.x_ip> -p 5432 -U morzaa -d morzaa_db`
- Web: `http://<your_host_192.168.56.x_ip>`

Which option would you like to try first?
