# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'pgcrypto'
    enable_extension 'uuid-ossp'

    create_table :users do |t|
      t.string :email, null: false
      t.string :encrypted_password
      t.uuid :uuid, default: -> { 'uuid_generate_v4()' }

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :uuid
  end
end
