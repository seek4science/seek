=begin
Inspired by http://www.hennessynet.com/blog/?p=70
but as a seperate mixin, rather than built into the will_paginate plugin
=end
module AlphabeticalPagination
  def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def alphabetical_pagination
          include AlphabeticalPagination::InstanceMethods
          extend AlphabeticalPagination::SingletonMethods
        end
      end

      module SingletonMethods

        PAGES=("A".."Z").to_a

        def paginate(*args)
          options=args.pop unless args.nil?
          options ||= {}
          page = options[:page] || "A"
          records=self.find(:all,:conditions=>["first_letter = ?",page])
          return Collection.new(records,page,page_totals)
        end

        def page_totals
          result={}
          ("A".."Z").each do |page|
            result[page]=self.count(:conditions=>["first_letter = ?",page])
          end
          result
        end

      end

      module InstanceMethods
        #Helper to strip the first letter from the text, converting non standard A-Z characters to their equivalent, e.g Ø -> O
        #uses some code based upon: http://github.com/grosser/sort_alphabetical/blob/9a8665d17394506c29cce51d8e22af69e2931523/lib/sort_alphabetical.rb with special handling for Ø
        def strip_first_letter text

          #handle the characters that can't be handled through normalization
          %w[ØO].each do |s|
            text.gsub!(/[#{s[0..-2]}]/,s[-1..-1])
          end

          codepoints = text.mb_chars.normalize(:d).split(//u)
          ascii=codepoints.map(&:to_s).reject{|e| e.length > 1}.join
          
          return ascii.first.capitalize

        end
      end

  class Collection < Array
    attr_reader :page,:page_totals

    def initialize records,page,page_totals
      super(records)
      @page=page
      @page_totals=page_totals
    end
  end
  
end

ActiveRecord::Base.class_eval do
  include AlphabeticalPagination
end