class Investigation < ApplicationRecord
  include Seek::Rdf::RdfGeneration

  acts_as_isa
  acts_as_snapshottable

  has_many :studies
  has_many :study_publications, through: :studies, source: :publications
  has_many :assays, through: :studies
  has_many :assay_publications, through: :assays, source: :publications

  validates :projects, presence: true, projects: { self: true }

  def state_allows_delete?(*args)
    studies.empty? && super
  end

  %w[data_file sop model document].each do |type|
    has_many "#{type}_versions".to_sym, -> { distinct }, through: :studies
    has_many "related_#{type.pluralize}".to_sym, -> { distinct }, through: :studies
  end

  def assets
    related_data_files + related_sops + related_models + related_publications + related_documents
  end

  def clone_with_associations
    new_object = dup
    new_object.policy = policy.deep_copy
    new_object.project_ids = project_ids
    new_object.publications = publications
    new_object
  end

  def related_publication_ids
    publication_ids | study_publication_ids | assay_publication_ids
  end
end
