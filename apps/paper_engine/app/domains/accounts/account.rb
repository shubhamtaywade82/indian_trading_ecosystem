# frozen_string_literal: true

module Accounts
  class Account < ApplicationRecord
    self.table_name = "accounts"

    include RuntimeScoped
  end
end
