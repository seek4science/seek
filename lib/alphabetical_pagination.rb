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
          
          return records
        end
      end

      module InstanceMethods
        
      end

  class Collection < Array

  end
  
end

ActiveRecord::Base.class_eval do
  include AlphabeticalPagination
end