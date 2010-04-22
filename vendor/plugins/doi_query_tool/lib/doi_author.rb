class DoiAuthor
  attr_accessor :first_name, :last_name
  
  def initialize(first, last)
    self.first_name = first
    self.last_name = last
  end
  
  def name
    return self.first_name + " " + self.last_name
  end
end