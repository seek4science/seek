module TagsHelper
  include ActsAsTaggableOn::TagsHelper

  def tag_cloud(tags, classes)
    max_count = tags.sort_by(&:count).last.count.to_f
    if max_count < 1
      max_count = 1
    end

    tags.each do |tag|
      index = ((tag.count / max_count) * (classes.size - 1)).round
      yield tag, classes[index]
    end
  end

  def overall_tag_cloud(tags, classes)
    max_count = tags.sort_by(&:overall_total).last.count.to_f
    if max_count < 1
      max_count = 1
    end

    tags.each do |tag|
      index = ((tag.overall_total / max_count) * (classes.size - 1)).round
      yield tag, classes[index]
    end
  end
end