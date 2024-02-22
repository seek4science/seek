module Fhir
    module V4
      class ResearchStudySerializer < ActiveModel::Serializer
        include Seek::Util.routes

        attribute :resourceType do
          object.class.name.demodulize
        end

        attributes :id,:identifier,
                   :title, :status, :category, :condition,
                   :contact, :description,:enrollment,:period,:sponsor, :principalInvestigator, :extension,
                   :contained

      end
    end

end

