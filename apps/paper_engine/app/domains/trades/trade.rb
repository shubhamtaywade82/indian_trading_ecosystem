class Trade < ApplicationRecord
  include RuntimeScoped
  belongs_to :order
end
