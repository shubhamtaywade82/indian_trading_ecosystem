require 'rails_helper'

RSpec.describe "Phase 1 OMS", type: :request do
  let!(:runtime) { Runtime.create!(name: "Test", mode: "paper", active: true) }
  let!(:account) { Accounts::Account.create!(runtime: runtime, name: "Test Account", currency: "INR") }

  describe "POST /api/v1/orders" do
    let(:valid_params) do
      {
        order: {
          symbol: "RELIANCE",
          side: "BUY",
          order_type: "LIMIT",
          quantity: 100,
          price: 1500,
          product_type: "CNC"
        }
      }
    end

    it "creates an order, accepts it, and publishes events" do
      expect {
        post "/api/v1/orders", params: valid_params
      }.to change { Orders::Order.count }.by(1)
        .and change { Events::DomainEvent.where(event_type: 'order.created').count }.by(1)
        .and change { Events::DomainEvent.where(event_type: 'order.accepted').count }.by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("OPEN")
      expect(json["order_id"]).to be_present
    end

    it "enforces idempotency" do
      post "/api/v1/orders", params: valid_params, headers: { "Idempotency-Key" => "test-key-1" }
      expect(response).to have_http_status(:created)
      order_id = JSON.parse(response.body)["order_id"]

      expect {
        post "/api/v1/orders", params: valid_params, headers: { "Idempotency-Key" => "test-key-1" }
      }.not_to change { Orders::Order.count }
      
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["order_id"]).to eq(order_id)
    end

    it "rejects invalid quantity" do
      post "/api/v1/orders", params: { order: valid_params[:order].merge(quantity: -10) }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]["quantity"]).to be_present
    end
  end

  describe "PATCH /api/v1/orders/:id" do
    let(:order) { Orders::Order.create!(runtime: runtime, account: account, symbol: "REL", side: "BUY", order_type: "LIMIT", quantity: 100, price: 1500, status: "open", external_order_id: SecureRandom.uuid) }

    it "updates quantity and price" do
      patch "/api/v1/orders/#{order.external_order_id}", params: { order: { quantity: 80, price: 1550 } }
      expect(response).to have_http_status(:ok)
      order.reload
      expect(order.quantity).to eq(80)
      expect(order.price).to eq(1550)
      expect(Events::DomainEvent.where(event_type: 'order.modified').count).to eq(1)
    end

    it "rejects modification of filled order" do
      order.update!(status: 'filled')
      patch "/api/v1/orders/#{order.external_order_id}", params: { order: { quantity: 80 } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/orders/:id" do
    let(:order) { Orders::Order.create!(runtime: runtime, account: account, symbol: "REL", side: "BUY", order_type: "LIMIT", quantity: 100, price: 1500, status: "open", external_order_id: SecureRandom.uuid) }

    it "cancels the order" do
      delete "/api/v1/orders/#{order.external_order_id}"
      expect(response).to have_http_status(:ok)
      expect(order.reload.status).to eq("cancelled")
      expect(Events::DomainEvent.where(event_type: 'order.cancelled').count).to eq(1)
    end

    it "returns conflict when cancelling twice" do
      order.update!(status: 'cancelled')
      delete "/api/v1/orders/#{order.external_order_id}"
      expect(response).to have_http_status(:conflict)
    end
  end
end
