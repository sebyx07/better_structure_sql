# frozen_string_literal: true

# == Schema Information
#
# Table name: products(Product catalog with pricing and inventory)
#
#  id                                                                     :bigint           not null, primary key
#  description                                                            :text
#  discount_percentage                                                    :decimal(5, 2)
#  is_active                                                              :boolean          default(TRUE)
#  is_featured                                                            :boolean          default(FALSE)
#  metadata                                                               :jsonb
#  name(Product name displayed to customers)                              :string           not null
#  price(Current selling price in cents (to avoid floating point errors)) :decimal(10, 2)   not null
#  sku                                                                    :string           not null
#  specifications                                                         :jsonb
#  stock_quantity                                                         :integer          default(0), not null
#  tags                                                                   :string           default([]), is an Array
#  created_at                                                             :datetime         not null
#  updated_at                                                             :datetime         not null
#  category_id                                                            :bigint           not null
#
# Indexes
#
#  index_active_products_unique_sku         (sku) UNIQUE WHERE (is_active = true)
#  index_products_fulltext_search           (to_tsvector('english'::regconfig, (((COALESCE(name, ''::character varying))::text || ' '::text) || COALESCE(description, ''::text)))) USING gin
#  index_products_metadata_path             (metadata) USING gin
#  index_products_on_available_items        (category_id,is_active,price) WHERE ((is_active = true) AND (stock_quantity > 0))
#  index_products_on_category_id            (category_id)
#  index_products_on_category_id_and_price  (category_id,price)
#  index_products_on_created_at             (created_at)
#  index_products_on_discounted_price       (((price * ((1)::numeric - (COALESCE(discount_percentage, (0)::numeric) / (100)::numeric)))))
#  index_products_on_is_active              (is_active)
#  index_products_on_is_featured            (is_featured) WHERE (is_featured = true)
#  index_products_on_metadata               (metadata) USING gin
#  index_products_on_name                   (name)
#  index_products_on_price                  (price)
#  index_products_on_sku                    (sku) UNIQUE
#  index_products_on_specifications         (specifications) USING gin
#  index_products_on_tags                   (tags) USING gin
#
# Foreign Keys
#
#  fk_rails_fb915499a4  (category_id => categories.id) ON DELETE => restrict
#
# Check Constraints
#
#  check_discount_range      (discount_percentage >= 0::numeric AND discount_percentage <= 100::numeric)
#  check_price_positive      (price > 0::numeric)
#  check_stock_non_negative  (stock_quantity >= 0)
#
class Product < ApplicationRecord
  belongs_to :category
  has_many :order_items
  has_many :price_histories, class_name: 'ProductPriceHistory'
end
