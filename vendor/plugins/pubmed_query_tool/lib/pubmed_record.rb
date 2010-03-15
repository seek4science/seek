class PubmedRecord
  attr_accessor :authors, :title, :abstract
  
  def initialize(attributes={})
    self.title = attributes[:title]
    self.abstract = attributes[:abstract]
    self.authors = attributes[:authors] || []    
  end
end