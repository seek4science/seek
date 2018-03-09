xml.instruct! :xml
xml.tag! 'documents', xlink_attributes(uri_for_collection('documents', params: params)), xml_root_attributes,
         resourceType: 'Documents' do
  render partial: 'api/core_index_elements', locals: { items: @documents, parent_xml: xml }
end
