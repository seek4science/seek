require 'test_helper'

class LicenseTest < ActiveSupport::TestCase
  setup do
    @zenodo = Seek::License::ZENODO[:all]
    @od = Seek::License::OPENDEFINITION[:all]
  end

  test 'can find licenses in zenodo vocab' do
    license = Seek::License.find('cc-by', @zenodo)
    assert license.is_a?(Seek::License)
    assert_equal 'Creative Commons Attribution', license.title
    assert_equal 'http://www.opendefinition.org/licenses/cc-by', license.url
  end

  test 'can find licenses as hash in zenodo vocab' do
    license = Seek::License.find_as_hash('cc-by', @zenodo)
    assert license.is_a?(Hash)
    assert_equal 'Creative Commons Attribution', license['title']
    assert_equal 'http://www.opendefinition.org/licenses/cc-by', license['url']
  end

  test 'can find licenses in opendefinition vocab' do
    license = Seek::License.find('CC-BY-4.0', @od)
    assert license.is_a?(Seek::License)
    assert_equal 'Creative Commons Attribution 4.0', license.title
    assert_equal 'https://creativecommons.org/licenses/by/4.0/', license.url

    license = Seek::License.find('CC-BY-4.0')
    assert license.is_a?(Seek::License)
    assert_equal 'Creative Commons Attribution 4.0', license.title
    assert_equal 'https://creativecommons.org/licenses/by/4.0/', license.url
  end

  test 'can find licenses as hash in opendefinition vocab' do
    license = Seek::License.find_as_hash('CC-BY-4.0', @od)
    assert license.is_a?(Hash)
    assert_equal 'Creative Commons Attribution 4.0', license['title']
    assert_equal 'https://creativecommons.org/licenses/by/4.0/', license['url']
  end

  test 'returns nil when cannot find license' do
    assert_nil Seek::License.find('license-to-kill')
    assert_nil Seek::License.find('cc-by', @od)
    assert_nil Seek::License.find('CC-BY-4.0', @zenodo)
  end
end
