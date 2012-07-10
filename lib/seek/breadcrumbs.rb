module Seek
  module BreadCrumbs
    def self.included(base)
      base.before_filter :set_resource, :except => :index
      base.class_eval do
         alias_method_chain :index, :breadcrumb
         alias_method_chain :show, :breadcrumb
         alias_method_chain :new, :breadcrumb
         alias_method_chain :edit, :breadcrumb
      end
    end


    def index_with_breadcrumb
      add_breadcrumb "Home", :root_path
      add_breadcrumb "#{controller_name.humanize} index",send("#{controller_name.downcase.underscore}_path")
      index_without_breadcrumb
    end

    def show_with_breadcrumb
      add_breadcrumb "Home", :root_path
      add_breadcrumb "#{controller_name.humanize} index",send("#{controller_name.downcase.underscore}_path")
      add_breadcrumb "#{@resource.title}", send("#{controller_name.downcase.underscore.singularize}_path", @resource)
      show_without_breadcrumb
    end

    def new_with_breadcrumb
      add_breadcrumb "Home", :root_path
      add_breadcrumb "#{controller_name.humanize} index",send("#{controller_name.downcase.underscore}_path")
      add_breadcrumb "New", send("new_#{controller_name.downcase.underscore.singularize}_path", @resource)
      new_without_breadcrumb
    end

    def edit_with_breadcrumb
      add_breadcrumb "Home", :root_path
      add_breadcrumb "#{controller_name.humanize} index",send("#{controller_name.downcase.underscore}_path")
      add_breadcrumb "#{@resource.title}", send("#{controller_name.downcase.underscore.singularize}_path", @resource)
      add_breadcrumb "Edit", send("edit_#{controller_name.downcase.underscore.singularize}_path", @resource)
      edit_without_breadcrumb
    end

    def set_resource
      c = self.controller_name.downcase
      @resource = eval("@"+c.singularize)
    end
  end
end