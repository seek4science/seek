require 'test_helper'

class LicenseTest < ActiveSupport::TestCase
  setup do
    @zenodo = Seek::License.zenodo
    @od = Seek::License.open_definition
    @spdx = Seek::License.spdx
    @combined = Seek::License.combined
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
  end

  test 'can find licenses as hash in opendefinition vocab' do
    license = Seek::License.find_as_hash('CC-BY-4.0', @od)
    assert license.is_a?(Hash)
    assert_equal 'Creative Commons Attribution 4.0', license['title']
    assert_equal 'https://creativecommons.org/licenses/by/4.0/', license['url']
  end

  test 'can find licenses in spdx vocab' do
    license = Seek::License.find('CC-BY-4.0', @spdx)
    assert license.is_a?(Seek::License)
    assert_equal 'Creative Commons Attribution 4.0 International', license.title
    assert_equal 'https://spdx.org/licenses/CC-BY-4.0', license.url

    license = Seek::License.find('Zed', @spdx)
    assert license.is_a?(Seek::License)
    assert_equal 'Zed License', license.title
    assert_equal 'https://spdx.org/licenses/Zed', license.url
  end

  test 'can find licenses as hash in spdx vocab' do
    license = Seek::License.find_as_hash('Zed', @spdx)
    assert license.is_a?(Hash)
    assert_equal 'Zed License', license['title']
    assert_equal 'https://spdx.org/licenses/Zed', license['url']
  end

  test 'can find licenses in combined vocab' do
    license = Seek::License.find('other-at', @combined)
    assert license.is_a?(Seek::License)
    assert_equal 'Other (Attribution)', license.title
    assert_equal '', license.url

    license = Seek::License.find('notspecified', @combined)
    assert license.is_a?(Seek::License)
    assert_equal 'No license - no permission to use unless the owner grants a licence', license.title
    assert_equal 'https://choosealicense.com/no-permission/', license.url

    license = Seek::License.find('Zed', @combined)
    assert license.is_a?(Seek::License)
    assert_equal 'Zed License', license.title
    assert_equal 'https://spdx.org/licenses/Zed', license.url

    license = Seek::License.find('CC-BY-4.0')
    assert license.is_a?(Seek::License)
    assert_equal 'Creative Commons Attribution 4.0 International', license.title
    assert_equal 'https://spdx.org/licenses/CC-BY-4.0', license.url
  end

  test 'can find licenses as hash in combined vocab' do
    license = Seek::License.find_as_hash('other-at', @combined)
    assert license.is_a?(Hash)
    assert_equal 'Other (Attribution)', license['title']
    assert_equal '', license['url']

    license = Seek::License.find_as_hash('notspecified', @combined)
    assert license.is_a?(Hash)
    assert_equal 'No license - no permission to use unless the owner grants a licence', license['title']
    assert_equal 'https://choosealicense.com/no-permission/', license['url']

    license = Seek::License.find_as_hash('Zed', @combined)
    assert license.is_a?(Hash)
    assert_equal 'Zed License', license['title']
    assert_equal 'https://spdx.org/licenses/Zed', license['url']

    license = Seek::License.find_as_hash('CC-BY-4.0')
    assert license.is_a?(Hash)
    assert_equal 'Creative Commons Attribution 4.0 International', license['title']
    assert_equal 'https://spdx.org/licenses/CC-BY-4.0', license['url']
  end

  test 'returns nil when cannot find license' do
    assert_nil Seek::License.find('license-to-kill')
    assert_nil Seek::License.find('cc-by', @od)
    assert_nil Seek::License.find('CC-BY-4.0', @zenodo)
  end

  test 'override notspecified text and url' do
    refute_nil(license = Seek::License.find('notspecified'))
    assert license.is_a?(Seek::License)
    assert license.is_null_license?
    assert_equal 'No license - no permission to use unless the owner grants a licence',license['title']
    assert_equal 'https://choosealicense.com/no-permission/',license['url']

    #double check the main hash
    license_json = Seek::License.open_definition['notspecified']
    assert_equal license,Seek::License.new(license_json)
  end

  test 'license key is validated' do
    sop = FactoryBot.create(:sop, license: 'CC0-1.0')
    assert sop.valid?

    sop.license = 'CCZZ'
    refute sop.valid?
    assert_equal 1,sop.errors.count
    assert sop.errors.added?(:license, "isn't a recognized license")

    #allow blank
    sop.license=nil
    assert sop.valid?
    sop.license=''
    assert sop.valid?

    # allow a known software license, if it comes through the api
    sop.license = 'MIT'
    assert sop.valid?
  end

  test 'lookup license ID from URI' do
    assert_equal 'CC-BY-4.0', Seek::License.uri_to_id('https://spdx.org/licenses/CC-BY-4.0.html')
    assert_equal 'CC-BY-4.0', Seek::License.uri_to_id('https://spdx.org/licenses/CC-BY-4.0')
    assert_equal 'CC-BY-4.0', Seek::License.uri_to_id('https://creativecommons.org/licenses/by/4.0/')
    assert_equal 'CC-BY-4.0', Seek::License.uri_to_id('https://creativecommons.org/licenses/by/4.0/legalcode')

    assert_equal 'MIT-open-group', Seek::License.uri_to_id('https://gitlab.freedesktop.org/xorg/app/iceauth/-/blob/master/COPYING')

    assert_nil Seek::License.uri_to_id('https://creativecommons.org/licenses/by/5.0')
  end

  test 'set license via URI' do
    sop = FactoryBot.create(:sop, license: 'https://creativecommons.org/licenses/by/4.0/')
    assert sop.valid?
    assert_equal 'CC-BY-4.0', sop.license

    sop.license = 'CCZZ'
    refute sop.valid?
    assert_equal 1,sop.errors.count
    assert sop.errors.added?(:license, "isn't a recognized license")
    assert_equal 'CCZZ', sop.license
  end
end
