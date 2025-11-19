# == Schema Information
#
# Table name: product_price_history
#
#  id         :bigint           not null, primary key
#  changed_at :datetime         not null
#  new_price  :decimal(10, 2)   not null
#  old_price  :decimal(10, 2)
#  product_id :bigint           not null
#
# Indexes
#
#  index_product_price_history_on_product_id                 (product_id)
#  index_product_price_history_on_product_id_and_changed_at  (product_id,changed_at)
#
# Foreign Keys
#
#  fk_rails_b70a9e116e  (product_id => products.id)
#
class ProductPriceHistory < ApplicationRecord
  self.table_name = 'product_price_history'
  belongs_to :product
end
