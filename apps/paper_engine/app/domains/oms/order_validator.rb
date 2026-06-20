module OMS
  class OrderValidator
    def self.validate(params)
      contract = Contracts::CreateOrderContract.new
      result = contract.call(params)
      
      if result.success?
        { valid: true, errors: {} }
      else
        { valid: false, errors: result.errors.to_h }
      end
    end
  end
end
