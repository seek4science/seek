require 'test_helper'

class ResourceListHelperTest < ActionView::TestCase

  test 'resource_list_table_row' do
    sop = FactoryBot.create(:max_sop)
    html = resource_list_table_row(sop, sop.allowed_table_columns)
    assert_equal sop.allowed_table_columns.length, html.scan('<td>').count
  end

  test 'resource_list_condensed_row' do
    event = FactoryBot.create(:event)
    assert event.default_table_columns.count >= 3
    html = resource_list_condensed_row(event)
    assert_equal 3, html.scan(/div class=\"rli-condensed-attribute\"/).count
  end

  test 'resource_list_column_display_value' do

    data_file = FactoryBot.create(:max_data_file, license: 'CC-BY-4.0')

    assert_equal date_as_string(data_file.created_at, true), resource_list_column_display_value(data_file, 'created_at')
    assert_equal date_as_string(data_file.updated_at, true), resource_list_column_display_value(data_file, 'updated_at')

    assert_equal link_to(data_file.contributor.name, data_file.contributor),
                 resource_list_column_display_value(data_file, 'contributor')
    assert_equal link_to('Creative Commons Attribution 4.0', 'https://creativecommons.org/licenses/by/4.0/', target: :_blank),
                 resource_list_column_display_value(data_file, 'license')

    assert_match(/href="#{data_file_path(data_file)}".*#{data_file.title}/,
                 resource_list_column_display_value(data_file, 'title'))
    assert_equal data_file.description, resource_list_column_display_value(data_file, 'description')

    creator = data_file.creators.first
    refute_nil creator
    assert_match(/href="#{person_path(creator)}".*#{creator.name}/, resource_list_column_display_value(data_file, 'creators'))

    project = data_file.projects.first
    assert_match(/href="#{project_path(project)}".*#{project.title}/,
                 resource_list_column_display_value(data_file, 'projects'))

    FactoryBot.create(:topics_controlled_vocab) unless SampleControlledVocab::SystemVocabs.topics_controlled_vocab
    unless SampleControlledVocab::SystemVocabs.operations_controlled_vocab
      FactoryBot.create(:operations_controlled_vocab)
    end
    workflow = FactoryBot.create(:max_workflow)
    assert_match(%r{href="https://edamontology.github.io/edam-browser/#topic_3314".*Chemistry},
                 resource_list_column_display_value(workflow, 'topic_annotation_values'))
    assert_match(%r{href="https://edamontology.github.io/edam-browser/#operation_3432".*Clustering},
                 resource_list_column_display_value(workflow, 'operation_annotation_values'))

    assay = FactoryBot.create(:experimental_assay)
    assert_match(%r{href="/technology_types\?label=Technology\+type.*".*Technology type},
                 resource_list_column_display_value(assay, 'technology_type_uri'))
    assert_match(%r{href="/assay_types\?label=Experimental\+assay\+type.*".*Experimental assay type},
                 resource_list_column_display_value(assay, 'assay_type_uri'))

    event = FactoryBot.create(:event, country: 'US')
    assert_match %r{href="/countries/US".*United States}, resource_list_column_display_value(event, 'country')
    assert_match %r{<img.*us.png}, resource_list_column_display_value(event, 'country')

    error = assert_raises(RuntimeError) do
      resource_list_column_display_value(assay, 'id')
    end
    assert_equal 'Invalid column', error.message
  end
end
