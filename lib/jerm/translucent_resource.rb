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
      begin
        
        @author_seek_id = @node.find_first("submitter").content unless @node.find_first("submitter").nil?
        if @type=="Model"
          @uri = @node.find_first("model").content unless @node.find_first("model").nil?
        else
          @uri = @node.find_first("file").content unless @node.find_first("file").nil?
        end
        
        @uri=URI.decode(@uri) unless @uri.nil?
        
        @timestamp = DateTime.parse(@node.find_first("submission_date").content) unless @node.find_first("submission_date").nil?
        #@title = @node.find_first("name").inner_xml unless @node.find_first("name").nil?
        @title = @node.find_first("title").content unless @node.find_first("title").nil?
        
        desc_node=@node.find_first("description")
        if !desc_node.nil?
          @description=desc_node.content          
        end
        
      rescue Exception=>e
        puts "Error processing the XML for this item"
        puts @node
        puts e.message
      end
    end
    
    def project_name
      "Translucent"
    end
    
  end
end
