# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'jerm/harvester'
require 'jerm/translucent_resource'

module Jerm
  
  class TranslucentHarvester < Harvester
    
    def initialize root_uri,username,key
      super root_uri,username,key
      configpath=File.join(File.dirname(__FILE__),"config/#{project_name.downcase}.yml")
      @config=YAML::load_file(configpath)      
      @tables_and_types=@config['tables_and_types']
    end

    def changed_since time
      result = []
      table_names.each do |table_name|
        xml=do_get(table_name)        
        type=@tables_and_types[table_name]['type']
        begin                    
          parser = LibXML::XML::Parser.string(xml,:encoding => LibXML::XML::Encoding::UTF_8)
          document = parser.parse
          document.find("item").each do |node|
            result << {:node=>node,:type=>type,:table_name=>table_name}
            puts "Item found in table_name: #{table_name}"
          end
        rescue LibXML::XML::Error=>e
          puts "Error with XML from #{table_name}"
          puts e.message          
        end

      end
      result
    end

    def construct_resource item
      TranslucentResource.new(item)
    end

    def do_get table_name
      key=@password
      uri=URI.parse(@base_uri)      
      http=Net::HTTP.new(uri.host,uri.port)

      http.use_ssl=true if uri.scheme=="https"
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      req=Net::HTTP::Get.new(uri.path+"?key=#{key}&xget=#{table_name}")

      http.request(req).body
    end    
    
    def project_name
      "Translucent"
    end

    def table_names
      @tables_and_types.keys
    end
    
  end
end
