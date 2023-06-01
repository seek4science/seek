Factory.define(:blank_repository, class: Git::Repository) do |f|
  f.after_create do |r|
    FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'blank-repository', '_git', '.'), File.join(r.local_path, '.git'))
  end
end

Factory.define(:unlinked_local_repository, class: Git::Repository) do |f|
  f.after_create do |r|
    FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'local-fixture-workflow', '_git', '.'), File.join(r.local_path, '.git'))
  end
end

Factory.define(:local_repository, parent: :unlinked_local_repository) do |f|
  f.resource { Factory(:workflow) }
end

Factory.define(:unfetched_remote_repository, class: Git::Repository) do |f|
  f.remote "https://github.com/seek4science/workflow-test-fixture.git"
end

Factory.define(:remote_repository, parent: :unfetched_remote_repository) do |f|
  f.after_create do |r|
    FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'fixture-workflow', '_git', '.'), File.join(r.local_path, '.git'))
  end
end

Factory.define(:workflow_ro_crate_repository, class: Git::Repository) do |f|
  f.after_create do |r|
    FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'galaxy-sort-change-case', '_git', '.'), File.join(r.local_path, '.git'))
  end
end

Factory.define(:remote_workflow_ro_crate_repository, class: Git::Repository) do |f|
  f.after_create do |r|
    FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'galaxy-sort-change-case-remote', '_git', '.'), File.join(r.local_path, '.git'))
  end
  f.remote "https://somewhere.internets/repo.git"
end

Factory.define(:nfcore_local_rocrate_repository, class: Git::Repository) do |f|
  f.after_create do |r|
    FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'nf-core-rnaseq', '_git', '.'), File.join(r.local_path, '.git'))
  end
end

# GitVersions
Factory.define(:git_version, class: Git::Version) do |f|
  f.git_repository { Factory(:local_repository) }
  f.resource { self.git_repository.resource }
  f.name 'version 1.0.0'
  f.ref 'refs/heads/master'
  f.mutable true
  f.after_build do |v|
    v.contributor ||= v.resource.contributor
  end
  f.after_create do |v|
    v.sync_resource_attributes
  end
end

Factory.define(:remote_git_version, parent: :git_version) do |f|
  f.git_repository { Factory(:remote_repository) }
  f.resource { Factory(:workflow) }
  f.name 'v0.01'
  f.ref 'refs/tags/v0.01'
  f.commit '3f2c23e92da3ccbc89d7893b4af6039e66bdaaaf'
  f.mutable false
end

