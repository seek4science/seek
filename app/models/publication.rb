require 'libxml'

class Publication < ApplicationRecord
  include Seek::Rdf::RdfGeneration

  alias_attribute :description, :abstract

  # searchable must come before acts_as_asset is called
  if Seek::Config.solr_enabled
    searchable(auto_index: false) do
      text :journal, :pubmed_id, :doi, :published_date
      text :publication_authors do
        seek_authors.map(&:person).collect(&:name)
      end
      text :non_seek_authors do
        non_seek_authors.compact.map(&:first_name) | non_seek_authors.compact.map(&:last_name)
      end
    end
  end

  has_many :related_relationships, -> { where(predicate: Relationship::RELATED_TO_PUBLICATION) },
           class_name: 'Relationship', as: :other_object, dependent: :destroy, inverse_of: :other_object

  has_many :data_files, through: :related_relationships, source: :subject, source_type: 'DataFile'
  has_many :models, through: :related_relationships, source: :subject, source_type: 'Model'
  has_many :assays, through: :related_relationships, source: :subject, source_type: 'Assay'
  has_many :studies, through: :related_relationships, source: :subject, source_type: 'Study'
  has_many :investigations, through: :related_relationships, source: :subject, source_type: 'Investigation'
  has_many :presentations, through: :related_relationships, source: :subject, source_type: 'Presentation'

  acts_as_asset
  validates :title, length: { maximum: 65_535 }

  has_many :publication_authors, dependent: :destroy, autosave: true
  has_many :persons, through: :publication_authors

  VALID_DOI_REGEX = /\A(10[.][0-9]{4,}(?:[.][0-9]+)*\/(?:(?!["&\'<>])\S)+)\z/
  VALID_PUBMED_REGEX = /\A(([1-9])([0-9]{0,7}))\z/
  # Note that the PubMed regex deliberately does not allow versions

  validates :doi, format: { with: VALID_DOI_REGEX, message: 'is invalid' }, allow_blank: true
  validates :pubmed_id, numericality: { greater_than: 0, message: 'is invalid' }, allow_blank: true

  # validation differences between OpenSEEK and the VLN SEEK
  validates_uniqueness_of :pubmed_id, allow_nil: true, allow_blank: true, if: -> { Seek::Config.is_virtualliver }
  validates_uniqueness_of :doi, allow_nil: true, allow_blank: true, if: -> { Seek::Config.is_virtualliver }
  validates_uniqueness_of :title, if: -> { Seek::Config.is_virtualliver }

  validate :check_uniqueness_within_project, unless: -> { Seek::Config.is_virtualliver }

  attr_writer :refresh_policy
  before_save :refresh_policy, on: :update
  after_update :update_creators_from_publication_authors

  accepts_nested_attributes_for :publication_authors

  # http://bioruby.org/rdoc/Bio/Reference.html#method-i-format
  # key for the file-extension and format used in the route
  # value contains the format used by bioruby that name for the view and mimetype for the response
  EXPORT_TYPES = Hash.new { |_hash, key| raise("Export type #{key} is not supported") }.update(
    # http://filext.com/file-extension/ENW
    enw: { format: 'endnote', name: 'Endnote', mimetype: 'application/x-endnote-refer' },
    # http://filext.com/file-extension/bibtex
    bibtex: { format: 'bibtex', name: 'BiBTeX', mimetype: 'application/x-bibtex' }, # (option available)
    # http://filext.com/file-extension/EMBL
    # ftp://ftp.embl.de/pub/databases/embl/doc/usrman.txt
    embl: { format: 'embl', name: 'EMBL', mimetype: 'chemical/x-embl-dl-nucleotide' }
  ).freeze

  def update_creators_from_publication_authors
    self.creators = seek_authors.map(&:person)
  end

  def publication_authors_attributes=(*args)
    self.refresh_policy = true
    super(*args)
  end

  def refresh_policy
    if @refresh_policy
      policy.permissions.clear

      populate_policy_from_authors(policy)

      policy.save

      self.refresh_policy = false
    end

    true
  end

  if Seek::Config.events_enabled
    has_and_belongs_to_many :events
  else
    def events
      []
    end

    def event_ids
      []
    end

    def event_ids=(events_ids); end

  end

  def pubmed_uri
    "https://www.ncbi.nlm.nih.gov/pubmed/#{pubmed_id}" if pubmed_id
  end

  def doi_uri
    "https://doi.org/#{doi}" if doi
  end

  # Automatically extract the actual DOI if the user put in the full URL
  def doi=(doi)
    doi = doi.gsub(/(https?:\/\/)?(dx\.)?doi\.org\//,'') if doi
    super(doi)
  end

  def default_policy
    Policy.new(name: 'publication_policy', access_type: Policy::VISIBLE).tap do |policy|
      populate_policy_from_authors(policy)
    end
  end

  def seek_authors
    publication_authors.select(&:person)
  end

  def non_seek_authors
    publication_authors.where(person_id: nil)
  end

  def contributor_credited?
    false
  end

  def extract_metadata(reference)
    if reference.respond_to?(:pubmed)
      extract_pubmed_metadata(reference)
    else
      extract_doi_metadata(reference)
    end

    reference.authors.each_with_index do |author, index|
      publication_authors.build(first_name: author.first_name,
                                last_name: author.last_name,
                                author_index: index)
    end
  end

  # @param reference Bio::Reference
  # @see https://github.com/bioruby/bioruby/blob/master/lib/bio/reference.rb
  def extract_pubmed_metadata(reference)
    self.title = reference.title.chomp # remove full stop
    self.abstract = reference.abstract
    self.journal = reference.journal
    self.pubmed_id = reference.pubmed
    self.published_date = reference.published_date
    self.citation = reference.citation
  end

  # @param doi_record DOI::Record
  # @see https://github.com/SysMO-DB/doi_query_tool/blob/master/lib/doi_record.rb
  def extract_doi_metadata(doi_record)
    self.title = doi_record.title
    self.published_date = doi_record.date_published
    self.journal = doi_record.journal
    self.doi = doi_record.doi
    self.publication_type = doi_record.publication_type
    self.citation = doi_record.citation
  end

  # @param bibtex_record BibTeX entity from bibtex-ruby gem
  def extract_bibtex_metadata(bibtex_record)
    self.title           = bibtex_record.title.try(:to_s).try(:encode!)
    self.abstract        = bibtex_record[:abstract].try(:to_s).try(:encode!) || ''
    self.journal         = bibtex_record.journal.try(:to_s).try(:encode!)
    self.published_date  = Date.new(bibtex_record.year.try(:to_i), bibtex_record.month_numeric || 1, bibtex_record[:day].try(:to_i) || 1)
    self.doi             = bibtex_record[:doi].try(:to_s).try(:encode!)
    self.pubmed_id       = bibtex_record[:pubmed_id].try(:to_s).try(:encode!)
    plain_authors = bibtex_record[:author].split(' and ') # by bibtex definition
    plain_authors.each_with_index do |author, index| # multiselect
      next if author.empty?
      last_name, first_name = author.split(', ') # by bibtex definition
      pa = PublicationAuthor.new(publication: self,
                                 first_name: first_name.try(:encode),
                                 last_name: last_name.try(:encode),
                                 author_index: index)
      publication_authors << pa
    end
  end

  def associate(item)
    clause = { subject_type: item.class.name,
               subject_id: item.id,
               predicate: Relationship::RELATED_TO_PUBLICATION,
               other_object_type: 'Publication',
               other_object_id: id }

    related_relationships.where(clause).first_or_create!
  end

  has_many :assay_data_files, through: :assays, source: :data_files
  # includes those related directly, or through an assay
  def related_data_files
    DataFile.where(id: related_data_file_ids)
  end

  def related_data_file_ids
    data_file_ids | assay_data_file_ids
  end

  has_many :assay_models, through: :assays, source: :models
  # includes those related directly, or through an assay
  def related_models
    Model.where(id: related_model_ids)
  end

  def related_model_ids
    model_ids | assay_model_ids
  end

  # indicates whether the publication has data files or models linked to it (either directly or via an assay)
  def has_assets?
    assets.none?
  end

  def assets
    data_files | models | presentations
  end

  has_many :assays_organisms, through: :assays, source: :organisms
  has_many :models_organisms, through: :models, source: :organism
  def related_organisms
    Organism.where(id: related_organism_ids)
  end

  def related_organism_ids
    assays_organism_ids | models_organism_ids
  end

  def self.subscribers_are_notified_of?(action)
    action == 'create'
  end

  # export the publication as one of the available types:
  # http://bioruby.org/rdoc/Bio/Reference.html
  # @export_type a registered mime_type that is a valid key to EXPORT_TYPES
  def export(export_type)
    bio_reference.format(EXPORT_TYPES[export_type][:format])
  end

  def publication_author_names
    author_names = []
    publication_authors.each do |author|
      seek_author = author.person
      author_names << if seek_author.nil?
                        author.first_name + ' ' + author.last_name
                      else
                        seek_author.name
                      end
    end
    author_names
  end

  def has_doi?
    self.doi.present?
  end

  def latest_citable_resource
    self
  end

  private

  def populate_policy_from_authors(pol)
    # add managers (authors + contributor)
    (creators | seek_authors.map(&:person)).each do |author|
      pol.permissions.build(contributor: author, access_type: Policy::MANAGING)
    end
    # Add contributor
    c = contributor || default_contributor
    pol.permissions.build(contributor: c.person, access_type: Policy::MANAGING) if c

    pol.permissions
  end

  def pubmed_entry
    if pubmed_id
      Rails.cache.fetch("bio-reference-#{pubmed_id}") do
        entry = Bio::PubMed.efetch(pubmed_id).first
        raise "PubMed entry was nil" if entry.nil?
        entry
      end
    end
  end

  def bio_reference
    if pubmed_id
      Bio::MEDLINE.new(pubmed_entry).reference
    else
      # TODO: Bio::Reference supports a 'url' option. Should this be the URL on seek, or the URL of the 'View Publication' button, or neither?
      Bio::Reference.new({ title: title, journal: journal, abstract: abstract,
                           authors: publication_authors.map { |e| e.person ? [e.person.last_name, e.person.first_name].join(', ') : [e.last_name, e.first_name].join(', ') },
                           year: published_date.try(:year) }.with_indifferent_access)
    end
  end

  def check_uniqueness_within_project
    { title: 'title', doi: 'DOI', pubmed_id: 'PubMed ID' }.each do |attr, name|
      next unless send(attr).present?
      existing = Publication.where(attr => send(attr)).to_a - [self]
      next unless existing.any?
      matching_projects = existing.collect(&:projects).flatten.uniq & projects
      if matching_projects.any?
        errors[attr] << "You cannot register the same #{name} within the same project."
        return false
      end
    end
  end

  # defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    Seek::Config.publications_enabled
  end
end
