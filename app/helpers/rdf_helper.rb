module RdfHelper
  def asset_rdf
    eval('@' + controller_name.singularize).to_rdf
  end

  # FIXME: currently experimental and may not be used.
  def json_ld_script_block
    resource = eval('@' + controller_name.singularize)
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
    return unless action_name == 'show'
    resource = eval('@' + controller_name.singularize)
    if resource.respond_to?(:schema_org_supported?) && resource.schema_org_supported?
      begin
        content_tag :script, type: 'application/ld+json' do
          resource.to_schema_ld.html_safe
        end
      rescue Exception => exception
        raise exception
        data={}
        data[:message] = 'Error embedding Schema JSON-LD into page HEAD'
        data[:item] = resource.inspect
        Seek::Errors::ExceptionForwarder.send_notification(exception, data)
        ''
      end
    end
  end

end
