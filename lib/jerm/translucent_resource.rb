# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'jerm/resource'

module Jerm
  class TranslucentResource < Resource
    def initialize item      
      @type=item[:type]
      @node=item[:node]
      @project=project_name
      @description=""
    end

    def populate      
      @author_seek_id = @node.find_first("submitter").inner_xml unless @node.find_first("submitter").nil?
      if @type=="Model"
        @uri = @node.find_first("model").inner_xml unless @node.find_first("model").nil?
      else
        @uri = @node.find_first("files").inner_xml unless @node.find_first("files").nil?
      end
      
      @timestamp = DateTime.parse(@node.find_first("submission_date").inner_xml) unless @node.find_first("submission_date").nil?
      @title = @node.find_first("name").inner_xml unless @node.find_first("name").nil?
      
      @description += "Purpose: #{@node.find_first("purpose").inner_xml}\n" unless (@node.find_first("purpose").nil? || @node.find_first("purpose").blank?)
      @description += @node.find_first("descriptions").inner_xml unless @node.find_first("descriptions").nil?
      @description += @node.find_first("description").inner_xml unless @node.find_first("description").nil?      
    end

    def project_name
      "Translucent"
    end
    
  end
end
