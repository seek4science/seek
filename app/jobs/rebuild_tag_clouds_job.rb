class RebuildTagCloudsJob < ApplicationJob
  include CommonSweepers

  def perform
    %w(sidebar_tag_cloud suggestions_for_tag suggestions_for_expertise suggestions_for_tool).each do |key|
      expire_fragment(key)
    end
  end
end
