module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for an Institution
      class Institution < Thing
        schema_mappings full_address: :address,
                        image: :logo,
                        ror_identifier: :identifier,
                        base_title: :name,
                        department_organization: :department

        def schema_type
          'ResearchOrganization'
        end

        def ror_identifier
          return unless ror_url.present?

          { '@id' => ror_url }
        end

        def department_organization
          return nil if department.blank?
          {
            '@type': 'Organization',
            name: department
          }
        end

        def url
          web_page.blank? ? identifier : web_page
        end

        def conformance
          'https://schema.org/ResearchOrganization'
        end

        def full_address
          full = {}
          full[:@type]='PostalAddress'
          full[:addressCountry] = country
          full[:addressLocality] = city unless city.blank?
          full[:streetAddress] = address unless address.blank?
          full
        end
      end
    end
  end
end
