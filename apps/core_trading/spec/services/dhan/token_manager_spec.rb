# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dhan::TokenManager do
  before do
    described_class.clear_cache!
  end

  describe '.current_token!' do
    context 'when a valid token is cached in the DB' do
      let!(:active_token) do
        DhanAccessToken.create!(
          token: 'db-token-abc',
          expiry_time: 2.hours.from_now
        )
      end

      it 'returns the cached token directly without refreshing' do
        expect(described_class).not_to receive(:refresh!)
        expect(described_class.current_token!).to eq('db-token-abc')
      end
    end

    context 'when the cached token is expiring soon' do
      let!(:expiring_token) do
        DhanAccessToken.create!(
          token: 'expiring-token',
          expiry_time: 15.minutes.from_now # buffer is 30 mins
        )
      end

      it 'triggers a refresh' do
        expect(described_class).to receive(:refresh!).and_return('new-refreshed-token')
        expect(described_class.current_token!).to eq('new-refreshed-token')
      end
    end
  end

  describe '.refresh!' do
    it 'calls the resolved auth strategy and saves the new token' do
      # Set auth mode to manual for easy testing
      stub_const('ENV', ENV.to_h.merge('DHAN_AUTH_MODE' => 'manual', 'DHAN_ACCESS_TOKEN' => 'manual-env-token'))

      expect(DhanAccessToken.count).to eq(0)
      token = described_class.refresh!(force: true)

      expect(token).to eq('manual-env-token')
      expect(DhanAccessToken.count).to eq(1)
      expect(DhanAccessToken.first.token).to eq('manual-env-token')
      expect(DhanAccessToken.first.expiry_time).to be > Time.current + 23.hours
    end
  end
end
