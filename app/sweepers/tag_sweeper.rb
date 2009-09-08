class TagSweeper  < ActionController::Caching::Sweeper

  observe Tag

  def after_update(tag)
    clear_tag_cloud_cache()
  end

  def after_create(tag)
    clear_tag_cloud_cache()
  end

  def after_save(tag)
    clear_tag_cloud_cache()
  end

  def after_destroy(tag)
    clear_tag_cloud_cache()
  end

  private

  def clear_tag_cloud_cache()
    puts "Clearing tag_clouds cache"
    expire_fragment("tag_clouds")  
  end

end