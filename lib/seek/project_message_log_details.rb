module Seek
  # handles processing the details about a log related to a project create or join
  # request. The details are logged as JSON and this class handles the generation and parsing of the
  # JSON
  module ProjectMessageLogDetails
    extend ActiveSupport::Concern

    # Encapsulates the message details, provind the project, programme, institution and comments
    class Details
      attr_reader :project, :programme, :institution, :comments

      def initialize(project:, programme:, institution:, comments:)
        @project = project
        @programme = programme
        @institution = institution
        @comments = comments
      end
    end

    def parsed_details
      @parsed_details ||= parse_details
    end

    private

    # parses the JSON, and creates an instance of each item if it is defined in the JSON
    def parse_details
      details_json = JSON.parse(details)

      Details.new(
        project: find_instance_from_json(details_json, Project),
        programme: find_instance_from_json(details_json, Programme),
        institution: find_instance_from_json(details_json, Institution),
        comments: details_json['comments']
      )
    end

    # returns an instance of each item from the json, according the instance class passed.
    # either returns a new record, or an instance from the database if the id is present
    def find_instance_from_json(json, instance_class)
      key = instance_class.table_name.singularize
      details = json[key]
      obj = nil
      if details
        obj = instance_class.new(details)
        obj = instance_class.find(obj.id) if obj.id
      end
      obj
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
