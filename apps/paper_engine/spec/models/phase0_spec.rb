require 'rails_helper'

RSpec.describe "Phase 0 Architecture", type: :model do
  it "completes phase 0 tests" do
    # Create Runtime
    runtime = Runtime.create!(mode: :paper)
    
    # Create Config
    runtime.create_runtime_config!
    
    # Create Account
    account = runtime.accounts.create!
    
    # Create Order
    runtime.orders.create!(account: account)
    
    # Create Trade
    runtime.trades.create!(order: runtime.orders.first)
    
    # Create Ledger Entry
    LedgerEntry.create!(runtime: runtime, account: account)
    
    # Create Event
    DomainEvent.create!(runtime: runtime)

    # Replay
    expect(ReplayRuntime.call(runtime)).to be_truthy
  end
end
