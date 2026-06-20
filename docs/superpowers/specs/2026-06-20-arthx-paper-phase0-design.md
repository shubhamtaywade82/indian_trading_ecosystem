# ARTHX Paper — Phase 0 Architectural Foundation

## Status
Draft — pending review.

## Context
The `indian_trading_ecosystem` repository already contains a multi-app Rails workspace under `apps/` (`core_api`, `core_trading`, `paper_engine`). Phase 0 will repurpose `apps/paper_engine/` as the runtime-centric paper/backtest/replay engine instead of creating a new top-level `arthx-paper` app.

## Goal
Establish the architectural invariants that every later phase depends on:

1. **Isolation** — every order, trade, ledger entry, and event belongs to exactly one `Runtime`.
2. **Determinism** — runtime config carries an `rng_seed` so backtests/replays reproduce identical results.
3. **Auditability** — immutable trades, append-only ledger entries, and a domain event store.
4. **Adapter Compatibility** — API contracts mirror live broker shapes (`order_id`, `status`, `symbol`, etc.).
5. **Future Replay** — all mutable state changes are captured as events; a `ReplayRuntime` service can reconstruct a run.

At the end of Phase 0 the following must work:

- Create Paper Account
- Create Paper Trading Run
- Create Backtest Run
- Load Runtime Config
- Store Orders
- Store Trades
- Store Ledger Entries
- Store Events
- Replay Entire Run

No matching engine, positions, margin, or P&L yet.

## Target Application
`apps/paper_engine/` (repurposed from the existing scaffold).

## Domain Layout

```
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
  models/
    concerns/
      runtime_scoped.rb
```

## Data Model

### Runtime
```ruby
class Runtime < ApplicationRecord
  enum :mode, { paper: "paper", backtest: "backtest", replay: "replay" }
  has_many :accounts
  has_one :runtime_config
  has_many :orders
  has_many :trades
  has_many :ledger_entries
  has_many :domain_events
  has_many :idempotency_keys
end
```

```sql
create_table :runtimes do |t|
  t.string :name
  t.string :mode, null: false
  t.uuid :uuid, null: false, default: -> { "gen_random_uuid()" }
  t.boolean :active, default: true
  t.timestamps
end
```

### RuntimeConfig
```ruby
class RuntimeConfig < ApplicationRecord
  belongs_to :runtime
end
```

```sql
create_table :runtime_configs do |t|
  t.references :runtime, null: false, foreign_key: true
  t.string :slippage_model
  t.string :latency_model
  t.string :brokerage_plan
  t.integer :rng_seed
  t.jsonb :settings, default: {}
  t.timestamps
end
```

Example config:
```json
{
  "slippage_model": "fixed_bps",
  "latency_model": "constant",
  "brokerage_plan": "dhan_equity",
  "rng_seed": 42
}
```

### Account
```ruby
class Account < ApplicationRecord
  belongs_to :runtime
end
```

```sql
create_table :accounts do |t|
  t.references :runtime, null: false, foreign_key: true
  t.string :name
  t.string :currency, default: "INR"
  t.timestamps
end
```

### Order
```ruby
class Order < ApplicationRecord
  belongs_to :runtime
  belongs_to :account
end
```

```sql
create_table :orders do |t|
  t.references :runtime, null: false, foreign_key: true
  t.references :account, null: false, foreign_key: true
  t.uuid :external_order_id, null: false
  t.string :symbol, null: false
  t.string :side, null: false
  t.string :order_type, null: false
  t.integer :quantity
  t.decimal :price, precision: 18, scale: 4
  t.string :status, default: "pending"
  t.timestamps
end
```

### Trade
```ruby
class Trade < ApplicationRecord
  belongs_to :runtime
  belongs_to :order
end
```

```sql
create_table :trades do |t|
  t.references :runtime, null: false, foreign_key: true
  t.references :order, null: false, foreign_key: true
  t.string :symbol, null: false
  t.integer :quantity, null: false
  t.decimal :price, precision: 18, scale: 4, null: false
  t.datetime :executed_at, null: false
  t.timestamps
end
```

Trades are immutable. Updates are prohibited at the application level.

### LedgerEntry
```ruby
class LedgerEntry < ApplicationRecord
  belongs_to :runtime
  belongs_to :account
end
```

```sql
create_table :ledger_entries do |t|
  t.references :runtime, null: false, foreign_key: true
  t.references :account, null: false, foreign_key: true
  t.string :entry_type, null: false
  t.decimal :amount, precision: 18, scale: 4, null: false
  t.string :reference_type
  t.bigint :reference_id
  t.timestamps
end
```

### DomainEvent
```ruby
class DomainEvent < ApplicationRecord
  belongs_to :runtime
end
```

```sql
create_table :domain_events do |t|
  t.references :runtime, null: false, foreign_key: true
  t.string :event_type, null: false
  t.jsonb :payload, default: {}, null: false
  t.datetime :occurred_at, null: false
  t.timestamps
end
```

### IdempotencyKey
```ruby
class IdempotencyKey < ApplicationRecord
  belongs_to :runtime
end
```

```sql
create_table :idempotency_keys do |t|
  t.references :runtime, null: false, foreign_key: true
  t.string :key, null: false
  t.string :resource_type
  t.bigint :resource_id
  t.timestamps
end
```

Unique index on `[:runtime_id, :key]`.

## Runtime Isolation

All domain models include a `RuntimeScoped` concern that enforces `default_scope { where(runtime_id: Current.runtime) }` when `Current.runtime` is set, or provides a `runtime` scope.

Bad:
```ruby
Order.all
```

Good:
```ruby
runtime.orders
```

## Services

### `Runtime::Create`
Creates a runtime and its default config.

### `Runtime::LoadConfig`
Returns the runtime's `RuntimeConfig` with merged defaults.

### `Runtime::Replay` (placeholder)
Boots a runtime, replays stored `DomainEvent`s in `occurred_at` order, and reconstructs orders/trades without errors. Phase 0 does not need a real state machine; it only needs to prove the event stream can be read back.

### `Idempotency::Acquire`
Attempts to create an `IdempotencyKey`. Returns existing resource if key already present.

## API Contracts

Future adapters (Dhan, Kite, Fyers) expect shapes like:

```json
{
  "order_id": "PAPER123",
  "status": "OPEN",
  "symbol": "RELIANCE",
  "side": "BUY",
  "quantity": 10,
  "price": 2500.00
}
```

Internal IDs (`Order#id`) are never exposed directly. Use `external_order_id`.

## Testing

Use RSpec + FactoryBot. Required passing scenarios:

- Create Runtime
- Create Config
- Create Account
- Create Order
- Create Trade
- Create Ledger Entry
- Create Event
- Replay Runtime

## Definition of Done

- [ ] `apps/paper_engine/` is a working Rails API app with PostgreSQL.
- [ ] All migrations create tables with correct columns, indexes, and foreign keys.
- [ ] Models exist with associations and runtime scoping.
- [ ] `RuntimeConfig` loading works with defaults.
- [ ] Idempotency keys prevent duplicate resource creation.
- [ ] Domain events can be stored and replayed.
- [ ] API contracts use broker-compatible field names.
- [ ] Full RSpec suite passes.
