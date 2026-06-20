# frozen_string_literal: true

require "spec_helper"

RSpec.describe DhanGateway::LiveGateway do
  let(:client) do
    DhanGateway::Client.new(client_id: "TEST001", access_token: "test_token")
  end
  let(:gateway) { described_class.new(client: client) }

  describe "#place_market" do
    before do
      stub_request(:post, "https://api.dhan.co/orders")
        .with(body: /"quantity":10/)
        .to_return(status: 200, body: { orderId: "ORDER123", orderStatus: "PENDING" }.to_json)
    end

    it "places a market order" do
      result = gateway.place_market(side: "buy", segment: "NSE_FNO", security_id: "12345", qty: 10)
      expect(result).to be_success
      expect(result.payload[:status]).to eq(:accepted)
      expect(result.payload[:paper]).to be false
    end
  end
end