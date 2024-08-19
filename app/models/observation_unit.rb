class ObservationUnit < ApplicationRecord

  include Seek::Rdf::RdfGeneration

  acts_as_asset

  belongs_to :contributor, class_name: 'Person'
  belongs_to :study
  has_many :samples
  has_many :assays, through: :samples
  has_many :observation_unit_assets, inverse_of: :observation_unit, dependent: :delete_all, autosave: true
  has_many :data_files, through: :observation_unit_assets, source: :asset, source_type: 'DataFile', inverse_of: :observation_units

  validates :study,  presence: true

  accepts_nested_attributes_for :data_files, allow_destroy: true

  has_extended_metadata

  def studies
    [study]
  end

  def investigations
    [study.investigation]
  end

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
