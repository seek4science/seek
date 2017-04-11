module Seek
  module BreadCrumbs
    def self.included(base)
      base.before_filter :add_breadcrumbs
    end

    def add_breadcrumbs
      # Home
      add_breadcrumb 'Home', :root_path
      # process for nested attributes
      if controller_name == 'studied_factors'
        add_index_breadcrumb 'data_files'
        add_show_breadcrumb @data_file
      elsif controller_name == 'experimental_conditions'
        add_index_breadcrumb 'sops'
        add_show_breadcrumb @sop
      elsif controller_name == 'folders'
        add_index_breadcrumb 'projects'
        add_show_breadcrumb @project
      elsif controller_name == 'avatars'
        add_index_breadcrumb @avatar_for.pluralize.downcase
        add_show_breadcrumb @avatar_owner_instance
        add_edit_breadcrumb @avatar_owner_instance
      elsif controller_name == 'snapshots'
        add_index_breadcrumb @resource.class.name.downcase.pluralize
        add_show_breadcrumb @resource
        if @snapshot
          add_breadcrumb "Snapshot #{@snapshot.snapshot_number}",
                         polymorphic_path([@resource, @snapshot])
        end
        return
      elsif controller_name == 'samples'
        if @data_file
          add_index_breadcrumb 'data_files'
          add_show_breadcrumb @data_file
        elsif @sample_type
          add_index_breadcrumb 'sample_types'
          add_show_breadcrumb @sample_type
        end
      end

      # Index
      controller_name == 'studied_factors' ? add_index_breadcrumb(controller_name, 'Factors studied Index') : add_index_breadcrumb(controller_name)
      resource = eval('@' + controller_name.singularize) || try_block { controller_name.singularize.camelize.constantize.find_by_id(params[:id]) }

      add_show_breadcrumb resource if resource && resource.respond_to?(:new_record?) && !resource.new_record?

      unless action_name == 'index' || action_name == 'show'
        if action_name == 'new_object_based_on_existing_one'
          add_breadcrumb "New #{controller_name.humanize.singularize.downcase} based on this one", url_for(controller: controller_name, action: action_name, id: resource.try(:id))
        else
          if resource.nil?
            url = url_for(controller: controller_name, action: action_name)
          else
            url = url_for(controller: controller_name, action: action_name, id: resource.try(:id))
          end
          add_breadcrumb "#{action_name.capitalize.humanize}", url
        end
      end
    end

    def add_index_breadcrumb(controller_name, breadcrumb_name = nil)
      breadcrumb_name ||= "#{t(controller_name.singularize, default: controller_name.singularize.humanize).pluralize} Index"
      add_breadcrumb breadcrumb_name, url_for(controller: controller_name, action: 'index')
    end

    def add_show_breadcrumb(resource, breadcrumb_name = nil)
      unless resource.is_a?(ProjectFolder)
        breadcrumb_name ||= "#{resource.respond_to?(:title) ? resource.title : resource.id}"
        add_breadcrumb breadcrumb_name, url_for(controller: resource.class.name.underscore.pluralize, action: 'show', id: resource.id)
      end
    end

    def add_edit_breadcrumb(resource, breadcrumb_name = nil)
      breadcrumb_name ||= 'Edit'
      add_breadcrumb breadcrumb_name, url_for(controller: resource.class.name.underscore.pluralize, action: 'edit', id: resource.id)
    end
  end
end
