require 'acts_as_asset'
require 'grouped_pagination'
require 'acts_as_uniquely_identifiable'
require 'title_trimmer'

class Publication < ActiveRecord::Base
  
  title_trimmer

  acts_as_asset
  
  grouped_pagination
  
  validates_presence_of :title
  validates_presence_of :project
  validate :check_identifier_present
  #validates_uniqueness_of :pubmed_id, :message => "publication has already been registered with that ID."
  #validates_uniqueness_of :doi, :message => "publication has already been registered with that ID."
  validates_uniqueness_of :title, :message => "not unique - A publication has already been registered with that title."
  
  has_many :non_seek_authors, :class_name => 'PublicationAuthor', :dependent => :destroy
  
  has_many :backwards_relationships, 
    :class_name => 'Relationship',
    :as => :object,
    :dependent => :destroy
   
  alias :seek_authors :creators
  
  acts_as_solr(:fields=>[:title,:abstract,:journal]) if SOLR_ENABLED  
  
  acts_as_uniquely_identifiable  
    

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
  
  private
  
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