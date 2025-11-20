# frozen_string_literal: true

# == Schema Information
#
# Table name: users(User accounts and authentication data)
#
#  id                                                            :bigint           not null, primary key
#  email(Unique email address for authentication)                :string           not null
#  encrypted_password(BCrypt hashed password for secure storage) :string
#  uuid                                                          :uuid
#  created_at                                                    :datetime         not null
#  updated_at                                                    :datetime         not null
#
# Indexes
#
#  index_users_on_email        (email) UNIQUE
#  index_users_on_lower_email  (lower((email)::text))
#  index_users_on_uuid         (uuid)
#
class User < ApplicationRecord
  has_many :posts, dependent: :destroy

  validates :email, presence: true, uniqueness: true
end
