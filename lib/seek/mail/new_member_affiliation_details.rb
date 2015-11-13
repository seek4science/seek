module Seek
  module Mail
    # utility for creating the text for list of projects and institutions a
    # new registration has indicated they are involved with, based on the params
    class NewMemberAffiliationDetails
      attr_reader :projects, :institutions, :other_projects, :other_institutions

      def initialize(params)
        @projects = Array(params[:projects]).collect { |id| Project.find_by_id(id) }.compact
        @institutions = Array(params[:institutions]).collect { |id| Institution.find_by_id(id) }.compact
        @other_projects = params[:other_projects] || ''
        @other_institutions = params[:other_institutions] || ''
      end

      def message
        lines = []
        lines << details_existing(projects)
        lines << "New #{I18n.t('project').pluralize}: #{other_projects}" unless other_projects.blank?
        lines << details_existing(institutions)
        lines << "New Institutions: #{other_institutions}" unless other_institutions.blank?
        lines.join("\r\n")
      end

      private

      def details_existing(items)
        items.collect do |item|
          "#{item.class.name}: #{item.title}"
        end.join("\r\n")
      end
    end
  end
end
