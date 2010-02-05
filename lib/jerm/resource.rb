# To change this template, choose Tools | Templates
# and open the template in the editor.

module Jerm
  class Resource

    attr_accessor :project, :uri, :author_first_name, :author_last_name,:author_seek_id,:timestamp,:type, :title

    def to_s
      "Owner: #{author_name} (#{author_seek_id}), Project: #{project}, URI: #{uri}, Type: #{type}, Timestamp: #{timestamp}"
    end

    def author_name
      "#{author_first_name} #{author_last_name}"
    end
        
  end
end
