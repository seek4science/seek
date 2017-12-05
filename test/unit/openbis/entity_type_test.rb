require 'test_helper'
require 'openbis_test_helper'


class EntityTypeTest < ActiveSupport::TestCase

  def setup

    @openbis_endpoint = OpenbisEndpoint.new project: Factory(:project), username: 'seek', password: 'seek',
                                    web_endpoint: 'https://127.0.0.1:8443/openbis/openbis',
                                    as_endpoint: 'https://127.0.0.1:8443/openbis/openbis',
                                    dss_endpoint: 'https://127.0.0.1:8443/doesnotmatter',
                                    space_perm_id: 'SEEK',
                                    refresh_period_mins: 60
  end

  test 'setup work' do
    assert @openbis_endpoint.test_authentication
  end

  test 'SampleType by code' do
    type = Seek::Openbis::EntityType.SampleType(@openbis_endpoint, 'TZ_ASSAY')
    assert type
    assert_equal 'TZ_ASSAY', type.code
    assert_equal 'Sample', type.entity_type
    assert_equal 'SampleType', type.type_name

  end
end