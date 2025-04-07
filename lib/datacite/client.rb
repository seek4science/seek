require 'rest-client'

module Datacite
  class Client
    ENDPOINT = 'https://mds.datacite.org'.freeze
    TEST_ENDPOINT = 'https://mds.test.datacite.org'.freeze

    def initialize(user_name, password, endpoint = nil)
      endpoint ||= ENDPOINT
      @endpoint = RestClient::Resource.new(endpoint, user: user_name, password: password)
    end

    def resolve(doi)
      @endpoint["doi/#{doi}"].get
    end

    def mint(doi, url)
      @endpoint['doi'].post("doi=#{doi}\nurl=#{url}", content_type: 'text/plain;charset=UTF-8')
    end

    def upload_metadata(metadata)
      @endpoint['metadata'].post(metadata, content_type: 'application/xml;charset=UTF-8')
    end

    def metadata(doi)
      @endpoint["metadata/#{doi}"].get
    end
  end
end
