require 'libxml'

class Publication < ActiveRecord::Base
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

  acts_as_asset

  has_many :publication_authors, dependent: :destroy, autosave: true
  has_many :persons, through: :publication_authors

  has_many :backwards_relationships,
           class_name: 'Relationship',
           as: :other_object,
           dependent: :destroy

  VALID_DOI_REGEX = /\A(10[.][0-9]{4,}(?:[.][0-9]+)*\/(?:(?!["&\'<>])\S)+)\z/
  VALID_PUBMED_REGEX = /\A(([1-9])([0-9]{0,7}))\z/
  # Note that the PubMed regex deliberately does not allow versions

  validates :doi, format: { with: VALID_DOI_REGEX, message: 'is invalid' }, allow_blank: true
  validates :pubmed_id, numericality: { greater_than: 0, message: 'is invalid' }, allow_blank: true

  # validation differences between OpenSEEK and the VLN SEEK
  validates_uniqueness_of :pubmed_id, allow_nil: true, allow_blank: true, if: 'Seek::Config.is_virtualliver'
  validates_uniqueness_of :doi, allow_nil: true, allow_blank: true, if: 'Seek::Config.is_virtualliver'
  validates_uniqueness_of :title, if: 'Seek::Config.is_virtualliver'

  validate :check_uniqueness_within_project, unless: 'Seek::Config.is_virtualliver'

  after_update :update_creators_from_publication_authors

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
    "https://dx.doi.org/#{doi}" if doi
  end

  # Automatically extract the actual DOI if the user put in the full URL
  def doi=(doi)
    doi = doi.gsub(/(https?:\/\/)?dx\.doi\.org\//,'') if doi
    super(doi)
  end

  def default_policy
    policy = Policy.new(name: 'publication_policy', access_type: Policy::VISIBLE)
    # add managers (authors + contributor)
    creators.each do |author|
      policy.permissions << Permissions.create(contributor: author, policy: policy, access_type: Policy::MANAGING)
    end
    # Add contributor
    c = contributor || default_contributor
    policy.permissions << Permission.create(contributor: c.person, policy: policy, access_type: Policy::MANAGING) if c
    policy
  end

  scope :default_order, -> { order('published_date DESC') }

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

  def data_files
    backwards_relationships.select { |a| a.subject_type == 'DataFile' }.collect(&:subject)
  end

  def models
    backwards_relationships.select { |a| a.subject_type == 'Model' }.collect(&:subject)
  end

  def assays
    backwards_relationships.select { |a| a.subject_type == 'Assay' }.collect(&:subject)
  end

  def studies
    backwards_relationships.select { |a| a.subject_type == 'Study' }.collect(&:subject)
  end

  def investigations
    backwards_relationships.select { |a| a.subject_type == 'Investigation' }.collect(&:subject)
  end

  def presentations
    backwards_relationships.select { |a| a.subject_type == 'Presentation' }.collect(&:subject)
  end

  def associate(item)
    clause = { subject_type: item.class.name,
               subject_id: item.id,
               predicate: Relationship::RELATED_TO_PUBLICATION,
               other_object_type: 'Publication',
               other_object_id: id }
    Relationship.create(clause) unless Relationship.where(clause).any?
  end

  # includes those related directly, or through an assay
  def related_data_files
    via_assay = assays.collect(&:data_files).flatten.uniq.compact
    via_assay | data_files
  end

  # includes those related directly, or through an assay
  def related_models
    via_assay = assays.collect(&:models).flatten.uniq.compact
    via_assay | models
  end

  # indicates whether the publication has data files or models linked to it (either directly or via an assay)
  def has_assets?
    assets.none?
  end

  def assets
    data_files | models | presentations
  end

  # returns a list of related organisms, related through either the assay or the model
  def related_organisms
    organisms = assays.collect(&:organisms).flatten
    organisms |= models.collect(&:organism).flatten
    organisms.uniq.compact
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

  # those displayed on the right. We don't want authors listed as creators here (OPSK-1247). Changing .creators breaks behaviour when editing
  def displayed_creators
    [contributor].compact.map do |creator|
      creator.is_a?(User) ? creator.person : creator
    end
  end

  private

  def bio_reference
    if pubmed_id
      Bio::MEDLINE.new(Bio::PubMed.efetch(pubmed_id).first).reference
    else
      # TODO: Bio::Reference supports a 'url' option. Should this be the URL on seek, or the URL of the 'View Publication' button, or neither?
      Bio::Reference.new({ title: title, journal: journal, abstract: abstract,
                           authors: publication_authors.map { |e| e.person ? [e.person.last_name, e.person.first_name].join(', ') : [e.last_name, e.first_name].join(', ') },
                           year: published_date.year }.with_indifferent_access)
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
