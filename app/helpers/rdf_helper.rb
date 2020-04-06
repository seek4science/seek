module RdfHelper
  include ApplicationHelper
  def asset_rdf
    resource_for_controller.to_rdf
  end

  # FIXME: currently experimental and may not be used.
  def json_ld_script_block
    resource = resource_for_controller
    if resource && resource.rdf_supported?
      begin
        content_tag :script, type: 'application/ld+json' do
          resource.to_json_ld.html_safe
        end
      rescue Exception => exception
        data={}
        data[:message] = 'Error embedding JSON-LD into page HEAD'
        data[:item] = resource.inspect
        Seek::Errors::ExceptionForwarder.send_notification(exception, data)
        ''
      end
    end
  end

  def schema_ld_script_block
    resource = determine_resource_for_schema_ld

    if resource && resource.respond_to?(:schema_org_supported?) && resource.schema_org_supported?
      begin
        content_tag :script, type: 'application/ld+json' do
          resource.to_schema_ld.html_safe
        end
      rescue Exception => exception
        data={}
        data[:message] = 'Error embedding Schema JSON-LD into page HEAD'
        data[:item] = resource.inspect
        Seek::Errors::ExceptionForwarder.send_notification(exception, data)
        ''
      end
    end
  end

  def determine_resource_for_schema_ld
    if controller_name=='homes' && action_name=='index'
      Seek::BioSchema::DataCatalogueMockModel.new
    elsif action_name == 'show'
      resource_for_controller
    end
  end

end
