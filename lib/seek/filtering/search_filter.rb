module Seek
  module Filtering
    class SearchFilter
      def apply(collection, query)
        q = query.join(' ')
        q = ActionController::Base.helpers.sanitize(q)
        q ||= ''
        q = Seek::Search::SearchTermFilter.filter(q)
        q = q.downcase
        collection.with_search_query(q)
      end

      def options(collection)
        []
      end
    end
  end
end
