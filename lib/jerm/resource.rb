# To change this template, choose Tools | Templates
# and open the template in the editor.

class Resource

  attr_accessor :project, :uri, :author_first_name, :author_last_name,:timestamp,:type  

  def to_s
    "Project: #{project}, URI:#{uri}, Type:#{type}"
  end
end
