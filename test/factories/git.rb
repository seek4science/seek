FactoryBot.define do
  factory(:blank_repository, class: Git::Repository) do
    after(:create) do |r|
      FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'blank-repository', '_git', '.'), File.join(r.local_path, '.git'))
    end
  end
  
  factory(:unlinked_local_repository, class: Git::Repository) do
    after(:create) do |r|
      FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'local-fixture-workflow', '_git', '.'), File.join(r.local_path, '.git'))
    end
  end
  
  factory(:local_repository, parent: :unlinked_local_repository) do
    resource { FactoryBot.create(:workflow) }
  end
  
  factory(:unfetched_remote_repository, class: Git::Repository) do
    remote { "https://github.com/seek4science/workflow-test-fixture.git" }
  end
  
  factory(:remote_repository, parent: :unfetched_remote_repository) do
    after(:create) do |r|
      FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'fixture-workflow', '_git', '.'), File.join(r.local_path, '.git'))
    end
  end
  
  factory(:workflow_ro_crate_repository, class: Git::Repository) do
    after(:create) do |r|
      FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'galaxy-sort-change-case', '_git', '.'), File.join(r.local_path, '.git'))
    end
  end
  
  factory(:remote_workflow_ro_crate_repository, class: Git::Repository) do
    after(:create) do |r|
      FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'galaxy-sort-change-case-remote', '_git', '.'), File.join(r.local_path, '.git'))
    end
    remote { "https://somewhere.internets/repo.git" }
  end
  
  factory(:nfcore_local_rocrate_repository, class: Git::Repository) do
    after(:create) do |r|
      FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'nf-core-rnaseq', '_git', '.'), File.join(r.local_path, '.git'))
    end
  end
  
  # GitVersions
  factory(:git_version, class: Git::Version) do
    git_repository { FactoryBot.create(:local_repository) }
    resource { self.git_repository.resource }
    name { 'version 1.0.0' }
    ref { 'refs/heads/master' }
    mutable { true }
    after(:build) do |v|
      v.contributor ||= v.resource.contributor
    end
    after(:create) do |v|
      v.sync_resource_attributes
    end
  end
  
  factory(:remote_git_version, parent: :git_version) do
    git_repository { FactoryBot.create(:remote_repository) }
    resource { FactoryBot.create(:workflow) }
    name { 'v0.01' }
    ref { 'refs/tags/v0.01' }
    commit { '3f2c23e92da3ccbc89d7893b4af6039e66bdaaaf' }
    mutable { false }
  end
  
end
