module BootstrapHelper

  def icon_link_to(text, icon, url, options = {})
    filename = icon_filename_for_key(icon)
    icon_options = options.delete(:icon_options) || {}
    icon_options[:class] = "icon #{icon_options[:class]}".strip
    icon_options[:alt] ||= text

    link_to((image_tag(filename, icon_options) + text).html_safe, url, options)
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

end
