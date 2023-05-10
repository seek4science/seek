require 'test_helper'

class GitBlobTest < ActiveSupport::TestCase
  setup do
    @resource = FactoryBot.create(:ro_crate_git_workflow)
    @git_version = @resource.git_version
  end

  test 'local blob' do
    local_blob = @git_version.get_blob('sort-and-change-case.ga')

    assert local_blob

    assert_equal 1, local_blob.annotations.count
    assert_equal 'sort-and-change-case.ga', local_blob.annotations.first.path
    assert_equal 'main_workflow', local_blob.annotations.first.key

    assert_nil local_blob.url
    refute local_blob.remote?
    assert_nil local_blob.remote_content

    assert_equal 3862, local_blob.size
    assert_equal 3862, local_blob.file_contents.size
    local_blob.file_contents do |c|
      assert_equal '{', c.read(1)
    end
  end

  test 'unfetched remote blob' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/little_file.txt", 'http://somewhere.com/text.txt'
    git_version = FactoryBot.create(:git_version)
    disable_authorization_checks do
      git_version.add_remote_file('remote.txt', 'http://somewhere.com/text.txt')
      git_version.save!
    end
    remote_blob = git_version.get_blob('remote.txt')

    assert remote_blob

    assert_equal 1, remote_blob.annotations.count
    assert_equal 'remote.txt', remote_blob.annotations.first.path
    assert_equal 'remote_source', remote_blob.annotations.first.key
    assert_equal 'http://somewhere.com/text.txt', remote_blob.annotations.first.value

    assert_equal 'http://somewhere.com/text.txt', remote_blob.url
    assert remote_blob.remote?
    refute remote_blob.fetched?
    io = remote_blob.remote_content
    assert io
    assert_equal 'little file', io.read

    assert_equal 0, remote_blob.size
    assert_equal 0, remote_blob.file_contents.size
    remote_blob.file_contents do |c|
      assert_nil c.read(1)
    end

    assert_equal 11, remote_blob.file_contents(fetch_remote: true).size
    remote_blob.file_contents(fetch_remote: true) do |c|
      assert_equal 'lit', c.read(3)
    end
  end

  test 'fetched remote blob' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/little_file.txt", 'http://somewhere.com/text.txt'
    git_version = FactoryBot.create(:git_version)
    disable_authorization_checks do
      git_version.add_remote_file('remote.txt', 'http://somewhere.com/text.txt')
      git_version.fetch_remote_file('remote.txt')
      git_version.save!
    end
    remote_blob = git_version.get_blob('remote.txt')

    assert remote_blob

    assert_equal 1, remote_blob.annotations.count
    assert_equal 'remote.txt', remote_blob.annotations.first.path
    assert_equal 'remote_source', remote_blob.annotations.first.key
    assert_equal 'http://somewhere.com/text.txt', remote_blob.annotations.first.value

    assert_equal 'http://somewhere.com/text.txt', remote_blob.url
    assert remote_blob.remote?
    assert remote_blob.fetched?
    io = remote_blob.remote_content
    assert io
    assert_equal 'little file', io.read

    assert_equal 11, remote_blob.size
    assert_equal 11, remote_blob.file_contents.size
    remote_blob.file_contents do |c|
      assert_equal 'lit', c.read(3)
    end

    assert_equal 11, remote_blob.file_contents(fetch_remote: true).size
    remote_blob.file_contents(fetch_remote: true) do |c|
      assert_equal 'lit', c.read(3)
    end
  end

  test 'search terms' do
    git_version = FactoryBot.create(:git_version)
    disable_authorization_checks do
      git_version.add_file('text.txt', open_fixture_file('large_text_file.txt'))
      git_version.add_file('binary.png', open_fixture_file('file_picture.png'))
      git_version.save!
    end

    text_blob = git_version.get_blob('text.txt')
    binary_blob = git_version.get_blob('binary.png')

    refute text_blob.binary?
    assert text_blob.text_contents_for_search.any? { |t| t.include?('cake') }

    assert binary_blob.binary?
    assert_empty binary_blob.text_contents_for_search
  end

  test 'equality' do
    blob1 = @git_version.get_blob('sort-and-change-case.ga')
    blob2 = Workflow::Git::Version.find(@git_version.id).get_blob('sort-and-change-case.ga')

    refute_equal blob1.object_id, blob2.object_id
    assert_equal blob1, blob2
  end

  test 'delegate read to file' do
    blob = @git_version.get_blob('sort-and-change-case.ga')
    one = blob.read(1)
    assert_equal "{", one
    sixteen = blob.read(16)
    assert_equal 16, sixteen.length
    eof = blob.read
    refute eof.start_with?('{')
    assert_includes eof, 'sort-and-change-case'
    assert_equal ((blob.size - 16) - 1), eof.length
  end
end
