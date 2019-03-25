require 'test_helper'

class VersionTest < ActiveSupport::TestCase
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
end
