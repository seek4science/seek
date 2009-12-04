require 'hpricot'
require 'open-uri'
require 'net/http'
require 'net/https'
module Jerm
  class SysmolabHarvester < WikiHarvester
    
    BASE_URL = "https://sysmolab.wikispaces.com/space/dav/pages_html"
    
    #Sop url
    SOP_URL = "https://sysmolab.wikispaces.com/space/dav/pages_html/SOPs"
    
    #List of data file urls
    DATA_FILE_URLS = ["https://sysmolab.wikispaces.com/space/dav/pages_html/Lactococcus+lactis",
                      "https://sysmolab.wikispaces.com/space/dav/pages_html/Enterococcus+faecalis",
                      "https://sysmolab.wikispaces.com/space/dav/pages_html/Streptococcus+pyogenes"]
                      
    
    def update    
      resources = changed_since(last_run)
      resources.each do |resource|
        populate resource
      end
    end
    
    def changed_since(date)
      @changed_since_date = date #TODO: use this for something
      
      @visited_links = []
      @resources = []
      @searched_uris = []         
      
      @file_type = "DataFile"
      DATA_FILE_URLS.each do |df|
        @level = 1 #Data files exists on the 3rd level
        get_links(df)
      end
      
      @file_type = "Sop"
      get_data(SOP_URL)
      
      return @resources.uniq
    end
  
        
    #Get links from a page and search them for data, or more links if we've not yet reached the "leaf" level of the hierarchy
    def get_links(target)
      links = []
  
      doc = open(target, :http_basic_authentication=>[@username, @password]) { |f| Hpricot(f) }
      doc.search("//a").each do |e|
        uri = e.attributes['href']
        uri = BASE_URL + uri unless uri.starts_with?("http")
        links << uri
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
              if e.inner_html.starts_with?("<span")
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
            if e['href'].starts_with?("/file/")
              #sort out relative paths
              resource_uri = "https://sysmolab.wikispaces.com" + e.attributes['href']    
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
            res = construct_resource(d)
            @resources << res
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
  end

  def project_name
    "SysMO-Lab"
  end
end