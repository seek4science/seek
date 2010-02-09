require 'hpricot'
require 'open-uri'
require 'net/http'
require 'net/https'
module Jerm
  class SysmolabHarvester < WikiHarvester
    
    def initialize root_uri,username,password
      super root_uri,username,password      
    end

    def update    
      responses = [] 
      resources = changed_since(last_run)
      resources.each do |resource|
        responses << populate(resource)
      end
      return responses
    end
    
    def changed_since(date)
      @changed_since_date = date
      
      @visited_links = []
      @resources = []
      @searched_uris = []
      
      data_file_urls = []
      
      #Get DataFile starting links from the menu
      doc = open(@base_uri + "/space.menu", :http_basic_authentication=>[@username, @password]) { |f| Hpricot(f) }
      doc.search("/ul//a").each do |e|
        uri = e.attributes['href']
        uri = @base_uri + uri
        data_file_urls << uri
      end
      
      @file_type = "DataFile"
      
      data_file_urls.each do |df|
        @level = 1 #Data files exists on the 3rd level
        get_links(df)
      end
      
      @file_type = "Sop"
      get_data(@base_uri + "/SOPs")
      
      return @resources.uniq
    end
  
        
    #Get links from a page and search them for data, or more links if we've not yet reached the "leaf" level of the hierarchy
    def get_links(target)
      links = []
  
      doc = open(target, :http_basic_authentication=>[@username, @password]) { |f| Hpricot(f) }
      doc.search("//a").each do |e|
        uri = e.attributes['href']
        unless uri.start_with?("/file/")
          uri = @base_uri + uri unless uri.start_with?("http")
          links << uri
        end
      end
      
      links.each do |link|
        unless @visited_links.include?(link)
          @data_files = []
          @hierarchy = []
          @title = ""
          @valid_template = false
          @visited_links << link
          #If we're not yet at the bottom level, keep traversing the hierarchy
          if @level < 3
            @level += 1
            get_links(link)
          #otherwise, start getting data
          else
            get_data(link)
          end          
        end
      end
    end
    
    def get_data(uri)
      #Open the page, using the http authentication
      doc = open(uri, :http_basic_authentication=>[@username, @password]) { |f| Hpricot(f) }
      doc.search("//").each do |e|
        case e.name
          when "span"
            if @title.blank?
              if e.inner_html.start_with?("<span")
                @title = e.search("/span").inner_html
                @title = @title[0...(@title =~ (/[^-a-zA-Z ]/))].strip if @title =~ (/[^-a-zA-Z ]/)
              else
                @title = e.inner_html.strip
              end
            end
          when "h2"
            #Get an array containing the page's hierarchy, for example: ["Metabolites", "Steady State", "Dilution Rate"]
            @hierarchy = e.search("/span").inner_html.split(/<[^>]*>/).collect {|a| a.sub("-", "").strip}.select {|i| !i.blank?}
          #Find links to data files
          when "a"
            if e['href'].start_with?("/file/")
              #sort out relative paths
              resource_uri = "https://sysmolab.wikispaces.com/space/dav/files/" + (e.attributes['href'].split("/").last)    
              unless @searched_uris.include?(resource_uri)
                #Remember we've visited this link
                @searched_uris << resource_uri
                @data_files << resource_uri   
                @valid_template = true
              end
            end        
        end
      end
      
      #If we're on a valid experiment page..
      if @valid_template
        #Create data file resources
        unless @data_files.empty?
          @data_files.uniq.each do |d|
            if get_last_modified_date(d) > @changed_since_date
              #Ridiculous title retrieval:
              if @file_type == "DataFile"
                text = doc.inner_html.gsub(/<[^a](.*)>/,"").split("\n").delete_if{|a| a.blank?}
                index = text.index(text.select{|e| e.include?(d.split("/").last)}.first)
                @title = index.nil? ? d.split("/").last : text[index-1].strip
              else
                @title =  d.split("/").last
              end
              #Make resource
              res = construct_resource(d)
              @resources << res
            end
          end
        end 
      end
    end    
    
    def construct_resource uri
      res = SysmolabResource.new(@username, @password)
      res.uri = uri
      res.type = @file_type
      res.project = "SysMO-LAB"
      return res
    end
    
    def get_last_modified_date(uri)
      uri = URI.parse(uri)
      response = nil
      Net::HTTP.start(uri.host) {|http|
        req = Net::HTTP::Head.new(uri.request_uri)
        req.basic_auth @username, @password
        response = http.request(req)
      }
      return response['last-modified'].to_datetime
    end
  end

  def project_name
    "SysMO-Lab"
  end  
end
