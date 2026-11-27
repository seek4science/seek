module Tools
  class SearchTool < ApplicationTool
    class << self
      # We define the tool dynamically because its schema looks at `Seek::Util.searchable_types` which can change.
      def build
        MCP::Tool.define(
          name: 'search_tool',
          title: 'Search Tool',
          description: 'Searches the given resource type for the given query',
          input_schema: {
            properties: {
              type: {
                type: 'string',
                enum: Seek::Util.searchable_types.map { |t| t.model_name.plural },
              },
              query: { type: 'string' },
            },
            required: ['type', 'query'],
          },
          annotations: {
            destructive_hint: false,
            idempotent_hint: true,
            open_world_hint: false,
            read_only_hint: true
          },
          &method(:call))
      end

      def call(type:, query:, server_context:)
        type_name = type.singularize.camelize
        if Seek::Util.searchable_types.map(&:to_s).include?(type_name)
          klass = Seek::Util.lookup_class(type_name, raise: false)
          if klass
            results = klass.with_search_query(query).authorized_for('view') # TODO: Get user_id from server_context and get authorized results
            results = Seek::ListSorter.sort_by_order(results, '--relevance')

            res = results.first(10).map { |t| "#{t.title} - #{Seek::Util.routes.polymorphic_url(t)}" }.join("\n\n")

            return MCP::Tool::Response.new([{ type: "text", text: res }])
          end
        end

        MCP::Tool::Response.new([{ type: "text", text: "ERROR: #{type} is not a valid search type" }], error: true)
      end

      def enabled?
        Seek::Config.solr_enabled
      end
    end
  end
end
