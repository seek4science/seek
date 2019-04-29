require 'test_helper'

class QueueNamesTest < ActiveSupport::TestCase

  test 'queue names' do
    assert_equal 'samples', QueueNames::SAMPLES
    assert_equal 'remotecontent', QueueNames::REMOTE_CONTENT
    assert_equal 'authlookup', QueueNames::AUTH_LOOKUP
    assert_equal 'default', QueueNames::DEFAULT
    assert_equal 'mailers', QueueNames::MAILERS
  end

end