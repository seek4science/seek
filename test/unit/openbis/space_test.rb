require 'test_helper'

class SpaceTest  < ActiveSupport::TestCase

  def setup
    Seek::Openbis::ConnectionInfo.setup('apiuser','apiuser','https://openbis-api.fair-dom.org/openbis/openbis','https://openbis-api.fair-dom.org/openbis/openbis')
  end

  test 'all' do
    all = Seek::Openbis::Space.all.sort_by(&:code)
    assert_equal 2,all.count
    assert_equal 'API-SPACE',all.first.code
    assert_equal 'API-SPACE',all.first.perm_id
    assert_equal 'use for testing openbis api integration ',all.first.description

    assert_equal 'DEFAULT',all.last.code
    assert_equal '',all.last.description
  end

end