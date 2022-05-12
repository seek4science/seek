module RawDisplay
  extend ActiveSupport::Concern

  RAW_DISPLAY_FORMATS = %w(notebook markdown pdf)

  def render_display(blob)
    if params[:display]
      renderer = Seek::Renderers.const_get("#{params[:display].classify}Renderer").new(blob)
    else
      renderer = Seek::Renderers::RendererFactory.instance.renderer(blob)
    end
    response.set_header('Content-Security-Policy', renderer.content_security_policy)
    render html: renderer.render_standalone.html_safe, content_type: 'text/html', layout: renderer.layout
  end

  def can_display?
    RAW_DISPLAY_FORMATS.include?(params[:display])
  end
end
