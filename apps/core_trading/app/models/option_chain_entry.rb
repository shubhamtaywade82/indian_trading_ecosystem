class OptionChainEntry < ApplicationRecord
  belongs_to :option_chain
  belongs_to :option_contract
end
