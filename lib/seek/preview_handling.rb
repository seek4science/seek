module Seek
  module PreviewHandling
    def preview
      @element = params[:element]
      @item = controller_model.find_by_id(params[:id])
      @partial = preview_partial

      respond_to do |format|
        format.js { render template: 'assets/preview' }
      end
    end

    # determine if a specific partial exists for the controller, otherwise use the general assets/resource_preview partial
    def preview_partial
      if lookup_context.find_all("#{controller_name}/_resource_preview").any?
        "#{controller_name}/resource_preview"
      else
        'assets/resource_preview'
      end
    end
  end
end
