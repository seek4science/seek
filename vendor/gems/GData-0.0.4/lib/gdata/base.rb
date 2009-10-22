require 'net/http'
require 'net/https'
require 'uri'
require 'rubygems'
require 'hpricot'

#
# Make it east to use some of the convenience methods using https
#
module Net
  class HTTPS < HTTP
    def initialize(address, port = nil)
      super(address, port)
      self.use_ssl = true
    end
  end
end

module GData
  GOOGLE_LOGIN_URL = URI.parse('https://www.google.com/accounts/ClientLogin')

  class Base
    
    attr_reader :service, :source, :url
    
    def initialize(service, source, url)
      @service = service
      @source = source
      @url = url
    end
    
    def authenticate(email, password)
      $VERBOSE = nil
      response = Net::HTTPS.post_form(GOOGLE_LOGIN_URL,
        {'Email'   => email,
         'Passwd'  => password,
         'source'  => source,
         'service' => service })

      response.error! unless response.kind_of? Net::HTTPSuccess

      @headers = {
       'Authorization' => "GoogleLogin auth=#{response.body.split(/=/).last}",
       'Content-Type'  => 'application/atom+xml'
      }
    end

    def request(path)
      response, data = get(path)
      data
    end

    def get(path)
      response, data = http.get(path, @headers)
    end

    def post(path, entry)
      http.post(path, entry, @headers)
    end

    def put(path, entry)
      h = @headers
      h['X-HTTP-Method-Override'] = 'PUT' # just to be nice, add the method override
  
      http.put(path, entry, h)
    end

    def http
      conn = Net::HTTP.new(url, 80)
      #conn.set_debug_output $stderr
      conn
    end

  end
end
