require 'seek/annotation_common'

module Seek
  module AssetsCommon
    include Seek::AnnotationCommon
    include Seek::ContentBlobCommon
    include Seek::PreviewHandling
    include Seek::AssetsStandardControllerActions

    def find_display_asset(asset = instance_variable_get("@#{controller_name.singularize}"))
      requested_version = params[:version] || asset.latest_version.version
      found_version = asset.find_version(requested_version)
      if !found_version || anonymous_request_for_previous_version?(asset, requested_version)
        error('This version is not available', 'invalid route')
        return false
      else
        instance_variable_set("@display_#{asset.class.name.underscore}", asset.find_version(found_version))
      end
    end

    def anonymous_request_for_previous_version?(asset, requested_version)
      (!User.logged_in_and_member? && requested_version.to_i != asset.latest_version.version)
    end

    def update_relationships(asset, params)
      Relationship.set_attributions(asset, params[:attributions])
    end

    def request_resource
      resource = class_for_controller_name.find(params[:id])
      details = params[:details]
      mail = Mailer.request_resource(current_user, resource, details)
      mail.deliver_later

      @resource = resource
      respond_to do |format|
        format.js { render template: 'assets/request_resource' }
      end
    end


    def request_contact
      resource = class_for_controller_name.find(params[:id])
      details = params[:details]
      mail = Mailer.request_contact(current_user, resource, details)
      mail.deliver_later
      MessageLog.log_contact_request(current_user.person, resource, details)
      @resource = resource
      respond_to do |format|
        format.js { render template: 'assets/request_contact' }
      end
    end

    # For use in autocompleters
    def typeahead
      model_name = controller_name.classify
      model_class = class_for_controller_name

      results = model_class.where('title LIKE ?', "#{params[:query]}%").authorized_for('view')
      items = results.first(params[:limit] || 10).map do |item|
        contributor_name = item.contributor.try(:person).try(:name)
        { id: item.id, name: item.title, hint: contributor_name, type: model_name, contributor: contributor_name }
      end

      respond_to do |format|
        format.json { render json: items.to_json }
      end
    end

    # the page to return to on an update validation failure, default to 'edit' if the referer is not found
    def update_validation_error_return_action
      previous = Rails.application.routes.recognize_path(request.referrer)
      if previous && previous[:action]
        previous[:action] || 'edit'
      else
        'edit'
      end
    end

    def params_for_controller
      name = controller_name.singularize
      method = "#{name}_params"
      send(method)
    end
  end
end
