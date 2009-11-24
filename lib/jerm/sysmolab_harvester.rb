require 'hpricot'
require 'open-uri'
require 'net/http'
require 'net/https'
module Jerm
  class SysmolabHarvester < WikiHarvester
    
    LOG_IN_PAGE_URL = "http://www.wikispaces.com/site/signin"
    LOG_IN_TARGET_URL = "https://session.wikispaces.com/session/login"

    def update    
      @cookies = {}
      authenticate
      resources = changed_since(last_run)
      resources.each do |resource|
        populate resource
      end
    end
    
    #Method
    def get_page uri
      tries = 5 #number of redirects to follow before we give up
      url = URI.parse(uri)
      x = nil
      request = Net::HTTP::Get.new(url.request_uri)
      request.basic_auth url.user, url.password if url.user
      request.add_field("Cookie", concat_cookies) unless @cookies.empty?
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      http.start {|h| x = h.request(request) }
      add_cookies(x['set-cookie']) unless x['set-cookie'].blank?
      
      while (x.code == "302" && tries > 0) 
        url = URI.parse(x['location'])
        request = Net::HTTP::Get.new(url.request_uri)
        request.basic_auth url.user, url.password if url.user
        request.add_field("Cookie", concat_cookies) unless @cookies.empty?
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = (url.scheme == 'https')
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.start {|h| x = h.request(request) }
        add_cookies(x['set-cookie']) unless x['set-cookie'].blank?
        tries -= 1
      end
      
      return x
    end
    
    def authenticate
      x = ""
      doc = Hpricot(get_page(LOG_IN_PAGE_URL).body)
      form_params = {}
      doc.search("//div.main//input").each do |input|
        form_params[input['name']] = input['value']
      end
      form_params.delete("openid_url")
      form_params["btn primary"] = "Sign In"
      form_params["username"] = @username
      form_params["password"] = @password
      url = URI.parse(LOG_IN_TARGET_URL)
      request = Net::HTTP::Post.new(url.request_uri)
      request.form_data = form_params
      request.add_field("Cookie", concat_cookies) unless @cookies.empty?
      request.basic_auth url.user, url.password if url.user
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = (url.scheme == 'https')
      http.start {|h| x = h.request(request) }
      add_cookies(x['set-cookie']) unless x['set-cookie'].blank?
    end
    
    def changed_since(date)
      @changed_since_date = date #TODO: use this for something
      
      @visited_links = Array.new
      @resources = Array.new
      @searched_uris = Array.new    
      
      get_links("http://sysmo-sumo.mpi-magdeburg.mpg.de/trac/wiki/LIMS/Experiments", 0)
      return @resources.uniq
    end
  
    private
    
    def concat_cookies
      @cookies.values.join(", ")
    end
    
    def add_cookies(cookies)
      cookies.split(".com,").each do |cookie|
        name = cookie.split(";").first.split("=").first.strip
        if (cookie =~ /domain=[^;,]*/) && !(cookie =~ /domain=[^;,]*.com/)
          @cookies[name] = (cookie + ".com").strip
        else          
          @cookies[name] = cookie.strip
        end      
      end
    end
    
  end
end