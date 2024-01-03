module Fhir
    module V4
      class ResearchStudySerializer < ActiveModel::Serializer
        include Seek::Util.routes

        attributes :resource_type, :id, :title, :description, :url

        attribute :practitioner_roles do
          serialize_assets_creators
        end

        def resource_type
          object.class.name
        end

        def url
          study_url(object.id)
        end

        def serialize_assets_creators
          object.assets_creators.map do |c|
            { profile: c.creator_id ? person_path(c.creator_id) : nil,
              family_name: c.family_name,
              given_name: c.given_name,
              affiliation: c.affiliation,
              orcid: c.orcid }
          end
        end
      end
    end

end

