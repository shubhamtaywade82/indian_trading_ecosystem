require 'rails_helper'

RSpec.describe "Paper Engine API — Orders", type: :request do
  let!(:account) do
    Account.create!(tenant_id: "t1", mode: "paper", name: "API Test Account")
  end

  before do
    ENV.delete('BROKER_PROFILE')
    MarginAccount.find_or_create_by!(account_id: account.id) do |ma|
      ma.cash_balance     = 10_000_000
      ma.blocked_margin   = 0
      ma.available_margin = 10_000_000
      ma.mtm_pnl          = 0
      ma.realized_pnl     = 0
    end
  end

  let(:headers) { { 'X-Account-Id' => account.id.to_s, 'Content-Type' => 'application/json' } }

  describe "POST /api/v1/orders" do
    let(:valid_params) do
      { order: { instrument_id: "RELIANCE", side: "buy", order_type: "LIMIT",
                 product_type: "CNC", qty: 10, price: 2500 } }
    end

    it "creates an order and returns OPEN status" do
      expect {
        post "/api/v1/orders", params: valid_params.to_json, headers: headers
      }.to change { PaperOrder.count }.by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("OPEN")
      expect(json["instrument_id"]).to eq("RELIANCE")
    end

    it "rejects orders with missing required fields" do
      post "/api/v1/orders",
           params: { order: { instrument_id: "RELIANCE", side: "buy" } }.to_json,
           headers: headers

      expect(response).to have_http_status(:bad_request).or have_http_status(:unprocessable_entity)
    end

    it "returns 401 when no account header" do
      post "/api/v1/orders", params: valid_params.to_json,
           headers: { 'Content-Type' => 'application/json' }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/orders" do
    it "returns all orders for the account" do
      PlaceOrder.call(account: account, payload: {
        instrument_id: 'RELIANCE', side: 'buy', order_type: 'LIMIT',
        product_type: 'CNC', qty: 10, price: 2500
      })

      get "/api/v1/orders", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.first["instrument_id"]).to eq("RELIANCE")
    end
  end

  describe "DELETE /api/v1/orders/:id" do
    it "cancels an open order" do
      order = PlaceOrder.call(account: account, payload: {
        instrument_id: 'INFY', side: 'buy', order_type: 'LIMIT',
        product_type: 'CNC', qty: 10, price: 1500
      })
      expect(order.status).to eq('OPEN')

      delete "/api/v1/orders/#{order.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(order.reload.status).to eq('CANCELLED')
    end

    it "returns 404 for unknown order" do
      delete "/api/v1/orders/999999", headers: headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/funds" do
    it "returns margin account data" do
      get "/api/v1/funds", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key("available")
      expect(json["available"]).to eq(10_000_000)
    end
  end
end
