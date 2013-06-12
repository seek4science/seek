
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
    js = form_callback_javascript options
    html = form_tag(url_for_options, options, &block)
    html << js
    html
  end

  def form_for_with_callbacks record, options={}, &block
    js = form_callback_javascript options
    html = form_for record, options, &block
    html << js
    html
  end

  private

  def form_callback_javascript options
    loading = options.delete(:loading)
    before = options.delete(:before)
    complete = options.delete(:loaded)
    complete ||= options.delete(:complete)
    success = options.delete(:success)
    failure = options.delete(:failure)
    after = options.delete(:after)
    id = options[:id]
    id ||= options[:html][:id] if options[:html]
    success_update_element = options[:update][:success] if options[:update]
    failure_update_element = options[:update][:failure] if options[:update]

    render(:template=>"general/form_tag_callbacks",:locals=>{:id=>id,
                                                          :before=>before,
                                                          :loading=>loading,
                                                          :complete=>complete,
                                                          :after=>after,
                                                          :success=>success,
                                                          :failure=>failure,
                                                          :success_update_element=>success_update_element,
                                                          :failure_update_element=>failure_update_element

    })
  end




end
