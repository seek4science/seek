class Sample < ActiveRecord::Base
  attr_accessible :contributor_id, :contributor_type, :json_metadata, :policy_id, :sample_type_id, :title, :uuid

  acts_as_uniquely_identifiable

  #belongs_to :sample_type

  validates :title, presence: true
end
