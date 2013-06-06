
module AjaxHelper

  def link_to_with_callbacks name, options={}, html_options={}
    html_options = html_options.merge(:onclick=> remote_function(options))
    html_options = html_options.merge(:remote => true) if html_options[:remote].nil?
    link_to name, "#", html_options
  end

  def button_to_with_callbacks name, options={}, html_options={}

    html_options[:value]=name
    html_options[:onclick]=remote_function(options)
    html_options[:type]="button"
    html = tag("input",html_options)

    html.html_safe
  end

  def form_tag_with_callbacks url_for_options = {}, options = {}, &block
    loading = options.delete(:loading)
    id = options[:id]
    html = form_tag url_for_options, options, &block
    html << render(:template=>"misc/form_tag_callbacks",:locals=>{:id=>id, :loading=>loading})


    html
  end

end
