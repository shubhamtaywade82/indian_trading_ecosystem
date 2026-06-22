#!/usr/bin/env bash
# Startup script for ARTHX / Indian Trading Ecosystem
set -e

# Color helpers
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0;5m' # No Color
RESET='\033[0m'

echo -e "${CYAN}=====================================================${RESET}"
echo -e "${CYAN}       Starting ARTHX Indian Trading Ecosystem       ${RESET}"
echo -e "${CYAN}=====================================================${RESET}"

# 1. Start Infrastructure via Docker
echo -e "\n${YELLOW}[1/3] Spinning up PostgreSQL & Redis containers...${RESET}"
if command -v docker-compose &> /dev/null; then
  docker-compose -f infrastructure/docker-compose.yml up -d --remove-orphans postgres redis
  echo -e "${GREEN}✔ Infrastructure container services started in background.${RESET}"
else
  echo -e "${RED}✘ docker-compose not found. Please ensure PostgreSQL is running on port 5434 and Redis on 6380 locally.${RESET}"
fi

# 2. Run Database Migrations (safety check)
echo -e "\n${YELLOW}[2/3] Checking database schema status...${RESET}"
(cd apps/paper_engine && bundle exec rails db:migrate)
(cd apps/core_api && bundle exec rails db:migrate)
(cd apps/core_trading && bundle exec rails db:migrate)
echo -e "${GREEN}✔ Databases migrated successfully.${RESET}"

# 3. Inform User how to start processes
echo -e "\n${YELLOW}[3/3] Ready to boot services!${RESET}"
echo -e "${CYAN}-----------------------------------------------------${RESET}"
echo -e "You can boot all microservices in one terminal tab using:"
echo -e "  ${GREEN}gem install foreman && foreman start${RESET}"
echo -e "${CYAN}-----------------------------------------------------${RESET}"
echo -e "Or execute them manually in separate terminal tabs:"
echo -e "  1. Paper Engine (Port 3001):"
echo -e "     ${GREEN}cd apps/paper_engine && bundle exec rails server -p 3001${RESET}"
echo -e "  2. API Gateway & Dashboard (Port 3000):"
echo -e "     ${GREEN}cd apps/core_api && bundle exec rails server -p 3000${RESET}"
echo -e "  3. Core Trading Daemon:"
echo -e "     ${GREEN}cd apps/core_trading && bundle exec bin/trading_daemon${RESET}"
echo -e "  4. Marketfeed Streamer Daemon:"
echo -e "     ${GREEN}cd apps/marketfeed && bundle exec bin/marketfeed${RESET}"
echo -e "${CYAN}-----------------------------------------------------${RESET}"
echo -e "Once started, open the UI at: ${GREEN}http://localhost:3000/${RESET}"
echo -e "${CYAN}=====================================================${RESET}"
