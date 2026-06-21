# Start services for Indian Trading Ecosystem

# Infrastructure
redis_db: docker-compose -f infrastructure/docker-compose.yml up postgres redis

# Core Paper Engine (Port 3001)
paper_engine: sleep 3 && cd apps/paper_engine && bundle exec rails server -p 3001

# Core API Gateway & Dashboard UI (Port 3000)
core_api: sleep 4 && cd apps/core_api && bundle exec rails server -p 3000

# Trading Execution Daemon
trading_daemon: sleep 5 && cd apps/core_trading && bundle exec bin/trading_daemon

# Market Feed Streamer
marketfeed: sleep 5 && cd apps/marketfeed && bundle exec bin/marketfeed
