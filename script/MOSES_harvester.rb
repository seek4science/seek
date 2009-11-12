#!/usr/bin/env ruby

# This script crawls through MOSES' wiki in search of data files.

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


class MOSESHarvester
  
  #Valid data file extensions
  FILE_EXTENSIONS = ["doc", "xls", "pdf", "zip"]
  
  def login
    if @cookie.nil?
      #MOSES' MediaWiki api code
      url = URI.parse("http://moses.sys-bio.net/api.php")
    
      #Log in
      #puts "Logging in..."
      resp, data = Net::HTTP.post_form(url, {:action => "login", :lgname => @username, :lgpassword => @password})  
      
      #Save the cookie
      @cookie = resp['set-cookie']
    end
    return {"Cookie" => @cookie}
  end
  
  def crawl(user, pass, target)
    @target = target
    @username = user
    @password = pass
    
    @searched_uris = Array.new
    @results = Array.new

    #Start the search on the Data page, then go to the SOPs page
    @file_type = "Data File"
    #get_data("http://moses.sys-bio.net/index.php/Data", 0)
    get_data("http://moses.sys-bio.net/index.php/W%C3%B6lfl_Data", 0)
    
    @results = Array.new
    
    #@file_type = "SOP"
    #get_data("http://moses.sys-bio.net/index.php/Standards", 0)
  end
  
  def get_data(uri, level)    
    #puts (" " * level) + "Searching page at: " + uri + " for data..." 
    #Open the page, using the cookie returned from the log in
    doc = open(uri, login) { |f| Hpricot(f) }
    #Examine all of the <a> tags within the content div
    doc.search("/html/body/div#globalWrapper/div#column-content/div#content//").each do |e|
      case e.name
        when "a"          
          if e['href'].nil?
            if e.attributes.size == 1 && !e['name'].nil?
              @section = e['name']
            end
          else       
            #sort out relative paths
            root_uri = extract_base_url(uri)
            resource_uri = complete_url(e['href'], root_uri)
            
            #Don't visit 'edit' links, anchors, or pages already visited.
            unless (resource_uri.starts_with?("#") || resource_uri.include?("action=edit") || resource_uri.include?("Special:Search") || @searched_uris.include?(resource_uri))
              #Remember we've visited this link
              @searched_uris << resource_uri
              #puts (" " * level) + " Checking uri: " + resource_uri
              #Get file extension
              extension = resource_uri.split(".").last
              #If valid data file, remember it
              if FILE_EXTENSIONS.include?(extension)
                @results << "Found #{@file_type} of format #{extension} @ " + resource_uri
                puts "Creating data file..."
                create_remote_resource(DataFile, e.inner_html, resource_uri, User.first)
              #If link wasn't a data file, but contains the word 'data' and is a wiki page, search it.
              elsif resource_uri.starts_with?(root_uri) && (resource_uri.downcase.include?("data") || resource_uri.downcase.include?("standard"))        
                get_data(resource_uri, (level+1))
              end          
            end
            
          end
        #//when "a"
        else          
      end #case
    end
    
    #puts (" " * level) + "DONE"
    
    #Print out what we've found
    if level == 0 && !@results.empty?
      puts "#{@file_type} Results:"
      @results.each do |result|
        puts result
      end
    end    
  end
  
  private  
  
  #This does now work!
  #Will need to be changed
  def create_remote_resource(type, title, url, user)
    #type = resource type eg. DataFile, Sop, Model
    
    params = {}
    
    resource_symbol = type.name.underscore.to_sym
    
    params[resource_symbol] = {}
    
    params[resource_symbol][:title] = title
    params[resource_symbol][:description] = "Automatically harvested resource"
    
    # prepare some extra metadata to store in Data files instance
    params[resource_symbol][:contributor_type] = user.class.name
    params[resource_symbol][:contributor_id] = user.id

    # store source and quality of the new Data file (this will be kept in the corresponding asset object eventually)
    # TODO set these values to something more meaningful, if required for Data files
    params[resource_symbol][:source_type] = "upload"
    params[resource_symbol][:source_id] = nil
    params[resource_symbol][:quality] = nil
    
    res = type.new(params[resource_symbol])
    res.content_blob = ContentBlob.new(:url => url)

    success = true

    begin
      type.transaction do
        res.original_filename, res.content_type = res.content_blob.cache_remote_content #this bit is important
        res.save!
        
        #Policy stuff:
        
        #THIS IS ALL REALLY BAD CODE:
        params[:sharing] = {}
        params[:sharing][:permissions] = {}
        params[:sharing][:sharing_scope] = 0
        params[:sharing]["include_custom_sharing_0"] = 0
        params[:sharing]["access_type_0"] = 0
   
        policy_err_msg = Policy.create_or_update_policy(res, user, params)
    
        # update attributions
        Relationship.create_or_update_attributions(res, params[:attributions])  
      end   
    rescue Exception => ex
      puts "An error occured whilst trying to create remote resource"
      puts ex.message
      puts ex.backtrace.join("\n")
      success = false
    end  
    
    return success ? res : nil
  end
  
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
  # becomes: http://www.website.com
  def extract_base_url(uri)
    root = uri.split("/",4)
    root[0] + "//" + root[2]
  end
  
end

data = MOSESHarvester.new
data.crawl(ARGV[1], ARGV[2], ARGV[3])