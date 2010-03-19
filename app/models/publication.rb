class Publication < ActiveRecord::Base

  acts_as_resource
  
  grouped_pagination
  
  before_save :update_first_letter
  
  #has_many :publication_authors, :dependent => :destroy
  #has_many :authors, :through => :publication_authors, :class_name => 'Person'
  
  validates_presence_of :title
  
  belongs_to :contributor, :polymorphic => true
  
  def update_first_letter
    self.first_letter=strip_first_letter(title)
  end
  
  def extract_metadata(pubmed_record)
    self.title = pubmed_record.title
    self.abstract = pubmed_record.abstract
    self.published_date = pubmed_record.date_published
    self.journal = pubmed_record.journal
    self.pubmed_id = pubmed_record.pmid
  end  
end