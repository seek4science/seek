module Fhir
  module V4
    class ResearchStudiesController < ApplicationController
      respond_to :json

      before_action :get_study, only: [:show]

      def show
        respond_with(@research_study, adapter: :attributes, root: '')
      end

      def get_study
        study = Study.find_by_id(params[:id])
        @research_study = ResearchStudy.new(study)
      end
    end
  end
end