class ProductPriceHistory < ApplicationRecord
  self.table_name = 'product_price_history'
  belongs_to :product
end
