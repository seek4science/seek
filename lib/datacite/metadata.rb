require 'nokogiri'

module DataCite
  class Metadata

    def initialize(hash)
      @hash = hash
    end

    def []=(key, value)
      @hash[key] = value
    end

    def [](key)
      @hash[key]
    end

    def build
      Nokogiri::XML::Builder.new do |xml|
        @xml = xml
        @xml.resource('xmlns' =>'http://datacite.org/schema/kernel-3',
                      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                      'xsi:schemaLocation' => 'http://datacite.org/schema/kernel-3 '\
                                           'http://schema.datacite.org/meta/kernel-3/metadata.xsd') do
          @hash.each do |key, value|
            self.send(key, value)
          end
        end
      end.to_xml
    end

    def to_s
      build.to_s
    end

    private

    def identifier(doi)
      @xml.identifier doi, 'identifierType' => 'DOI'
    end

    def creators(creator_list)
      @xml.creators do
        creator_list.each do |creator|
          @xml.creator do
            @xml.creatorName "#{creator.last_name}, #{creator.first_name}"
          end
        end
      end
    end

    def title(title)
      @xml.titles do
        @xml.title title, 'xml:lang' => 'en-gb'
      end
    end

    def description(desc)
      @xml.descriptions do
        @xml.description ActionView::Base.full_sanitizer.sanitize(desc),
                         'xml:lang' => 'en-gb',
                         'descriptionType' => 'Abstract'
      end
    end

    def publisher(publisher_name)
      @xml.publisher publisher_name
    end

    def year(year)
      @xml.publicationYear year
    end

    def content_type(types)
      @xml.resourceType types[0], 'resourceTypeGeneral' => types[1]
    end

  end
end
