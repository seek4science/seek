# Node
Factory.define(:node) do |f|
  f.title 'This Node'
  f.with_project_contributor

  f.after_create do |node|
    if node.content_blob.blank?
      node.content_blob = Factory.create(:content_blob, original_filename: 'node.pdf',
                                        content_type: 'application/pdf', asset: node, asset_version: node.version)
    else
      node.content_blob.asset = node
      node.content_blob.asset_version = node.version
      node.content_blob.save
    end
  end
end

Factory.define(:min_node, class: Node) do |f|
  f.with_project_contributor
  f.title 'A Minimal Node'
  f.projects { [Factory.build(:min_project)] }
  f.after_create do |node|
    node.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: node, asset_version: node.version)
  end
end

Factory.define(:max_node, class: Node) do |f|
  f.with_project_contributor
  f.title 'A Maximal Node'
  f.description 'How to run a simulation in GROMACS'
  f.projects { [Factory.build(:max_project)] }
  f.assays {[Factory.build(:max_assay, policy: Factory(:public_policy))]}
  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
  f.after_create do |node|
    node.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: node, asset_version: node.version)
  end
  f.other_creators 'Blogs, Joe'
end

Factory.define(:doc_node, parent: :node) do |f|
  f.association :content_blob, factory: :doc_content_blob
end

Factory.define(:odt_node, parent: :node) do |f|
  f.association :content_blob, factory: :odt_content_blob
end

Factory.define(:pdf_node, parent: :node) do |f|
  f.association :content_blob, factory: :pdf_content_blob
end

# A Node that has been registered as a URI
Factory.define(:url_node, parent: :node) do |f|
  f.association :content_blob, factory: :url_content_blob
end

# Node::Version
Factory.define(:node_version, class: Node::Version) do |f|
  f.association :node
  f.projects { node.projects }
  f.after_create do |node_version|
    node_version.node.version += 1
    node_version.node.save
    node_version.version = node_version.node.version
    node_version.title = node_version.node.title
    node_version.save
  end
end

Factory.define(:node_version_with_blob, parent: :node_version) do |f|
  f.after_create do |node_version|
    if node_version.content_blob.blank?
      node_version.content_blob = Factory.create(:pdf_content_blob,
                                                asset: node_version.node,
                                                asset_version: node_version.version)
    else
      node_version.content_blob.asset = node_version.node
      node_version.content_blob.asset_version = node_version.version
      node_version.content_blob.save
    end
  end
end

Factory.define(:api_pdf_node, parent: :node) do |f|
  f.association :content_blob, factory: :blank_pdf_content_blob
end
