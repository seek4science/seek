class PubmedAuthor
  attr_accessor :first_name, :last_name, :initials
  
  def initialize(first, last, init)
    self.first_name = first
    self.last_name = last
    self.initials = init    
  end
  
  def name
    return self.first_name + " " + self.last_name
  end
end