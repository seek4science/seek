module Seek
  module Filtering
    class SearchFilter
      def apply(collection, query)
        q = query.join(' ')
        q = ActionController::Base.helpers.sanitize(q)
        q ||= ''
        q = Seek::Search::SearchTermFilter.filter(q)
        q = q.downcase
        results = collection.with_search_query(q)

        # needs to return a relation for chaining, the order will be fixed from the solr cache once other filters have been applied
        collection.where(id: results.collect(&:id))
      end

      def options(collection, active_values)
        return [] unless collection.searchable? && Seek::Config.solr_enabled && collection.any?
        q = active_values.join(' ')
        [Seek::Filtering::Option.new(q, q, nil, active_values.any?)]
      end
    end
  end
end
