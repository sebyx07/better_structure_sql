# frozen_string_literal: true

# == Schema Information
#
# Table name: orders
#
#  id               :bigint           not null, primary key
#  billing_address  :jsonb
#  confirmed_at     :datetime
#  delivered_at     :datetime
#  notes            :text
#  order_number     :string           not null
#  shipped_at       :datetime
#  shipping_address :jsonb
#  shipping_cost    :decimal(10, 2)   default(0.0), not null
#  status           :enum             default("draft"), not null
#  subtotal         :decimal(10, 2)   default(0.0), not null
#  tax_amount       :decimal(10, 2)   default(0.0), not null
#  total_amount     :decimal(10, 2)   default(0.0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_orders_created_at_brin        (created_at) USING brin
#  index_orders_on_confirmed_at        (confirmed_at) WHERE (confirmed_at IS NOT NULL)
#  index_orders_on_created_at          (created_at)
#  index_orders_on_order_number        (order_number) UNIQUE
#  index_orders_on_shipped_at          (shipped_at) WHERE (shipped_at IS NOT NULL)
#  index_orders_on_status              (status)
#  index_orders_on_user_id             (user_id)
#  index_orders_shipping_address_path  (shipping_address) USING gin
#
# Foreign Keys
#
#  fk_rails_f868b47f6a  (user_id => users.id) ON DELETE => restrict
#
# Check Constraints
#
#  check_order_amounts_positive  (subtotal >= 0::numeric AND tax_amount >= 0::numeric AND shipping_cost >= 0::numeric AND total_amount >= 0::numeric)
#
class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items
end
