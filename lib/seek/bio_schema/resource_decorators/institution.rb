module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for an Institution
      class Institution < Thing
        schema_mappings full_address: :address,
                        image: :logo,
                        ror_url: :identifier

        def schema_type
          'ResearchOrganization'
        end

        def url
          web_page.blank? ? identifier : web_page
        end

        def conformance
          'https://schema.org/ResearchOrganization'
        end

        def full_address
          full = {}
          full[:address_country] = country
          full[:address_locality] = city unless city.blank?
          full[:street_address] = address unless address.blank?
          full
        end
      end
    end
  end
end
