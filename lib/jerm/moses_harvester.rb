module Jerm
  class MosesHarvester < MediaWikiHarvester
   
    #URI to the data and SOP pages to start crawling from
    BASE_DATA_FILE_URI = "http://moses.sys-bio.net/index.php/Data"
    BASE_SOP_URI = "http://moses.sys-bio.net/index.php/Standards"
    
    #Valid file extensions to retrieve
    DATA_FILE_EXTENSIONS = ['xls','xlsx']
    SOP_EXTENSIONS = ['doc','docx','pdf']
    
    #URL to the API (for logging in)
    def api_url
      "http://moses.sys-bio.net/api.php"
    end
    
    def changed_since(date)
      @changed_since_date = date #TODO: this needs to do something eventually
      
      @searched_uris = Array.new
      @results = Array.new
  
      #Start the search on the Data page
      @file_type = "DataFile"
      get_data(BASE_DATA_FILE_URI, 0)
      
      #Then get the sops
      @file_type = "Sop"
      get_data(BASE_SOP_URI, 0)
      
      return @results
    end

    private
    
    def get_data(uri, level)    
      #Open the page, using the cookie returned from the login
      doc = open(uri, "Cookie" => @cookie) { |f| Hpricot(f) }
      #Examine all the tags within the content div
      doc.search("/html/body/div#globalWrapper/div#column-content/div#content//").each do |e|
        case e.name
          when "a" #For <a> tags..
            if e['href'].nil? #If it's an anchor, remember what section we're in
              if e.attributes.size == 1 && !e['name'].nil?
                @section = e['name']
              end
            else       
              #Turn relative paths into complete urls
              root_uri = extract_base_url(uri)
              resource_uri = complete_url(e['href'], root_uri)
              
              #Don't visit 'edit' links, anchors, or pages already visited.
              unless (resource_uri.start_with?("#") || resource_uri.include?("action=edit") || resource_uri.include?("Special:Search") || @searched_uris.include?(resource_uri))
                #Remember we've visited this link
                @searched_uris << resource_uri
                #Get file extension
                extension = resource_uri.split(".").last
                #If valid, set up a Resource object for the uri
                if (@file_type == "DataFile" && DATA_FILE_EXTENSIONS.include?(extension)) ||
                   (@file_type == "Sop" && SOP_EXTENSIONS.include?(extension))
                  if @file_type == "DataFile"
                    type = MosesResource
                  else #Sops
                    type = Resource
                  end
                  r = type.new
                  r.uri = resource_uri
                  r.type = @file_type
                  r.project = "MOSES"
                  @results << r
                #If link wasn't a data file, but contains the word 'data' and is a wiki page, search it.
                elsif resource_uri.start_with?(root_uri) && (resource_uri.downcase.include?("data") || resource_uri.downcase.include?("standard"))        
                  get_data(resource_uri, (level+1))
                end          
              end              
            end
          #//when "a"
          else          
        end 
        #//case
      end
    end
  end

  def project_name
    "MOSES"
  end
end
