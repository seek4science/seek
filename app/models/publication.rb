require 'libxml'

class Publication < ApplicationRecord
  include Seek::Rdf::RdfGeneration
  include Seek::ActsAsHavingMiscLinks
  include PublicationsHelper

  alias_attribute :description, :abstract

  # searchable must come before acts_as_asset is called
  if Seek::Config.solr_enabled
    searchable(auto_index: false) do
      text :journal, :pubmed_id, :doi, :published_date, :human_disease_terms
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
  has_many :workflows, through: :related_relationships, source: :subject, source_type: 'Workflow'

  has_and_belongs_to_many :human_diseases
  has_filter :human_disease

  acts_as_asset
  validates :title, length: { maximum: 65_535 }

  acts_as_having_misc_links

  has_many :publication_authors, dependent: :destroy, autosave: true
  has_many :people, through: :publication_authors

  has_one :content_blob, ->(r) { where('content_blobs.asset_version =?', r.version) }, as: :asset, foreign_key: :asset_id

  explicit_versioning(:version_column => "version", sync_ignore_columns: ['license','other_creators']) do
    acts_as_versioned_resource
    has_one :content_blob, -> (r) { where('content_blobs.asset_version =? AND content_blobs.asset_type =?', r.version, r.parent.class.name) },
            :primary_key => :publication_id,:foreign_key => :asset_id
  end

  belongs_to :publication_type

  VALID_DOI_REGEX = /\A10.\d{4,9}\/[<>\-._;()\/:A-Za-z0-9]+\z/
  VALID_PUBMED_REGEX = /\A(([1-9])([0-9]{0,7}))\z/
  # Note that the PubMed regex deliberately does not allow versions

  validates :doi, format: { with: VALID_DOI_REGEX, message: 'is invalid' }, allow_blank: true
  validates :pubmed_id, numericality: { greater_than: 0, message: 'is invalid' }, allow_blank: true
  validates :publication_type_id, presence: true, on: :create

  # validation differences between OpenSEEK and the VLN SEEK
  validates_uniqueness_of :pubmed_id, allow_nil: true, allow_blank: true, if: -> { Seek::Config.is_virtualliver }
  validates_uniqueness_of :doi, allow_nil: true, allow_blank: true, if: -> { Seek::Config.is_virtualliver }
  validates_uniqueness_of :title, if: -> { Seek::Config.is_virtualliver }

  validate :check_uniqueness_within_project, unless: -> { Seek::Config.is_virtualliver }

  attr_writer :refresh_policy
  before_save :refresh_policy, on: :update
  after_update :update_creators_from_publication_authors

  accepts_nested_attributes_for :publication_authors

  # Types of registration
  REGISTRATION_BY_PUBMED = 1
  REGISTRATION_BY_DOI    = 2
  REGISTRATION_MANUALLY = 3
  REGISTRATION_FROM_BIBTEX = 4

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

  # Returns the columns to be shown on the table view for the resource
  def columns_default
    super + ['published_date','journal']
  end

  def columns_allowed
    columns_default + ['abstract','last_used_at','doi','citation','booktitle','publisher','editor','url']
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

  def human_disease_terms
    human_diseases.collect(&:searchable_terms).flatten
  end

  def default_policy
    Policy.new(name: 'publication_policy', access_type: Policy::ACCESSIBLE).tap do |policy|
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

  def is_in_isa_publishable?
    false
  end

  def extract_metadata(pubmed_id, doi)

    reference = fetch_pubmed_or_doi_result(pubmed_id, doi)

    if reference.nil? || self.errors.any?
      return
    end

    if reference.respond_to?(:pubmed)
      result = extract_pubmed_metadata(reference)
    else
      result = extract_doi_metadata(reference)
    end

    reference.authors.each_with_index do |author, index|
      publication_authors.build(first_name: author.first_name,
                                last_name: author.last_name,
                                author_index: index)
    end
    return reference
  end

  # @param reference Bio::Reference
  # @see https://github.com/bioruby/bioruby/blob/master/lib/bio/reference.rb
  def extract_pubmed_metadata(reference)
    self.registered_mode = Publication::REGISTRATION_BY_PUBMED
    self.title = reference.title.chomp # remove full stop
    self.abstract = reference.abstract
    self.journal = reference.journal
    self.pubmed_id = reference.pubmed
    self.published_date = reference.published_date
    self.citation = reference.citation
    #currently the metadata fetched by pubmed id doesn't contain the following items.
    # TODO
    self.publisher = nil
    self.booktitle = nil
    self.editor = nil
  end

  # @param doi_record DOI::Record
  # @see https://github.com/SysMO-DB/doi_query_tool/blob/master/lib/doi_record.rb
  def extract_doi_metadata(doi_record)
    self.registered_mode = Publication::REGISTRATION_BY_DOI
    self.title = doi_record.title
    self.abstract = doi_record.abstract
    self.published_date = doi_record.date_published
    self.journal = doi_record.journal
    self.doi = doi_record.doi
    self.citation = doi_record.citation
    self.publisher = doi_record.publisher
    self.booktitle = doi_record.booktitle
    self.editor = doi_record.editors.map(&:name).join(" and ")
  end

  # @param bibtex_record BibTeX entity from bibtex-ruby gem
  def extract_bibtex_metadata(bibtex_record)
    self.registered_mode = Publication::REGISTRATION_FROM_BIBTEX
    self.publication_type_id = PublicationType.get_publication_type_id(bibtex_record)
    self.title           = bibtex_record[:title].try(:to_s).gsub /{|}/, '' unless bibtex_record[:title].nil?
    self.title           = bibtex_record[:chapter].try(:to_s).gsub /{|}/, '' if (self.title.nil? && !bibtex_record[:chapter].nil?)
    self.title         += ( ":"+ (bibtex_record[:subtitle].try(:to_s).gsub /{|}/, '')) unless bibtex_record[:subtitle].nil?

    if check_bibtex_file (bibtex_record)
      self.abstract = bibtex_record[:abstract].try(:to_s)
      self.journal = bibtex_record.journal.try(:to_s)
      month = bibtex_record[:month].try(:to_s)
      year = bibtex_record[:year].try(:to_s)
      self.published_date = Date.new(bibtex_record.year.try(:to_i) || 1, bibtex_record.month_numeric || 1, bibtex_record[:day].try(:to_i) || 1)
      self.published_date = nil if self.published_date.to_s == "0001-01-01"
      self.doi = bibtex_record[:doi].try(:to_s)
      self.pubmed_id = bibtex_record[:pubmed_id].try(:to_s)
      self.booktitle = bibtex_record[:booktitle].try(:to_s)
      self.publisher = bibtex_record[:publisher].try(:to_s)
      self.editor = bibtex_record[:editors].try(:to_s)
      self.url = parse_bibtex_url(bibtex_record).try(:to_s)

      unless bibtex_record[:author].nil?
        plain_authors = bibtex_record[:author].split(' and ') # by bibtex definition
        plain_authors.each_with_index do |author, index| # multiselect
          next if author.empty?
          last_name, first_name = author.split(', ') # by bibtex definition
          unless first_name.nil?
            first_name = first_name.try(:to_s).gsub /^{|}$/, ''
          end
          unless last_name.nil?
            last_name = last_name.try(:to_s).gsub /^{|}$/, ''
          end
          pa = PublicationAuthor.new(publication: self,
                                     first_name: first_name,
                                     last_name: last_name,
                                     author_index: index)
          publication_authors << pa
        end
      end

      unless bibtex_record[:editor].nil? && bibtex_record[:editors].nil?
        self.editor = bibtex_record[:editor].try(:to_s) || bibtex_record[:editors].try(:to_s)
      end

      # in some cases, e.g. proceedings, book, there are no authors but only editors
      if bibtex_record[:author].nil? && !self.editor.nil?
        plain_editors = self.editor.split(' and ') # by bibtex definition
        plain_editors.each_with_index do |editor, index| # multiselect
          next if editor.empty?
          last_name, first_name = editor.split(', ') # by bibtex definition
          unless first_name.nil?
            first_name = first_name.try(:to_s).gsub /^{|}$/, ''
          end
          unless last_name.nil?
            last_name = last_name.try(:to_s).gsub /^{|}$/, ''
          end
          pa = PublicationAuthor.new(publication: self,
                                     first_name: first_name,
                                     last_name: last_name,
                                     author_index: index)
          publication_authors << pa
        end
      end

      #using doi/pubmed_id to fetch the metadata
      result = fetch_pubmed_or_doi_result(self.pubmed_id, self.doi) if self.pubmed_id.present? || self.doi.present?

      unless result.nil?
        self.citation = result.citation unless result.citation.nil?

        if self.journal.nil? && !result.journal.nil?
          self.journal = result.journal
        end

        self.published_date = result.date_published unless result.date_published.nil?
      end

      if self.citation.nil?
        self.generate_citation(bibtex_record)
      end
      return true
    else
      return false
    end
  end

  # generating the citations for different types of publications by using the data from Bibtex file when no doi/pubmed_id
  def generate_citation(bibtex_record)
    self.citation = ''
    month = bibtex_record[:month].try(:to_s)
    year = bibtex_record[:year].try(:to_s)
    page_or_pages = (bibtex_record[:pages].try(:to_s).match?(/[^0-9]/) ? "pp." : "p." ) unless bibtex_record[:pages].nil?
    pages = bibtex_record[:pages].try(:to_s)
    volume = bibtex_record[:volume].try(:to_s)
    series = bibtex_record[:series].try(:to_s)
    number = bibtex_record[:number].try(:to_s)
    address = bibtex_record[:address].try(:to_s)
    school = bibtex_record[:school].try(:to_s)
    tutor = bibtex_record[:tutor].try(:to_s)
    tutorhits = bibtex_record[:tutorhits].try(:to_s)
    institution = bibtex_record[:institution].try(:to_s)
    type = bibtex_record[:type].try(:to_s)
    note = bibtex_record[:note].try(:to_s)
    archivePrefix = bibtex_record[:archiveprefix].try(:to_s)
    primaryClass = bibtex_record[:primaryclass].try(:to_s)
    eprint= bibtex_record[:eprint].try(:to_s)
    url = parse_bibtex_url(bibtex_record).try(:to_s)
    publication_type = PublicationType.find(self.publication_type_id)

    if publication_type.is_journal?
      self.citation += self.journal.nil? ? '':self.journal
      self.citation += volume.blank? ? '': ' '+volume
      self.citation += number.nil? ? '' : '('+ number+')'
      self.citation += pages.blank? ? '' : (':'+pages)
=begin
      unless year.nil?
        self.citation += year.nil? ? '' : (' '+year)
      end
=end
    elsif publication_type.is_booklet?
      self.citation += howpublished.blank? ? '': ''+ howpublished
      self.citation += address.nil? ? '' : (', '+ address)
=begin
      unless year.nil?
        self.citation += year.nil? ? '' : (' '+year)
      end
=end
    elsif publication_type.is_inbook?
      self.citation += self.booktitle.nil? ? '' : ('In '+ self.booktitle)
      self.citation += volume.blank? ? '' : (', volume '+ volume)
      self.citation += series.blank? ? '' : (' of '+series)
      self.citation += pages.blank? ? '' : (', '+ page_or_pages + ' '+pages)
      self.citation += self.editor.blank? ? '' : (', Eds: '+ self.editor)
      self.citation += self.publisher.blank? ? '' : (', '+ self.publisher)
      unless address.nil? || (self.booktitle.try(:include?, address))
        self.citation += address.nil? ? '' : (', '+ address)
      end
=begin
      unless self.booktitle.try(:include?, year)
        unless year.nil?
          self.citation += year.nil? ? '' : (' '+year)
        end
      end
=end
    elsif publication_type.is_inproceedings? || publication_type.is_incollection? || publication_type.is_book?
      # InProceedings / InCollection
      self.citation += self.booktitle.nil? ? '' : ('In '+ self.booktitle)
      self.citation += volume.blank? ? '' : (', vol. '+ volume)
      self.citation += series.blank? ? '' : (' of '+series)
      self.citation += pages.blank? ? '' : (', '+ page_or_pages + ' '+pages)
      self.citation += self.editor.blank? ? '' : (', Eds: '+ self.editor)
      self.citation += self.publisher.blank? ? '' : (', '+ self.publisher)
      unless address.nil? || (self.booktitle.try(:include?, address))
        self.citation += address.nil? ? '' : (', '+ address)
      end
=begin
      unless self.booktitle.try(:include?, year)
        unless year.nil?
          self.citation += year.nil? ? '' : (', '+year)
        end
      end
=end
    elsif publication_type.is_phd_thesis? || publication_type.is_masters_thesis? || publication_type.is_bachelor_thesis?
      #PhD/Master Thesis
      self.citation += school.nil? ? '' : (' '+ school)
      self.errors.add(:base,'A thesis need to have a school') if school.nil?
      self.citation += year.nil? ? '' : (', '+ year)
      self.citation += tutor.nil? ? '' : (', '+ tutor+'(Tutor)')
      self.citation += tutorhits.nil? ? '' : (', '+ tutorhits+'(HITS Tutor)')
      self.citation += url.nil? ? '' : (', '+ url)
    elsif publication_type.is_proceedings?
      # Proceedings are conference proceedings, it has no authors but editors
      # Book
      self.journal = self.title
      self.citation += volume.blank? ? '' : ('vol. '+ volume)
      self.citation += series.blank? ? '' : (' of '+series)
      self.citation += self.publisher.blank? ? '' : (', '+ self.publisher)
=begin
      unless month.nil? && year.nil?
        self.citation += self.citation.blank? ? '' : ','
        self.citation += month.nil? ? '' : (' '+ month.capitalize)
        self.citation += year.nil? ? '' : (' '+year)
      end
=end
    elsif publication_type.is_tech_report?
      self.citation += institution.blank? ? ' ': institution
      self.citation += type.blank? ? ' ' : (', '+type)
    elsif publication_type.is_unpublished?
      self.citation += note.blank? ? ' ': note
    end

    if self.doi.blank? && self.citation.blank?
      self.citation += archivePrefix unless archivePrefix.nil?
      self.citation += (self.citation.blank? ? primaryClass : (','+primaryClass)) unless primaryClass.nil?
      self.citation += (self.citation.blank? ? eprint : (','+eprint)) unless eprint.nil?
      self.journal = self.citation if self.journal.blank?
    end

    if self.doi.blank? && self.citation.blank?
     self.citation += url.blank? ? '': url
    end
    self.citation =  self.citation.try(:to_s).strip.gsub(/^,/,'').strip
  end

  def fetch_pubmed_or_doi_result(pubmed_id, doi)
    result = nil
    @error = nil
    if !pubmed_id.blank?
      begin
        result = Bio::MEDLINE.new(Bio::PubMed.efetch(pubmed_id).first).reference
        @error = result.error
      rescue => exception
        raise exception unless Rails.env.production?
        result ||= Bio::Reference.new({})
        @error = 'There was a problem contacting the PubMed query service. Please try again later'
        Seek::Errors::ExceptionForwarder.send_notification(exception, data: {message: "Problem accessing ncbi using pubmed id #{pubmed_id}"})
      end
    elsif !doi.blank?
      begin
        query = DOI::Query.new(Seek::Config.crossref_api_email)
        result = query.fetch(doi)

        @error = 'Unable to get result' if result.blank?
        @error = 'Unable to get DOI' if result.title.blank?
      rescue DOI::MalformedDOIException
        @error = 'The DOI you entered appears to be malformed.'
      rescue DOI::NotFoundException
        @error = 'The DOI you entered could not be resolved.'
      rescue RuntimeError => exception
        @error = 'There was an problem contacting the DOI query service. Please try again later'
        Seek::Errors::ExceptionForwarder.send_notification(exception, data: {message: "Problem accessing crossref using DOI #{doi}"})
      end
    else
      @error = 'Please enter either a DOI or a PubMed ID for the publication.'
    end

    self.errors.add(:base, @error) unless @error.nil?
    result
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

  has_filter organism: Seek::Filtering::Filter.new(
    value_field: 'organisms.id',
    label_field: 'organisms.title',
    joins: [:assays_organisms, :models_organisms]
  )

  # returns a list of related human diseases, related through either the assay or the model
  def related_human_diseases
    (assays.collect(&:human_diseases).flatten | models.collect(&:human_disease).flatten).uniq
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
    publication_authors.map(&:full_name)
  end

  def has_doi?
    self.doi.present?
  end

  def latest_citable_resource
    self
  end

  def can_soft_delete_full_text?(user = User.current_user)
    return false if user.nil? || user.person.nil? || !Seek::Config.allow_publications_fulltext
    return true if user.is_admin?
    contributor == can_edit(user) || projects.detect { |project| project.can_manage?(user) }.present?
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
                           year: published_date.try(:year),
                           url: url,
                           doi: doi
                           }.with_indifferent_access)
    end
  end

  def check_uniqueness_within_project
    { title: 'title', doi: 'DOI', pubmed_id: 'PubMed ID' }.each do |attr, name|
      next unless send(attr).present?
      existing = Publication.where(attr => send(attr)).to_a - [self]
      next unless existing.any?
      matching_projects = existing.collect(&:projects).flatten.uniq & projects
      if matching_projects.any?
        errors.add(:base, "You cannot register the same #{name} within the same project.")
        return false
      end
    end
  end

  def check_bibtex_file (bibtex_record)


    if self.title.blank?
      errors.add(:base, "Please check your bibtex files, each publication should contain a title or a chapter name.")
      return false
    end

    if (%w[InCollection InProceedings].include? self.publication_type.title) && (bibtex_record[:booktitle].blank?)
        errors.add(:base, "An #{self.publication_type.title} needs to have a booktitle.")
        return false
    end

    unless %w[Booklet Manual Misc Proceedings].include? self.publication_type.title
      if bibtex_record[:author].nil? && self.editor.nil?
        self.errors.add(:base, "You need at least one author or editor for the #{self.publication_type.title}.")
        return false
      end
    end

    if self.publication_type.is_phd_thesis? || self.publication_type.is_masters_thesis? || self.publication_type.is_bachelor_thesis?
      if bibtex_record[:school].try(:to_s).nil?
        self.errors.add(:base,"A #{self.publication_type.title} needs to have a school.")
        return false
      end
    end
    return true
  end

  def parse_bibtex_url(bibtex_record)
    pub_url=nil
    howpublished = bibtex_record[:howpublished].try(:to_s)
    note = bibtex_record[:note].try(:to_s)
    url = bibtex_record[:url].try(:to_s)
    biburl = bibtex_record[:biburl].try(:to_s)

    pub_url = url if url.try(:include?,'http')
    pub_url ||= howpublished if howpublished.try(:include?,'http')
    pub_url ||= note if note.try(:include?,'http')
    pub_url ||= biburl if biburl.try(:include?,'http')

    if (pub_url.try(:start_with?,'\url'))
      pub_url = pub_url.gsub('\url', '')
    end
    pub_url
  end

  def self.user_creatable?
    Seek::Config.publications_enabled
  end
end
