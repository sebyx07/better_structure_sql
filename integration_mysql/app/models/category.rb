# frozen_string_literal: true

# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  position    :integer          default(0)
#  slug        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  parent_id   :integer
#
# Indexes
#
#  index_categories_on_lower_name  (lower((name)::text))
#  index_categories_on_parent_id   (parent_id)
#  index_categories_on_position    (position)
#  index_categories_on_slug        (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_82f48f7407  (parent_id => categories.id) ON DELETE => cascade
#
class Category < ApplicationRecord
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :children, class_name: 'Category', foreign_key: :parent_id
  has_many :products
end
