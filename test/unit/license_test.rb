require 'test_helper'

class LicenseTest < ActiveSupport::TestCase

  test 'can find licenses' do
    license = Seek::License.find('cc-by')
    assert license.is_a?(Seek::License)
    assert_equal "Creative Commons Attribution", license.title
    assert_equal "http://www.opendefinition.org/licenses/cc-by", license.url
  end

  test 'can find licenses as hash' do
    license = Seek::License.find_as_hash('cc-by')
    assert license.is_a?(Hash)
    assert_equal "Creative Commons Attribution", license['title']
    assert_equal "http://www.opendefinition.org/licenses/cc-by", license['url']
  end

  test 'returns nil when cannot find license' do
    assert_nil Seek::License.find('license-to-kill')
  end

end
