class PubmedRecord
  attr_accessor :authors, :title, :abstract, :journal, :pmid, :date_published, :error
    
  PUBMED_BASE_URL = "http://www.ncbi.nlm.nih.gov/pubmed/"
  
  def initialize(attributes={})
    self.title = attributes[:title]
    self.abstract = attributes[:abstract]
    self.journal = attributes[:journal]
    self.pmid = attributes[:pmid]
    self.date_published = attributes[:pubmed_pub_date]
    self.authors = attributes[:authors] || []
    self.error = attributes[:error] || nil
  end
  
  def pubmed_url
    return PUBMED_BASE_URL + self.pmid
  end
end