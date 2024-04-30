class ObservationUnit < ApplicationRecord

  include Seek::Creators
  include Seek::ProjectAssociation
  include Seek::Stats::ActivityCounts
  include Seek::Search::CommonFields, Seek::Search::BackgroundReindexing

  belongs_to :contributor, class_name: 'Person'
  belongs_to :study
  has_many :samples

  has_extended_metadata

  def contributors
    [contributor]
  end

  def is_in_isa_publishable?
    false
  end

  def can_publish?
    false
  end

  def related_people
    (creators + contributors).compact.uniq
  end

end
