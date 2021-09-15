module Ga4gh
  module Trs
    module V2
      # Decorator for a Workflow::Version to make it appear as a GA4GH TRS Tool Version.
      class ToolClass
        include ActiveModel::Serializers::JSON

        def initialize(params)
          @params = params
        end

        def id
          @params[:id].to_s
        end

        def name
          @params[:name]
        end

        def description
          @params[:description]
        end

        def attributes
          { id: id, name: name, description: description }
        end

        WORKFLOW = ToolClass.new(id: 1, name: 'Workflow', description: 'A computational workflow')
      end
    end
  end
end
