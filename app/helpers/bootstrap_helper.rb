module BootstrapHelper
  include ImagesHelper

  # A link with an icon next to it
  def icon_link_to(text, icon_key, url, options = {})
    icon = icon_tag(icon_key, options.delete(:icon_options) || {})
    unless url
      content_tag(:a, (icon + text).html_safe, options)
    else
      link_to((icon + text).html_safe, url, options)
    end
  end

  # A button with an icon and text
  def button_link_to(text, icon, url, options = {})
    options[:class] = "btn #{options[:type] || 'btn-default'} #{options[:class]}".strip
    if (reason = options.delete(:disabled_reason))
      options[:class] += ' disabled'
      content_tag(:span, 'data-tooltip' => reason, onclick: "alert('#{reason}');") do
        icon_link_to(text, icon, url, options)
      end
    else
      icon_link_to(text, icon, url, options)
    end
  end

  # A collapsible panel
  def folding_panel(title = nil, collapsed = false, options = {})
    title += " <span class=\"#{collapsed ? 'caret' : 'caret-up'}\"></span>".html_safe

    options[:collapsible] = true
    options[:heading_options] = merge_options({ :class => 'clickable collapsible', 'data-toggle' => 'collapse-next' }, options[:heading_options])
    options[:collapse_options] = { :class => 'panel-collapse collapse', 'aria-expanded' => true }
    if collapsed
      options[:heading_options][:class] += ' collapsed'
      options[:collapse_options]['aria-expanded'] = false
    else
      options[:collapse_options][:class] += ' in'
    end

    panel(title, options) do
      yield
    end
  end

  # A panel with a heading section and body
  def panel(title = nil, options = {})
    heading_options = merge_options({ class: 'panel-heading' }, options.delete(:heading_options))
    body_options = merge_options({ class: 'panel-body' }, options.delete(:body_options))
    options = merge_options({ class: "panel #{options[:type] || 'panel-default'}" }, options)

    # The body of the panel
    body = content_tag(:div, body_options) do
      yield
    end

    content_tag(:div, options) do # The panel wrapper
      if title
        panel_title(title, options, heading_options)
      else
        ''.html_safe
      end +
        if options.delete(:collapsible)
          content_tag(:div, body, options.delete(:collapse_options)) # The "collapse" wrapper around the body
        else
          body
        end
    end
  end

  def panel_title(title, options, heading_options)
    content_tag(:div, heading_options) do # The panel title
      title_html = ''
      if (help_text = options.delete(:help_text))
        title_html << help_icon(help_text) + ' '
      end
      title_html << title
      title_html.html_safe
    end
  end

  # A coloured information box with an X button to close it
  def alert_box(style = 'info', options = {}, &block)
    hide_button = options.delete(:hide_button)
    content_tag(:div, merge_options(options, class: "alert alert-#{style} alert-dismissable", role: 'alert')) do
      if hide_button
        capture(&block)
      else
        dismiss_button + capture(&block)
      end
    end
  end

  # A button that displays a dropdown menu when clicked
  def dropdown_button(text, icon_key = nil, options = {})

    content_tag(:div, class: 'btn-group') do
      content_tag(:div, :type => 'button', :class => "btn dropdown-toggle #{options[:type] || 'btn-default'}".strip,
                        'data-toggle' => 'dropdown', 'aria-expanded' => 'false','data-tooltip'=>options[:tooltip]) do
        ((icon_key ? icon_tag(icon_key, options.delete(:icon_options) || {}) : '') +
            text + ' <span class="caret"></span>'.html_safe)
      end +
        content_tag(:ul, merge_options({ class: 'dropdown-menu text-left', role: 'menu' }, options.delete(:menu_options))) do
          yield
        end
    end
  end

  # A dropdown menu for admin commands. Will not display if the content is blank.
  # (Saves having to check privileges twice)
  def item_actions_dropdown(text = t('actions_button'), icon = 'actions')
    opts = capture do
      yield
    end

    unless opts.blank?
      dropdown_button(text, icon, menu_options: { class: 'pull-right', id: 'item-admin-menu' }) do
        opts
      end
    end
  end

  def tags_input(name, existing_tags = [], options = {})
    options['data-role'] = 'seek-tagsinput'
    options['data-tags-limit'] = options.delete(:limit) if options[:limit]
    options.merge!(tags_input_typeahead_options(options.delete(:typeahead))) if options[:typeahead]

    text_field_tag(name, existing_tags.join(','), options)
  end

  def objects_input(name, existing_objects = [], options = {})
    options['data-role'] = 'seek-objectsinput'
    options['data-tags-limit'] = options.delete(:limit) if options[:limit]
    options.merge!(typeahead_options(options.delete(:typeahead))) if options[:typeahead]

    unless existing_objects.empty?
      if existing_objects.is_a?(String)
        options['data-existing-objects'] = existing_objects
      else
        options['data-existing-objects'] = existing_objects.map { |object| { id: object.id, name: object.try(:name) || object.try(:title) } }.to_json
      end
    end

    text_field_tag(name, nil, options)
  end

  def modal(options = {})
    opts = merge_options({ class: 'modal', role: 'dialog', tabindex: -1 }, options)

    dialog_class = 'modal-dialog'
    if (size = options.delete(:size))
      dialog_class += " modal-#{size}"
    end

    content_tag(:div, opts) do
      content_tag(:div, class: dialog_class) do
        content_tag(:div, class: 'modal-content') do
          yield
        end
      end
    end
  end

  def modal_header(title, _options = {})
    content_tag(:div, class: 'modal-header') do
      content_tag(:button, class:'close', 'data-dismiss' => 'modal', 'aria-label' => 'Close') do
        content_tag(:span, '&times;'.html_safe, 'aria-hidden' => 'true')
      end +
        content_tag(:h4, title, class: 'modal-title')
    end
  end

  def modal_body(options = {})
    opts = merge_options({ class: 'modal-body' }, options)
    content_tag(:div, opts) do
      yield
    end
  end

  def modal_footer(options = {})
    opts = merge_options({ class: 'modal-footer' }, options)
    content_tag(:div, opts) do
      yield
    end
  end

  private

  def tags_input_typeahead_options(typeahead_opts)
    options = typeahead_options(typeahead_opts)

    original_opts = typeahead_opts.is_a?(TrueClass) ? {} : typeahead_opts

    unless options.key?('data-typeahead-local-values')
      unless options.key?('data-typeahead-prefetch-url')
        options['data-typeahead-prefetch-url'] = if original_opts[:type]
          latest_tags_path(type: original_opts[:type])
        else
          latest_tags_path
        end
      end

      unless options.key?('data-typeahead-query-url')
        options['data-typeahead-query-url'] = if original_opts[:type]
          (query_tags_path(type: original_opts[:type]) + '&query=%QUERY').html_safe # this is the only way i've found to stop rails escaping %QUERY into %25QUERY:
        else
          (query_tags_path + '?query=%QUERY').html_safe
        end
      end
    end

    options
  end

  def typeahead_options(typeahead_opts)
    typeahead_opts = {} if typeahead_opts.is_a?(TrueClass)
    options = {}
    options['data-typeahead'] = true
    options[:placeholder] ||= ' ' * 20
    if typeahead_opts[:values]
      options['data-typeahead-local-values'] = typeahead_opts[:values].to_json
    else
      options['data-typeahead-prefetch-url'] = typeahead_opts[:prefetch_url] if typeahead_opts[:prefetch_url]
      options['data-typeahead-query-url'] = typeahead_opts[:query_url] if typeahead_opts[:query_url]
    end

    if typeahead_opts[:handlebars_template]
      options['data-typeahead-template'] = typeahead_opts[:handlebars_template]
    end

    options
  end

  def dismiss_button
    content_tag(:button, :class => 'close', 'data-dismiss' => 'alert', 'aria-label' => 'Close') do
      content_tag(:span, '&times'.html_safe, 'aria-hidden' => 'true')
    end
  end

  def icon_tag(key, options = {})
    filename = icon_filename_for_key(key)
    options[:class] = "icon #{options[:class]}".strip
    image_tag(filename, options)
  end

  # Merge two option hashes, joining colliding values with a whitespace
  def merge_options(defaults, options = {})
    options ||= {}

    defaults.symbolize_keys!
    options.symbolize_keys!

    (defaults.keys & options.keys).each do |key|
      options[key] = "#{defaults[key]} #{options[key]}".strip
    end

    defaults.merge(options)
  end
end
