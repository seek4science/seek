require 'acts_as_resource'
require 'grouped_pagination'
require 'acts_as_uniquely_identifiable'

class Publication < ActiveRecord::Base

  acts_as_resource
  
  grouped_pagination
  
  before_save :update_first_letter
  
  validates_presence_of :title
  validate :check_identifier_present
  #validates_uniqueness_of :pubmed_id, :message => "publication has already been registered with that ID."
  #validates_uniqueness_of :doi, :message => "publication has already been registered with that ID."
  validates_uniqueness_of :title, :message => "not unique - A publication has already been registered with that title."
  
  has_many :non_seek_authors, :class_name => 'PublicationAuthor', :dependent => :destroy
  
  acts_as_solr(:fields=>[:title,:abstract,:journal]) if SOLR_ENABLED  
  
  acts_as_uniquely_identifiable  
  
  #belongs_to :contributor, :polymorphic => true
  
  def update_first_letter
    self.first_letter=strip_first_letter(title.gsub(/[\[\]]/,""))
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
  end
  
  private
  
  def check_identifier_present
    if self.doi.nil? && self.pubmed_id.nil?
      self.errors.add_to_base("Please specify either a PubMed ID or DOI")
      return false
    else
      return true
    end
  end
end