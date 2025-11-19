# == Schema Information
#
# Table name: order_items
#
#  id               :bigint           not null, primary key
#  discount_amount  :decimal(10, 2)   default(0.0)
#  product_snapshot :jsonb
#  quantity         :integer          not null
#  subtotal         :decimal(10, 2)   not null
#  unit_price       :decimal(10, 2)   not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  order_id         :bigint           not null
#  product_id       :bigint           not null
#
# Indexes
#
#  index_order_items_on_order_id                 (order_id)
#  index_order_items_on_order_id_and_product_id  (order_id,product_id) UNIQUE
#  index_order_items_on_product_id               (product_id)
#
# Foreign Keys
#
#  fk_rails_e3cb28f071  (order_id => orders.id) ON DELETE => cascade
#  fk_rails_f1a29ddd47  (product_id => products.id) ON DELETE => restrict
#
# Check Constraints
#
#  check_item_amounts_positive  (unit_price > 0::numeric AND discount_amount >= 0::numeric AND subtotal >= 0::numeric)
#
class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product
end
