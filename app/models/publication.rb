require 'acts_as_resource'
require 'grouped_pagination'

class Publication < ActiveRecord::Base

  acts_as_resource
  
  grouped_pagination
  
  before_save :update_first_letter
  
  validates_presence_of :title
  validates_presence_of :pubmed_id
  validates_uniqueness_of :pubmed_id, :message => "publication has already been registered with that ID."
  
  has_many :non_seek_authors, :class_name => 'PublicationAuthor', :dependent => :destroy
  
  #belongs_to :contributor, :polymorphic => true
  
  def update_first_letter
    self.first_letter=strip_first_letter(title.gsub(/[\[\]]/,""))
  end
  
  def extract_metadata(pubmed_record)
    self.title = pubmed_record.title
    self.abstract = pubmed_record.abstract
    self.published_date = pubmed_record.date_published
    self.journal = pubmed_record.journal
    self.pubmed_id = pubmed_record.pmid
  end 
end