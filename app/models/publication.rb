require 'acts_as_asset'
require 'grouped_pagination'
require 'title_trimmer'
require 'libxml'

class Publication < ActiveRecord::Base
  
  title_trimmer

  acts_as_asset

  def default_policy
    policy = Policy.new(:name => "publication_policy", :sharing_scope => Policy::EVERYONE, :access_type => Policy::VISIBLE)
    #add managers (authors + contributor)
    creators.each do |author|
      policy.permissions.build(:contributor => author, :policy => policy, :access_type => Policy::MANAGING)
    end
    #Add contributor
    c = contributor || default_contributor
    policy.permissions.build(:contributor => c.person, :policy => policy, :access_type => Policy::MANAGING) if c
    policy
  end

  validate :check_identifier_present
  #validates_uniqueness_of :pubmed_id, :message => "publication has already been registered with that ID."
  #validates_uniqueness_of :doi, :message => "publication has already been registered with that ID."
  validates_uniqueness_of :title, :message => "not unique - A publication has already been registered with that title."
  
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
  
  searchable do
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

  def endnote
   bio_reference.endnote
  end
  
  private

  def bio_reference
    if pubmed_id
      Bio::MEDLINE.new(Bio::PubMed.efetch(pubmed_id).first).reference
    else
      #TODO: Bio::Reference supports a 'url' option. Should this be the URL on seek, or the URL of the 'View Publication' button, or neither?
      Bio::Reference.new({:title => title, :journal => journal, :abstract => abstract,
                          :authors => (seek_authors + non_seek_authors).map {|e| [e.last_name, e.first_name].join(', ')},
                          :year => published_date.year}.with_indifferent_access)
    end
  end

  def check_identifier_present
    if self.doi.nil? && self.pubmed_id.nil?
      self.errors.add_to_base("Please specify either a PubMed ID or DOI")
      false
    else
      true
    end
  end

  #defines that this is a user_creatable object type, and appears in the "New Object" gadget
  def self.user_creatable?
    true
  end
end

