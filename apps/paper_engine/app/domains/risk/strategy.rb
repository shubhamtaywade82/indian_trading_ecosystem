module Risk
  class Strategy < ApplicationRecord
    self.table_name = "strategies"
    include RuntimeScoped
  end
end
