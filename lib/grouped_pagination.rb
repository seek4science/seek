=begin
Inspired by http://www.hennessynet.com/blog/?p=70
but as a seperate mixin, rather than built into the will_paginate plugin
=end
module GroupedPagination
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    
    #this is the array of possible pages, defaults to A-Z. Can be set with the options[:pages] in grouped_pagination definition in model
    attr_reader :pages
    
    #this is limit to the list when showing 'latest', 7. Can be set with the options[:latest_limit] in grouped_pagination definition in model
    attr_reader :latest_limit

    #this is the default page to use if :page is not provided when paginating.
    attr_reader :default_page
    
    def grouped_pagination(options={})
      @pages = options[:pages] || ("A".."Z").to_a + ["?"]
      @field = options[:field] || "first_letter"
      @latest_limit = options[:latest_limit] || Seek::Config.limit_latest
      @default_page = options[:default_page] || 'all'
      
      before_save :update_first_letter
      
      include GroupedPagination::InstanceMethods
      extend GroupedPagination::SingletonMethods
    end
    
    def paginate_after_fetch(collection, *args)
      options=args.pop unless args.nil?
      options ||= {}
      
      default_page = options[:default_page] || @default_page
      default_page = @pages.first if default_page == "first"      
      
      page = options[:page] || default_page            
    
      records=[]
      if page == "all"
        records=collection
      elsif page == "latest"
        records=collection.sort{|x,y| y.updated_at <=> x.updated_at}[0...@latest_limit]
        records = records.sort_by {|r| collection.index r}
      elsif @pages.include?(page)           
        records=collection.select {|i| i.first_letter == page}        
      end
      
      page_totals={}
      @pages.each do |p|
        page_totals[p]=collection.select {|i| i.first_letter == p}.size            
      end
      
      result = Collection.new(records, page, @pages, page_totals)
      
      #jump to the first page with content if no page is specified and their is no content in the first page.
      if (result.empty? && options[:page].nil?)
        first_page_with_content = result.pages.find{|p| result.page_totals[p]>0}
        unless first_page_with_content.nil?
          options[:page]=first_page_with_content
          result=self.paginate_after_fetch(collection, options)
        end
      end
      
      result
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

      default_page = options[:default_page] || @default_page
      default_page = @pages.first if default_page == "first"  

      page = options[:page] || default_page
    
      records=[]
      if page == "all"
        records=self.find(:all)
      elsif page == "latest"
        records=self.find(:all,:order=>'created_at DESC', :limit=>@latest_limit)
      elsif @pages.include?(page)
        conditions = merge_optional_conditions(options[:conditions], page)
        query_options = [:conditions=>conditions]
        query_options[0].merge!(options.except(:conditions,:page,:default_page))                
        records=self.find(:all,*query_options)        
      end
      
      page_totals={}
      @pages.each do |p|
        conditions=merge_optional_conditions(options[:conditions],p)
        query_options = [:conditions=>conditions]
        query_options[0].merge!(options.except(:conditions,:page,:default_page))
        page_totals[p]=self.count(*query_options)            
      end
      
      result = Collection.new(records, page, @pages, page_totals)
      
      #jump to the first page with content if no page is specified and their is no content in the first page.
      if (result.empty? && options[:page].nil?)
        first_page_with_content = result.pages.find{|p| result.page_totals[p]>0}
        unless first_page_with_content.nil?
          options[:page]=first_page_with_content
          result=paginate(options)
        end
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
        text.gsub!(/[#{s[0..-2]}]/, s[-1..-1])
      end
      
      codepoints = text.mb_chars.normalize(:d).split(//u)
      ascii=codepoints.map(&:to_s).reject{|e| e.length > 1}.join
      
      return ascii.first.capitalize
      
    end
    
    def update_first_letter
      self.first_letter = strip_first_letter(title.strip.gsub(/[\[\]]/,""))
      self.first_letter = "?" unless self.class.pages.include?(self.first_letter)
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
  include GroupedPagination
end