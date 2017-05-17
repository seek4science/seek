module ActsAsTaggableExtensions

  module TagExtensions

    #FIXME: temporary - to trick the old Tag to behave like the new annotations.This should be removed when tools and expertise are updated.
    class String < String
      def text
        to_s
      end
    end

    def overall_total
      taggings.select{|tg| !tg.taggable.nil?}.count
    end

    def value
      String.new name
    end

  end

end

ActsAsTaggableOn::Tag.class_eval do
  include ActsAsTaggableExtensions::TagExtensions

  scope :all_tags_for_cloud, -> { group('tags.id').joins(:taggings).where('taggings.taggable_id IS NOT NULL') }
  
end
