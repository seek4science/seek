# BioCatalogue: app/helpers/api_helper.rb
#
# Copyright (c) 2008-2009, University of Manchester, The European Bioinformatics
# Institute (EMBL-EBI) and the University of Southampton.
# See license.txt for details.
require 'jbuilder'
require 'jbuilder/json_api/version'
module ApiHelper
  #Jbuilder.include JsonAPI
  def xml_root_attributes
    { 'xmlns' => 'http://www.sysmo-db.org/2010/xml/rest',
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      'xsi:schemaLocation' => 'http://www.sysmo-db.org/2010/xml/rest/schema-v1.xsd',
      'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
      'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
      'xmlns:dcterms' => 'http://purl.org/dc/terms/' }
  end

  def api_partial_path_for_item(object)
    Seek::Api.api_partial_path_for_item(object)
  end

  def uri_for_collection(resource_name, *args)
    Seek::Api.uri_for_collection(resource_name, *args)
  end

  def uri_for_object(resource_obj, *args)
    Seek::Api.uri_for_object(resource_obj, *args)
  end

  def previous_link_xml_attributes(resource_uri)
    xlink_attributes(resource_uri, title: xlink_title('Previous page of results'))
  end

  def next_link_xml_attributes(resource_uri)
    xlink_attributes(resource_uri, title: xlink_title('Next page of results'))
  end

  def assay_type_xlink(assay)
    xlink = xlink_attributes(assay.assay_type_uri)
    xlink['xlink:title'] = assay.assay_type_label
    xlink['resourceType'] = 'AssayType'
    xlink
  end

  def technology_type_xlink(assay)
    xlink = xlink_attributes(assay.technology_type_uri)
    xlink['xlink:title'] = assay.technology_type_label
    xlink['resourceType'] = 'TechnologyType'
    xlink
  end

  def core_xlink(object, include_title = true)
    xlink = if object.class.name.include?('::Version')
              xlink_attributes(uri_for_object(object.parent, params: { version: object.version }))
            else
              xlink_attributes(uri_for_object(object))
            end

    xlink['xlink:title'] = xlink_title(object) unless !include_title || display_name(object, false).nil?
    xlink['id'] = object.id
    xlink['uuid'] = object.uuid if object.respond_to?('uuid')
    xlink['resourceType'] = object.class.name.include?('::Version') ? object.parent.class.name : object.class.name
    xlink
  end

  def avatar_href_link(object)
    uri = nil
    uri = "/#{object.class.name.pluralize.underscore}/#{object.id}/avatars/#{object.avatar.id}" unless object.avatar.nil?
    uri
  end

  # requires a slightly different handling to core_xlink because the route is nested
  def avatar_xlink(avatar)
    return { 'xsi:nil' => 'true' } if avatar.nil?
    uri = uri_for_object(avatar.owner)
    uri = "#{uri}/avatars/#{avatar.id}"
    xlink = xlink_attributes(uri)
    xlink['id'] = avatar.id
    xlink['resourceType'] = avatar.class.name
    xlink
  end

  def xlink_attributes(resource_uri, *args)
    attribs = {}

    attribs_in = args.extract_options!

    attribs['xlink:href'] = resource_uri

    attribs_in.each do |k, v|
      attribs["xlink:#{k}"] = v
    end

    attribs
  end

  def xlink_title(item, item_type_name = nil)
    case item
    when String
      item
    else
      if item_type_name.blank?
        item_type_name = case item
                         when User
                           'User'
                         else
                           if item.class.name.include?('::Version')
                             item.parent.class.name
                           else
                             item.class.name
                           end
        end
      end

      display_name(item, false).to_s
    end
  end

  def display_name(item, escape_html = false)
    result = nil
    result = item.title if item.respond_to?('title')
    result = item.name if item.respond_to?('name') && result.nil?
    result = h(result) if escape_html && !result.nil?
    result
  end

  def dc_xml_tag(builder, term, value)
    builder.tag! "dc:#{term}", value
  end

  def dcterms_xml_tag(builder, term, value)
    # For dates...
    if [:created, :modified, 'created', 'modified'].include?(term)
      value = value.iso8601
    end

    builder.tag! "dcterms:#{term}", value
  end

  def core_xml(builder, object)
    builder.tag! 'id', object.id
    dc_core_xml builder, object
    builder.tag! 'uuid', object.uuid if object.respond_to?('uuid')
  end

  def extended_xml(builder, object)
    submitter = determine_submitter object
    if submitter
      builder.tag! 'submitter' do
        api_partial(builder, submitter)
      end
    end

    if object.respond_to?('organism') || object.respond_to?('organisms')
      builder.tag! 'organisms' do
        organisms = []
        organisms = object.organisms if object.respond_to?('organisms')
        organisms << object.organism if object.respond_to?('organism') && object.organism
        api_partial_collection builder, organisms
      end
    end

    if object.respond_to?('human_disease') || object.respond_to?('human_diseases')
      builder.tag! 'human_diseases' do
        human_diseases = []
        human_diseases = object.human_diseases if object.respond_to?('human_diseases')
        human_diseases << object.human_disease if object.respond_to?('human_disease') && object.human_disease
        api_partial_collection builder, human_diseases
      end
    end

    if !object.instance_of?(Publication) && object.respond_to?('creators')
      builder.tag! 'creators' do
        api_partial_collection builder, (object.creators || [])
      end
    end

    if object.is_a?(Person) || object.is_a?(Project)
      unless hide_contact_details?(object)
        builder.tag! 'email', object.email if object.respond_to?('email')
        builder.tag! 'webpage', object.webpage if object.respond_to?('webpage')
        builder.tag! 'internal_webpage', object.internal_webpage if object.respond_to?('internal_webpage')
        builder.tag! 'phone', object.phone if object.respond_to?('phone')
      end
      builder.tag! 'orcid', object.orcid_uri if object.respond_to?('orcid_uri')
    end

    if object.respond_to?('bioportal_concept') || object.respond_to?('bioportal_concepts')
      builder.tag! 'bioportal_concepts' do
        concepts = []
        concepts = object.bioportal_concepts if object.respond_to?('bioportal_concepts')
        concept = object.bioportal_concept if object.respond_to?('bioportal_concept')
        concepts.compact.each do |concept|
          builder.tag! 'bioportal_concept' do
            builder.tag! 'ontology_id', concept.ontology_id
            builder.tag! 'concept_uri', concept.concept_uri
          end
        end
      end
    end

    builder.tag! 'version', object.version if object.respond_to?('version')
    builder.tag! 'revision_comments', object.revision_comments if object.respond_to?('revision_comments')
    builder.tag! 'latest_version', core_xlink(object.latest_version) if object.respond_to?('latest_version')

    if object.respond_to?('versions')
      builder.tag! 'versions' do
        object.versions.each do |v|
          builder.tag! 'version', core_xlink(v)
        end
      end
    end

    policy_xml builder, object if User.admin_logged_in? && object.respond_to?('policy')
    if object.respond_to?('content_blobs')
      builder.tag! 'blobs' do
        object.content_blobs.each do |cb|
          blob_xml builder, cb
        end
      end
    elsif object.respond_to?('content_blob')
      blob_xml builder, object.content_blob
    end

    if object.respond_to?('avatar')
      builder.tag! 'avatars' do
        builder.tag! 'avatar', avatar_xlink(object.avatar) unless object.avatar.nil?
      end
    end
    tags_xml builder, object
  end

  def tags_xml(builder, object)
    object = object.parent if object.class.name.include?('::Version')
    if object.respond_to?(:annotations_as_text_array) && !object.is_a?(Project)
      builder.tag! 'tags' do
        object.annotations.each do |annotation|
          builder.tag! 'tag', annotation.value.text, context: annotation.annotation_attribute.name
        end
      end
    end
  end

  def policy_xml(builder, asset)
    policy = asset.policy
    if policy.nil?
      builder.tag! 'policy', 'xsi:nil' => 'true'
    else
      builder.tag! 'policy' do
        dc_core_xml builder, policy
        builder.tag! 'sharing_scope', policy.sharing_scope
        builder.tag! 'access_type', policy.access_type
        builder.tag! 'use_blacklist', policy.use_blacklist ? policy.use_blacklist : false
        builder.tag! 'use_whitelist', policy.use_whitelist ? policy.use_whitelist : false
        builder.tag! 'permissions' do
          policy.permissions.reject { |p| p.contributor_type == 'FavouriteGroup' }.each do |permission|
            builder.tag! 'permission' do
              dc_core_xml builder, permission
              builder.tag! 'contributor', core_xlink(permission.contributor)
              builder.tag! 'access_type', permission.access_type
            end
          end
        end
      end
    end
  end

  def resource_xml(builder, resource)
    builder.tag! 'resource', core_xlink(resource)
  end

  def blob_xml(builder, blob)
    builder.tag! 'blob', core_xlink(blob) do
      builder.tag! 'uuid', blob.uuid
      builder.tag! 'md5sum', blob.md5sum
      builder.tag! 'url', blob.url
      builder.tag! 'original_filename', blob.original_filename
      builder.tag! 'content_type', blob.content_type
      builder.tag! 'is_remote', !blob.file_exists?
    end
  end

  def assets_list_xml(builder, assets, tag = 'assets', include_core = true, include_resource = true)
    builder.tag! tag do
      assets.each do |asset|
        asset_xml builder, asset, include_core, include_resource
      end
    end
  end

  def associated_resources(object)
    associated_hash = get_related_resources(object)
    to_ignore = ignore_associated_types.collect(&:name)
    associated_hash.delete_if { |k, _v| to_ignore.include?(k) }
    associated_hash
  end

  def associated_resources_xml(builder, object)
    object = object.parent if object.class.name.include?('::Version')
    associated = get_related_resources(object)
    to_ignore = ignore_associated_types.collect(&:name).concat ignore_associated_types_xml.collect(&:name)
    associated.delete_if { |k, _v| to_ignore.include?(k) }
    builder.tag! 'associated' do
      associated.keys.sort.each do |key|
        attr = {}
        attr[:total] = associated[key][:items].count
        if associated[key][:hidden_count]
          attr[:total] = attr[:total] + associated[key][:hidden_count]
          attr[:hidden_count] = associated[key][:hidden_count]
        end
        generic_list_xml(builder, associated[key][:items], key.underscore.pluralize, attr)
      end
    end
  end

  # types that should be ignored from the related resources. It may be desirable to add items in this list to the schema
  def ignore_associated_types
    [Strain, Organism, HumanDisease]
  end

  def ignore_associated_types_xml
    [Workflow, Node]
  end

  def generic_list_xml(builder, list, tag, attr = {})
    builder.tag! tag, attr do
      list.each do |item|
        if item.class.name.include?('::Version') # versioned items need to be handled slightly differently.
          parent = item.parent
          builder.tag! parent.class.name.underscore, core_xlink(item)
        else
          builder.tag! item.class.name.underscore, core_xlink(item)
        end
      end
    end
  end

  def api_partial(builder, object, is_root = false)
    parent_object = object.class.name.include?('::Version') ? object.parent : object
    path = api_partial_path_for_item(parent_object)
    classname = parent_object.class.name.underscore
    render partial: path, locals: { :parent_xml => builder, :is_root => is_root, classname.to_sym => object }
  end

  def api_partial_collection(builder, objects, is_root = false)
    objects.each { |o| api_partial builder, o, is_root }
  end

  def parent_child_elements(builder, object)
    builder.tag! 'parents' do
      api_partial_collection(builder, object.parents, is_root = false)
    end

    builder.tag! 'children' do
      api_partial_collection(builder, object.children, is_root = false)
    end
  end

  def dc_core_xml(builder, object)
    submitter = determine_submitter object
    dc_xml_tag builder, :title, object.title if object.respond_to?('title')
    dc_xml_tag builder, :description, object.description if object.respond_to?('description')
    dcterms_xml_tag builder, :created, object.created_at if object.respond_to?('created_at')
    dcterms_xml_tag builder, :modified, object.updated_at if object.respond_to?('updated_at')
    dc_xml_tag builder, :creator, submitter.name if submitter
  end

  def determine_submitter(object)
    # FIXME: needs to be the creators for assets
    return object.owner if object.respond_to?('owner')
    result = object.contributor if object.respond_to?('contributor') && !object.is_a?(Permission)
    if result
      return result if result.instance_of?(Person)
      return result.person if result.instance_of?(User)
    end

    nil
  end

  def assay_data_relationships_xml(builder, assay)
    relationships = {}
    assay.assay_assets.each do |aa|
      if aa.relationship_type
        relationships[aa.relationship_type.title] ||= []
        relationships[aa.relationship_type.title] << aa.asset
      end
    end

    builder.tag! 'data_relationships' do
      relationships.keys.each do |k|
        generic_list_xml(builder, relationships[k], 'data_relationship', type: k)
      end
    end
  end



end
