
require 'grouped_pagination'
require 'title_trimmer'
require 'libxml'

class Publication < ActiveRecord::Base
  include Seek::Rdf::RdfGeneration
  title_trimmer
  alias_attribute :description, :abstract
  #searchable must come before acts_as_asset is called
  searchable(:auto_index=>false) do
    text :journal,:pubmed_id, :doi, :published_date
    text :publication_authors do
      seek_authors.map(&:person).collect{|p| p.name}
    end
    text :non_seek_authors do
      non_seek_authors.compact.map(&:first_name) | non_seek_authors.compact.map(&:last_name)
    end
  end if Seek::Config.solr_enabled

  acts_as_asset

  has_many :publication_authors, :dependent => :destroy, :autosave => true

  has_many :backwards_relationships,
           :class_name => 'Relationship',
           :as => :other_object,
           :dependent => :destroy

  #validation differences between OpenSEEK and the VLN SEEK
  validates_uniqueness_of :pubmed_id , :allow_nil => true, :allow_blank => true, :if => "Seek::Config.is_virtualliver"
  validates_uniqueness_of :doi ,:allow_nil => true, :allow_blank => true, :if => "Seek::Config.is_virtualliver"
  validates_uniqueness_of :title , :if => "Seek::Config.is_virtualliver"

  validate :check_uniqueness_of_identifier_within_project, :unless => "Seek::Config.is_virtualliver"
  validate :check_uniqueness_of_title_within_project, :unless => "Seek::Config.is_virtualliver"

  validate :check_identifier_present

  after_update :update_creators_from_publication_authors

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

    def event_ids= events_ids

    end

  end

  def default_policy
    policy = Policy.new(:name => "publication_policy", :sharing_scope => Policy::EVERYONE, :access_type => Policy::VISIBLE)
    #add managers (authors + contributor)
    creators.each do |author|
      policy.permissions << Permissions.create(:contributor => author, :policy => policy, :access_type => Policy::MANAGING)
    end
    #Add contributor
    c = contributor || default_contributor
    policy.permissions << Permission.create(:contributor => c.person, :policy => policy, :access_type => Policy::MANAGING) if c
    policy
  end

  scope :default_order, order("published_date DESC")

  def seek_authors
    publication_authors.select{|publication_author| publication_author.person}
  end

  def non_seek_authors
    publication_authors.find_all_by_person_id nil
  end


  def self.sort publications
    publications.sort_by &:published_date
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

  def extract_pubmed_metadata(reference)
    self.title = reference.title.chop #remove full stop
    self.abstract = reference.abstract
    self.journal = reference.journal
    self.pubmed_id = reference.pubmed
    self.published_date = reference.published_date
    self.citation = reference.citation
  end

  def extract_doi_metadata(doi_record)
    self.title = doi_record.title
    self.published_date = doi_record.date_published
    self.journal = doi_record.journal
    self.doi = doi_record.doi
    self.publication_type = doi_record.publication_type
    self.citation = doi_record.citation
  end

  def related_data_files
    self.backwards_relationships.select {|a| a.subject_type == "DataFile"}.collect { |a| a.subject }
  end

  def related_models
    self.backwards_relationships.select {|a| a.subject_type == "Model"}.collect { |a| a.subject }
  end

  def related_assays
    self.backwards_relationships.select {|a| a.subject_type == "Assay"}.collect { |a| a.subject }
  end

  def related_presentations
    self.backwards_relationships.select {|a| a.subject_type == "Presentation"}.collect { |a| a.subject }
  end

  #includes those related directly, or through an assay
  def all_related_data_files
    via_assay = related_assays.collect do |assay|
      assay.data_file_masters
    end.flatten.uniq.compact
    via_assay | related_data_files
  end

  #includes those related directly, or through an assay
  def all_related_models
    via_assay = related_assays.collect do |assay|
      assay.model_masters
    end.flatten.uniq.compact
    via_assay | related_models
  end

  #indicates whether the publication has data files or models linked to it (either directly or via an assay)
  def has_assets?
    #FIXME: requires a unit test
    !all_related_data_files.empty? || !all_related_models.empty?
  end

  #returns a list of related organisms, related through either the assay or the model
  def related_organisms
    organisms = related_assays.collect{|a| a.organisms}.flatten.uniq.compact
    organisms = organisms | related_models.collect{|m| m.organism}.uniq.compact
    organisms
  end

  def self.subscribers_are_notified_of? action
    action == 'create'
  end

  def endnote
   bio_reference.endnote
  end

  def publication_author_names
    author_names = []
    publication_authors.each do |author|
      seek_author = author.person
      unless seek_author.nil?
        author_names << seek_author.name
      else
        author_names << author.first_name + " " + author.last_name
      end
    end
    author_names
  end

  private

  def bio_reference
    if pubmed_id
      Bio::MEDLINE.new(Bio::PubMed.efetch(pubmed_id).first).reference
    else
      #TODO: Bio::Reference supports a 'url' option. Should this be the URL on seek, or the URL of the 'View Publication' button, or neither?
      Bio::Reference.new({:title => title, :journal => journal, :abstract => abstract,
                          :authors => publication_authors.map {|e| e.person ? [e.person.last_name, e.person.first_name].join(', ') : [e.last_name, e.first_name].join(', ')},
                          :year => published_date.year}.with_indifferent_access)
    end
  end

  def check_identifier_present
    if doi.blank? && pubmed_id.blank?
      self.errors[:base] << "Please specify either a PubMed ID or DOI"
      return false
    end

    if !doi.blank? && !pubmed_id.blank?
      self.errors[:base] << "Can't have both a PubMed ID and a DOI"
      return false
    end

    true

  end

  def check_uniqueness_of_identifier_within_project
    if !doi.blank?
      existing = Publication.find_all_by_doi(doi) - [self]
      if !existing.empty?
        matching_projects = existing.collect(&:projects).flatten.uniq & projects
        if !matching_projects.empty?
          self.errors[:base] << "You cannot register the same DOI within the same project"
          return false
        end
      end
    end
    if !pubmed_id.blank?
      existing = Publication.find_all_by_pubmed_id(pubmed_id) - [self]
      if !existing.empty?
        matching_projects = existing.collect(&:projects).flatten.uniq & projects
        if !matching_projects.empty?
          self.errors[:base] << "You cannot register the same PubMed ID within the same project"
          return false
        end
      end
    end
    true
  end

  def check_uniqueness_of_title_within_project
    existing = Publication.find_all_by_title(title) - [self]
    if !existing.empty?
      matching_projects = existing.collect(&:projects).flatten.uniq & projects
      if !matching_projects.empty?
        self.errors[:base] << "You cannot register the same Title within the same project"
        return false
      end
    end
  end

  #defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    Seek::Config.publications_enabled
  end
end

