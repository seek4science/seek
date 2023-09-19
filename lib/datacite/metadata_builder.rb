require 'nokogiri'

module DataCite
  class MetadataBuilder
    def initialize(metadata)
      @metadata = metadata
    end

    def build
      Nokogiri::XML::Builder.new do |xml|
        xml.resource('xmlns' => 'http://datacite.org/schema/kernel-4',
                      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                      'xsi:schemaLocation' => 'http://datacite.org/schema/kernel-4 '\
                                           'http://schema.datacite.org/meta/kernel-4.3/metadata.xsd') do
          xml.identifier @metadata.identifier, 'identifierType' => 'DOI'
          xml.titles do
            xml.title @metadata.title, 'xml:lang' => 'en-gb'
          end
          unless @metadata.description.blank?
            xml.descriptions do
              xml.description ActionView::Base.full_sanitizer.sanitize(@metadata.description),
                               'xml:lang' => 'en-gb',
                               'descriptionType' => 'Abstract'
            end
          end
          xml.creators do
            @metadata.creators.each do |creator|
              xml.creator do
                xml.creatorName "#{creator.last_name}, #{creator.first_name}"
                xml.nameIdentifier creator.orcid_uri, 'nameIdentifierScheme' => 'ORCID', 'schemeURI' => 'https://orcid.org' if creator.orcid.present?
              end
            end
          end
          xml.publicationYear(@metadata.year.to_s)
          xml.publisher(@metadata.publisher)
          xml.resourceType(@metadata.resource_type, 'resourceTypeGeneral' => @metadata.resource_type_general)
        end
      end.to_xml
    end
  end
end
