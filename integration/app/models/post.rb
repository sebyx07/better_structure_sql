# frozen_string_literal: true

# == Schema Information
#
# Table name: posts
#
#  id           :bigint           not null, primary key
#  body         :text
#  published_at :datetime
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_posts_on_published_at  (published_at) WHERE (published_at IS NOT NULL)
#  index_posts_on_user_id       (user_id)
#
# Foreign Keys
#
#  fk_rails_5b5ddfd518  (user_id => users.id) ON DELETE => cascade
#
class Post < ApplicationRecord
  belongs_to :user

  validates :title, presence: true
end
