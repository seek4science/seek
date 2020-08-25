module Ga4gh
  module Trs
    module V2
      # Decorator for a Workflow to make it appear as a GA4GH TRS Tool.
      class Tool
        include ActiveModel::Serialization
        include Rails.application.routes.url_helpers
        delegate_missing_to :@workflow

        def initialize(workflow)
          @workflow = workflow
        end

        def name
          title
        end

        def versions
          super.map { |v| ToolVersion.new(v) }
        end
      end
    end
  end
end