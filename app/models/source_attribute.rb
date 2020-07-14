class SourceAttribute < ApplicationRecord
  # has_one :source_type, :dependent => :destroy
  belongs_to :source_type
end
