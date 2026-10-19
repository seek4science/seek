# frozen_string_literal: true
# EventType model
#
# Represents a category/type of events. Associates many `Event` records; when an
# EventType is removed the association on events is nullified. Validates presence
# and uniqueness of the `title` attribute.
class EventType < ApplicationRecord
  has_many :events, dependent: :nullify

  validates :title, presence: true, uniqueness: true
end
