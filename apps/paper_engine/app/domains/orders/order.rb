class Order < ApplicationRecord
  include RuntimeScoped
  belongs_to :account
end
