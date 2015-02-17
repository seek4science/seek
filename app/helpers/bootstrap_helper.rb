module BootstrapHelper

  # A link with an icon next to it
  def icon_link_to(text, icon_key, url, options = {})
    icon = icon_tag(icon_key, options.delete(:icon_options) || {})
    link_to((icon + text).html_safe, url, options)
  end

  # A button with an icon and text
  def button_link_to(text, icon, url, options = {})
    options[:class] = "btn #{options[:type] || 'btn-default'} #{options[:class]}".strip
    icon_link_to(text, icon, url, options)
  end

  # A collapsible panel
  def folding_panel(title = nil, collapsed = false, options = {})
    options = options.merge(:collapsible => true, :collapsed => collapsed)
    panel(title, options) do
      yield
    end
  end

  # A panel with a heading section and body
  def panel(title = nil, options = {})
    collapsible = options.delete(:collapsible)
    collapse_options = {}

    if collapsible
      collapsed = options.delete(:collapsed)
      options[:heading_options] = merge_options({:class => 'clickable collapsible', 'data-toggle' => 'collapse-next'}, options[:heading_options])
      collapse_options = {:class => 'panel-collapse collapse', 'aria-expanded' => true}
      if collapsed
        options[:heading_options][:class] += ' collapsed'
        collapse_options['aria-expanded'] = false
      else
        collapse_options[:class] += ' in'
      end
    end

    heading_options = merge_options({:class => 'panel-heading'}, options.delete(:heading_options))
    body_options = merge_options({:class => 'panel-body'}, options.delete(:body_options))
    options = merge_options({:class => "panel #{options[:type] || 'panel-default'}"}, options)

    content_tag(:div, options) do
      if title
        content_tag(:div, heading_options) do
          title_html = ""
          unless (help_text = options.delete(:help_text)).nil?
            title_html << help_icon(help_text) + " "
          end
          title_html << title
          title_html << ' <span class="caret"></span>' if collapsible
          title_html.html_safe
        end +
        if collapsible
          content_tag(:div, collapse_options) do
            content_tag(:div, body_options) do
              yield
            end
          end
        else
          content_tag(:div, body_options) do
            yield
          end
        end
      else
        content_tag(:div, body_options) do
          yield
        end
      end
    end
  end

  # A coloured information box with an X button to close it
  def alert_box(style = 'info', options = {}, &block)
    content_tag(:div, merge_options(options, {:class => "alert alert-#{style} alert-dismissable", :role => 'alert'})) do
      dismiss_button + capture(&block)
    end
  end

  # A button that displays a dropdown menu when clicked
  def dropdown_button(text, icon_key = nil, options = {})
    content_tag(:div, :class => "btn-group") do
      content_tag(:div, :type => 'button', :class => "btn dropdown-toggle #{options[:type] || 'btn-default'}".strip,
                  'data-toggle' => 'dropdown', 'aria-expanded' => 'false') do
        ((icon_key ? icon_tag(icon_key, options.delete(:icon_options) || {}) : '') +
        text + ' <span class="caret"></span>'.html_safe)
      end +
      content_tag(:ul, merge_options({:class => 'dropdown-menu', :role => 'menu'}, options.delete(:menu_options))) do
        yield
      end
    end
  end

  # A dropdown menu for admin commands. Will not display if the content is blank.
  # (Saves having to check privileges twice)
  def admin_dropdown(text = 'Administration', icon = 'manage')
    opts = capture do
      yield
    end

    unless opts.blank?
      dropdown_button(text, icon, {:menu_options => {:class => 'pull-right'}}) do
        opts
      end
    end
  end

  def tags_input(name, existing_tags, options = {})
    text_field_tag(name, existing_tags.join(','), options.merge('data-role' => 'tagsinput'))
  end

  private

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
