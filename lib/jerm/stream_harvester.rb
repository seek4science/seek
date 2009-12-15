module Jerm
  class StreamHarvester < WikiHarvester
    
    BASE_URL = "https://www.wsbc.warwick.ac.uk"
    
    def update    
      #Authenticate
      x = ""
      url = URI.parse("https://www.wsbc.warwick.ac.uk/groups/sysmo/auth/?path=/groups/sysmo/")
      request = Net::HTTP::Get.new(url.request_uri)
      request.basic_auth @username, @password
      #tell the site that we can use cookies
      request.add_field("Cookie", "cookies=1; path=/")
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.start {|h| x = h.request(request) }
      @cookie = x['set-cookie'] #get the authenticated session_id cookie
      
      resources = changed_since(last_run)
      resources.each do |resource|
        puts resource.to_s
      end
    end
    
    def changed_since(date)
      @changed_since_date = date #TODO: use this for something
      
      @visited_links = Array.new
      @resources = Array.new
      @searched_uris = Array.new    
      
      @resource_type = "DataFile"
      get_links("https://www.wsbc.warwick.ac.uk/groups/sysmo/wiki/792d0/Data_Downloads.html")
      @resource_type = "Sop"
      get_data("https://www.wsbc.warwick.ac.uk/groups/sysmo/wiki/4cb5d/Standard_Operating_Procedures_(SOPs)_or_Protocols.html")
      return @resources.uniq
    end
  
    private
    
    def get_links(target)
      links = Array.new
      
      doc = open(target, "Cookie" => @cookie) { |f| Hpricot(f) }
      doc.search("//div.wiki_entry//li//a").each do |e|
        if e['class'].blank? && e['id'].blank? && e['style'].blank?
          uri = e['href']
          links << complete_url(uri, BASE_URL)
        end
      end
      
      links.uniq.each do |link|
        unless @visited_links.include?(link)
          @valid_links = Array.new
          @visited_links << link
          get_data(link)
        end
      end
    end
    
    def get_data(uri)    
      #Open the page, using the http authentication
      doc = open(uri, "Cookie" => @cookie) { |f| Hpricot(f) }
      #Get all of the tags
      doc.search("//img.attachment_handle_img").each do |e|
        unless e['longdesc'].nil?
          resource_uri = e['longdesc']    
          #sort out relative paths
          resource_uri = complete_url(resource_uri, BASE_URL)          
          #Don't visit timeline links, anchors, or pages already visited.
          unless (resource_uri.include?("timeline?") || resource_uri.starts_with?("#") || @searched_uris.include?(resource_uri))
            #Remember we've visited this link
            @searched_uris << resource_uri
            @valid_links << resource_uri   
          end
        end
      end
      
      #Create sop resources
      unless @valid_links.empty?
        @valid_links.each do |s|
          res = StreamResource.new
          res.uri = s
          res.type = @resource_type
          res.project = "STREAM"
          res.username = @username
          res.password = @password
          @resources << res
        end
      end
      
    end
  end
end