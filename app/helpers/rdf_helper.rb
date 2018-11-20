module RdfHelper
  def asset_rdf
    eval('@' + controller_name.singularize).to_rdf
  end

  def json_ld_script_block
    resource = eval('@' + controller_name.singularize)
    if resource && resource.rdf_supported?
      begin
        content_tag :script, type: 'application/ld+json' do
          resource.to_json_ld.html_safe
        end
      rescue Exception => exception
        if Seek::Config.exception_notification_enabled
          data[:message] = 'Error embedding JSON-LD into page HEAD'
          data[:item] = resource.inspect
          ExceptionNotifier.notify_exception(exception, data: data)
        end
        ''
      end
    end
  end

  def schema_ld_script_block
    resource = eval('@' + controller_name.singularize)
    if resource && resource.schema_org_supported?
      #begin
        content_tag :script, type: 'application/ld+json' do
          resource.to_schema_ld.html_safe
        end
      # rescue Exception => exception
      #   if Seek::Config.exception_notification_enabled
      #     data[:message] = 'Error embedding Schema JSON-LD into page HEAD'
      #     data[:item] = resource.inspect
      #     ExceptionNotifier.notify_exception(exception, data: data)
      #   end
      #   ''
      # end
    end
  end

  def json_ld(resource)

  end
end
