module Seek
  module BreadCrumbs
    def self.included(base)
      base.before_action :add_breadcrumbs
    end

    # FIXME: badly needs refactoring, this code is wrong in so many ways:
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
      elsif controller_name == 'nels'
        add_index_breadcrumb 'assays'
        add_show_breadcrumb @assay
      elsif %w[compounds suggested_assay_types suggested_technology_types site_announcements].include?(controller_name)
        add_index_breadcrumb('admin', 'Administration')
      elsif controller_name == 'stats'
        add_index_breadcrumb 'projects'
        add_show_breadcrumb @project
        add_breadcrumb 'Dashboard'
        return
      end

      # Index
      case controller_name
      when 'studied_factors'
        add_index_breadcrumb(controller_name, 'Factors studied Index')
      when 'admin'
        add_index_breadcrumb(controller_name, 'Administration')
      when 'site_announcements'
        add_index_breadcrumb(controller_name, 'Announcements')
      when 'suggested_assay_types'
        add_index_breadcrumb(controller_name, 'Assay types')
      when 'suggested_technology_types'
        add_index_breadcrumb(controller_name, 'Technology types')
      else
        add_parent_breadcrumb if @parent_resource
        add_index_breadcrumb(controller_name)
      end
      resource = eval('@' + controller_name.singularize) || try_block { controller_name.singularize.camelize.constantize.find_by_id(params[:id]) }

      add_show_breadcrumb resource if resource && resource.respond_to?(:new_record?) && !resource.new_record?

      unless action_name == 'index' || action_name == 'show'
        case action_name
        when 'new_object_based_on_existing_one'
          breadcrumb_name = "New #{controller_name.humanize.singularize.downcase} based on this one"
        when 'create_content_blob'
          breadcrumb_name = "New #{controller_name.humanize.singularize.downcase} details"
        else
          breadcrumb_name = action_name.capitalize.humanize
        end
        url = if resource.nil?
                url_for(controller: controller_name, action: action_name)
              else
                url_for(controller: controller_name, action: action_name, id: resource.try(:id))
              end
        add_breadcrumb breadcrumb_name, url
      end
    end

    def add_index_breadcrumb(controller_name, breadcrumb_name = nil)
      breadcrumb_name ||= "#{t(controller_name.singularize, default: controller_name.singularize.humanize).pluralize} Index"
      add_breadcrumb breadcrumb_name, url_for(controller: controller_name, action: 'index')
    end

    def add_show_breadcrumb(resource, breadcrumb_name = nil)
      unless resource.is_a?(ProjectFolder)
        breadcrumb_name ||= (resource.respond_to?(:title) ? resource.title : resource.id).to_s
        add_breadcrumb breadcrumb_name, url_for(controller: resource.class.name.underscore.pluralize, action: 'show', id: resource.id)
      end
    end

    def add_edit_breadcrumb(resource, breadcrumb_name = nil)
      breadcrumb_name ||= 'Edit'
      add_breadcrumb breadcrumb_name, url_for(controller: resource.class.name.underscore.pluralize, action: 'edit', id: resource.id)
    end

    def add_parent_breadcrumb
      add_index_breadcrumb @parent_resource.class.name.underscore.pluralize
      add_show_breadcrumb @parent_resource
    end
  end
end
