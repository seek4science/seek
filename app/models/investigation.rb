class Investigation < ApplicationRecord

  acts_as_isa
  acts_as_snapshottable

  has_filter :is_isa_json_compliant
  has_many :studies
  has_many :study_publications, through: :studies, source: :publications
  has_many :assays, through: :studies
  has_many :assay_publications, through: :assays, source: :publications

  validates :projects, presence: true, projects: { self: true }

  belongs_to :assignee, class_name: 'Person'

  has_many :study_sops, through: :studies, source: :sops
  has_many :assay_sops, -> { distinct }, through: :assays, source: :sops
  has_many :sop_versions, through: :studies
  has_many :assay_data_files, -> { distinct }, through: :assays, source: :data_files
  has_many :data_file_versions, -> { distinct }, through: :studies
  has_many :assay_samples, -> { distinct }, through: :assays, source: :samples
  has_many :observation_units, through: :studies
  has_many :observations_unit_data_files, -> { distinct }, through: :observation_units, source: :data_files
  has_many :observations_unit_samples, -> { distinct }, through: :observation_units, source: :samples

  has_many :fair_data_station_uploads, dependent: :destroy
  def state_allows_delete?(*args)
    studies.empty? && super
  end

  def clone_with_associations
    new_object = dup
    new_object.policy = policy.deep_copy
    new_object.project_ids = project_ids
    new_object.publications = publications
    new_object
  end

  # related
  def assets
    related_data_files + related_sops + related_models + related_publications + related_documents
  end

  %w[model document].each do |type|
    has_many "#{type}_versions".to_sym, -> { distinct }, through: :studies
    has_many "related_#{type.pluralize}".to_sym, -> { distinct }, through: :studies
  end

  def related_data_file_ids
    observations_unit_data_file_ids | assay_data_file_ids
  end

  def related_publication_ids
    publication_ids | study_publication_ids | assay_publication_ids
  end

  def related_sop_ids
    study_sop_ids | assay_sop_ids
  end

  def related_sample_ids
    observations_unit_sample_ids | assay_sample_ids
  end

  def related_samples
    Sample.where(id: related_sample_ids)
  end

  def positioned_studies
    studies.order(position: :asc)
  end
  
  def self.user_creatable?
    Seek::Config.investigations_enabled
  end

  # utility method for cleaning up durng testing, not to be used in production code
  def deep_destroy!
    raise 'need to be admin' unless User.current_user&.is_admin?
    disable_authorization_checks do
      assays.each do |assay|
        assay.samples.each do |sample|
          sample.destroy
        end
        assay.data_files.each do |df|
          df.destroy
        end
        assay.destroy
      end
      studies.each do |study|
        study.observation_units.each do |obs_unit|
          obs_unit.samples.each do |sample|
            sample.destroy
          end
          obs_unit.data_files.each do |df|
            df.destroy
          end
          obs_unit.destroy
        end
        study.destroy
      end
      destroy
    end

  end
end
