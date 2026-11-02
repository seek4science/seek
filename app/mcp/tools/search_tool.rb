module Tools
  class SearchTool < MCP::Tool
    title 'Search Tool'
    description 'Searches the given resource type for the given query'
    input_schema(
      properties: {
        type: {
          type: 'string',
          'enum': Seek::Util.searchable_types.map { |t| t.model_name.plural },
        },
        query: { type: 'string' },
      },
      required: ['type', 'query'],
      )
    annotations(
      destructive_hint: false,
      idempotent_hint: true,
      open_world_hint: false,
      read_only_hint: true,
    )

    class << self
      def call(type:, query:, server_context:)
        begin
          type_name = type.singularize.camelize
          if Seek::Util.searchable_types.map(&:to_s).include?(type_name)
            klass = Seek::Util.lookup_class(type_name, raise: false)
            if klass
              results = klass.with_search_query(query).authorized_for('view') # TODO: Get user_id from server_context and get authorized results

              res = results.first(10).map { |t| "#{t.title} - #{Seek::Util.routes.polymorphic_url(t)}" }.join("\n\n")

              return MCP::Tool::Response.new([{ type: "text", text: res }])
            end
          end

          MCP::Tool::Response.new([{ type: "text", text: "ERROR: #{type} is not a valid search type" }], error: true)
        rescue => e
          puts e.message
          puts e.backtrace.join("\n")
          raise e
        end
      end
    end
  end
end
