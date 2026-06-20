# ARTHX Paper Phase 0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Repurpose `apps/paper_engine/` into the Phase 0 runtime-centric foundation supporting Runtime, RuntimeConfig, Account, Order, Trade, LedgerEntry, DomainEvent, IdempotencyKey, runtime isolation, and replay.

**Architecture:** All state is scoped to a `Runtime` via a `RuntimeScoped` concern. Models live under `app/domains/` grouped by subdomain. Services live under `app/domains/runtime/` and `app/domains/orders/`. RSpec + FactoryBot validate the definition of done.

**Tech Stack:** Rails 8.1.3 API, PostgreSQL, RSpec, FactoryBot, Faker, AASM, dry-validation, paper_trail, money-rails, oj, json_schemer, enumerize, pg.

---

## File Map

| File | Purpose |
|------|---------|
| `apps/paper_engine/Gemfile` | Add Phase 0 gems. |
| `apps/paper_engine/app/models/concerns/runtime_scoped.rb` | Enforce runtime isolation default scope. |
| `apps/paper_engine/app/models/application_record.rb` | Base record. |
| `apps/paper_engine/app/domains/runtime/runtime.rb` | Runtime model. |
| `apps/paper_engine/app/domains/runtime/runtime_config.rb` | Runtime config model. |
| `apps/paper_engine/app/domains/accounts/account.rb` | Account model. |
| `apps/paper_engine/app/domains/orders/order.rb` | Order model. |
| `apps/paper_engine/app/domains/trades/trade.rb` | Trade model. |
| `apps/paper_engine/app/domains/accounting/ledger_entry.rb` | Ledger entry model. |
| `apps/paper_engine/app/domains/events/domain_event.rb` | Domain event model. |
| `apps/paper_engine/app/domains/runtime/idempotency_key.rb` | Idempotency key model. |
| `apps/paper_engine/app/domains/runtime/create.rb` | Service to create a runtime + default config. |
| `apps/paper_engine/app/domains/runtime/load_config.rb` | Service to load runtime config. |
| `apps/paper_engine/app/domains/runtime/replay.rb` | Service to replay domain events. |
| `apps/paper_engine/app/domains/orders/create.rb` | Service to create an order with idempotency. |
| `apps/paper_engine/db/migrate/20260620060000_create_runtimes.rb` | Runtime table. |
| `apps/paper_engine/db/migrate/20260620060001_create_runtime_configs.rb` | Runtime config table. |
| `apps/paper_engine/db/migrate/20260620060002_create_accounts.rb` | Account table. |
| `apps/paper_engine/db/migrate/20260620060003_create_orders.rb` | Order table. |
| `apps/paper_engine/db/migrate/20260620060004_create_trades.rb` | Trade table. |
| `apps/paper_engine/db/migrate/20260620060005_create_ledger_entries.rb` | Ledger entry table. |
| `apps/paper_engine/db/migrate/20260620060006_create_domain_events.rb` | Domain event table. |
| `apps/paper_engine/db/migrate/20260620060007_create_idempotency_keys.rb` | Idempotency key table. |
| `apps/paper_engine/spec/rails_helper.rb` | RSpec setup. |
| `apps/paper_engine/spec/factories/` | Factories for all models. |
| `apps/paper_engine/spec/domains/runtime/` | Runtime service specs. |
| `apps/paper_engine/spec/domains/orders/` | Order service specs. |
| `apps/paper_engine/spec/models/` | Model association/validation specs. |

---

### Task 1: Add Phase 0 Gems

**Files:**
- Modify: `apps/paper_engine/Gemfile`

Add gems inside the main group and `:development, :test` group.

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
```

`pg` is already present.

- [ ] **Step 1: Edit Gemfile**

Insert the new gems after `gem "pg", "~> 1.1"`:

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
```

- [ ] **Step 2: Run bundle install**

```bash
cd apps/paper_engine
bundle install
```

Expected: all gems resolve and install.

- [ ] **Step 3: Commit**

```bash
git add apps/paper_engine/Gemfile apps/paper_engine/Gemfile.lock
git commit -m "chore(paper_engine): add Phase 0 foundation gems"
```

---

### Task 2: Remove Legacy Ledger Scaffolding

**Files:**
- Delete: `apps/paper_engine/app/controllers/api/paper/ledger_controller.rb`
- Delete: `apps/paper_engine/app/controllers/api/paper/positions_controller.rb`
- Delete: `apps/paper_engine/app/models/ledger_account.rb`
- Delete: `apps/paper_engine/app/models/ledger_balance.rb`
- Delete: `apps/paper_engine/app/models/ledger_journal.rb`
- Delete: `apps/paper_engine/app/models/ledger_posting.rb`
- Delete: `apps/paper_engine/db/migrate/20260620053658_create_ledger_accounts.rb`
- Delete: `apps/paper_engine/db/migrate/20260620053709_create_ledger_journals.rb`
- Delete: `apps/paper_engine/db/migrate/20260620053801_create_ledger_postings.rb`
- Delete: `apps/paper_engine/db/migrate/20260620053802_create_ledger_balances.rb`
- Modify: `apps/paper_engine/config/routes.rb`

- [ ] **Step 1: Delete legacy files**

```bash
cd apps/paper_engine
rm -f app/controllers/api/paper/ledger_controller.rb
rm -f app/controllers/api/paper/positions_controller.rb
rm -f app/models/ledger_account.rb
rm -f app/models/ledger_balance.rb
rm -f app/models/ledger_journal.rb
rm -f app/models/ledger_posting.rb
rm -f db/migrate/20260620053658_create_ledger_accounts.rb
rm -f db/migrate/20260620053709_create_ledger_journals.rb
rm -f db/migrate/20260620053801_create_ledger_postings.rb
rm -f db/migrate/20260620053802_create_ledger_balances.rb
```

- [ ] **Step 2: Clear routes**

Replace contents of `config/routes.rb` with:

```ruby
Rails.application.routes.draw do
  # Phase 0: no routes yet
end
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore(paper_engine): remove legacy ledger scaffolding"
```

---

### Task 3: Create Domain Directories and Runtime-Scoped Concern

**Files:**
- Create: `apps/paper_engine/app/models/concerns/runtime_scoped.rb`
- Create: `apps/paper_engine/app/domains/runtime/runtime.rb`
- Create: `apps/paper_engine/app/domains/runtime/runtime_config.rb`
- Create: `apps/paper_engine/app/domains/accounts/account.rb`
- Create: `apps/paper_engine/app/domains/orders/order.rb`
- Create: `apps/paper_engine/app/domains/trades/trade.rb`
- Create: `apps/paper_engine/app/domains/accounting/ledger_entry.rb`
- Create: `apps/paper_engine/app/domains/events/domain_event.rb`
- Create: `apps/paper_engine/app/domains/runtime/idempotency_key.rb`

- [ ] **Step 1: Create concern**

Create `app/models/concerns/runtime_scoped.rb`:

```ruby
# frozen_string_literal: true

module RuntimeScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :runtime

    def self.runtime(runtime)
      where(runtime: runtime)
    end
  end
end
```

- [ ] **Step 2: Create model stubs**

Create each model file with only the class declaration and `include RuntimeScoped` where applicable. Exact contents will be filled after migrations exist; for now create placeholder files to autoload cleanly:

`app/domains/runtime/runtime.rb`:
```ruby
# frozen_string_literal: true

module Runtime
  class Runtime < ApplicationRecord
    self.table_name = "runtimes"
  end
end
```

`app/domains/runtime/runtime_config.rb`:
```ruby
# frozen_string_literal: true

module Runtime
  class RuntimeConfig < ApplicationRecord
    self.table_name = "runtime_configs"
  end
end
```

`app/domains/accounts/account.rb`:
```ruby
# frozen_string_literal: true

module Accounts
  class Account < ApplicationRecord
    self.table_name = "accounts"
  end
end
```

`app/domains/orders/order.rb`:
```ruby
# frozen_string_literal: true

module Orders
  class Order < ApplicationRecord
    self.table_name = "orders"
  end
end
```

`app/domains/trades/trade.rb`:
```ruby
# frozen_string_literal: true

module Trades
  class Trade < ApplicationRecord
    self.table_name = "trades"
  end
end
```

`app/domains/accounting/ledger_entry.rb`:
```ruby
# frozen_string_literal: true

module Accounting
  class LedgerEntry < ApplicationRecord
    self.table_name = "ledger_entries"
  end
end
```

`app/domains/events/domain_event.rb`:
```ruby
# frozen_string_literal: true

module Events
  class DomainEvent < ApplicationRecord
    self.table_name = "domain_events"
  end
end
```

`app/domains/runtime/idempotency_key.rb`:
```ruby
# frozen_string_literal: true

module Runtime
  class IdempotencyKey < ApplicationRecord
    self.table_name = "idempotency_keys"
  end
end
```

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "chore(paper_engine): add domain directories and model stubs"
```

---

### Task 4: Create Migrations

**Files:**
- Create: `apps/paper_engine/db/migrate/20260620060000_create_runtimes.rb`
- Create: `apps/paper_engine/db/migrate/20260620060001_create_runtime_configs.rb`
- Create: `apps/paper_engine/db/migrate/20260620060002_create_accounts.rb`
- Create: `apps/paper_engine/db/migrate/20260620060003_create_orders.rb`
- Create: `apps/paper_engine/db/migrate/20260620060004_create_trades.rb`
- Create: `apps/paper_engine/db/migrate/20260620060005_create_ledger_entries.rb`
- Create: `apps/paper_engine/db/migrate/20260620060006_create_domain_events.rb`
- Create: `apps/paper_engine/db/migrate/20260620060007_create_idempotency_keys.rb`

- [ ] **Step 1: Write runtimes migration**

```ruby
# frozen_string_literal: true

class CreateRuntimes < ActiveRecord::Migration[8.1]
  def change
    create_table :runtimes do |t|
      t.string :name
      t.string :mode, null: false
      t.uuid :uuid, null: false, default: -> { "gen_random_uuid()" }
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :runtimes, :uuid, unique: true
    add_index :runtimes, :mode
  end
end
```

- [ ] **Step 2: Write runtime_configs migration**

```ruby
# frozen_string_literal: true

class CreateRuntimeConfigs < ActiveRecord::Migration[8.1]
  def change
    create_table :runtime_configs do |t|
      t.references :runtime, null: false, foreign_key: true
      t.string :slippage_model
      t.string :latency_model
      t.string :brokerage_plan
      t.integer :rng_seed
      t.jsonb :settings, null: false, default: {}

      t.timestamps
    end

    add_index :runtime_configs, :runtime_id, unique: true
  end
end
```

- [ ] **Step 3: Write accounts migration**

```ruby
# frozen_string_literal: true

class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.references :runtime, null: false, foreign_key: true
      t.string :name
      t.string :currency, null: false, default: "INR"

      t.timestamps
    end

    add_index :accounts, [:runtime_id, :name], unique: true
  end
end
```

- [ ] **Step 4: Write orders migration**

```ruby
# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :runtime, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.uuid :external_order_id, null: false
      t.string :symbol, null: false
      t.string :side, null: false
      t.string :order_type, null: false
      t.integer :quantity
      t.decimal :price, precision: 18, scale: 4
      t.string :status, null: false, default: "pending"

      t.timestamps
    end

    add_index :orders, [:runtime_id, :external_order_id], unique: true
    add_index :orders, [:runtime_id, :status]
  end
end
```

- [ ] **Step 5: Write trades migration**

```ruby
# frozen_string_literal: true

class CreateTrades < ActiveRecord::Migration[8.1]
  def change
    create_table :trades do |t|
      t.references :runtime, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.string :symbol, null: false
      t.integer :quantity, null: false
      t.decimal :price, precision: 18, scale: 4, null: false
      t.datetime :executed_at, null: false

      t.timestamps
    end

    add_index :trades, [:runtime_id, :executed_at]
  end
end
```

- [ ] **Step 6: Write ledger_entries migration**

```ruby
# frozen_string_literal: true

class CreateLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_entries do |t|
      t.references :runtime, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.string :entry_type, null: false
      t.decimal :amount, precision: 18, scale: 4, null: false
      t.string :reference_type
      t.bigint :reference_id

      t.timestamps
    end

    add_index :ledger_entries, [:runtime_id, :entry_type]
    add_index :ledger_entries, [:reference_type, :reference_id]
  end
end
```

- [ ] **Step 7: Write domain_events migration**

```ruby
# frozen_string_literal: true

class CreateDomainEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :domain_events do |t|
      t.references :runtime, null: false, foreign_key: true
      t.string :event_type, null: false
      t.jsonb :payload, null: false, default: {}
      t.datetime :occurred_at, null: false

      t.timestamps
    end

    add_index :domain_events, [:runtime_id, :occurred_at]
    add_index :domain_events, [:runtime_id, :event_type]
  end
end
```

- [ ] **Step 8: Write idempotency_keys migration**

```ruby
# frozen_string_literal: true

class CreateIdempotencyKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :idempotency_keys do |t|
      t.references :runtime, null: false, foreign_key: true
      t.string :key, null: false
      t.string :resource_type
      t.bigint :resource_id

      t.timestamps
    end

    add_index :idempotency_keys, [:runtime_id, :key], unique: true
  end
end
```

- [ ] **Step 9: Run migrations on development and test databases**

```bash
cd apps/paper_engine
bin/rails db:drop db:create db:migrate
RAILS_ENV=test bin/rails db:drop db:create db:migrate
```

Expected: both databases are created and all eight migrations run successfully.

- [ ] **Step 10: Commit**

```bash
git add -A
git commit -m "feat(paper_engine): add Phase 0 runtime migration suite"
```

---

### Task 5: Implement Models and Associations

**Files:**
- Modify: `apps/paper_engine/app/domains/runtime/runtime.rb`
- Modify: `apps/paper_engine/app/domains/runtime/runtime_config.rb`
- Modify: `apps/paper_engine/app/domains/accounts/account.rb`
- Modify: `apps/paper_engine/app/domains/orders/order.rb`
- Modify: `apps/paper_engine/app/domains/trades/trade.rb`
- Modify: `apps/paper_engine/app/domains/accounting/ledger_entry.rb`
- Modify: `apps/paper_engine/app/domains/events/domain_event.rb`
- Modify: `apps/paper_engine/app/domains/runtime/idempotency_key.rb`

- [ ] **Step 1: Implement Runtime model**

```ruby
# frozen_string_literal: true

module Runtime
  class Runtime < ApplicationRecord
    self.table_name = "runtimes"

    enum :mode, {
      paper: "paper",
      backtest: "backtest",
      replay: "replay"
    }

    has_one :runtime_config, class_name: "Runtime::RuntimeConfig", dependent: :destroy
    has_many :accounts, class_name: "Accounts::Account", dependent: :destroy
    has_many :orders, class_name: "Orders::Order", dependent: :destroy
    has_many :trades, class_name: "Trades::Trade", dependent: :destroy
    has_many :ledger_entries, class_name: "Accounting::LedgerEntry", dependent: :destroy
    has_many :domain_events, class_name: "Events::DomainEvent", dependent: :destroy
    has_many :idempotency_keys, class_name: "Runtime::IdempotencyKey", dependent: :destroy

    validates :mode, presence: true, inclusion: { in: modes.keys.map(&:to_s) }
    validates :uuid, presence: true, uniqueness: true
  end
end
```

- [ ] **Step 2: Implement RuntimeConfig model**

```ruby
# frozen_string_literal: true

module Runtime
  class RuntimeConfig < ApplicationRecord
    self.table_name = "runtime_configs"

    belongs_to :runtime, class_name: "Runtime::Runtime"

    validates :runtime_id, uniqueness: true
  end
end
```

- [ ] **Step 3: Implement Account model**

```ruby
# frozen_string_literal: true

module Accounts
  class Account < ApplicationRecord
    self.table_name = "accounts"

    include RuntimeScoped

    has_many :orders, class_name: "Orders::Order", dependent: :destroy
    has_many :ledger_entries, class_name: "Accounting::LedgerEntry", dependent: :destroy

    validates :name, presence: true
    validates :currency, presence: true
    validates :name, uniqueness: { scope: :runtime_id }
  end
end
```

- [ ] **Step 4: Implement Order model**

```ruby
# frozen_string_literal: true

module Orders
  class Order < ApplicationRecord
    self.table_name = "orders"

    include RuntimeScoped

    belongs_to :account, class_name: "Accounts::Account"
    has_many :trades, class_name: "Trades::Trade", dependent: :destroy

    validates :external_order_id, presence: true, uniqueness: { scope: :runtime_id }
    validates :symbol, presence: true
    validates :side, presence: true
    validates :order_type, presence: true
  end
end
```

- [ ] **Step 5: Implement Trade model**

```ruby
# frozen_string_literal: true

module Trades
  class Trade < ApplicationRecord
    self.table_name = "trades"

    include RuntimeScoped

    belongs_to :order, class_name: "Orders::Order"

    validates :symbol, presence: true
    validates :quantity, presence: true
    validates :price, presence: true
    validates :executed_at, presence: true
  end
end
```

- [ ] **Step 6: Implement LedgerEntry model**

```ruby
# frozen_string_literal: true

module Accounting
  class LedgerEntry < ApplicationRecord
    self.table_name = "ledger_entries"

    include RuntimeScoped

    belongs_to :account, class_name: "Accounts::Account"

    validates :entry_type, presence: true
    validates :amount, presence: true
  end
end
```

- [ ] **Step 7: Implement DomainEvent model**

```ruby
# frozen_string_literal: true

module Events
  class DomainEvent < ApplicationRecord
    self.table_name = "domain_events"

    include RuntimeScoped

    validates :event_type, presence: true
    validates :occurred_at, presence: true
  end
end
```

- [ ] **Step 8: Implement IdempotencyKey model**

```ruby
# frozen_string_literal: true

module Runtime
  class IdempotencyKey < ApplicationRecord
    self.table_name = "idempotency_keys"

    belongs_to :runtime, class_name: "Runtime::Runtime"

    validates :key, presence: true, uniqueness: { scope: :runtime_id }
  end
end
```

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat(paper_engine): implement Phase 0 domain models"
```

---

### Task 6: Configure RSpec and FactoryBot

**Files:**
- Modify: `apps/paper_engine/.rspec`
- Create/Modify: `apps/paper_engine/spec/rails_helper.rb`
- Create/Modify: `apps/paper_engine/spec/spec_helper.rb`
- Create: `apps/paper_engine/spec/factories/runtime/runtimes.rb`
- Create: `apps/paper_engine/spec/factories/runtime/runtime_configs.rb`
- Create: `apps/paper_engine/spec/factories/accounts/accounts.rb`
- Create: `apps/paper_engine/spec/factories/orders/orders.rb`
- Create: `apps/paper_engine/spec/factories/trades/trades.rb`
- Create: `apps/paper_engine/spec/factories/accounting/ledger_entries.rb`
- Create: `apps/paper_engine/spec/factories/events/domain_events.rb`

- [ ] **Step 1: Install RSpec**

```bash
cd apps/paper_engine
bin/rails generate rspec:install
```

Expected: `.rspec`, `spec/rails_helper.rb`, `spec/spec_helper.rb` created/updated.

- [ ] **Step 2: Configure FactoryBot in rails_helper.rb**

Ensure `spec/rails_helper.rb` contains:

```ruby
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
```

- [ ] **Step 3: Write factories**

`spec/factories/runtime/runtimes.rb`:
```ruby
# frozen_string_literal: true

FactoryBot.define do
  factory :runtime, class: "Runtime::Runtime" do
    sequence(:name) { |n| "Runtime #{n}" }
    mode { "paper" }

    trait :backtest do
      mode { "backtest" }
    end

    trait :replay do
      mode { "replay" }
    end
  end
end
```

`spec/factories/runtime/runtime_configs.rb`:
```ruby
# frozen_string_literal: true

FactoryBot.define do
  factory :runtime_config, class: "Runtime::RuntimeConfig" do
    runtime
    slippage_model { "fixed_bps" }
    latency_model { "constant" }
    brokerage_plan { "dhan_equity" }
    rng_seed { 42 }
    settings { { "fixed_bps" => 5 } }
  end
end
```

`spec/factories/accounts/accounts.rb`:
```ruby
# frozen_string_literal: true

FactoryBot.define do
  factory :account, class: "Accounts::Account" do
    runtime
    sequence(:name) { |n| "Account #{n}" }
    currency { "INR" }
  end
end
```

`spec/factories/orders/orders.rb`:
```ruby
# frozen_string_literal: true

FactoryBot.define do
  factory :order, class: "Orders::Order" do
    runtime
    account
    sequence(:external_order_id) { |n| "PAPER#{n.to_s.rjust(8, '0')}" }
    symbol { "RELIANCE" }
    side { "BUY" }
    order_type { "LIMIT" }
    quantity { 10 }
    price { 2500.00 }
    status { "pending" }
  end
end
```

`spec/factories/trades/trades.rb`:
```ruby
# frozen_string_literal: true

FactoryBot.define do
  factory :trade, class: "Trades::Trade" do
    runtime
    order
    symbol { "RELIANCE" }
    quantity { 10 }
    price { 2500.00 }
    executed_at { Time.current }
  end
end
```

`spec/factories/accounting/ledger_entries.rb`:
```ruby
# frozen_string_literal: true

FactoryBot.define do
  factory :ledger_entry, class: "Accounting::LedgerEntry" do
    runtime
    account
    entry_type { "credit" }
    amount { 25_000.00 }
  end
end
```

`spec/factories/events/domain_events.rb`:
```ruby
# frozen_string_literal: true

FactoryBot.define do
  factory :domain_event, class: "Events::DomainEvent" do
    runtime
    event_type { "order.created" }
    payload { { "order_id" => "PAPER00000001" } }
    occurred_at { Time.current }
  end
end
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore(paper_engine): configure RSpec and FactoryBot"
```

---

### Task 7: Implement Runtime Services

**Files:**
- Create: `apps/paper_engine/app/domains/runtime/create.rb`
- Create: `apps/paper_engine/app/domains/runtime/load_config.rb`
- Create: `apps/paper_engine/app/domains/runtime/replay.rb`
- Create: `apps/paper_engine/app/domains/orders/create.rb`

- [ ] **Step 1: Implement Runtime::Create**

```ruby
# frozen_string_literal: true

module Runtime
  class Create
    DEFAULT_CONFIG = {
      slippage_model: "fixed_bps",
      latency_model: "constant",
      brokerage_plan: "dhan_equity",
      rng_seed: 42,
      settings: {}
    }.freeze

    def self.call(attrs = {})
      new(attrs).call
    end

    def initialize(attrs = {})
      @attrs = attrs
    end

    def call
      runtime = Runtime::Runtime.create!(@attrs)
      runtime.create_runtime_config!(DEFAULT_CONFIG)
      runtime
    end
  end
end
```

- [ ] **Step 2: Implement Runtime::LoadConfig**

```ruby
# frozen_string_literal: true

module Runtime
  class LoadConfig
    def self.call(runtime)
      new(runtime).call
    end

    def initialize(runtime)
      @runtime = runtime
    end

    def call
      config = @runtime.runtime_config || @runtime.build_runtime_config
      {
        slippage_model: config.slippage_model || "fixed_bps",
        latency_model: config.latency_model || "constant",
        brokerage_plan: config.brokerage_plan || "dhan_equity",
        rng_seed: config.rng_seed || 42,
        settings: config.settings || {}
      }
    end
  end
end
```

- [ ] **Step 3: Implement Runtime::Replay**

```ruby
# frozen_string_literal: true

module Runtime
  class Replay
    def self.call(runtime)
      new(runtime).call
    end

    def initialize(runtime)
      @runtime = runtime
    end

    def call
      events = @runtime.domain_events.order(:occurred_at, :id)
      events.each do |event|
        replay_event(event)
      end
      { runtime_id: @runtime.id, events_replayed: events.count }
    end

    private

    def replay_event(event)
      case event.event_type
      when "order.created"
        payload = event.payload
        @runtime.orders.find_or_create_by!(external_order_id: payload["external_order_id"]) do |order|
          order.account = @runtime.accounts.find(payload["account_id"]) if payload["account_id"]
          order.symbol = payload["symbol"]
          order.side = payload["side"]
          order.order_type = payload["order_type"]
          order.quantity = payload["quantity"]
          order.price = payload["price"]
          order.status = payload["status"] || "pending"
        end
      when "trade.executed"
        payload = event.payload
        order = @runtime.orders.find_by!(external_order_id: payload["order_id"])
        order.trades.find_or_create_by!(executed_at: payload["executed_at"]) do |trade|
          trade.runtime = @runtime
          trade.symbol = payload["symbol"]
          trade.quantity = payload["quantity"]
          trade.price = payload["price"]
        end
      end
    end
  end
end
```

- [ ] **Step 4: Implement Orders::Create with idempotency**

```ruby
# frozen_string_literal: true

module Orders
  class Create
    def self.call(runtime:, account:, idempotency_key:, attrs:)
      new(runtime: runtime, account: account, idempotency_key: idempotency_key, attrs: attrs).call
    end

    def initialize(runtime:, account:, idempotency_key:, attrs:)
      @runtime = runtime
      @account = account
      @idempotency_key = idempotency_key
      @attrs = attrs
    end

    def call
      existing = find_existing
      return existing if existing

      order = nil
      ActiveRecord::Base.transaction do
        order = @runtime.orders.create!(@attrs.merge(account: @account))
        Runtime::IdempotencyKey.create!(
          runtime: @runtime,
          key: @idempotency_key,
          resource_type: "Orders::Order",
          resource_id: order.id
        )
      end
      order
    end

    private

    def find_existing
      key = @runtime.idempotency_keys.find_by(key: @idempotency_key)
      return nil unless key

      Orders::Order.find_by(id: key.resource_id)
    end
  end
end
```

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "feat(paper_engine): add runtime and order services"
```

---

### Task 8: Write Model and Service Specs

**Files:**
- Create: `apps/paper_engine/spec/models/runtime/runtime_spec.rb`
- Create: `apps/paper_engine/spec/models/accounts/account_spec.rb`
- Create: `apps/paper_engine/spec/models/orders/order_spec.rb`
- Create: `apps/paper_engine/spec/models/trades/trade_spec.rb`
- Create: `apps/paper_engine/spec/models/accounting/ledger_entry_spec.rb`
- Create: `apps/paper_engine/spec/models/events/domain_event_spec.rb`
- Create: `apps/paper_engine/spec/domains/runtime/create_spec.rb`
- Create: `apps/paper_engine/spec/domains/runtime/load_config_spec.rb`
- Create: `apps/paper_engine/spec/domains/runtime/replay_spec.rb`
- Create: `apps/paper_engine/spec/domains/orders/create_spec.rb`

- [ ] **Step 1: Write Runtime model spec**

`spec/models/runtime/runtime_spec.rb`:
```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runtime::Runtime, type: :model do
  it "creates a paper runtime" do
    runtime = described_class.create!(mode: :paper)
    expect(runtime).to be_paper
    expect(runtime.uuid).to be_present
  end

  it "creates a backtest runtime" do
    runtime = described_class.create!(mode: :backtest)
    expect(runtime).to be_backtest
  end

  it "requires a valid mode" do
    expect { described_class.create!(mode: "invalid") }.to raise_error(ArgumentError)
  end
end
```

- [ ] **Step 2: Write Account model spec**

`spec/models/accounts/account_spec.rb`:
```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounts::Account, type: :model do
  let(:runtime) { create(:runtime) }

  it "belongs to a runtime" do
    account = runtime.accounts.create!(name: "Primary", currency: "INR")
    expect(account.runtime).to eq(runtime)
  end

  it "allows duplicate names across runtimes" do
    runtime2 = create(:runtime)
    runtime.accounts.create!(name: "Primary", currency: "INR")
    expect { runtime2.accounts.create!(name: "Primary", currency: "INR") }.not_to raise_error
  end
end
```

- [ ] **Step 3: Write Order model spec**

`spec/models/orders/order_spec.rb`:
```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orders::Order, type: :model do
  let(:runtime) { create(:runtime) }
  let(:account) { create(:account, runtime: runtime) }

  it "stores an order" do
    order = runtime.orders.create!(
      account: account,
      external_order_id: "PAPER123",
      symbol: "RELIANCE",
      side: "BUY",
      order_type: "LIMIT",
      quantity: 10,
      price: 2500.00
    )
    expect(order.external_order_id).to eq("PAPER123")
    expect(order.status).to eq("pending")
  end
end
```

- [ ] **Step 4: Write Trade model spec**

`spec/models/trades/trade_spec.rb`:
```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Trades::Trade, type: :model do
  let(:runtime) { create(:runtime) }
  let(:account) { create(:account, runtime: runtime) }
  let(:order) { create(:order, runtime: runtime, account: account) }

  it "stores a trade" do
    trade = order.trades.create!(
      runtime: runtime,
      symbol: order.symbol,
      quantity: 10,
      price: 2500.00,
      executed_at: Time.current
    )
    expect(trade.runtime).to eq(runtime)
    expect(trade.order).to eq(order)
  end
end
```

- [ ] **Step 5: Write LedgerEntry model spec**

`spec/models/accounting/ledger_entry_spec.rb`:
```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Accounting::LedgerEntry, type: :model do
  let(:runtime) { create(:runtime) }
  let(:account) { create(:account, runtime: runtime) }

  it "stores a ledger entry" do
    entry = runtime.ledger_entries.create!(
      account: account,
      entry_type: "credit",
      amount: 25_000.00
    )
    expect(entry.runtime).to eq(runtime)
    expect(entry.amount).to eq(25_000.00)
  end
end
```

- [ ] **Step 6: Write DomainEvent model spec**

`spec/models/events/domain_event_spec.rb`:
```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Events::DomainEvent, type: :model do
  let(:runtime) { create(:runtime) }

  it "stores an event" do
    event = runtime.domain_events.create!(
      event_type: "order.created",
      payload: { "external_order_id" => "PAPER123" },
      occurred_at: Time.current
    )
    expect(event.event_type).to eq("order.created")
  end
end
```

- [ ] **Step 7: Write Runtime::Create spec**

`spec/domains/runtime/create_spec.rb`:
```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runtime::Create do
  it "creates a runtime with default config" do
    runtime = described_class.call(mode: "paper")
    expect(runtime).to be_paper
    expect(runtime.runtime_config).to be_present
    expect(runtime.runtime_config.rng_seed).to eq(42)
  end
end
```

- [ ] **Step 8: Write Runtime::LoadConfig spec**

`spec/domains/runtime/load_config_spec.rb`:
```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runtime::LoadConfig do
  let(:runtime) { create(:runtime) }

  it "loads defaults when no config exists" do
    config = described_class.call(runtime)
    expect(config[:slippage_model]).to eq("fixed_bps")
    expect(config[:rng_seed]).to eq(42)
  end

  it "loads persisted config" do
    create(:runtime_config, runtime: runtime, rng_seed: 123)
    config = described_class.call(runtime)
    expect(config[:rng_seed]).to eq(123)
  end
end
```

- [ ] **Step 9: Write Runtime::Replay spec**

`spec/domains/runtime/replay_spec.rb`:
```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Runtime::Replay do
  let(:runtime) { create(:runtime) }
  let(:account) { create(:account, runtime: runtime) }

  it "replays events without errors" do
    runtime.domain_events.create!(
      event_type: "order.created",
      payload: {
        "external_order_id" => "PAPER123",
        "account_id" => account.id,
        "symbol" => "RELIANCE",
        "side" => "BUY",
        "order_type" => "LIMIT",
        "quantity" => 10,
        "price" => 2500.00,
        "status" => "open"
      },
      occurred_at: 1.minute.ago
    )

    runtime.domain_events.create!(
      event_type: "trade.executed",
      payload: {
        "order_id" => "PAPER123",
        "symbol" => "RELIANCE",
        "quantity" => 10,
        "price" => 2500.00,
        "executed_at" => Time.current.iso8601
      },
      occurred_at: Time.current
    )

    result = described_class.call(runtime)
    expect(result[:events_replayed]).to eq(2)
    expect(runtime.orders.count).to eq(1)
    expect(runtime.trades.count).to eq(1)
  end
end
```

- [ ] **Step 10: Write Orders::Create spec**

`spec/domains/orders/create_spec.rb`:
```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orders::Create do
  let(:runtime) { create(:runtime) }
  let(:account) { create(:account, runtime: runtime) }

  it "creates an order" do
    order = described_class.call(
      runtime: runtime,
      account: account,
      idempotency_key: "key-1",
      attrs: {
        external_order_id: "PAPER123",
        symbol: "RELIANCE",
        side: "BUY",
        order_type: "LIMIT",
        quantity: 10,
        price: 2500.00
      }
    )
    expect(order).to be_persisted
    expect(order.external_order_id).to eq("PAPER123")
  end

  it "is idempotent" do
    described_class.call(
      runtime: runtime,
      account: account,
      idempotency_key: "key-1",
      attrs: { external_order_id: "PAPER123", symbol: "RELIANCE", side: "BUY", order_type: "LIMIT", quantity: 10, price: 2500.00 }
    )

    second = described_class.call(
      runtime: runtime,
      account: account,
      idempotency_key: "key-1",
      attrs: { external_order_id: "OTHER", symbol: "TCS", side: "SELL", order_type: "MARKET", quantity: 5, price: 100.00 }
    )

    expect(Orders::Order.count).to eq(1)
    expect(second.external_order_id).to eq("PAPER123")
  end
end
```

- [ ] **Step 11: Commit**

```bash
git add -A
git commit -m "test(paper_engine): add Phase 0 model and service specs"
```

---

### Task 9: Run Full Test Suite and Fix Failures

- [ ] **Step 1: Run RSpec**

```bash
cd apps/paper_engine
bundle exec rspec
```

Expected: all specs pass.

- [ ] **Step 2: Fix any failures**

If failures occur, read the output, edit the offending model/service/spec, and rerun the failing spec in isolation.

- [ ] **Step 3: Commit fixes**

```bash
git add -A
git commit -m "fix(paper_engine): resolve Phase 0 test failures"
```

---

### Task 10: Final Verification

- [ ] **Step 1: Run migrations from scratch**

```bash
cd apps/paper_engine
bin/rails db:drop db:create db:migrate
RAILS_ENV=test bin/rails db:drop db:create db:migrate
```

- [ ] **Step 2: Run full test suite again**

```bash
bundle exec rspec
```

Expected: green.

- [ ] **Step 3: Commit final state**

```bash
git add -A
git commit -m "feat(paper_engine): complete Phase 0 architectural foundation"
```

---

## Self-Review Checklist

1. **Spec coverage:** Every model/table in the design doc has a migration, model, factory, and spec. Services cover runtime creation, config loading, idempotency, and replay.
2. **Placeholder scan:** No TBD/TODO; all code blocks are complete.
3. **Type consistency:** `Runtime::Runtime`, `Runtime::RuntimeConfig`, `Runtime::IdempotencyKey` namespaces are consistent. `external_order_id` is used throughout. `rng_seed` integer type is consistent.
