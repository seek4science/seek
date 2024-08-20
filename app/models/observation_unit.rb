class ObservationUnit < ApplicationRecord

  include Seek::Rdf::RdfGeneration

  belongs_to :contributor, class_name: 'Person'
  belongs_to :study
  has_one :investigation, through: :study
  has_many :samples
  has_many :related_assays, -> { distinct }, through: :samples, source: :assays
  has_many :observation_unit_assets, inverse_of: :observation_unit, dependent: :delete_all, autosave: true
  has_many :data_files, through: :observation_unit_assets, source: :asset, source_type: 'DataFile', inverse_of: :observation_units

  acts_as_asset
  undef_method :studies, :investigations # we don't want these from acts_as_asset

  validates :study,  presence: true

  accepts_nested_attributes_for :data_files, allow_destroy: true

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
