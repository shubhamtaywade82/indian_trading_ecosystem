# frozen_string_literal: true

module Strategy
  module OptionsHelper
    def ema(prices, period)
      return prices.last if prices.length <= period

      k = 2.0 / (period + 1)
      ema_val = prices.first(period).sum / period.to_f

      prices[period..].each do |price|
        ema_val = price * k + ema_val * (1 - k)
      end

      ema_val.round(4)
    end

    def select_strike(contracts, underlying_price, option_type, strike_style, strike_offset)
      # Find index of the contract closest to ATM
      atm_index = contracts.each_with_index.min_by { |c, _| (c.strike_price - underlying_price).abs }[1]

      case strike_style
      when "ITM"
        target_idx = option_type == "CE" ? atm_index - strike_offset : atm_index + strike_offset
        target_idx = [[target_idx, 0].max, contracts.length - 1].min
        contracts[target_idx]
      when "OTM"
        target_idx = option_type == "CE" ? atm_index + strike_offset : atm_index - strike_offset
        target_idx = [[target_idx, 0].max, contracts.length - 1].min
        contracts[target_idx]
      else # ATM
        contracts[atm_index]
      end
    end

    def check_gamma_walls(underlying_id, expiry, underlying_price, option_type)
      underlying_inst = Instrument.find_by(symbol: underlying_id)
      return false unless underlying_inst

      underlying_record = Underlying.find_by(instrument_id: underlying_inst.id)
      return false unless underlying_record

      chain = OptionChain.where(underlying_id: underlying_record.id, expiry: expiry).order(snapshot_at: :desc).first
      return false unless chain

      max_oi_entries = OptionChainEntry.joins(:option_contract)
                                       .where(option_chain_id: chain.id)
                                       .where(option_contracts: { option_type: option_type })
                                       .order(oi: :desc)
                                       .limit(3)

      max_oi_entries.each do |entry|
        strike = entry.option_contract.strike_price.to_f
        percentage_gap = ((underlying_price - strike).abs / strike)
        
        if percentage_gap <= 0.005
          Rails.logger.warn("[OptionsHelper] Blocked: Underlying price (#{underlying_price}) is too close to major #{option_type} OI Wall at strike #{strike} (gap: #{(percentage_gap * 100).round(2)}%).")
          return true
        end
      end

      false
    end

    def find_primary_contract(core_contract)
      underlying_inst = Instrument.find_by(symbol: core_contract.underlying_symbol)
      return nil unless underlying_inst

      underlying_record = Underlying.find_by(instrument_id: underlying_inst.id)
      return nil unless underlying_record

      OptionContract.joins(derivative_contract: :underlying)
                    .where(option_type: core_contract.option_type)
                    .where(strike_price: core_contract.strike_price)
                    .where(derivative_contracts: { expiry_date: core_contract.expiry_date })
                    .where(underlying: { id: underlying_record.id })
                    .first
    end

    def resolve_option_contract(underlying_id, current_date, underlying_price, option_type, expiry_offset, strike_style, strike_offset)
      contracts = Core::OptionContract
                    .where(underlying_symbol: underlying_id)
                    .where(option_type: option_type)
                    .where("expiry_date >= ?", current_date)
                    .order(expiry_date: :asc)

      available_expiries = contracts.pluck(:expiry_date).uniq
      selected_expiry = available_expiries[expiry_offset] || available_expiries.first
      return nil unless selected_expiry

      expiry_contracts = contracts.where(expiry_date: selected_expiry).order(strike_price: :asc).to_a
      return nil if expiry_contracts.empty?

      select_strike(expiry_contracts, underlying_price, option_type, strike_style, strike_offset)
    end
  end
end
