#A common pattern to trim titles before the are saved. This is used in most assets
module TitleTrimmer
  
  def self.included(mod)
    mod.extend(ClassMethods)
  end
  
  module ClassMethods
    
    def title_trimmer
      before_save :trim_title      
      include TitleTrimmer::InstanceMethods      
    end    
  end
  
  module InstanceMethods
    def trim_title
      self.title=title.strip unless title.nil?
    end
  end
  
end


ActiveRecord::Base.class_eval do
  include TitleTrimmer
end