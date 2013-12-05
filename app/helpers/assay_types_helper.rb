#encoding: utf-8
module AssayTypesHelper

  def link_to_assay_type assay
    uri = assay.assay_type_uri
    label = assay.assay_type_label
    unless uri.nil?
      link_to label,assay_types_path(:uri=>uri,:label=>label)
    else
      label
    end
  end

  def child_assay_types_list_links children
    child_type_links children,"assay_type"
  end

  def child_type_links children,type
    unless children.empty?
      children.collect do |child|
        uris = child.flatten_hierarchy.collect{|o| o.uri.to_s}
        assays = Assay.where("#{type}_uri".to_sym => uris)
        n = Assay.authorize_asset_collection(assays,"view").count
        link_to h(child.label)+" (#{n})",assay_types_path(:uri=>child.uri,:label=>child.label)
      end.join(" | ").html_safe
    else
      content_tag :span,"No child terms",:class=>"none_text"
    end
  end

end