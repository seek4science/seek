module Seek
  module NestedFilters
    extend ActiveSupport::Concern

    module ClassMethods
      def support_nested_filters *actions
        actions.each do |action|
          define_method action do
            invoke_dynamic_nested_filter
          end
        end
      end
    end

    def invoke_dynamic_nested_filter
      model = action_name.classify.constantize
      if model.respond_to?(:all_authorized_for)
        objects = model.all_authorized_for("view")
      else
        objects = model.all
      end

      objects = model.paginate_after_fetch(objects,:page=>"all")
      filter={}
      filter[controller_name.singularize]=params[:id]
      params[:filter]=filter
      objects = apply_filters(objects)
      objects = model.paginate_after_fetch(objects,:page=>"all")
      eval("@#{action_name}=objects")
      render "/#{action_name}/index",:page=>"all"
    end
  end
end

ActionController::Base.class_eval do
  include Seek::NestedFilters
end
