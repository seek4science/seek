module Jerm
  class MosesHarvester < MediaWikiHarvester
   
    #Valid data file extensions to be saved as data files
    FILE_EXTENSIONS = ["xls"]
    
    #URI to the API (for logging in)
    API_URI = "http://moses.sys-bio.net/api.php"
    
    #URI to the page to start crawling from
    BASE_DATA_URI = "http://moses.sys-bio.net/index.php/Data"
    
    def initialize(user, pass)
      super
      @api_uri = API_URI
    end
    
    def changed_since(date)
      @changed_since_date = date
      
      @searched_uris = Array.new
      @results = Array.new
  
      #Start the search on the Data page
      @file_type = "DataFile"
      get_data(BASE_DATA_URI, 0)
      return @results
    end
  
    def construct_resource(item)
      r = MosesResource.new
      r.uri = item
      r.type = @file_type
      r.project = "MOSES"
      return r
    end
    
    def populate(resource)
      puts resource.uri + " - valid: " + resource.populate.to_s
    end
  
    private
    
    def get_data(uri, level)    
      #Open the page, using the cookie returned from the log in
      doc = open(uri, "Cookie" => @cookie) { |f| Hpricot(f) }
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
                #Get file extension
                extension = resource_uri.split(".").last
                #If valid data file, remember it
                if FILE_EXTENSIONS.include?(extension)
                  @results << resource_uri
                #If link wasn't a data file, but contains the word 'data' and is a wiki page, search it.
                elsif resource_uri.starts_with?(root_uri) && (resource_uri.downcase.include?("data") || resource_uri.downcase.include?("standard"))        
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
end
