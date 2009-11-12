#!/usr/bin/env ruby

# This script searches through a single page on the SUMO wiki in search of data files.

env = "development"

unless ARGV[0].nil? or ARGV[0] == ''
  env = ARGV[0]
end

RAILS_ENV = env

# Load up the Rails app
require File.join(File.dirname(__FILE__), '..', 'config', 'environment')
require 'hpricot'
require 'open-uri'
require 'net/http'
require 'net/https'


class SUMOHarvester
  
  #Valid data file extensions, maybe not needed in this case
  FILE_EXTENSIONS = ["doc", "xls", "pdf", "zip", "csv"]
  
  def login
    return {:http_basic_authentication=>[@username, @password]}
  end
  
  def crawl(user, pass, target)
    @username = user
    @password = pass
    
    @visited_links = []
    
    get_links(target, 0)
  end
  
  #Get links from a page and search them for experiment templates
  def get_links(target, level)
    puts (" " * level) + "Searching page at: " + target + " for links..." 
    links = Array.new

    #Start the search on the Data page
    doc = open(target, login) { |f| Hpricot(f) }
    doc.search("/html/body/div#main/div#content//a").each do |e|
      uri = e.attributes['href']
      if uri.starts_with?("/trac/wiki/LIMS/Experiments/")
        links << complete_url(uri, extract_base_url(target))
      end      
    end
    
    puts (" " * (level+1)) + (links.uniq - @visited_links).size.to_s + " links found"
    
    links.uniq.each do |link|
      unless @visited_links.include?(link)
        @searched_uris = Array.new    
        @data_files = Array.new
        @sops = Array.new
        @experimenters = Array.new
        @section = "none"
        @title = ""
        @valid_template = false
        @visited_links << link
        get_data(link, (level+1))
      end
    end
  end
  
  def get_data(uri, level)    
    puts (" " * level) + "Searching page at: " + uri + " for data..." 
    #Open the page, using the cookie returned from the log in
    doc = open(uri, :http_basic_authentication=>[@username, @password]) { |f| Hpricot(f) }
    #Examine all of the <a> tags with class "attachment" in the content div
    doc.search("/html/body/div#main/div#content//").each do |e|
      case e.name
        when "p"
          if e.attributes['class'] == "path"
            @section = "path"
          end
        when "h1"
          @title += " " + e.inner_html
          @title.strip!
        when "h2", "h3"
          @section = e.inner_html
        when "table"
          if @section == "General Data"
            @valid_template = true
            general_data = {}
            rows = e.search("//tr")
            #Make a hash with the items from the first column as the key
            # and the items from the second column as the value
            rows.each do |row|
              cols = row.search("//td")
              general_data[cols.first.inner_html.strip] = cols.last.inner_html.strip 
            end
            
            general_data.each_key do |k|
              if k.downcase.starts_with?("author")
                @author = general_data[k]
              elsif k.downcase.starts_with?("date")
                @date = general_data[k]              
              end              
            end
            
          end
          
          if @section == "Experimenters"
            #Get the experimenters names from the table (1st column)
            rows = e.search("//tr")
            rows.each do |row|
              unless row == rows.first
                cols = row.search("//td")
                cell = cols[0].inner_html.strip
                if cell =~ /[a-zA-Z]+/
                  @experimenters << cell 
                end
              end
            end
          end
          
          if @section == "Applied SOPs"
            rows = e.search("//tr")
            rows.each do |row|
              #skip first row (titles)
              unless row == rows.first
                cols = row.search("//td")
                #Get the SOP names from the table (1st column)              
                cell = cols[0]
                #Get the URL to the SOP from the table cell
                sop_link = cell.at("a")
                unless sop_link.nil?
                  resource_uri = complete_url(sop_link['href'], extract_base_url(uri))
                  @sops ||= []
                  @sops << resource_uri
                end
              end
            end
          end
        
        #Get the attached data files from the links with class 'attachment'
        when "a"
          if @section == "path" && e.inner_html.starts_with?("WP")
            @WP = e.inner_html.split("WP").last.to_f / 10            
          end
          unless e.attributes['href'].nil?
            resource_uri = e.attributes['href']    
            #sort out relative paths
            resource_uri = complete_url(resource_uri, extract_base_url(uri))
            
            #Don't visit timeline links, anchors, or pages already visited.
            unless (resource_uri.include?("timeline?") || resource_uri.starts_with?("#") || @searched_uris.include?(resource_uri))
              #Remember we've visited this link
              @searched_uris << resource_uri
              #Get file extension
              #extension = resource_uri.split(".").last
              #If valid data file, remember it
              #if FILE_EXTENSIONS.include?(extension)
              if @section == "Attachments"
                @data_files << resource_uri
              else
                @data_files << resource_uri if e.attributes['class'] == "attachment"
              end
                
              #If link wasn't a data file, but contains the word 'data' and is a wiki page, search it.
              #elsif resource_uri.starts_with?(root_uri) && (resource_uri.include?("data") || resource_uri.include?("Data"))        
              #  get_data(resource_uri, (level+1))
              #end          
            end        
          end
      end
    end
    
    
    #Print out what we've found
    if @valid_template
      puts "------------------------------------"
      puts "Title: "
      puts " " + (@title.nil? ? "None" : CGI.unescapeHTML(@title))
      
      puts "Work Package: "
      puts " " + (@WP.nil? ? "None" : "WP" + @WP.to_s)
      
      puts "Author: "
      puts " " + (@author.nil? ? "None" : @author)
      
      puts "Date: "
      puts " " + (@date.nil? ? "None" : @date)
      
      puts "Experimenters: "
      if @experimenters.empty?
        puts " None" 
      else
        @experimenters.uniq.each do |e|
          puts " " + e
        end
      end
      
      puts "Sops:"
      if @sops.empty?
        puts " None" 
      else
        @sops.uniq.each do |s|
          puts " " + s
        end
      end
      
      puts "Data Files:"
      if @data_files.empty?
        puts " None" 
      else
        @data_files.uniq.each do |df|
          puts " " + df
        end
      end  
      puts "------------------------------------"
    else
      puts " "*level + " No valid experiment template found."
      get_links(uri, level)
    end
  end
  
  private
  
  #Turn relative paths into complete urls
  def complete_url(url, base)
    if url.starts_with?("/")
      resource_uri = base + url
    else
      resource_uri = url
    end    
    return resource_uri
  end  
  
  #extract the base url from a url, eg.:
  # http://www.website.com/folder/file.ext
  # becomes: http://www.website.com/
  def extract_base_url(uri)
    root = uri.split("/",4)
    root[0] + "//" + root[2]
  end
  
end

data = SUMOHarvester.new
data.crawl(ARGV[1], ARGV[2], ARGV[3])