require 'test_helper'

class DataCatalogueMockModelTest < ActiveSupport::TestCase

  def setup
    @data_catalogue = Seek::BioSchema::DataCatalogueMockModel.new
  end

  test 'date created' do
    ActivityLog.destroy_all
    assert_nil @data_catalogue.date_created

    now = 2.days.ago
    df = Factory(:data_file)
    travel_to(now) do
      log = Factory :activity_log, activity_loggable: df, action: 'create', controller_name: 'data_files'
    end
    travel_to(1.day.ago) do
      Factory :activity_log, activity_loggable: df, action: 'create', controller_name: 'data_files'
      Factory :activity_log, activity_loggable: df, action: 'create', controller_name: 'data_files'
    end

    assert_equal now.to_i, @data_catalogue.date_created.to_i
  end

  test 'url' do
    with_config_value(:site_base_host,'http://fish.com') do
      assert_equal 'http://fish.com',@data_catalogue.url
    end
  end

  test 'provider' do
    with_config_value(:project_name,'WIBBLE') do
      with_config_value(:project_link,'http://wibble.eu') do
        expected = {
            '@type' => 'Organization',
            'name' => 'WIBBLE',
            'url' => 'http://wibble.eu'
        }
        assert_equal expected, @data_catalogue.provider
      end
    end
  end

  test 'keywords' do
    with_config_value(:application_keywords,'a, b, c, d, e') do
      assert_equal'a, b, c, d, e',@data_catalogue.keywords
    end
  end

  test 'description' do
    with_config_value(:application_description,'The worlds best app') do
      assert_equal 'The worlds best app',@data_catalogue.description
    end
  end

  test 'title' do
    with_config_value(:application_name, 'bioschema supported app') do
      assert_equal('bioschema supported app',@data_catalogue.title)
    end
  end

  test 'to_schema_ld' do
    # just a sanity check the json parses
    with_config_value(:site_base_host,'http://fish.com') do
      with_config_value(:project_name,'WIBBLE') do
        with_config_value(:project_link,'http://wibble.eu') do
          with_config_value(:application_keywords,'a, b, c, d, e') do
            with_config_value(:application_description,'The worlds best app') do
              with_config_value(:application_name, 'bioschema supported app') do
                json = @data_catalogue.to_schema_ld
                JSON.parse(json)
              end
            end
          end
        end
      end
    end
  end

end