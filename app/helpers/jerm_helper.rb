module JermHelper
  RESPONSE_STATUS_IMAGES = { fail: 'error', success: 'tick', skipped: 'skipped', warning: 'warning' }

  def status_image(status)
    image_name = RESPONSE_STATUS_IMAGES[status]
    image(image_name)
  end

  def the_jerm(options = { size: 50 })
    logo_filename = icon_filename_for_key('jerm_logo')
    size = options[:size]
    image_tag logo_filename,
              alt: 'The JERM',
              size: "#{size}x#{size}",
              class: 'framed',
              style: 'padding: 2px;',
              title: 'The JERM'
  end

  def jerm_harvester_name
    'JERM'
  end

  def generate_resource_title_from_filename(filename)
    last_dot = filename.rindex('.')
    if !last_dot.nil? && last_dot > filename.length - 6 # only handle dots close to the end
      filename = filename[0..last_dot - 1]
    end
    filename.tr('_', ' ').capitalize
  end

  def generate_resource_title(resource)
    filename = resource.original_filename
    generate_resource_title_from_filename filename
  end
end
