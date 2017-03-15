module RdfHelper
  def asset_rdf
    eval('@' + controller_name.singularize).to_rdf
  end
end
