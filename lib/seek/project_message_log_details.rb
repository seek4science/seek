module Seek
  module ProjectMessageLogDetails
    extend ActiveSupport::Concern

    class Details
      attr_accessor :project, :programme, :institution, :comments
    end

    def parsed_details
      @parsed_details ||= parse_details
    end

    private

    def parse_details
      details_json = JSON.parse(details)
      details = Details.new
      if details_json['programme']
        details.programme = Programme.new(details_json['programme'])
        details.programme = Programme.find(details.programme.id) unless details.programme.id.nil?
      end
      if details_json['project']
        details.project = Project.new(details_json['project'])
        details.project = Project.find(details.project.id) unless details.project.id.nil?
      end
      if details_json['institution']
        details.institution = Institution.new(details_json['institution'])
        details.institution = Institution.find(details.institution.id) unless details.institution.id.nil?
      end
      details.comments = details_json['comments']
      details
    end

    module ClassMethods
      def details_json(programme: nil, project: nil, institution: nil, comments: nil)
        details = {}
        details[:institution] = institution.attributes if institution
        details[:project] = project.attributes if project
        details[:programme] = programme&.attributes if programme
        details[:comments] = comments if comments

        details.to_json
      end
    end
  end
end
