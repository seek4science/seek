module JermHelper
  RESPONSE_STATUS_IMAGES={:fail=>"error",:success=>"tick",:skipped=>"skipped",:warning=>"warning"}

  def status_image status
    image_name=RESPONSE_STATUS_IMAGES[status]
    image(image_name)
  end

  def the_jerm options={:size=>50}
    logo_filename=icon_filename_for_key("jerm_logo")
    size=options[:size]
    image_tag logo_filename,
      :alt => "The JERM",
      :size => "#{size}x#{size}",
      :class => 'framed',
      :style=>"padding: 2px;",
      :title=>"The JERM"
  end

  def jerm_harvester_name
    "JERM"
  end
  
end
