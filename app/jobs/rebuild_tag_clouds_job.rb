class RebuildTagCloudsJob < SeekJob
  def perform_job(key)
    ApplicationController.new.expire_fragment key
  end

  def gather_items
    %w(sidebar_tag_cloud suggestions_for_tag suggestions_for_expertise suggestions_for_tool)
  end

  def allow_duplicate_jobs?
    false
  end

  def default_priority
    3
  end

  def default_delay
    5.minutes
  end
end
