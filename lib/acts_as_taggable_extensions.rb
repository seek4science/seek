module ActsAsTaggableExtensions

  module TagExtensions

    def overall_total
      taggings.select{|tg| !tg.taggable.nil?}.count
    end
  end

end

ActsAsTaggableOn::Tag.class_eval do
  include ActsAsTaggableExtensions::TagExtensions

  named_scope :all_tags_for_cloud, :group=>"tags.id",:joins=>:taggings,:conditions=>["taggings.taggable_id IS NOT NULL"]
  
end