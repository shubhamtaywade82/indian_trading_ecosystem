# ARTHX Trading Ecosystem Startup Guide

This document describes how to set up, configure, and start the complete Indian Trading Ecosystem.

---

## 1. Port & Service Mapping

The ecosystem consists of decoupled services that connect to each other over HTTP, WebSockets, and Redis:

| Service | Protocol / Type | Port / Address | Responsibility |
| :--- | :--- | :--- | :--- |
| **`core_api`** | HTTP Gateway & WebSockets | `3000` | Exposes REST API gateway and Action Cable WebSocket (`/cable`) for dashboards. Serves the Dashboard UI page directly on `/`. |
| **`paper_engine`** | HTTP Matching API | `3001` | Virtual matching engine, double-entry ledger, margin calculators, and trade lot accounting. |
| **`core_trading`** | Ruby Daemon | Daemon process | The loop supervisor daemon executing indicator strategy checks and rebalancing. |
| **`marketfeed`** | Ruby Daemon | Daemon process | Live client WebSocket feed parsing and ingestion. |
| **PostgreSQL** | SQL Database | `5434` (Docker mapping) | Persistent relational store for all three microservices. |
| **Redis** | Pub/Sub & Caching | `6380` (Docker mapping) | High-speed cache and pub/sub broker for tick stream propagation. |

---

## 2. Prerequisites

Ensure you have the following installed on your machine:
* Ruby (version `3.3.4` or compatible)
* Docker & Docker Compose (optional but recommended for database infrastructure)
* Bundler (`gem install bundler`)
* Optional: Foreman (`gem install foreman`) for single-command orchestration.

---

## 3. Automated Quickstart

The easiest way to spin up the system is to use the provided automated startup script:

### Step 1: Run the Bootstrapper
Run [start_ecosystem.sh](file:///home/nemesis/project/trading-workspace/indian_trading_ecosystem/bin/start_ecosystem.sh) to spin up the PostgreSQL and Redis containers, verify status, and run migrations across all three apps:
```bash
./bin/start_ecosystem.sh
```

### Step 2: Start All Services
If you have `foreman` installed, use the [Procfile](file:///home/nemesis/project/trading-workspace/indian_trading_ecosystem/Procfile) to start the web servers and daemons in parallel:
```bash
foreman start
```

---

## 4. Manual Sequential Startup

If you prefer to run services manually in separate terminal windows, run the following commands:

### Tab 1: Start Database Containers
```bash
docker-compose -f infrastructure/docker-compose.yml up -d postgres redis
```

### Tab 2: Start Paper Engine (Port 3001)
```bash
cd apps/paper_engine
bundle exec rails server -p 3001
```

### Tab 3: Start API Gateway & UI Dashboard (Port 3000)
```bash
cd apps/core_api
bundle exec rails server -p 3000
```

### Tab 4: Start Trading Daemon Loop
```bash
cd apps/core_trading
bundle exec bin/trading_daemon
```

### Tab 5: Start Marketfeed stream ingestion
```bash
cd apps/marketfeed
bundle exec bin/marketfeed
```

---

## 5. Verification & Accessing UI

### Dashboard UI Access
Once the processes are running, open your web browser and navigate to:
* **[http://localhost:3000/](http://localhost:3000/)**

The dashboard UI will load, connect to the `/cable` endpoint via WebSockets, and begin streaming live metrics.

### REST API Health Check
You can test the health endpoints for the services via curl:
```bash
# Verify API Gateway
curl http://localhost:3000/api/v1/health

# Verify Paper Matching Engine
curl http://localhost:3001/up
```

### Run Tests Suite
Verify that all application test suites are green:
```bash
# Shared gateway tests
cd shared/dhan_gateway && bundle exec rspec

# Core trading logic tests
cd ../../apps/core_trading && bundle exec rspec

# Paper matching engine tests
cd ../paper_engine && bundle exec rspec

# API endpoint and gateway tests
cd ../core_api && bundle exec rspec
```

---

## 6. Syncing Indian Exchanges, Segments & Instruments

The database includes a full **Security Master schema** capable of representing all segments of the Indian markets (NSE, BSE, MCX, Currency F&O). 

To populate the database with all tradeable instruments, ex-dates, expiries, lot sizes, strike prices, and option types, you can run the built-in Rake synchronization task.

### Run Instrument Importer
Execute the importer in the `core_trading` directory. This downloads the daily scrip master from Dhan HQ's official servers and populates both the core execution loop and primary security master databases:
```bash
cd apps/core_trading
bundle exec rails import:instruments
```

* **Limit Records (Optional)**: If you wish to only import a small sample subset (e.g., for test environments or quick validation), specify a `LIMIT` variable:
  ```bash
  LIMIT=1000 bundle exec rails import:instruments
  ```
* **Custom URL (Optional)**: To parse a specific CSV mapping or local file, override the `SCRIP_MASTER_URL` environment variable.

