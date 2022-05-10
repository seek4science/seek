module RawDisplay
  extend ActiveSupport::Concern

  RAW_DISPLAY_FORMATS = %w(notebook markdown)

  def render_display(blob)
    renderer = Seek::Renderers.const_get("#{params[:display].classify}Renderer").new(blob)
    response.set_header('Content-Security-Policy', renderer.iframe_csp)
    render html: renderer.render_iframe_contents.html_safe, content_type: 'text/html', layout: renderer.iframe_layout
  end

  def can_display?
    RAW_DISPLAY_FORMATS.include?(params[:display])
  end
end
