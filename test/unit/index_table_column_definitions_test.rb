require 'test_helper'

class IndexTableColumnDefinitionsTest < ActiveSupport::TestCase
  def setup
    @assay = FactoryBot.create(:experimental_assay)
    @data_file = FactoryBot.create(:data_file)
    @person = FactoryBot.create(:person)
    @project = FactoryBot.create(:project)
  end

  test 'required columns' do
    assert_equal ['title'], Seek::IndexTableColumnDefinitions.required_columns(@assay)
    assert_equal ['title'], Seek::IndexTableColumnDefinitions.required_columns(@data_file)
    assert_equal ['title'], Seek::IndexTableColumnDefinitions.required_columns(@person)
    assert_equal ['title'], Seek::IndexTableColumnDefinitions.required_columns(@project)
  end

  test 'default columns' do
    assert_equal %w[creators projects assay_type_uri], Seek::IndexTableColumnDefinitions.default_columns(@assay)
    assert_equal %w[creators projects version license],
                 Seek::IndexTableColumnDefinitions.default_columns(@data_file)
    assert_equal %w[first_name last_name projects], Seek::IndexTableColumnDefinitions.default_columns(@person)
    assert_equal ['web_page'], Seek::IndexTableColumnDefinitions.default_columns(@project)
  end

  test 'allowed_columns' do
    assert_equal %w[title creators projects assay_type_uri technology_type_uri contributor description created_at updated_at other_creators tags],
                 Seek::IndexTableColumnDefinitions.allowed_columns(@assay)
    assert_equal %w[title creators projects version license data_type_annotation_values data_format_annotation_values simulation_data contributor description created_at updated_at other_creators doi tags],
                 Seek::IndexTableColumnDefinitions.allowed_columns(@data_file)
    assert_equal %w[title first_name last_name projects orcid description],
                 Seek::IndexTableColumnDefinitions.allowed_columns(@person)
    assert_equal %w[title web_page start_date end_date topic_annotation_values description created_at updated_at],
                 Seek::IndexTableColumnDefinitions.allowed_columns(@project)
  end

  test 'sanity check and responds to' do
    [Assay, Study, Investigation, Model, Sop, DataFile, FileTemplate, Placeholder, Presentation, Document, Workflow,
     Event, Publication, Organism, SampleType, Institution, Person, Project].each do |type|
      obj = type.new
      refute_empty Seek::IndexTableColumnDefinitions.default_columns(obj)
      refute_empty Seek::IndexTableColumnDefinitions.required_columns(obj)
      allowed = Seek::IndexTableColumnDefinitions.allowed_columns(obj)
      refute_empty allowed
      allowed.each do |col|
        assert obj.respond_to?(col)
      end
    end
  end

  test 'via model accessor' do
    assert_equal ['title'], @person.required_table_columns
    assert_equal %w[title first_name last_name projects orcid description], @person.allowed_table_columns
    assert_equal %w[first_name last_name projects], @person.default_table_columns
  end
end
