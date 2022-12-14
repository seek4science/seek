module RawDisplay
  extend ActiveSupport::Concern

  RAW_DISPLAY_FORMATS = %w(notebook markdown pdf text image)

  # A method for rendering a given Git/Content Blob in an HTML "Viewer"
  def render_display(blob, url_options: {})
    if params[:display]
      renderer = Seek::Renderers.const_get("#{params[:display].classify}Renderer").new(blob, url_options: url_options)
    else
      renderer = Seek::Renderers::RendererFactory.instance.renderer(blob, url_options: url_options)
    end
    if renderer.can_render?
      # check if allowed by cookies
      unless renderer.is_remote? && !cookie_consent.allow_embedding?
        response.set_header('Content-Security-Policy', renderer.content_security_policy)
        render renderer.format => renderer.render_standalone.html_safe, layout: renderer.layout
      end
    else
      raise ActionController::UnknownFormat
    end
  end

  def render_display?
    RAW_DISPLAY_FORMATS.include?(params[:display])
  end
end
