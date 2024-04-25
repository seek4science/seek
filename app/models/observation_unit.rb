class ObservationUnit < ApplicationRecord

  include Seek::Creators
  include Seek::ProjectAssociation

  belongs_to :contributor, class_name: 'Person'
  belongs_to :study

  has_extended_metadata

end
