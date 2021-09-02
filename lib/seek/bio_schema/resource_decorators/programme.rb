module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Organism
      class Programme < Thing
        schema_mappings avatar_url: :logo
        
        def schema_type
          'FundingScheme'
        end

        def conformance
          'https://schema.org/FundingScheme'
        end

        def url
          puts web_page
          puts identifier
          web_page.blank? ? identifier : web_page
        end

        def avatar_url
          avatar&.public_asset_url
        end
        
      end
    end
  end
end
