=begin
Inspired by http://www.hennessynet.com/blog/?p=70
but as a seperate mixin, rather than built into the will_paginate plugin
=end
module AlphabeticalPagination
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def alphabetical_pagination(options={})
      @pages = options[:pages] || ("A".."Z").to_a
      @field = options[:field] || "first_letter"

      include AlphabeticalPagination::InstanceMethods
      extend AlphabeticalPagination::SingletonMethods
    end
  end

  module SingletonMethods
    
    def merge_optional_conditions(optional_conditions, page)
      conditions= []
      conditions << ["#{@field} = ?", page]
      conditions << optional_conditions if optional_conditions
      conditions=merge_conditions(*conditions)
      return conditions
    end

    def paginate(*args)
      options=args.pop unless args.nil?
      options ||= {}
      page = options[:page] || "A"

      records=[]
      if @pages.include?(page)
        conditions = merge_optional_conditions(options[:conditions], page)
        query_options = [:conditions=>conditions]
        query_options[0].merge!(options.except(:conditions,:page))                
        records=self.find(:all,*query_options)        
      end

      page_totals={}
      @pages.each do |p|
        conditions=merge_optional_conditions(options[:conditions],p)
        query_options = [:conditions=>conditions]
        query_options[0].merge!(options.except(:conditions,:page))
        page_totals[p]=self.count(*query_options)            
      end
      
      return Collection.new(records, page, @pages, page_totals)
    end

  end



  module InstanceMethods
    #Helper to strip the first letter from the text, converting non standard A-Z characters to their equivalent, e.g Ø -> O
    #uses some code based upon: http://github.com/grosser/sort_alphabetical/blob/9a8665d17394506c29cce51d8e22af69e2931523/lib/sort_alphabetical.rb with special handling for Ø
    def strip_first_letter text

      #handle the characters that can't be handled through normalization
      %w[ØO].each do |s|
        text.gsub!(/[#{s[0..-2]}]/, s[-1..-1])
      end

      codepoints = text.mb_chars.normalize(:d).split(//u)
      ascii=codepoints.map(&:to_s).reject{|e| e.length > 1}.join

      return ascii.first.capitalize

    end
  end

  class Collection < Array
    attr_reader :page, :page_totals, :pages

    def initialize records, page, pages, page_totals
      super(records)
      @page=page
      @page_totals=page_totals
      @pages=pages
    end
  end

end

ActiveRecord::Base.class_eval do
  include AlphabeticalPagination
end