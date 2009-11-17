module Jerm
  class MediaWikiHarvester < WikiHarvester
      
    def update
      if @cookie.nil?
        #MediaWiki API url, defined in subclass for each MediaWiki
        url = URI.parse(api_url)
      
        #Log in
        resp, data = Net::HTTP.post_form(url, {:action => "login", :lgname => @username, :lgpassword => @password})  
        
        #Save the cookie
        @cookie = resp['set-cookie']
      end
      
      items = changed_since(last_run)
      items.each do |resource|
        populate resource
      end
    end

    
  end
end