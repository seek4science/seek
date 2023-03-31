# Workflow Class
Factory.define(:cwl_workflow_class, class: WorkflowClass) do |f|
  f.title 'Common Workflow Language'
  f.key 'cwl'
  f.extractor 'CWL'
  f.description 'Common Workflow Language'
  f.alternate_name 'CWL'
  f.identifier 'https://w3id.org/cwl/v1.0/'
  f.url 'https://www.commonwl.org/'
end

Factory.define(:galaxy_workflow_class, class: WorkflowClass) do |f|
  f.title 'Galaxy'
  f.key 'galaxy'
  f.extractor 'Galaxy'
  f.description 'Galaxy'
  f.identifier 'https://galaxyproject.org/'
  f.url 'https://galaxyproject.org/'
end

Factory.define(:nextflow_workflow_class, class: WorkflowClass) do |f|
  f.title 'Nextflow'
  f.key 'nextflow'
  f.extractor 'Nextflow'
  f.description 'Nextflow'
  f.identifier 'https://www.nextflow.io/'
  f.url 'https://www.nextflow.io/'
end

Factory.define(:knime_workflow_class, class: WorkflowClass) do |f|
  f.title 'KNIME'
  f.key 'knime'
  f.extractor 'KNIME'
  f.description 'KNIME'
  f.identifier 'https://www.knime.com/'
  f.url 'https://www.knime.com/'
end

Factory.define(:unextractable_workflow_class, class: WorkflowClass) do |f|
  f.title 'Mystery'
  f.key 'Mystery'
  f.description 'Mysterious'
end

Factory.define(:jupyter_workflow_class, class: WorkflowClass) do |f|
  f.title 'Jupyter Notebook'
  f.description 'Jupyter Notebook'
end

Factory.define(:user_added_workflow_class, class: WorkflowClass) do |f|
  f.sequence(:title) { |n| "User-added Type #{n}" }
  f.contributor { Factory(:person) }
end

Factory.define(:user_added_workflow_class_with_logo, class: WorkflowClass) do |f|
  f.sequence(:title) { |n| "User-added Type with Logo #{n}" }
  f.avatar
  f.contributor { Factory(:person) }
end

# Workflow
Factory.define(:workflow) do |f|
  f.title 'This Workflow'
  f.with_project_contributor
  f.workflow_class { WorkflowClass.find_by_key('cwl') || Factory(:cwl_workflow_class) }

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

Factory.define(:public_workflow, parent: :workflow) do |f|
  f.policy { Factory(:downloadable_public_policy) }
end

Factory.define(:min_workflow, class: Workflow) do |f|
  f.with_project_contributor
  f.title 'A Minimal Workflow'
  f.workflow_class { WorkflowClass.find_by_key('cwl') || Factory(:cwl_workflow_class) }
  f.projects { [Factory.build(:min_project)] }
  f.after_create do |workflow|
    workflow.content_blob = Factory.create(:cwl_content_blob, asset: workflow, asset_version: workflow.version)
  end
end

Factory.define(:max_workflow, class: Workflow) do |f|
  f.with_project_contributor
  f.title 'A Maximal Workflow'
  f.description 'How to run a simulation in GROMACS'
  f.workflow_class { WorkflowClass.find_by_key('cwl') || Factory(:cwl_workflow_class) }
  f.assays { [Factory(:public_assay)] }
  f.relationships {[Factory(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: Factory(:publication))]}
  f.discussion_links { [Factory.build(:discussion_link, label:'Slack')] }
  f.after_create do |workflow|
    workflow.content_blob = Factory.create(:cwl_content_blob, asset: workflow, asset_version: workflow.version)
    workflow.annotate_with(['Workflow-tag1', 'Workflow-tag2', 'Workflow-tag3', 'Workflow-tag4', 'Workflow-tag5'], 'tag', workflow.contributor)
    User.with_current_user(workflow.contributor.user) do
      workflow.operation_annotations = 'Clustering'
      workflow.topic_annotations = 'Chemistry'
    end
    workflow.save!
  end
  f.other_creators 'Blogs, Joe'
  f.assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: Factory(:person, first_name: 'Some', last_name: 'One'))] }
end

Factory.define(:cwl_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :cwl_content_blob
end

Factory.define(:cwl_packed_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :cwl_packed_content_blob
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

# A pre-made RO-Crate
Factory.define(:existing_galaxy_ro_crate_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :existing_galaxy_ro_crate
  f.workflow_class { WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class) }
end

# An RO-Crate generated by SEEK through the form on the workflow page
Factory.define(:generated_galaxy_ro_crate_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :generated_galaxy_ro_crate
  f.workflow_class { WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class) }
end

Factory.define(:generated_galaxy_no_diagram_ro_crate_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :generated_galaxy_no_diagram_ro_crate
  f.workflow_class { WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class) }
end

Factory.define(:nf_core_ro_crate_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :nf_core_ro_crate
  f.workflow_class { WorkflowClass.find_by_key('nextflow') || Factory(:nextflow_workflow_class) }
end

Factory.define(:just_cwl_ro_crate_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :just_cwl_ro_crate
end

Factory.define(:workflow_with_tests, parent: :workflow) do |f|
  f.association :content_blob, factory: :ro_crate_with_tests
end

Factory.define(:spaces_ro_crate_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :spaces_ro_crate
  f.workflow_class { WorkflowClass.find_by_title('Jupyter Notebook') || Factory(:jupyter_workflow_class) }
end

Factory.define(:dots_ro_crate_workflow, parent: :workflow) do |f|
  f.association :content_blob, factory: :dots_ro_crate
  f.workflow_class { WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class) }
end

Factory.define(:remote_git_workflow, class: Workflow) do |f|
  f.title 'Concat two files'
  f.with_project_contributor
  f.workflow_class { WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class) }
  f.git_version_attributes {
    repo = Factory(:remote_repository)
    { git_repository_id: repo.id,
      ref: 'refs/heads/main',
      commit: 'b6312caabe582d156dd351fab98ce78356c4b74c',
      main_workflow_path: 'concat_two_files.ga',
      diagram_path: 'diagram.png',
    }
  }
end

Factory.define(:annotationless_local_git_workflow, class: Workflow) do |f|
  f.title 'Concat two files'
  f.with_project_contributor
  f.workflow_class { WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class) }
  f.git_version_attributes do
    repo = Factory(:unlinked_local_repository)
    { git_repository_id: repo.id,
      ref: 'refs/heads/master',
      commit: '96aee188b2f9c145860f21dc182608fec5084a8a',
      mutable: true
    }
  end
end

Factory.define(:local_git_workflow, class: Workflow) do |f|
  f.title 'Concat two files'
  f.with_project_contributor
  f.workflow_class { WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class) }
  f.git_version_attributes do
    repo = Factory(:unlinked_local_repository)
    { git_repository_id: repo.id,
      ref: 'refs/heads/master',
      commit: '96aee188b2f9c145860f21dc182608fec5084a8a',
      main_workflow_path: 'concat_two_files.ga',
      diagram_path: 'diagram.png',
      mutable: true
    }
  end
end

Factory.define(:ro_crate_git_workflow, class: Workflow) do |f|
  f.title 'Sort and change case'
  f.with_project_contributor
  f.workflow_class { WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class) }
  f.git_version_attributes do
    repo = Factory(:remote_workflow_ro_crate_repository)
    { git_repository_id: repo.id,
      ref: 'refs/remotes/origin/master',
      commit: 'a321b6e',
      main_workflow_path: 'sort-and-change-case.ga',
      mutable: false
    }
  end
end

Factory.define(:local_ro_crate_git_workflow, class: Workflow) do |f|
  f.title 'Sort and change case'
  f.with_project_contributor
  f.workflow_class { WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class) }
  f.git_version_attributes do
    repo = Factory(:workflow_ro_crate_repository)
    { git_repository_id: repo.id,
      ref: 'refs/heads/master',
      commit: 'a321b6e',
      main_workflow_path: 'sort-and-change-case.ga',
      mutable: false
    }
  end
end

Factory.define(:local_ro_crate_git_workflow_with_tests, class: Workflow) do |f|
  f.title 'Sort and change case'
  f.with_project_contributor
  f.workflow_class { WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class) }
  f.git_version_attributes do
    repo = Factory(:workflow_ro_crate_repository)
    { git_repository_id: repo.id,
      ref: 'refs/heads/tests',
      commit: '612f7f7',
      main_workflow_path: 'sort-and-change-case.ga',
      mutable: false
    }
  end
end

Factory.define(:nfcore_git_workflow, class: Workflow) do |f|
  f.title 'nf-core/rnaseq'
  f.with_project_contributor
  f.workflow_class { WorkflowClass.find_by_key('nextflow') || Factory(:nextflow_workflow_class) }
  f.git_version_attributes do
    repo = Factory(:nfcore_local_rocrate_repository)
    { git_repository_id: repo.id,
      ref: 'refs/heads/master',
      commit: '3643a94411b65f42bce5357c5015603099556ad9',
      main_workflow_path: 'main.nf',
      mutable: true
    }
  end
end

Factory.define(:empty_git_workflow, class: Workflow) do |f|
  f.title 'Empty Workflow'
  f.with_project_contributor
  f.git_version_attributes do
    repo = Factory(:blank_repository)
    { git_repository_id: repo.id, mutable: true }
  end
end

Factory.define(:test_data_workflow_data_file_relationship, class: WorkflowDataFileRelationship) do |f|
  f.title 'Test data'
  f.key 'test'
end

Factory.define(:ro_crate_git_workflow_with_tests, class: Workflow) do |f|
  f.title 'Sort and change case'
  f.with_project_contributor
  f.workflow_class { WorkflowClass.find_by_key('galaxy') || Factory(:galaxy_workflow_class) }
  f.git_version_attributes do
    repo = Factory(:remote_workflow_ro_crate_repository)
    { git_repository_id: repo.id,
      ref: 'refs/remotes/origin/tests',
      commit: '612f7f7',
      main_workflow_path: 'sort-and-change-case.ga',
      mutable: false
    }
  end
end