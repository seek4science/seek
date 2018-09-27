# Sop
Factory.define(:workflow) do |f|
  f.title 'This Workflow'
  f.with_project_contributor

  f.after_create do |workflow|
    if workflow.content_blob.blank?
      workflow.content_blob = Factory.create(:content_blob, original_filename: 'workflow.pdf',
                                        content_type: 'application/pdf', asset: workflow, asset_version: workflow.version)
    else
      workflow.content_blob.asset = workflow
      workflow.content_blob.asset_version = workflow.version
      workflow.content_blob.save
    end
  end
end

Factory.define(:min_workflow, class: Sop) do |f|
  f.with_project_contributor
  f.title 'A Minimal Workflow'
  f.projects { [Factory.build(:min_project)] }
  f.after_create do |workflow|
    workflow.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: workflow, asset_version: workflow.version)
  end
end

Factory.define(:max_workflow, class: Sop) do |f|
  f.with_project_contributor
  f.title 'A Maximal Workflow'
  f.description 'How to run a simulation in GROMACS'
  f.projects { [Factory.build(:max_project)] }
  f.assays {[Factory.build(:max_assay, policy: Factory(:public_policy))]}
  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
  f.after_create do |workflow|
    workflow.content_blob = Factory.create(:min_content_blob, content_type: 'application/pdf', asset: workflow, asset_version: workflow.version)
  end
  f.other_creators 'Blogs, Joe'
end

Factory.define(:doc_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :doc_content_blob
end

Factory.define(:odt_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :odt_content_blob
end

Factory.define(:pdf_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :pdf_content_blob
end

# A Workflow that has been registered as a URI
Factory.define(:url_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :url_content_blob
end

# Workflow::Version
Factory.define(:workflow_version, class: Sop::Version) do |f|
  f.association :workflow
  f.projects { workflow.projects }
  f.after_create do |workflow_version|
    workflow_version.workflow.version += 1
    workflow_version.workflow.save
    workflow_version.version = workflow_version.workflow.version
    workflow_version.title = workflow_version.workflow.title
    workflow_version.save
  end
end

Factory.define(:workflow_version_with_blob, parent: :workflow_version) do |f|
  f.after_create do |workflow_version|
    if workflow_version.content_blob.blank?
      workflow_version.content_blob = Factory.create(:pdf_content_blob,
                                                asset: workflow_version.workflow,
                                                asset_version: workflow_version.version)
    else
      workflow_version.content_blob.asset = workflow_version.workflow
      workflow_version.content_blob.asset_version = workflow_version.version
      workflow_version.content_blob.save
    end
  end
end

Factory.define(:api_pdf_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :blank_pdf_content_blob
end
