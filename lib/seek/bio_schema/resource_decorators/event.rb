module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Event
      class Event < Thing
        EVENT_PROFILE = 'https://bioschemas.org/profiles/Event/0.3-DRAFT'.freeze

        associated_items contact: :contributors,
                         host_institution: :projects,
                         all_assets: :about_assets

        schema_mappings contact: :contact,
                        start_date: :startDate,
                        end_date: :endDate,
                        event_type: :eventType,
                        location: :location,
                        host_institution: :hostInstitution,
                        all_assets: :about,
                        created_at: :dateCreated,
                        updated_at: :dateModified

        def conformance
          EVENT_PROFILE
        end

        def contributors
          [contributor]
        end

        def end_date
          if (end_date = resource.end_date).blank?
            resource.start_date
          else
            end_date
          end
        end

        def event_type
          []
        end

        def location
          [address, city, country].reject(&:blank?).join(', ')
        end

        def country
          CountryCodes.country(resource.country)
        end

        def about_assets
          data_files + documents + presentations # + publications
        end
      end
    end
  end
end
