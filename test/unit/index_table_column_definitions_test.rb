require 'test_helper'

class IndexTableColumnDefinitionsTest < ActiveSupport::TestCase

  def setup
    @assay = Factory(:experimental_assay)
    @data_file = Factory(:data_file)
    @person = Factory(:person)
    @project = Factory(:project)
  end

  test 'required columns' do
    assert_equal ['title'], Seek::IndexTableColumnDefinitions.required_columns(@assay)
    assert_equal ['title'], Seek::IndexTableColumnDefinitions.required_columns(@data_file)
    assert_equal ['title'], Seek::IndexTableColumnDefinitions.required_columns(@person)
    assert_equal ['title'], Seek::IndexTableColumnDefinitions.required_columns(@project)
  end

  test 'default columns' do
    assert_equal ['creators', 'projects', 'assay_type_uri','technology_type_uri'], Seek::IndexTableColumnDefinitions.default_columns(@assay)
    assert_equal ['creators', 'projects', 'version'], Seek::IndexTableColumnDefinitions.default_columns(@data_file)
    assert_equal ['projects','first_name','last_name'], Seek::IndexTableColumnDefinitions.default_columns(@person)
    assert_equal ['web_page'], Seek::IndexTableColumnDefinitions.default_columns(@project)
  end

  test 'allowed_columns' do
    assert_equal ['title', 'creators', 'projects', 'assay_type_uri', 'technology_type_uri', 'tags'], Seek::IndexTableColumnDefinitions.allowed_columns(@assay)
    assert_equal ['title', 'creators', 'projects', 'version','tags', 'format_type', 'data_type', 'last_used_at', 'other_creators','doi','license','simulation_data'], Seek::IndexTableColumnDefinitions.allowed_columns(@data_file)
    assert_equal ['title', 'projects','first_name','last_name','orcid'], Seek::IndexTableColumnDefinitions.allowed_columns(@person)
    assert_equal ['title','web_page','start_date','end_date'], Seek::IndexTableColumnDefinitions.allowed_columns(@project)
  end

end