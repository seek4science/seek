module Seek
  module Stats
    class SearchStats

      def yearly_searches
        searches_since 1.year.ago
      end

      def monthly_searches
        searches_since 1.month.ago
      end

      def weekly_searches
        searches_since 1.week.ago
      end

      def daily_searches
        searches_since 1.day.ago
      end

      def daily_search_terms limit=10
        search_queries_since 1.day.ago, limit
      end

      def weekly_search_terms limit=10
        search_queries_since 1.week.ago, limit
      end

      def monthly_search_terms limit=10
        search_queries_since 1.month.ago, limit
      end

      def yearly_search_terms limit=10
        search_queries_since 1.year.ago, limit
      end

      def searches_since time=500.years.ago
        ActivityLog.count(:all,:conditions=>["controller_name = ? and created_at > ?","search",time])
      end

      #returns a 2 dimensional array each outer element containing the [term,score]
      #for the 'limit' most frequent search terms since 'time'
      def search_queries_since time=500.years.ago,limit=5
        terms = ActivityLog.where(["controller_name = ? and created_at > ?","search",time]).collect{|al| al.data[:search_query]}
        scores = {}
        terms.each do |term|
          if scores.keys.include? term
            scores[term]+=1
          else
            scores[term]=1
          end
        end
        scores = scores.sort{|a,b| b[1]<=>a[1]} #sort descending by score

        scores[0...limit]
      end
    end
  end
end