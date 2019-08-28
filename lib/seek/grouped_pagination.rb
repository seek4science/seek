
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

      # this is limit to the list when showing the 'top' page of results, defaults to 7.
      # Can be set with the options[:page_limit] in grouped_pagination definition in model
      attr_reader :page_limit

      # this is the default page to use if :page is not provided when paginating.
      attr_reader :default_page

      def grouped_pagination(options = {})
        @pages = options[:pages] || ('A'..'Z').to_a + ['?']
        @field = options[:field] || 'first_letter'
        @page_limit = options[:limit] || Seek::Config.limit_latest
        @default_page = options[:default_page] || Seek::Config.default_page(name.underscore.pluralize) || 'all'
        @default_page = 'top' if @default_page == 'latest'

        before_save :update_first_letter

        include Seek::GroupedPagination::InstanceMethods
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
      def paginate(*args)
        paginate_relation(unscoped, *args)
      end

      # Paginate an ActiveRecord::Relation
      def paginate_relation(relation, *args)
        as_paginated_collection(*args) do |page_totals, page, order, limit, options|
          if page == 'top'
            records = relation.order(order).limit(limit)
          elsif page == 'all'
            records = relation.order(order)
          elsif @pages.include?(page)
            query_options = { conditions: options[:conditions] }
            query_options.merge!(options.except(:conditions, :page, :default_page))
            records = relation.where(@field.to_s => page).where(query_options[:conditions]).order(order)
          else
            records = []
          end

          @pages.each do |p|
            query_options = [conditions: options[:conditions]]
            query_options[0].merge!(options.except(:conditions, :page, :default_page))
            page_totals[p] = relation.where(@field.to_s => p).where(query_options[0][:conditions]).count
          end

          records.to_a
        end
      end

      # Paginate an Enumerable
      def paginate_enumerable(collection, *args)
        as_paginated_collection(*args) do |page_totals, page, order, limit|
          @pages.each do |p|
            page_totals[p] = collection.count { |i| i.first_letter == p }
          end

          records = collection
          Seek::ListSorter.index_items(records, order)
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

        limit = options[:limit] || @page_limit
        default_page = options[:default_page] || @default_page
        default_page = @pages.first if default_page == 'first'
        page = options[:page] || default_page
        order = options[:order] || Seek::ListSorter.sort_field(name, :index)
        order = Seek::ListSorter.sort_value(:updated_at_desc) if !options.key?(:order) && page == 'top'

        page_totals = {}

        records = block.call(page_totals, page, order, limit, options)

        # If there isn't anything on this page, go to the first page that has something (if there is one).
        if records.empty? && options[:page].nil?
          first_page_with_content = page_totals.detect { |_page, count| count != 0 }
          unless first_page_with_content.nil?
            page = first_page_with_content.first
            options[:page] = page
            records = block.call(page_totals, page, order, limit, options)
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
