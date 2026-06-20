Automated autonomous stocks investment using dhanhq client + rails + resque, technical analysis, ollama cloud models (ollama-client) etc @Web search build a firm level architecture for single retail user for investment plans dn trading (swing trading) and long-term trading in Indian stocks in nse/bse

# DhanHQ — The Ruby SDK for Dhan API v2

[![Gem Version](https://badge.fury.io/rb/DhanHQ.svg)](https://rubygems.org/gems/DhanHQ)
[![CI](https://github.com/shubhamtaywade82/dhanhq-client/actions/workflows/main.yml/badge.svg)](https://github.com/shubhamtaywade82/dhanhq-client/actions/workflows/main.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-ruby.svg)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE.txt)

Build trading systems in Ruby without fighting raw HTTP, fragile auth flows, or unreliable market streams.

DhanHQ is a production-grade Ruby SDK for the [Dhan trading API](https://dhanhq.co/docs/v2/), designed for:

- trading bots
- real-time market data streaming
- portfolio and order management
- Rails or standalone trading systems

If you're looking for a Ruby SDK for Dhan API, this is built to be the default choice.

Unlike thin wrappers, DhanHQ gives you:

- typed models for orders, positions, holdings, and more
- WebSocket clients with auto-reconnect and backoff
- token lifecycle management with retry-on-401
- safety rails for live trading

This is closer to trading infrastructure than a simple API client.

## Install and Run in 60 Seconds

```ruby
# Gemfile
gem 'DhanHQ'
```

```ruby
require 'dhan_hq'

DhanHQ.configure do |c|
  c.client_id    = ENV["DHAN_CLIENT_ID"]
  c.access_token = ENV["DHAN_ACCESS_TOKEN"]
end

# You're live — no manual HTTP, no JSON parsing
positions = DhanHQ::Models::Position.all
```

---

## Who This Is For

- Ruby developers building trading bots
- Rails apps integrating the Dhan API
- Algo trading systems that need clean abstractions over raw HTTP
- Long-running processes that rely on WebSocket market data

## Who This Is Not For

- One-off scripts where raw HTTP is enough
- Non-Ruby stacks

---

## Start Here (Pick Your Use Case)

Pick the path that matches what you want to build:

- **Get live prices fast** → [Market Feed WebSocket](#market-feed-ticker--quote--full)
- **Place orders safely** → [Order Safety](#order-safety)
- **Build a trading strategy** → [WebSockets](#websockets)
- **Build a trading bot** → [examples/basic_trading_bot.rb](examples/basic_trading_bot.rb)
- **Use with Rails** → [docs/RAILS_INTEGRATION.md](docs/RAILS_INTEGRATION.md)

---

## Trust Signals

- **CI on supported Rubies** — GitHub Actions runs RSpec on Ruby 3.2.0 and 3.3.4, plus RuboCop on every push and pull request
- **Typed domain models** — Orders, Positions, Holdings, Funds, MarketFeed, OptionChain, Super Orders, and more expose a Ruby-first API instead of raw hashes
- **No real API calls in the default test suite** — WebMock blocks outbound HTTP and VCR covers cassette-backed integration paths
- **Auth lifecycle support** — static tokens, dynamic token providers, 401 retry with refresh hooks, and token sanitization in logs
- **WebSocket resilience** — reconnect, backoff, 429 cool-off, local connection cleanup, and dedicated market/order stream clients
- **Live trading guardrails** — order placement is blocked unless `LIVE_TRADING=true`, and order attempts emit structured audit logs

---

## Why Not a Thin Wrapper?

Most API clients give you HTTP access. DhanHQ gives you a working Ruby system.

| Instead of | You get |
| ---------- | -------- |
| JSON parsing and manual field mapping | Typed models |
| Manual auth refresh | Built-in token lifecycle |
| Fragile WebSocket code | Auto-reconnect, backoff, and 429 handling |
| Risky order scripts | Live trading guardrails and audit logs |

---

## Architecture At A Glance

![DhanHQ architecture overview](docs/architecture-overview.svg)

Models own the Ruby API. Resources own HTTP calls. Contracts validate inputs. The transport layer handles auth, retries, rate limiting, and error mapping. WebSockets are a separate subsystem that shares configuration but not the REST stack.

For the full dependency flow and extension pattern, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## ✨ Key Features

- **ActiveRecord-style models** — `find`, `all`, `where`, `save`, `cancel` across Orders, Positions, Holdings, Funds, and more
- **Auto token refresh** — 401 retry with fresh token via provider callback
- **Thread-safe WebSocket client** — Orders, Market Feed, Market Depth with auto-reconnect
- **Exponential backoff + 429 cool-off** — no manual rate-limit management
- **Secure logging** — automatic token sanitization in all log output
- **Super Orders** — entry + stop-loss + target + trailing jump in one request
- **Instrument convenience methods** — `.ltp`, `.ohlc`, `.option_chain` directly on instruments
- **Order audit logging** — every order attempt logs machine, IP, environment, and correlation ID as structured JSON
- **Live trading guard** — prevents accidental order placement unless `ENV["LIVE_TRADING"]="true"`
- **Full REST coverage** — Orders, Trades, Forever Orders, Super Orders, Positions, Holdings, Funds, HistoricalData, OptionChain, MarketFeed, EDIS, Kill Switch, P&L Exit, Alert Orders, Margin Calculator
- **P&L Based Exit** — automatic position exit on profit/loss thresholds
- **Postback parser** — parse Dhan webhook payloads with `Postback.parse` and status predicates
- **EDIS model** — ORM-style T-PIN, form, and status inquiry for delivery instruction slips

---

## Reliability & Safety

- retry-on-401 with token refresh
- WebSocket auto-reconnect and backoff
- 429 rate-limit protection
- live trading guard via `LIVE_TRADING=true`
- structured order audit logs

See [ARCHITECTURE.md](ARCHITECTURE.md), [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md), and [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for the deeper implementation details.

---

## Installation

```ruby
# Gemfile (recommended)
gem 'DhanHQ'
```

```bash
bundle install
# or
gem install DhanHQ
```

> **Bleeding edge?** Use `gem 'DhanHQ', git: 'https://github.com/shubhamtaywade82/dhanhq-client.git', branch: 'main'` only if you need unreleased features.

**`bundle update` / `bundle install` warnings** — If you see "Local specification for rexml-3.2.8 has different dependencies" or "Unresolved or ambiguous specs during Gem::Specification.reset: psych", the bundle still completes successfully. To clear the rexml warning once, run: `gem cleanup rexml`. The psych message is a known Bundler quirk and can be ignored.

### Gem name vs require path

RubyGems normalizes names, so `DhanHQ` and `dhan_hq` refer to the same slot — the published name stays `DhanHQ` and will never change. The require path has used snake_case since v2.1.5:

```ruby
# Gemfile              # Ruby file
gem 'DhanHQ'           require 'dhan_hq'
```

### Optional features

The core SDK (`require 'dhan_hq'`) only loads the API client. Technical analysis and the options advisor are opt-in:

```ruby
require 'dhan_hq/analysis'  # DhanHQ::Analysis::OptionsBuyingAdvisor, MultiTimeframeAnalyzer
require 'dhan_hq/ta'        # TA::TechnicalAnalysis, TA::Fetcher, TA::Candles
```

---

## Configuration

### Static token (simplest)

```ruby
require 'dhan_hq'
DhanHQ.configure_with_env   # reads DHAN_CLIENT_ID + DHAN_ACCESS_TOKEN from ENV
```

| Variable             | Purpose                                |
| -------------------- | -------------------------------------- |
| `DHAN_CLIENT_ID`     | Your Dhan trading account client ID    |
| `DHAN_ACCESS_TOKEN`  | API token from the Dhan console        |

### Dynamic token (production / OAuth)

```ruby
DhanHQ.configure do |config|
  config.client_id = ENV["DHAN_CLIENT_ID"]
  config.access_token_provider = -> { YourTokenStore.active_token }
  config.on_token_expired = ->(error) { YourTokenStore.refresh! }  # optional
end
```

When the API returns 401, the client retries **once** with a fresh token from your provider.

> **Full details**: TOTP flows, partner mode, token endpoint bootstrap, auto-management — see [docs/AUTHENTICATION.md](docs/AUTHENTICATION.md).

---

## Order Safety

### Live Trading Guard

Order placement (`create`, `slicing`) is blocked unless you explicitly enable it:

```bash
# Production (Render, VPS, etc.)
LIVE_TRADING=true

# Development / Test (default — orders are blocked)
LIVE_TRADING=false   # or simply omit
```

Attempting to place an order without `LIVE_TRADING=true` raises `DhanHQ::LiveTradingDisabledError`.

### Order Audit Logging

Every order attempt (place, modify, slice) automatically logs a structured JSON line at WARN level:

```json
{
  "event": "DHAN_ORDER_ATTEMPT",
  "hostname": "DESKTOP-SHUBHAM",
  "env": "production",
  "ipv4": "122.171.22.40",
  "ipv6": "2401:4900:894c:8448:1da9:27f1:48e7:61be",
  "security_id": "11536",
  "correlation_id": "SCALPER_7af1",
  "timestamp": "2026-03-17T06:45:22Z"
}
```

This tells you instantly which machine, app, IP, and environment placed the order.

### Correlation ID Prefixes

Use per-app prefixes for instant source identification in the Dhan orderbook:

```ruby
# algo_scalper_api
correlation_id: "SCALPER_#{SecureRandom.hex(4)}"

# algo_trader_api
correlation_id: "TRADER_#{SecureRandom.hex(4)}"
```

The Dhan orderbook will show `SCALPER_7af1` or `TRADER_3bc9`, making the source obvious.

---

## REST API

### Orders — Place, Modify, Cancel

```ruby
order = DhanHQ::Models::Order.new(
  transaction_type: DhanHQ::Constants::TransactionType::BUY,
  exchange_segment: DhanHQ::Constants::ExchangeSegment::NSE_FNO,
  product_type: DhanHQ::Constants::ProductType::MARGIN,
  order_type: DhanHQ::Constants::OrderType::LIMIT,
  validity: DhanHQ::Constants::Validity::DAY,
  security_id:      "43492",
  quantity:         50,
  price:            100.0
)
order.save          # places the order
order.modify(price: 101.5)
order.cancel
```

### Positions, Holdings, Funds

```ruby
DhanHQ::Models::Position.all
DhanHQ::Models::Holding.all
DhanHQ::Models::Fund.balance
```

### Historical Data

```ruby
bars = DhanHQ::Models::HistoricalData.intraday(
  security_id:      "13",
  exchange_segment: DhanHQ::Constants::ExchangeSegment::IDX_I,
  instrument: DhanHQ::Constants::InstrumentType::INDEX,
  interval:         "5",
  from_date:        "2025-08-14",
  to_date:          "2025-08-18"
)
```

### Instrument Lookup

```ruby
nifty = DhanHQ::Models::Instrument.find("IDX_I", "NIFTY")
nifty.ltp           # last traded price
nifty.ohlc          # OHLC data
nifty.option_chain(expiry: "2025-02-28")
nifty.intraday(from_date: "2025-08-14", to_date: "2025-08-18", interval: "15")
```

---

## WebSockets

Three real-time feeds, all with **auto-reconnect**, **backoff**, **429 cool-off**, and **thread-safe operation**.

### Order Updates

```ruby
DhanHQ::WS::Orders.connect do |order_update|
  puts "#{order_update.order_no} → #{order_update.status} (#{order_update.traded_qty}/#{order_update.quantity})"
end
```

### Market Feed (Ticker / Quote / Full)

```ruby
client = DhanHQ::WS.connect(mode: :ticker) do |tick|
  puts "#{tick[:security_id]} = ₹#{tick[:ltp]}"
end

client.subscribe_one(segment: DhanHQ::Constants::ExchangeSegment::IDX_I, security_id: "13")   # NIFTY
client.subscribe_one(segment: DhanHQ::Constants::ExchangeSegment::IDX_I, security_id: "25")   # BANKNIFTY
```

### Market Depth

```ruby
reliance = DhanHQ::Models::Instrument.find("NSE_EQ", "RELIANCE")

DhanHQ::WS::MarketDepth.connect(symbols: [
  { symbol: "RELIANCE", exchange_segment: reliance.exchange_segment, security_id: reliance.security_id }
]) do |depth|
  puts "Best Bid: #{depth[:best_bid]} | Best Ask: #{depth[:best_ask]} | Spread: #{depth[:spread]}"
end
```

### Cleanup

```ruby
DhanHQ::WS.disconnect_all_local!   # kills all local WS connections
```

---

## Super Orders

Entry + target + stop-loss + trailing jump in a single request:

```ruby
DhanHQ::Models::SuperOrder.create(
  transaction_type: DhanHQ::Constants::TransactionType::BUY,
  exchange_segment: DhanHQ::Constants::ExchangeSegment::NSE_EQ,
  product_type: DhanHQ::Constants::ProductType::CNC,
  order_type: DhanHQ::Constants::OrderType::LIMIT,
  security_id:      "11536",
  quantity:         5,
  price:            1500,
  target_price:     1600,
  stop_loss_price:  1400,
  trailing_jump:    10
)
```

> **Full API reference** (modify, cancel, list, response schemas): [docs/SUPER_ORDERS.md](docs/SUPER_ORDERS.md)

---

## Real-World Example: NIFTY Trend Monitor

```ruby
require 'dhan_hq'

DhanHQ.configure_with_env

# 1. Check the trend using historical 5-min bars
bars = DhanHQ::Models::HistoricalData.intraday(
  security_id: "13", exchange_segment: DhanHQ::Constants::ExchangeSegment::IDX_I,
  instrument: DhanHQ::Constants::InstrumentType::INDEX, interval: "5",
  from_date: Date.today.to_s, to_date: Date.today.to_s
)

closes = bars.map { |b| b[:close] }
sma_20 = closes.last(20).sum / 20.0
trend  = closes.last > sma_20 ? :bullish : :bearish
puts "NIFTY trend: #{trend} (LTP: #{closes.last}, SMA20: #{sma_20.round(2)})"

# 2. Stream live ticks for real-time monitoring
client = DhanHQ::WS.connect(mode: :quote) do |tick|
  puts "NIFTY ₹#{tick[:ltp]} | Vol: #{tick[:vol]} | #{Time.now.strftime('%H:%M:%S')}"
end
client.subscribe_one(segment: DhanHQ::Constants::ExchangeSegment::IDX_I, security_id: "13")

# 3. On signal, place a super order with built-in risk management
# DhanHQ::Models::SuperOrder.create(
#   transaction_type: DhanHQ::Constants::TransactionType::BUY, exchange_segment: DhanHQ::Constants::ExchangeSegment::NSE_FNO, ...
#   target_price: entry + 50, stop_loss_price: entry - 30, trailing_jump: 5
# )

# 4. Clean shutdown
at_exit { DhanHQ::WS.disconnect_all_local! }
sleep   # keep the script alive
```

---

## Rails Integration

Need initializers, service objects, ActionCable wiring, and background workers? See the [Rails Integration Guide](docs/RAILS_INTEGRATION.md).

---

## Real-World Examples

These scripts are designed around user goals rather than API surfaces:

| Example | Use case |
| ------- | -------- |
| [examples/basic_trading_bot.rb](examples/basic_trading_bot.rb) | Pull historical data, evaluate a simple signal, and place a guarded order |
| [examples/portfolio_monitor.rb](examples/portfolio_monitor.rb) | Snapshot funds, holdings, and positions for a monitoring script |
| [examples/options_watchlist.rb](examples/options_watchlist.rb) | Build a live options watchlist with index quotes and option-chain context |
| [examples/market_feed_example.rb](examples/market_feed_example.rb) | Subscribe to major market indices over WebSocket |
| [examples/live_order_updates.rb](examples/live_order_updates.rb) | Track order lifecycle events in real time |

For search-driven discovery and onboarding content, see:

- [docs/HOW_TO_USE_DHAN_API_WITH_RUBY.md](docs/HOW_TO_USE_DHAN_API_WITH_RUBY.md)
- [docs/BUILD_A_TRADING_BOT_WITH_RUBY_AND_DHAN.md](docs/BUILD_A_TRADING_BOT_WITH_RUBY_AND_DHAN.md)

## Use Case Guides

- [docs/DHAN_API_RUBY_EXAMPLES.md](docs/DHAN_API_RUBY_EXAMPLES.md)
- [docs/DHAN_WEBSOCKET_RUBY_GUIDE.md](docs/DHAN_WEBSOCKET_RUBY_GUIDE.md)
- [docs/BEST_WAY_TO_USE_DHAN_API_IN_RUBY.md](docs/BEST_WAY_TO_USE_DHAN_API_IN_RUBY.md)
- [docs/DHAN_RUBY_QA.md](docs/DHAN_RUBY_QA.md)

---

## 📚 Documentation

| Guide | What it covers |
| ----- | -------------- |
| [Architecture](ARCHITECTURE.md) | Layering, dependency flow, design patterns, extension points |
| [Authentication](docs/AUTHENTICATION.md) | Token flows, TOTP, OAuth, auto-management |
| [Configuration Reference](docs/CONFIGURATION.md) | Full ENV matrix, logging, timeouts, available resources |
| [WebSocket Integration](docs/WEBSOCKET_INTEGRATION.md) | All WS types, architecture, best practices |
| [WebSocket Protocol](docs/WEBSOCKET_PROTOCOL.md) | Packet parsing, request codes, tick schema, exchange enums |
| [Rails WebSocket Guide](docs/RAILS_WEBSOCKET_INTEGRATION.md) | Rails-specific patterns, ActionCable |
| [Rails Integration](docs/RAILS_INTEGRATION.md) | Initializers, service objects, workers |
| [Standalone Ruby Guide](docs/STANDALONE_RUBY_WEBSOCKET_INTEGRATION.md) | Scripts, daemons, and long-running Ruby processes |
| [Super Orders API](docs/SUPER_ORDERS.md) | Full REST reference for super orders |
| [API Constants Reference](docs/CONSTANTS_REFERENCE.md) | All valid enums, exchange segments, and order parameters |
| [Data API Parameters](docs/DATA_API_PARAMETERS.md) | Historical data, option chain parameters |
| [Testing Guide](docs/TESTING_GUIDE.md) | WebSocket testing, model testing, console helpers |
| [Technical Analysis](docs/TECHNICAL_ANALYSIS.md) | Indicators, multi-timeframe aggregation |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | 429 errors, reconnect, auth issues, debug logging |
| [How To Use Dhan API With Ruby](docs/HOW_TO_USE_DHAN_API_WITH_RUBY.md) | Search-friendly onboarding guide for Ruby users |
| [Build A Trading Bot With Ruby And Dhan](docs/BUILD_A_TRADING_BOT_WITH_RUBY_AND_DHAN.md) | End-to-end tutorial framing for strategy builders |
| [Dhan API Ruby Examples](docs/DHAN_API_RUBY_EXAMPLES.md) | Small answer-style snippets for common Ruby + Dhan tasks |
| [Dhan WebSocket Ruby Guide](docs/DHAN_WEBSOCKET_RUBY_GUIDE.md) | Query-shaped guide for Dhan market data streaming in Ruby |
| [Best Way To Use Dhan API In Ruby](docs/BEST_WAY_TO_USE_DHAN_API_IN_RUBY.md) | Comparison-focused guide for SDK vs raw HTTP |
| [Dhan Ruby Q&A](docs/DHAN_RUBY_QA.md) | Publish-ready answers for common Dhan + Ruby questions |
| [Release Guide](docs/RELEASE_GUIDE.md) | Versioning, publishing, changelog |

---

## Best Practices

- Keep `on(:tick)` handlers **non-blocking** — push heavy work to a queue/thread
- Use `mode: :quote` for most strategies; `:full` only if you need depth/OI
- Don't exceed **100 instruments per subscribe frame** (auto-chunked by the client)
- Call `DhanHQ::WS.disconnect_all_local!` on shutdown
- Avoid rapid connect/disconnect loops — the client already backs off on 429
- Use dynamic token providers in long-running systems instead of hardcoding expiring tokens

---

## Contributing

PRs welcome! Please include tests for new features. See [CHANGELOG.md](CHANGELOG.md) for recent changes.

```bash
bundle exec rake          # run tests
bundle exec rubocop       # lint
bin/console               # interactive console
```

## Disclaimer

This gem is an independent, community-maintained project and is **not officially affiliated with, endorsed by, or supported by Dhan (Mirae Asset Capital Markets)**. Trading in financial instruments carries significant risk. Use this SDK at your own risk and always verify order placement in a sandbox environment before going live.

## License

[MIT](LICENSE.txt)

# DhanHQ — The Ruby SDK for Dhan API v2

[![Gem Version](https://badge.fury.io/rb/DhanHQ.svg)](https://rubygems.org/gems/DhanHQ)
[![CI](https://github.com/shubhamtaywade82/dhanhq-client/actions/workflows/main.yml/badge.svg)](https://github.com/shubhamtaywade82/dhanhq-client/actions/workflows/main.yml)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-ruby.svg)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE.txt)

Build trading systems in Ruby without fighting raw HTTP, fragile auth flows, or unreliable market streams.

DhanHQ is a production-grade Ruby SDK for the [Dhan trading API](https://dhanhq.co/docs/v2/), designed for:

- trading bots
- real-time market data streaming
- portfolio and order management
- Rails or standalone trading systems

If you're looking for a Ruby SDK for Dhan API, this is built to be the default choice.

Unlike thin wrappers, DhanHQ gives you:

- typed models for orders, positions, holdings, and more
- WebSocket clients with auto-reconnect and backoff
- token lifecycle management with retry-on-401
- safety rails for live trading

This is closer to trading infrastructure than a simple API client.

## Install and Run in 60 Seconds

```ruby
# Gemfile
gem 'DhanHQ'
```

```ruby
require 'dhan_hq'

DhanHQ.configure do |c|
  c.client_id    = ENV["DHAN_CLIENT_ID"]
  c.access_token = ENV["DHAN_ACCESS_TOKEN"]
end

# You're live — no manual HTTP, no JSON parsing
positions = DhanHQ::Models::Position.all
```

---

## Who This Is For

- Ruby developers building trading bots
- Rails apps integrating the Dhan API
- Algo trading systems that need clean abstractions over raw HTTP
- Long-running processes that rely on WebSocket market data

## Who This Is Not For

- One-off scripts where raw HTTP is enough
- Non-Ruby stacks

---

## Start Here (Pick Your Use Case)

Pick the path that matches what you want to build:

- **Get live prices fast** → [Market Feed WebSocket](#market-feed-ticker--quote--full)
- **Place orders safely** → [Order Safety](#order-safety)
- **Build a trading strategy** → [WebSockets](#websockets)
- **Build a trading bot** → [examples/basic_trading_bot.rb](examples/basic_trading_bot.rb)
- **Use with Rails** → [docs/RAILS_INTEGRATION.md](docs/RAILS_INTEGRATION.md)

---

## Trust Signals

- **CI on supported Rubies** — GitHub Actions runs RSpec on Ruby 3.2.0 and 3.3.4, plus RuboCop on every push and pull request
- **Typed domain models** — Orders, Positions, Holdings, Funds, MarketFeed, OptionChain, Super Orders, and more expose a Ruby-first API instead of raw hashes
- **No real API calls in the default test suite** — WebMock blocks outbound HTTP and VCR covers cassette-backed integration paths
- **Auth lifecycle support** — static tokens, dynamic token providers, 401 retry with refresh hooks, and token sanitization in logs
- **WebSocket resilience** — reconnect, backoff, 429 cool-off, local connection cleanup, and dedicated market/order stream clients
- **Live trading guardrails** — order placement is blocked unless `LIVE_TRADING=true`, and order attempts emit structured audit logs

---

## Why Not a Thin Wrapper?

Most API clients give you HTTP access. DhanHQ gives you a working Ruby system.

| Instead of | You get |
| ---------- | -------- |
| JSON parsing and manual field mapping | Typed models |
| Manual auth refresh | Built-in token lifecycle |
| Fragile WebSocket code | Auto-reconnect, backoff, and 429 handling |
| Risky order scripts | Live trading guardrails and audit logs |

---

## Architecture At A Glance

![DhanHQ architecture overview](docs/architecture-overview.svg)

Models own the Ruby API. Resources own HTTP calls. Contracts validate inputs. The transport layer handles auth, retries, rate limiting, and error mapping. WebSockets are a separate subsystem that shares configuration but not the REST stack.

For the full dependency flow and extension pattern, see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## ✨ Key Features

- **ActiveRecord-style models** — `find`, `all`, `where`, `save`, `cancel` across Orders, Positions, Holdings, Funds, and more
- **Auto token refresh** — 401 retry with fresh token via provider callback
- **Thread-safe WebSocket client** — Orders, Market Feed, Market Depth with auto-reconnect
- **Exponential backoff + 429 cool-off** — no manual rate-limit management
- **Secure logging** — automatic token sanitization in all log output
- **Super Orders** — entry + stop-loss + target + trailing jump in one request
- **Instrument convenience methods** — `.ltp`, `.ohlc`, `.option_chain` directly on instruments
- **Order audit logging** — every order attempt logs machine, IP, environment, and correlation ID as structured JSON
- **Live trading guard** — prevents accidental order placement unless `ENV["LIVE_TRADING"]="true"`
- **Full REST coverage** — Orders, Trades, Forever Orders, Super Orders, Positions, Holdings, Funds, HistoricalData, OptionChain, MarketFeed, EDIS, Kill Switch, P&L Exit, Alert Orders, Margin Calculator
- **P&L Based Exit** — automatic position exit on profit/loss thresholds
- **Postback parser** — parse Dhan webhook payloads with `Postback.parse` and status predicates
- **EDIS model** — ORM-style T-PIN, form, and status inquiry for delivery instruction slips

---

## Reliability & Safety

- retry-on-401 with token refresh
- WebSocket auto-reconnect and backoff
- 429 rate-limit protection
- live trading guard via `LIVE_TRADING=true`
- structured order audit logs

See [ARCHITECTURE.md](ARCHITECTURE.md), [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md), and [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for the deeper implementation details.

---

## Installation

```ruby
# Gemfile (recommended)
gem 'DhanHQ'
```

```bash
bundle install
# or
gem install DhanHQ
```

> **Bleeding edge?** Use `gem 'DhanHQ', git: 'https://github.com/shubhamtaywade82/dhanhq-client.git', branch: 'main'` only if you need unreleased features.

**`bundle update` / `bundle install` warnings** — If you see "Local specification for rexml-3.2.8 has different dependencies" or "Unresolved or ambiguous specs during Gem::Specification.reset: psych", the bundle still completes successfully. To clear the rexml warning once, run: `gem cleanup rexml`. The psych message is a known Bundler quirk and can be ignored.

### Gem name vs require path

RubyGems normalizes names, so `DhanHQ` and `dhan_hq` refer to the same slot — the published name stays `DhanHQ` and will never change. The require path has used snake_case since v2.1.5:

```ruby
# Gemfile              # Ruby file
gem 'DhanHQ'           require 'dhan_hq'
```

### Optional features

The core SDK (`require 'dhan_hq'`) only loads the API client. Technical analysis and the options advisor are opt-in:

```ruby
require 'dhan_hq/analysis'  # DhanHQ::Analysis::OptionsBuyingAdvisor, MultiTimeframeAnalyzer
require 'dhan_hq/ta'        # TA::TechnicalAnalysis, TA::Fetcher, TA::Candles
```

---

## Configuration

### Static token (simplest)

```ruby
require 'dhan_hq'
DhanHQ.configure_with_env   # reads DHAN_CLIENT_ID + DHAN_ACCESS_TOKEN from ENV
```

| Variable             | Purpose                                |
| -------------------- | -------------------------------------- |
| `DHAN_CLIENT_ID`     | Your Dhan trading account client ID    |
| `DHAN_ACCESS_TOKEN`  | API token from the Dhan console        |

### Dynamic token (production / OAuth)

```ruby
DhanHQ.configure do |config|
  config.client_id = ENV["DHAN_CLIENT_ID"]
  config.access_token_provider = -> { YourTokenStore.active_token }
  config.on_token_expired = ->(error) { YourTokenStore.refresh! }  # optional
end
```

When the API returns 401, the client retries **once** with a fresh token from your provider.

> **Full details**: TOTP flows, partner mode, token endpoint bootstrap, auto-management — see [docs/AUTHENTICATION.md](docs/AUTHENTICATION.md).

---

## Order Safety

### Live Trading Guard

Order placement (`create`, `slicing`) is blocked unless you explicitly enable it:

```bash
# Production (Render, VPS, etc.)
LIVE_TRADING=true

# Development / Test (default — orders are blocked)
LIVE_TRADING=false   # or simply omit
```

Attempting to place an order without `LIVE_TRADING=true` raises `DhanHQ::LiveTradingDisabledError`.

### Order Audit Logging

Every order attempt (place, modify, slice) automatically logs a structured JSON line at WARN level:

```json
{
  "event": "DHAN_ORDER_ATTEMPT",
  "hostname": "DESKTOP-SHUBHAM",
  "env": "production",
  "ipv4": "122.171.22.40",
  "ipv6": "2401:4900:894c:8448:1da9:27f1:48e7:61be",
  "security_id": "11536",
  "correlation_id": "SCALPER_7af1",
  "timestamp": "2026-03-17T06:45:22Z"
}
```

This tells you instantly which machine, app, IP, and environment placed the order.

### Correlation ID Prefixes

Use per-app prefixes for instant source identification in the Dhan orderbook:

```ruby
# algo_scalper_api
correlation_id: "SCALPER_#{SecureRandom.hex(4)}"

# algo_trader_api
correlation_id: "TRADER_#{SecureRandom.hex(4)}"
```

The Dhan orderbook will show `SCALPER_7af1` or `TRADER_3bc9`, making the source obvious.

---

## REST API

### Orders — Place, Modify, Cancel

```ruby
order = DhanHQ::Models::Order.new(
  transaction_type: DhanHQ::Constants::TransactionType::BUY,
  exchange_segment: DhanHQ::Constants::ExchangeSegment::NSE_FNO,
  product_type: DhanHQ::Constants::ProductType::MARGIN,
  order_type: DhanHQ::Constants::OrderType::LIMIT,
  validity: DhanHQ::Constants::Validity::DAY,
  security_id:      "43492",
  quantity:         50,
  price:            100.0
)
order.save          # places the order
order.modify(price: 101.5)
order.cancel
```

### Positions, Holdings, Funds

```ruby
DhanHQ::Models::Position.all
DhanHQ::Models::Holding.all
DhanHQ::Models::Fund.balance
```

### Historical Data

```ruby
bars = DhanHQ::Models::HistoricalData.intraday(
  security_id:      "13",
  exchange_segment: DhanHQ::Constants::ExchangeSegment::IDX_I,
  instrument: DhanHQ::Constants::InstrumentType::INDEX,
  interval:         "5",
  from_date:        "2025-08-14",
  to_date:          "2025-08-18"
)
```

### Instrument Lookup

```ruby
nifty = DhanHQ::Models::Instrument.find("IDX_I", "NIFTY")
nifty.ltp           # last traded price
nifty.ohlc          # OHLC data
nifty.option_chain(expiry: "2025-02-28")
nifty.intraday(from_date: "2025-08-14", to_date: "2025-08-18", interval: "15")
```

---

## WebSockets

Three real-time feeds, all with **auto-reconnect**, **backoff**, **429 cool-off**, and **thread-safe operation**.

### Order Updates

```ruby
DhanHQ::WS::Orders.connect do |order_update|
  puts "#{order_update.order_no} → #{order_update.status} (#{order_update.traded_qty}/#{order_update.quantity})"
end
```

### Market Feed (Ticker / Quote / Full)

```ruby
client = DhanHQ::WS.connect(mode: :ticker) do |tick|
  puts "#{tick[:security_id]} = ₹#{tick[:ltp]}"
end

client.subscribe_one(segment: DhanHQ::Constants::ExchangeSegment::IDX_I, security_id: "13")   # NIFTY
client.subscribe_one(segment: DhanHQ::Constants::ExchangeSegment::IDX_I, security_id: "25")   # BANKNIFTY
```

### Market Depth

```ruby
reliance = DhanHQ::Models::Instrument.find("NSE_EQ", "RELIANCE")

DhanHQ::WS::MarketDepth.connect(symbols: [
  { symbol: "RELIANCE", exchange_segment: reliance.exchange_segment, security_id: reliance.security_id }
]) do |depth|
  puts "Best Bid: #{depth[:best_bid]} | Best Ask: #{depth[:best_ask]} | Spread: #{depth[:spread]}"
end
```

### Cleanup

```ruby
DhanHQ::WS.disconnect_all_local!   # kills all local WS connections
```

---

## Super Orders

Entry + target + stop-loss + trailing jump in a single request:

```ruby
DhanHQ::Models::SuperOrder.create(
  transaction_type: DhanHQ::Constants::TransactionType::BUY,
  exchange_segment: DhanHQ::Constants::ExchangeSegment::NSE_EQ,
  product_type: DhanHQ::Constants::ProductType::CNC,
  order_type: DhanHQ::Constants::OrderType::LIMIT,
  security_id:      "11536",
  quantity:         5,
  price:            1500,
  target_price:     1600,
  stop_loss_price:  1400,
  trailing_jump:    10
)
```

> **Full API reference** (modify, cancel, list, response schemas): [docs/SUPER_ORDERS.md](docs/SUPER_ORDERS.md)

---

## Real-World Example: NIFTY Trend Monitor

```ruby
require 'dhan_hq'

DhanHQ.configure_with_env

# 1. Check the trend using historical 5-min bars
bars = DhanHQ::Models::HistoricalData.intraday(
  security_id: "13", exchange_segment: DhanHQ::Constants::ExchangeSegment::IDX_I,
  instrument: DhanHQ::Constants::InstrumentType::INDEX, interval: "5",
  from_date: Date.today.to_s, to_date: Date.today.to_s
)

closes = bars.map { |b| b[:close] }
sma_20 = closes.last(20).sum / 20.0
trend  = closes.last > sma_20 ? :bullish : :bearish
puts "NIFTY trend: #{trend} (LTP: #{closes.last}, SMA20: #{sma_20.round(2)})"

# 2. Stream live ticks for real-time monitoring
client = DhanHQ::WS.connect(mode: :quote) do |tick|
  puts "NIFTY ₹#{tick[:ltp]} | Vol: #{tick[:vol]} | #{Time.now.strftime('%H:%M:%S')}"
end
client.subscribe_one(segment: DhanHQ::Constants::ExchangeSegment::IDX_I, security_id: "13")

# 3. On signal, place a super order with built-in risk management
# DhanHQ::Models::SuperOrder.create(
#   transaction_type: DhanHQ::Constants::TransactionType::BUY, exchange_segment: DhanHQ::Constants::ExchangeSegment::NSE_FNO, ...
#   target_price: entry + 50, stop_loss_price: entry - 30, trailing_jump: 5
# )

# 4. Clean shutdown
at_exit { DhanHQ::WS.disconnect_all_local! }
sleep   # keep the script alive
```

---

## Rails Integration

Need initializers, service objects, ActionCable wiring, and background workers? See the [Rails Integration Guide](docs/RAILS_INTEGRATION.md).

---

## Real-World Examples

These scripts are designed around user goals rather than API surfaces:

| Example | Use case |
| ------- | -------- |
| [examples/basic_trading_bot.rb](examples/basic_trading_bot.rb) | Pull historical data, evaluate a simple signal, and place a guarded order |
| [examples/portfolio_monitor.rb](examples/portfolio_monitor.rb) | Snapshot funds, holdings, and positions for a monitoring script |
| [examples/options_watchlist.rb](examples/options_watchlist.rb) | Build a live options watchlist with index quotes and option-chain context |
| [examples/market_feed_example.rb](examples/market_feed_example.rb) | Subscribe to major market indices over WebSocket |
| [examples/live_order_updates.rb](examples/live_order_updates.rb) | Track order lifecycle events in real time |

For search-driven discovery and onboarding content, see:

- [docs/HOW_TO_USE_DHAN_API_WITH_RUBY.md](docs/HOW_TO_USE_DHAN_API_WITH_RUBY.md)
- [docs/BUILD_A_TRADING_BOT_WITH_RUBY_AND_DHAN.md](docs/BUILD_A_TRADING_BOT_WITH_RUBY_AND_DHAN.md)

## Use Case Guides

- [docs/DHAN_API_RUBY_EXAMPLES.md](docs/DHAN_API_RUBY_EXAMPLES.md)
- [docs/DHAN_WEBSOCKET_RUBY_GUIDE.md](docs/DHAN_WEBSOCKET_RUBY_GUIDE.md)
- [docs/BEST_WAY_TO_USE_DHAN_API_IN_RUBY.md](docs/BEST_WAY_TO_USE_DHAN_API_IN_RUBY.md)
- [docs/DHAN_RUBY_QA.md](docs/DHAN_RUBY_QA.md)

---

## 📚 Documentation

| Guide | What it covers |
| ----- | -------------- |
| [Architecture](ARCHITECTURE.md) | Layering, dependency flow, design patterns, extension points |
| [Authentication](docs/AUTHENTICATION.md) | Token flows, TOTP, OAuth, auto-management |
| [Configuration Reference](docs/CONFIGURATION.md) | Full ENV matrix, logging, timeouts, available resources |
| [WebSocket Integration](docs/WEBSOCKET_INTEGRATION.md) | All WS types, architecture, best practices |
| [WebSocket Protocol](docs/WEBSOCKET_PROTOCOL.md) | Packet parsing, request codes, tick schema, exchange enums |
| [Rails WebSocket Guide](docs/RAILS_WEBSOCKET_INTEGRATION.md) | Rails-specific patterns, ActionCable |
| [Rails Integration](docs/RAILS_INTEGRATION.md) | Initializers, service objects, workers |
| [Standalone Ruby Guide](docs/STANDALONE_RUBY_WEBSOCKET_INTEGRATION.md) | Scripts, daemons, and long-running Ruby processes |
| [Super Orders API](docs/SUPER_ORDERS.md) | Full REST reference for super orders |
| [API Constants Reference](docs/CONSTANTS_REFERENCE.md) | All valid enums, exchange segments, and order parameters |
| [Data API Parameters](docs/DATA_API_PARAMETERS.md) | Historical data, option chain parameters |
| [Testing Guide](docs/TESTING_GUIDE.md) | WebSocket testing, model testing, console helpers |
| [Technical Analysis](docs/TECHNICAL_ANALYSIS.md) | Indicators, multi-timeframe aggregation |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | 429 errors, reconnect, auth issues, debug logging |
| [How To Use Dhan API With Ruby](docs/HOW_TO_USE_DHAN_API_WITH_RUBY.md) | Search-friendly onboarding guide for Ruby users |
| [Build A Trading Bot With Ruby And Dhan](docs/BUILD_A_TRADING_BOT_WITH_RUBY_AND_DHAN.md) | End-to-end tutorial framing for strategy builders |
| [Dhan API Ruby Examples](docs/DHAN_API_RUBY_EXAMPLES.md) | Small answer-style snippets for common Ruby + Dhan tasks |
| [Dhan WebSocket Ruby Guide](docs/DHAN_WEBSOCKET_RUBY_GUIDE.md) | Query-shaped guide for Dhan market data streaming in Ruby |
| [Best Way To Use Dhan API In Ruby](docs/BEST_WAY_TO_USE_DHAN_API_IN_RUBY.md) | Comparison-focused guide for SDK vs raw HTTP |
| [Dhan Ruby Q&A](docs/DHAN_RUBY_QA.md) | Publish-ready answers for common Dhan + Ruby questions |
| [Release Guide](docs/RELEASE_GUIDE.md) | Versioning, publishing, changelog |

---

## Best Practices

- Keep `on(:tick)` handlers **non-blocking** — push heavy work to a queue/thread
- Use `mode: :quote` for most strategies; `:full` only if you need depth/OI
- Don't exceed **100 instruments per subscribe frame** (auto-chunked by the client)
- Call `DhanHQ::WS.disconnect_all_local!` on shutdown
- Avoid rapid connect/disconnect loops — the client already backs off on 429
- Use dynamic token providers in long-running systems instead of hardcoding expiring tokens

---

## Contributing

PRs welcome! Please include tests for new features. See [CHANGELOG.md](CHANGELOG.md) for recent changes.

```bash
bundle exec rake          # run tests
bundle exec rubocop       # lint
bin/console               # interactive console
```

## Disclaimer

This gem is an independent, community-maintained project and is **not officially affiliated with, endorsed by, or supported by Dhan (Mirae Asset Capital Markets)**. Trading in financial instruments carries significant risk. Use this SDK at your own risk and always verify order placement in a sandbox environment before going live.

## License

[MIT](LICENSE.txt)

<https://github.com/shubhamtaywade82/ollama-client>

# Ollama::Client

[![CI](https://github.com/shubhamtaywade82/ollama-client/actions/workflows/main.yml/badge.svg)](https://github.com/shubhamtaywade82/ollama-client/actions)
[![Gem Version](https://badge.fury.io/rb/ollama-client.svg)](https://rubygems.org/gems/ollama-client)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.0-ruby.svg)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE.txt)

> **A production-safe Ollama client for Rails & agent systems.**

Not a chatbot UI. Not a 1:1 API wrapper.
A failure-aware, contract-driven client that covers **all 12 Ollama API endpoints** with production guarantees.

**Correctness. Determinism. Failure-aware design. Nothing else.**

## Why This Gem Exists

Other Ollama clients give you raw HTTP access. This one gives you **production guarantees**:

| What goes wrong | What other gems do | What `ollama-client` does |
|---|---|---|
| Model isn't downloaded | Raise error | Auto-pull → retry |
| Ollama server is down | Hang for 60s | Fast-fail instantly |
| LLM returns broken JSON | Crash your parser | Repair prompt → retry |
| Request times out | Raise immediately | Exponential backoff |
| Schema violation | You find out in prod | `SchemaViolationError` before it reaches your code |

## Installation

```ruby
gem "ollama-client"
```

## Quick Start

Works out of the box — all defaults are production-safe:

```ruby
require "ollama_client"

client = Ollama::Client.new
# model: "llama3.2:3b", timeout: 30, retries: 2, strict_json: true
```

### Ollama Cloud Multi-Key Failover

For hosted models on `https://ollama.com`, configure either one API key or a comma-separated key pool. `OLLAMA_API_KEYS` takes precedence over `OLLAMA_API_KEY`; when a cloud request receives HTTP 429, `ollama-client` transparently retries the same request with the next configured key. If every key is rate-limited, the client waits with exponential backoff (`2 ** attempt`) and retries the pool until `config.retries` is exhausted, then raises `Ollama::RateLimitExhaustedError`.

```bash
OLLAMA_BASE_URL=https://ollama.com
OLLAMA_API_KEYS=key_abc123,key_xyz789
ENABLE_MULTI_KEY_CONCURRENCY=false # set true to round-robin initial keys across concurrent threads
```

```ruby
config = Ollama::Config.new
config.base_url = "https://ollama.com"
config.api_keys = ENV["OLLAMA_API_KEYS"] # accepts comma-separated strings or arrays
config.enable_multi_key_concurrency = true

client = Ollama::Client.new(config: config)
client.chat(messages: [{ role: "user", content: "Hello" }], model: "gpt-oss:120b-cloud")
```

For Sidekiq or other highly concurrent agent loops, keep configuration immutable after boot and instantiate clients with per-client `Ollama::Config` objects rather than mutating `OllamaClient.configure` at runtime.

### Chat (Multi-turn Conversations)

The primary endpoint for agentic usage:

```ruby
response = client.chat(
  messages: [
    { role: "system", content: "You are a helpful assistant." },
    { role: "user", content: "What is Ruby?" }
  ]
)

response.message.content  # => "Ruby is a dynamic, open source..."
response.message.role     # => "assistant"
response.done?            # => true
response.done_reason      # => "stop"
response.total_duration   # => 1234567 (nanoseconds)
```

#### Tool Calling

```ruby
messages = [{ role: "user", content: "What is the weather in London?" }]

tools = [
  {
    type: "function",
    function: {
      name: "get_weather",
      description: "Get weather for a city",
      parameters: {
        type: "object",
        properties: { city: { type: "string" } },
        required: ["city"]
      }
    }
  }
]

response = client.chat(messages: messages, tools: tools)
response.message.tool_calls.first.name       # => "get_weather"
response.message.tool_calls.first.arguments  # => { "city" => "London" }
```

#### Structured Output (JSON Schema)

```ruby
messages = [{ role: "user", content: "What is the capital of France? Answer in JSON." }]
schema = { type: "object", properties: { answer: { type: "string" } } }

response = client.chat(messages: messages, format: schema)
JSON.parse(response.message.content)  # => { "answer" => "Paris" }
```

#### Thinking Mode

> **Note:** Requires a thinking-capable model (e.g. `deepseek-coder:6.7b`, `qwen3:0.6b`).

```ruby
messages = [{ role: "user", content: "What is the square root of 144?" }]

response = client.chat(messages: messages, model: "qwen3:0.6b", think: true)
response.message.thinking  # => "Let me reason through this..."
response.message.content   # => "The answer is 12."
```

#### Chat Options

```ruby
messages = [{ role: "user", content: "Hello" }]

client.chat(
  messages: messages,
  model: "qwen2.5-coder:7b",             # Override default model
  options: { temperature: 0.8 }, # Runtime options
  keep_alive: "10m",           # Keep model loaded
  logprobs: true,              # Return log probabilities
  top_logprobs: 5
)
```

### Generate (Prompt → Completion)

```ruby
client.generate(prompt: "Explain Ruby blocks in one sentence.")
# => "Ruby blocks are anonymous closures passed to methods..."
```

#### Structured JSON (Agents / Planners)

```ruby
schema = {
  "type" => "object",
  "required" => ["action", "confidence"],
  "properties" => {
    "action" => { "type" => "string", "enum" => ["search", "calculate", "finish"] },
    "confidence" => { "type" => "number" }
  }
}

result = client.generate(prompt: "User wants weather in Paris.", schema: schema)
result["action"]     # => "search"
result["confidence"] # => 0.95
```

If the LLM returns invalid JSON, the client automatically retries with a repair prompt. You get valid output or a typed exception — never a silent failure.

#### Structured Thinking (Zero-Magic CoT extraction)

You can ask reasoning models to output their thoughts separately from the final answer. `ollama-client` enforces this via strict JSON schema prompting.

> **Note:** Requires a thinking model. Supported defaults: `/deepseek/i`, `/qwen/i`, `/r1/i`.

```ruby
schema = {
  "type" => "object",
  "required" => ["decision"],
  "properties" => {
    "decision" => { "type" => "string" }
  }
}

result = client.generate(
  model: "deepseek-r1",
  prompt: "Should we BUY or WAIT?",
  schema: schema,
  think: true,
  return_reasoning: true
)

result["reasoning"]          # => "...step by step analysis..."
result["final"]["decision"]  # => "WAIT"
```

#### Generate Options

```ruby
client.generate(
  prompt: "Write a poem",
  model: "qwen3:0.6b",               # Explicitly use a thinking model
  system: "You are a poet",          # System prompt
  think: true,                       # Thinking output
  keep_alive: "5m",                  # Keep model loaded
  options: { temperature: 0.8 }      # Runtime options
)
```

### Streaming (Observer Hooks)

No raw SSE. No state corruption risk. Works with both `chat` and `generate`:

```ruby
# Stream generate tokens
client.generate(
  prompt: "Write a haiku about code.",
  hooks: {
    on_token:    ->(token) { print token },
    on_error:    ->(err)   { warn err.message },
    on_complete: ->        { puts "\nDone" }
  }
)

# Stream chat tokens with log probabilities
client.chat(
  messages: [{ role: "user", content: "Tell me a story" }],
  logprobs: true,
  hooks: {
    # If your block takes 2 args, it receives the logprobs array for that token
    on_token: ->(token, logprobs) {
      print token
      # logprobs is an Array of Hashes, e.g. [{"token"=>"Once", "logprob"=>-0.12}, ...]
    },
    on_complete: -> { puts }
  }
)
```

### Embeddings (RAG)

```ruby
client.embeddings.embed(model: "nomic-embed-text:latest", input: "What is Ruby?")
# => [0.12, -0.05, 0.88, ...]

# Batch embeddings
client.embeddings.embed(model: "nomic-embed-text:latest", input: ["text1", "text2"])

# With options
client.embeddings.embed(
  model: "nomic-embed-text:latest",
  input: "text",
  truncate: true,        # Truncate long inputs
  dimensions: 256,       # Embedding dimensions
  keep_alive: "5m"       # Keep model loaded
)
```

### Model Management

```ruby
client.list_models              # Returns models with details & automatic capabilities map
# => [{ "name" => "llama3.1", "capabilities" => { "tools" => true, "thinking" => false, ... }, ... }]
client.list_model_names         # Just names: ["qwen2.5-coder:7b", "llama3.2:3b", ...]
client.list_running             # Currently loaded models (aliased as `ps`)
client.show_model(model: "qwen2.5-coder:7b")           # Model details, capabilities
client.show_model(model: "qwen2.5-coder:7b", verbose: true)  # Include model_info
client.pull("llama3.2:3b")                      # Download a model
client.delete_model(model: "old-model")      # Remove a model
client.copy_model(source: "qwen2.5-coder:7b", destination: "qwen2.5-coder:7b-backup")
client.create_model(model: "my-model", from: "qwen2.5-coder:7b", system: "You are Alpaca")
client.push_model(model: "user/my-model")    # Push to registry
client.version                               # => "0.12.6"
```

### Runtime Options

Pass via `options:` on `chat` or `generate`:

```ruby
messages = [{ role: "user", content: "Tell me a joke" }]

options = Ollama::Options.new(
  temperature: 0.7,
  num_predict: 256,
  stop: ["END"],
  presence_penalty: 0.5,
  frequency_penalty: -0.3
)

client.chat(messages: messages, options: options.to_h)
```

<details>
<summary>All supported options</summary>

| Option | Type | Description |
|---|---|---|
| `temperature` | Float (0–2) | Sampling temperature |
| `top_p` | Float (0–1) | Nucleus sampling |
| `top_k` | Integer | Top-K sampling |
| `num_ctx` | Integer | Context window size |
| `num_predict` | Integer | Max tokens to generate |
| `repeat_penalty` | Float (0–2) | Repeat penalty |
| `seed` | Integer | Random seed |
| `stop` | Array | Stop sequences |
| `tfs_z` | Float | Tail-free sampling |
| `mirostat` | 0/1/2 | Mirostat sampling mode |
| `mirostat_tau` | Float | Mirostat target entropy |
| `mirostat_eta` | Float | Mirostat learning rate |
| `typical_p` | Float (0–1) | Typical-p sampling |
| `presence_penalty` | Float (-2–2) | Presence penalty |
| `frequency_penalty` | Float (-2–2) | Frequency penalty |
| `num_gpu` | Integer | GPU layers |
| `num_thread` | Integer | CPU threads |
| `num_keep` | Integer | Tokens to keep for context |

</details>

## CLI

A strict, JSON-first CLI ships with the gem:

```bash
# Generate text
ollama-client generate --prompt "Explain Ruby blocks"

# Structured output with schema
echo '{"type":"object","properties":{"category":{"type":"string"}}}' > schema.json
ollama-client generate --prompt "Classify this" --schema schema.json --json

# Stream tokens
ollama-client generate --prompt "Write a poem" --stream

# Embeddings
ollama-client embed --input "What is Ruby?" --model nomic-embed-text:latest

# List models
ollama-client models

# Pull a model
ollama-client pull llama3.2:3b
```

All errors output as structured JSON to stderr. No hidden behavior.

## Console (Debug Mode)

```bash
bin/console
```

```ruby
verbose!  # Enable HTTP request/response logging
quiet!    # Disable it

client = Ollama::Client.new
client.version  # Prints full HTTP request/response to STDERR
```

## Failure Behaviors

| Scenario | What happens |
|---|---|
| **Model missing (404)** | Auto-pull → retry your request |
| **Server unreachable** | Instant `Ollama::Error` — no waiting |
| **Timeout** | Exponential backoff (`2^attempt` seconds) |
| **Invalid JSON** | Repair prompt → retry → `InvalidJSONError` if exhausted |
| **Schema violation** | Repair prompt → retry → `SchemaViolationError` if exhausted |
| **Streaming error** | `StreamError` raised with Ollama's error message |

## v1.0 Stability Contract

The public API is locked. See [API_CONTRACT.md](API_CONTRACT.md) for the full specification.

1. All method signatures are stable until v2.0
2. Error class hierarchy is stable until v2.0
3. Recovery behaviors (auto-pull, backoff, repair) are guaranteed
4. No silent coercion of malformed JSON — ever
5. Typed errors over generic exceptions — always

## Testing

```bash
# Unit + lint
bundle exec rake

# Integration (requires running Ollama)
OLLAMA_INTEGRATION=1 bundle exec rspec spec/integration/
```

## License

MIT. See [LICENSE.txt](LICENSE.txt).

## OpenAI-Compatible Facade (Optional Extension)

OpenAI compatibility is intentionally isolated from the core runtime.
Load it explicitly when needed:

```ruby
require "ollama_client"
require "ollama/openai"

client = Ollama::Client.new

client.openai.models.list
client.openai.chat.completions.create(
  model: "qwen2.5-coder:7b",
  messages: [{ role: "user", content: "hello" }]
)
client.openai.completions.create(model: "llama3.2:3b", prompt: "Write one line")
client.openai.embeddings.create(model: "nomic-embed-text", input: "ruby")
```

## Raw Endpoint Escape Hatch (New)

Access unsupported and future endpoints without waiting for wrapper updates:

```ruby
client = Ollama::Client.new

client.raw.post("/api/chat", payload: {
  model: "llama3.2:3b",
  messages: [{ role: "user", content: "hello" }],
  stream: false
})
```

## Transport Adapter (Foundation)

The client now resolves HTTP through a transport adapter boundary.
Default remains Net::HTTP, and the API is forward-compatible with future adapters.

```ruby
config = Ollama::Config.new
config.transport_adapter = :net_http
client = Ollama::Client.new(config: config)
```

Transport internals now normalize responses through a transport response object
(`status`, `headers`, `body`, `duration_ms`) to support future adapters and observability.
A stream transport contract (`transport.stream`) is also defined as the next expansion point.

### Mock transport (testing)

For deterministic tests without a live Ollama server:

```ruby
config = Ollama::Config.new
config.transport_adapter = :mock
client = Ollama::Client.new(config: config)

transport = client.instance_variable_get(:@transport)
transport.enqueue(status: 200, body: '{"version":"0.0.0-test"}')
client.version # => "0.0.0-test"
```

### Error taxonomy foundation

Runtime now includes explicit typed transport/runtime errors such as:
`UnauthorizedError`, `ModelUnavailableError`, `ConnectionFailedError`, and
`MalformedResponseError` for safer retry and policy layering.

<https://github.com/shubhamtaywade82/ollama_agent>

# ollama_agent

Version: 1.0.0

Ruby gem that runs a **CLI coding agent** against a local [Ollama](https://ollama.com) model. It exposes tools to **list files**, **read files**, **search the tree** (ripgrep or grep), and **apply unified diffs** so the model can make small, reviewable edits.

## Contents

- [Features](#features)
- [Kernel runtime (deterministic execution)](#kernel-runtime-deterministic-execution) — see also [CAPABILITIES](docs/CAPABILITIES.md), [CLI](docs/CLI.md), [OPERATIONS](docs/OPERATIONS.md), [USAGE](docs/USAGE.md)
- [Requirements](#requirements)
- [Security and sandbox](#security-and-sandbox)
- [Installation](#installation)
- [Usage](#usage)
  - [Agentic tool calling](#agentic-tool-calling-local-environment-tools)
- [Skills](#skills-deterministic-json-contract-pipelines)
- [Troubleshooting](#troubleshooting)
- [How it works](#how-it-works)
- [Development](#development)
- [License](#license)

## Features

- Tool `list_files` – list project files.
- Tool `read_file` – read file contents.
- Tool `search_code` – search code with ripgrep or grep.
- Tool `edit_file` – apply unified diffs safely.
- Tool `list_directory_contents` – sandboxed filesystem inspection; see [Agentic tool calling](#agentic-tool-calling-local-environment-tools).
- Tool `calculate` – safe arithmetic evaluator (Shunting-yard, no `eval`); see [Agentic tool calling](#agentic-tool-calling-local-environment-tools).
- CLI built with Thor, entry point `exe/ollama_agent`.
- **`self_review`** – self-review / improvement with a **`--mode`**:
  - **`analysis`** (default, alias `1`) — read-only tools; report only; no writes.
  - **`interactive`** (alias `2`, `fix`) — full tools on `--root`; you confirm each patch (like `ask`); optional `-y` / `--semi`.
  - **`automated`** (alias `3`, `sandbox`) — temp copy, agent edits, **`bundle exec rspec`** in the sandbox, optional **`--apply`** to merge into your checkout.
- **`improve`** — same as **`self_review --mode automated`** (you can pass **`--mode automated`** explicitly; other modes belong on **`self_review`**).
- **`orchestrate`** / **`OLLAMA_AGENT_ORCHESTRATOR=1`** — optional **orchestrator** tools to probe and delegate to other local CLI agents (see [Orchestrator](#orchestrator-external-cli-agents)); **`agents`** lists availability.
- **Ruby API** — embed **`Runner`**, **`Agent`**, custom tools, hooks, sessions, and (optionally) **`ToolRuntime`**; see [Library usage (Ruby)](#library-usage-ruby).

## Kernel runtime (deterministic execution)

**Documentation (post-kernel):** [Capability matrix](docs/CAPABILITIES.md) · [CLI reference](docs/CLI.md) · [Operations / incidents](docs/OPERATIONS.md) · [Usage guide](docs/USAGE.md).

The **runtime kernel** is an optional execution layer behind `OLLAMA_AGENT_KERNEL`. It wraps file mutations in a **saga-style finite state machine**: intent reservation, **atomic writes** (CAS + pre-image hashes), ownership checks against compiled rules, **SQLite-backed WAL** and sagas, isolated post-mutation validation, and compensation on failure. The workspace root remains the **trust boundary**; the kernel adds structured **ownership** and **fencing** so replays and automation stay auditable. When cloud or validator paths fail, **circuit-breaker style** escalation limits (see the rollout runbook) keep bad states from compounding.

| `OLLAMA_AGENT_KERNEL` | Behavior |
| --- | --- |
| unset / `false` (default) | Legacy tool paths; kernel pipeline is not used for tool routing. |
| `shadow` | Same routing as `true`, but the pipeline runs in **shadow** mode: saga + WAL + observability run, while workspace bytes for certain mutations stay off the “real” path (see runbook). |
| `true` / `1` | Tool intents for configured mutation tools go through **`OllamaAgent::Runtime::KernelPipeline`**. |

**Quick start (kernel on):**

```bash
OLLAMA_AGENT_KERNEL=true bundle exec ollama_agent ask "Your task"
```

Design notes and roadmap items live in **`docs/new_features_plan_v2.md`**. Operational rollout, shadow mode, and rollback expectations are in **`docs/agile/release_rollout_runbook.md`** (incident SQL, health JSON, and compaction details are expanded in **`docs/OPERATIONS.md`**). For **E7 validator activation** (Docker-backed isolated checks), see **`docs/agile/docker_spec_activation.md`**.

**Compaction and disk bounds:** long-lived workspaces accumulate kernel SQLite rows and content-addressed blobs. Use **`OllamaAgent::Runtime::Compactor`** (logical `current_epoch` only — no wall clock) to prune sealed sagas, cold-archive old WAL rows into `event_store_archive.db`, purge expired recovery leases and stale intent reservations, and unlink blob files not referenced by compensations or in-flight mutation WAL payloads. **`OllamaAgent::Runtime::CompactorRunner`** wraps the compactor with an epoch interval for daemon loops (opt-in; nothing starts automatically).

**Permission unification:** when `OLLAMA_AGENT_KERNEL` is on and `config/ollama_agent/owners.yml` exists, **`OllamaAgent::Runtime::PermissionBridge`** reconciles legacy **`Runtime::Permissions` / `Runtime::Policies`** with **`Security::OwnershipIndex`** + **`CriticalityPolicy`** before pipeline execution. On divergence the bridge logs and **prefers the kernel decision** (stricter path wins). `OllamaAgent::PermissionConflictError` is raised only by the strict `#allow_mutation?` API for tests and diagnostics. With the kernel **off**, only the legacy permission path runs (no bridge).

## Requirements

- Ruby ≥ 3.2 (enforced in the gemspec as `required_ruby_version`)
- **Runtime kernel (SQLite):** the **sqlite3** gem is a runtime dependency; kernel storage uses `event_store.db` and `runtime.db` under `.ollama_agent/kernel/` in the configured project root.
- **Local:** Ollama running and a capable tool-calling model, **or**
- **Ollama Cloud:** API key and a cloud-capable model name (see below)

### Prerequisites (external tools)

- **`patch`** — required for `edit_file` (GNU `patch` on `PATH`). On Windows, use Git Bash, WSL, GnuWin32, or another environment that provides `patch`.
- **`rg` (ripgrep) or `grep`** — text mode for `search_code` needs at least one of these on `PATH` (ripgrep is preferred when present).

## Security and sandbox

- **Project root** — File tools and search are constrained to the configured workspace (`--root` / `OLLAMA_AGENT_ROOT`). Treat that directory as the trust boundary: only aim the agent at trees you are willing to modify.
- **`list_directory_contents`** — Paths are resolved with `File.expand_path` relative to the project root and rejected before the filesystem is touched if they escape that boundary. `../../etc`, `/etc`, and any other traversal are caught by a prefix check, not a regex.
- **`calculate`** — Uses a hand-written tokenizer and Shunting-yard evaluator. `eval` is never called. Only numeric literals and the operators `+`, `-`, `*`, `/`, `**` are accepted; any other character is an error.
- **`run_shell` (optional tool)** — Commands are parsed into an argument vector (no shell) and must match an allowlist; a denylist blocks obviously dangerous patterns. You can still shoot yourself in the foot with an allowed prefix (for example `git` with destructive subcommands), so keep profiles and permissions tight in automated setups.
- **Timeouts** — Text search honors `OLLAMA_AGENT_SEARCH_TIMEOUT_SEC` (default 120). Shell execution has its own per-invocation timeout.
- **Logging** — Budget, loop-detection, and `list_local_model_names` failures go through Ruby’s `Logger` (stderr by default). Set `OLLAMA_AGENT_LOG_LEVEL=debug` or `OLLAMA_AGENT_DEBUG=1` for more detail.

## Installation

From RubyGems (when published) or from this repository:

```bash
bundle install
```

## Usage

**Default:** run the gem with **no subcommand** to open the **interactive TUI** (same as `ask` with no query):

```bash
ollama_agent
# or from this repo:
bundle exec ruby exe/ollama_agent
```

Other entry points are **opt-in**: pass a **subcommand** (`self_review`, `sessions`, …) or **`ask` / `orchestrate`** with a **query** for a one-shot task, or flags for a plain line REPL (see below).

From the project you want the agent to modify (set the working directory accordingly):

```bash
bundle exec ruby exe/ollama_agent ask "Update the README.md with current codebase"
```

From this repository after `bundle install`, `ruby exe/ollama_agent` (without `bundle exec`) also works: the executable adds `lib` to the load path and loads `bundler/setup` when a `Gemfile` is present.

Apply proposed patches without interactive confirmation:

```bash
bundle exec ruby exe/ollama_agent ask -y "Your task"

# Review / audit only (no patches, writes, or delegation)—same as a report-style self_review
bundle exec ruby exe/ollama_agent ask --read-only "Summarize risks in this repo"
```

Long-running models (slow local inference):

```bash
bundle exec ruby exe/ollama_agent ask --timeout 300 "Your task"
```

### Agent budget (steps, tokens, cost)

Each **model round-trip** that runs during a session counts as one **step** toward `OLLAMA_AGENT_MAX_TURNS` (default **64**), enforced together with token and optional cost limits in `OllamaAgent::Core::Budget`. Exploratory tasks that **list, read, and search** across a **large repository** can burn through steps quickly; if you see `budget exceeded — step limit (64)`, raise the limit—for example:

```bash
export OLLAMA_AGENT_MAX_TURNS=128
bundle exec ruby exe/ollama_agent ask "Your wide-ranging task"
```

Narrower prompts, **`--read-only`**, or a smaller `--root` also reduce step usage. With **`OLLAMA_AGENT_DEBUG=1`**, the agent prints an extra hint when the **maximum tool rounds** for a run are reached.

### `search_code` and regex patterns

In **text** mode, the tool passes your pattern to **ripgrep** (or **grep**). Patterns are **regular expressions**: literal parentheses, brackets, and unbalanced groups can trigger errors (for example `unclosed group`). Escape metacharacters or use **fixed-string** mode when your tool schema exposes it.

**Plain line REPL** (no TUI boxes / markdown shell): use **`ask` (or `orchestrate`) with `-i` and without `--tui`**—for example when you omit the query you must opt out of the default TUI this way:

```bash
bundle exec ruby exe/ollama_agent ask --interactive
# same idea: explicit -i, no --tui
```

Self-review modes (default project root is the **current working directory** unless you set `--root` or `OLLAMA_AGENT_ROOT`):

```bash
# Mode 1 — analysis only (default)
bundle exec ruby exe/ollama_agent self_review
bundle exec ruby exe/ollama_agent self_review --mode analysis

# Mode 2 — optional fixes in the working tree (confirm each patch, or -y / --semi)
bundle exec ruby exe/ollama_agent self_review --mode interactive

# Mode 3 — sandbox + tests + optional merge back (same as `improve`)
# Without --apply, edits stay in a temp dir only; pass --apply to copy changed files into your checkout.
bundle exec ruby exe/ollama_agent self_review --mode automated
bundle exec ruby exe/ollama_agent self_review --mode automated --apply
bundle exec ruby exe/ollama_agent improve --apply
```

**`ruby_mastery` (optional):** When the [`ruby_mastery`](https://github.com/shubhamtaywade82/ruby_mastery) gem is installed (this repo lists it in the `Gemfile` for development), **`self_review`** (all modes) and **`improve`** prepend a **markdown static-analysis** section to the user prompt. Add the same gem to your app’s `Gemfile` if you want that behavior outside this checkout. Disable with **`--no-ruby-mastery`** or **`OLLAMA_AGENT_RUBY_MASTERY=0`**. Limit size with **`OLLAMA_AGENT_RUBY_MASTERY_MAX_CHARS`** (default `60000`).

For mode 3, `-y` skips all patch prompts; `--no-semi` prompts for every patch when not using `-y`.

### Reasoning / thinking output

On [thinking-capable models](https://docs.ollama.com/capabilities/thinking), Ollama can return **reasoning** separately from the final answer (`message.thinking` vs `message.content`). The CLI labels them **Thinking** (dim) and **Assistant** (green / Markdown).

#### Enable `think` on the request

The agent sends Ollama’s `think` field only when you set it (CLI or env). If you omit it, the server uses its own defaults—and some models then omit or change reasoning in the response.

| You want | CLI | Environment |
|----------|-----|-------------|
| Reasoning on (typical Qwen / DeepSeek-style) | `--think true` | `OLLAMA_AGENT_THINK=true` or `1` |
| Reasoning off | `--think false` | `OLLAMA_AGENT_THINK=false` or `0` |
| **GPT-OSS** style levels | `--think low`, `medium`, or `high` | `OLLAMA_AGENT_THINK=medium` (example) |

Examples:

```bash
OLLAMA_AGENT_THINK=true bundle exec ruby exe/ollama_agent ask -i
bundle exec ruby exe/ollama_agent ask -i --think true
# GPT-OSS: prefer a level, not only true/false
bundle exec ruby exe/ollama_agent ask --think medium "Your task"
```

#### Streaming vs one-shot (default)

| Mode | Flags | What you see |
|------|--------|----------------|
| **One-shot** (default) | neither `--stream` nor `OLLAMA_AGENT_STREAM=1` | Each model round completes over HTTP; **Thinking** / **Assistant** are printed from the assembled **`message`** (including Gemma-style reasoning tags stripped from `content` when the API omits `thinking`). |
| **Streaming** | `--stream` or `OLLAMA_AGENT_STREAM=1` | Reasoning streams in **dim** text under one **Thinking** line, then **Assistant** and the reply stream—similar to Cursor. Uses `hooks[:on_thinking]` on the ollama-client chat stream (see `OllamaAgent::OllamaChatThinkingStreamPatch`). |

```bash
OLLAMA_AGENT_THINK=medium OLLAMA_AGENT_STREAM=1 bundle exec ruby exe/ollama_agent ask "Your task"
```

**Note:** Subscribing only to `on_thinking` does **not** enable the streaming chat path; the agent uses streaming when something listens for **`on_token`** (the console streamer registers both). See CHANGELOG **1.0.0** if you embed the library.

#### Display style (TTY)

By default **`OLLAMA_AGENT_THINKING_STYLE=compact`**: one **Thinking** header per `ask` run; later reasoning chunks in the same run are separated by **blank lines** only (including after tool rounds). **`OLLAMA_AGENT_THINKING_STYLE=framed`** repeats the full boxed banner per message. Thinking body is **plain dim** unless **`OLLAMA_AGENT_THINKING_MARKDOWN=1`**.

The CLI uses **ANSI colors** on a TTY (banner, prompt, patch prompts). **Assistant** replies use **Markdown** via `tty-markdown` when stdout is a TTY and **`NO_COLOR`** is unset. Disable Markdown with **`OLLAMA_AGENT_MARKDOWN=0`**; disable colors with **`NO_COLOR`** or **`OLLAMA_AGENT_COLOR=0`**.

#### If you see no **Thinking** block

1. **Set `think` explicitly**—especially for **GPT-OSS** (`low` / `medium` / `high`).
2. **Confirm the model returns `message.thinking`** (e.g. `curl` / `ollama` CLI against `/api/chat` with the same `think` value). If the API never sends `thinking`, the agent has nothing to show.
3. **Try streaming** (`--stream` or `OLLAMA_AGENT_STREAM=1`) if you want live reasoning tokens.
4. **Embedded reasoning in `content`:** Some templates (e.g. Gemma) put tags such as `<|channel>thought` … `<channel|>` or `<redacted_thinking>` … `</redacted_thinking>` inside `content`. The agent strips those into **Thinking** when present (`OllamaAgent::GemmaThoughtContentParser`). If your model uses different delimiters, reasoning may stay inside the main reply until parsers are extended.

#### Ruby API

```ruby
OllamaAgent::Runner.build(stream: true, think: "medium").run("Your task")
```

Custom subscribers can attach to **`hooks[:on_thinking]`** and **`hooks[:on_token]`** on the same **`Runner`** instance (see `OllamaAgent::Streaming::Hooks`).

### Ollama Cloud

[Ollama Cloud](https://docs.ollama.com/cloud) uses the same HTTP API as the local server, with HTTPS and a Bearer API key. The **ollama-client** gem sends `Authorization: Bearer <api_key>` when `Ollama::Config#api_key` is set (HTTPS is used when the URL scheme is `https`).

1. Create a key at [ollama.com/settings/keys](https://ollama.com/settings/keys).
2. Point the agent at the cloud host and pass the key (same env names as ollama-client’s docs):

```bash
export OLLAMA_BASE_URL="https://ollama.com"
export OLLAMA_API_KEY="your_key"
export OLLAMA_AGENT_MODEL="gpt-oss:120b-cloud"   # example; pick a cloud model from `ollama list` / the catalog
# Reasoning for GPT-OSS: set a level (see "Reasoning / thinking output" above)
export OLLAMA_AGENT_THINK=medium
bundle exec ruby exe/ollama_agent ask "Your task"
```

#### Multi-Key Provider Credential Orchestration & Failover

To handle rate limits (RPM/TPM window exhaustion), daily quotas, or network timeouts when using Ollama Cloud (or other providers like OpenAI and Anthropic), you can configure a thread-safe, quota-aware **Credential Pool** with automatic reactive failover.

The pool can be configured dynamically via the Ruby API or auto-detected from environment variables.

##### Environment Auto-Detection

If no explicit credentials are passed in, `ollama_agent` automatically scans the environment for keys indexed `1` to `5` and initializes a `CredentialPool`:

- **Ollama Cloud**: Configure keys `OLLAMA_API_KEY_1` through `OLLAMA_API_KEY_5`. When any of these are present, requests are routed to `"https://api.ollama.com"` (aliased as `"ollama_cloud"`).
- **OpenAI**: Configure keys `OPENAI_API_KEY_1` through `OPENAI_API_KEY_5`.
- **Anthropic**: Configure keys `ANTHROPIC_API_KEY_1` through `ANTHROPIC_API_KEY_5`.

Example for Ollama Cloud:

```bash
export OLLAMA_API_KEY_1="ollama_key_abc123"
export OLLAMA_API_KEY_2="ollama_key_def456"
bundle exec ruby exe/ollama_agent ask "Your task"
```

##### Ruby API Configuration

You can also pass a structured array of credential hashes to `OllamaAgent::Runner.build`:

```ruby
runner = OllamaAgent::Runner.build(
  credentials: [
    {
      id: "ollama-cloud-primary",
      provider: "ollama_cloud",
      api_key: "ollama_...",
      weight: 2, # weighted round-robin priority (default: 1)
      limits: { rpm: 10, tpm: 10000, daily_tokens: 1000000 } # automatic quota tracking
    },
    {
      id: "openai-backup",
      provider: "openai",
      api_key: "sk-...",
      weight: 1
    }
  ]
)
runner.run("Your task")
```

##### Failover Behavior

1. **Weighted Round-Robin**: Requests are balanced across healthy and available credentials.
2. **Quota Tracking**: Daily token/request and RPM/TPM sliding windows are tracked locally.
3. **Reactive Failover**: If a key encounters a rate limit (`HTTP 429`), temporary provider error (`HTTP 5xx`), or quota exhaustion, it is temporarily cooled down and the request is retried with the next available key.
4. **Permanent Disabling**: If a key encounters an authentication failure (`HTTP 401` or `HTTP 403`), it is permanently disabled to prevent dead-key hammering.

### Environment

| Variable | Purpose |
|----------|---------|
| `OLLAMA_BASE_URL` | Ollama API base URL (default from ollama-client: `http://localhost:11434`; use `https://ollama.com` for cloud) |
| `OLLAMA_API_KEY` | API key for Ollama Cloud (`https://ollama.com`); optional for local HTTP |
| `OLLAMA_AGENT_MODEL` | Model name (overrides default from ollama-client) |
| `OLLAMA_AGENT_ROOT` | Project root for tools (`list_files`, `read_file`, etc.). Defaults to **current working directory** when unset (CLI never falls back to the gem install path). |
| `OLLAMA_AGENT_DEBUG` | Set to `1` to print validation diagnostics on stderr |
| `OLLAMA_AGENT_STRICT_ENV` | Set to `1` so invalid numeric env values (e.g. `OLLAMA_AGENT_MAX_TURNS`) raise `ConfigurationError` instead of falling back to defaults |
| `OLLAMA_AGENT_MAX_TURNS` | Max chat rounds with tool calls (default: 64) |
| `OLLAMA_AGENT_TIMEOUT` | HTTP read/open timeout in seconds for Ollama requests (default **120**; use `ask --timeout` / `-t` to override per run) |
| `OLLAMA_AGENT_PARSE_TOOL_JSON` | Set to `1` to run tools parsed from JSON lines in assistant text (fallback when the model

## Objective

Build a **single-user retail quant platform** that behaves like a small investment firm:

- Long-term investing (3–10 years)
- Swing trading (days to months)
- Portfolio rebalancing
- Autonomous research
- AI-assisted decision making
- Automated execution through DhanHQ
- Full audit trail and risk controls

You already own the three most important building blocks:

- [DhanHQ Ruby SDK](https://github.com/shubhamtaywade82/dhanhq-client?utm_source=chatgpt.com)
- [ollama-client](https://github.com/shubhamtaywade82/ollama-client?utm_source=chatgpt.com)
- [ollama_agent](https://github.com/shubhamtaywade82/ollama_agent?utm_source=chatgpt.com)

The mistake most retail traders make is:

```text
Indicators
   ↓
AI
   ↓
Buy/Sell
```

That architecture is garbage.

Professional systems separate:

```text
Research
↓
Signal Generation
↓
Portfolio Construction
↓
Risk Engine
↓
Execution Engine
↓
Monitoring
↓
Post Trade Analytics
```

---

# High-Level Architecture

```text
┌──────────────────────────────────────┐
│           Rails Monolith             │
│        (Control Plane / UI)          │
└──────────────────────────────────────┘

                │
                ▼

┌──────────────────────────────────────┐
│            PostgreSQL                │
│                                      │
│ instruments                          │
│ ohlcv                                │
│ indicators                           │
│ watchlists                           │
│ investment_plans                     │
│ portfolios                           │
│ positions                            │
│ orders                               │
│ signals                              │
│ ai_decisions                         │
│ risk_events                          │
│ backtests                            │
└──────────────────────────────────────┘

                │
                ▼

┌──────────────────────────────────────┐
│          Resque Workers              │
└──────────────────────────────────────┘

   │          │          │
   ▼          ▼          ▼

Market      AI       Execution
Workers   Workers     Workers

```

---

# Layer 1 — Market Data Layer

## Sources

DhanHQ

```ruby
DhanHQ::Models::HistoricalData
DhanHQ::WS.connect
DhanHQ::Models::Instrument
```

Store:

```sql
ohlcv_daily
ohlcv_weekly
ohlcv_monthly

market_breadth
sector_strength
```

### Daily Job

```ruby
FetchHistoricalDataJob
```

Runs:

```text
After Market Close
```

Updates:

```text
NSE 500
NIFTY 50
NIFTY NEXT 50
MIDCAP 150
SMALLCAP 250
```

---

# Layer 2 — Technical Analysis Engine

Use DhanHQ TA module.

Generate:

```text
EMA 20
EMA 50
EMA 200

RSI
MACD
ATR
ADX

Bollinger Bands
VWAP
Volume Profile
```

Store snapshot.

```ruby
IndicatorSnapshot
```

Example:

```json
{
  "symbol":"RELIANCE",
  "ema50":1450,
  "ema200":1390,
  "rsi":62,
  "adx":28
}
```

---

# Layer 3 — Fundamental Research Engine

For long-term investing.

Collect:

```text
Revenue Growth
Profit Growth
ROE
ROCE
Debt/Equity
FCF
Promoter Holding
FII/DII Activity
```

Store:

```ruby
FundamentalSnapshot
```

AI should NEVER decide from price alone.

---

# Layer 4 — AI Research Layer

This is where Ollama comes in.

## Models

Fast model:

```text
gpt-oss:20b-cloud
qwen3
```

Deep research:

```text
gpt-oss:120b-cloud
deepseek-r1
```

via:

```ruby
Ollama::Client
```

---

## Research Agent

Input:

```json
{
  "symbol":"RELIANCE",
  "fundamentals":{},
  "technicals":{},
  "sector_data":{},
  "news":[]
}
```

Output:

```json
{
  "rating":"BUY",
  "confidence":84,
  "risk":"LOW",
  "holding_period":"LONG_TERM",
  "reasoning":[]
}
```

Store:

```ruby
AiResearchReport
```

---

# Layer 5 — Strategy Engine

Separate strategies.

Never mix them.

---

## Strategy A

Long-Term Investing

Criteria:

```text
Revenue CAGR > 15%

ROCE > 15%

Debt/Equity < 0.5

EMA200 Uptrend

RSI > 50
```

Output:

```text
BUY
ACCUMULATE
HOLD
EXIT
```

---

## Strategy B

Swing Trading

Criteria:

```text
EMA20 > EMA50

ADX > 25

Volume Spike

Breakout

Relative Strength
```

Holding:

```text
3–30 Days
```

---

## Strategy C

Sector Rotation

Track:

```text
IT
BANKING
PHARMA
AUTO
FMCG
PSU
```

Allocate capital dynamically.

---

# Layer 6 — Portfolio Construction

This is where most systems fail.

Signal ≠ Order

Example:

```text
Capital = ₹10,00,000
```

Investment:

```text
60%
```

Swing:

```text
30%
```

Cash:

```text
10%
```

---

### Investment Bucket

```text
Max Stock = 10%
```

Example:

```text
RELIANCE 10%
TCS 10%
HDFCBANK 10%
```

---

### Swing Bucket

Risk:

```text
1%
account risk
per trade
```

Position size:

```ruby
quantity =
risk_amount /
(entry-stoploss)
```

---

# Layer 7 — Risk Engine

Most important component.

Without this:

```text
You don't have a system.
You have gambling automation.
```

---

## Risk Rules

### Daily

```text
Max Daily Drawdown = 3%
```

### Weekly

```text
Max Weekly Drawdown = 6%
```

### Monthly

```text
Max Monthly Drawdown = 10%
```

---

### Position Limits

```text
Max Exposure Per Stock = 10%

Max Sector = 25%

Max Open Swing Trades = 10
```

---

### Kill Switch

Automatically:

```ruby
DhanHQ::Models::KillSwitch
```

or

```ruby
Exit all positions
Disable new entries
```

---

# Layer 8 — Execution Engine

Uses:

```ruby
DhanHQ::Models::Order
DhanHQ::Models::SuperOrder
```

Flow:

```text
Signal
↓
Risk Validation
↓
Capital Validation
↓
Order Creation
↓
Broker
↓
Order Update
↓
Position Update
```

Never allow:

```ruby
AI
  ↓
Direct Order
```

Mandatory:

```text
AI
↓
Signal
↓
Risk Engine
↓
Execution
```

---

# Layer 9 — Autonomous Investment Planner

Monthly.

AI analyzes:

```text
Salary
Cash
Portfolio
Goals
Current Holdings
```

Produces:

```json
{
  "invest_this_month":25000,
  "buy":[
    "RELIANCE",
    "TCS"
  ]
}
```

Then:

```ruby
SIPExecutionJob
```

places CNC orders.

---

# Layer 10 — Monitoring

Dashboard

### Portfolio

```text
Current Value
PnL
XIRR
CAGR
Sharpe
Sortino
```

### Swing

```text
Open Trades
Win Rate
Expectancy
```

### AI

```text
AI Accuracy
Prediction Success
Confidence Calibration
```

---

# Resque Worker Topology

```text
resque:market_data
resque:technical_analysis
resque:fundamental_analysis
resque:news_analysis
resque:ai_research
resque:signal_generation
resque:risk_management
resque:execution
resque:portfolio_rebalance
resque:monitoring
```

---

# Recommended Database Domains

```text
users
portfolios
investment_plans

instruments
ohlcv

indicator_snapshots
fundamental_snapshots

signals
signal_evaluations

ai_reports

orders
trades
positions

risk_events

backtests

sector_strengths
market_breadth
```

---

# v1 Roadmap

### Phase 1

Market Data + Portfolio

```text
DhanHQ
OHLCV
Holdings
Positions
Orders
```

### Phase 2

Technical Engine

```text
EMA
RSI
MACD
ATR
ADX
```

### Phase 3

Swing Trading

```text
Breakouts
Trend Following
Position Sizing
```

### Phase 4

Long-Term Investing

```text
Fundamentals
Sector Ranking
Monthly SIP Automation
```

### Phase 5

AI Layer

```text
Ollama Research Agents
Decision Reports
Portfolio Review
```

### Phase 6

Autonomous Portfolio Manager

```text
Research
Allocation
Rebalancing
Execution
Monitoring
```

If I were building this for myself using Rails + DhanHQ + Resque + Ollama Cloud, I would start with **Investment OS first** (portfolio, research, allocation, rebalancing) and add swing trading second. Long-term investing compounds capital; swing trading should be an alpha overlay, not the core engine. The target capital allocation would be:

```text
70% Long-Term Investing
20% Swing Trading
10% Cash Reserve
```

This produces a much more stable system than a pure trading-first architecture.

# Product Requirements Document (PRD)

# Autonomous Investment Platform (AIP)

Version: 1.0

Status: Draft

Owner: Shubham Taywade

---

# 1. Executive Summary

Autonomous Investment Platform (AIP) is a Rails-based AI-assisted investment and swing trading platform designed for a single retail investor.

The platform combines:

- DhanHQ API execution
- Technical analysis
- Fundamental analysis
- AI research agents
- Portfolio management
- Risk management
- Autonomous investment planning
- Automated trade execution

The objective is to operate a retail portfolio with institutional-grade processes while maintaining full auditability and risk controls.

The platform is not intended to be a high-frequency trading system.

Primary focus:

1. Long-Term Investing
2. Swing Trading
3. Portfolio Optimization
4. Capital Preservation

---

# 2. Vision

Build a self-managing investment operating system that:

- Continuously researches NSE/BSE stocks
- Generates investment and swing trade opportunities
- Manages portfolio allocation
- Executes trades automatically
- Enforces risk controls
- Learns from historical performance

The system should function like a small hedge fund for a single investor.

---

# 3. Goals

## Business Goals

Increase portfolio CAGR.

Reduce emotional decision making.

Standardize investment process.

Automate portfolio management.

Create reusable trading infrastructure.

---

## Technical Goals

100% API driven.

Event-driven architecture.

AI-assisted decision making.

Fully auditable.

No manual spreadsheet dependency.

Single source of truth in PostgreSQL.

---

# 4. Non Goals

Not a social trading platform.

Not a broker.

Not a high frequency trading engine.

Not a multi-user SaaS in V1.

Not an options scalping system.

Not a futures trading system.

---

# 5. Target User

Primary User:

Retail Investor

Characteristics:

- Indian market participant
- Uses Dhan
- Invests monthly
- Executes swing trades
- Wants automation
- Understands markets

---

# 6. Product Scope

## Included

Portfolio Management

Investment Planning

Research Engine

Technical Analysis

Fundamental Analysis

AI Research

Risk Management

Automated Execution

Monitoring Dashboard

Backtesting

Trade Journaling

Performance Analytics

---

## Excluded

Options Selling

Futures Trading

Intraday Scalping

Social Features

Copy Trading

Multi Broker Support

---

# 7. Capital Allocation Model

Default Allocation

70% Long-Term Investing

20% Swing Trading

10% Cash Reserve

Configurable by user.

---

# 8. Core Functional Modules

## Module 1

Market Data Platform

Responsibilities:

Fetch:

- OHLCV
- Index Data
- Sector Data
- Holdings
- Positions
- Orders

Sources:

- DhanHQ
- NSE/BSE Data

Storage:

PostgreSQL

Update Frequency:

- Intraday
- Daily
- Weekly

---

## Module 2

Technical Analysis Engine

Indicators:

Trend:

- EMA20
- EMA50
- EMA200
- Supertrend

Momentum:

- RSI
- MACD
- ADX

Volatility:

- ATR
- Bollinger Bands

Volume:

- Volume SMA
- Relative Volume

Outputs:

Technical Snapshot

Signal Candidates

---

## Module 3

Fundamental Analysis Engine

Metrics:

Revenue Growth

Profit Growth

ROE

ROCE

Debt Equity

FCF

Promoter Holding

Institutional Ownership

Outputs:

Fundamental Score

Quality Score

Valuation Score

---

## Module 4

AI Research Engine

Provider:

Ollama Cloud

Client:

ollama-client

Models:

Fast Research:

- gpt-oss:20b-cloud

Deep Research:

- gpt-oss:120b-cloud

Responsibilities:

Research Reports

Investment Ratings

Sector Analysis

Portfolio Reviews

Risk Analysis

Monthly Recommendations

Output Format:

Strict JSON Schema

Stored For Auditing

---

## Module 5

Strategy Engine

### Strategy 1

Long-Term Investing

Criteria:

ROCE > 15

Debt Equity < 0.5

Revenue Growth > 15%

EMA200 Uptrend

Result:

BUY

HOLD

SELL

---

### Strategy 2

Swing Trading

Criteria:

EMA20 > EMA50

Breakout

Volume Expansion

ADX > 25

Relative Strength

Result:

ENTRY

EXIT

WAIT

---

### Strategy 3

Sector Rotation

Ranks sectors using:

Relative Strength

Momentum

Breadth

Capital flows

---

# 9. Portfolio Management

Features:

Portfolio Allocation

Position Sizing

Sector Allocation

Exposure Monitoring

Rebalancing

Cash Management

Portfolio Metrics:

CAGR

XIRR

Sharpe Ratio

Sortino Ratio

Drawdown

Exposure

---

# 10. Risk Management

Mandatory Controls

## Daily

Maximum Drawdown

3%

## Weekly

Maximum Drawdown

6%

## Monthly

Maximum Drawdown

10%

---

Position Controls

Maximum Stock Exposure

10%

Maximum Sector Exposure

25%

Maximum Open Swing Positions

10

---

Emergency Controls

Kill Switch

Exit All Positions

Disable New Entries

Freeze Execution

---

# 11. Execution Engine

Broker:

DhanHQ

Execution Flow:

Signal

Risk Validation

Portfolio Validation

Capital Validation

Order Creation

Broker Execution

Position Update

Audit Logging

---

Order Types

Market

Limit

Super Orders

Bracket Orders

---

# 12. Autonomous Investment Planner

Frequency:

Monthly

Inputs:

Salary

Available Cash

Portfolio

Current Allocation

Goals

Outputs:

Monthly Investment Plan

Rebalancing Plan

Suggested Purchases

Capital Deployment Schedule

---

# 13. Monitoring Dashboard

Portfolio Dashboard

Current Value

PnL

Allocation

Cash

Returns

---

Trading Dashboard

Open Trades

Win Rate

Expectancy

Profit Factor

---

AI Dashboard

Research Reports

Confidence Scores

Decision History

Prediction Accuracy

---

Risk Dashboard

Drawdown

Exposure

Risk Events

Kill Switch Status

---

# 14. Backtesting Engine

Capabilities

Historical Backtests

Walk Forward Testing

Parameter Optimization

Monte Carlo Simulation

Strategy Comparison

Outputs

Sharpe

Sortino

Win Rate

Max Drawdown

CAGR

Expectancy

---

# 15. Audit & Compliance

Every decision stored.

Every AI response stored.

Every order logged.

Every portfolio change logged.

Every risk override logged.

Immutable event history.

---

# 16. Functional Requirements

FR-001

System shall import NSE/BSE stock universe.

FR-002

System shall update market data daily.

FR-003

System shall calculate technical indicators.

FR-004

System shall generate investment signals.

FR-005

System shall generate swing trading signals.

FR-006

System shall create AI research reports.

FR-007

System shall calculate portfolio allocations.

FR-008

System shall execute orders via DhanHQ.

FR-009

System shall monitor risk limits.

FR-010

System shall generate monthly investment plans.

FR-011

System shall perform portfolio rebalancing.

FR-012

System shall maintain audit logs.

---

# 17. Non Functional Requirements

Availability

99%

Response Time

<500ms dashboard

<5s AI queries

Security

Encrypted credentials

Audit logs

Role based permissions

Scalability

Single user

10,000 instruments

100+ years historical data

Reliability

Retry mechanisms

Circuit breakers

Broker fail handling

AI fail handling

---

# 18. Technology Stack

Backend

Ruby 3.3+

Rails 8 API

PostgreSQL

Redis (optional)

Resque

---

Broker Layer

DhanHQ Ruby SDK

---

AI Layer

ollama-client

ollama_agent

---

Frontend

React

TypeScript

Material UI

TradingView Charts

---

Infrastructure

Docker

Azure

GitHub Actions

---

# 19. Success Metrics

Portfolio CAGR > NIFTY CAGR

Maximum Drawdown < 15%

100% Order Audit Coverage

100% Signal Audit Coverage

AI Recommendation Tracking

Monthly Rebalancing Success

Automated Execution Success Rate > 99%

---

# 20. Future Roadmap

V2

Mutual Funds

ETF Rotation

Multi Broker

Options Strategies

Crypto Investing

Tax Optimization

V3

Multi User SaaS

Mobile App

Family Office Features

Advisor Dashboard

Institutional Research Workbench

A PRD explains **what** to build.

A TDD (Technical Design Document) explains **how** to build it.

For this project, a weak TDD would jump into Rails models and APIs. A proper TDD starts with architecture boundaries because this system is effectively a mini asset-management platform.

# Technical Design Document (TDD)

# Autonomous Investment Platform (AIP)

Version: 1.0

Status: Draft

Author: Shubham Taywade

---

# 1. Overview

The Autonomous Investment Platform (AIP) is a Rails-based portfolio management, investment research, swing trading, and automated execution system for Indian equities.

The platform integrates:

- DhanHQ API
- PostgreSQL
- Rails API
- Resque
- Ollama Cloud
- React
- TradingView Charts

The system is designed around:

- Event-driven workflows
- AI-assisted decision making
- Strict risk management
- Full auditability

---

# 2. Architecture Principles

## Principle 1

AI Never Places Orders

Forbidden:

AI → Broker

Mandatory:

AI → Signal → Risk Engine → Execution Engine

---

## Principle 2

Signals Are Stateless

Signals can be regenerated.

Positions cannot.

Signals are derived data.

Positions are source-of-truth state.

---

## Principle 3

Everything Is Auditable

Every:

- Signal
- Decision
- Order
- AI Response
- Risk Event

Must be persisted.

---

## Principle 4

Portfolio First

Trading engine exists to improve portfolio returns.

Portfolio management owns strategy execution.

---

# 3. High Level Architecture

```
                ┌───────────────┐
                │ React UI      │
                └──────┬────────┘
                       │
                       ▼

              ┌─────────────────┐
              │ Rails API       │
              │ Control Plane   │
              └─────────────────┘

                       │
    ┌──────────────────┼──────────────────┐
    ▼                  ▼                  ▼
```

┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ PostgreSQL   │  │ Resque       │  │ DhanHQ       │
│ Source Truth │  │ Workers      │  │ Broker       │
└──────────────┘  └──────────────┘  └──────────────┘

```
                       │
                       ▼

                ┌──────────────┐
                │ Ollama Cloud │
                └──────────────┘
```

---

# 4. Domain Driven Design

Bounded Contexts

1. Market Data
2. Research
3. Technical Analysis
4. Portfolio Management
5. Trading
6. Risk
7. AI
8. Monitoring

Each context owns its models.

No shared business logic.

---

# 5. Rails Folder Structure

app/

domains/

```
market_data/

research/

technical_analysis/

portfolio/

trading/

risk/

ai/

monitoring/
```

jobs/

controllers/

serializers/

policies/

services/

queries/

contracts/

lib/

config/

---

# 6. Database Design

Core Domains

users

investment_plans

portfolios

positions

orders

trades

signals

ai_reports

risk_events

indicator_snapshots

fundamental_snapshots

market_data

backtests

watchlists

---

# 7. Market Data Domain

Responsibilities

Instrument Master

Historical Data

Realtime Data

Sector Data

Index Data

Market Breadth

---

Tables

instruments

daily_candles

weekly_candles

monthly_candles

sector_strengths

market_breadths

---

Service Objects

MarketData::HistoricalImporter

MarketData::RealtimeProcessor

MarketData::InstrumentSync

---

Jobs

ImportHistoricalDataJob

UpdateMarketBreadthJob

UpdateSectorStrengthJob

---

# 8. Technical Analysis Domain

Input

OHLCV

Output

Indicator Snapshots

---

Indicators

EMA20

EMA50

EMA200

RSI

MACD

ADX

ATR

Bollinger Bands

Supertrend

---

Table

indicator_snapshots

symbol

date

ema20

ema50

ema200

rsi

macd

adx

atr

supertrend

---

Service

TechnicalAnalysis::SnapshotGenerator

---

# 9. Fundamental Analysis Domain

Tables

fundamental_snapshots

valuation_snapshots

sector_rankings

---

Metrics

Revenue Growth

Profit Growth

ROE

ROCE

Debt Equity

EPS Growth

FCF

Promoter Holding

---

Service

Research::FundamentalScorer

---

# 10. AI Domain

Provider

Ollama Cloud

Client

ollama-client

---

Services

AI::ResearchAgent

AI::PortfolioReviewer

AI::SectorAnalyst

AI::InvestmentPlanner

AI::RiskReviewer

---

Storage

ai_reports

id

report_type

prompt

response

confidence

model

created_at

---

# 11. Signal Domain

Signal Lifecycle

Generated

Validated

Approved

Executed

Expired

Rejected

---

Table

signals

symbol

strategy

direction

score

confidence

status

generated_at

---

Strategies

LONG_TERM

SWING

SECTOR_ROTATION

---

# 12. Portfolio Domain

Responsibilities

Capital Allocation

Position Sizing

Rebalancing

Cash Management

Performance Tracking

---

Tables

portfolios

portfolio_allocations

positions

performance_snapshots

---

Services

Portfolio::Allocator

Portfolio::Rebalancer

Portfolio::PerformanceCalculator

Portfolio::PositionSizer

---

# 13. Risk Domain

Most Critical Domain

Every order passes through risk.

---

Risk Rules

Daily DD

Weekly DD

Monthly DD

Sector Exposure

Stock Exposure

Cash Reserve

Position Count

---

Tables

risk_rules

risk_events

risk_snapshots

---

Services

Risk::Validator

Risk::DrawdownMonitor

Risk::ExposureCalculator

Risk::KillSwitch

---

# 14. Trading Domain

Execution Layer

Uses DhanHQ

---

Services

Trading::OrderExecutor

Trading::PositionManager

Trading::OrderManager

Trading::BrokerAdapter

---

Flow

Signal

↓

Risk Validation

↓

Position Sizing

↓

Order Creation

↓

DhanHQ

↓

Order Updates

↓

Position Update

---

# 15. Resque Queues

market_data

technical_analysis

research

ai

signals

portfolio

risk

execution

monitoring

---

Worker Mapping

MarketDataWorker

IndicatorWorker

ResearchWorker

AIResearchWorker

SignalWorker

PortfolioWorker

RiskWorker

ExecutionWorker

MonitoringWorker

---

# 16. API Design

/api/dashboard

/api/portfolios

/api/positions

/api/orders

/api/trades

/api/signals

/api/ai-reports

/api/backtests

/api/risk

/api/watchlists

---

# 17. WebSocket Design

Realtime Updates

Portfolio

Orders

Positions

Signals

Risk Alerts

---

Channels

PortfolioChannel

OrdersChannel

SignalsChannel

RiskChannel

---

# 18. Event Flow

Nightly Cycle

Import Market Data

↓

Calculate Indicators

↓

Update Fundamentals

↓

Generate Signals

↓

AI Analysis

↓

Portfolio Analysis

↓

Rebalancing Decisions

↓

Execution Queue

---

# 19. Security

Encrypted Credentials

Broker Tokens Encrypted

AI Keys Encrypted

Audit Logging

IP Tracking

Order Correlation IDs

Immutable Risk Events

---

# 20. Observability

Metrics

Orders Executed

Signals Generated

AI Calls

Portfolio Value

Drawdown

Win Rate

Latency

---

Logs

Broker Logs

AI Logs

Risk Logs

Execution Logs

---

# 21. Deployment

Frontend

React

Azure Static Web App

Backend

Rails API

Azure App Service

Database

Azure PostgreSQL

Workers

Dedicated Resque Instance

---

# 22. Failure Recovery

Broker Failure

Retry

AI Failure

Fallback Models

Queue Failure

Retry

Market Data Failure

Reimport

Position Reconciliation

Nightly Validation

---

# 23. Testing Strategy

Unit Tests

RSpec

Target

90%+

---

Integration Tests

DhanHQ

Ollama

Database

Queues

---

Contract Tests

AI JSON Schema

Broker Responses

Signal Contracts

---

End-to-End Tests

Signal → Order

Portfolio → Rebalance

AI → Report

Risk → Block

---

# 24. Future Architecture

Multi Broker

Multi Portfolio

ETF Allocation

Mutual Funds

Options

Crypto

Multi User SaaS

Family Office Mode

### Next Document

The most important document is actually **DATABASE_DESIGN.md**.

For a trading platform, database mistakes become permanent technical debt. Before writing Rails models, I would design:

- 50–70 PostgreSQL tables
- indexes
- partitions for OHLCV
- event tables
- audit tables
- portfolio accounting tables
- signal lifecycle tables
- AI report storage tables
- order reconciliation tables

That schema becomes the foundation for everything else.

For this project, don't model the database like a CRUD app.

Model it like an **Investment Management System (IMS)** + **Portfolio Management System (PMS)** + **Execution Management System (EMS)**. Institutional systems separate portfolios, positions, signals, orders, executions, and research because they evolve at different speeds. ([Wikipedia][1])

# Database Architecture

```text
Core
├── Users
├── Settings
├── Audit

Market Data
├── Instruments
├── OHLCV
├── Fundamentals
├── Corporate Actions

Research
├── Technical Indicators
├── AI Reports
├── Signals

Portfolio
├── Portfolios
├── Holdings
├── Positions
├── Allocations

Execution
├── Orders
├── Trades
├── Broker Events

Risk
├── Risk Rules
├── Risk Events
├── Exposure Snapshots

Analytics
├── Backtests
├── Performance Snapshots
├── Journal Entries
```

---

# Domain 1 — Identity

## users

```sql
id
email
name
timezone
status
created_at
updated_at
```

---

## user_settings

```sql
id
user_id

default_portfolio_id

investment_allocation_pct
swing_allocation_pct
cash_reserve_pct

risk_per_trade_pct

created_at
updated_at
```

---

# Domain 2 — Instrument Master

This becomes the most important table in the entire system.

## instruments

```sql
id

security_id
exchange

symbol
trading_symbol

isin

name

sector
industry

instrument_type

lot_size

tick_size

is_active

created_at
updated_at
```

Example:

```text
RELIANCE
TCS
INFY
HDFCBANK
```

---

## exchanges

```sql
id

code
name

timezone
currency
```

---

# Domain 3 — Market Data

Do NOT store everything in one candles table.

Partition it.

---

## daily_candles

```sql
id

instrument_id

date

open
high
low
close

volume

created_at
```

Partition:

```sql
PARTITION BY RANGE(date)
```

Yearly partitions.

```text
daily_candles_2024
daily_candles_2025
daily_candles_2026
```

---

## intraday_candles

```sql
id

instrument_id

timestamp

interval

open
high
low
close

volume
```

Partition monthly.

---

# Domain 4 — Fundamentals

## fundamental_snapshots

```sql
id

instrument_id

snapshot_date

market_cap

pe_ratio
pb_ratio

roe
roce

debt_equity

sales_growth

profit_growth

eps_growth

free_cash_flow

promoter_holding

fii_holding
dii_holding

created_at
```

Never overwrite.

Insert snapshots.

---

# Domain 5 — Technical Analysis

## indicator_snapshots

```sql
id

instrument_id

snapshot_date

ema20
ema50
ema200

rsi

macd
macd_signal
macd_histogram

adx

atr

supertrend

bb_upper
bb_middle
bb_lower

volume_sma

created_at
```

---

# Domain 6 — AI Research

One of the biggest mistakes is storing only output.

Store prompts.

Store models.

Store confidence.

Store costs.

---

## ai_reports

```sql
id

instrument_id

report_type

model_name

prompt

response

confidence

tokens_used

generated_at
```

---

## ai_decisions

```sql
id

report_id

decision

confidence

risk_level

holding_period

created_at
```

Example:

```text
BUY
ACCUMULATE
WAIT
EXIT
```

---

# Domain 7 — Signal Engine

Signals are NOT trades.

---

## signals

```sql
id

instrument_id

strategy

signal_type

direction

score

confidence

entry_price

stop_loss

target_price

generated_at

expires_at

status
```

Status:

```text
generated
validated
approved
executed
expired
rejected
```

---

## signal_validations

```sql
id

signal_id

validator_type

result

reason

validated_at
```

---

# Domain 8 — Portfolio

You need portfolio abstraction even for a single user.

Future-proofing.

---

## portfolios

```sql
id

user_id

name

portfolio_type

currency

status

created_at
```

Examples:

```text
Long Term
Swing
Paper Trading
```

---

## portfolio_allocations

```sql
id

portfolio_id

allocation_type

target_pct

current_pct
```

Example:

```text
IT
15%

BANKING
20%

PHARMA
10%
```

---

# Domain 9 — Holdings

Investment positions.

---

## holdings

```sql
id

portfolio_id

instrument_id

quantity

average_price

current_price

market_value

unrealized_pnl

realized_pnl

opened_at
updated_at
```

---

# Domain 10 — Trading Positions

Separate from holdings.

Critical.

---

## positions

```sql
id

portfolio_id

signal_id

instrument_id

position_type

quantity

entry_price

stop_loss

target

current_price

status

opened_at
closed_at
```

---

# Domain 11 — Orders

Broker order state.

---

## orders

```sql
id

portfolio_id

position_id

signal_id

broker_order_id

correlation_id

order_type

transaction_type

product_type

quantity

price

trigger_price

status

placed_at
updated_at
```

---

## order_events

```sql
id

order_id

event_type

payload

received_at
```

Store raw Dhan payload.

Never discard.

---

# Domain 12 — Executions

Fill level.

---

## trades

```sql
id

order_id

instrument_id

quantity

price

trade_time
```

One order may have many trades.

---

# Domain 13 — Risk

Most important domain.

---

## risk_rules

```sql
id

name

rule_type

threshold

is_enabled
```

---

## risk_events

```sql
id

rule_id

severity

message

payload

occurred_at
```

---

## exposure_snapshots

```sql
id

portfolio_id

snapshot_time

gross_exposure

net_exposure

sector_exposure

cash_pct
```

---

# Domain 14 — Backtesting

## backtests

```sql
id

name

strategy

start_date
end_date

parameters

results

created_at
```

---

## backtest_trades

```sql
id

backtest_id

instrument_id

entry_date

exit_date

entry_price

exit_price

pnl
```

---

# Domain 15 — Performance Analytics

## performance_snapshots

```sql
id

portfolio_id

snapshot_date

portfolio_value

cash

realized_pnl

unrealized_pnl

drawdown

cagr

xirr
```

---

# Domain 16 — Event Store

This is where institutional systems differ.

Instead of relying only on current state:

```sql
portfolio_events
signal_events
position_events
order_events
risk_events
```

Store every state transition.

Example:

```text
Signal Generated
Signal Approved
Order Created
Order Filled
Position Opened
Position Closed
```

This gives:

- Complete audit trail
- Replay capability
- AI training dataset
- Strategy evaluation history

---

# PostgreSQL Partitioning Strategy

## Partition

```text
daily_candles
intraday_candles
indicator_snapshots
performance_snapshots
order_events
ai_reports
```

## Index

```sql
(symbol)
(instrument_id)

(date DESC)

(snapshot_date DESC)

(portfolio_id,status)

(signal_id)

(broker_order_id)

(correlation_id)
```

---

# Expected Scale

Even for one retail trader:

```text
NSE Universe         ~5000 stocks

Daily Candles        ~10M+ rows
Intraday Candles     ~100M+ rows

Indicators           ~50M+ rows

Signals              ~1M+

Orders               ~100k+

Trades               ~500k+

Audit Events         ~10M+
```

Design for this scale on day one. Retrofitting partitions, event storage, and portfolio accounting later is where most trading-platform rewrites begin. The schema above gives you a foundation that can grow from a single-user Rails application into a small fund-management platform without major redesign.

[1]: https://en.wikipedia.org/wiki/Execution_management_system?utm_source=chatgpt.com "Execution management system"

Do **not** create 40+ fat ActiveRecord models.

The biggest mistake in trading systems is putting business logic inside models.

Use:

```text
Models      = State + Associations
Services    = Business Logic
Queries     = Read Models
Policies    = Risk Rules
Jobs        = Orchestration
Events      = Audit Trail
```

For Rails 8 API I would organize it like:

```text
app/models
app/models/concerns

app/domains
  market_data
  portfolio
  trading
  risk
  research
  ai
```

---

# Shared Concerns

## Auditable

```ruby
# app/models/concerns/auditable.rb

module Auditable
  extend ActiveSupport::Concern

  included do
    has_many :audit_events,
             as: :auditable,
             dependent: :destroy
  end
end
```

---

## Activatable

```ruby
module Activatable
  extend ActiveSupport::Concern

  included do
    enum :status,
      {
        active: "active",
        inactive: "inactive"
      },
      default: :active
  end
end
```

---

## Trackable

```ruby
module Trackable
  extend ActiveSupport::Concern

  included do
    scope :recent, -> { order(created_at: :desc) }
  end
end
```

---

# User Domain

## User

```ruby
class User < ApplicationRecord
  include Activatable
  include Trackable

  has_one :user_setting, dependent: :destroy

  has_many :portfolios, dependent: :destroy
end
```

---

## UserSetting

```ruby
class UserSetting < ApplicationRecord
  belongs_to :user

  belongs_to :default_portfolio,
             class_name: "Portfolio",
             optional: true

  validates :investment_allocation_pct,
            :swing_allocation_pct,
            :cash_reserve_pct,
            numericality: true
end
```

---

# Market Data Domain

## Instrument

This becomes the center of the universe.

```ruby
class Instrument < ApplicationRecord
  include Activatable

  has_many :daily_candles
  has_many :intraday_candles

  has_many :indicator_snapshots
  has_many :fundamental_snapshots

  has_many :signals

  validates :symbol,
            :security_id,
            presence: true

  validates :security_id,
            uniqueness: true
end
```

---

## DailyCandle

```ruby
class DailyCandle < ApplicationRecord
  belongs_to :instrument

  validates :date,
            uniqueness: {
              scope: :instrument_id
            }
end
```

---

## IntradayCandle

```ruby
class IntradayCandle < ApplicationRecord
  belongs_to :instrument
end
```

---

# Research Domain

## FundamentalSnapshot

```ruby
class FundamentalSnapshot < ApplicationRecord
  belongs_to :instrument

  scope :latest,
        -> { order(snapshot_date: :desc) }
end
```

---

## IndicatorSnapshot

```ruby
class IndicatorSnapshot < ApplicationRecord
  belongs_to :instrument

  scope :latest,
        -> { order(snapshot_date: :desc) }
end
```

---

# AI Domain

## AiReport

```ruby
class AiReport < ApplicationRecord
  include Auditable

  belongs_to :instrument,
             optional: true

  has_many :ai_decisions,
           dependent: :destroy

  enum :report_type,
       {
         investment: "investment",
         swing: "swing",
         portfolio_review: "portfolio_review",
         sector_analysis: "sector_analysis"
       }
end
```

---

## AiDecision

```ruby
class AiDecision < ApplicationRecord
  belongs_to :ai_report

  enum :decision,
       {
         buy: "buy",
         accumulate: "accumulate",
         hold: "hold",
         wait: "wait",
         sell: "sell"
       }
end
```

---

# Signal Domain

## Signal

```ruby
class Signal < ApplicationRecord
  include Auditable

  belongs_to :instrument

  has_many :signal_validations,
           dependent: :destroy

  has_one :position

  enum :strategy,
       {
         long_term: "long_term",
         swing: "swing",
         sector_rotation: "sector_rotation"
       }

  enum :status,
       {
         generated: "generated",
         validated: "validated",
         approved: "approved",
         executed: "executed",
         expired: "expired",
         rejected: "rejected"
       }
end
```

---

## SignalValidation

```ruby
class SignalValidation < ApplicationRecord
  belongs_to :signal
end
```

---

# Portfolio Domain

## Portfolio

```ruby
class Portfolio < ApplicationRecord
  include Auditable

  belongs_to :user

  has_many :holdings
  has_many :positions

  has_many :portfolio_allocations

  has_many :performance_snapshots

  enum :portfolio_type,
       {
         long_term: "long_term",
         swing: "swing",
         paper: "paper"
       }
end
```

---

## PortfolioAllocation

```ruby
class PortfolioAllocation < ApplicationRecord
  belongs_to :portfolio
end
```

---

## Holding

Long-term investments.

```ruby
class Holding < ApplicationRecord
  belongs_to :portfolio
  belongs_to :instrument
end
```

---

# Trading Domain

## Position

Open trade.

```ruby
class Position < ApplicationRecord
  include Auditable

  belongs_to :portfolio

  belongs_to :instrument

  belongs_to :signal,
             optional: true

  has_many :orders

  enum :status,
       {
         open: "open",
         closed: "closed",
         cancelled: "cancelled"
       }

  enum :position_type,
       {
         long: "long",
         short: "short"
       }
end
```

---

## Order

```ruby
class Order < ApplicationRecord
  include Auditable

  belongs_to :portfolio

  belongs_to :position,
             optional: true

  belongs_to :signal,
             optional: true

  has_many :trades

  has_many :order_events

  enum :status,
       {
         pending: "pending",
         open: "open",
         partially_filled: "partially_filled",
         filled: "filled",
         cancelled: "cancelled",
         rejected: "rejected"
       }
end
```

---

## Trade

```ruby
class Trade < ApplicationRecord
  belongs_to :order

  belongs_to :instrument
end
```

---

## OrderEvent

Store raw Dhan webhook payload.

```ruby
class OrderEvent < ApplicationRecord
  belongs_to :order
end
```

---

# Risk Domain

## RiskRule

```ruby
class RiskRule < ApplicationRecord
  enum :rule_type,
       {
         daily_drawdown: "daily_drawdown",
         weekly_drawdown: "weekly_drawdown",
         monthly_drawdown: "monthly_drawdown",
         sector_exposure: "sector_exposure",
         stock_exposure: "stock_exposure"
       }
end
```

---

## RiskEvent

```ruby
class RiskEvent < ApplicationRecord
  belongs_to :risk_rule,
             optional: true
end
```

---

## ExposureSnapshot

```ruby
class ExposureSnapshot < ApplicationRecord
  belongs_to :portfolio
end
```

---

# Analytics Domain

## Backtest

```ruby
class Backtest < ApplicationRecord
  has_many :backtest_trades
end
```

---

## BacktestTrade

```ruby
class BacktestTrade < ApplicationRecord
  belongs_to :backtest
  belongs_to :instrument
end
```

---

## PerformanceSnapshot

```ruby
class PerformanceSnapshot < ApplicationRecord
  belongs_to :portfolio
end
```

---

# Audit Domain

Instead of creating:

```text
signal_events
position_events
portfolio_events
order_events
```

Create one polymorphic model.

## AuditEvent

```ruby
class AuditEvent < ApplicationRecord
  belongs_to :auditable,
             polymorphic: true

  store_accessor :payload,
                 :before,
                 :after,
                 :reason,
                 :metadata
end
```

---

# Models I Would NOT Create

These usually become garbage abstractions:

```text
OrderManager
SignalManager
PortfolioManager
TradeManager
RiskManager
```

Instead:

```text
Trading::OrderExecutor
Trading::PositionCloser

Portfolio::Allocator
Portfolio::Rebalancer

Risk::Validator
Risk::ExposureCalculator

Signals::Generator

AI::ResearchAgent
```

Keep models under ~50 lines each. If a model exceeds ~100 lines, business logic is leaking out of services and the architecture is starting to rot.

For this project, I would **not** generate OpenAPI from Rails routes.

I would do the opposite:

```text
PRD
 ↓
OpenAPI First
 ↓
Controllers
 ↓
Services
 ↓
Routes
 ↓
Frontend SDK
```

The OpenAPI spec becomes the contract between:

```text
React Frontend
AI Agents
Rails API
Future Mobile App
External Integrations
```

---

# API Structure

```text
/api/v1

/auth

/dashboard

/instruments
/market-data

/portfolios
/holdings
/positions

/signals
/strategies

/orders
/trades

/risk

/ai-reports
/ai-decisions

/backtests

/settings

/system
```

---

# Recommended Rails Routes

```ruby
# config/routes.rb

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do

      resource :dashboard, only: :show

      resources :instruments, only: %i[index show] do
        member do
          get :fundamentals
          get :indicators
          get :signals
          get :ai_reports
        end
      end

      resources :portfolios do
        member do
          get :performance
          get :allocations
          post :rebalance
        end
      end

      resources :holdings, only: %i[index show]

      resources :positions do
        member do
          post :close
        end
      end

      resources :signals do
        member do
          post :approve
          post :reject
          post :execute
        end
      end

      resources :orders do
        member do
          post :cancel
          post :modify
        end
      end

      resources :trades, only: %i[index show]

      resources :risk_events, only: %i[index show]

      resources :risk_rules

      resources :ai_reports, only: %i[index show]

      resources :backtests do
        member do
          post :run
        end
      end

      resources :watchlists

      resource :settings,
               only: %i[show update]

      namespace :system do
        get :health
        get :metrics
      end
    end
  end
end
```

---

# OpenAPI Folder Structure

```text
docs/openapi/

openapi.yml

schemas/
  portfolio.yml
  position.yml
  holding.yml
  signal.yml
  order.yml
  trade.yml
  ai_report.yml

paths/
  portfolios.yml
  positions.yml
  signals.yml
  orders.yml
```

Much easier to maintain than a 5000-line file.

---

# OpenAPI Root

```yaml
openapi: 3.1.0

info:
  title: Autonomous Investment Platform API
  version: 1.0.0

servers:
  - url: https://api.example.com/api/v1

security:
  - bearerAuth: []

components:

  securitySchemes:

    bearerAuth:
      type: http
      scheme: bearer

  schemas:

    Portfolio:
      $ref: "./schemas/portfolio.yml"

    Position:
      $ref: "./schemas/position.yml"

    Signal:
      $ref: "./schemas/signal.yml"

    Order:
      $ref: "./schemas/order.yml"
```

---

# Portfolio Schema

```yaml
type: object

properties:

  id:
    type: integer

  name:
    type: string

  portfolio_type:
    type: string
    enum:
      - long_term
      - swing
      - paper

  status:
    type: string

  current_value:
    type: number

  cash:
    type: number

  created_at:
    type: string
    format: date-time
```

---

# Position Schema

```yaml
type: object

properties:

  id:
    type: integer

  instrument_id:
    type: integer

  quantity:
    type: integer

  entry_price:
    type: number

  current_price:
    type: number

  stop_loss:
    type: number

  target:
    type: number

  status:
    type: string

  unrealized_pnl:
    type: number
```

---

# Signal Schema

```yaml
type: object

properties:

  id:
    type: integer

  strategy:
    type: string

  direction:
    type: string

  confidence:
    type: number

  score:
    type: number

  status:
    type: string

  entry_price:
    type: number

  stop_loss:
    type: number

  target_price:
    type: number
```

---

# Order Schema

```yaml
type: object

properties:

  id:
    type: integer

  broker_order_id:
    type: string

  correlation_id:
    type: string

  order_type:
    type: string

  transaction_type:
    type: string

  quantity:
    type: integer

  price:
    type: number

  status:
    type: string

  placed_at:
    type: string
    format: date-time
```

---

# Critical Endpoints

These are the endpoints that actually matter in V1.

## Dashboard

```http
GET /api/v1/dashboard
```

Returns:

```json
{
  "portfolio_value": 1025000,
  "cash": 120000,
  "day_pnl": 12000,
  "drawdown": -3.2,
  "open_positions": 8
}
```

---

## Generate Signals

```http
POST /api/v1/signals/generate
```

Triggers:

```text
Technical Analysis
Fundamental Analysis
AI Review
Signal Creation
```

---

## Execute Signal

```http
POST /api/v1/signals/:id/execute
```

Flow:

```text
Signal
↓
Risk Validation
↓
Position Sizing
↓
Order Creation
↓
DhanHQ
```

---

## Rebalance Portfolio

```http
POST /api/v1/portfolios/:id/rebalance
```

Flow:

```text
Current Allocation
↓
Target Allocation
↓
Orders Generated
↓
Approval
↓
Execution
```

---

# WebSocket API

Do not poll.

Use ActionCable.

```ruby
PortfolioChannel
SignalsChannel
OrdersChannel
RiskChannel
```

Events:

```json
{
  "event": "position.updated",
  "portfolio_id": 1,
  "position_id": 101
}
```

---

# Missing Routes You Will Need

Add these immediately:

```ruby
post "/signals/generate"
post "/ai_reports/generate"

post "/portfolio/rebalance"

post "/market_data/sync"

post "/backtests/:id/run"

post "/risk/kill_switch"

post "/execution/emergency_exit"
```

These represent actual business workflows. CRUD endpoints alone are insufficient for a trading platform because most operations are commands, not resource updates.

If you want this platform to become a serious trading infrastructure, then **DhanHQ should never appear outside the broker adapter layer**.

The mistake is:

```text
Trading::OrderExecutor
      ↓
    DhanHQ
```

That creates vendor lock-in.

Instead:

```text
Trading::OrderExecutor
        ↓
BrokerGateway
        ↓
BrokerAdapter
        ↓
 ┌─────────────┬─────────────┬─────────────┐
 │ DhanAdapter │ KiteAdapter │ FyersAdapter│
 └─────────────┴─────────────┴─────────────┘
```

---

# Target Architecture

```text
Domains
│
├── Signals
├── Portfolio
├── Risk
├── Trading
│
└── Broker Abstraction Layer
         │
         ├── Dhan
         ├── Zerodha
         ├── Angel
         ├── Fyers
         ├── Upstox
         ├── Delta
         └── Paper
```

---

# Core Broker Interface

Every broker must implement the same contract.

```ruby
module Brokers
  class BaseAdapter

    def place_order(order)
      raise NotImplementedError
    end

    def modify_order(order)
      raise NotImplementedError
    end

    def cancel_order(order)
      raise NotImplementedError
    end

    def positions
      raise NotImplementedError
    end

    def holdings
      raise NotImplementedError
    end

    def funds
      raise NotImplementedError
    end

    def orderbook
      raise NotImplementedError
    end

    def websocket
      raise NotImplementedError
    end
  end
end
```

---

# Dhan Adapter

```ruby
module Brokers
  module Dhan
    class Adapter < BaseAdapter

      def place_order(order)
        DhanHQ::Models::Order.create(
          transaction_type: order.side,
          security_id: order.instrument.security_id,
          quantity: order.quantity
        )
      end

    end
  end
end
```

---

# Zerodha Adapter

```ruby
module Brokers
  module Zerodha
    class Adapter < BaseAdapter

      def place_order(order)
        kite.place_order(...)
      end

    end
  end
end
```

---

# Broker Registry

```ruby
module Brokers
  class Registry

    def self.fetch(name)
      case name.to_sym
      when :dhan
        Brokers::Dhan::Adapter.new

      when :zerodha
        Brokers::Zerodha::Adapter.new

      when :fyers
        Brokers::Fyers::Adapter.new

      else
        raise "Unsupported broker"
      end
    end
  end
end
```

---

# Order Execution

Trading code never knows which broker is used.

```ruby
class Trading::OrderExecutor

  def execute(signal)

    broker =
      Brokers::Registry.fetch(
        signal.portfolio.broker_account.broker
      )

    broker.place_order(...)
  end
end
```

---

# Data Model

## Broker

```ruby
class Broker < ApplicationRecord

  has_many :broker_accounts

  enum :provider,
    {
      dhan: "dhan",
      zerodha: "zerodha",
      fyers: "fyers",
      angel: "angel",
      upstox: "upstox",
      delta: "delta",
      paper: "paper"
    }
end
```

---

## BrokerAccount

```ruby
class BrokerAccount < ApplicationRecord

  belongs_to :user
  belongs_to :broker

  encrypts :access_token
  encrypts :refresh_token

  has_many :portfolios
end
```

---

## Portfolio

```ruby
class Portfolio < ApplicationRecord

  belongs_to :broker_account
end
```

Now one user can have:

```text
Long Term Portfolio
  -> Dhan

Swing Portfolio
  -> Zerodha

Crypto Portfolio
  -> Delta

Paper Portfolio
  -> Paper Broker
```

---

# Instrument Normalization Layer

This is where most systems fail.

Every broker uses different identifiers.

Example:

```text
Dhan:
  security_id=11536

Zerodha:
  instrument_token=738561

Fyers:
  symbol=NSE:RELIANCE-EQ
```

Never store broker identifiers in positions.

Store internal instruments.

```ruby
Instrument
  id

  symbol
  isin
```

Then:

```ruby
BrokerInstrument
```

```ruby
instrument_id

broker_id

external_symbol

external_security_id
```

Example:

```text
RELIANCE

Dhan:
11536

Zerodha:
738561

Fyers:
NSE:RELIANCE-EQ
```

---

# Market Data Abstraction

Do NOT fetch candles directly from DhanHQ everywhere.

Use:

```ruby
MarketDataProvider
```

```text
NSE Direct
Dhan
Zerodha
Polygon
AlphaVantage
Yahoo
```

Architecture:

```text
TechnicalAnalysis
      ↓
MarketDataProvider
      ↓
Provider Adapter
      ↓
Broker/API
```

---

# WebSocket Abstraction

Create:

```ruby
BrokerStream
```

Common event:

```ruby
{
  type: "tick",

  symbol: "RELIANCE",

  ltp: 1520.25,

  volume: 120000
}
```

Dhan:

```ruby
tick[:ltp]
```

Zerodha:

```ruby
tick.last_price
```

Both converted into:

```ruby
TickEvent
```

---

# Paper Trading Broker

Most important adapter.

```ruby
Brokers::Paper::Adapter
```

Implements:

```ruby
place_order
cancel_order
positions
holdings
```

using PostgreSQL only.

This allows:

```text
Backtesting
Forward Testing
Paper Trading
Live Trading
```

without changing strategy code.

---

# Final Architecture

```text
Portfolio
     ↓

Signal Engine
     ↓

Risk Engine
     ↓

Order Executor
     ↓

Broker Gateway
     ↓

Broker Adapter
     ↓

Dhan
Zerodha
Fyers
Angel
Upstox
Delta
Paper
```

This is the same pattern used by professional OMS/EMS systems. Your strategies, AI agents, portfolio logic, risk engine, and backtests never know which broker is underneath. The only code that changes when adding a new broker is a new adapter implementation plus instrument mapping.

The Paper Trading Adapter should be one of the largest and most sophisticated modules in the platform.

Most retail systems implement paper trading as:

```ruby
cash -= order_value
position += qty
```

That's garbage.

A proper Paper Broker should simulate a real broker, exchange, OMS, RMS, and portfolio accounting system.

---

# Architecture

```text
Paper Broker

├── Order Management System (OMS)
├── Execution Simulator
├── Risk Management System (RMS)
├── Portfolio Accounting
├── Market Data Engine
├── Corporate Actions Engine
├── Margin Engine
├── Slippage Engine
├── Commission Engine
├── Tax Engine
├── Trade Journal
├── Replay Engine
├── Backtesting Engine
├── Walk Forward Engine
└── Analytics Engine
```

---

# 1. Order Management System

Exactly same interface as Dhan.

```ruby
paper.place_order(...)
paper.modify_order(...)
paper.cancel_order(...)
paper.orderbook
```

Tables:

```text
paper_orders

paper_order_events

paper_trades
```

Lifecycle:

```text
NEW
↓
VALIDATED
↓
OPEN
↓
PARTIALLY_FILLED
↓
FILLED
↓
CANCELLED
↓
REJECTED
```

---

# 2. Execution Simulator

Most important component.

Without this all backtests are fake.

---

## Instant Fill Mode

```text
BUY RELIANCE @ MARKET

LTP = 1500

Fill = 1500
```

Used for quick testing.

---

## Realistic Fill Mode

Uses:

```text
Spread

Bid

Ask

Volume

ATR

Market Depth
```

Example:

```text
Bid 1499.80

Ask 1500.20

BUY 1000 shares

Fill

300 @ 1500.20
400 @ 1500.25
300 @ 1500.30
```

---

# 3. Slippage Engine

Never trust backtests without slippage.

---

Config

```ruby
slippage:
  fixed: 0.05

or

slippage:
  atr_multiplier: 0.02
```

---

Calculation

```text
Expected Price

1500

Actual Fill

1501.75
```

---

# 4. Brokerage Engine

Simulate broker charges.

---

Examples

```text
Brokerage

STT

Exchange Charges

SEBI Charges

GST

Stamp Duty
```

Store per trade.

```text
trade_costs
```

---

# 5. Portfolio Accounting

Professional accounting.

---

Tables

```text
cash_ledgers

journal_entries

portfolio_transactions
```

Every action creates entries.

Example:

```text
Cash - 150000

Position + 150000
```

Double-entry bookkeeping.

---

# 6. Margin Engine

Needed for future expansion.

Supports:

```text
CNC

MIS

MTF

Futures

Options
```

Methods:

```ruby
available_margin

blocked_margin

utilized_margin
```

---

# 7. Risk Engine

Same risk engine as live trading.

Never bypass.

---

Validations

```text
Max Exposure

Max Drawdown

Max Sector Allocation

Max Position Size

Cash Allocation
```

---

# 8. Position Manager

Tracks:

```text
Open Positions

Closed Positions

Average Price

MTM

Realized PnL

Unrealized PnL
```

---

Tables

```text
paper_positions

paper_position_events
```

---

# 9. Holdings Engine

Investment portfolio simulation.

Tracks:

```text
CNC Holdings

Average Cost

Current Value

Dividends

Splits
```

---

# 10. Corporate Actions Engine

Most systems completely ignore this.

Huge mistake.

---

Support:

```text
Dividend

Split

Bonus

Rights Issue

Merger

Demerger
```

Example:

```text
TCS 1:1 Bonus

100 shares

becomes

200 shares
```

---

# 11. Market Replay Engine

One of the most powerful features.

---

Replay

```text
1 Day

1 Week

1 Month

1 Year

COVID Crash

Election Day

Budget Day
```

Feed historical candles as live ticks.

```ruby
ReplayEngine.start(
  date: "2020-03-20"
)
```

Strategy thinks market is live.

---

# 12. Strategy Competition Engine

Run multiple strategies.

```text
Momentum

SMC

Swing

Long Term
```

Same capital.

Compare results.

---

# 13. Walk Forward Testing

Backtest

↓

Optimize

↓

Forward Test

↓

Validate

---

Much more realistic.

---

# 14. AI Simulation Environment

Extremely useful.

---

Run:

```text
Research Agent

Signal Agent

Portfolio Agent

Risk Agent
```

Against historical data.

Measure:

```text
Decision Accuracy

PnL Impact

Confidence Scores

Hallucination Rate
```

---

# 15. Trade Journal

Auto-generated.

Store:

```text
Signal

Reason

AI Analysis

Entry

Exit

PnL

Screenshots

Indicators
```

---

# 16. Performance Analytics

Metrics:

```text
Win Rate

Profit Factor

Sharpe

Sortino

Max Drawdown

Recovery Factor

Expectancy

Average R

CAGR

XIRR
```

---

# 17. Paper Broker WebSocket

Exactly mimic live broker.

```ruby
PaperBroker::WS.connect
```

Events:

```json
{
  "event": "order_update",
  "status": "FILLED"
}
```

Strategies should not know:

```text
Live Broker

OR

Paper Broker
```

---

# 18. Event Sourcing

Store everything.

```text
paper_events
```

Events:

```text
ORDER_CREATED

ORDER_FILLED

POSITION_OPENED

POSITION_CLOSED

DIVIDEND_RECEIVED

SPLIT_APPLIED

RISK_REJECTED
```

---

# 19. Multi-Mode Paper Broker

```text
Mode 1
Instant

Mode 2
Realistic

Mode 3
Exchange Simulation

Mode 4
Historical Replay

Mode 5
AI Sandbox

Mode 6
Backtesting

Mode 7
Walk Forward
```

---

# Final Interface

```ruby
broker = Brokers::Paper::Adapter.new

broker.place_order(...)
broker.cancel_order(...)
broker.modify_order(...)

broker.positions
broker.holdings
broker.funds

broker.start_replay(...)
broker.stop_replay(...)

broker.performance_report
broker.trade_journal

broker.risk_report
broker.analytics
```

If architected correctly, **PaperBroker becomes the foundation for:**

- Backtesting
- Forward Testing
- Strategy Development
- AI Agent Evaluation
- Portfolio Research
- Risk Testing
- Broker Integration Testing
- Disaster Recovery Testing

A good rule: **every strategy should run against PaperBroker first, then switch to Dhan/Zerodha/Fyers by changing only the broker account configuration.** No strategy code should change.

I would not name it **paper-exchange**.

That sounds like a toy simulator.

You're actually building something closer to:

```text
OMS + EMS + PMS + Broker Simulator + Exchange Simulator
```

that can be reused by:

- Indian Stocks
- Crypto
- Futures
- Options
- Backtesting
- AI Agents
- Paper Trading
- Strategy Development

So choose a name that represents the **execution/simulation infrastructure**, not just paper trading.

# My Top Recommendations

## 1. TradeForge ⭐

```text
tradeforge
```

Meaning:

```text
Trades are forged here.
```

Can support:

```text
TradeForge Stocks
TradeForge Crypto
TradeForge Exchange
TradeForge OMS
```

Structure:

```text
tradeforge-core
tradeforge-paper
tradeforge-stocks
tradeforge-crypto
```

This is probably what I would pick.

---

## 2. MarketForge ⭐

```text
marketforge
```

Meaning:

```text
Synthetic market creation.
```

Perfect because you are literally building:

```text
Exchange Simulator
Broker Simulator
Replay Engine
Market Generator
```

Can power:

```text
Indian Stocks
Crypto
Forex
Options
```

---

## 3. BrokerForge

```text
brokerforge
```

Focuses on:

```text
Broker Simulation
Multi-Broker Layer
OMS
EMS
```

Good if the broker abstraction is the core vision.

---

## 4. SimExchange

```text
simexchange
```

Simple.

Very descriptive.

Not very brandable.

---

## 5. MarketCore

```text
marketcore
```

Feels institutional.

Could become:

```text
MarketCore OMS
MarketCore PMS
MarketCore Exchange
```

---

## 6. StratX

```text
stratx
```

Strategy execution platform.

More hedge-fund sounding.

Less focused on exchange simulation.

---

## 7. AlphaForge

```text
alphaforge
```

Research

Signals

Execution

Portfolio

AI

Good if your end goal is alpha generation.

---

# If You Plan Multiple Projects

You already have:

```text
DhanHQ
ollama-client
ollama-agent
pineforge-platform
```

I would create an ecosystem:

```text
pineforge-platform      # strategy creation

tradeforge-core         # execution kernel

tradeforge-paper        # paper exchange

tradeforge-stocks       # Indian equities

tradeforge-crypto       # crypto exchange support

tradeforge-ai           # AI agents

tradeforge-web          # UI
```

Architecture:

```text
                 tradeforge-core
                        │
        ┌───────────────┼───────────────┐
        │               │               │
        ▼               ▼               ▼

tradeforge-paper  tradeforge-stocks  tradeforge-crypto

        │               │               │

        └─────── used by AlgoScalper ───┘
```

For long-term maintainability, **tradeforge-core** + **tradeforge-paper** is the naming scheme I would choose. It scales from a simple paper broker all the way to a full OMS/EMS platform without the name becoming misleading.

If this system is **strictly for Indian markets**, then the name should reflect:

```text
NSE
BSE
Equities
ETF
Mutual Funds
IPO
Bonds
F&O
Options
Paper Trading
Broker Simulation
Portfolio Management
```

and not generic global trading.

Also avoid names tied to:

```text
Crypto
Forex
Multi-asset
Global Markets
```

---

# What This Project Actually Is

You are not building:

```text
Paper Trading App
```

You are building:

```text
Indian Market Simulation Platform

or

Indian Broker Simulation Platform

or

Indian OMS/EMS Sandbox
```

with:

```text
Broker APIs
Paper Broker
Paper Exchange
Portfolio Engine
Risk Engine
Backtesting
AI Research
Investment Management
Swing Trading
```

---

# Names I Would Consider

## 1. NiveshX ⭐

```text
niveshx
```

Meaning:

```text
Nivesh = Investment
X = Execution Platform
```

Fits:

```text
Long Term Investing
Swing Trading
Portfolio Management
```

---

## 2. BharatOMS ⭐

```text
bharat-oms
```

Professional.

Institutional sounding.

Future architecture:

```text
bharat-oms-core
bharat-oms-paper
bharat-oms-dhan
bharat-oms-zerodha
```

---

## 3. NiveshForge ⭐

```text
nivesh-forge
```

Focused on Indian investing.

Good for:

```text
Investment Research
Portfolio Management
Execution
```

---

## 4. DalalStreet Simulator

```text
dalal-street-sim
```

Very Indian.

Very obvious.

Less enterprise.

---

## 5. StockMandi

```text
stock-mandi
```

Retail-oriented.

Probably not suitable for a serious architecture project.

---

## 6. EquityEngine ⭐

```text
equity-engine
```

Strong.

Technical.

Focused on Indian equities.

---

## 7. NSEngine ⭐

```text
nsengine
```

Short for:

```text
NSE Engine
```

Could become:

```text
nsengine-core
nsengine-paper
nsengine-brokers
```

---

## 8. MarketSutra ⭐

```text
market-sutra
```

Indian flavor.

Unique.

Good branding potential.

---

## 9. ArthX ⭐

```text
arthx
```

Meaning:

```text
Arth = Wealth / Finance
```

Modern.

Short.

Brandable.

---

## 10. Niveshak ⭐

```text
niveshak
```

Meaning:

```text
Investor
```

This actually aligns very well with your stated goal:

```text
Autonomous Investing
Swing Trading
Long-Term Investing
Portfolio Management
```

---

# Names I Would Avoid

```text
paper-exchange
paper-broker
tradeforge
marketforge
simexchange
brokerforge
stock-simulator
trading-simulator
```

Reason:

They sound like a feature.

Your project is becoming an entire platform.

---

# My Top 5 for Your Use Case

```text
1. ArthX
2. Niveshak
3. NiveshForge
4. BharatOMS
5. EquityEngine
```

For a Rails monorepo with DhanHQ, AI agents, portfolio management, broker abstraction, paper exchange, and investment automation, **ArthX** or **Niveshak** are the strongest names because they don't lock you into a single feature like paper trading while remaining focused on Indian investing rather than crypto or global markets.

so we had first thr autonomouse investment engine and now paper engine so how would they fit in one like the autonomous engine and the paper engine where paper engine is for paper trading which can be used by the autonomous engine when user wants to do paper and when they use other adapters like dhanhq or kite it uses the brokers apis but for market data we need to allow seeting a adapter whihc user might use in future for real so allow setting data source by user as dhanhq or other and then deibale trading apis for that adapter if paper mode is on and only use the paper engine for executtion or trading

You're thinking about this correctly.

The mistake would be to make the autonomous investment engine directly depend on Dhan, Kite, or the Paper Engine.

Instead, split the system into **three independent layers**.

# Correct Architecture

```text
                    ┌──────────────────────┐
                    │ Autonomous Engine    │
                    │----------------------│
                    │ Research             │
                    │ Signals              │
                    │ Portfolio Mgmt       │
                    │ Risk Engine          │
                    │ Rebalancer           │
                    └──────────┬───────────┘
                               │
                               ▼
                    ┌──────────────────────┐
                    │ Trading Gateway      │
                    │----------------------│
                    │ Broker Selection     │
                    │ Market Data Routing  │
                    │ Order Routing        │
                    └───────┬───────┬──────┘
                            │       │
                            │       │
            ┌───────────────┘       └───────────────┐
            ▼                                       ▼

┌───────────────────┐               ┌─────────────────────┐
│ Market Data Layer │               │ Execution Layer     │
└─────────┬─────────┘               └──────────┬──────────┘
          │                                    │
          ▼                                    ▼

 Dhan Market Feed                     Dhan Broker
 Kite Market Feed                     Kite Broker
 Fyers Market Feed                    Fyers Broker
 Upstox Market Feed                   Upstox Broker

                                      Paper Broker
```

---

# Critical Design Rule

Market Data Provider and Execution Broker are NOT the same thing.

Most retail platforms incorrectly assume:

```text
Dhan Market Data
+
Dhan Trading
```

must always go together.

That is wrong.

---

# Example Configurations

## Configuration 1

Real Trading

```yaml
market_data_provider: dhan
execution_provider: dhan
```

---

## Configuration 2

Paper Trading Using Real Dhan Data

```yaml
market_data_provider: dhan
execution_provider: paper
```

This is probably your most common setup.

Flow:

```text
Dhan WebSocket
        ↓
Autonomous Engine
        ↓
Paper Broker
```

No live orders are sent.

---

## Configuration 3

Paper Trading Using Kite Data

```yaml
market_data_provider: kite
execution_provider: paper
```

---

## Configuration 4

Future Migration

```yaml
market_data_provider: kite
execution_provider: dhan
```

Possible because both are abstracted.

---

# User Configuration Model

```ruby
class TradingEnvironment < ApplicationRecord

  enum :mode,
  {
    paper: "paper",
    live: "live"
  }

  enum :market_data_provider,
  {
    dhan: "dhan",
    kite: "kite",
    fyers: "fyers",
    upstox: "upstox"
  }

  enum :execution_provider,
  {
    paper: "paper",
    dhan: "dhan",
    kite: "kite",
    fyers: "fyers",
    upstox: "upstox"
  }
end
```

---

# Provider Registry

## Market Data

```ruby
MarketData::Registry.fetch(
  environment.market_data_provider
)
```

Returns:

```ruby
DhanMarketDataAdapter
KiteMarketDataAdapter
FyersMarketDataAdapter
```

---

## Execution

```ruby
Execution::Registry.fetch(
  environment.execution_provider
)
```

Returns:

```ruby
PaperBrokerAdapter
DhanBrokerAdapter
KiteBrokerAdapter
```

---

# Safety Layer

This is mandatory.

If:

```yaml
mode: paper
```

Then:

```ruby
execution_provider != paper
```

must be rejected.

---

Example:

```ruby
class EnvironmentValidator

  def validate!

    return unless environment.paper?

    if environment.execution_provider != "paper"
      raise InvalidEnvironmentError,
        "Paper mode requires Paper execution provider"
    end
  end
end
```

---

# Better Approach

Don't even expose execution provider in paper mode.

User sees:

```text
Mode

○ Paper
○ Live
```

When user selects:

```text
Paper
```

System automatically becomes:

```yaml
market_data_provider: dhan
execution_provider: paper
```

or

```yaml
market_data_provider: kite
execution_provider: paper
```

---

# Autonomous Engine Should Never Know

The autonomous engine should never know:

```text
Paper Broker
Dhan
Kite
Fyers
```

It should only know:

```ruby
market_data = MarketDataGateway.current

execution = ExecutionGateway.current
```

Example:

```ruby
signal = SignalGenerator.generate

RiskValidator.validate!(signal)

execution.place_order(
  signal.to_order
)
```

The engine has no idea where the order goes.

---

# Final Architecture

I would split the repositories/modules like this:

```text
arthx-core
│
├── Research Engine
├── Signal Engine
├── Portfolio Engine
├── Risk Engine
├── Autonomous Engine
│
├── Market Data Gateway
│     ├── Dhan Adapter
│     ├── Kite Adapter
│     ├── Fyers Adapter
│     └── Upstox Adapter
│
└── Execution Gateway
      ├── Paper Broker
      ├── Dhan Adapter
      ├── Kite Adapter
      ├── Fyers Adapter
      └── Upstox Adapter
```

Then a user can run:

```text
Mode: Paper
Market Data: Dhan
Execution: Paper

OR

Mode: Paper
Market Data: Kite
Execution: Paper

OR

Mode: Live
Market Data: Dhan
Execution: Dhan

OR

Mode: Live
Market Data: Kite
Execution: Kite
```

without changing a single line of autonomous strategy code. That separation is what keeps the system extensible and prevents the autonomous engine from becoming tightly coupled to any broker.

The current design is still too "trading bot" oriented.

If the goal is:

```text
Autonomous Indian Investment Platform
```

then the architecture should be redesigned around **Investment Mandates**, not brokers or signals.

Most retail systems are:

```text
Indicators
 ↓
Signal
 ↓
Order
 ↓
Broker
```

That works for swing trading.

It is wrong for:

- Long-term investing
- SIP-style investing
- ETF investing
- Sector rotation
- Momentum investing
- Value investing
- Quality investing
- Portfolio rebalancing
- Dividend investing
- Smallcase-like baskets
- Swing trading
- Positional trading

---

# Redesign

Instead of:

```text
Signal Engine
```

Build:

```text
Investment Decision Engine
```

---

# New Architecture

```text
Autonomous Investment Platform

├── Market Data Layer
├── Research Layer
├── Screening Layer
├── Portfolio Layer
├── Allocation Layer
├── Decision Layer
├── Execution Layer
├── Risk Layer
├── Reporting Layer
└── Broker Layer
```

---

# Supported Segments

```text
NSE Equity

BSE Equity

ETF

REIT

INVIT

Mutual Funds

IPO

SGB

Bonds

NSE Futures

NSE Options

Index Options

Stock Options
```

Not every strategy needs every segment.

---

# Core Concept

Everything revolves around:

```ruby
InvestmentMandate
```

Example:

```ruby
LongTermWealthMandate

SwingTradingMandate

ETFAccumulationMandate

ValueInvestingMandate

MomentumMandate

DividendMandate

SectorRotationMandate
```

---

# Portfolio First

Current retail architecture:

```text
Signal
 ↓
Position
```

Better:

```text
Portfolio
 ↓
Allocation
 ↓
Decision
 ↓
Execution
```

---

Example

Portfolio:

```text
Capital

₹10,00,000
```

Target:

```text
40% ETF

30% Large Cap

20% Mid Cap

10% Cash
```

System decides:

```text
What to Buy

When to Buy

How Much to Buy

Whether to Hold
```

---

# Autonomous Engine

Instead of:

```text
Generate Buy Signal
```

Think:

```text
What is the best action for this portfolio?
```

Actions:

```ruby
BUY

SELL

ACCUMULATE

REDUCE

HOLD

REBALANCE

WAIT
```

---

# Decision Pipeline

```text
Market Data
      ↓

Research Engine
      ↓

Scoring Engine
      ↓

Portfolio Constraints
      ↓

Risk Engine
      ↓

Decision Engine
      ↓

Execution Engine
```

---

# Research Engine

Inputs:

```text
OHLCV

Fundamentals

Sector Data

Index Data

Macro Data

News

AI Research
```

Outputs:

```ruby
ResearchScore
```

Example:

```ruby
{
  symbol: "RELIANCE",

  quality: 85,

  valuation: 70,

  momentum: 90,

  growth: 88,

  conviction: 84
}
```

---

# Screening Engine

Like institutional stock screening.

Filters:

```text
ROE

ROCE

Revenue Growth

Debt

Promoter Holding

Volume

Momentum

Relative Strength
```

Output:

```text
Investment Universe
```

Example:

```text
Top 200 investable stocks
```

---

# Allocation Engine

One of the most important modules.

Example:

```text
Capital

₹10L
```

Target:

```text
Large Cap 40%

Mid Cap 20%

ETF 20%

Cash 20%
```

Produces:

```ruby
AllocationPlan
```

---

# Decision Engine

Instead of:

```text
RSI Crossed 60

BUY
```

Use:

```text
Portfolio Underweight

Research Score High

Risk Acceptable

BUY
```

---

Decision Object

```ruby
InvestmentDecision
```

```ruby
{
  action: "BUY",

  symbol: "RELIANCE",

  confidence: 87,

  allocation: 5
}
```

---

# Execution Layer

Completely isolated.

```text
Market Data Provider
```

Separate from:

```text
Execution Provider
```

As discussed.

---

# Example

Paper Mode

```yaml
market_data: dhan

execution: paper
```

---

Live Mode

```yaml
market_data: dhan

execution: dhan
```

---

Future

```yaml
market_data: kite

execution: dhan
```

Still works.

---

# Strategy Types

Each strategy becomes a plugin.

```ruby
Strategies::LongTermInvesting

Strategies::Momentum

Strategies::SwingTrading

Strategies::ETFAccumulation

Strategies::ValueInvesting

Strategies::DividendInvesting

Strategies::SectorRotation
```

Each implements:

```ruby
evaluate(portfolio)
```

Returns:

```ruby
InvestmentDecision
```

---

# Autonomous Agents

Your Ollama agents should not place trades.

They should only produce:

```ruby
ResearchReport

PortfolioReview

InvestmentRecommendation

RiskAssessment
```

Then deterministic services decide.

---

# Final Architecture

```text
                        User Portfolio
                               │
                               ▼

                    Investment Mandate Engine
                               │
                               ▼

                        Research Layer
                               │
                               ▼

                        Scoring Layer
                               │
                               ▼

                       Allocation Layer
                               │
                               ▼

                        Risk Layer
                               │
                               ▼

                     Investment Decisions
                               │
                               ▼

                      Execution Gateway
                               │
              ┌────────────────┴──────────────┐
              │                               │

        Paper Broker                    Live Broker
              │                               │

      Dhan Data Feed                 Dhan/Kite/Fyers
```

This redesign allows the same platform to manage:

- Long-term investing
- SIP-style accumulation
- ETF portfolios
- Swing trading
- Positional trading
- F&O strategies
- Paper trading
- Live trading

under one unified architecture centered on **portfolio objectives and investment mandates**, rather than individual trading signals.

No. This is one of the most important architectural boundaries in the entire system.

## Short Answer

### Core Investment Engine owns

```text
Instruments
Instrument Metadata
Corporate Actions
Fundamentals
Screeners
Watchlists
Market Data Abstractions
Market Data Storage
Historical Data
Research Data
```

### Paper Engine owns

```text
Simulated Order Book
Simulated Trades
Simulated Positions
Simulated Holdings
Simulated Funds
Simulated Ledger
Simulated Margin
Simulated Exchange
Simulated Broker
```

---

# Correct Separation

Think of it this way:

## Real World

### NSE

Provides:

```text
Instruments
Market Data
Corporate Actions
```

### Broker

Provides:

```text
Orders
Trades
Positions
Funds
Holdings
```

---

Your architecture should mirror reality.

---

# Stock Engine (Core)

This should be the source of truth.

```text
Core Engine

├── Instrument Master
├── Market Data
├── Historical Data
├── Corporate Actions
├── Fundamentals
├── Research
├── Screening
├── Portfolio Logic
├── Decision Engine
└── Risk Engine
```

Tables:

```text
instruments
instrument_aliases
exchanges
segments

market_ticks
market_quotes
market_depths
ohlcv_candles

corporate_actions

financial_statements
ratios

watchlists
research_reports
```

---

# Why Instruments DON'T Belong To Paper Engine

Bad:

```text
Paper Engine

└── instruments
```

Why?

Because:

```text
RELIANCE
TCS
INFY
NIFTY
BANKNIFTY
```

exist regardless of:

```text
Paper Trading
Dhan
Kite
Fyers
```

They are market entities.

Not broker entities.

---

# Market Data Doesn't Belong To Paper Engine

This is another common mistake.

Bad:

```text
Paper Engine

└── market_ticks
```

Then:

```text
Paper Mode
```

and

```text
Live Mode
```

would have different data stores.

Disaster.

---

Instead:

```text
Market Data Layer
        │
        ▼

Historical DB
Realtime Feed
```

shared by:

```text
Autonomous Engine

AND

Paper Engine
```

---

# What Paper Engine Should Consume

```text
Core Market Data
      │
      ▼

Paper Exchange
```

Example:

```ruby
tick = MarketDataGateway.latest("RELIANCE")

paper_exchange.process_tick(tick)
```

Paper Engine should NEVER fetch Dhan data directly.

---

# Better Architecture

```text
                         Core Platform
                         ─────────────

┌──────────────────────────────────────────────────┐
│                Instrument Master                 │
├──────────────────────────────────────────────────┤
│ Instruments                                      │
│ Corporate Actions                               │
│ Fundamentals                                    │
│ Segments                                        │
│ Exchanges                                       │
└──────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────┐
│                 Market Data Hub                  │
├──────────────────────────────────────────────────┤
│ Dhan Adapter                                    │
│ Kite Adapter                                    │
│ Fyers Adapter                                   │
│ Upstox Adapter                                  │
│ Historical Storage                              │
│ Tick Storage                                    │
│ Candle Storage                                  │
└──────────────────────────────────────────────────┘
                     │
                     │
          ┌──────────┴──────────┐
          │                     │
          ▼                     ▼

Autonomous Engine        Paper Engine
```

---

# Paper Engine

Paper Engine becomes:

```text
Paper Engine

├── Simulated Exchange
├── Simulated Broker
├── OMS
├── Matching Engine
├── Execution Simulator
├── Margin Engine
├── Position Engine
├── Holdings Engine
├── Funds Engine
├── Accounting Engine
├── Analytics Engine
└── Trade Journal
```

Tables:

```text
paper_orders
paper_order_events

paper_trades
paper_trade_costs

paper_positions
paper_holdings

paper_funds

paper_margin_accounts

paper_journal_entries

paper_events
```

Notice:

❌ No instruments

❌ No ticks

❌ No candles

❌ No corporate actions

---

# One Exception

Paper Engine may have cached snapshots.

Example:

```text
paper_market_snapshots
```

Purpose:

```text
Replay
Backtesting
Historical Simulations
```

But these are copies.

Not the master records.

---

# What I Would Build

For your autonomous Indian investing platform:

```text
arthx-core

├── instruments
├── market_data
├── fundamentals
├── corporate_actions
├── portfolios
├── mandates
├── research
├── screening
├── allocation
├── decisions
├── risk

arthx-paper

├── exchange
├── broker
├── oms
├── matching
├── execution
├── accounting
├── margin
├── journal
├── analytics
```

The rule is:

> If NSE/BSE knows about it, it belongs in the Core Engine.
>
> If a broker statement knows about it, it belongs in the Paper Engine.

Using that rule, **instruments and market data belong in the Core Investment Platform, not in the Paper Engine.**

Your analysis is mostly correct, but there is one architectural change I would make before writing a single line of code.

The current diagram still has a subtle flaw:

```text
Core Platform
      ↔
Paper Engine
```

This creates a future coupling problem.

Instead, introduce a third layer.

# Correct Enterprise Architecture

```text
                   ┌──────────────────────┐
                   │   Investment Core    │
                   └──────────┬───────────┘
                              │
                              ▼
                   ┌──────────────────────┐
                   │ Trading Runtime API  │
                   └───────┬───────┬──────┘
                           │       │
                           ▼       ▼

                 Paper Runtime   Live Runtime
```

---

# Investment Core

Owns:

```text
Instrument Master
Corporate Actions
Fundamentals
Research
Screening
Scoring
Watchlists

Market Data

Portfolios
Mandates
Strategies
Allocations
Risk Definitions

AI Agents
```

This is the brain.

It never executes orders.

---

# Trading Runtime API

This is the layer missing from the diagram.

Responsibilities:

```text
Order Submission

Position Queries

Holdings Queries

Funds Queries

Margin Queries

Execution Reports

Trade Events

Market Data Access
```

Contract:

```ruby
runtime.place_order
runtime.modify_order
runtime.cancel_order

runtime.positions
runtime.holdings
runtime.funds

runtime.subscribe_orders
runtime.subscribe_positions
```

---

# Paper Runtime

Owns:

```text
OMS
Matching Engine
Execution Simulator
Margin Engine
Accounting
Trade Journal
Paper Positions
Paper Holdings
Paper Funds
```

Can run:

```text
Paper Trading
Backtesting
Replay
Forward Testing
```

---

# Live Runtime

Owns:

```text
Broker Adapters
```

Examples:

```text
Dhan
Kite
Fyers
Upstox
```

---

# Why This Matters

Current diagram:

```text
Strategy
   ↓
Paper Engine
```

Future problem:

```text
Strategy
   ↓
Dhan

Strategy
   ↓
Paper
```

Different code paths.

Bad.

---

Instead:

```text
Strategy
    ↓
Trading Runtime
    ↓
Paper Runtime

or

Strategy
    ↓
Trading Runtime
    ↓
Live Runtime
```

Same code path.

---

# Market Data Architecture

This is another place I'd modify the diagram.

Current:

```text
Dhan Data
   ↓
Core
   ↓
Paper
```

Better:

```text
Market Data Service
```

Separate bounded context.

```text
Market Data Service

├── Instrument Master
├── Ticks
├── Quotes
├── Depth
├── Candles
├── Option Chains
├── Corporate Actions
└── Fundamentals
```

Consumed by:

```text
Investment Core

Paper Runtime

Live Runtime
```

---

# Final Service Boundaries

## Service 1

### Market Service

```text
arthx-market
```

Owns:

```text
Instruments
Market Data
Corporate Actions
Fundamentals
```

---

## Service 2

### Investment Service

```text
arthx-core
```

Owns:

```text
Research
Screening
Scoring
Portfolio
Mandates
Risk Policies
AI Agents
Decision Engine
```

---

## Service 3

### Runtime Service

```text
arthx-runtime
```

Contract:

```text
Orders
Trades
Positions
Holdings
Funds
```

---

## Service 4

### Paper Runtime

```text
arthx-paper
```

Owns:

```text
Exchange Simulation
Broker Simulation
Accounting
Replay
Backtesting
```

---

## Service 5

### Live Runtime

```text
arthx-brokers
```

Owns:

```text
Dhan Adapter
Kite Adapter
Fyers Adapter
Upstox Adapter
```

---

# What I Would Build First

Forget AI.

Forget portfolios.

Forget dashboards.

Build these modules first:

```text
arthx-market
```

- Instrument Master
- Market Data Ingestion
- Candle Storage

and

```text
arthx-paper
```

- Orders
- Trades
- Matching Engine
- Positions
- Ledger

Then connect them:

```text
Market Tick
      ↓
Paper Exchange
      ↓
Trade
      ↓
Position
      ↓
Ledger
```

When that loop works, the rest of the platform becomes layering on top of a solid foundation.

That would be the architecture I would approve for a production-grade autonomous Indian investment platform.

If we are building **arthx-paper** today, with your preferences and the Rails 8 ecosystem, I would not start with microservices.

Build a **modular monolith first**.

---

# Tech Stack

## Backend

```text
Ruby 3.4.x
Rails 8.1

PostgreSQL 17

Solid Queue
Solid Cache
Solid Cable

Puma

RSpec
FactoryBot
Faker

OpenAPI 3.1

dry-validation

money-rails
```

Rails 8 ships with a database-backed queueing and infrastructure approach that is well suited to a single-user or low-scale trading platform without introducing Redis and Sidekiq immediately. ([Wikipedia][1])

This also aligns with your long-standing preference of avoiding Redis/Sidekiq.

---

# Repository Structure

```text
arthx-paper/

app/
├── domains/
│
├── accounting/
│
├── exchange/
│
├── oms/
│
├── portfolio/
│
├── margin/
│
├── risk/
│
├── events/
│
├── api/
│
└── jobs/

spec/

db/

config/

docs/

openapi/
```

---

# Domain Driven Layout

## Exchange

```text
app/domains/exchange

exchange/
├── order_book.rb
├── matching_engine.rb
├── trade_processor.rb
├── market_simulator.rb
├── execution_engine.rb
└── slippage_engine.rb
```

Responsible for:

```text
Matching
Trade creation
Execution simulation
```

---

## OMS

```text
app/domains/oms
```

Contains:

```text
Orders

Validation

Cancellation

Modification
```

---

## Portfolio

```text
app/domains/portfolio
```

Contains:

```text
Positions

Holdings

PnL

MTM
```

---

## Accounting

```text
app/domains/accounting
```

Contains:

```text
Double Entry Ledger

Cash Ledger

Broker Charges

Tax Charges
```

---

## Margin

```text
app/domains/margin
```

Contains:

```text
SPAN

Exposure

Cash Margin

F&O Margin
```

Even if we don't implement all calculations initially.

---

# Rails Models

## Accounts

```ruby
Paper::Account
```

---

## Orders

```ruby
Paper::Order
```

---

## Trades

```ruby
Paper::Trade
```

---

## Positions

```ruby
Paper::Position
```

---

## Holdings

```ruby
Paper::Holding
```

---

## Funds

```ruby
Paper::FundAccount
```

---

## Ledger

```ruby
Paper::LedgerEntry
```

---

# Event Driven Architecture

Never call services directly.

Bad:

```ruby
TradeProcessor.new.call
PositionUpdater.new.call
LedgerUpdater.new.call
```

---

Use domain events.

```ruby
Events.publish(
  "trade.executed",
  trade_id:
)
```

Subscribers:

```ruby
PositionUpdater

LedgerUpdater

PnlUpdater

AuditLogger
```

---

# Initial Database

## accounts

```sql
id
name

cash_balance
blocked_balance

created_at
updated_at
```

---

## orders

```sql
id

account_id

symbol

exchange

segment

side

order_type

status

quantity

filled_quantity

price

trigger_price

created_at
updated_at
```

---

## trades

```sql
id

order_id

account_id

symbol

exchange

segment

side

quantity

price

executed_at
```

---

## positions

```sql
id

account_id

symbol

exchange

segment

quantity

average_price

realized_pnl

unrealized_pnl
```

---

## ledger_entries

```sql
id

account_id

entry_type

debit

credit

balance

reference_type

reference_id
```

---

# API V1

## Accounts

```http
POST /accounts

GET /accounts/:id
```

---

## Orders

```http
POST /orders

GET /orders

GET /orders/:id

DELETE /orders/:id
```

---

## Trades

```http
GET /trades
```

---

## Positions

```http
GET /positions
```

---

## Funds

```http
GET /funds
```

---

# Testing Strategy

## Unit Tests

```text
OrderValidator

MatchingEngine

PositionManager

LedgerManager
```

---

## Integration Tests

```text
Place Order

Create Trade

Update Position

Update Ledger
```

---

## End To End

```text
Account
 ↓
Order
 ↓
Trade
 ↓
Position
 ↓
PnL
```

---

# First Sprint Deliverable

A single RSpec should pass:

```ruby
account = create(
  :account,
  cash_balance: 100_000
)

order = Paper::OMS::CreateOrder.call(
  account: account,
  symbol: "RELIANCE",
  side: :buy,
  quantity: 10,
  price: 1500
)
```

Expected:

```ruby
expect(
  account.positions.first.quantity
).to eq(10)

expect(
  account.cash_balance
).to eq(85_000)
```

---

# After Sprint 1

Add:

```text
Market Orders

Limit Orders

Partial Fills

Order Book

FIFO Matching
```

Then:

```text
Broker Charges

STT

Exchange Charges

SEBI Charges

GST

Stamp Duty
```

Then:

```text
MIS

CNC

NRML

Margin Engine
```

Then:

```text
Market Data Adapter Interface
```

```ruby
MarketData::Adapter
```

Implementations:

```ruby
MarketData::DhanAdapter

MarketData::KiteAdapter

MarketData::ReplayAdapter
```

At that point the Paper Engine becomes capable of serving:

- Paper trading
- Forward testing
- Backtesting
- Broker simulation
- Strategy validation

and can later plug directly into the larger ArthX autonomous investment platform without any architectural rewrites.


For a trading/investment platform, there are two categories:

# Category A — Safe To Change On The Fly (Runtime Config)

These should be database-driven and hot reloadable.

---

## Market Data Provider

```text id="j0mksk"
Dhan
Kite
Fyers
Upstox
Replay
```

Example:

```ruby id="dnyodj"
TradingEnvironment.market_data_provider
```

Change:

```text id="zhjjv9"
Dhan → Kite
```

without restart.

---

## Execution Provider

```text id="6a6uoa"
Paper
Dhan
Kite
Fyers
```

Example:

```text id="6gjv86"
Paper Mode
↓
Live Mode
```

Should be instant.

---

## Trading Mode

```text id="glzh7h"
Paper

Live

Backtest

Replay
```

---

## Risk Limits

```text id="wjmjlwm"
Max Position Size

Max Exposure

Max Daily Loss

Max Symbol Exposure

Max Sector Exposure
```

These absolutely should be configurable live.

Institutional systems do this.

---

## Strategy Parameters

```text id="9mr8zq"
RSI Length

EMA Length

ATR Multiplier

Position Size %

Stop Loss %

Take Profit %
```

No deployment needed.

---

## Investment Mandates

```text id="llmdhb"
Long Term

Momentum

Swing

ETF Accumulation
```

Can switch instantly.

---

## Broker Charges

```text id="4u79cn"
Brokerage

Exchange Charges

GST

STT
```

Should come from DB tables.

---

## Slippage Models

```text id="clxf88"
Fixed

Percentage

ATR Based

Depth Based
```

Runtime configurable.

---

## Margin Rules

```text id="0w0m8r"
CNC

MIS

NRML
```

Hot reload.

---

## Market Sessions

```text id="hvyz7h"
Pre Market

Normal

Post Market
```

DB-driven.

---

# Category B — Configurable But Requires New Records

These are dynamic but not "settings".

---

## Instruments

```text id="n4a6ch"
RELIANCE

TCS

NIFTY

BANKNIFTY
```

Loaded from instrument master.

---

## Watchlists

```text id="5f31ww"
Nifty50

Momentum Basket

ETF Basket
```

---

## Portfolios

```text id="wwt09h"
Growth

Retirement

Swing
```

---

## Universes

```text id="iwk7c3"
Nifty500

FnO

Midcap150
```

---

# Category C — NEVER Change On The Fly

These should require deployment/version upgrades.

---

## Matching Engine Logic

Bad:

```text id="wjc6ly"
FIFO
↓
Pro-rata
```

while orders exist.

Disaster.

Version it.

---

## Ledger Accounting Rules

Never hot change.

Example:

```text id="y4if69"
Position Debit

Cash Credit
```

Must be deterministic forever.

---

## Event Schema

Bad:

```json id="i6ik6g"
{
  "trade_id":1
}
```

↓

```json id="h0xsbv"
{
  "id":1
}
```

without versioning.

---

## Order State Machine

Never change live.

```text id="w2on66"
NEW
OPEN
FILLED
```

is core business logic.

---

## Trade Settlement Logic

```text id="zqegzx"
T+1
```

logic should be versioned.

---

## Position Calculation Engine

Average price calculations.

PnL calculations.

Do not hot edit.

---

# What Makes Sense For ArthX Paper

I would create a dedicated runtime settings subsystem.

```ruby id="1knk7e"
SystemSetting

RiskProfile

BrokerProfile

MarketDataProfile

ExecutionProfile
```

Example:

```yaml id="qj8y0q"
market_data_provider: dhan

execution_provider: paper

max_position_size: 100000

max_daily_loss: 5000

slippage_model: depth_based

broker_profile: dhan
```

Then the engine loads:

```ruby id="g1q1o8"
CurrentRuntimeConfig.instance
```

and refreshes every 30–60 seconds.

---

# Ultimate Goal

A user should be able to do this from the UI:

```text id="j0jkz0"
Market Data
--------------
Dhan

Execution
--------------
Paper

Risk Profile
--------------
Conservative

Strategy
--------------
Swing Momentum

Max Daily Loss
--------------
₹5,000
```

Click Save.

No deployment.

No restart.

No migration.

The system immediately starts operating under the new configuration.

Those are the parts that should be "on the fly". The matching engine, accounting engine, order lifecycle, and core execution semantics should remain code-driven and versioned.

After reviewing the TDD, I would significantly change the implementation plan.

The TDD itself is good as a target architecture, but it is **far too large for Sprint 1**.

If you try building:

```text
Market Simulator
Depth Simulator
Spread Simulator
News Simulator
Matching Engine
OMS
Execution Simulator
Positions
Holdings
Funds
Margin
Accounting
Risk
Analytics
Reports
```

before proving the core execution loop, you'll spend months building infrastructure without validating the system.

---

# What I Would Change

The TDD mixes:

```text
Core Domain
+
Infrastructure
+
Analytics
+
Simulation Enhancements
+
Reporting
```

into one implementation phase.

Instead:

```text
Phase 1 = Execution correctness

Phase 2 = Accounting correctness

Phase 3 = Market realism

Phase 4 = Analytics

Phase 5 = Autonomous trading integration
```

---

# New Build Order

## Phase 0

Repository Bootstrap

```bash
rails new arthx-paper \
  --api \
  --database=postgresql \
  --skip-action-mailer \
  --skip-active-storage
```

Add:

```ruby
rspec-rails
factory_bot_rails
faker
aasm
dry-validation
money-rails
```

Nothing else.

No Kafka.

No Redis.

No Timescale.

No Sidekiq.

No Ollama.

No Dhan.

---

# Phase 1

## Core Trading Loop

This is the smallest valuable system.

Build only:

```text
Account
Order
Trade
Position
```

Tables:

```text
accounts
orders
trades
positions
```

Services:

```text
PlaceOrder

TradeProcessor

PositionUpdater
```

Goal:

```text
BUY 10 RELIANCE @ 1000

↓

Trade

↓

Position

↓

Cash Reduced
```

Nothing else.

---

# Phase 2

## Double Entry Accounting

Now add:

```text
LedgerEntry

JournalEntry

FundsAccount
```

Every trade must generate:

```text
Debit
Credit
```

entries.

After this phase:

```text
Position
=
Derived

Ledger
=
Source Of Truth
```

This is a major architectural milestone.

The TDD correctly identifies the ledger as critical.

---

# Phase 3

## OMS

Add:

```text
OPEN

PARTIAL

FILLED

REJECTED

CANCELLED
```

state machine.

Now:

```text
Market Order

Limit Order

Modify

Cancel
```

become possible.

---

# Phase 4

## Matching Engine

This is where most people start.

They shouldn't.

Now build:

```text
OrderBook

FIFO

Price-Time Priority

Partial Fills
```

Exactly as described in the TDD.

---

# Phase 5

## Risk & Margin

Add:

```text
Capital Checks

Position Limits

Exposure Limits

Margin Blocking
```

before execution.

---

# Phase 6

## Charges Engine

Implement:

```text
Brokerage

STT

GST

Exchange Charges

SEBI Charges

Stamp Duty
```

The TDD is correct that this must be table-driven.

---

# Phase 7

## Market Data Integration

Create interface:

```ruby
MarketData::Adapter
```

Implement:

```ruby
MarketData::ReplayAdapter
```

first.

Not Dhan.

Not Kite.

Replay adapter.

Reason:

```text
Deterministic testing
```

---

# Phase 8

## Backtesting

Now connect:

```text
Historical Candle

↓

Replay Clock

↓

Order

↓

Trade

↓

Position

↓

PnL
```

---

# Phase 9

## Paper Trading

Now add:

```ruby
MarketData::DhanAdapter
```

using your DhanHQ gem.

Only market data.

No live trading.

---

# Phase 10

## Realistic Simulation

Now add:

```text
Latency Simulator

Spread Simulator

Depth Simulator

Slippage Simulator
```

The TDD includes all of these, but they are advanced realism layers, not foundations.

---

# Phase 11

## Broker Emulation Profiles

```text
Dhan Profile

Kite Profile

Fyers Profile

Upstox Profile
```

Each profile defines:

```yaml
charges
margin
product_rules
squareoff_time
```

---

# Phase 12

## Event Bus

Only now introduce:

```text
Kafka
```

or

```text
Rails Event Store
```

because by now you actually have events worth publishing.

---

# Phase 13

## Analytics

Build:

```text
Trade Book

PnL

Performance

Drawdown

Win Rate

Sharpe
```

---

# Phase 14

## Autonomous Platform Integration

Finally:

```text
ArthX Core
      ↓
Execution Gateway
      ↓
Paper Engine
```

---

# What I Would Remove From V1 Entirely

The current TDD includes several things that should not exist in the first year:

```text
News Simulator

Event Simulator

Depth Synthesis

Circuit Simulation

Holiday Engine

Kafka

Prometheus

Grafana

ELK

MinIO
```

These are scale concerns.

You do not have scale yet.

---

# Recommended First 30 Days

Week 1

```text
Rails Setup

Accounts

Orders

Trades

Positions
```

Week 2

```text
Ledger

Funds

Accounting
```

Week 3

```text
OMS

State Machine

Order Validation
```

Week 4

```text
Order Book

Matching Engine

FIFO Matching
```

If, after 30 days, you can execute:

```text
BUY 100 RELIANCE

↓

Trade

↓

Position

↓

Ledger

↓

PnL
```

without bugs, you will have completed the hardest 20% of the system that enables the remaining 80%. The TDD should remain the north-star architecture, but the implementation plan should be aggressively reduced to the execution core first.

Yes. In fact, if you're serious about building a broker-grade Paper Engine, I would go even further:

**Positions, Holdings, Funds, Margin Utilization, Realized P&L, Cash Balance should all be projections of the ledger and trade events, not primary writable tables.**

This is how serious trading systems, clearing systems, and accounting systems are designed.

---

# The Wrong Approach

Most retail trading platforms do:

```text
orders
trades

positions
holdings
funds
```

Trade executes:

```ruby
position.qty += 10
funds.balance -= 10000
```

Problems:

- Position drift
- Cash drift
- Reconciliation nightmares
- Difficult replay
- Difficult auditing
- Bugs impossible to trace

---

# Better Architecture

## Source Of Truth

```text
orders
trades

ledger_entries
```

Everything else is derived.

---

# Trade Example

BUY 100 RELIANCE @ 1000

Trade Value:

```text
100 × 1000 = 100,000
```

---

## Ledger

```text
Account                     Debit       Credit

Inventory:RELIANCE         100,000
Cash                                       100,000
```

---

Sell 40 RELIANCE @ 1200

```text
40 × 1200 = 48,000
```

Ledger:

```text
Cash                        48,000
Inventory:RELIANCE                       40,000

RealizedPnL                                8,000
```

---

# Position Calculation

No positions table required.

Calculate:

```sql
SELECT
  symbol,
  SUM(quantity_delta)
FROM trade_lots
GROUP BY symbol
```

Result:

```text
RELIANCE = 60
```

Current Position.

---

# Position Sizing

This becomes trivial.

---

## Scale In

Buy 100

```text
100 @ 1000
```

Buy 50

```text
50 @ 1100
```

Ledger:

```text
Inventory = 155,000
Qty = 150
```

Average:

```text
155000 / 150

1033.33
```

---

## Scale Out

Sell 25

```text
25 @ 1200
```

Position Projection:

```text
Qty = 125
```

Average remains:

```text
1033.33
```

---

# Futures Position

Same concept.

```text
NIFTY FUT

+50
+50
-25
```

Projection:

```text
75
```

---

# Option Position

```text
NIFTY 25000 CE

+150
-75
```

Projection:

```text
75
```

No special logic.

---

# Recommended Data Model

## Immutable Tables

```text
paper_orders

paper_trades

ledger_entries

corporate_action_events

margin_events
```

Only inserts.

Never updates.

---

## Read Models

Generated asynchronously.

```text
position_snapshots

holding_snapshots

fund_snapshots

risk_snapshots

analytics_snapshots
```

Can be rebuilt anytime.

---

# Event Sourcing Pattern

Trade executes.

```text
TradeExecuted
```

event emitted.

---

Consumers:

```text
PositionProjector

HoldingProjector

FundProjector

MarginProjector

AnalyticsProjector
```

Each builds its own view.

---

# Hybrid Model (What I Recommend)

Pure ledger-only calculation for every API call becomes expensive.

Bad:

```sql
10 million trades

↓

calculate position
```

for every request.

---

Instead:

## Write Side

```text
orders

trades

ledger_entries
```

Immutable.

---

## Read Side

```text
positions

holdings

funds
```

Projection tables.

Updated immediately after trade.

---

Flow:

```text
Trade
 ↓
Ledger
 ↓
Event

 ├─ Position Projection
 ├─ Holding Projection
 ├─ Fund Projection
 └─ Margin Projection
```

---

# For ArthX Paper

I would build:

### Source of Truth

```text
paper_orders

paper_trades

ledger_entries
```

### Projections

```text
paper_positions

paper_holdings

paper_funds

paper_margin_accounts
```

### Rebuild Capability

```ruby
Paper::RebuildPositions.call

Paper::RebuildFunds.call

Paper::RebuildLedger.call
```

Any projection can be dropped and regenerated from:

```text
paper_trades
+
ledger_entries
```

---

# One Additional Improvement

For position sizing and scale-in/scale-out support, add a trade lot table.

```text
trade_lots

id
trade_id
instrument_id

open_qty
closed_qty

entry_price

remaining_qty
```

This enables:

```text
FIFO
LIFO
Weighted Average
```

realized P&L methods.

Then:

```text
BUY 100 @ 1000
BUY 50 @ 1100
SELL 75 @ 1200
```

can correctly calculate:

- Remaining position
- Average price
- Realized P&L
- Unrealized P&L
- Tax lots
- Holding period

without hacks.

For the Paper Engine, my recommendation is:

```text
Orders
      ↓
Trades
      ↓
Double Entry Ledger
      ↓
Events
      ↓
Position/Holding/Fund Projections
```

This gives you broker-grade auditability while still providing fast position queries.

Yes. The earlier plan was too broad for the paper engine. The TDD is explicit that the paper engine is a **complete exchange + broker simulation** with **derived positions/holdings/funds/margin/accounting**, and it **does not own instruments, market data, or research**; those stay in the Core Platform. That boundary is the key constraint for the implementation plan.

## Reassessed implementation plan

### Phase 0 — Rails skeleton, contracts, and config model

Build the paper engine as a standalone Rails service first, with Postgres tables for `orders`, `trades`, `positions`, `holdings`, `funds`, `ledger_entries`, `events`, and `config`. The TDD is clear that paper-side tables are tenant/mode scoped and that replay/backtest needs deterministic config, including RNG seed.

**Scenarios**

- Create a paper account
- Create isolated paper/backtest runs
- Load per-run config: slippage model, latency model, brokerage plan, RNG seed
- Expose a minimal API contract matching the live execution gateway

**Edge cases**

- Duplicate order submission idempotency
- Tenant isolation across parallel runs
- Backtest runs must not leak state into paper mode
- Same payload shape as live broker adapters

---

### Phase 1 — Order lifecycle and OMS

Implement the order domain and lifecycle first: `place`, `modify`, `cancel`, validation, and state transitions. The TDD defines the OMS responsibilities and order lifecycle explicitly: `PENDING → OPEN → PARTIALLY_FILLED → FILLED`, with `CANCELLED`, `EXPIRED`, and `REJECTED` branches.

**Scenarios**

- Market order accepted during market hours
- Limit order accepted and rests in book
- Modify quantity/price before fill
- Cancel before any fill
- Partial fill followed by cancel
- Expiry at TIF/EOD
- Rejection for invalid product type / tick size / lot size / price band

**Edge cases**

- Order arrives outside market hours
- Order rejected because circuit band is breached
- Duplicate order IDs from retries
- Cancel after full fill
- Modify after partial fill
- Invalid CNC/MIS/NRML combination
- Lot-size violation for F&O

---

### Phase 2 — Matching engine and paper exchange

Now build the actual exchange simulator: order book, matching, partial fills, slippage, and event emission. The TDD’s paper exchange scope includes ticks, depth, spread, news/events, and a matching engine with price-time priority and partial fills.

**Scenarios**

- FIFO matching at same price
- Multiple buy/sell orders on same symbol
- Partial fill against limited liquidity
- Zero-slippage test mode
- Fixed-bps slippage mode
- Depth-based impact mode
- Historical replay driving the same execution path as live paper

**Edge cases**

- Illiquid symbol with no depth
- Wide spread at open/close
- Option strike-specific order books
- Orders resting across multiple ticks
- Non-deterministic behavior in backtest if sequence numbers are not fixed
- Replay gaps in historical data
- Circuit-halt session where orders must be held or rejected, not silently dropped

---

### Phase 3 — Trade processor and immutable event log

After fills exist, make trade creation and event emission authoritative. The TDD states that trade confirmations drive ledger updates, and every transition should be emitted to the event bus. Positions/holdings/funds must be rebuildable by replaying `paper_trades` and `paper_events`.

**Scenarios**

- One trade fills one order
- Multiple trade fills per order
- One order generates partial fills over time
- Event published after each fill
- Rebuild positions from trade log

**Edge cases**

- Duplicate trade event from retry
- Missing event delivery
- Out-of-order event consumption
- Trade reversal/compensation
- Idempotent write on `trade_id`

---

### Phase 4 — Double-entry accounting and derived projections

This is where the paper engine becomes broker-grade instead of a toy simulator. The TDD makes accounting, funds, margin, and risk part of the paper accounting layer, and it explicitly says these are **derived state** from immutable trades and events.

**Scenarios**

- Buy reduces cash and increases inventory/position value
- Sell realizes P&L and updates cash
- Charges posted at confirmation time
- Daily MTM updated from market moves
- Projection rebuild from ledger + trades

**Edge cases**

- Scale-in and scale-out on same symbol
- Intraday netting vs carry-forward positions
- Corporate-action adjustment on open holdings
- Negative cash / blocked funds
- Reconciliation after a failed projection update
- Rebuild projections from scratch after deletion

---

### Phase 5 — Risk, margin, and India-specific charges

Now enforce pre-trade and post-trade controls: margin sufficiency, exposure limits, drawdown limits, and auto square-off logic. The TDD explicitly requires pre-trade checks, post-trade exposure monitoring, and portfolio-level drawdown controls. It also requires table-driven India-specific charges.

**Scenarios**

- Reject order when margin is insufficient
- Block order that exceeds per-symbol exposure
- Apply STT/GST/SEBI/exchange/stamp duty per config
- Trigger margin call when post-trade exposure breaks threshold
- Auto square-off on risk breach

**Edge cases**

- Charge-rate change without code change
- Different rates for equity delivery vs intraday vs F&O
- Order valid in paper but invalid under broker-profile rules
- Drawdown breach at strategy level
- Simulated “hold” during broker RMS delay

---

### Phase 6 — Market simulation realism

Only after the core loop works should you add realism layers: depth simulation, spread simulation, latency simulation, and event simulation. The TDD treats these as part of the paper exchange and paper broker realism stack, but they are not the foundation.

**Scenarios**

- Synthetic depth when real depth is absent
- Wider spreads on illiquid instruments
- Latency distribution for acknowledgements
- News/event injection for volatility testing
- Replay mode with deterministic pacing

**Edge cases**

- Open/close session volatility
- Expiry-day option chaos
- Holiday skipping, including exchange exceptions
- Halts and price-band locks
- Zero-liquidity symbols

---

### Phase 7 — Outputs and reporting

Now expose read models: portfolio overview, trade book, risk reports, tax reports, analytics, and exports. The TDD says these are read models only, built off the accounting layer and event log.

**Scenarios**

- Portfolio dashboard
- Trade ledger export
- Realized vs unrealized P&L
- Tax/charge report
- Strategy comparison report

**Edge cases**

- Projection lag
- Report rebuild from raw events
- Multiple concurrent backtest runs
- Strategy-level vs portfolio-level reporting mismatch

---

## What I would explicitly defer

I would **not** start with Kafka, Timescale, MinIO, Prometheus, Grafana, or the full UI. The TDD lists them as part of the broader stack, but the paper engine can and should be proven with Rails + Postgres first.

## The first real milestone

The first milestone is not “paper engine exists.” It is:

```text
BUY 10 RELIANCE
→ trade created
→ ledger updated
→ position projection updated
→ cash reduced
→ replay rebuild matches live projection
```

That milestone is directly aligned with the TDD’s requirement that all paper-side state be replayable from immutable trades and events.

If you want the next step, I’ll convert this into a **Sprint-by-Sprint engineering backlog** with exact epics, user stories, and acceptance criteria.

Phase 0 is not just "create Rails app".

Phase 0 establishes the **architectural invariants** that every later phase depends on.

If Phase 0 is wrong:

```text
OMS = rewrite
Ledger = rewrite
Replay = rewrite
Backtesting = rewrite
Multi-account = rewrite
```

So Phase 0 must solve:

```text
1. Isolation
2. Determinism
3. Auditability
4. Adapter Compatibility
5. Future Replay
```

---

# Phase 0 Goal

At the end of Phase 0 we should be able to:

```text
Create Paper Account

Create Paper Trading Run

Create Backtest Run

Load Runtime Config

Store Orders

Store Trades

Store Ledger Entries

Store Events

Replay Entire Run
```

No matching engine yet.

No positions yet.

No margin yet.

Just architecture.

---

# Rails Setup

## Create Application

```bash
rails new arthx-paper \
  --api \
  --database=postgresql \
  --skip-action-mailer \
  --skip-action-mailbox \
  --skip-active-storage \
  --skip-javascript
```

---

# Gems

```ruby
gem "rspec-rails"

gem "factory_bot_rails"

gem "faker"

gem "aasm"

gem "dry-validation"

gem "paper_trail"

gem "money-rails"

gem "oj"

gem "json_schemer"

gem "enumerize"

gem "pg"
```

---

# Domain Layout

```text
app/

domains/

  accounts/

  runtime/

  orders/

  trades/

  accounting/

  events/

  adapters/

  projections/

contracts/

serializers/

validators/
```

---

# Core Principle

Everything belongs to a Runtime.

Not Account.

Not User.

Runtime.

---

# Why?

Paper Trading:

```text
Paper Run #1
```

Backtest:

```text
Backtest Run #99
```

Forward Test:

```text
Forward Test Run #4
```

All isolated.

---

# Runtime Model

```ruby
class Runtime < ApplicationRecord

  enum :mode,
  {
    paper: "paper",
    backtest: "backtest",
    replay: "replay"
  }

  has_many :accounts

  has_one :runtime_config
end
```

---

# Runtime Table

```sql
create_table :runtimes do |t|

  t.string :name

  t.string :mode

  t.uuid :uuid

  t.boolean :active

  t.timestamps
end
```

Example:

```text
uuid: abc123

mode: paper
```

---

```text
uuid: xyz456

mode: backtest
```

Completely isolated worlds.

---

# Runtime Config

Most important table in Phase 0.

---

```ruby
class RuntimeConfig < ApplicationRecord

  belongs_to :runtime
end
```

---

Table

```sql
create_table :runtime_configs do |t|

  t.references :runtime

  t.string :slippage_model

  t.string :latency_model

  t.string :brokerage_plan

  t.integer :rng_seed

  t.jsonb :settings

  t.timestamps
end
```

---

Example

```json
{
  "slippage_model":"fixed_bps",
  "latency_model":"constant",
  "brokerage_plan":"dhan_equity",
  "rng_seed":42
}
```

---

# Why RNG Seed?

Replay.

---

Backtest today:

```text
Order Fill
Slippage = 0.21%
```

Replay tomorrow:

```text
Order Fill
Slippage = 0.21%
```

Must match exactly.

---

# Account Model

```ruby
class Account < ApplicationRecord

  belongs_to :runtime
end
```

---

Table

```sql
create_table :accounts do |t|

  t.references :runtime

  t.string :name

  t.string :currency

  t.timestamps
end
```

---

Example

```text
Runtime A

Account A
```

---

```text
Runtime B

Account A
```

Different accounts.

Same name.

No collision.

---

# Orders

Even before OMS exists.

---

```ruby
class Order < ApplicationRecord

  belongs_to :runtime

  belongs_to :account
end
```

---

Table

```sql
create_table :orders do |t|

  t.references :runtime

  t.references :account

  t.uuid :external_order_id

  t.string :symbol

  t.string :side

  t.string :order_type

  t.integer :quantity

  t.decimal :price

  t.string :status

  t.timestamps
end
```

---

# External Order ID

Critical.

---

Live broker:

```text
DHAN12345
```

Paper:

```text
PAPER12345
```

Replay:

```text
REPLAY12345
```

All stored.

---

# Trades

Immutable.

Never update.

---

```ruby
class Trade < ApplicationRecord

  belongs_to :runtime

  belongs_to :order
end
```

---

Table

```sql
create_table :trades do |t|

  t.references :runtime

  t.references :order

  t.string :symbol

  t.integer :quantity

  t.decimal :price

  t.datetime :executed_at

  t.timestamps
end
```

---

# Ledger Entries

Source of truth.

---

```ruby
class LedgerEntry < ApplicationRecord
end
```

---

```sql
create_table :ledger_entries do |t|

  t.references :runtime

  t.references :account

  t.string :entry_type

  t.decimal :amount

  t.string :reference_type

  t.bigint :reference_id

  t.timestamps
end
```

---

No positions yet.

No holdings yet.

---

# Event Store

Critical for replay.

---

```ruby
class DomainEvent < ApplicationRecord
end
```

---

```sql
create_table :domain_events do |t|

  t.references :runtime

  t.string :event_type

  t.jsonb :payload

  t.datetime :occurred_at

  t.timestamps
end
```

---

Examples

```json
{
  "event_type":"order.created"
}
```

---

```json
{
  "event_type":"trade.executed"
}
```

---

# Idempotency

Required.

---

Table

```sql
create_table :idempotency_keys do |t|

  t.references :runtime

  t.string :key

  t.string :resource_type

  t.bigint :resource_id

  t.timestamps
end
```

---

Scenario

Client retries:

```http
POST /orders
```

twice.

Same key.

Only one order.

---

# Runtime Isolation

Every query must be scoped.

---

Bad

```ruby
Order.all
```

---

Good

```ruby
runtime.orders
```

---

Add concern.

```ruby
module RuntimeScoped
end
```

All models include it.

---

# API Contract

Must match live adapters.

---

Never do:

```json
{
  "paper_order_id":1
}
```

---

Use:

```json
{
  "order_id":"PAPER123",
  "status":"OPEN"
}
```

Same shape as:

```text
Dhan

Kite

Fyers
```

---

Future:

```ruby
ExecutionGateway.place_order
```

---

Works with:

```text
Paper Adapter

Dhan Adapter

Kite Adapter
```

No code changes.

---

# Phase 0 Tests

Must pass.

---

Create Runtime

```ruby
runtime =
 Runtime.create!(mode: :paper)
```

---

Create Config

```ruby
runtime.create_runtime_config!
```

---

Create Account

```ruby
account =
 runtime.accounts.create!
```

---

Create Order

```ruby
runtime.orders.create!
```

---

Create Trade

```ruby
runtime.trades.create!
```

---

Create Ledger Entry

```ruby
LedgerEntry.create!
```

---

Create Event

```ruby
DomainEvent.create!
```

---

Replay

```ruby
ReplayRuntime.call(runtime)
```

Should reconstruct:

```text
Orders

Trades

Events
```

without errors.

---

# Definition Of Done

Phase 0 is complete when:

```text
✓ Runtime isolation works

✓ Config loading works

✓ Idempotency works

✓ Event store works

✓ Ledger storage works

✓ API contracts match future broker adapters

✓ Replay runtime boots successfully
```

Only after all of that should we move to **Phase 1 (OMS + Order Lifecycle)**, because every later subsystem will depend on these foundations.

# Phase 1 — OMS (Order Management System) & Order Lifecycle

Phase 0 created the foundation:

```text id="8j6vfi"
Runtime
RuntimeConfig
Account
Order
Trade
Ledger
Event Store
Idempotency
```

Phase 1 introduces the first real business capability:

```text id="m8hbpn"
Accept Order
Validate Order
Manage Order State
Cancel Order
Modify Order
Emit Events
```

Still:

```text id="xgh8v0"
NO Matching Engine
NO Positions
NO Holdings
NO Margin
NO Accounting Logic
```

Those come later.

---

# Goal

At the end of Phase 1:

```text id="f5x8ee"
POST /orders

↓

Order Created

↓

Status = OPEN

↓

Events Emitted
```

and

```text id="9h0pr0"
PATCH /orders/:id

↓

Modified
```

and

```text id="rhrl4p"
DELETE /orders/:id

↓

Cancelled
```

must work perfectly.

---

# Architecture

```text id="jc38mr"
OMS

├── Contracts
├── Validators
├── State Machine
├── Services
├── Events
└── APIs
```

---

# Order State Machine

Use AASM.

```ruby
class Order < ApplicationRecord
  include AASM

  aasm column: :status do

    state :pending, initial: true

    state :open

    state :partially_filled

    state :filled

    state :cancelled

    state :rejected

    state :expired

    event :accept do
      transitions from: :pending,
                  to: :open
    end

    event :fill do
      transitions from: [:open, :partially_filled],
                  to: :filled
    end

    event :partial_fill do
      transitions from: :open,
                  to: :partially_filled
    end

    event :cancel do
      transitions from: [:open, :partially_filled],
                  to: :cancelled
    end

    event :reject do
      transitions from: :pending,
                  to: :rejected
    end

    event :expire do
      transitions from: :open,
                  to: :expired
    end
  end
end
```

---

# Database Changes

## Orders Table

Add:

```ruby
change_table :orders do |t|

  t.string :exchange

  t.string :segment

  t.string :product_type

  t.string :validity

  t.string :correlation_id

  t.integer :filled_quantity,
            default: 0

  t.decimal :trigger_price

  t.decimal :average_price

  t.datetime :expires_at
end
```

---

# Enumerations

## Side

```ruby
BUY
SELL
```

---

## Order Type

```ruby
MARKET
LIMIT
SL
SLM
```

---

## Product Type

```ruby
CNC
MIS
NRML
```

---

## Validity

```ruby
DAY
IOC
GTD
```

---

# Order Contract

Never trust controller params.

---

```ruby
OMS::Contracts::CreateOrderContract
```

Using Dry Validation.

```ruby
params do

  required(:symbol).filled(:string)

  required(:side).filled(:string)

  required(:quantity).filled(:integer)

  required(:order_type).filled(:string)

  optional(:price).filled(:decimal)

end
```

---

# Order Validator

Separate business validation.

```ruby
OMS::OrderValidator
```

Checks:

```text id="l6igyk"
Positive Quantity

Valid Side

Valid Product

Valid Order Type

Valid Price

Valid Trigger
```

---

# Future Validator Hook

Don't implement now.

Create interface.

```ruby
validate_market_rules
```

Later:

```text id="e6g2e3"
Lot Size

Price Band

Circuit Limits

Freeze Limits
```

---

# Create Order Service

```ruby
OMS::CreateOrder
```

Flow:

```text id="j3b77v"
Validate

↓

Create Order

↓

Accept

↓

Publish Event
```

---

Pseudo:

```ruby
call

  validate

  order = create

  order.accept!

  publish

  order
```

---

# Modify Order

```ruby
OMS::ModifyOrder
```

Allowed:

```text id="73hj5k"
OPEN

PARTIALLY_FILLED
```

Not Allowed:

```text id="vj20kq"
FILLED

REJECTED

CANCELLED
```

---

Scenario

```text id="z6h48j"
BUY

100

↓

filled 20

↓

modify remaining 80
```

Allowed.

---

# Cancel Order

```ruby
OMS::CancelOrder
```

Allowed:

```text id="r8lcvv"
OPEN

PARTIALLY_FILLED
```

---

Not Allowed:

```text id="zqwhgx"
FILLED
```

---

# Events

Every state change emits event.

---

## Order Created

```json
{
  "event":"order.created"
}
```

---

## Order Accepted

```json
{
  "event":"order.accepted"
}
```

---

## Order Modified

```json
{
  "event":"order.modified"
}
```

---

## Order Cancelled

```json
{
  "event":"order.cancelled"
}
```

---

## Order Rejected

```json
{
  "event":"order.rejected"
}
```

---

Store all in:

```text id="8ffn7l"
domain_events
```

---

# API

## Create

```http
POST /api/v1/orders
```

Request:

```json
{
  "account_id":"1",

  "symbol":"RELIANCE",

  "side":"BUY",

  "order_type":"LIMIT",

  "quantity":100,

  "price":1500
}
```

---

Response

```json
{
  "order_id":"PAPER123",

  "status":"OPEN"
}
```

---

## Modify

```http
PATCH /api/v1/orders/:id
```

---

## Cancel

```http
DELETE /api/v1/orders/:id
```

---

## Show

```http
GET /api/v1/orders/:id
```

---

## List

```http
GET /api/v1/orders
```

---

# Idempotency

Already built in Phase 0.

Now enforce it.

---

Header

```http
Idempotency-Key:
```

---

Duplicate request:

```http
POST /orders
```

must return:

```text id="a9n7zw"
Same Order
```

Not create second order.

---

# Critical Edge Cases

## Duplicate Submit

```text id="t9rv30"
Client Timeout

↓

Retries

↓

Same Order Returned
```

---

## Cancel Twice

```text id="c9j0dm"
OPEN

↓

CANCELLED

↓

CANCEL AGAIN
```

Return:

```text id="3smf5q"
409
```

---

## Modify Filled Order

```text id="v1or5p"
FILLED
```

Reject.

---

## Modify Cancelled Order

Reject.

---

## Negative Quantity

Reject.

---

## Zero Quantity

Reject.

---

## Market Order With Price

Normalize.

---

## Limit Order Without Price

Reject.

---

## Stop Loss Without Trigger

Reject.

---

## Invalid Product

Reject.

---

## Runtime Isolation

Critical.

---

Bad:

```ruby
Order.find(id)
```

---

Good:

```ruby
runtime.orders.find(id)
```

Every query scoped.

---

# RSpec Coverage

## Create Order

```ruby
creates order

accepts order

publishes event
```

---

## Modify Order

```ruby
updates quantity

updates price
```

---

## Cancel Order

```ruby
changes state
```

---

## Validation

```ruby
rejects invalid quantity

rejects invalid product

rejects invalid order type
```

---

## Idempotency

```ruby
same key

returns same order
```

---

# Definition Of Done

Phase 1 is complete when:

```text id="4v65jd"
✓ Create Order

✓ Modify Order

✓ Cancel Order

✓ State Machine Works

✓ Events Emitted

✓ Runtime Isolation Works

✓ Idempotency Works

✓ Full RSpec Coverage
```

Only then move to **Phase 2 (Trade Execution + Double Entry Ledger Foundation)**.

Notice:

```text id="y1bg14"
Still no matching engine.
Still no positions.
Still no holdings.
```

We're intentionally proving the OMS independently before introducing execution complexity. This keeps the architecture clean and testable.

# Phase 2 — Trade Execution + Double Entry Ledger Foundation

This is the phase where the Paper Engine stops being an OMS and becomes a financial system.

Phase 1 gave us:

```text id="a0z7iw"
Account
Runtime
Order Lifecycle
Events
Idempotency
```

Phase 2 introduces:

```text id="mn5fd5"
Trade Execution

Double Entry Accounting

Funds

Position Projections

Holding Projections

Replayability
```

---

# Critical Architectural Decision

This is where most retail platforms fail.

Do NOT do:

```ruby id="t0o2w7"
position.qty += 10

account.cash -= 10000
```

Never.

---

Source Of Truth becomes:

```text id="cikx13"
Trade
+
LedgerEntry
```

Everything else is derived.

---

# Goal

At end of Phase 2:

```text id="2bajq4"
Order
 ↓

Trade
 ↓

Ledger
 ↓

Position Projection
 ↓

Fund Projection
```

must work.

---

# Architecture

```text id="yupyrj"
Execution

├── Trade Processor
├── Ledger Engine
├── Event Publisher
└── Projection Engine
```

---

# New Models

---

## Trade

Already exists.

Now becomes immutable.

```ruby id="5qph3j"
class Trade < ApplicationRecord

  belongs_to :runtime

  belongs_to :order

end
```

No updates.

Ever.

---

# Trade States

Not required.

Trade is final.

```text id="x4yxyo"
Executed
```

That's it.

---

# Trade Fields

```ruby id="3vnyqh"
trade_id

runtime_id

order_id

symbol

side

quantity

price

trade_value

executed_at
```

---

Example

```text id="v4s8aj"
BUY

100

RELIANCE

1000
```

Trade Value

```text id="d95y5w"
100000
```

---

# Ledger Entry

Most important table.

---

```ruby id="4of8fr"
class LedgerEntry < ApplicationRecord
end
```

---

Table

```ruby id="m8otku"
entry_type

account_code

debit

credit

reference_type

reference_id
```

---

# Ledger Accounts

Create chart of accounts.

---

## Asset Accounts

```text id="p0r6w7"
Cash

Inventory
```

---

## Liability

```text id="1m1q26"
Blocked Funds
```

---

## Income

```text id="hv79uo"
RealizedPnL
```

---

## Expense

```text id="pxm7h2"
Brokerage

Charges

Taxes
```

---

# Example Trade

BUY

```text id="44s8dn"
100

RELIANCE

1000
```

---

Value

```text id="xyazru"
100000
```

---

Ledger

```text id="3h9jk7"
Inventory:RELIANCE

Debit

100000
```

---

```text id="dljhxr"
Cash

Credit

100000
```

---

Balanced.

Always.

---

# Ledger Engine

Service

```ruby id="8q0g3o"
Accounting::LedgerEngine
```

---

Flow

```text id="q0rlj0"
Trade

↓

Generate Entries

↓

Persist Entries

↓

Verify Balance
```

---

Validation

```ruby id="mf2zup"
debits == credits
```

Must always pass.

---

# Trade Processor

New service.

```ruby id="xg5ox4"
Execution::TradeProcessor
```

---

Input

```ruby id="lj0ncl"
order
```

---

Output

```ruby id="z1e6lv"
trade
```

---

Flow

```text id="kknz86"
Create Trade

↓

Create Ledger Entries

↓

Emit Event
```

---

# Events

---

## Trade Executed

```json id="o4v00d"
{
  "event":"trade.executed"
}
```

---

## Ledger Posted

```json id="7gb2yy"
{
  "event":"ledger.posted"
}
```

---

# Projection Layer

Now we introduce read models.

---

# Why?

Querying ledger every request:

```sql id="x66l97"
10M rows
```

is stupid.

---

Instead:

```text id="q0z0hf"
Ledger
 ↓
Projection
```

---

# Position Projection

Table

```ruby id="mmbopd"
paper_positions
```

---

Fields

```ruby id="1u8g2w"
runtime_id

account_id

symbol

quantity

average_price

realized_pnl

unrealized_pnl
```

---

# Position Projector

Subscriber

```ruby id="nqoqcc"
PositionProjector
```

Listens:

```text id="v0fkvq"
trade.executed
```

---

Example

Trade

```text id="q4sh2o"
BUY

100

1000
```

Projection

```text id="92lkie"
Qty

100

Avg

1000
```

---

# Scale In

BUY

```text id="h0r8uw"
100 @ 1000
```

BUY

```text id="lrvx6n"
50 @ 1200
```

---

Projection

```text id="lmof95"
Qty

150

Avg

1066.67
```

---

# Scale Out

SELL

```text id="0h2q9q"
25 @ 1300
```

---

Projection

```text id="fnf5y7"
Qty

125
```

---

Average unchanged.

---

# Funds Projection

Table

```ruby id="sn5c2y"
paper_funds
```

---

Fields

```ruby id="q47n6j"
cash_balance

blocked_balance

available_balance
```

---

Subscriber

```ruby id="ap2wqh"
FundsProjector
```

---

Trade

```text id="q9s6z0"
BUY
```

↓

Cash reduces.

---

SELL

↓

Cash increases.

---

# Holding Projection

Separate.

---

Table

```ruby id="0h35g9"
paper_holdings
```

---

Only delivery holdings.

---

Future

```text id="0vdn2l"
T+1

Corporate Actions
```

depend on this.

---

# Replay Engine

First version.

---

```ruby id="5rq9rn"
ReplayRuntime.call(runtime)
```

---

Flow

```text id="o7oj3x"
Delete Projections

↓

Read Trades

↓

Rebuild Positions

↓

Rebuild Funds

↓

Rebuild Holdings
```

---

Must produce same result.

---

# APIs

---

## Trades

```http id="78fq95"
GET /trades
```

---

## Position

```http id="mg6xsb"
GET /positions
```

---

## Holdings

```http id="t4bfbz"
GET /holdings
```

---

## Funds

```http id="3o9ewr"
GET /funds
```

---

# Edge Cases

---

## Scale In

```text id="wzk8ur"
BUY

BUY

BUY
```

Average recalculated.

---

## Scale Out

```text id="grh2k7"
SELL partial
```

Qty reduced.

---

## Full Exit

```text id="3p32r9"
Qty

0
```

Position closed.

---

## Over Sell

```text id="qjzq1n"
Have

100

Sell

200
```

Reject.

---

## Replay

```text id="3x1e9s"
Delete projections

Replay
```

Same answer.

---

## Duplicate Trade Event

Projector must be idempotent.

---

## Ledger Imbalance

```text id="7t4k8l"
Debit != Credit
```

Fail transaction.

---

## Concurrent Trades

```text id="s5d8ww"
BUY

BUY
```

same symbol.

Projection must lock row.

Use:

```ruby id="nm4z41"
with_lock
```

---

# RSpec Coverage

---

## Ledger

```ruby id="h3czr8"
balanced entries
```

---

## Trade Processor

```ruby id="j6xgqf"
creates trade

creates ledger
```

---

## Position Projector

```ruby id="5xj4vk"
buy

sell

scale in

scale out
```

---

## Funds Projector

```ruby id="b9xg1h"
cash changes
```

---

## Replay

```ruby id="z6e4pn"
rebuilds projections
```

---

# Definition Of Done

Phase 2 completes when:

```text id="9y8t25"
✓ Trade Processor Exists

✓ Double Entry Ledger Exists

✓ Debits == Credits

✓ Position Projection Exists

✓ Funds Projection Exists

✓ Holdings Projection Exists

✓ Replay Engine Exists

✓ Full Replay Produces Same State

✓ All Tests Pass
```

At that point you have the first truly valuable artifact:

```text id="67yrhc"
Trade
 ↓
Ledger
 ↓
Position
 ↓
Funds
```

which becomes the foundation for:

- Matching Engine (Phase 3)
- Margin Engine (Phase 4)
- Risk Engine (Phase 5)
- Backtesting
- Paper Trading
- Broker Simulation

without needing to redesign the accounting model later.

# Phase 3 — Exchange Simulation & Matching Engine

Phase 0-2 built:

```text
Runtime
OMS
Trades
Double Entry Ledger
Positions Projection
Funds Projection
Replay Engine
```

But we still have a fake execution path:

```text
Order
 ↓
TradeProcessor
 ↓
Trade
```

There is no exchange.

No order book.

No liquidity.

No partial fills.

No price-time priority.

Phase 3 introduces the first actual market microstructure.

---

# Goal

Transform:

```text
Order
 ↓
Immediate Trade
```

into:

```text
Order
 ↓
Order Book
 ↓
Matching Engine
 ↓
Execution
 ↓
Trade
 ↓
Ledger
```

---

# Critical Design Decision

Many retail paper trading systems cheat:

```text
LTP = 100

BUY 100

↓

Filled @ 100
```

This is garbage.

A proper simulator must model:

```text
Bid
Ask
Spread
Depth
Liquidity
Queue Position
Partial Fills
```

---

# Architecture

```text
Paper Exchange

├── Order Book
├── Matching Engine
├── Execution Engine
├── Tick Processor
├── Market Data Gateway
└── Trade Publisher
```

---

# Ownership Boundary

Paper Engine DOES NOT own:

```text
Instruments
Market Data
Historical Data
Corporate Actions
```

Those come from Core Platform.

---

Paper Engine owns:

```text
Order Book
Liquidity
Matching
Execution
Trades
```

---

# New Models

## OrderBook

Not a DB table.

In-memory engine.

```ruby
Paper::Exchange::OrderBook
```

One per:

```text
NSE_EQ:RELIANCE

NSE_EQ:TCS

NSE_FNO:NIFTYFUT

NSE_FNO:NIFTY25000CE
```

---

# Internal Structure

```ruby
{
  bids: [],
  asks: []
}
```

---

Bid Example

```ruby
{
  price: 2500,
  quantity: 100,
  timestamp: ...
}
```

---

Ask Example

```ruby
{
  price: 2501,
  quantity: 200
}
```

---

# Matching Engine

Service

```ruby
Paper::Exchange::MatchingEngine
```

Responsible for:

```text
Price Priority

Time Priority

Partial Fills

Trade Creation
```

---

# Price-Time Priority

Must behave like NSE.

---

BUY

```text
100 @ 2500
```

---

Book

```text
SELL 100 @ 2500 (09:15:01)

SELL 100 @ 2500 (09:15:05)
```

---

Result

```text
First Order Filled First
```

---

Not:

```text
Random
```

---

# Tick Processor

Consumes:

```text
Market Data Adapter
```

from Core.

---

Receives:

```json
{
  "symbol":"RELIANCE",
  "ltp":2500,
  "bid":2499,
  "ask":2501
}
```

---

Updates:

```text
OrderBook
```

---

# Market Orders

Scenario

---

Book

```text
ASK

100 @ 2500

100 @ 2501
```

---

Order

```text
BUY MARKET 150
```

---

Fill

```text
100 @ 2500

50 @ 2501
```

---

Trades Generated

```text
Trade 1

Trade 2
```

---

Average

```text
2500.33
```

---

# Limit Orders

Book

```text
ASK

100 @ 2505
```

---

Order

```text
BUY LIMIT 2500
```

---

No Fill.

---

Status

```text
OPEN
```

---

Waits in book.

---

# Partial Fill

Book

```text
ASK

50 @ 2500
```

---

Order

```text
BUY 100
```

---

Result

```text
50 filled

50 remaining
```

---

State

```text
PARTIALLY_FILLED
```

---

# Execution Engine

Coordinates:

```text
Match
 ↓
Trade
 ↓
Ledger
 ↓
Projection
```

---

Service

```ruby
Paper::Execution::ExecutionEngine
```

---

Flow

```text
Order
 ↓
Matching
 ↓
Trade(s)
 ↓
Publish Event
```

---

# New Events

## Order Queued

```json
{
  "event":"order.queued"
}
```

---

## Trade Matched

```json
{
  "event":"trade.matched"
}
```

---

## Trade Executed

```json
{
  "event":"trade.executed"
}
```

---

# Liquidity Model V1

Start simple.

---

Do NOT build:

```text
Depth Simulator
Spread Simulator
Slippage Engine
```

yet.

---

Use:

```text
Top Of Book Only
```

---

Structure

```ruby
{
  bid_price: 2500,
  bid_qty: 1000,

  ask_price: 2501,
  ask_qty: 800
}
```

---

Enough for V1.

---

# Order Queue Position

Critical.

---

Order A

```text
09:15:01
BUY 100
```

---

Order B

```text
09:15:05
BUY 100
```

---

Seller arrives.

---

Fill:

```text
Order A

Then

Order B
```

---

Need queue position tracking.

---

# New Table

## ExecutionQueue

```ruby
paper_execution_queues
```

---

Fields

```ruby
runtime_id

symbol

side

price

order_id

queue_position
```

---

Could be removed later for Redis.

Keep in DB initially.

---

# Replay Support

Replay must rebuild:

```text
Order Books

Queue Positions

Trades
```

---

Deterministically.

---

Use:

```text
timestamp
sequence_number
```

on events.

---

# APIs

---

## Depth

```http
GET /depth/:symbol
```

---

Response

```json
{
  "bids":[...],
  "asks":[...]
}
```

---

## Order Book

```http
GET /orderbook/:symbol
```

---

## Executions

```http
GET /executions
```

---

# Edge Cases

---

## Market Closed

Order submitted.

---

Behavior

```text
REJECT
```

or

```text
QUEUE
```

depending config.

---

# IOC

No liquidity.

---

Behavior

```text
Cancel remainder
```

---

# Large Order

Book

```text
100 available
```

---

Order

```text
500
```

---

Fill

```text
100
```

---

Remain

```text
400
```

---

# Crossing Orders

Book

```text
SELL 2500
```

---

Incoming

```text
BUY 2600
```

---

Immediate Fill.

---

# Self Trade

Same account.

---

Configurable:

```text
Allow

or

Reject
```

---

# Replay Consistency

Replay run must generate:

```text
Same Trades

Same Average Price

Same Queue Position
```

every run.

---

# RSpec Coverage

## Matching Engine

```ruby
matches orders
```

```ruby
partial fills
```

```ruby
price priority
```

```ruby
time priority
```

---

## Market Orders

```ruby
fills against asks
```

---

## Limit Orders

```ruby
rests in book
```

---

## Queue

```ruby
older order fills first
```

---

## Replay

```ruby
same trades reproduced
```

---

# Definition Of Done

Phase 3 completes when:

```text
✓ Order Book Exists

✓ Matching Engine Exists

✓ Market Orders Work

✓ Limit Orders Work

✓ Partial Fills Work

✓ Price-Time Priority Works

✓ Queue Position Works

✓ Trade Events Generated

✓ Ledger Updates Triggered

✓ Replay Generates Same Result
```

At this point you have the first **real exchange simulator**.

The Paper Engine is no longer a mock broker.

It becomes:

```text
Mini NSE/BSE Simulation
      +
Broker Simulation
      +
Accounting System
```

which is the foundation needed before building:

```text
Phase 4 → Margin Engine
Phase 5 → Risk Engine
Phase 6 → Charges & Tax Engine
Phase 7 → Realism Layer
Phase 8 → Broker Profiles (Dhan/Kite/Fyers)
Phase 9 → Autonomous Trading Integration
```

# Phase 4 — Margin Engine, Capital Management & Broker Product Rules

Phase 3 gave us:

```text
OMS
↓
Order Book
↓
Matching Engine
↓
Trades
↓
Ledger
↓
Projections
```

But currently the system has a fatal flaw:

```text
User Cash = ₹100,000

BUY RELIANCE ₹5,000,000

↓

Accepted
```

Impossible.

A real broker would reject this long before the order reaches the exchange.

Phase 4 introduces the **Broker Layer**.

---

# Objective

Introduce:

```text
Funds Validation

Margin Blocking

Margin Release

Product Rules

Broker RMS

Capital Checks
```

before orders enter the matching engine.

New flow:

```text
Order
 ↓
Broker RMS
 ↓
Margin Engine
 ↓
Order Book
 ↓
Matching Engine
```

---

# Core Principle

Exchange does NOT care about margin.

Broker does.

Therefore:

```text
Paper Exchange
```

and

```text
Paper Broker
```

remain separate.

---

# Architecture

```text
Paper Broker

├── Margin Engine
├── RMS Engine
├── Capital Engine
├── Product Rules Engine
├── Exposure Engine
└── Margin Projection
```

---

# New Domain Models

## MarginAccount

Represents broker-side capital state.

```ruby
class MarginAccount < ApplicationRecord
end
```

---

Fields

```ruby
runtime_id

account_id

cash_balance

blocked_margin

available_margin

utilized_margin

mtm_pnl

realized_pnl
```

---

Example

```text
Cash = 100,000

Blocked = 20,000

Available = 80,000
```

---

# Margin Requirement

New table.

```ruby
margin_requirements
```

---

Fields

```ruby
segment

product_type

symbol

span_margin_pct

exposure_margin_pct

cash_requirement_pct
```

---

Examples

---

Equity CNC

```text
100%
```

---

MIS

```text
20%
```

---

NRML Futures

```text
15%
```

---

Options Buying

```text
100%
premium
```

---

Options Selling

```text
SPAN + Exposure
```

---

No hardcoding.

Everything configurable.

---

# Margin Calculator

Service

```ruby
Paper::Broker::MarginCalculator
```

---

Input

```ruby
order
```

---

Output

```ruby
required_margin
```

---

Example

```text
BUY

RELIANCE

100

₹2500
```

Value

```text
250000
```

---

CNC

```text
Required

250000
```

---

MIS

```text
Required

50000
```

---

# RMS Engine

Broker risk layer.

---

Service

```ruby
Paper::Broker::RMSEngine
```

---

Responsibilities

```text
Funds Check

Margin Check

Exposure Check

Order Freeze Check

Product Rules
```

---

Flow

```text
Order
 ↓
RMS
 ↓
Approve
or
Reject
```

---

# Funds Validation

Scenario

---

Account

```text
100000
```

---

Order

```text
BUY

150000
```

---

Result

```text
REJECTED
```

---

Reason

```text
INSUFFICIENT_FUNDS
```

---

# Margin Blocking

Critical.

---

Before order enters book:

```text
Required Margin
```

must be blocked.

---

Ledger Entry

```text
Cash

Credit
```

---

```text
Blocked Margin

Debit
```

---

Projection Updates

```text
available_margin
```

decreases.

---

# Margin Release

Order Cancelled.

---

Release:

```text
Blocked Margin
```

back to

```text
Available Margin
```

---

# Partial Fill Margin

Scenario

---

Order

```text
BUY

1000
```

---

Filled

```text
200
```

---

Cancelled

```text
800
```

---

Must release:

```text
Remaining Margin
```

only.

---

# Product Rules Engine

New service.

```ruby
Paper::Broker::ProductRules
```

---

Supports:

```text
CNC

MIS

NRML
```

---

CNC

```text
Delivery
```

---

MIS

```text
Intraday
```

---

NRML

```text
Carry Forward
```

---

# Example

CNC

---

Sell without holdings.

```text
Reject
```

---

MIS

---

Allow intraday short.

```text
Accept
```

---

# Position-Aware Margin

Phase 4 introduces netting.

---

Example

Current

```text
BUY 100
```

---

New Order

```text
SELL 100
```

---

Margin Requirement

```text
0
```

---

Position closes.

---

# Intraday Netting

Example

---

BUY

```text
100
```

---

SELL

```text
100
```

---

Exposure

```text
0
```

---

Margin Released.

---

# Exposure Engine

Tracks risk concentration.

---

Config

```yaml
max_symbol_exposure_pct: 20

max_segment_exposure_pct: 40

max_position_size: 10000000
```

---

Scenario

Portfolio

```text
100 lakh
```

---

Single Stock Exposure

```text
50 lakh
```

---

Limit

```text
20 lakh
```

---

Reject.

---

# New Projection

## Margin Projection

```ruby
paper_margin_accounts
```

---

Derived from:

```text
Ledger

Orders

Trades
```

---

Never primary source.

---

# New Events

---

Margin Blocked

```json
{
  "event":"margin.blocked"
}
```

---

Margin Released

```json
{
  "event":"margin.released"
}
```

---

Order Rejected

```json
{
  "event":"order.rejected"
}
```

---

Risk Breach

```json
{
  "event":"risk.breach"
}
```

---

# Futures Margin

Scenario

---

NIFTY FUT

```text
₹10,00,000
```

---

Margin

```text
15%
```

---

Required

```text
₹150,000
```

---

Order accepted only if:

```text
available_margin >= 150000
```

---

# Options Buying

Scenario

---

BUY CE

Premium

```text
₹50
```

Qty

```text
100
```

---

Required

```text
₹5,000
```

---

Simple.

---

# Options Selling

Scenario

---

SELL CE

````

Requires:

```text
SPAN

+

Exposure
````

---

Calculated using config table.

---

# Short Selling

Configurable.

---

Equity CNC

```text
Disallow
```

---

MIS

```text
Allow
```

---

Paper Mode

Can emulate:

```text
Dhan

Kite

Fyers

Upstox
```

later.

---

# Replay Requirements

Replay must reconstruct:

```text
Blocked Margin

Released Margin

Available Funds

Exposure
```

from:

```text
Trades

Orders

Ledger
```

---

No recalculation drift allowed.

---

# APIs

## Funds

```http
GET /api/v1/funds
```

---

Response

```json
{
  "cash":100000,
  "blocked":20000,
  "available":80000
}
```

---

## Margin

```http
GET /api/v1/margin
```

---

## Margin Estimate

```http
POST /api/v1/margin/calculate
```

---

Input

```json
{
  "symbol":"RELIANCE",
  "quantity":100
}
```

---

Returns

```json
{
  "required_margin":50000
}
```

---

# Edge Cases

## Order Cancel Before Fill

```text
Margin Released
```

---

## Partial Fill

```text
Release Unused Margin
```

---

## Modify Order Up

```text
Need Additional Margin
```

---

## Modify Order Down

```text
Release Excess Margin
```

---

## Gap Open

Position loses money.

---

MTM

```text
Negative
```

---

Available Margin drops.

---

## Margin Call

Threshold breached.

---

Emit

```text
margin.call
```

---

## Auto Square Off

Configurable.

---

Trigger:

```text
Available Margin < 0
```

---

Generate:

```text
Forced Exit Order
```

---

# RSpec Coverage

### Margin Calculator

```ruby
equity_cnc

equity_mis

futures

options
```

---

### RMS

```ruby
accept order

reject insufficient funds

reject exposure breach
```

---

### Margin Release

```ruby
cancel

partial fill
```

---

### Product Rules

```ruby
short sell validation

intraday validation
```

---

### Replay

```ruby
rebuild margin state
```

---

# Definition Of Done

Phase 4 is complete when:

```text
✓ Margin Engine Exists

✓ RMS Exists

✓ Capital Validation Exists

✓ Margin Blocking Works

✓ Margin Release Works

✓ Exposure Limits Work

✓ Product Rules Work

✓ Margin Projection Exists

✓ Replay Reconstructs Margin State

✓ Auto Square-Off Hooks Exist
```

At the end of Phase 4, the Paper Engine behaves like a real Indian broker's RMS layer.

```text
Client
 ↓
Paper Broker RMS
 ↓
Margin Engine
 ↓
Exchange Simulator
 ↓
Trade
 ↓
Ledger
```

Only after this phase should you build **Phase 5: Portfolio Risk Engine, Drawdown Controls, Strategy Limits, Kill Switches, and Multi-Strategy Risk Management**, because those risk systems depend on accurate margin and capital accounting.

# Phase 5 — Portfolio Risk Engine, Drawdown Controls, Kill Switches & Strategy Risk Management

Phase 4 made the Paper Engine behave like a broker.

Phase 5 makes it behave like a **professional prop desk / hedge fund risk system**.

This is where most retail platforms completely fail.

Retail systems usually stop at:

```text
Funds Check
Margin Check
```

Professional systems add:

```text
Portfolio Risk
Strategy Risk
Account Risk
Sector Risk
Correlation Risk
Drawdown Limits
Daily Loss Limits
Kill Switches
Circuit Breakers
```

---

# Objective

Prevent this:

```text
Strategy A
   ↓
Loses 30%

Strategy B
   ↓
Still keeps trading

Strategy C
   ↓
Still keeps trading
```

A professional system must stop itself.

---

# Architecture

```text
Paper Risk Engine

├── Portfolio Risk Manager
├── Strategy Risk Manager
├── Position Risk Manager
├── Drawdown Engine
├── Exposure Engine
├── Correlation Engine
├── Kill Switch Engine
├── Circuit Breaker Engine
└── Risk Projection Engine
```

---

# Risk Hierarchy

Risk must exist at multiple levels.

```text
Runtime
 ├── Portfolio
 │
 ├── Strategy
 │
 ├── Position
 │
 └── Order
```

---

# Example

Portfolio

```text
₹10,00,000
```

---

Strategy A

```text
₹2,00,000
```

---

Strategy B

```text
₹3,00,000
```

---

Strategy C

```text
₹5,00,000
```

Each can have separate limits.

---

# New Models

## Strategy

```ruby
class Strategy < ApplicationRecord
end
```

---

Fields

```ruby
runtime_id

name

code

status
```

---

Examples

```text
LONG_TERM

SWING

MOMENTUM

BREAKOUT

AI_INVESTOR
```

---

# Risk Profile

```ruby
class RiskProfile < ApplicationRecord
end
```

---

Fields

```ruby
runtime_id

strategy_id

max_daily_loss

max_drawdown

max_position_size

max_open_positions

max_symbol_exposure

max_sector_exposure
```

---

Example

```yaml
max_daily_loss: 5000

max_drawdown: 10%

max_open_positions: 10
```

---

# Position Risk

New Projection

```ruby
paper_position_risks
```

---

Tracks

```text
Market Value

Exposure

PnL

Risk Weight

Sector Exposure
```

---

# Drawdown Engine

Most important service.

---

```ruby
Risk::DrawdownEngine
```

---

Tracks:

```text
Equity Curve

Peak Equity

Current Equity

Drawdown
```

---

Formula

```text
Drawdown %

=
(Current Equity - Peak Equity)
/
Peak Equity
```

---

Example

Peak

```text
₹100,000
```

Current

```text
₹85,000
```

Drawdown

```text
-15%
```

---

# Daily Loss Engine

Tracks:

```text
Start Of Day Equity

Current Equity

Today's PnL
```

---

Example

Start

```text
₹100,000
```

Current

```text
₹94,000
```

---

Loss

```text
₹6,000
```

---

Limit

```text
₹5,000
```

---

Result

```text
Trading Halted
```

---

# Kill Switch Engine

Professional requirement.

---

Service

```ruby
Risk::KillSwitch
```

---

States

```text
ACTIVE

PAUSED

STOPPED
```

---

Example

```text
Daily Loss Breach
```

↓

```text
STOP ALL NEW ORDERS
```

---

Existing positions:

```text
Allowed
```

or

```text
Forced Exit
```

configurable.

---

# Strategy Kill Switch

Not portfolio-wide.

---

Scenario

```text
Breakout Strategy
```

loses

```text
10%
```

---

Only:

```text
Breakout Strategy Disabled
```

---

Momentum strategy continues.

---

# Position Sizing Guard

Before order enters RMS:

```text
Order
 ↓
Risk Engine
```

---

Check:

```text
Position Size
```

---

Example

Portfolio

```text
₹10 lakh
```

---

Rule

```text
Max Position = 5%
```

---

Allowed

```text
₹50,000
```

---

Order

```text
₹200,000
```

---

Reject.

---

# Open Position Limit

Rule

```yaml
max_open_positions: 20
```

---

Current

```text
20 Open
```

---

New Buy

```text
Rejected
```

---

# Symbol Exposure Limit

Example

Portfolio

```text
₹10 lakh
```

Rule

```yaml
max_symbol_exposure: 10%
```

---

Max

```text
₹100,000
```

---

Current RELIANCE

```text
₹90,000
```

---

New Order

```text
₹20,000
```

---

Reject.

---

# Sector Exposure Engine

Indian-specific.

---

Need sector mapping.

Comes from Core Platform:

```text
RELIANCE → Energy

INFY → IT

HDFCBANK → Banking
```

---

Rule

```yaml
max_sector_exposure: 30%
```

---

Portfolio

```text
₹10 lakh
```

---

IT Holdings

```text
₹4 lakh
```

---

Exposure

```text
40%
```

---

Reject new IT orders.

---

# Correlation Engine

Advanced.

Optional V1.1.

---

Example

User holds:

```text
HDFCBANK

ICICIBANK

AXISBANK
```

---

Different symbols.

Same risk.

---

Correlation Score

```text
0.9
```

---

Risk engine detects concentration.

---

Future enhancement.

Not mandatory V1.

---

# Concentration Risk

Tracks:

```text
Top 5 Holdings

Top 10 Holdings
```

---

Example

```text
80%
```

portfolio in

```text
RELIANCE
```

---

Emit warning.

---

# Risk Projection

Table

```ruby
paper_risk_snapshots
```

---

Stores

```ruby
portfolio_value

equity

drawdown

daily_pnl

open_positions

sector_exposure

symbol_exposure
```

---

Derived only.

Never source of truth.

---

# Events

## Daily Loss Breach

```json
{
  "event":"risk.daily_loss_breach"
}
```

---

## Drawdown Breach

```json
{
  "event":"risk.drawdown_breach"
}
```

---

## Position Limit Breach

```json
{
  "event":"risk.position_limit_breach"
}
```

---

## Kill Switch Activated

```json
{
  "event":"risk.kill_switch_activated"
}
```

---

# Order Flow Now

Before

```text
Order
 ↓
RMS
 ↓
Exchange
```

Now

```text
Order
 ↓
Risk Engine
 ↓
RMS
 ↓
Exchange
```

---

# Backtesting Support

Critical.

---

Risk Engine must run during:

```text
Paper Trading

Backtesting

Replay
```

---

Otherwise:

```text
Backtest Results
```

become unrealistic.

---

# Replay Requirements

Must reconstruct:

```text
Daily PnL

Drawdown

Exposure

Risk Breaches

Kill Switches
```

from:

```text
Trades

Ledger

Market Data
```

---

# APIs

## Portfolio Risk

```http
GET /api/v1/risk/portfolio
```

---

## Strategy Risk

```http
GET /api/v1/risk/strategies
```

---

## Risk Snapshot

```http
GET /api/v1/risk/snapshot
```

---

## Kill Switch

```http
POST /api/v1/risk/kill-switch
```

---

Response

```json
{
  "status":"STOPPED"
}
```

---

# Edge Cases

## Gap Down Open

Position

```text
₹100,000
```

opens

```text
₹80,000
```

---

Drawdown breach before first trade.

Must trigger.

---

## Multiple Strategies

Strategy A

```text
-12%
```

Strategy B

```text
+5%
```

---

Only A halted.

---

## Forced Exit During Kill Switch

Config:

```yaml
force_exit_on_breach: true
```

---

Generate liquidation orders.

---

## Simultaneous Breaches

```text
Daily Loss

+

Sector Exposure

+

Drawdown
```

Must process deterministically.

---

## Replay

Replay must recreate:

```text
same breach
same timestamp
same action
```

---

# RSpec Coverage

### Drawdown Engine

```ruby
calculates peak

calculates drawdown
```

---

### Daily Loss Engine

```ruby
tracks pnl

triggers breach
```

---

### Position Limits

```ruby
rejects oversize positions
```

---

### Exposure Engine

```ruby
symbol exposure

sector exposure
```

---

### Kill Switch

```ruby
activate

deactivate

strategy scope

portfolio scope
```

---

### Replay

```ruby
recreates breaches
```

---

# Definition Of Done

Phase 5 completes when:

```text
✓ Portfolio Risk Engine Exists

✓ Strategy Risk Exists

✓ Drawdown Engine Exists

✓ Daily Loss Engine Exists

✓ Exposure Engine Exists

✓ Position Limits Exist

✓ Sector Limits Exist

✓ Kill Switch Exists

✓ Risk Snapshots Exist

✓ Replay Recreates Risk State
```

At the end of Phase 5, the Paper Engine behaves less like a broker simulator and more like a **professional trading firm's risk platform**.

```text
Order
 ↓
Risk Engine
 ↓
Broker RMS
 ↓
Exchange Simulator
 ↓
Trade
 ↓
Ledger
```

Only after this phase should you move to:

```text
Phase 6 → Charges, Taxes, Corporate Actions & Settlement
```

because all financial accounting and portfolio lifecycle calculations depend on stable trades, positions, margin, and risk controls.

# Phase 6 — Charges, Taxes, Corporate Actions, Settlement & Portfolio Lifecycle

Phase 5 gave us:

```text
OMS
↓
Matching Engine
↓
Trades
↓
Ledger
↓
Positions
↓
Margin
↓
Risk
```

Now we must solve the next major problem:

A trade is not the final state of an investment account.

Indian markets introduce:

```text
Brokerage
STT
GST
SEBI Charges
Exchange Charges
Stamp Duty

Settlement

Corporate Actions

Dividends

Bonus

Splits

Rights

Mergers

Delisting
```

Without Phase 6:

```text
PnL Wrong

Holdings Wrong

Cash Balance Wrong

Tax Reports Wrong

Backtests Wrong
```

This phase transforms the Paper Engine from:

```text
Trading Simulator
```

into:

```text
Investment Portfolio Simulator
```

---

# Architecture

```text
Portfolio Lifecycle Engine

├── Charges Engine
├── Settlement Engine
├── Corporate Action Engine
├── Dividend Engine
├── Holdings Engine
├── Cashflow Engine
├── Tax Engine
└── Portfolio Projection Engine
```

---

# Critical Design Rule

Never hardcode charges.

Never.

Bad:

```ruby
stt = value * 0.001
```

Good:

```text
charge_profiles
```

table driven.

---

# New Models

## ChargeProfile

```ruby
class ChargeProfile < ApplicationRecord
end
```

---

Fields

```ruby
broker

segment

product_type

stt_pct

gst_pct

exchange_pct

sebi_pct

stamp_pct

brokerage_flat

brokerage_pct
```

---

Examples

```text
Dhan CNC

Dhan MIS

Kite CNC

Kite F&O

Paper Generic
```

---

# Charges Engine

Service

```ruby
Accounting::ChargesEngine
```

---

Input

```ruby
trade
```

---

Output

```ruby
charges_breakdown
```

---

Example

Trade

```text
BUY RELIANCE

100

₹2500
```

Value

```text
₹250,000
```

---

Output

```json
{
  "brokerage":20,
  "stt":250,
  "exchange":8.25,
  "sebi":2.5,
  "stamp":37.5,
  "gst":5.44
}
```

---

# Ledger Posting

Trade

```text
BUY
```

Creates

```text
Inventory
Cash
```

entries.

---

Charges create additional entries.

```text
Brokerage Expense

STT Expense

GST Expense

Exchange Expense

SEBI Expense

Stamp Expense
```

---

Every charge must hit ledger.

---

# Settlement Engine

This is where most paper systems fail.

Indian delivery trades are not instant.

---

CNC Buy

T Day

```text
Cash Debited
```

---

T+1

```text
Holdings Credited
```

---

Until settlement:

```text
Unsettled Holdings
```

must exist.

---

# New Models

## SettlementLot

```ruby
class SettlementLot < ApplicationRecord
end
```

---

Fields

```ruby
trade_id

symbol

quantity

settlement_date

status
```

---

States

```text
PENDING

SETTLED

FAILED
```

---

# Example

BUY

```text
100 INFY
```

---

T Day

```text
Holding = 0

Pending = 100
```

---

T+1

```text
Holding = 100

Pending = 0
```

---

# Holdings Engine

Now holdings become different from positions.

---

Position

```text
Trading View
```

---

Holding

```text
Settlement View
```

---

Example

BUY

```text
100 RELIANCE
```

Today

```text
Position = 100

Holding = 0
```

Tomorrow

```text
Position = 100

Holding = 100
```

---

# Corporate Action Engine

Most important long-term investing feature.

---

New model

```ruby
CorporateAction
```

---

Types

```text
DIVIDEND

BONUS

SPLIT

RIGHTS

MERGER

DEMERGER

BUYBACK

DELISTING
```

---

Source

Core Platform.

Paper Engine consumes.

Never owns.

---

# Dividend Engine

Example

```text
TCS

Dividend ₹20/share
```

Holding

```text
100 Shares
```

---

Cash Credit

```text
₹2,000
```

---

Ledger

```text
Cash

Dividend Income
```

---

# Stock Split

Example

```text
1:5 Split
```

Before

```text
100 shares

₹1000
```

---

After

```text
500 shares

₹200
```

---

Portfolio Value

Same.

---

Projection changes.

---

# Bonus Issue

Example

```text
1:1 Bonus
```

Before

```text
100 shares
```

---

After

```text
200 shares
```

---

Cost basis adjusted.

---

# Rights Issue

Example

```text
1:4 Rights
```

---

User chooses:

```text
Accept

Ignore
```

---

Paper Engine must support both.

---

# Merger Engine

Example

```text
Company A

merged into

Company B
```

---

Automatically:

```text
Close Old Holdings

Open New Holdings
```

---

Generate ledger entries.

---

# Delisting

Example

```text
Stock Delisted
```

---

Position closed.

---

Holding removed.

---

Realized PnL generated.

---

# Tax Engine

Not CA-grade.

Simulation-grade.

---

New service

```ruby
Accounting::TaxEngine
```

---

Tracks

```text
STCG

LTCG

Dividend Income
```

---

Example

Bought

```text
1 Jan
```

Sold

```text
1 Mar
```

---

Holding Period

```text
< 1 year
```

---

Classification

```text
STCG
```

---

# Portfolio Cashflows

New model

```ruby
PortfolioCashflow
```

---

Tracks

```text
Deposit

Withdrawal

Dividend

Charges

Tax

Settlement
```

---

Needed for:

```text
IRR

XIRR

Performance Attribution
```

---

# New Events

## Trade Settled

```json
{
  "event":"trade.settled"
}
```

---

## Dividend Credited

```json
{
  "event":"dividend.credited"
}
```

---

## Bonus Issued

```json
{
  "event":"bonus.issued"
}
```

---

## Split Applied

```json
{
  "event":"split.applied"
}
```

---

## Rights Offered

```json
{
  "event":"rights.offered"
}
```

---

# Replay Requirements

Replay must reproduce:

```text
Charges

Taxes

Settlements

Dividends

Bonus

Splits

Rights

Cashflows
```

exactly.

---

Example

Replay

```text
2025-01-01

to

2025-12-31
```

must generate identical:

```text
Cash Balance

Holdings

PnL

Tax Report
```

---

# APIs

## Charges

```http
GET /api/v1/charges
```

---

## Settlements

```http
GET /api/v1/settlements
```

---

## Corporate Actions

```http
GET /api/v1/corporate-actions
```

---

## Dividends

```http
GET /api/v1/dividends
```

---

## Tax Summary

```http
GET /api/v1/tax-summary
```

---

## Cashflows

```http
GET /api/v1/cashflows
```

---

# Edge Cases

## Split After Buy

Buy

```text
100 @ ₹1000
```

---

Split

```text
1:5
```

---

Must become

```text
500 @ ₹200
```

---

## Dividend Ex-Date

Bought after ex-date.

---

No dividend.

---

Bought before ex-date.

---

Dividend eligible.

---

## Bonus Shares

Position open during record date.

---

Receive bonus.

---

Position closed before record date.

---

No bonus.

---

## Settlement Holiday

T+1 falls on holiday.

---

Move to next settlement day.

---

## Delisting During Holding

Must liquidate position.

---

## Merger

Holding transformed.

---

Cost basis preserved.

---

## Replay

Same corporate action applied twice.

Must be idempotent.

---

# RSpec Coverage

### Charges

```ruby
equity delivery

intraday

futures

options
```

---

### Settlement

```ruby
pending

settled

holiday adjustment
```

---

### Dividend

```ruby
eligibility

cash credit
```

---

### Split

```ruby
quantity adjustment

cost adjustment
```

---

### Bonus

```ruby
share issuance
```

---

### Tax Engine

```ruby
stcg

ltcg
```

---

### Replay

```ruby
corporate action rebuild
```

---

# Definition Of Done

Phase 6 completes when:

```text
✓ Charges Engine Exists

✓ Settlement Engine Exists

✓ Holdings Engine Exists

✓ Dividend Engine Exists

✓ Split Engine Exists

✓ Bonus Engine Exists

✓ Rights Engine Exists

✓ Merger Engine Exists

✓ Tax Engine Exists

✓ Portfolio Cashflow Engine Exists

✓ Replay Reconstructs Portfolio Lifecycle
```

At the end of Phase 6, the Paper Engine becomes capable of simulating **long-term investing, swing trading, portfolio management, and tax-aware investing**, not just order execution.

```text
Order
 ↓
Exchange
 ↓
Trade
 ↓
Ledger
 ↓
Settlement
 ↓
Holdings
 ↓
Corporate Actions
 ↓
Portfolio Lifecycle
```

The next major phase should be **Phase 7 — Market Realism Layer (Depth Simulation, Slippage Models, Latency Models, Auction Sessions, Circuit Breakers, Market Sessions, and Historical Replay Engine)** because execution quality is still too idealized at this point.

# Phase 7 — Market Realism Layer, Historical Replay Engine & Exchange Session Simulator

Up to Phase 6, the Paper Engine is:

```text id="9v9q6k"
Correct
Auditable
Replayable
Risk Aware
Portfolio Aware
```

But it is still not realistic.

Example:

```text id="g3eq8k"
BUY MARKET

1000 RELIANCE

↓

Fill @ LTP
```

This is wrong.

Real markets have:

```text id="2zcnfk"
Spread

Depth

Latency

Slippage

Auction Sessions

Circuit Breakers

Freeze Limits

Liquidity Droughts

Gap Opens

Volatility
```

Phase 7 transforms the engine from:

```text id="n7u69g"
Accounting Correct
```

to

```text id="y3gmzy"
Execution Realistic
```

---

# Objective

Create a simulation environment capable of:

```text id="k77n31"
Paper Trading

Forward Testing

Strategy Validation

Execution Quality Testing

Historical Replay
```

using the same execution path.

---

# Architecture

```text id="u10b9h"
Market Realism Layer

├── Market Session Engine
├── Historical Replay Engine
├── Latency Simulator
├── Slippage Engine
├── Depth Simulator
├── Spread Simulator
├── Circuit Breaker Engine
├── Auction Engine
├── Volatility Engine
└── Market Clock
```

---

# Critical Principle

Never modify:

```text id="xfuw7r"
OMS

Trades

Ledger

Risk

Margin
```

These are already correct.

Phase 7 only affects:

```text id="1c57bh"
Execution Quality
```

---

# Market Clock

New Core Component.

---

Everything runs through:

```ruby
Paper::MarketClock
```

---

Modes

```text id="k0v4o0"
LIVE

REPLAY

BACKTEST

SIMULATION
```

---

Live

```text id="abk3d2"
Uses system clock
```

---

Replay

```text id="z9fr4l"
Uses historical timestamp
```

---

Backtest

```text id="x85v0u"
Fast forward
```

---

Without this:

```text id="4yb2d2"
Replay impossible
```

---

# Historical Replay Engine

Most important component of Phase 7.

---

Service

```ruby
Paper::Replay::HistoricalReplayEngine
```

---

Consumes:

```text id="n2g7db"
Historical Ticks

Historical Candles

Historical Depth
```

from Core Platform.

---

Does NOT own market data.

---

Core Platform owns:

```text id="nly4zv"
Instruments

Corporate Actions

Historical Data

Live Market Data
```

---

Paper Engine consumes.

---

Replay Flow

```text id="w4mzvn"
Historical Tick

↓

Market Clock

↓

Order Book

↓

Matching Engine

↓

Trades
```

---

Exactly same execution path.

---

# Replay Modes

## Tick Replay

Highest accuracy.

```text id="6cgr29"
Tick By Tick
```

---

Example

```text id="z1k2vs"
09:15:00.001

09:15:00.034

09:15:00.080
```

---

Most realistic.

---

## Candle Replay

Faster.

---

Example

```text id="x2k6h1"
1m

5m

15m
```

---

Uses synthetic ticks.

---

# Slippage Engine

Critical.

---

Without slippage:

```text id="n39sh1"
Backtests Lie
```

---

Service

```ruby
Paper::Execution::SlippageEngine
```

---

Models

```text id="n0sl9x"
NONE

FIXED_BPS

PERCENTAGE

DEPTH_BASED

VOLATILITY_BASED
```

---

# Fixed BPS

Example

```text id="3n6t3m"
5 bps
```

---

BUY

```text id="rvq5jg"
1000
```

---

Fill

```text id="5w4msn"
1000.50
```

instead of

```text id="9mdh4y"
1000
```

---

# Depth Based

Order

```text id="e8ahd4"
10000 shares
```

---

Available

```text id="r0km2s"
500 shares
```

---

Impact increases.

---

Realistic.

---

# Spread Simulator

New service.

```ruby
Paper::Market::SpreadSimulator
```

---

Uses:

```text id="b0zx8v"
Historical Spread

or

Synthetic Spread
```

---

Example

```text id="f7hy0s"
Bid

100.00
```

Ask

```text id="brw38l"
100.25
```

---

Spread

```text id="ay9k9v"
0.25
```

---

Market orders pay spread.

---

# Depth Simulator

Required when:

```text id="quktxj"
Historical Depth Missing
```

---

Service

```ruby
Paper::Market::DepthSimulator
```

---

Generates

```text id="ng63iq"
Bid Levels

Ask Levels
```

---

Example

```text id="z7a2cz"
2500

500 qty
```

```text id="85lxhc"
2499

1000 qty
```

```text id="upz6ua"
2498

2000 qty
```

---

# Latency Simulator

Professional requirement.

---

Service

```ruby
Paper::Execution::LatencySimulator
```

---

Models

```text id="g9mhx4"
NONE

FIXED

NORMAL_DISTRIBUTION

BROKER_PROFILE
```

---

Example

```text id="jlwmvd"
Dhan

50ms
```

---

```text id="p3g2ui"
Kite

35ms
```

---

Order path

```text id="h6vdrz"
Submit

↓

Wait

↓

Exchange
```

---

# Circuit Breaker Engine

Indian markets.

---

Supports

```text id="4r6cyl"
Upper Circuit

Lower Circuit

Index Circuit
```

---

Example

```text id="8zk6ux"
+20%
```

---

Result

```text id="mr0m0l"
No Buy Fill
```

---

or

```text id="skbn4e"
No Sell Fill
```

depending condition.

---

# Price Band Engine

Required.

---

Example

```text id="lbh8tw"
Allowed

100
```

---

Order

```text id="bdwq6j"
150
```

---

Reject.

---

# Freeze Quantity Engine

NSE specific.

---

Example

```text id="lgh0yi"
Order Size

500000
```

---

Exchange Freeze

```text id="34x7rt"
100000
```

---

Split order automatically.

---

Future Broker Profile may enable this.

---

# Auction Session Engine

Very important.

---

Supports

```text id="k1n5tp"
Pre Open

Regular

Post Close

Special Auction
```

---

Pre Open

```text id="k3z06v"
Orders Collected
```

---

No execution.

---

Open

```text id="1u4tjb"
Matching Begins
```

---

# Session Engine

Market timings.

---

Supports

```text id="y6z3gn"
NSE

BSE
```

---

Examples

```text id="bydbzm"
09:15

to

15:30
```

---

Reject orders outside session.

---

Or queue.

Configurable.

---

# Volatility Engine

Advanced.

---

Used by:

```text id="9xxcwg"
Slippage

Spread

Liquidity
```

---

High volatility:

```text id="m55u3q"
Spread Widens

Slippage Increases
```

---

# Market Event Engine

Consumes:

```text id="jjvuxl"
News

Results

Corporate Actions
```

from Core.

---

Can increase:

```text id="by58ka"
Volatility
```

temporarily.

---

# Runtime Config Additions

```json
{
  "slippage_model":"depth_based",
  "latency_model":"broker_profile",
  "spread_model":"historical",
  "replay_mode":"tick"
}
```

---

# Replay Determinism

Critical.

---

Must reproduce:

```text id="o7s8g6"
Same Fill

Same Slippage

Same Delay
```

---

Use:

```text id="j8h9l7"
rng_seed
```

from Phase 0.

---

# New Events

## Market Open

```json
{
  "event":"market.open"
}
```

---

## Market Close

```json
{
  "event":"market.close"
}
```

---

## Circuit Triggered

```json
{
  "event":"circuit.triggered"
}
```

---

## Auction Started

```json
{
  "event":"auction.started"
}
```

---

## Replay Advanced

```json
{
  "event":"replay.tick"
}
```

---

# APIs

## Replay

```http
POST /api/v1/replay/start
```

---

## Pause Replay

```http
POST /api/v1/replay/pause
```

---

## Resume Replay

```http
POST /api/v1/replay/resume
```

---

## Replay Status

```http
GET /api/v1/replay/status
```

---

## Market Session

```http
GET /api/v1/market/session
```

---

## Depth

```http
GET /api/v1/market/depth/:symbol
```

---

# Edge Cases

## Gap Open

Previous

```text id="iwxv9h"
1000
```

Open

```text id="m0b7n0"
900
```

---

Stop loss triggered immediately.

---

## Circuit Hit

Open orders remain pending.

---

No fills.

---

## Auction Orders

Submitted before market open.

---

Queued.

---

## Replay Restart

Must continue from same sequence.

---

## Historical Data Gap

Configurable:

```text id="2bgd2j"
skip

pause

synthesize
```

---

## Large Market Order

Consumes multiple levels.

---

Produces:

```text id="vsm34k"
multiple fills
```

---

# RSpec Coverage

### Slippage

```ruby
fixed

depth

volatility
```

---

### Latency

```ruby
fixed

random

broker
```

---

### Replay

```ruby
tick replay

candle replay
```

---

### Circuits

```ruby
upper

lower
```

---

### Sessions

```ruby
market open

market close

auction
```

---

### Determinism

```ruby
same seed

same results
```

---

# Definition Of Done

Phase 7 completes when:

```text id="zq9s6v"
✓ Historical Replay Engine Exists

✓ Market Clock Exists

✓ Slippage Engine Exists

✓ Latency Engine Exists

✓ Spread Engine Exists

✓ Depth Engine Exists

✓ Session Engine Exists

✓ Circuit Engine Exists

✓ Auction Engine Exists

✓ Deterministic Replay Works
```

At the end of Phase 7, the Paper Engine becomes a realistic Indian market simulator.

```text id="8qjlwm"
Core Market Data
        ↓
Historical Replay
        ↓
Market Clock
        ↓
Order Book
        ↓
Matching Engine
        ↓
Risk
        ↓
Margin
        ↓
Ledger
        ↓
Portfolio
```

This is the phase where your backtests stop being optimistic and start behaving much closer to real NSE/BSE execution conditions.

The next phase should be **Phase 8 — Broker Emulation Layer (Dhan, Kite, Fyers, Upstox profiles, API compatibility, brokerage plans, RMS differences, freeze limits, product behavior, and execution routing)** so that the same strategy can be tested against different broker behaviors before going live.

# Phase 8 — Broker Emulation Layer, Multi-Broker Compatibility & Live Migration Framework

Phase 7 made execution realistic.

Phase 8 solves a different problem:

> "My strategy works in Paper Engine. Will it behave the same on Dhan, Kite, Fyers, Upstox, Angel, Groww, ICICI Direct, Zerodha?"

Answer:

**No.**

Every broker behaves differently.

Examples:

```text
Dhan      → Different margin calculation
Kite      → Different freeze quantities
Fyers     → Different order validation
Upstox    → Different RMS checks
Angel     → Different product handling
```

Most paper trading systems ignore this.

Professional systems don't.

---

# Objective

Create a Broker Emulation Framework that allows:

```text
Paper Engine

to behave as

Dhan
Kite
Fyers
Upstox
Angel
ICICI Direct
Motilal
Groww
```

without changing strategy code.

---

# Critical Principle

Strategy should never know:

```text
Paper
Live
Broker
```

---

Bad

```ruby
if broker == "dhan"
  ...
end
```

---

Good

```ruby
ExecutionGateway.place_order(...)
```

---

Gateway resolves:

```text
Paper Broker
Dhan
Kite
Fyers
```

---

# Architecture

```text
Broker Emulation Layer

├── Broker Profile Registry
├── Broker Rules Engine
├── Broker RMS Engine
├── Broker Margin Emulator
├── Brokerage Emulator
├── Freeze Quantity Emulator
├── Product Emulator
├── Order Lifecycle Emulator
├── API Compatibility Layer
└── Live Routing Layer
```

---

# Core Concept

Introduce:

```ruby
BrokerProfile
```

---

Every runtime uses:

```ruby
runtime.broker_profile
```

---

Examples

```text
paper-generic

paper-dhan

paper-kite

paper-fyers

paper-upstox
```

---

# New Model

## BrokerProfile

```ruby
class BrokerProfile < ApplicationRecord
end
```

---

Fields

```ruby
name

broker_type

version

active
```

---

Examples

```text
DHAN_V2

KITE_V3

FYERS_V3

UPSTOX_V2
```

---

# Broker Rules Config

Stored in JSON.

---

Example

```json
{
  "allow_intraday_short": true,
  "freeze_qty": 1800,
  "max_order_value": 10000000,
  "supports_gtt": true,
  "supports_amo": true
}
```

---

# Broker Rule Engine

Service

```ruby
Paper::BrokerProfiles::RuleEngine
```

---

Before order acceptance:

```text
Order
 ↓
Rule Engine
 ↓
Exchange
```

---

# Example

Kite

Freeze Quantity

```text
1800
```

---

Order

```text
5000
```

---

Auto split:

```text
1800

1800

1400
```

---

# Brokerage Emulator

Broker-specific charges.

---

Dhan

```text
₹20
```

---

Kite

```text
₹20
```

---

Others

Different.

---

Phase 6 Charges Engine becomes:

```text
Broker Profile Driven
```

---

# Margin Emulator

Most important.

---

Same trade.

```text
BUY NIFTY FUT
```

---

Dhan Margin

```text
₹145,000
```

---

Kite Margin

```text
₹147,500
```

---

Paper Engine must emulate.

---

# Product Emulator

Different brokers support:

```text
CNC

MIS

NRML

MTF

CO

BO
```

---

Example

Broker Profile:

```json
{
  "supports_bo": false
}
```

---

Order

```text
Bracket Order
```

---

Rejected.

---

# RMS Emulator

Every broker has hidden RMS.

---

Example

```text
High Volatility
```

---

Broker rejects:

```text
Market Orders
```

---

Paper Engine must replicate.

---

# Order Lifecycle Emulator

Different brokers generate:

```text
PENDING

OPEN

TRIGGER_PENDING

COMPLETE

CANCELLED

REJECTED
```

---

Different state transitions.

---

Example

Kite

```text
PUT ORDER

↓

OPEN

↓

COMPLETE
```

---

Another broker

```text
PUT ORDER

↓

VALIDATION_PENDING

↓

OPEN

↓

COMPLETE
```

---

Paper Engine must support.

---

# API Compatibility Layer

Huge feature.

---

Expose:

```text
Dhan Compatible APIs

Kite Compatible APIs

Fyers Compatible APIs
```

---

Example

Strategy built for:

```text
Dhan API
```

---

Can switch:

```text
base_url
```

to Paper Engine.

---

No code changes.

---

# Example

Instead of:

```text
api.dhan.co
```

Use:

```text
paper-engine/api/dhan
```

---

Paper Engine responds exactly like Dhan.

---

# Adapter Structure

```ruby
Paper::ApiAdapters
```

---

Contains

```ruby
DhanAdapter

KiteAdapter

FyersAdapter

UpstoxAdapter
```

---

# Live Migration Testing

Goal:

```text
Paper Dhan
```

↓

```text
Real Dhan
```

No strategy changes.

---

Strategy uses:

```ruby
ExecutionGateway
```

---

Gateway routes:

```text
Paper Mode
```

↓

Paper Broker

---

```text
Live Mode
```

↓

Real Broker Adapter

---

# Broker Capability Matrix

New projection.

```ruby
broker_capabilities
```

---

Stores

```text
GTT

AMO

BO

CO

Margin

MTF

Basket Orders
```

---

Used by UI.

---

# Multi-Broker Simulation

Advanced feature.

---

Example

Run same strategy:

```text
Paper Dhan

Paper Kite

Paper Fyers
```

simultaneously.

---

Compare:

```text
PnL

Slippage

Charges

Margin
```

---

# Broker Drift Analysis

Critical.

---

Compare:

```text
Expected Fill

Actual Fill
```

from live broker.

---

Adjust:

```text
Latency

Slippage

Spread
```

models.

---

Paper becomes more realistic over time.

---

# New Events

## Broker Rejection

```json
{
  "event":"broker.rejected"
}
```

---

## Broker RMS Breach

```json
{
  "event":"broker.rms_breach"
}
```

---

## Freeze Split

```json
{
  "event":"order.freeze_split"
}
```

---

## Broker Simulation

```json
{
  "event":"broker.simulated"
}
```

---

# APIs

## Broker Profiles

```http
GET /api/v1/broker-profiles
```

---

## Activate Profile

```http
POST /api/v1/broker-profiles/:id/activate
```

---

## Capabilities

```http
GET /api/v1/broker-profiles/:id/capabilities
```

---

## Compatibility

```http
GET /api/v1/broker-profiles/:id/compatibility
```

---

# Edge Cases

## Broker Changes Margin Mid-Day

Profile update.

---

Replay must reproduce.

---

## Broker Disables MIS

Runtime config update.

---

Orders rejected.

---

## Freeze Quantity Changes

Auto applies.

---

## New Product Introduced

Profile update only.

No code change.

---

## Different Brokerage Plans

Flat

Percentage

Premium

Zero Brokerage

Supported.

---

# RSpec Coverage

### Rule Engine

```ruby
freeze quantity

product validation

max value validation
```

---

### Margin Emulator

```ruby
dhan

kite

fyers
```

---

### Charges

```ruby
broker specific
```

---

### API Compatibility

```ruby
dhan response

kite response

fyers response
```

---

### Replay

```ruby
broker profile replay
```

---

# Definition Of Done

Phase 8 completes when:

```text
✓ Broker Profiles Exist

✓ Broker Rules Engine Exists

✓ Margin Emulator Exists

✓ Brokerage Emulator Exists

✓ RMS Emulator Exists

✓ Product Emulator Exists

✓ Order Lifecycle Emulator Exists

✓ API Compatibility Layer Exists

✓ Live Routing Layer Exists

✓ Multi-Broker Simulation Works
```

---

# Result After Phase 8

At this point the Paper Engine is no longer merely a simulator.

It becomes a **Broker Virtualization Platform**.

```text
                    Strategy
                        │
                        ▼
                Execution Gateway
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
  Paper Dhan      Paper Kite      Paper Fyers
        │               │               │
        └────── Broker Emulation ───────┘
                        │
                 Exchange Simulator
                        │
                    Ledger
```

This is the phase where your larger architecture starts paying off:

```text
Autonomous Investment Engine
        ↓
Execution Gateway
        ↓
Paper Dhan
Paper Kite
Paper Fyers
Real Dhan
Real Kite
Real Fyers
```

The investment engine, swing engine, portfolio engine, and AI agents never need to know which broker is underneath.

The next logical phase is:

```text
Phase 9 — Strategy Runtime & Autonomous Trading Engine
```

where we introduce:

- Strategy lifecycle management
- Multi-strategy orchestration
- Signal bus
- Portfolio construction
- Rebalancing
- AI research agents
- Autonomous investment plans
- Swing trading workflows
- Long-term investing workflows
- Walk-forward validation
- Paper-to-live promotion pipelines

This is where the Paper Engine becomes the execution substrate for the autonomous stock investing platform.

# Phase 9 — Strategy Runtime, Autonomous Investment Engine & Portfolio Orchestration

Phase 8 completed the execution substrate:

```text id="o6q3jk"
Execution Gateway
↓
Paper Dhan / Paper Kite / Paper Fyers
↓
Exchange Simulator
↓
Ledger
↓
Portfolio Lifecycle
```

That means the platform can now **execute** correctly.

Phase 9 introduces what actually makes it **autonomous**:

```text id="m3z8fk"
Strategy Runtime
Mandate Engine
Signal Bus
Portfolio Orchestrator
Research Agent Runtime
Rebalancer
Promotion Pipeline
```

The TDD already establishes the split: the Paper Engine owns simulation/execution state, while Core Platform owns instruments, market data, and decision/research logic. The Paper Engine is the execution backend for paper and backtest modes, not the strategy brain.

---

# Objective

At the end of Phase 9, the platform should support:

```text id="e4xv0z"
Long-Term Investment Automation
Swing Trading Automation
Portfolio Rebalancing
Signal Generation
AI-Assisted Research
Paper-to-Live Promotion
Strategy Lifecycle Management
Walk-Forward Validation
```

This is the layer that turns the system from:

```text id="p1z8bh"
execution simulator
```

into:

```text id="k4d1rm"
autonomous investment platform
```

---

# Core Design Principle

Do **not** let strategies talk directly to brokers, paper engine internals, or database tables.

Strategies should only interact with:

```ruby id="u8q1mt"
StrategyRuntime
```

which exposes:

```text id="b9h3kp"
market snapshot
research inputs
portfolio state
risk state
execution gateway
signal bus
```

---

# Architecture

```text id="q7m1xn"
Strategy Runtime

├── Strategy Registry
├── Mandate Engine
├── Signal Engine
├── Portfolio Allocator
├── Rebalancer
├── Research Agent Runtime
├── Validation Pipeline
├── Promotion Pipeline
└── Strategy Event Store
```

---

# 1) Strategy Registry

Every strategy is a first-class artifact.

---

## Model

```ruby id="s5k8jd"
class Strategy < ApplicationRecord
end
```

---

## Fields

```ruby id="g1n7pv"
runtime_id

name

strategy_type

status

version

code_ref

config
```

---

## Types

```text id="2xv6rr"
LONG_TERM
SWING
MOMENTUM
VALUE
ETF_ACCUMULATION
DIVIDEND
SECTOR_ROTATION
AI_ASSISTED
```

---

## Why this matters

You need to be able to:

```text id="d9r4qm"
create
pause
resume
version
compare
retire
```

strategies independently.

---

# 2) Mandate Engine

This is the real brain.

A strategy should not just say “buy.”

It should answer:

```text id="z1c4qj"
What mandate am I fulfilling?
```

---

## Model

```ruby id="n8v2ld"
class InvestmentMandate < ApplicationRecord
end
```

---

## Examples

```text id="m7j2xs"
Wealth Accumulation
Retirement
Dividend Income
Capital Growth
Swing Alpha
ETF Core
Event Driven
Sector Rotation
```

---

## Fields

```text id="r0p8vf"
name

target_return

horizon

risk_budget

capital_allocation

rebalance_frequency

max_drawdown

allowed_segments
```

---

## Why this is important

Mandates are what make the platform **investing-first** instead of **trade-first**.

Example:

```text id="l5w8pq"
Portfolio A
  → 70% Long-term
  → 20% Swing
  → 10% Cash
```

The strategy runtime should optimize actions under that mandate, not chase random entries.

---

# 3) Signal Engine

Signals are derived outputs, not the source of truth.

---

## Model

```ruby id="t3v5md"
class Signal < ApplicationRecord
end
```

---

## States

```text id="k3r9vz"
GENERATED
VALIDATED
APPROVED
REJECTED
EXECUTED
EXPIRED
```

---

## Signal Types

```text id="f4w3km"
BUY
SELL
ACCUMULATE
REDUCE
HOLD
REBALANCE
```

---

## Signal fields

```text id="p7n2qc"
strategy_id

mandate_id

symbol

action

confidence

score

entry_price

stop_loss

target_price

time_horizon

reasoning
```

---

## Scenarios

### Long-term investing

```text id="v9r3hj"
BUY RELIANCE because fundamental score, sector strength, and portfolio underweight state align with the mandate.
```

### Swing trading

```text id="j2m8xd"
BUY INFY because momentum, breakout structure, and volatility regime fit the swing mandate.
```

### Rebalancing

```text id="c8p3zl"
REDUCE oversized stock, increase ETF bucket.
```

---

# 4) Research Agent Runtime

This is where Ollama-based research and analysis belongs.

It should **not** place trades.

It should only produce structured outputs.

---

## Services

```ruby id="b6q1sm"
Research::FundamentalAgent
Research::TechnicalAgent
Research::SectorAgent
Research::PortfolioReviewAgent
Research::RiskReviewAgent
Research::MacroAgent
```

---

## Outputs

```text id="s4n8xc"
ResearchReport
ScoreCard
Ranking
WatchlistCandidate
RiskNote
PortfolioNote
```

---

## Scenarios

### Fundamental research

```text id="y7m5ha"
analyze profitability, growth, debt, valuation, quality
```

### Technical research

```text id="h4q8zr"
analyze trend, momentum, ATR, volatility, support/resistance
```

### Portfolio review

```text id="d2p8ac"
detect over-concentration, sector drift, stale positions
```

---

## Edge cases

- AI returns malformed JSON
- AI returns low confidence
- AI contradicts the mandate
- AI suggests an action outside allowed segments
- AI output conflicts with risk engine
- AI output is stale versus current market snapshot

All of those must be rejected by validation, not trusted blindly.

---

# 5) Portfolio Allocator

This is the core of autonomous investing.

The system must decide:

```text id="a2v7nn"
how much capital goes where
```

not just “buy this.”

---

## Model

```ruby id="q2k9ab"
class PortfolioAllocation < ApplicationRecord
end
```

---

## Example allocations

```text id="z5m1qs"
70% core long-term
20% swing
10% cash
```

or

```text id="g8r2pt"
40% large cap
20% ETF
20% mid cap
10% dividend
10% cash
```

---

## Responsibilities

- Compute target weights
- Compare actual vs target
- Generate rebalance actions
- Respect risk budget
- Respect account mode
- Respect broker profile constraints
- Respect segment restrictions

---

## Edge cases

- Cash too low for target allocation
- Target allocation conflicts with risk profile
- Symbol already overexposed
- Sector overweight
- Rebalance order size hits freeze limit
- Rebalance would trigger tax inefficient turnover

---

# 6) Rebalancer

This is where portfolio decisions become orders.

---

## Service

```ruby id="h1v7nc"
Portfolio::Rebalancer
```

---

## Responsibilities

```text id="m0s2je"
compare target vs actual
generate buy/sell/trim/accumulate actions
split orders by broker limits
queue orders through Execution Gateway
```

---

## Scenarios

### Rebalance up

```text id="n7v3dl"
stock under target weight → buy more
```

### Rebalance down

```text id="r8q4hz"
stock over target weight → trim position
```

### Maintain

```text id="x5m9qa"
within tolerance band → do nothing
```

---

## Edge cases

- Partial rebalance due to insufficient cash
- Rebalance during market close
- Rebalance with halted symbol
- Rebalance order rejected by broker profile
- Rebalance blocked by risk engine
- Rebalance in paper mode vs live mode

---

# 7) Strategy Validation Pipeline

No strategy should trade immediately after creation.

---

## Pipeline

```text id="j8q5wh"
backtest
→ walk-forward validation
→ paper simulation
→ approval
→ live promotion
```

---

## Validation checks

```text id="m4x2qv"
PnL consistency
max drawdown
win rate
expectancy
risk usage
turnover
broker sensitivity
slippage sensitivity
```

---

## Scenarios

- Strategy passes backtest but fails paper due to slippage
- Strategy passes paper but fails live because freeze quantities differ
- Strategy is profitable but violates drawdown constraints
- Strategy is only good in one volatility regime
- Strategy is too sensitive to latency

---

# 8) Promotion Pipeline

This is the bridge from paper to live.

---

## States

```text id="f3p9tv"
DRAFT
BACKTESTED
PAPER_TESTED
APPROVED
LIVE_ENABLED
PAUSED
RETIRED
```

---

## Rules

A strategy can move to live only if:

```text id="k9m2xa"
paper PnL acceptable
risk metrics acceptable
portfolio behavior acceptable
manual approval granted
```

---

## Edge cases

- Live promotion blocked by open risk breach
- Promotion blocked by stale market data adapter
- Promotion blocked by missing broker compatibility
- Promotion blocked by incomplete audit trail

---

# 9) Strategy Event Store

Strategy behavior must be replayable.

---

## Events

```text id="t9v4qe"
strategy.created
strategy.updated
strategy.suspended
signal.generated
signal.validated
signal.approved
signal.executed
rebalance.created
rebalance.executed
strategy.promoted
strategy.demoted
```

---

## Why

You need to answer questions like:

```text id="v6m1rw"
Why did the system buy RELIANCE on that day?
```

or

```text id="p3m8xt"
Why did the strategy stop trading?
```

That answer should come from event history, not memory.

---

# 10) APIs

## Strategy management

```http id="c7m5pr"
POST /api/v1/strategies
PATCH /api/v1/strategies/:id
POST /api/v1/strategies/:id/pause
POST /api/v1/strategies/:id/resume
```

## Mandates

```http id="x2n7qv"
POST /api/v1/mandates
GET /api/v1/mandates
```

## Signals

```http id="m7q2hz"
GET /api/v1/signals
POST /api/v1/signals/:id/approve
POST /api/v1/signals/:id/reject
```

## Rebalancing

```http id="b8n4wd"
POST /api/v1/portfolios/:id/rebalance
GET /api/v1/portfolios/:id/allocation
```

## Validation

```http id="q5v1sm"
POST /api/v1/strategies/:id/validate
POST /api/v1/strategies/:id/promote
```

---

# 11) Scenarios to support

## Long-term investor

- monthly capital injection
- portfolio allocation by mandate
- dividend-aware holding
- quarterly rebalance
- tax-aware trim decisions

## Swing trader

- daily or hourly signal generation
- volatility-aware entries
- stop/target management
- intraday capital constraints
- paper-first validation

## Hybrid investor

- core long-term portfolio
- smaller swing allocation
- shared risk budget
- separate mandate per sleeve

---

# 12) Edge cases

These are the important ones.

## AI hallucination

If the AI suggests a symbol outside the allowed universe, reject it.

## Stale market data

If research uses stale data, mark the signal invalid.

## Conflicting mandates

If one strategy wants to buy and another wants to reduce the same symbol, apply portfolio-level arbitration.

## Overlapping positions

If multiple strategies trade the same symbol, use a position attribution model.

## Strategy drift

If live behavior diverges from paper/backtest, flag it.

## Turnover explosion

If strategy overtrades, throttle or suspend it.

## Cross-segment constraints

If mandate is equity-only, reject F&O instructions.

---

# 13) Phase 9 Done when

```text id="q4n8yw"
✓ Strategy Registry Exists
✓ Mandate Engine Exists
✓ Signal Engine Exists
✓ Research Agent Runtime Exists
✓ Portfolio Allocator Exists
✓ Rebalancer Exists
✓ Validation Pipeline Exists
✓ Promotion Pipeline Exists
✓ Event Store Exists
✓ Paper-to-Live Flow Works
```

---

# Why this phase matters

Without Phase 9, the platform is just a very good simulation engine.

With Phase 9, it becomes:

```text id="u2m7xp"
an autonomous investment operating system
```

The Paper Engine becomes the execution substrate.

The Strategy Runtime becomes the brain.

The Core Platform becomes the source of truth.

And the whole system finally behaves like a controlled investment firm rather than a trading bot.

If you want, I can turn Phase 9 into a **Rails domain structure + tables + services + RSpec backlog** next.

After Phase 9, you have essentially built:

```text
Core Platform
+
Paper Exchange
+
Broker Virtualization
+
Strategy Runtime
+
Autonomous Investment Engine
```

At that point the system can:

```text
Research
↓
Generate Signals
↓
Allocate Capital
↓
Paper Trade
↓
Validate
↓
Go Live
```

Most people would stop here.

A firm-grade platform does not.

---

# Phase 10 — Portfolio Intelligence, Optimization & Capital Management

Phase 9 decides:

```text
BUY RELIANCE
BUY INFY
BUY HDFCBANK
```

Phase 10 decides:

```text
How much?

When?

From which mandate?

With what capital?

What should be sold first?

How much cash should remain?
```

---

## New Engines

```text
Portfolio Intelligence Layer

├── Portfolio Optimizer
├── Capital Allocation Engine
├── Portfolio Construction Engine
├── Tax Aware Optimizer
├── Correlation Engine
├── Exposure Engine
├── Performance Attribution Engine
├── Cash Management Engine
└── Multi Portfolio Manager
```

---

## Example

Today:

```text
Cash
₹10,00,000
```

Candidates:

```text
RELIANCE
INFY
HDFCBANK
TCS
ITBEES
```

Phase 9 says:

```text
All are good
```

Phase 10 says:

```text
40% Large Cap

20% Banking

20% IT

10% ETF

10% Cash
```

---

## Multi Portfolio Support

One user can have:

```text
Retirement Portfolio

Swing Portfolio

Dividend Portfolio

Children Education Portfolio

Paper Portfolio

Live Portfolio
```

Each independently managed.

---

## Performance Attribution

Answer:

```text
Why portfolio made 18%?

Sector Allocation?
Stock Selection?
Timing?
```

---

## Benchmark Engine

Compare against:

NIFTY 50

NIFTY Next 50

NIFTY Midcap 150

---

# Phase 11 — AI Research Firm Layer

This is where Ollama agents become a research department.

---

## Agents

```text
Fundamental Analyst

Technical Analyst

Macro Analyst

Sector Analyst

Risk Analyst

Portfolio Analyst

Valuation Analyst

News Analyst

Corporate Action Analyst
```

---

Instead of:

```text
1 AI Agent
```

You get:

```text
Research Desk
```

---

Example

Every night:

```text
5000 NSE/BSE Stocks
        ↓
Screen
        ↓
Rank
        ↓
Score
        ↓
Research Reports
        ↓
Watchlists
        ↓
Investment Ideas
```

---

# Phase 12 — Live Trading Operations Platform

This is where the system becomes operationally safe.

---

## Components

```text
Trade Surveillance

Order Audit

Risk Monitoring

Broker Health Monitoring

Execution Quality Monitoring

PnL Monitoring

Drift Detection

Alerting
```

---

Questions answered:

```text
Why was order rejected?

Why did paper differ from live?

Which broker is failing?

Which strategy is degrading?
```

---

# Phase 13 — Multi-Asset Expansion Layer

Your current scope:

```text
NSE Equity
NSE Futures
NSE Options
BSE Equity
```

Phase 13 allows:

```text
Currency
Commodity
Mutual Funds
ETF
Bonds
SGB
REIT
INVIT
```

without changing architecture.

---

# Phase 14 — Quant Research Platform

At this point you're building something resembling a small hedge fund platform.

---

## Components

```text
Factor Engine

Alpha Engine

Walk Forward Engine

Monte Carlo Engine

Parameter Optimization

Strategy Lab

Regime Detection

Feature Store
```

---

Example

```text
Find best performing factors
for Indian Midcaps
between 2015-2026
```

---

# Phase 15 — Autonomous Investment Firm

Final evolution.

---

## Layers

```text
AI Research Desk
        ↓
Portfolio Committee
        ↓
Risk Committee
        ↓
Capital Allocation Committee
        ↓
Execution Desk
        ↓
Broker Network
```

---

The system can:

```text
Research Stocks

Create Investment Thesis

Construct Portfolio

Allocate Capital

Paper Validate

Promote To Live

Monitor Risk

Rebalance

Generate Reports

Retire Strategies
```

with minimal human intervention.

---

# My recommended build order

Do **not** jump to Phase 10 yet.

Build in this order:

```text
Phase 0-9
      ↓
Productionize Phase 0-9
      ↓
Phase 10 Portfolio Intelligence
      ↓
Phase 11 AI Research Desk
      ↓
Phase 12 Operations Platform
      ↓
Real Users
      ↓
Phase 14 Quant Research
      ↓
Phase 15 Autonomous Firm
```

For your specific goal (Indian stocks + autonomous investing + paper/live brokers), **Phase 10 Portfolio Intelligence** is the next logical phase because Phase 9 can generate signals, but it still lacks sophisticated portfolio construction and capital allocation decisions. That is the missing layer before the system starts behaving like a real investment manager.

No.

By the end of **Phase 9**, you have completed far more than just the Paper Engine.

Let's separate the architecture because we started crossing boundaries around Phase 9.

---

# What belongs to the Paper Engine?

The Paper Engine is responsible for:

```text
Order Simulation
Trade Simulation
Exchange Simulation
Broker Simulation
Accounting
Portfolio Accounting
Settlement
Corporate Actions
Margin
Risk
Market Replay
Broker Emulation
```

---

# Paper Engine Boundary

```text
Paper Engine

├── Orders
├── Order Book
├── Matching Engine
├── Execution Simulator
├── Trade Engine
├── Positions
├── Holdings
├── Margin Engine
├── Risk Engine
├── Ledger Engine
├── Settlement Engine
├── Corporate Actions
├── Tax Engine
├── Replay Engine
├── Market Realism Engine
├── Broker Emulation Engine
└── API Compatibility Layer
```

---

# Which phases belong to Paper Engine?

## Phase 0

Infrastructure

```text
Rails
Config
Tenancy
Runtime
```

---

## Phase 1

OMS

```text
Orders
Order Lifecycle
```

---

## Phase 2

Matching Engine

```text
Order Book
Execution
Trades
```

---

## Phase 3

Portfolio Accounting

```text
Positions
Holdings
Ledger
```

---

## Phase 4

Broker Layer

```text
Margin
RMS
Funds
```

---

## Phase 5

Risk

```text
Portfolio Risk
Strategy Risk
Kill Switch
Drawdown
```

---

## Phase 6

Portfolio Lifecycle

```text
Charges
Taxes
Settlement
Corporate Actions
```

---

## Phase 7

Market Realism

```text
Replay
Depth
Spread
Slippage
Latency
Sessions
```

---

## Phase 8

Broker Virtualization

```text
Dhan Profile
Kite Profile
Fyers Profile
API Compatibility
```

---

# Paper Engine COMPLETE

At the end of Phase 8:

```text
✓ Paper Exchange

✓ Paper Broker

✓ Paper Accounting

✓ Paper Risk

✓ Market Replay

✓ Broker Emulation

✓ API Compatibility

✓ Backtesting Support

✓ Paper Trading Support

✓ Forward Testing Support
```

This is effectively:

```text
Virtual NSE/BSE Broker + Exchange
```

for a retail user.

---

# What is Phase 9 then?

Phase 9 is NOT Paper Engine.

Phase 9 belongs to:

```text
Autonomous Investment Engine
```

---

# New System Boundary

```text
Autonomous Investment Engine

├── Strategy Runtime
├── Signal Engine
├── Research Agents
├── Portfolio Allocator
├── Rebalancer
├── Validation Pipeline
├── Promotion Pipeline
└── Strategy Registry
```

This system simply uses:

```text
Paper Engine
```

as one execution destination.

---

# Real Architecture

```text
                    User
                      │
                      ▼

          Autonomous Investment Engine
                      │
                      ▼

               Execution Gateway
                      │

      ┌───────────────┼───────────────┐
      ▼               ▼               ▼

 Paper Engine      DhanHQ         Kite/Fyers
      │               │               │
      ▼               ▼               ▼

 Virtual NSE     Real NSE       Real NSE
```

---

# If we stop today at Phase 8

You already have a complete standalone product:

```text
Paper Trading Platform
```

Comparable to:

- TradingView Paper Trading
- Zerodha Streak Backtesting
- AlgoTest Paper Trading
- QuantConnect Simulation Layer
- Interactive Brokers Paper Account

but specifically for:

```text
NSE Equity
BSE Equity
NSE Futures
NSE Options
```

with broker emulation.

---

# If we continue to Phase 9+

Then we are building a second product:

```text
Autonomous Investment Platform
```

which sits on top of the Paper Engine.

---

So the correct milestone is:

```text
Phase 0-8
    =
Paper Engine MVP Complete

Phase 9-15
    =
Autonomous Investment Engine
```

If I were architecting this repository structure today, I would actually split it into two deployable services:

```text
stockos-paper-engine
    (Phase 0-8)

stockos-autonomous-engine
    (Phase 9-15)
```

with the autonomous engine talking to the paper engine exactly the same way it talks to DhanHQ, Kite, or any future broker adapter. That keeps the Paper Engine reusable for other projects and makes the autonomous layer broker-agnostic from day one.

Build the **core trading system** as the **brain**, and keep **Paper Engine + DhanHQ** as **execution adapters** behind one gateway. The paper engine should stay a full simulation backend, but it must not own instruments or market data; those stay in the core platform as the source of truth.

# Correct split

```text
Core Trading System
├── Market Data Hub
├── Instrument Master
├── Research Engine
├── Strategy Runtime
├── Portfolio Engine
├── Risk Engine
├── Mandate / Allocation Engine
└── Execution Gateway
        ├── Paper Engine Adapter
        └── DhanHQ Adapter
```

## Principle

The core trading system should **never** call DhanHQ or Paper Engine directly.
It should only talk to:

```ruby
ExecutionGateway.place_order(...)
ExecutionGateway.modify_order(...)
ExecutionGateway.cancel_order(...)
ExecutionGateway.funds(...)
ExecutionGateway.positions(...)
```

The gateway decides which adapter to use.

---

# Build order after Paper Engine

## 1) Core domain first

Create the core source-of-truth tables and services:

```text
instruments
market_data_snapshots
corporate_actions
fundamentals
strategies
mandates
portfolios
allocations
risk_profiles
broker_accounts
runtime_configs
```

This is the layer that remains stable even when you add brokers later.

---

## 2) Market Data Hub with adapter interface

Do not hardcode DhanHQ inside strategy code.

Create:

```ruby
MarketData::Adapter
MarketData::DhanAdapter
MarketData::ReplayAdapter
```

Later you can add Kite/Fyers without changing strategy logic.

For now:

- DhanHQ = live market data
- ReplayAdapter = backtest/paper replay source

---

## 3) Strategy Runtime

This is the autonomous brain.

Own:

- screeners
- scoring
- signal generation
- mandate evaluation
- portfolio suggestions
- rebalance candidates

Do **not** let strategies place orders.

They should only emit:

```text
BUY
SELL
ACCUMULATE
REDUCE
REBALANCE
HOLD
```

---

## 4) Portfolio + Risk layer

This should be broker-agnostic.

Own:

- portfolio weights
- position sizing
- exposure limits
- drawdown limits
- strategy-level risk
- symbol/sector concentration

This layer decides:

- how much to buy/sell
- whether action is allowed
- whether to paper or live execute

---

## 5) Execution Gateway

This is the key abstraction for future broker support.

Interface:

```ruby
ExecutionGateway.place_order(...)
ExecutionGateway.modify_order(...)
ExecutionGateway.cancel_order(...)
ExecutionGateway.orders(...)
ExecutionGateway.trades(...)
ExecutionGateway.positions(...)
ExecutionGateway.holdings(...)
ExecutionGateway.funds(...)
```

Adapters for now:

- `PaperEngineAdapter`
- `DhanHQAdapter`

Future adapters:

- `KiteAdapter`
- `FyersAdapter`
- `UpstoxAdapter`

The core system should not care.

---

## 6) Broker capability registry

Add a broker capability matrix so the core knows what each adapter supports.

Example:

```yaml
paper:
  market_orders: true
  limit_orders: true
  sl_orders: true
  bracket_orders: false
  gtt: false

dhan:
  market_orders: true
  limit_orders: true
  sl_orders: true
  bracket_orders: true
  gtt: true
```

This prevents strategies from generating unsupported orders.

---

## 7) Runtime configuration

Keep user-selectable runtime settings in DB:

- market data source
- execution adapter
- paper/live mode
- broker profile
- risk profile
- slippage model
- latency model
- mandate profile

This is how one system can run paper today and Dhan live tomorrow with no code change.

---

# Recommended module split

```text
app/domains/core/
  instruments/
  market_data/
  research/
  strategies/
  mandates/
  portfolio/
  risk/
  execution_gateway/
  broker_profiles/
  runtime/
```

---

# Practical implementation plan

## Sprint A

Core models + runtime config + adapter contracts.

## Sprint B

Market data adapter abstraction with DhanHQ and Replay.

## Sprint C

Strategy runtime + signal objects + portfolio allocator.

## Sprint D

ExecutionGateway wiring to PaperEngine and DhanHQ.

## Sprint E

Risk checks + broker capability enforcement + UI for runtime switching.

---

# What not to do

Do not build:

- strategy code that imports DhanHQ directly
- paper engine-specific logic inside core portfolio services
- market-data code inside order execution services
- broker-specific branching inside strategy files

That becomes trash architecture fast.

---

# Final shape

```text
User / UI
   ↓
Core Trading System
   ↓
Decision + Risk + Portfolio
   ↓
Execution Gateway
   ├── Paper Engine
   └── DhanHQ
```

This gives you:

- paper trading now
- live trading on DhanHQ now
- future broker support later
- no rewrite of strategy or portfolio logic

If you want, I’ll turn this into a **phase-wise Rails implementation blueprint** with tables, models, service objects, and folder structure for the core trading system.

# Core Trading System Implementation Roadmap

At this point:

```text id="8xm0xy"
Paper Engine
=
Complete Trading Infrastructure
```

Now we build:

```text id="00h13w"
Core Trading System
=
Brain
```

The core system should never know:

```text id="d2vuvz"
Paper
Dhan
Kite
Fyers
```

It only knows:

```text id="u4ttzm"
Market Data
Strategies
Portfolios
Risk
Execution Gateway
```

---

# Final Architecture

```text id="ghgh4g"
Core Trading System

├── Instrument Master
├── Market Data Hub
├── Screening Engine
├── Research Engine
├── Strategy Runtime
├── Signal Engine
├── Portfolio Engine
├── Allocation Engine
├── Risk Engine
├── Execution Gateway
├── Analytics Engine
├── Reporting Engine
└── Automation Engine
```

---

# Phase CTS-0

# Foundation

Goal:

```text id="z1z2df"
Establish all core abstractions
```

No trading.

No AI.

No strategies.

Just domain model.

---

## Models

```ruby
Instrument
Exchange
Segment
Sector
Industry

BrokerAccount
ExecutionProfile
MarketDataSource

Portfolio
PortfolioAccount

RiskProfile

Runtime
RuntimeConfig
```

---

## Service Contracts

### Market Data

```ruby
MarketData::Adapter
```

---

### Execution

```ruby
Execution::Adapter
```

---

### Research

```ruby
Research::Provider
```

---

### Notification

```ruby
Notification::Provider
```

---

## Deliverables

```text id="hdmsrm"
Instrument Master

Execution Gateway Contracts

Market Data Contracts

Runtime Configuration
```

---

# Phase CTS-1

# Instrument Master & Security Master

Goal

Become source of truth for:

```text id="8ajqq3"
NSE
BSE
Indices
Stocks
Futures
Options
ETFs
Mutual Funds
```

---

## Models

```ruby
Instrument

InstrumentAlias

OptionContract

FutureContract

Expiry

CorporateAction

SymbolMapping
```

---

## Examples

```text id="4z2bmo"
RELIANCE

NSE_EQ

500325

2885
```

---

## Responsibilities

Symbol lookup.

Search.

Broker mapping.

Expiry tracking.

Lot size tracking.

Corporate action adjustments.

---

# Phase CTS-2

# Market Data Hub

Goal

Single source of truth.

---

## Adapters

```ruby
MarketData::DhanAdapter

MarketData::ReplayAdapter
```

Future:

```ruby
MarketData::KiteAdapter

MarketData::FyersAdapter
```

---

## Models

```ruby
Tick

Quote

OHLCV

MarketDepth

MarketSnapshot
```

---

## Services

```ruby
TickIngestion

CandleBuilder

SnapshotBuilder
```

---

## Outputs

```text id="sjgh2g"
Realtime

Historical

Replay
```

---

# Phase CTS-3

# Indicator & Analytics Engine

Goal

No strategies yet.

Only analytics.

---

## Indicators

```text id="0n1hgp"
RSI

EMA

SMA

ATR

VWAP

ADX

MACD

BB

Supertrend
```

---

## Services

```ruby
IndicatorEngine

IndicatorCache

SignalMetrics
```

---

## Projections

```ruby
IndicatorSnapshot
```

---

# Phase CTS-4

# Screening Engine

Goal

Generate candidates.

---

## Screeners

```text id="rn69bx"
Momentum

Volume

Breakout

Value

Growth

Dividend

Quality
```

---

## Services

```ruby
Screening::Momentum

Screening::Breakout

Screening::Value
```

---

## Output

```ruby
ScreeningResult
```

---

# Phase CTS-5

# Research Engine

Goal

Turn candidates into investment ideas.

---

## Components

```text id="zgh5yf"
Fundamental

Technical

Sector

Macro

Risk
```

---

## Models

```ruby
ResearchReport

ResearchScore

ResearchRanking
```

---

## Scores

```text id="s7gsc4"
Quality

Value

Growth

Momentum

Volatility
```

---

## Output

```text id="rkrv2g"
Investable Universe
```

---

# Phase CTS-6

# Strategy Runtime

Goal

Strategies become first-class citizens.

---

## Models

```ruby
Strategy

StrategyVersion

StrategyConfig

StrategySchedule
```

---

## Types

```text id="95v8tn"
Long Term

Swing

Momentum

ETF

Dividend

Custom
```

---

## Services

```ruby
StrategyRunner

StrategyRegistry

StrategyScheduler
```

---

# Phase CTS-7

# Signal Engine

Goal

Strategies emit signals.

---

## Models

```ruby
Signal

SignalValidation

SignalDecision
```

---

## Actions

```text id="b6q1ch"
BUY

SELL

ACCUMULATE

REDUCE

REBALANCE

EXIT
```

---

## Pipeline

```text id="mfjsvh"
Strategy
↓
Signal
↓
Validation
```

---

# Phase CTS-8

# Portfolio Engine

Goal

Manage portfolios.

---

## Models

```ruby
Portfolio

PortfolioPosition

PortfolioHolding

PortfolioTarget
```

---

## Capabilities

```text id="5z8m9q"
Multi Portfolio

Multi Strategy

Multi Mandate
```

---

# Phase CTS-9

# Allocation Engine

Goal

Decide capital deployment.

---

## Models

```ruby
AllocationModel

AllocationDecision

AllocationPolicy
```

---

## Policies

```text id="smzn6m"
Equal Weight

Risk Weight

Market Cap

Factor Weight

Custom
```

---

## Outputs

```text id="votvag"
Target Weights
```

---

# Phase CTS-10

# Core Risk Engine

This is NOT broker RMS.

---

## Risk Types

```text id="n6n7gb"
Portfolio

Strategy

Symbol

Sector

Allocation
```

---

## Services

```ruby
RiskEvaluator

ExposureEngine

ConcentrationEngine
```

---

# Phase CTS-11

# Rebalancer

Goal

Convert allocations into actions.

---

## Services

```ruby
PortfolioRebalancer
```

---

## Inputs

```text id="20bqqf"
Current

Target
```

---

## Outputs

```text id="8hpgdc"
Buy

Sell

Trim

Accumulate
```

---

# Phase CTS-12

# Execution Gateway

Most important phase.

---

## Adapters

```ruby
Execution::PaperAdapter

Execution::DhanAdapter
```

Future:

```ruby
Execution::KiteAdapter

Execution::FyersAdapter
```

---

## Contract

```ruby
place_order

modify_order

cancel_order

positions

holdings

funds

orders
```

---

## Routing

```text id="dbm4oa"
Paper

or

Live
```

selected dynamically.

---

# Phase CTS-13

# Automation Runtime

Goal

Autonomous behavior.

---

## Components

```text id="jlwm65"
Schedulers

Jobs

Triggers

Rules
```

---

## Examples

```text id="f1lmxk"
Daily Screening

Weekly Rebalance

Monthly SIP

Quarterly Review
```

---

# Phase CTS-14

# AI Research Agents

Uses:

- Ollama Client
- Ollama Agent

---

## Agents

```text id="fdu8y3"
Fundamental Analyst

Technical Analyst

Sector Analyst

Portfolio Analyst

Risk Analyst
```

---

## Output

```ruby
AIRecommendation
```

Never orders.

Only recommendations.

---

# Phase CTS-15

# Validation & Promotion Pipeline

Goal

Paper → Live.

---

## States

```text id="eezxg7"
Draft

Backtested

Paper Tested

Approved

Live
```

---

## Services

```ruby
StrategyValidator

PromotionEngine
```

---

# Phase CTS-16

# Reporting & Analytics

Goal

Measure everything.

---

## Reports

```text id="vpdx2u"
Portfolio

Risk

Strategy

Performance

Broker
```

---

## Metrics

```text id="hnzdc8"
Sharpe

Sortino

Drawdown

Win Rate

Expectancy
```

---

# Phase CTS-17

# Operations Center

Goal

Production readiness.

---

## Components

```text id="3f1ds0"
Health

Monitoring

Alerting

Audit

Drift Detection
```

---

# Phase CTS-18

# Multi-Account & Multi-Broker

Goal

Scale.

---

## Example

```text id="wnxrlh"
Paper Account

Dhan Account

Future Kite Account
```

All simultaneously.

---

# Phase CTS-19

# Autonomous Investment Platform

Final phase.

---

Combines:

```text id="oczmwn"
Research

Strategies

Signals

Portfolio

Risk

Allocation

Execution

AI
```

Into:

```text id="7p51x8"
Autonomous Investment Manager
```

---

# What I Would Actually Build First

Do **not** start at CTS-14 AI.

Do:

```text id="hzyjjc"
CTS-0
CTS-1
CTS-2
CTS-3
CTS-6
CTS-7
CTS-8
CTS-9
CTS-10
CTS-12
```

First.

That gives you:

```text id="aj2jdi"
Market Data
+
Strategy Runtime
+
Signals
+
Portfolio
+
Risk
+
Paper Engine
+
DhanHQ
```

Which is already a usable V1 autonomous investing platform.

Only after that add:

```text id="8olht8"
Screening
Research
AI
Promotion
Operations
```

because AI without a robust portfolio, risk, and execution foundation is just generating expensive noise.

Yes. I would strongly separate them.

If you don't separate them now, within 12-18 months you'll end up with:

```text
if paper_mode?
  ...
elsif dhan?
  ...
elsif kite?
  ...
```

spread across strategies, risk, portfolio, and execution code.

That architecture becomes extremely difficult to maintain.

---

# Final Architecture

```text
StockOS

├── Core Trading System
│
├── Paper Engine
│
├── Dhan Adapter
│
├── Future Broker Adapters
│
└── Frontend
```

Think:

```text
Core Trading System
=
Brain

Paper Engine
=
Virtual Broker + Virtual Exchange

Dhan Adapter
=
Real Broker Connector
```

---

# System 1

# Core Trading System

Repository:

```text
stockos-core
```

Purpose:

```text
Source Of Truth

Portfolio Decisions

Research

Strategies

Risk

Allocation

Execution Routing
```

Never owns:

```text
Order Book
Matching Engine
Ledger
Broker Simulation
```

---

## Core Trading System Architecture

```text
stockos-core

├── Instrument Master
├── Market Data Hub
├── Indicator Engine
├── Screening Engine
├── Research Engine
├── Strategy Runtime
├── Signal Engine
├── Portfolio Engine
├── Allocation Engine
├── Risk Engine
├── Execution Gateway
├── Reporting Engine
├── AI Agents
└── Automation Runtime
```

---

## Core Trading System Database

```text
instruments
instrument_aliases

market_snapshots

strategies
strategy_versions

signals

screening_results

research_reports

portfolios

portfolio_targets

allocation_models

risk_profiles

broker_accounts

execution_profiles

runtimes
```

---

## Core Trading System Responsibilities

### Instrument Master

```text
NSE Symbols

BSE Symbols

Futures

Options

ETFs
```

---

### Market Data Hub

```text
Realtime

Historical

Replay Sources
```

---

### Research

```text
Fundamental

Technical

Sector

Macro
```

---

### Strategies

```text
Long Term

Swing

ETF

Momentum
```

---

### Portfolio Management

```text
Capital Allocation

Rebalancing

Mandates
```

---

### Risk

```text
Portfolio Risk

Sector Risk

Strategy Risk
```

---

### Execution Gateway

Provides:

```ruby
place_order
cancel_order
modify_order

positions
holdings
funds
```

---

# System 2

# Paper Engine

Repository:

```text
stockos-paper-engine
```

Purpose:

```text
Virtual Broker

Virtual Exchange

Virtual Portfolio

Virtual Ledger
```

---

# Paper Engine Architecture

```text
stockos-paper-engine

├── OMS
├── Matching Engine
├── Order Book
├── Trade Engine
├── Position Engine
├── Holdings Engine
├── Ledger Engine
├── Settlement Engine
├── Margin Engine
├── Risk Engine
├── Corporate Actions
├── Replay Engine
├── Market Realism
├── Broker Emulation
└── Compatibility APIs
```

---

## Paper Engine Database

```text
accounts

orders

executions

trades

positions

holdings

funds

ledger_entries

settlements

margin_snapshots

risk_snapshots

corporate_actions

broker_profiles

market_sessions
```

---

## Paper Engine Responsibilities

### Broker Simulation

```text
Dhan
Kite
Fyers
```

---

### Exchange Simulation

```text
Order Book

Matching

Auction

Circuit Breakers
```

---

### Accounting

```text
Double Entry Ledger
```

---

### Settlement

```text
T+1

Corporate Actions
```

---

### Replay

```text
Historical Tick Replay

Historical Candle Replay
```

---

# System 3

# Dhan Adapter

Repository:

```text
stockos-adapter-dhan
```

Thin service.

---

Purpose:

```text
Translate Core Contracts

⇅

DhanHQ SDK
```

---

Architecture

```text
stockos-adapter-dhan

├── Orders
├── Positions
├── Holdings
├── Funds
├── Market Data
└── Websocket Sync
```

---

Uses:

```ruby
DhanHQ::Models::Order

DhanHQ::Models::Position

DhanHQ::WS
```

---

# Critical Rule

Core should NEVER know Dhan exists.

Bad:

```ruby
DhanHQ::Models::Order.create
```

inside strategy code.

---

Good:

```ruby
ExecutionGateway.place_order(...)
```

---

Gateway decides:

```text
Paper Mode
```

↓

```text
Paper Engine
```

or

```text
Live Mode
```

↓

```text
Dhan Adapter
```

---

# Communication

## Core -> Paper

```text
REST

Events

Webhooks
```

---

Example

```http
POST /api/v1/orders
```

---

Paper returns

```json
{
  "order_id":"123",
  "status":"OPEN"
}
```

---

## Core -> Dhan

Same contract.

---

```http
POST /api/v1/orders
```

---

Returns

```json
{
  "order_id":"DH123",
  "status":"OPEN"
}
```

---

Core doesn't care.

---

# Event Flow

```text
Market Data
      ↓
Core
      ↓
Strategy
      ↓
Signal
      ↓
Allocation
      ↓
Risk
      ↓
Execution Gateway
      ↓
 ┌───────────────┐
 │ Paper Engine  │
 └───────────────┘
          or
 ┌───────────────┐
 │ Dhan Adapter  │
 └───────────────┘
      ↓
Execution Result
      ↓
Core Portfolio Update
```

---

# Repositories I Would Create

```text
stockos-core

stockos-paper-engine

stockos-adapter-dhan
```

Later:

```text
stockos-adapter-kite

stockos-adapter-fyers

stockos-adapter-upstox
```

---

# Build Order

First build:

```text
stockos-paper-engine
```

(Already designed)

Then:

```text
stockos-core
```

Only up to:

```text
CTS-12
```

which gives:

```text
Instruments
Market Data
Strategies
Signals
Portfolio
Risk
Execution Gateway
```

Then integrate:

```text
Paper Engine Adapter
```

Then:

```text
Dhan Adapter
```

Only after both are working should you build:

```text
AI Research
Autonomous Investing
Promotion Pipeline
Multi-Agent Research
```

because those layers depend on a stable core and execution substrate.

The clean separation is:

```text
stockos-core          = Brain
stockos-paper-engine  = Virtual Broker + Exchange
stockos-adapter-dhan  = Real Broker Connector
```

and all future brokers become just additional adapters behind the same execution gateway contract.

If you want a **firm-grade paper trading platform**, most people massively underestimate what belongs inside the Paper Engine.

The Paper Engine is not:

```text
cash -= order_value
position += qty
```

That is a toy simulator.

The Paper Engine should emulate:

```text
Broker
+
Exchange
+
Clearing Corporation
+
Portfolio Accounting
+
Settlement System
```

for Indian markets.

---

# Level 1 — Foundation

## Configuration

```text
PaperEnvironment
PaperRun
PaperAccount
PaperProfile
BrokerProfile
ExchangeProfile
SimulationProfile
RuntimeConfig
```

---

## Multi Tenant

```text
User
Organization
Workspace
Account
Portfolio
```

---

# Level 2 — Order Management System

## Orders

```text
Order
OrderLeg
OrderAmendment
OrderCancellation
OrderTag
OrderComment
```

---

## Order Types

```text
MARKET
LIMIT
SL
SLM
IOC
DAY
GTT
AMO

CNC
MIS
NRML
```

---

## States

```text
PENDING

OPEN

PARTIAL

COMPLETE

CANCELLED

REJECTED

EXPIRED
```

---

# Level 3 — Execution Engine

## Trade Execution

```text
Execution
Trade
Fill
PartialFill
```

---

## Matching

```text
MatchingEngine

OrderBook

BidBook

AskBook
```

---

## Execution Models

```text
Instant Fill

LTP Fill

Bid Ask Fill

Order Book Fill

Replay Fill
```

---

# Level 4 — Position Engine

## Positions

```text
Position

PositionLot

PositionSnapshot

PositionAdjustment
```

---

Supports

```text
Increase Qty

Decrease Qty

Partial Exit

Reverse Position

Scale In

Scale Out
```

---

# Level 5 — Holdings Engine

For CNC.

```text
Holding

HoldingLot

HoldingAdjustment

HoldingSnapshot
```

---

Supports

```text
T1 Holdings

Settled Holdings

Corporate Action Adjustments
```

---

# Level 6 — Double Entry Ledger

This is the heart.

Never calculate portfolio state from trades.

Portfolio state should be derived from ledger.

---

## Ledger

```text
LedgerAccount

LedgerTransaction

LedgerEntry

Journal

JournalEntry
```

---

## Accounts

```text
Cash

Blocked Cash

Brokerage

STT

Exchange Charges

GST

Stamp Duty

DP Charges

Margin

Unrealized PnL

Realized PnL
```

---

## Example

BUY 100 INFY

```text
Cash             -150000

Holding Asset    +150000
```

SELL

```text
Holding Asset    -150000

Cash             +155000

Realized PnL     +5000
```

---

# Level 7 — Funds Engine

## Funds

```text
FundAccount

FundMovement

CashBalance

WithdrawRequest

DepositRequest
```

---

## Balance Types

```text
Available

Blocked

Margin

Collateral

Utilized
```

---

# Level 8 — Margin Engine

Critical for Indian trading.

## Margin Models

```text
Cash Margin

SPAN

Exposure

Option Margin

Futures Margin
```

---

## Components

```text
MarginCalculator

MarginBlocker

MarginRelease
```

---

# Level 9 — RMS

Broker risk.

## Checks

```text
Funds

Position Limits

Quantity Limits

Price Bands

Freeze Limits

Leverage Limits
```

---

## Actions

```text
Reject

Reduce

SquareOff

KillSwitch
```

---

# Level 10 — Charges Engine

Indian markets require this.

## Charges

```text
Brokerage

STT

Exchange Charges

GST

SEBI Charges

Stamp Duty

DP Charges
```

---

## Service

```text
ChargeCalculator
```

---

# Level 11 — Settlement Engine

Indian settlement.

## Components

```text
SettlementCycle

SettlementEntry

SettlementBatch
```

---

Supports

```text
T+1 Equity

Intraday Settlement

Derivative Expiry Settlement
```

---

# Level 12 — Corporate Actions

Often ignored.

---

## Actions

```text
Bonus

Split

Dividend

Rights

Merger

Demerger
```

---

## Models

```text
CorporateAction

CorporateActionImpact

Adjustment
```

---

# Level 13 — Market Replay Engine

For backtests.

## Components

```text
ReplaySession

ReplayTick

ReplayCandle

ReplayClock
```

---

Supports

```text
1x

2x

10x

100x
```

---

# Level 14 — Market Realism Engine

Most simulators fail here.

---

## Components

```text
SpreadModel

LatencyModel

SlippageModel

LiquidityModel
```

---

## Examples

```text
0 ms latency

100 ms latency

500 ms latency
```

---

## Slippage

```text
Fixed

Percentage

ATR Based

Liquidity Based
```

---

# Level 15 — Exchange Emulator

Virtual NSE/BSE.

## Components

```text
ExchangeSession

TradingCalendar

TradingHalt

AuctionSession

CircuitBreaker
```

---

Supports

```text
Pre Open

Regular

Post Close
```

---

# Level 16 — Broker Emulator

Emulates Dhan.

Later:

```text
Kite

Fyers

Upstox
```

---

## Components

```text
BrokerProfile

BrokerBehavior

BrokerCapabilities
```

---

Examples

```text
DhanProfile

PaperDhanProfile
```

---

# Level 17 — API Compatibility Layer

Most important.

Core system talks only here.

---

## Endpoints

```text
/orders

/trades

/positions

/holdings

/funds

/margins
```

---

Response format should mimic:

```text
DhanHQ
```

so adapter switching becomes trivial.

---

# Level 18 — Event Store

Everything becomes an event.

## Events

```text
OrderCreated

OrderFilled

OrderRejected

TradeExecuted

PositionChanged

MarginBlocked

SettlementCompleted
```

---

# Level 19 — Audit System

Required for debugging.

## Audit

```text
Who

When

Why

Correlation ID

Source
```

---

# Level 20 — Analytics

Useful but separate from core execution.

## Metrics

```text
Win Rate

Expectancy

Sharpe

Sortino

Drawdown

Exposure
```

---

# If I were creating repositories today

```text
stockos-paper-engine

├── paper_accounts
├── order_management
├── execution
├── matching
├── positions
├── holdings
├── ledger
├── funds
├── margin
├── risk
├── settlement
├── corporate_actions
├── replay
├── realism
├── exchange
├── broker_emulation
├── api_compatibility
├── events
├── audit
└── analytics
```

The absolutely non-negotiable modules are:

```text
OMS
Matching Engine
Positions
Holdings
Double Entry Ledger
Funds
Margin
Risk
Settlement
Replay
Broker Emulation
API Compatibility
```

Everything else can be layered on later, but without those, it is not a realistic paper broker/exchange for NSE/BSE trading.
