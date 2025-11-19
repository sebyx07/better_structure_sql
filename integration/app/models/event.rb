# frozen_string_literal: true

# == Schema Information
#
# Table name: events
#
#  id          :uuid             not null, primary key
#  event_data  :jsonb
#  event_name  :string           not null
#  event_type  :string           not null
#  ip_address  :inet
#  occurred_at :datetime         not null
#  user_agent  :string
#  user_id     :bigint
#
# Indexes
#
#  index_events_on_event_data               (event_data) USING gin
#  index_events_on_event_name               (event_name)
#  index_events_on_event_type               (event_type)
#  index_events_on_occurred_at              (occurred_at) USING brin
#  index_events_on_user_id                  (user_id)
#  index_events_on_user_id_and_occurred_at  (user_id,occurred_at)
#
# Foreign Keys
#
#  fk_rails_0cb5590091  (user_id => users.id)
#
# Check Constraints
#
#  check_event_type_not_empty  (length(event_type::text) > 0 AND length(event_name::text) > 0)
#
class Event < ApplicationRecord
  belongs_to :user, optional: true
end
