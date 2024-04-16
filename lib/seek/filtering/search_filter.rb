module Seek
  module Filtering
    class SearchFilter
      def apply(collection, query)
        q = query.join(' ')
        q = ActionController::Base.helpers.sanitize(q)
        q ||= ''
        q = q.downcase.strip
        collection.with_search_query(q)
      end

      def options(collection, active_values)
        return [] unless collection.searchable? && Seek::Config.solr_enabled && collection.any?
        q = active_values.join(' ')
        [Seek::Filtering::Option.new(q, q, nil, active_values.any?)]
      end
    end
  end
end
