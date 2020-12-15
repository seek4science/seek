Factory.define(:local_repository, class: GitRepository) do |f|
  f.resource { Factory(:workflow) }
end

Factory.define(:remote_repository, class: GitRepository) do |f|
  f.resource { Factory(:workflow) }
  f.remote File.join(Rails.root, 'test', 'fixtures', 'files', 'git', 'nf-core', 'chipseq')
end
