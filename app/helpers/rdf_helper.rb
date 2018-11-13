module RdfHelper
  def asset_rdf
    eval('@' + controller_name.singularize).to_rdf
  end

  def json_ld resource
    resource.to_json_ld.html_safe
  end
end
