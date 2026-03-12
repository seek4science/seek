module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Programme
      class Programme < Thing
        schema_mappings avatar_url: :logo

        def schema_type
          'FundingScheme'
        end

        def url
          web_page.blank? ? identifier : web_page
        end

        def avatar_url
          avatar&.public_asset_url
        end
      end
    end
  end
end
