require 'seek/annotation_common'

module Seek
  module AssetsCommon
    extend ActiveSupport::Concern

    include Seek::AnnotationCommon
    include Seek::ContentBlobCommon
    include Seek::PreviewHandling
    include Seek::AssetsStandardControllerActions

    included do
      after_action :fair_signposting, only: [:show], if: -> { Seek::Config.fair_signposting_enabled }

      user_content_actions :download
    end

    def find_display_asset(asset = instance_variable_get("@#{controller_name.singularize}"))
      found_version = params[:version] ? asset.find_version(params[:version]) : asset.latest_version
      if found_version&.visible?
        instance_variable_set("@display_#{asset.class.name.underscore}", found_version)
      else
        status =  found_version.nil? ? :not_found : :forbidden
        error('This version is not available', 'invalid route', status)
        false
      end
    end

    def update_relationships(asset, params)
      Relationship.set_attributions(asset, params[:attributions])
    end
    
    def request_contact
      resource = class_for_controller_name.find(params[:id])
      details = params[:details]
      mail = Mailer.request_contact(current_user, resource, details)
      mail.deliver_later
      ContactRequestMessageLog.log_request(sender:current_user.person, item:resource, details:details)
      @resource = resource
      respond_to do |format|
        format.js { render template: 'assets/request_contact' }
      end
    end

    # For use in autocompleters
    def typeahead
      query = params[:q] || ''
      model_name = controller_name.classify
      model_class = class_for_controller_name

      results = model_class.where('title LIKE ?', "%#{query}%").authorized_for('view')
      items = results.first(params[:limit] || 10).map do |item|
        contributor_name = item.contributor.try(:person).try(:name)
        { id: item.id, text: item.title, hint: contributor_name, type: model_name, contributor: contributor_name }
      end

      respond_to do |format|
        format.json { render json: {results: items}.to_json }
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
