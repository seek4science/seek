module BootstrapHelper

  def icon_link_to(text, icon_key, url, options = {})
    icon = icon_tag(icon_key, options.delete(:icon_options) || {})
    link_to((icon + text).html_safe, url, options)
  end

  def button_link_to(text, icon, url, options = {})
    options[:class] = "btn #{options[:type] || 'btn-default'} #{options[:class]}".strip
    icon_link_to(text, icon, url, options)
  end

  def info_box(title, options = {})
    content_tag(:div, :class => "panel #{options[:type] || 'panel-default'}".strip) do
      content_tag(:div, :class => 'panel-heading') do
        title
      end +
      content_tag(:div, :class => 'panel-body') do
        yield
      end
    end
  end

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

  def admin_dropdown(text, icon_key = nil, options = {})
    opts = capture do
      yield
    end

    unless opts.blank?
      dropdown_button(text, icon_key, options) do
        opts
      end
    end
  end

  private

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
