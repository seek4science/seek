FactoryBot.define do
  # Workflow Class
  factory(:cwl_workflow_class, class: WorkflowClass) do
    title { 'Common Workflow Language' }
    key { 'cwl' }
    extractor { 'CWL' }
    description { 'Common Workflow Language' }
    alternate_name { 'CWL' }
    identifier { 'https://w3id.org/cwl/v1.0/' }
    url { 'https://www.commonwl.org/' }
  end
  
  factory(:galaxy_workflow_class, class: WorkflowClass) do
    title { 'Galaxy' }
    key { 'galaxy' }
    extractor { 'Galaxy' }
    description { 'Galaxy' }
    identifier { 'https://galaxyproject.org/' }
    url { 'https://galaxyproject.org/' }
  end
  
  factory(:nextflow_workflow_class, class: WorkflowClass) do
    title { 'Nextflow' }
    key { 'nextflow' }
    extractor { 'Nextflow' }
    description { 'Nextflow' }
    identifier { 'https://www.nextflow.io/' }
    url { 'https://www.nextflow.io/' }
  end
  
  factory(:knime_workflow_class, class: WorkflowClass) do
    title { 'KNIME' }
    key { 'knime' }
    extractor { 'KNIME' }
    description { 'KNIME' }
    identifier { 'https://www.knime.com/' }
    url { 'https://www.knime.com/' }
  end
  
  factory(:unextractable_workflow_class, class: WorkflowClass) do
    title { 'Mystery' }
    key { 'Mystery' }
    description { 'Mysterious' }
  end
  
  factory(:jupyter_workflow_class, class: WorkflowClass) do
    title { 'Jupyter Notebook' }
    description { 'Jupyter Notebook' }
  end
  
  factory(:user_added_workflow_class, class: WorkflowClass) do
    sequence(:title) { |n| "User-added Type #{n}" }
    contributor { FactoryBot.create(:person) }
  end
  
  factory(:user_added_workflow_class_with_logo, class: WorkflowClass) do
    sequence(:title) { |n| "User-added Type with Logo #{n}" }
    avatar
    contributor { FactoryBot.create(:person) }
  end
  
  # Workflow
  factory(:workflow) do
    title { 'This Workflow' }
    with_project_contributor
    workflow_class { WorkflowClass.find_by_key('cwl') || FactoryBot.create(:cwl_workflow_class) }
  
    after(:create) do |workflow|
      if workflow.content_blob.blank?
        workflow.content_blob = FactoryBot.create(:cwl_content_blob, original_filename: 'workflow.cwl',
                                          asset: workflow, asset_version: workflow.version)
      else
        workflow.content_blob.asset = workflow
        workflow.content_blob.asset_version = workflow.version
        workflow.content_blob.save
      end
    end
  end
  
  factory(:public_workflow, parent: :workflow) do
    policy { FactoryBot.create(:downloadable_public_policy) }
  end
  
  factory(:min_workflow, class: Workflow) do
    with_project_contributor
    title { 'A Minimal Workflow' }
    workflow_class { WorkflowClass.find_by_key('cwl') || FactoryBot.create(:cwl_workflow_class) }
    projects { [FactoryBot.build(:min_project)] }
    after(:create) do |workflow|
      workflow.content_blob = FactoryBot.create(:cwl_content_blob, asset: workflow, asset_version: workflow.version)
    end
  end
  
  factory(:max_workflow, class: Workflow) do
    with_project_contributor
    title { 'A Maximal Workflow' }
    description { 'How to run a simulation in GROMACS' }
    workflow_class { WorkflowClass.find_by_key('cwl') || FactoryBot.create(:cwl_workflow_class) }
    assays { [FactoryBot.create(:public_assay)] }
    relationships {[FactoryBot.create(:relationship, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: FactoryBot.create(:publication))]}
    discussion_links { [FactoryBot.build(:discussion_link, label:'Slack')] }
    tools_attributes {
      [
        { bio_tools_id: 'workflowhub', name: 'WorkflowHub'},
        { bio_tools_id: 'bio.tools', name: 'bio.tools'},
        { bio_tools_id: 'bioruby', name: 'BioRuby'}
      ]
    }

    after(:create) do |workflow|
      workflow.content_blob = FactoryBot.create(:cwl_content_blob, asset: workflow, asset_version: workflow.version)
  
      # required for annotations
      FactoryBot.create(:operations_controlled_vocab) unless SampleControlledVocab::SystemVocabs.operations_controlled_vocab
      FactoryBot.create(:topics_controlled_vocab) unless SampleControlledVocab::SystemVocabs.topics_controlled_vocab
  
      User.with_current_user(workflow.contributor.user) do
        workflow.tags = ['Workflow-tag1', 'Workflow-tag2', 'Workflow-tag3', 'Workflow-tag4', 'Workflow-tag5']
        workflow.operation_annotations = 'Clustering'
        workflow.topic_annotations = 'Chemistry'
      end
      workflow.save!
    end
    other_creators { 'Blogs, Joe' }
    assets_creators { [AssetsCreator.new(affiliation: 'University of Somewhere', creator: FactoryBot.create(:person, first_name: 'Some', last_name: 'One'))] }
  end
  
  factory(:cwl_workflow, parent: :workflow) do
    association :content_blob, factory: :cwl_content_blob
  end
  
  factory(:cwl_packed_workflow, parent: :workflow) do
    association :content_blob, factory: :cwl_packed_content_blob
  end
  
  # A Workflow that has been registered as a URI
  factory(:cwl_url_workflow, parent: :workflow) do
    association :content_blob, factory: :url_cwl_content_blob
  end
  
  # Workflow::Version
  factory(:workflow_version, class: Workflow::Version) do
    association :workflow
    projects { workflow.projects }
    after(:create) do |workflow_version|
      workflow_version.workflow.version += 1
      workflow_version.workflow.save
      workflow_version.version = workflow_version.workflow.version
      workflow_version.title = workflow_version.workflow.title
      workflow_version.save
    end
  end
  
  factory(:workflow_version_with_blob, parent: :workflow_version) do
    after(:create) do |workflow_version|
      if workflow_version.content_blob.blank?
        workflow_version.content_blob = FactoryBot.create(:cwl_content_blob,
                                                  asset: workflow_version.workflow,
                                                  asset_version: workflow_version.version)
      else
        workflow_version.content_blob.asset = workflow_version.workflow
        workflow_version.content_blob.asset_version = workflow_version.version
        workflow_version.content_blob.save
      end
    end
  end
  
  factory(:api_cwl_workflow, parent: :workflow) do
    association :content_blob, factory: :blank_cwl_content_blob
  end
  
  # A pre-made RO-Crate
  factory(:existing_galaxy_ro_crate_workflow, parent: :workflow) do
    association :content_blob, factory: :existing_galaxy_ro_crate
    workflow_class { WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class) }
  end
  
  # An RO-Crate generated by SEEK through the form on the workflow page
  factory(:generated_galaxy_ro_crate_workflow, parent: :workflow) do
    association :content_blob, factory: :generated_galaxy_ro_crate
    workflow_class { WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class) }
  end
  
  factory(:generated_galaxy_no_diagram_ro_crate_workflow, parent: :workflow) do
    association :content_blob, factory: :generated_galaxy_no_diagram_ro_crate
    workflow_class { WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class) }
  end
  
  factory(:nf_core_ro_crate_workflow, parent: :workflow) do
    association :content_blob, factory: :nf_core_ro_crate
    workflow_class { WorkflowClass.find_by_key('nextflow') || FactoryBot.create(:nextflow_workflow_class) }
  end
  
  factory(:just_cwl_ro_crate_workflow, parent: :workflow) do
    association :content_blob, factory: :just_cwl_ro_crate
  end
  
  factory(:workflow_with_tests, parent: :workflow) do
    association :content_blob, factory: :ro_crate_with_tests
  end
  
  factory(:spaces_ro_crate_workflow, parent: :workflow) do
    association :content_blob, factory: :spaces_ro_crate
    workflow_class { WorkflowClass.find_by_title('Jupyter Notebook') || FactoryBot.create(:jupyter_workflow_class) }
  end
  
  factory(:dots_ro_crate_workflow, parent: :workflow) do
    association :content_blob, factory: :dots_ro_crate
    workflow_class { WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class) }
  end
  
  factory(:remote_git_workflow, class: Workflow) do
    title { 'Concat two files' }
    with_project_contributor
    workflow_class { WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class) }
    git_version_attributes {
      repo = FactoryBot.create(:remote_repository)
      { git_repository_id: repo.id,
        ref: 'refs/heads/main',
        commit: 'b6312caabe582d156dd351fab98ce78356c4b74c',
        main_workflow_path: 'concat_two_files.ga',
        diagram_path: 'diagram.png',
      }
    }
  end
  
  factory(:annotationless_local_git_workflow, class: Workflow) do
    title { 'Concat two files' }
    with_project_contributor
    workflow_class { WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class) }
    git_version_attributes do
      repo = FactoryBot.create(:unlinked_local_repository)
      { git_repository_id: repo.id,
        ref: 'refs/heads/master',
        commit: '96aee188b2f9c145860f21dc182608fec5084a8a',
        mutable: true
      }
    end
  end
  
  factory(:local_git_workflow, class: Workflow) do
    title { 'Concat two files' }
    with_project_contributor
    workflow_class { WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class) }
    git_version_attributes do
      repo = FactoryBot.create(:unlinked_local_repository)
      { git_repository_id: repo.id,
        ref: 'refs/heads/master',
        commit: '96aee188b2f9c145860f21dc182608fec5084a8a',
        main_workflow_path: 'concat_two_files.ga',
        diagram_path: 'diagram.png',
        mutable: true
      }
    end
  end
  
  factory(:ro_crate_git_workflow, class: Workflow) do
    title { 'Sort and change case' }
    with_project_contributor
    workflow_class { WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class) }
    git_version_attributes do
      repo = FactoryBot.create(:remote_workflow_ro_crate_repository)
      { git_repository_id: repo.id,
        ref: 'refs/remotes/origin/master',
        commit: 'a321b6e',
        main_workflow_path: 'sort-and-change-case.ga',
        mutable: false
      }
    end
  end
  
  factory(:local_ro_crate_git_workflow, class: Workflow) do
    title { 'Sort and change case' }
    with_project_contributor
    workflow_class { WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class) }
    git_version_attributes do
      repo = FactoryBot.create(:workflow_ro_crate_repository)
      { git_repository_id: repo.id,
        ref: 'refs/heads/master',
        commit: 'a321b6e',
        main_workflow_path: 'sort-and-change-case.ga',
        mutable: false
      }
    end
  end
  
  factory(:local_ro_crate_git_workflow_with_tests, class: Workflow) do
    title { 'Sort and change case' }
    with_project_contributor
    workflow_class { WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class) }
    git_version_attributes do
      repo = FactoryBot.create(:workflow_ro_crate_repository)
      { git_repository_id: repo.id,
        ref: 'refs/heads/tests',
        commit: '612f7f7',
        main_workflow_path: 'sort-and-change-case.ga',
        mutable: false
      }
    end
  end
  
  factory(:nfcore_git_workflow, class: Workflow) do
    title { 'nf-core/rnaseq' }
    with_project_contributor
    workflow_class { WorkflowClass.find_by_key('nextflow') || FactoryBot.create(:nextflow_workflow_class) }
    git_version_attributes do
      repo = FactoryBot.create(:nfcore_local_rocrate_repository)
      { git_repository_id: repo.id,
        ref: 'refs/heads/master',
        commit: '3643a94411b65f42bce5357c5015603099556ad9',
        main_workflow_path: 'main.nf',
        mutable: true
      }
    end
  end
  
  factory(:empty_git_workflow, class: Workflow) do
    title { 'Empty Workflow' }
    with_project_contributor
    git_version_attributes do
      repo = FactoryBot.create(:blank_repository)
      { git_repository_id: repo.id, mutable: true }
    end
  end
  
  factory(:test_data_workflow_data_file_relationship, class: WorkflowDataFileRelationship) do
    title { 'Test data' }
    key { 'test' }
  end
  
  factory(:ro_crate_git_workflow_with_tests, class: Workflow) do
    title { 'Sort and change case' }
    with_project_contributor
    workflow_class { WorkflowClass.find_by_key('galaxy') || FactoryBot.create(:galaxy_workflow_class) }
    git_version_attributes do
      repo = FactoryBot.create(:remote_workflow_ro_crate_repository)
      { git_repository_id: repo.id,
        ref: 'refs/remotes/origin/tests',
        commit: '612f7f7',
        main_workflow_path: 'sort-and-change-case.ga',
        mutable: false
      }
    end
  end
end
