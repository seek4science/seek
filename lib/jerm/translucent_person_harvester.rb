require "rubygems"
require "net/http"
require 'libxml'

module Jerm
  class TranslucentPersonHarvester
    TABLENAME="people"
    class TranslucentPerson
      
      DISCIPLINE_MAP={"Laboratory"=>"Experimentalist","Modeler"=>"Modeller","Admin"=>"Admin"}
      
      attr_accessor :seek_id,:firstname,:lastname,:tags,:avatar_uri,:institution_id,:email,:telephone 
      def initialize(node)
        @node=node
        @seek_id=element_value("id")
        @firstname=element_value("firstname")
        @lastname=element_value("lastname")
        @institution_id=element_value("institute")
        @email=element_value("email")
        @tags=element_value("tags")
        @avatar_uri=element_value("avatar")
        @telephone=element_value("telephone")        
        @project=Project.find_by_name("TRANSLUCENT")
      end
      
      def to_s
        puts "id: #{seek_id}"
        puts "name: #{name}"
        puts "email: #{email}"
        puts "tags: #{tags}"
        puts "institution id: #{institution_id}"
        puts "avatar: #{avatar_uri}"
        puts "telephone: #{telephone}"
      end
      
      def name
      "#{firstname} #{lastname}"
      end
      
      def avatar_data
        uri=URI.parse(avatar_uri)      
        http=Net::HTTP.new(uri.host,uri.port)
        req=Net::HTTP::Get.new(uri.path)
        http.request(req).body
      end
      
      def update
        raise Exception.new("No ID") if seek_id.blank?
        person_record=Person.find_by_id(seek_id)
        raise Exception.new("Unable to find person with ID: #{seek_id}") if person_record.nil?
        raise Exception.new("Person is not a member of Translucent") unless person_record.projects.include?(@project)  
        raise Exception.new("Name does not match that in database:  DB: #{person_record.name}, other: #{name}") if person_record.name != name
        i=Institution.find_by_id(institution_id)
        raise Exception.new("Institute not found for id: #{institution_id}") if i.nil?
        raise Exception.new("Institute #{i.name} is not a Translucent Institute") if !@project.institutions.include?(i)
        
        if DISCIPLINE_MAP[tags].nil?
          puts "Unable to match discipline to #{tags}"
        else
          title=DISCIPLINE_MAP[tags]
          discipline=Discipline.find_by_title(title)
          if discipline.nil?
            puts "Unable to find the discipline #{title} in the database"
          else
            person_record.disciplines << discipline unless person_record.disciplines.include?(discipline)
          end
        end
        
        
        #        person_record.firstname=firstname
        #        person_record.lastname=lastname
        person_record.email=email unless email.blank?
        person_record.phone=telephone
        unless avatar_uri.blank?
          if person_record.avatar_id.nil?
            avatar=Avatar.new
            avatar.owner=person_record
          else            
            avatar=Avatar.find(person_record.avatar_id)
          end  
          avatar.image_file_url=avatar_uri
          avatar.save!
          person_record.avatar_id=avatar.id
        end
        
        class << person_record
          def record_timestamps
            false
          end
        end
        person_record.save!
        
      end
      
      private
      
      def element_value name
        return @node.find_first(name).inner_xml unless @node.find_first(name).nil?
        return nil
      end
      
    end
    
    def self.start(root_uri,key)
      xml = fetch_xml(root_uri,key)           
      people=[]
      begin
        parser = LibXML::XML::Parser.string(xml,:encoding => LibXML::XML::Encoding::UTF_8)
        document = parser.parse
        document.find("item").each do |node|
          people << TranslucentPerson.new(node)
        end
        
      rescue LibXML::XML::Error => e
        puts "Error parsing the xml: #{e.message}"
      end
      
      return people
    end
    
    def self.fetch_xml(root_uri,key)
      
      uri=URI.parse(root_uri)      
      http=Net::HTTP.new(uri.host,uri.port)
      if uri.scheme=="https"
        http.use_ssl=true 
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end      
      req=Net::HTTP::Get.new(uri.path+"?key=#{key}&get=#{TABLENAME}")
      
      http.request(req).body
    end
    
  end
end

