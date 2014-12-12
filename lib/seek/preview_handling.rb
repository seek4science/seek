module Seek
  module PreviewHandling
    def preview
      element = params[:element]
      item = controller_name.classify.constantize.find_by_id(params[:id])
      partial = preview_partial
      render :update do |page|
        if item.try :can_view?
          page.replace_html element, partial: partial, locals: { resource: item }
        else
          page.replace_html element, text: 'Nothing is selected to preview.'
        end
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
