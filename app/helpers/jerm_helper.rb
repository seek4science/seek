module JermHelper
  RESPONSE_STATUS_IMAGES={:fail=>"error",:success=>"tick",:skipped=>"warning",:warning=>"warning"}

  def status_image status
    image_name=RESPONSE_STATUS_IMAGES[status]
    image(image_name)
  end
end
