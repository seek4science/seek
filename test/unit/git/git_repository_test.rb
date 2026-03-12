require 'test_helper'

class GitRepositoryTest < ActiveSupport::TestCase

  test 'init local repo' do
    repo = FactoryBot.create(:local_repository)
    assert File.exist?(File.join(repo.local_path, '.git', 'config'))
  end

  test 'fetch remote' do
    repo = FactoryBot.create(:remote_repository)
    RemoteGitFetchJob.perform_now(repo)
    remote = repo.git_base.remotes.first

    assert_equal 'origin', remote.name
    assert remote.url.end_with?('seek4science/workflow-test-fixture.git')
    assert File.exist?(File.join(repo.local_path, '.git', 'config'))
  ensure
    FileUtils.rm_rf(repo.remote) if repo
  end

  test "don't fetch if recently fetched" do
    repo = FactoryBot.create(:remote_repository, last_fetch: 5.minutes.ago)
    assert_no_difference('Task.count') do
      assert_no_enqueued_jobs(only: RemoteGitFetchJob) do
        repo.queue_fetch
      end
    end
  end

  test "fetch even if recently fetched with force option set" do
    repo = FactoryBot.create(:remote_repository, last_fetch: 5.minutes.ago)
    assert_difference('Task.count', 1) do
      assert_enqueued_jobs(1, only: RemoteGitFetchJob) do
        repo.queue_fetch(true)
      end
    end
  end

  test "fetch if not recently fetched" do
    repo = FactoryBot.create(:remote_repository, last_fetch: 30.minutes.ago)
    assert_difference('Task.count', 1) do
      assert_enqueued_jobs(1, only: RemoteGitFetchJob) do
        repo.queue_fetch
      end
    end
  end

  test 'redundant repositories' do
    redundant = Git::Repository.create!
    not_redundant = FactoryBot.create(:git_version).git_repository

    repositories = Git::Repository.redundant.to_a

    assert_includes repositories, redundant
    assert_not_includes repositories, not_redundant
  end

  test 'remote_refs' do
    repo = FactoryBot.create(:nfcore_remote_repository)
    refs = repo.remote_refs
    branches = refs[:branches]
    tags = refs[:tags]

    assert_equal %w[master arm change_testing_logic dev document_fastp_sampling feat/implement-ci-nf-tests
                        fix_bbsplit_config fix_gtf_unzip fix_salmon_args improve_rseqc_strandedness lpantano_patch_561
                        nf-core-template-merge-1.13 nf-core-template-merge-1.13.1 nf-core-template-merge-1.13.2
                        nf-core-template-merge-1.13.3 nf-test-cicd optimized-resources pytest-workflow TEMPLATE
                        update_default_pipeline_test], branches.map { |b| b[:name] },
                 'Branches should be sorted with the default branch first, and then alphabetically ascending'

    assert_equal %w[3.14.0 3.13.2 3.13.1 3.13.0 3.12.0 3.11.2 3.11.1 3.11.0 3.10.1 3.10 3.9 3.8.1 3.8 3.7 3.6 3.5
                        3.4 3.3 3.2 3.1 3.0 2.0 1.4.2 1.4.1 1.4 1.3 1.2 1.1 1.0], tags.map { |t| t[:name] },
                 'Tags should be sorted newest -> oldest'

    main = branches[0]
    assert_equal 'master', main[:name]
    assert_equal 'refs/remotes/origin/master', main[:ref]
    assert_equal 'b89fac32650aacc86fcda9ee77e00612a1d77066', main[:sha]
    assert_equal '2024-01-08 17:22:19 UTC', main[:time].utc.to_s

    three_twelve = tags.detect { |t| t[:name] == '3.12.0' }
    assert_equal '3.12.0', three_twelve[:name]
    assert_equal 'refs/tags/3.12.0', three_twelve[:ref]
    assert_equal '3bec2331cac2b5ff88a1dc71a21fab6529b57a0f', three_twelve[:sha]
    assert_equal '2023-06-02 15:37:43 UTC', three_twelve[:time].utc.to_s
  end
end
