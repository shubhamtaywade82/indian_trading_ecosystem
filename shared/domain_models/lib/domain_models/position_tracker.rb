# frozen_string_literal: true

module DomainModels
  class PositionTracker
    attr_accessor :id, :order_no, :security_id, :segment, :instrument_type,
                  :symbol, :side, :quantity, :entry_price, :avg_price,
                  :exit_price, :exited_at, :status, :paper,
                  :last_pnl_rupees, :high_water_mark_pnl, :meta,
                  :created_at, :updated_at

    def initialize(attrs = {})
      @id = attrs[:id]
      @order_no = attrs[:order_no]
      @security_id = attrs[:security_id]
      @segment = attrs[:segment]
      @instrument_type = attrs[:instrument_type]
      @symbol = attrs[:symbol]
      @side = attrs[:side]
      @quantity = attrs[:quantity]
      @entry_price = attrs[:entry_price]
      @avg_price = attrs[:avg_price]
      @exit_price = attrs[:exit_price]
      @exited_at = attrs[:exited_at]
      @status = attrs[:status] || :pending
      @paper = attrs.fetch(:paper, false)
      @last_pnl_rupees = attrs[:last_pnl_rupees]
      @high_water_mark_pnl = attrs[:high_water_mark_pnl]
      @meta = attrs[:meta] || {}
      @created_at = attrs[:created_at]
      @updated_at = attrs[:updated_at]

      @state_machine = PositionStateMachine.new(@status)
    end

    def state_machine
      @state_machine
    end

    def mark_active!
      @state_machine.transition_to(:active)
      @status = @state_machine.state
      @updated_at = Time.now.utc.iso8601
      self
    end

    def mark_exited!(exit_price: nil)
      @state_machine.transition_to(:exited)
      @status = @state_machine.state
      @exit_price = exit_price
      @exited_at = Time.now.utc.iso8601
      @updated_at = @exited_at
      self
    end

    def mark_cancelled!
      @state_machine.transition_to(:cancelled)
      @status = @state_machine.state
      @updated_at = Time.now.utc.iso8601
      self
    end

    def active?
      @state_machine.active?
    end

    def exited?
      @state_machine.exited?
    end

    def pending?
      @state_machine.pending?
    end

    def live?
      !@paper
    end

    def unrealized_pnl(current_ltp)
      return nil unless active? && entry_price && current_ltp
      (@side.to_s.downcase == 'buy' ? 1 : -1) * (current_ltp - entry_price) * quantity
    end

    def to_h
      {
        id: id, order_no: order_no, security_id: security_id, segment: segment,
        instrument_type: instrument_type, symbol: symbol, side: side,
        quantity: quantity, entry_price: entry_price, avg_price: avg_price,
        exit_price: exit_price, status: status, paper: paper,
        last_pnl_rupees: last_pnl_rupees, high_water_mark_pnl: high_water_mark_pnl,
        meta: meta, created_at: created_at, updated_at: updated_at
      }
    end
  end
end