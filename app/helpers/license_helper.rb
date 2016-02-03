require 'json'

module LicenseHelper

  LICENSE_ARRAY = JSON.parse(File.read(File.join(Rails.root, 'public', 'licenses.json')))

  def license_select(name, selected = nil, opts = {})
    option_pairs = LICENSE_ARRAY.map { |value| [value['title'], value['id'], {'data-url' => value['url']}] }

    select_tag(name, options_for_select(option_pairs, selected), opts)
  end

  def describe_license(id)
    license = LICENSE_ARRAY.find { |l| l['id'] == id }
    if license
      link_to(license['title'], license['url'])
    else
      content_tag(:span, 'No license specified', :class => 'none_text')
    end
  end

end
