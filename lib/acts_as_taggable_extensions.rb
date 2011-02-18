module ActsAsTaggableExtensions

  module TagExtensions
    def overall_total
      taggings.select{|tg| !tg.taggable.nil?}.count
    end
  end

end

ActsAsTaggableOn::Tag.class_eval do
  include ActsAsTaggableExtensions::TagExtensions
end