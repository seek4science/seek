require 'json'
require 'seek/license'

module LicenseHelper
  def license_select(name, selected = nil, opts = {})
    opts[:data] ||= {}
    opts[:data]['seek-license-select'] ||= 'true'
    opts[:multiple] = false

    recommended = opts.delete(:recommended)
    source = opts.delete(:source) || Seek::License.combined
    if recommended
      opts[:select_options] = grouped_options_for_select(grouped_license_options(source.values, recommended), selected)
    else
      opts[:select_options] = options_for_select(license_options(source.values), selected)
    end

    objects_input(name, [], opts)
  end

  def describe_license(id)
    license = Seek::License.find(id)
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
      link_to(t('null_license') ,Seek::Help::HelpDictionary.instance.help_link(:null_license),target: :_blank)
    end
  end

  def license_options(licenses)
    licenses.map do |value|
      [value['title'], value['id'], { 'data-url' => value['url'] }]
    end.sort_by do |value|
      if value[1] == Seek::License::NULL_LICENSE # Put null license first
        '-'
      else
        value[0] # Otherwise sort by title
      end
    end
  end

  def grouped_license_options(licenses, recommended)
    grouped_licenses = licenses.group_by do |l|
      if recommended&.include?(l['id'])
        'recommended'
      else
        'other'
      end
    end

    grouped_licenses.transform_values! do |l|
      license_options(l)
    end

    # Transform into array to ensure recommended licenses come first
    ['recommended', 'other'].map do |key|
      [t("licenses.#{key}"), grouped_licenses[key] || []]
    end
  end
end
