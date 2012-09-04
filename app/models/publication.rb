require 'acts_as_asset'
require 'grouped_pagination'
require 'title_trimmer'
require 'libxml'

class Publication < ActiveRecord::Base
  
  title_trimmer

  acts_as_asset

  validate :check_identifier_present
  validate :check_uniqueness_of_identifier_within_project
  validate :check_uniqueness_of_title_within_project
  
  has_many :non_seek_authors, :class_name => 'PublicationAuthor', :dependent => :destroy
  
  has_many :backwards_relationships, 
    :class_name => 'Relationship',
    :as => :object,
    :dependent => :destroy

  
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

  alias :seek_authors :creators

  def unique_for_project? doi_or_pubmed
    true
  end
  
  searchable(:ignore_attribute_changes_of=>[:updated_at,:last_used_at]) do
    text :title,:abstract,:journal,:searchable_tags, :pubmed_id, :doi
  end if Seek::Config.solr_enabled

  #TODO: refactor to something like 'sorted_by :start_date', which should create the default scope and the sort method. Maybe rename the sort method.
  default_scope :order => "#{self.table_name}.published_date DESC"
  def self.sort publications
    publications.sort_by &:published_date
  end

  def contributor_credited?
    false
  end

  def extract_pubmed_metadata(pubmed_record)
    self.title = pubmed_record.title.chop #remove full stop
    self.abstract = pubmed_record.abstract
    self.published_date = pubmed_record.date_published
    self.journal = pubmed_record.journal
    self.pubmed_id = pubmed_record.pmid
  end
  
  def extract_doi_metadata(doi_record)
    self.title = doi_record.title
    self.published_date = doi_record.date_published
    self.journal = doi_record.journal
    self.doi = doi_record.doi
    self.publication_type = doi_record.publication_type
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
  
  def self.subscribers_are_notified_of? action
    action == 'create'
  end
  
  private
  
  def check_identifier_present
    if doi.blank? && pubmed_id.blank?
      self.errors.add_to_base("Please specify either a PubMed ID or DOI")
      return false
    end

    if !doi.blank? && !pubmed_id.blank?
      self.errors.add_to_base("Can't have both a PubMed ID and a DOI")
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
          self.errors.add_to_base("You cannot register the same DOI within the same project")
          return false
        end
      end
    end
    if !pubmed_id.blank?
      existing = Publication.find_all_by_pubmed_id(pubmed_id) - [self]
      if !existing.empty?
        matching_projects = existing.collect(&:projects).flatten.uniq & projects
        if !matching_projects.empty?
          self.errors.add_to_base("You cannot register the same PubMed ID within the same project")
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
        self.errors.add_to_base("You cannot register the same Title within the same project")
        return false
      end
    end
  end

  #defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end
end

