class SampleType < ActiveRecord::Base
  attr_accessible :attr_definitions, :title, :uuid

  acts_as_uniquely_identifiable

  has_many :samples

  validates :title, presence: true

end
