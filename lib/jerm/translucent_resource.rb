# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'jerm/resource'

module Jerm
  class TranslucentResource < Resource
    def initialize item      
      @type=item[:type]
      @node=item[:node]
      @project=project_name
    end

    def populate
      @author_seek_id = @node.find_first("submitter").inner_xml unless @node.find_first("submitter").nil?
      @uri = @node.find_first("files").inner_xml unless @node.find_first("files").nil?
      @timestamp = DateTime.parse(@node.find_first("submission_date").inner_xml) unless @node.find_first("submission_date").nil?
    end

    def project_name
      "Translucent"
    end
  end
end
