Factory.define(:local_repository, class: GitRepository) do |f|
  f.resource { Factory(:workflow) }
  f.after_create do |r|
    FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'nf-core-rnaseq', '_git'), File.join(r.local_path, '.git'))
  end
end

Factory.define(:remote_repository, class: GitRepository) do |f|
  f.remote File.join(Rails.root, 'test', 'fixtures', 'files', 'git', 'nf-core', 'chipseq')
  f.after_create do |r|
    FileUtils.cp_r(File.join(Rails.root, 'test', 'fixtures', 'git', 'nf-core-rnaseq', '_git'), File.join(r.local_path, '.git'))
  end
end
