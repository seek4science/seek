# To change this template, choose Tools | Templates
# and open the template in the editor.

module Jerm
  class Resource

    attr_accessor :project, :uri, :author_first_name, :author_last_name,:author_seek_id,:timestamp,:type    

    def to_s
      "Owner: #{author_first_name} #{author_last_name} (#{author_seek_id}), Project: #{project}, URI: #{uri}, Type: #{type}, Timestamp: #{timestamp}"
    end
        
  end
end
