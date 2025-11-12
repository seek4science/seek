module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Project
      class Project < Thing
        associated_items member: :all_members,
                         funder: :programme_set,
                         event: :events

        schema_mappings image: :logo,
                        member: :member,
                        funder: :funder,
                        event: :event

        def programme_set
          [programme].reject(&:blank?)
        end

        def url
          web_page.blank? ? identifier : web_page
        end

        def all_members
          people + institutions
        end

        def schema_type
          %w[Project Organization]
        end
      end
    end
  end
end
