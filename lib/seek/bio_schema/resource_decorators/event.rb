module Seek
  module BioSchema
    module ResourceDecorators
      # Decorator that provides extensions for a Event
      class Event < BaseDecorator

        associated_items contact: :contributors
        associated_items host_institution: :projects

        def contributors
          [contributor]
        end

        def end_date
          if resource.end_date.blank?
            resource.start_date
          else
            resource.end_date
          end
        end

        def event_type
          []
        end

        def location
          [address,city,country].reject(&:blank?).join(", ")
        end

        def country
          CountryCodes. country(resource.country)
        end

        def rdf_resource
          uri = URI.join(Seek::Config.site_base_host + '/', "events/", id.to_s).to_s
          RDF::Resource.new(uri)
        end

      end
    end
  end
end
