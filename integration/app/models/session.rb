# == Schema Information
#
# Table name: sessions
#
#  id               :uuid             not null, primary key
#  expires_at       :datetime         not null
#  ip_address       :inet
#  last_accessed_at :datetime
#  token            :string           not null
#  user_agent       :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_sessions_on_expires_at  (expires_at)
#  index_sessions_on_token       (token) UNIQUE
#  index_sessions_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_758836b4f0  (user_id => users.id)
#
class Session < ApplicationRecord
  belongs_to :user
end
