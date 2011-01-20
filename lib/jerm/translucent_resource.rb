# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'jerm/resource'

module Jerm
  class TranslucentResource < Resource
    
    def initialize item      
      @type=item[:type]
      @node=item[:node]
      @table_name=item[:table_name]
      @project=project_name
      @description=""
      @filename=nil
    end
    
    def populate      
      begin
        @translucent_id = @node.find_first("id").content unless @node.find_first("id").nil?
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
        authorization_tag = @node.find_first("authorization").content unless @node.find_first("authorization").nil?
        if authorization_tag.nil? || authorization_tag=="Translucent"
          @authorization=AUTH_TYPES[:project]
        elsif authorization_tag == "SysMO"
          @authorization=AUTH_TYPES[:sysmo]
        else
          @authorization=AUTH_TYPES[:default]
        end
        desc_node=@node.find_first("description")
        if !desc_node.nil?
          @description=desc_node.content          
        end
        
        @filename="translucent_#{@table_name}_#{@translucent_id}"
        
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
