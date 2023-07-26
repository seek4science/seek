module WorkflowsHelper
  def port_types(port)
    return content_tag(:span, 'n/a', class: 'none_text') if port.type.nil?
    port_type_description(port.type)
  end

  def port_type_description(types)
    types = [types] unless types.is_a?(Array)

    html = ''
    classes = ['workflow-port-type']

    actual_types = 0
    types.each do |type|
      case type['type']
      when 'enum'
        html += content_tag(:li) do
          '<strong>enum</strong> of: ' + type['symbols'].join(', ')
        end
      when 'array'
        html += content_tag(:li) do
          ('<strong>array</strong> containing ' + port_type_description(type['items'])).html_safe
        end
      when 'record'
        html += content_tag(:li) do
          ('<strong>record</strong> containing ' + port_type_description(type['fields'])).html_safe
        end
      when 'null'
        classes << 'optional'
      else
        html += content_tag(:li, content_tag(:strong, type['type']))
      end
    end

    content_tag(:ul, html.html_safe, class: classes.join(' '))
  end

  def maturity_badge(level)
    label_class = case level
                when :released
                  'label-success'
                when :work_in_progress
                  'label-warning'
                when :deprecated
                  'label-danger'
                else
                  'label-default'
                end
    content_tag(:span, t("maturity_level.#{level}"), class: "maturity-level label #{label_class}")
  end

  def test_status_badge(resource)
    status = resource.test_status
    case status
    when :all_passing
      label_class = 'label-success'
      label = t("test_status.#{status}")
    when :some_passing
      label_class = 'label-warning'
      label = t("test_status.#{status}")
    when :all_failing
      label_class = 'label-danger'
      label = t("test_status.#{status}")
    else
      label_class = 'label-default'
      label = t('test_status.not_available')
    end
    url = LifeMonitor::Rest::Client.status_page_url(resource)
    link_to(url, class: 'lifemonitor-status btn btn-default', target: '_blank', rel: 'noopener',
            'data-tooltip' => 'Click to view in LifeMonitor') do
      image('life_monitor_icon', class: 'icon lifemonitor-logo') +
        'Tests ' +
        content_tag(:span, label, class: "test-status label #{label_class}")
    end
  end

  def run_workflow_url(workflow_version)
    if workflow_version.workflow_class_title == 'Galaxy'
      "#{Seek::Config.galaxy_instance_trs_import_url}&trs_id=#{workflow_version.parent.id}&trs_version=#{workflow_version.version}"
    end
  end

  def workflow_class_options_for_select(selected = nil)
    opts = WorkflowClass.order(:title).map do |c|
      extra = {}
      exts = c.extractor_class&.file_extensions
      extra['data-file-extensions'] = exts.join(' ') if exts.any?
      [c.title, c.id, extra]
    end

    options_for_select(opts, selected)
  end

  def bio_tools_url(tool)
    BioTools::Client.tool_url(tool.bio_tools_id)
  end
end
