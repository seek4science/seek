# Workflow Class
Factory.define(:cwl_workflow_class, class: WorkflowClass) do |f|
  f.title I18n.t('workflows.cwl_workflow')
  f.key 'CWL'
  f.description 'Common Workflow Language'
end

# Workflow
Factory.define(:workflow) do |f|
  f.title 'This Workflow'
  f.with_project_contributor
  f.workflow_class { WorkflowClass.find_by_key('CWL') || Factory(:cwl_workflow_class) }

  f.after_create do |workflow|
    if workflow.content_blob.blank?
      workflow.content_blob = Factory.create(:cwl_content_blob, original_filename: 'workflow.cwl',
                                        asset: workflow, asset_version: workflow.version)
    else
      workflow.content_blob.asset = workflow
      workflow.content_blob.asset_version = workflow.version
      workflow.content_blob.save
    end
  end
end

Factory.define(:min_workflow, class: Workflow) do |f|
  f.with_project_contributor
  f.title 'A Minimal Workflow'
  f.workflow_class { WorkflowClass.find_by_key('CWL') || Factory(:cwl_workflow_class) }
  f.projects { [Factory.build(:min_project)] }
  f.after_create do |workflow|
    workflow.content_blob = Factory.create(:cwl_content_blob, asset: workflow, asset_version: workflow.version)
  end
end

Factory.define(:max_workflow, class: Workflow) do |f|
  f.with_project_contributor
  f.title 'A Maximal Workflow'
  f.description 'How to run a simulation in GROMACS'
  f.workflow_class { WorkflowClass.find_by_key('CWL') || Factory(:cwl_workflow_class) }
  f.projects { [Factory.build(:max_project)] }
  f.assays {[Factory.build(:max_assay, policy: Factory(:public_policy))]}
  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
  f.after_create do |workflow|
    workflow.content_blob = Factory.create(:cwl_content_blob, asset: workflow, asset_version: workflow.version)
  end
  f.other_creators 'Blogs, Joe'
end

Factory.define(:cwl_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :cwl_content_blob
end

# A Workflow that has been registered as a URI
Factory.define(:cwl_url_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :url_cwl_content_blob
end

# Workflow::Version
Factory.define(:workflow_version, class: Workflow::Version) do |f|
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
      workflow_version.content_blob = Factory.create(:cwl_content_blob,
                                                asset: workflow_version.workflow,
                                                asset_version: workflow_version.version)
    else
      workflow_version.content_blob.asset = workflow_version.workflow
      workflow_version.content_blob.asset_version = workflow_version.version
      workflow_version.content_blob.save
    end
  end
end

Factory.define(:api_cwl_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :blank_cwl_content_blob
end
