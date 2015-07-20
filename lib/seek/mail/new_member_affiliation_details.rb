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
        msg = details_existing(projects)
        msg += "\r\nNew #{I18n.t('project').pluralize}: #{other_projects}\r\n" unless other_projects.blank?
        msg += details_existing(institutions)
        msg += "\r\nNew Institutions: #{other_institutions}\r\n" unless other_institutions.blank?
        msg
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
