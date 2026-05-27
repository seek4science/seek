require 'nokogiri'

module Datacite
  class MetadataReader
    def initialize(xml)
      @xml = Nokogiri::XML(xml)
    end

    def parse
      Datacite::Metadata.new(
        title: parse_title,
        identifier: parse_identifier,
        publisher: parse_publisher,
        year: parse_year,
        creators: parse_creators,
        resource_type: parse_resource_type
      )
    end

    private

    def parse_title
      @xml.xpath('//xmlns:title').first&.text
    end

    def parse_identifier
      @xml.xpath('//xmlns:identifier').first&.text
    end

    def parse_publisher
      @xml.xpath('//xmlns:publisher').first&.text
    end

    def parse_year
      year_text = @xml.xpath('//xmlns:publicationYear').first&.text
      year_text&.to_i
    end

    def parse_creators
      @xml.xpath('//xmlns:creator').map do |creator_node|
        name = creator_node.xpath('.//xmlns:creatorName').first&.text
        Creator.new(*parse_name(name)) if name
      end.compact
    end

    def parse_name(full_name)
      parts = full_name.split(',').map(&:strip)
      if parts.length == 2
        [parts[1], parts[0]] # [first_name, last_name]
      else
        [full_name, '']
      end
    end

    def parse_resource_type
      resource_type_node = @xml.xpath('//xmlns:resourceType').first
      return nil unless resource_type_node

      general_type = resource_type_node.attr('resourceTypeGeneral')
      specific_type = resource_type_node.text

      [specific_type, general_type]
    end
  end

  class Creator
    attr_reader :first_name, :last_name

    def initialize(first_name, last_name)
      @first_name = first_name
      @last_name = last_name
    end
  end
end