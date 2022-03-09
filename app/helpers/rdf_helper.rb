module RdfHelper
  include ApplicationHelper
  def asset_rdf
    resource_for_controller.to_rdf
  end

  def schema_ld_script_block
    resource = determine_resource_for_schema_ld

    if resource && resource.respond_to?(:schema_org_supported?) && resource.schema_org_supported?
      begin
        content_tag :script, type: 'application/ld+json' do
          resource.to_schema_ld.html_safe
        end
      rescue StandardError => exception
        raise exception if Rails.env.development?
        data={}
        data[:message] = 'Error embedding Schema JSON-LD into page HEAD'
        data[:item] = resource.inspect
        Seek::Errors::ExceptionForwarder.send_notification(exception, data:data)
        ''
      end
    end
  end

  def determine_resource_for_schema_ld
    if controller_name=='homes' && action_name=='index'
      Seek::BioSchema::DataCatalogMockModel.new
    elsif action_name == 'show'
      versioned_resource_for_controller || resource_for_controller
    end
  end

end
