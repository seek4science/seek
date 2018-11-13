module RdfHelper
  def asset_rdf
    eval('@' + controller_name.singularize).to_rdf
  end

  def json_ld_script_block
    resource = eval('@' + controller_name.singularize)
    if resource && resource.rdf_supported?
      begin
        content_tag :script,type:'application/ld+json' do
          json_ld(resource)
        end
      rescue
        ''
      end
    end
  end

  def json_ld resource
    resource.to_json_ld.html_safe
  end
end
