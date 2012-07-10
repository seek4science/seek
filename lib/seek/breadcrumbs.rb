module Seek
  module BreadCrumbs
    def self.included(base)
      base.before_filter :add_breadcrumbs
    end

    def add_breadcrumbs
      add_breadcrumb "Home", :root_path
      add_breadcrumb "#{controller_name.humanize} Index",send("#{controller_name}_path")
      @resource = eval("@"+controller_name.singularize) || controller_name.singularize.camelize.constantize.find_by_id(params[:id])
      add_breadcrumb "#{@resource.title}", send("#{controller_name.singularize}_path", @resource) if @resource

      add_breadcrumb "#{action_name.capitalize}", url_for(:controller => controller_name, :action => action_name, :id => @resource.try(:id)) unless action_name == 'index' || action_name == 'show'

    end
  end
end
