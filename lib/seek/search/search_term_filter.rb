module Seek
  module Search
    class SearchTermFilter
      def self.filter query
        query = query.strip
        query = query.gsub("*", "")
        query = query.gsub("?", "")
        query = query.chop if query.end_with?(":")

        query = query.strip
        query = "" if query=="-"

        query
      end

    end
  end
end

