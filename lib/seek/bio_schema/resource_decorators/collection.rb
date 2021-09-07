module Seek
  module BioSchema
    module ResourceDecorators
      class Collection < CreativeWork
        associated_items has_part: :schema_enabled_assets
        schema_mappings has_part: :hasPart

        def schema_type
          'Collection'
        end

        def conformance
          'https://schema.org/Collection'
        end

        def schema_enabled_assets
          sel_assets = []
          assets.each { |a|
            next if a.blank?
            next unless a.schema_org_supported?
            sel_assets << a
          }
          sel_assets
        end
      end
    end
  end
end
