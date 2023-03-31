require 'test_helper'

class VersionTest < ActiveSupport::TestCase

  def teardown
    File.delete(Seek::Version::GIT_VERSION_RECORD_FILE_PATH) if File.exist?(Seek::Version::GIT_VERSION_RECORD_FILE_PATH)
  end

  test 'default path' do
    str = Seek::Version.read.to_s

    # basic sanity check, other tests using a test version.yml are more specific
    assert_equal 2, str.count('.')
    assert str.length > 2
  end

  test 'all numbers' do
    str = Seek::Version.read(File.join(Rails.root, 'test/fixtures/files/version1.test-yml')).to_s
    assert_equal '1.2.3', str
  end

  test 'wordy patch' do
    str = Seek::Version.read(File.join(Rails.root, 'test/fixtures/files/version2.test-yml')).to_s
    assert_equal '2.3.sprint-33', str
  end

  test 'no patch' do
    str = Seek::Version.read(File.join(Rails.root, 'test/fixtures/files/version3.test-yml')).to_s
    assert_equal '4.0', str
  end

  test 'APP_VERSION' do
    assert_equal Seek::Version::APP_VERSION, Seek::Version.read
  end

  test 'git_version_record_present?' do
    refute Seek::Version.git_version_record_present?
    File.write(Seek::Version::GIT_VERSION_RECORD_FILE_PATH, 'wibble')
    assert Seek::Version.git_version_record_present?
  end

  test 'git version' do
    real_git = `git rev-parse HEAD`.chomp
    assert_equal real_git, Seek::Version.git_version
    File.write(Seek::Version::GIT_VERSION_RECORD_FILE_PATH, 'abcdefghi')
    assert_equal 'abcdefghi', Seek::Version.git_version
  end
end
