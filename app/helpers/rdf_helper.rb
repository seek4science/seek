module RdfHelper
  include ApplicationHelper
  include ResourceHelper

  def asset_rdf
    resource_for_controller.to_rdf
  end

  def schema_ld_script_block
    resource = determine_resource_for_schema_ld

    if resource.respond_to?(:schema_org_supported?) && resource&.schema_org_supported?
      begin
        content_tag :script, type: 'application/ld+json' do
          resource.to_schema_ld.html_safe
        end
      rescue StandardError => e
        raise e if Rails.env.development?

        Seek::Errors::ExceptionForwarder.send_notification(e,
                                                           data: {
                                                             message: 'Error embedding Schema JSON-LD into page HEAD',
                                                             item: resource.inspect
                                                           })
        ''
      end
    end
  end
end
