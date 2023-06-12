require 'test_helper'

class LicenseTest < ActiveSupport::TestCase
  setup do
    @zenodo = Seek::License.zenodo[:all]
    @od = Seek::License.open_definition[:all]
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

  test 'override notspecified text and url' do
    refute_nil (license = Seek::License.find('notspecified'))
    assert license.is_a?(Seek::License)
    assert license.is_null_license?
    assert_equal 'No license - no permission to use unless the owner grants a licence',license['title']
    assert_equal 'https://choosealicense.com/no-permission/',license['url']

    #double check the main hash
    license_json = Seek::License.open_definition[:all].find{|x| x['id']=='notspecified'}
    assert_equal license,Seek::License.new(license_json)
  end

  test 'license key is validated' do
    sop = FactoryBot.create(:sop, license: 'CC0-1.0')
    assert sop.valid?

    sop.license = 'CCZZ'
    refute sop.valid?
    assert_equal 1,sop.errors.count
    assert sop.errors.added?(:license, "isn't a valid license ID")

    #allow blank
    sop.license=nil
    assert sop.valid?
    sop.license=''
    assert sop.valid?

    # allow a known software license, if it comes through the api
    sop.license = 'MIT'
    assert sop.valid?
  end

end
