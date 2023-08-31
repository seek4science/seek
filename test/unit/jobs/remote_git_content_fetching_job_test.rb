require 'test_helper'
require 'minitest/mock'

class RemoteGitContentFetchingJobTest < ActiveSupport::TestCase

  test 'perform' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/little_file.txt", 'http://somewhere.com/text.txt'

    gv = FactoryBot.create(:git_version)
    disable_authorization_checks do
      gv.add_file('remote-file.txt', StringIO.new(''))
      gv.remote_sources = { 'remote-file.txt' => 'http://somewhere.com/text.txt' }
      gv.save
      gv.reload
    end

    old_commit = gv.commit

    assert_equal 'http://somewhere.com/text.txt', gv.remote_sources['remote-file.txt']
    assert_equal '', gv.file_contents('remote-file.txt')

    RemoteGitContentFetchingJob.perform_now(gv, 'remote-file.txt')

    assert_not_equal old_commit, gv.reload.commit
    assert_equal 'little file', gv.file_contents('remote-file.txt')
  end

  test 'fail due to http error' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/little_file.txt", 'http://somewhere.com/text.txt', {}, 404

    gv = FactoryBot.create(:git_version)
    disable_authorization_checks do
      gv.add_file('remote-file.txt', StringIO.new(''))
      gv.remote_sources = { 'remote-file.txt' => 'http://somewhere.com/text.txt' }
      gv.save
      gv.reload
    end

    old_commit = gv.commit

    assert_equal 'http://somewhere.com/text.txt', gv.remote_sources['remote-file.txt']
    assert_equal '', gv.file_contents('remote-file.txt')

    RemoteGitContentFetchingJob.perform_now(gv, 'remote-file.txt')

    assert_equal old_commit, gv.reload.commit
    assert_equal '', gv.file_contents('remote-file.txt')
  end
end
