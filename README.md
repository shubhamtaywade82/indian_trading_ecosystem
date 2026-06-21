# Indian Trading Ecosystem

A modular, high-frequency algorithmic trading system for Indian stock and derivatives markets (NSE/BSE), supporting real-time data ingestion, strategy execution, portfolio allocation, risk management, automated token rotation, and order routing.

---

## 1. System Architecture

The ecosystem consists of decoupled microservices and shared gems:

```
                            +--------------------------+
                            |     Dashboard / UI       |
                            +-------------+------------+
                                          |
                                      HTTP API
                                          v
+------------------+        +-------------+------------+        +------------------+
|   apps/core_api  +------->|   Execution::Gateway     |<-------+ apps/core_trading|
| (REST API layer) |        +------+------------+------+        |  (Trading Loop)  |
+------------------+               |            |               +------------------+
                                   |            |
                               Paper      Live Broker
                                   v            v
                       +-----------+---+    +---+----------+
                       |apps/paper_engine|  |   DhanHQ API |
                       +-----------------+  +--------------+
```

### Components:
* **`apps/core_trading`**: The heart of the trading execution loop. Coordinates indicator computation, evaluates pre-trade risk mandates, builds portfolio asset weights, and handles the Security Master.
* **`apps/paper_engine`**: Virtual matching engine mimicking stock exchange fills, trade settlement, and paper-ledger account balances.
* **`apps/core_api`**: REST API Gateway exposing endpoints for dashboards to fetch portfolios, positions, signals, health metrics, and send manual overrides.
* **`shared/`**:
  * `dhan_gateway`: Faraday client and adapters wrapping Dhan's order routing, positions, and margins.
  * `domain_models`: Shared ActiveRecord schemas and data models.
  * `risk_lib`: Rule-based pre-trade checks.

---

## 2. Quick Start Setup

### Step 1: Clone and Setup Environment
Copy the environment template and edit with your credentials (Dhan API credentials and TOTP secrets):
```bash
cp .env.example .env
```

### Step 2: Initialize Databases
Initialize PostgreSQL databases across all three applications:
```bash
# Core Trading Database
cd apps/core_trading && bundle install
bundle exec rails db:create db:migrate

# Paper Engine Database
cd ../paper_engine && bundle install
bundle exec rails db:create db:migrate

# Core API Database
cd ../core_api && bundle install
bundle exec rails db:create db:migrate
```

---

## 3. Running in Paper Trading Mode (Simulation)

To test strategies safely in a simulated environment using real-time market data:

1. **Start the Paper Matching Engine**:
   Runs on port `3001` by default:
   ```bash
   cd apps/paper_engine
   bundle exec rails server -p 3001
   ```

2. **Seed execution configurations**:
   In a separate terminal, open the `core_trading` console:
   ```bash
   cd apps/core_trading
   bundle exec rails console
   ```
   Add a runtime profile and configuration pointing to the local paper engine:
   ```ruby
   profile = Core::ExecutionProfile.find_or_create_by!(
     name: 'paper_profile',
     adapter_name: 'paper'
   )
   Core::RuntimeConfig.find_or_create_by!(
     name: 'paper_trading',
     mode: 'paper',
     market_data_source: 'dhan',
     execution_profile: profile,
     broker: 'dhan',
     paper_account_id: 'ACC_123'
   )
   ```

3. **Start the API Server**:
   Runs on port `3000` by default:
   ```bash
   cd apps/core_api
   bundle exec rails server -p 3000
   ```

4. **Launch the Loop Supervisor Daemon**:
   Starts monitoring strategies and executing loop cycles:
   ```bash
   cd apps/core_trading
   bundle exec bin/trading_daemon
   ```

---

## 4. Running in Live Mode with Dhan HQ

To execute real orders directly on the exchange:

1. Add your credentials (`DHAN_CLIENT_ID`, `DHAN_PIN`, and `DHAN_TOTP_SECRET`) to the `.env` file.
2. In the `core_trading` Rails console, configure the live profile:
   ```ruby
   profile_live = Core::ExecutionProfile.find_or_create_by!(
     name: 'live_profile',
     adapter_name: 'live'
   )
   Core::RuntimeConfig.find_or_create_by!(
     name: 'live_trading',
     mode: 'live',
     market_data_source: 'dhan',
     execution_profile: profile_live,
     broker: 'dhan'
   )
   ```
3. Run the daemon pointing to the live config, which automatically uses automated **TOTP Token Rotation** under the hood:
   ```bash
   # In terminal
   export DHAN_AUTH_MODE=totp
   bundle exec bin/trading_daemon
   ```

---

## 5. Verification and Running Tests
Execute unit and integration tests across all microservices:
```bash
# Verify shared gateway logic
cd shared/dhan_gateway && bundle exec rspec

# Verify trading daemon logic & adapters
cd ../../apps/core_trading && bundle exec rspec

# Verify matching engine logic
cd ../paper_engine && bundle exec rspec

# Verify REST API routing logic
cd ../core_api && bundle exec rspec
```
