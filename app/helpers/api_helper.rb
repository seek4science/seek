# BioCatalogue: app/helpers/api_helper.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics 
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.

module ApiHelper
  
  
  def xml_root_attributes
    { "xmlns" => "http://www.sysmo-db.org/2009/xml/rest",
      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
      "xsi:schemaLocation" => "http://www.sysmo-db.org/2009/xml/rest/schema-v1.xsd",
      "xmlns:xlink" => "http://www.w3.org/1999/xlink",
      "xmlns:dc" => "http://purl.org/dc/elements/1.1/",
      "xmlns:dcterms" => "http://purl.org/dc/terms/" }
  end
  
  def uri_for_path(path, *args)
    Sysmo::Api.uri_for_path(path, *args)
  end
  
  def api_partial_path_for_item object
    Sysmo::Api.api_partial_path_for_item(object)
  end
  
  def uri_for_collection(resource_name, *args)
    Sysmo::Api.uri_for_collection(resource_name, *args)
  end
  
  def uri_for_object(resource_obj, *args)
    Sysmo::Api.uri_for_object(resource_obj, *args)
  end
  
  def previous_link_xml_attributes(resource_uri)
    xlink_attributes(resource_uri, :title => xlink_title("Previous page of results"))
  end
  
  def next_link_xml_attributes(resource_uri)
    xlink_attributes(resource_uri, :title => xlink_title("Next page of results"))
  end
  
  def core_xlink object,include_title=true
    if (object.class.name.include?("::Version"))
      xlink=xlink_attributes(uri_for_object(object.parent,{:params=>{:version=>object.version}}),:resourceType => object.parent.class.name)
    else
      xlink=xlink_attributes(uri_for_object(object),:resourceType => object.class.name)  
    end
    
    xlink["xlink:title"]=xlink_title(object) unless !include_title || display_name(object,false).nil?
    xlink["id"]=object.id
    xlink["uuid"]=object.uuid if object.respond_to?("uuid")
    return xlink
  end
  
  def xlink_attributes(resource_uri, *args)
    attribs = { }
    
    attribs_in = args.extract_options!
    
    attribs["xlink:href"] = resource_uri
    
    attribs_in.each do |k,v|
      attribs["xlink:#{k.to_s}"] = v
    end
    
    return attribs
  end
  
  def xlink_title(item, item_type_name=nil)
    case item
      when String
      return item
    else
      if item_type_name.blank?
        item_type_name = case item
          when User
              "User"
        else
          if (item.class.name.include?("::Version"))
            item.parent.class.name
          else
            item.class.name  
          end              
        end
      end
      
      #return "#{item_type_name} - #{display_name(item, false)}"
      return "#{display_name(item, false)}"
    end
  end
  
  def display_name item,escape_html=false          
    result = nil
    result = item.title if item.respond_to?("title")
    result = item.name if item.respond_to?("name") && result.nil?
    result = h(result) if escape_html && !result.nil?
    return result
  end
  
  def dc_xml_tag(builder, term, value, *attributes)
    builder.tag! "dc:#{term}", value, attributes
  end
  
  def dcterms_xml_tag(builder, term, value, *attributes)
    # For dates...
    if [ :created, :modified, "created", "modified" ].include?(term)
      value = value.iso8601
    end
    
    builder.tag! "dcterms:#{term}", value, attributes
  end
  
  def core_xml builder,object
    builder.tag! "id",object.id
    dc_core_xml builder,object
    builder.tag! "uuid",object.uuid if object.respond_to?("uuid")    
  end  
  
  def extended_xml builder,object
    
    submitter = determine_submitter object
    builder.tag! "submitter" do 
      api_partial(builder,submitter)
    end if submitter
    
    if (object.class.name.include?("::Version"))
      builder.tag! "creators" do      
        api_partial_collection builder,object.parent.creators
      end if object.parent.respond_to?("creators") 
    end
    
    builder.tag! "organisms" do
      organisms=[]
      organisms=object.organisms if object.respond_to?("organisms")
      organisms << object.organism if object.respond_to?("organism") && object.organism
      api_partial_collection builder,organisms
    end if object.respond_to?("organism") || object.respond_to?("organisms")
    
    if (object.class.name.include?("::Version"))
      builder.tag! "attributions" do      
        api_partial_collection builder,object.parent.attributions
      end if object.parent.respond_to?("attributions") 
    end
    
    builder.tag! "creators" do      
      api_partial_collection builder,object.creators
    end if object.respond_to?("creators")  
    
    unless HIDE_DETAILS
      builder.tag! "email",object.email if object.respond_to?("email")
      builder.tag! "webpage",object.webpage if object.respond_to?("webpage")
      builder.tag! "internal_webpage",object.internal_webpage if object.respond_to?("internal_webpage")
      builder.tag! "phone",object.phone if object.respond_to?("phone")
    end
    
    builder.tag! "content_type",object.content_type if object.respond_to?("content_type")
    builder.tag! "version",object.version if object.respond_to?("version")
    builder.tag! "latest_version",object.latest_version.version,core_xlink(object.latest_version) if object.respond_to?("latest_version")           
    builder.tag! "revision_comments",object.revision_comments if object.respond_to?("revision_comments")
    if (object.respond_to?("versions"))
      builder.tag! "versions" do
        object.versions.each do |v|
          builder.tag! "version",v.version,core_xlink(v)
        end
      end
    end    
    
    asset_xml builder,object.asset if object.respond_to?("asset")
    blob_xml builder,object.content_blob if object.respond_to?("content_blob")
    api_partial builder,object.project if object.respond_to?("project")    
    
  end
  
  def asset_xml builder,asset,include_core=true,include_resource=true
    builder.tag! "asset",
    xlink_attributes(uri_for_object(asset),:resourceType => "Asset") do
      core_xml builder,asset if include_core
      resource_xml builder,asset.resource if (include_resource)                   
    end    
  end
  
  def resource_xml builder,resource 
    builder.tag! "resource",resource.title,core_xlink(resource)
  end
  
  def blob_xml builder,blob
    builder.tag! "blob",core_xlink(blob) do      
      builder.tag! "uuid",blob.uuid if blob.respond_to?("uuid")
      builder.tag! "md5sum",blob.md5sum if blob.respond_to?("md5sum")
      builder.tag! "is_remote",!blob.url.nil?
    end
  end
  
  def assets_list_xml builder,assets,tag="assets",include_core=true,include_resource=true
    builder.tag! tag do
      assets.each do |asset|
        asset_xml builder,asset,include_core,include_resource
      end
    end
  end
  
  def associated_resources_xml builder, object
    #FIXME: this needs fixing, with some refactoring of the version->asset linkage - see http://www.mygrid.org.uk/dev/issues/browse/SYSMO-362
    object=object.parent if (object.class.name.include?("::Version"))
    associated = get_related_resources object
    builder.tag! "associated" do
      associated.keys.each do |key|        
        attr={}
        attr[:total]=associated[key][:items].count
        if (associated[key][:hidden_count])
          attr[:total]=attr[:total]+associated[key][:hidden_count]
          attr[:hidden_count]=associated[key][:hidden_count]
        end
        generic_list_xml(builder, associated[key][:items],key.downcase.pluralize,attr)        
      end
    end    
  end    
  
  def api_index_parameters builder,params
    builder.page params[:page]
    builder.page_size params[:page_size]
    
  end
  
  def generic_list_xml builder,list,tag,attr={}
    builder.tag! tag,attr do 
      list.each do |item|
        if (item.class.name.include?("::Version")) #versioned items need to be handled slightly differently.
          parent=item.parent
          builder.tag! parent.class.name.underscore,core_xlink(item)
        else
          builder.tag! item.class.name.underscore,core_xlink(item)  
        end
        
      end
    end
  end
  
  def api_partial builder,object, is_root=false
    object=object.parent if object.class.name.include?("::Version")
    path=api_partial_path_for_item(object)    
    classname=object.class.name.underscore
    render :partial=>path,:locals=>{:parent_xml => builder,:is_root=>is_root,classname.to_sym=>object}
  end
  
  def api_partial_collection builder,objects,is_root=false
    objects.each{|o| api_partial builder,o,is_root}
  end
  
  def parent_child_elements builder,object
    builder.tag! "parents" do
      api_partial_collection(builder, object.parents, is_root = false)  
    end
    
    builder.tag! "children" do
      api_partial_collection(builder, object.children, is_root = false)
    end
  end
  
  def dc_core_xml builder,object
    submitter = determine_submitter object
    dc_xml_tag builder,:title,object.title if object.respond_to?("title")
    dc_xml_tag builder,:description,object.description if object.respond_to?("description")
    dc_xml_tag builder,:creator,submitter.name if submitter
    dcterms_xml_tag builder,:created,object.created_at if object.respond_to?("created_at")
    dcterms_xml_tag builder,:modified,object.updated_at if object.respond_to?("updated_at")    
  end
  
  def determine_submitter object
    #FIXME: needs to be the creators for assets
    return object.owner if object.respond_to?("owner")
    result = object.contributor if object.respond_to?("contributor")
    if (result)
      return result if result.instance_of?(Person)
      return result.person if result.instance_of?(User)      
    end
    
    return nil
  end
  
  def assay_data_relationships_xml builder,assay
    relationships={}
    assay.assay_assets.each do |aa|
      if aa.relationship_type
        relationships[aa.relationship_type.title] ||= []
        relationships[aa.relationship_type.title] << aa.asset.resource
      end
    end
    
    builder.tag! "data_relationships" do
      relationships.keys.each do |k|        
        generic_list_xml(builder, relationships[k],"data_relationship",{:type=>k})                 
      end
    end
  end
  
end