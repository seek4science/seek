module BootstrapHelper
  include ImagesHelper

  # A link with an icon next to it
  def icon_link_to(text, icon_key, url, options = {})
    icon = icon_tag(icon_key, options.delete(:icon_options) || {})
    disabled_reason = options.delete(:disabled_reason)
    options[:class] = "#{options[:class]} disabled".strip if disabled_reason
    inner = if url
              link_to((icon + text).html_safe, url, options)
            else
              content_tag(:a, (icon + text).html_safe, options)
            end

    if disabled_reason
      content_tag(:span, 'data-tooltip' => disabled_reason, onclick: "alert('#{disabled_reason}');") do
        inner
      end
    else
      inner
    end
  end

  # A button with an icon and text
  def button_link_to(text, icon, url, options = {})
    options[:class] = "btn #{options[:type] || 'btn-default'} #{options[:class]}".strip
    icon_link_to(text, icon, url, options)
  end

  # A collapsible panel
  def folding_panel(title = nil, collapsed = false, options = {}, &block)
    title += " <span class=\"#{collapsed ? 'caret' : 'caret-up'}\"></span>".html_safe

    options[:collapsible] = true
    options[:heading_options] =
      merge_options({ :class => 'clickable collapsible', 'data-toggle' => 'collapse-next' }, options[:heading_options])
    options[:collapse_options] = { :class => 'panel-collapse collapse', 'aria-expanded' => true }
    if collapsed
      options[:heading_options][:class] += ' collapsed'
      options[:collapse_options]['aria-expanded'] = false
    else
      options[:collapse_options][:class] += ' in'
    end

    panel(title, options, &block)
  end

  # A panel with a heading section and body
  def panel(title = nil, options = {}, &block)
    heading_options = merge_options({ class: 'panel-heading' }, options.delete(:heading_options))
    body_options = merge_options({ class: 'panel-body' }, options.delete(:body_options))
    options = merge_options({ class: "panel #{options[:type] || 'panel-default'}" }, options)

    # The body of the panel
    body = content_tag(:div, body_options, &block)

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
        title_html << "#{help_icon(help_text)} "
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
  def dropdown_button(text, icon_key = nil, options = {}, &block)
    content_tag(:div, class: 'btn-group') do
      content_tag(:div, :type => 'button', :class => "btn dropdown-toggle #{options[:type] || 'btn-default'}".strip,
                        'data-toggle' => 'dropdown', 'aria-expanded' => 'false', 'data-tooltip' => options[:tooltip]) do
        ((icon_key ? icon_tag(icon_key, options.delete(:icon_options) || {}) : '') +
            text + ' <span class="caret"></span>'.html_safe)
      end +
        content_tag(:ul,
                    merge_options({ class: 'dropdown-menu text-left', role: 'menu' }, options.delete(:menu_options)), &block)
    end
  end

  # A dropdown menu for admin commands. Will not display if the content is blank.
  # (Saves having to check privileges twice)
  def item_actions_dropdown(text = t('actions_button'), icon = 'actions', &block)
    opts = capture(&block)

    unless opts.blank?
      dropdown_button(text, icon, menu_options: { class: 'pull-right', id: 'item-admin-menu' }) do
        opts
      end
    end
  end

  def tags_input(element_name, existing_tags = [], options = {})
    options = update_tags_input_options(options)
    objects_input(element_name, existing_tags, options, :to_s, :to_s)
  end

  def objects_input(element_name, existing_objects = [], options = {}, value_method = :id, text_method = :title)
    options['data-role'] = 'seek-objectsinput'
    options['data-tags-limit'] = options.delete(:limit) if options[:limit]
    options['data-allow-new-items'] = options.delete(:allow_new) if options[:allow_new]
    options['data-placeholder'] = options.delete(:placeholder) if options[:placeholder]
    options[:include_blank] = ''
    options[:multiple] = true
    options[:name] = "#{element_name}[]" unless options.key?(:name)
    options.merge!(typeahead_options(options.delete(:typeahead))) if options[:typeahead]

    select_options = options_from_collection_for_select(
      existing_objects,
      value_method, text_method,
      existing_objects.collect { |obj| obj.send(value_method) }
    )

    hidden_field_tag(element_name, '', name: options[:name]) +
      select_tag(element_name,
                 select_options,
                 options)
  end

  def modal(options = {}, &block)
    opts = merge_options({ class: 'modal', role: 'dialog', tabindex: -1 }, options)

    dialog_class = 'modal-dialog'
    if (size = options.delete(:size))
      dialog_class += " modal-#{size}"
    end

    content_tag(:div, opts) do
      content_tag(:div, class: dialog_class) do
        content_tag(:div, class: 'modal-content', &block)
      end
    end
  end

  def modal_header(title, _options = {})
    content_tag(:div, class: 'modal-header') do
      content_tag(:button, class: 'close', 'data-dismiss' => 'modal', 'aria-label' => 'Close') do
        content_tag(:span, '&times;'.html_safe, 'aria-hidden' => 'true')
      end +
        content_tag(:h4, title, class: 'modal-title')
    end
  end

  def modal_body(options = {})
    opts = merge_options({ class: 'modal-body' }, options)
    content_tag(:div, opts) do
      yield if block_given?
    end
  end

  def modal_footer(options = {})
    opts = merge_options({ class: 'modal-footer' }, options)
    content_tag(:div, opts) do
      yield if block_given?
    end
  end

  def tab(*args, disabled_reason: nil, &block)
    if block_given?
      tab_id, selected = *args
      title = nil
    else
      title, tab_id, selected = *args
    end

    selected = show_page_tab == tab_id if selected.nil?

    tab_options = {}
    link_options = {
      data: { target: "##{tab_id}",
              toggle: 'tab' },
      aria: { controls: tab_id },
      role: 'tab'
    }

    if disabled_reason
      tab_options[:class] = 'disabled'
      tab_options['data-tooltip'] = disabled_reason
      tab_options[:onclick] = "alert('#{disabled_reason}');";
      link_options = {}
    elsif selected
      tab_options[:class] = 'active'
    end

    content_tag(:li, **tab_options) do
      if block_given?
        content_tag(:a, **link_options, &block)
      else
        content_tag(:a, title, **link_options, role: 'tab')
      end
    end
  end

  def tab_pane(tab_id, selected = nil, &block)
    selected = show_page_tab == tab_id if selected.nil?

    content_tag(:div, id: tab_id, class: selected ? 'tab-pane fade in active' : 'tab-pane fade', &block)
  end

  private

  # sets the default options for tags, including the query_url according to type unless already specified
  # if typeahead is set to false, there will be no autocomplete or querying
  def update_tags_input_options(options)
    options[:allow_new] = true unless options.key?(:allow_new)

    if options[:typeahead] == false
      options.delete(:typeahead)
    else
      typeahead = options[:typeahead] ||= {}

      unless typeahead[:query_url]
        typeahead[:query_url] = if typeahead[:type]
                                  query_tags_path(type: typeahead.delete(:type))
                                else
                                  query_tags_path
                                end
      end
    end

    options
  end

  def typeahead_options(typeahead_opts)
    options = {}

    options['data-typeahead-local-values'] = typeahead_opts[:values].to_json if typeahead_opts[:values]
    options['data-typeahead-query-url'] = typeahead_opts[:query_url] if typeahead_opts[:query_url]

    options['data-typeahead-template'] = typeahead_opts[:handlebars_template] if typeahead_opts[:handlebars_template]

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
