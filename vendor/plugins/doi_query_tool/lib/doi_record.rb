class DoiRecord
  attr_accessor :authors, :title, :abstract, :journal, :doi, :xml, :date_published,:publication_type  

  PUBLICATION_TYPES = {:journal=>1,:conference=>2,:book_chapter=>3}


  def initialize(attributes={})
    self.title = attributes[:title]
    self.abstract = attributes[:abstract]
    self.journal = attributes[:journal]
    self.doi = attributes[:doi]
    self.xml = attributes[:doc]
    self.date_published = attributes[:pub_date]
    self.authors = attributes[:authors] || []    
    self.publication_type = attributes[:type] || PUBLICATION_TYPES[:journal]
  end

  
  def lookup_url
    DOI_BASE_URL + self.doi
  end
end