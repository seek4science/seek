module TagsHelper
  include ActsAsTaggableOn::TagsHelper

  def tag_cloud(tags, classes,counter_method=:count)
    tags = tags.sort_by(&:name)
    max_count = tags.max_by(&counter_method).send(counter_method).to_f
    if max_count < 1
      max_count = 1
    end

    tags.each do |tag|
      index = ((tag.send(counter_method) / max_count) * (classes.size - 1)).round
      yield tag, classes[index]
    end
  end

  def overall_tag_cloud(tags, classes,&block)
    tag_cloud(tags,classes,:overall_total, &block)
  end

  def aggregated_asset_tags
    tags = []
    asset_model_classes.each do |c|
      tags |= c.tag_counts if c.taggable?
    end
    tags
  end

end