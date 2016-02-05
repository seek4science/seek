require 'json'
require 'seek/license'

module LicenseHelper

  def license_select(name, selected = nil, opts = {})
    licenses = opts.delete(:data_only) ? Seek::License::DATA_LICENSE_ARRAY : Seek::License::LICENSE_ARRAY
    option_pairs = licenses.map { |value| [value['title'], value['id'], {'data-url' => value['url']}] }

    select_tag(name, options_for_select(option_pairs, selected), opts)
  end

  def describe_license(id)
    license = Seek::License.find(id)
    if license && !license.is_null_license?
      if license.url.blank?
        license.title
      else
        link_to(license.title, license.url)
      end
    else
      content_tag(:span, 'No license specified', :class => 'none_text')
    end
  end

end
