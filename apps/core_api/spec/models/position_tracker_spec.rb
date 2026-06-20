require 'rails_helper'

RSpec.describe PositionTracker, type: :model do
  describe "database schema" do
    it "has required columns" do
      columns = described_class.column_names

      expect(columns).to include("order_no", "security_id", "segment", "side",
                                 "quantity", "status", "paper", "entry_price",
                                 "avg_price", "exit_price", "exited_at",
                                 "last_pnl_rupees", "high_water_mark_pnl", "meta")
    end

    it "has correct column types" do
      expect(described_class.column_for_attribute(:status).type).to eq(:integer)
      expect(described_class.column_for_attribute(:paper).type).to eq(:boolean)
      expect(described_class.column_for_attribute(:quantity).type).to eq(:integer)
    end

    it "status defaults to pending (0)" do
      expect(described_class.column_for_attribute(:status).default).to eq(0)
    end

    it "paper defaults to false" do
      expect(described_class.column_for_attribute(:paper).default).to eq(false)
    end
  end

  describe "enum" do
    it "defines status enum with correct values" do
      expect(described_class.statuses).to eq(
        "pending" => 0, "active" => 1, "exited" => 2, "cancelled" => 3
      )
    end

    it "responds to status query methods" do
      tracker = described_class.new(status: :pending)
      expect(tracker).to be_pending
      expect(tracker).not_to be_active

      tracker.status = :active
      expect(tracker).to be_active
    end
  end

  describe "scopes" do
    before do
      @live_active = described_class.create!(
        order_no: "LIVE1", security_id: "123", segment: "NSE_FNO",
        side: "buy", quantity: 10, paper: false, status: :active
      )
      @paper_active = described_class.create!(
        order_no: "PAP1", security_id: "456", segment: "NSE_EQ",
        side: "sell", quantity: 5, paper: true, status: :active
      )
      @exited = described_class.create!(
        order_no: "EXIT1", security_id: "789", segment: "NSE_FNO",
        side: "buy", quantity: 20, paper: false, status: :exited
      )
    end

    it ".live returns only non-paper positions" do
      expect(described_class.live).to include(@live_active, @exited)
      expect(described_class.live).not_to include(@paper_active)
    end

    it ".paper returns only paper positions" do
      expect(described_class.paper).to include(@paper_active)
      expect(described_class.paper).not_to include(@live_active, @exited)
    end

    it ".active_positions returns only active status" do
      expect(described_class.active_positions).to match_array([@live_active, @paper_active])
    end

    it ".open returns pending and active" do
      pending_tracker = described_class.create!(
        order_no: "PEND1", security_id: "000", segment: "NSE_FNO",
        side: "buy", quantity: 1, paper: false, status: :pending
      )
      expect(described_class.open).to match_array([@live_active, @paper_active, pending_tracker])
    end
  end

  describe "#to_domain" do
    let(:tracker) do
      described_class.create!(
        order_no: "TEST001",
        security_id: "12345",
        segment: "NSE_FNO",
        side: "buy",
        quantity: 100,
        entry_price: 150.50,
        status: :active,
        paper: false
      )
    end

    it "returns a DomainModels::PositionTracker" do
      domain = tracker.to_domain
      expect(domain).to be_a(DomainModels::PositionTracker)
      expect(domain.order_no).to eq("TEST001")
      expect(domain.security_id).to eq("12345")
      expect(domain.side).to eq("buy")
      expect(domain.quantity).to eq(100)
      expect(domain.entry_price).to eq(150.50)
      expect(domain.state_machine).to be_active
    end
  end

  describe "to_h" do
    let(:tracker) do
      described_class.create!(
        order_no: "HASH1",
        security_id: "99999",
        segment: "NSE_FNO",
        side: "sell",
        quantity: 50,
        status: :active,
        paper: true
      )
    end

    it "returns all attributes as a hash" do
      h = tracker.to_h
      expect(h[:order_no]).to eq("HASH1")
      expect(h[:security_id]).to eq("99999")
      expect(h[:side]).to eq("sell")
      expect(h[:quantity]).to eq(50)
      expect(h[:status]).to eq("active")
      expect(h[:paper]).to be true
      expect(h).to have_key(:created_at)
      expect(h).to have_key(:updated_at)
    end
  end
end
