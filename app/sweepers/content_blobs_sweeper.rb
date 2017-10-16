class ContentBlobsSweeper < ActionController::Caching::Sweeper

  include CommonSweepers

  observe ContentBlob

  def after_update(content_blob)
    expire_nels_data_sheet(content_blob)
  end

  def after_destroy(content_blob)
    expire_nels_data_sheet(content_blob)
  end

  def expire_nels_data_sheet(content_blob)
    expire_fragment("nels_data_#{content_blob.id}")
  end

end
