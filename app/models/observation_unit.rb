class ObservationUnit < ApplicationRecord

  include Seek::Rdf::RdfGeneration

  belongs_to :contributor, class_name: 'Person'
  belongs_to :study
  has_one :investigation, through: :study
  has_many :projects, through: :study
  has_many :samples
  has_many :related_assays, -> { distinct }, through: :samples, source: :assays
  has_many :observation_unit_assets, inverse_of: :observation_unit, dependent: :delete_all, autosave: true
  has_many :data_files, through: :observation_unit_assets, source: :asset, source_type: 'DataFile', inverse_of: :observation_units
  has_many :assay_data_files, -> { distinct }, through: :related_assays, source: :data_files
  has_many :assay_sops, -> { distinct }, through: :related_assays, source: :sops
  has_many :assay_publications, -> { distinct }, through: :related_assays, source: :publications

  acts_as_isa

  validates :study,  presence: true, projects: true
  validate :study_matches_assays_if_present

  accepts_nested_attributes_for :data_files, allow_destroy: true

  has_extended_metadata

  # the associated projects from the Investigation.
  # Overrides the :through :study, as that relies on being saved to the database first, causing validation issues
  def projects
    study&.projects || []
  end

  def contributors
    [contributor]
  end

  def related_people
    (creators + contributors).compact.uniq
  end

  def related_data_file_ids
    data_file_ids | assay_data_file_ids
  end

  def related_sop_ids
    assay_sop_ids
  end

  def related_publication_ids
    assay_publication_ids
  end

  def self.filter_by_projects(projects)
    joins(:projects).where(investigations: {investigations_projects: {project_id: projects}})
  end

  private

  def study_matches_assays_if_present
    return if samples.empty?
    samples.each do |sample|
      sample.assays.each do |assay|
        if assay.study != study
          errors.add(:study, 'must match the associated assay')
          return false
        end
      end
    end
  end
end
