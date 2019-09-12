module Seek
  module BioSchema
    module ResourceDecorators
      class Thing < BaseDecorator

        associated_items subject_of: :events

        def url
          identifier
        end

      end
    end
  end
end