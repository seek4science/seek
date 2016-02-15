require 'json'
require 'seek/license'

module LicenseHelper

  def license_select(name, selected = nil, opts = {})
    select_tag(name, options_for_select(license_options(opts), selected), opts)
  end

  def grouped_license_select(name, selected = nil, opts = {})
    select_tag(name, grouped_options_for_select(grouped_license_options(opts), selected), opts)
  end

  def describe_license(id, source = nil)
    license = Seek::License.find(id, source)
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

  private

  def license_values(opts = {})
    opts.delete(:source) || Seek::License::OPENDEFINITION[:all]
  end

  def license_options(opts = {})
    license_values(opts).map { |value| [value['title'], value['id'], {'data-url' => value['url']}] }
  end

  def grouped_license_options(opts = {})
    grouped_licenses = license_values(opts).group_by do |l|
      if l.has_key?('is_generic') && l['is_generic']
        'Generic'
      elsif l.has_key?('od_recommended') && l['od_recommended']
        'Recommended'
      else
        'Other'
      end
    end.to_a.sort_by do |pair|
      case pair[0]
        when 'Recommended'
          0
        when 'Generic'
          1
        else
          2
      end
    end

    grouped_licenses.each do |_, licenses|
      licenses.map! { |value| [value['title'], value['id'], {'data-url' => value['url']}] }
    end

    grouped_licenses
  end


end
