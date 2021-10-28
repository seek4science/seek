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
    content = license_description_content(license)

    if !license || license.is_null_license?
      content_tag(:span, id: 'null_license') do
        image(:warning) +
            content
      end
    else
      content
    end
  end

  # link to select a licence if the license is nil or a null license
  def prompt_for_license(resource, versioned_resource)
    license = Seek::License.find(versioned_resource.license)
    return unless (license.nil? || license.is_null_license?) && resource.can_manage?
    content_tag(:hr) +
        content_tag(:p) do
          link_to('Click here to choose a license', polymorphic_path(resource, action: :edit, anchor: 'license-section'))
        end
  end

  # whether to enable to auto selection of the license based on the selected project
  # only enabled if it is a new item, and the logged in person belongs to projects with a default license
  def enable_auto_project_license?
    resource_for_controller.try(:new_record?) && logged_in_and_registered? &&
      default_license_for_current_user
  end

  def default_license_for_current_user
    current_user.person.projects_with_default_license.any?
  end

  # JSON that creates a lookup for project license by id
  def project_licenses_json
    projects = current_user.person.projects_with_default_license
    Hash[projects.collect { |proj| [proj.id, proj.default_license] }].to_json.html_safe
  end

  private

  def license_description_content(license)
    if license
      url = license.url
      title = license.title
      if url.blank?
        title
      else
        link_to(title, url, target: :_blank)
      end
    else
      link_to(Seek::License::NULL_LICENSE_TEXT,Seek::Help::HelpDictionary.instance.help_link(:null_license),target: :_blank)
    end
  end

  def license_values(opts = {})
    opts.delete(:source) || Seek::License::OPENDEFINITION[:all]
  end

  def license_options(opts = {})
    license_values(opts).map { |value| [value['title'], value['id'], { 'data-url' => value['url'] }] }
  end

  def grouped_license_options(opts = {})
    grouped_licenses = sort_grouped_licenses(group_licenses(opts))

    grouped_licenses.each do |_, licenses|
      licenses.map! { |value| [value['title'], value['id'], { 'data-url' => value['url'] }] }
    end

    grouped_licenses
  end

  def sort_grouped_licenses(licenses)
    licenses.sort_by do |pair|
      case pair[0]
      when 'Recommended'
        0
      when 'Generic'
        1
      else
        2
      end
    end
  end

  def group_licenses(opts)
    
    grouped = license_values(opts).group_by do |l|
      if opts[:recommended]&.include?(l['id'])
        'Recommended'
      elsif l.key?('is_generic') && l['is_generic']
        'Generic'
      else
        'Other'
      end
    end.to_a
  end
  
end
