
# Inspired by http://www.hennessynet.com/blog/?p=70
# but as a seperate mixin, rather than built into the will_paginate plugin
module Seek
  module GroupedPagination
    def self.included(base)
      base.extend ClassMethods
    end
    module ClassMethods
      # this is the array of possible pages, defaults to A-Z. Can be set with the options[:pages] in grouped_pagination definition in model
      attr_reader :pages

      def grouped_pagination(options = {})
        @pages = options[:pages] || ('A'..'Z').to_a + ['?']
        @field = options[:field] || 'first_letter'
        # this is limit to the list when showing the 'top' page of results, defaults to 7.
        # Can be set with the options[:page_limit] in grouped_pagination definition in model
        @page_limit = options[:limit]

        before_save :update_first_letter

        include Seek::GroupedPagination::InstanceMethods
      end

      def page_limit
        @page_limit || Seek::Config.results_per_page_for(name.underscore.pluralize) || Seek::Config.results_per_page_default
      end

      # Paginate a given collection/relation
      def paginate_after_fetch(collection, *args)
        if collection.is_a?(ActiveRecord::Relation)
          paginate_relation(collection, *args)
        else
          paginate_enumerable(collection, *args)
        end
      end

      # Fetch from the database and paginate
      def grouped_paginate(*args)
        paginate_relation(self, *args)
      end

      # Paginate an ActiveRecord::Relation
      def paginate_relation(relation, *args)
        as_paginated_collection(*args) do |page_totals, page, limit, options|
          relation = relation.where(options[:conditions]) if options.key?(:conditions)

          if page == 'top'
            records = relation.limit(limit)
          elsif page == 'all'
            records = relation.all
          elsif @pages.include?(page)
            records = relation.where(@field.to_s => page)
          else
            records = []
          end

          # GROUP BY and COUNT to get page totals quickly
          groups = relation.reorder('').select(@field).group(@field).count
          @pages.each do |p|
            page_totals[p] = groups[p] || 0
          end

          records.to_a
        end
      end

      # Paginate an Enumerable
      def paginate_enumerable(collection, *args)
        as_paginated_collection(*args) do |page_totals, page, limit|
          @pages.each do |p|
            page_totals[p] = collection.count { |i| i.first_letter == p }
          end

          records = collection
          if page == 'top'
            records = records[0...limit]
          elsif page == 'all'
            records = records
          elsif @pages.include?(page)
            records = records.select { |i| i.first_letter == page }
          else
            records = []
          end

          records
        end
      end

      # Set-up pagination options, then yield to the given block to return the expected current page of items as an array, and also calculate page totals.
      def as_paginated_collection(*args, &block)
        options = args.pop unless args.nil?
        options ||= {}

        limit = options[:limit] || page_limit

        def_page = options[:default_page]
        def_page = @pages.first if def_page == 'first'
        def_page = 'top' if def_page == 'latest'

        page = options[:page] || def_page

        page_totals = {}

        records = yield(page_totals, page, limit, options)

        # If there isn't anything on this page, go to the first page that has something (if there is one).
        if records.empty? && options[:page].nil?
          first_page_with_content = page_totals.detect { |_page, count| count != 0 }
          unless first_page_with_content.nil?
            page = first_page_with_content.first
            options[:page] = page
            records = block.call(page_totals, page, limit, options)
          end
        end

        Collection.new(records, page, @pages, page_totals)
      end
    end

    module InstanceMethods
      # Helper to strip the first letter from the text, converting non standard A-Z characters to their equivalent, e.g Ø -> O
      # uses some code based upon: http://github.com/grosser/sort_alphabetical/blob/9a8665d17394506c29cce51d8e22af69e2931523/lib/sort_alphabetical.rb with special handling for Ø
      def strip_first_letter(text)
        # handle the characters that can't be handled through normalization
        %w[ØO].each do |s|
          text.gsub!(/[#{s[0..-2]}]/, s[-1..-1])
        end

        codepoints = text.mb_chars.normalize(:d).split(//u)
        ascii = codepoints.map(&:to_s).reject { |e| e.length > 1 }.join

        ascii.first.capitalize
      end

      def update_first_letter
        self.first_letter = strip_first_letter(title.strip.gsub(/[\[\]]/, ''))
        self.first_letter = '?' unless self.class.pages.include?(first_letter)
      end
    end

    class Collection < Array
      attr_reader :page, :page_totals, :pages

      def initialize(records, page, pages, page_totals)
        super(records)
        @page = page
        @page_totals = page_totals
        @pages = pages
      end
    end
  end
end
