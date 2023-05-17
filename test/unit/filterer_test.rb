require 'test_helper'

class FiltererTest < ActiveSupport::TestCase
  test 'available filters' do
    data_file_filters = Seek::Filterer.new(DataFile).available_filter_keys
    assay_filters = Seek::Filterer.new(Assay).available_filter_keys

    assert_includes data_file_filters, :query
    assert_includes data_file_filters, :tag
    assert_includes data_file_filters, :created_at
    assert_includes data_file_filters, :project
    assert_not_includes data_file_filters, :assay_class

    assert_includes assay_filters, :query
    assert_includes assay_filters, :tag
    assert_includes assay_filters, :created_at
    assert_includes assay_filters, :project
    assert_includes assay_filters, :assay_class
    assert_not_includes assay_filters, :published_year

    Banana = Class.new(ApplicationRecord)
    banana_filters = Seek::Filterer.new(Banana).available_filter_keys
    assert_includes banana_filters, :created_at, 'Should automatically include some filters'
  end

  test 'get filter' do
    data_file_filterer = Seek::Filterer.new(DataFile)
    publication_filterer = Seek::Filterer.new(Publication)

    query_filter = data_file_filterer.get_filter(:query)
    assert query_filter.is_a?(Seek::Filtering::SearchFilter)

    tag_filter = data_file_filterer.get_filter(:tag)
    assert tag_filter.is_a?(Seek::Filtering::Filter)

    created_at_filter = data_file_filterer.get_filter(:created_at)
    assert created_at_filter.is_a?(Seek::Filtering::DateFilter)

    published_year_filter = publication_filterer.get_filter(:published_year)
    assert published_year_filter.is_a?(Seek::Filtering::YearFilter)

    assert_nil data_file_filterer.get_filter(:banana)
  end

  test 'get active filter values' do
    person_filterer = Seek::Filterer.new(Person)

    active_filter_values = person_filterer.active_filter_values(
        {
            query: ['hello'],
            project: ['1', '300'],
            expertise: ['', nil],
            bananas: ['420']
        })

    assert_equal ['hello'], active_filter_values[:query]
    assert_equal ['1', '300'], active_filter_values[:project]
    assert_equal [], active_filter_values[:expertise]
    assert_nil active_filter_values[:bananas]
    assert_nil active_filter_values[:apples]
  end

  test 'get available filters' do
    assert_equal 0, Document.count
    project = FactoryBot.create(:project)
    project_doc = FactoryBot.create(:document, created_at: 3.days.ago, projects: [project])
    old_project_doc = FactoryBot.create(:document, created_at: 10.years.ago, projects: [project])
    other_project = FactoryBot.create(:project)
    other_project_doc = FactoryBot.create(:document, created_at: 3.days.ago, projects: [other_project])

    document_filterer = Seek::Filterer.new(Document)

    # All documents
    available_filters = document_filterer.available_filters(Document.all, {})
    assert_equal 3, available_filters[:contributor].length
    assert_equal 2, available_filters[:project].length
    project_ids = available_filters[:project].map { |o| o.value }
    assert_includes project_ids, project.id.to_s
    assert_includes project_ids, other_project.id.to_s
    assert_equal 2, available_filters[:project].detect { |o| o.value == project.id.to_s }.count
    assert_equal 1, available_filters[:project].detect { |o| o.value == other_project.id.to_s }.count

    # Apply "created in the last 1 year" filter.
    available_filters = document_filterer.available_filters(Document.all, { created_at: ['P1Y'] })
    assert_equal 2, available_filters[:contributor].length
    assert_equal 2, available_filters[:project].length
    project_ids = available_filters[:project].map { |o| o.value }
    assert_includes project_ids, project.id.to_s
    assert_includes project_ids, other_project.id.to_s
    assert_equal 1, available_filters[:project].detect { |o| o.value == project.id.to_s }.count
    assert_equal 1, available_filters[:project].detect { |o| o.value == other_project.id.to_s }.count

    # Apply "project" filter.
    available_filters = document_filterer.available_filters(Document.all, { project: [project.id.to_s] })
    assert_equal 2, available_filters[:contributor].length
    assert_equal 2, available_filters[:project].length
    project_ids = available_filters[:project].map { |o| o.value }
    assert_includes project_ids, project.id.to_s
    assert_includes project_ids, other_project.id.to_s, "Should still include other project ID as an 'or' option"
    assert_equal 2, available_filters[:project].detect { |o| o.value == project.id.to_s }.count
    assert available_filters[:project].detect { |o| o.value == project.id.to_s }.active?
    assert_equal 1, available_filters[:project].detect { |o| o.value == other_project.id.to_s }.count
    refute available_filters[:project].detect { |o| o.value == other_project.id.to_s }.active?

    # Apply "contributor" filter.
    available_filters = document_filterer.available_filters(Document.all, { contributor: [project_doc.contributor.id.to_s] })
    assert_equal 3, available_filters[:contributor].length
    assert_equal 1, available_filters[:project].length
    project_ids = available_filters[:project].map { |o| o.value }
    assert_includes project_ids, project.id.to_s
    assert_not_includes project_ids, other_project.id.to_s
    assert_equal 1, available_filters[:project].detect { |o| o.value == project.id.to_s }.count
  end

  test 'perform filtering' do
    assert_equal 0, Document.count
    project = FactoryBot.create(:project)
    project_doc = FactoryBot.create(:private_document, created_at: 3.days.ago, projects: [project])
    old_project_doc = FactoryBot.create(:public_document, created_at: 10.years.ago, projects: [project])
    other_project = FactoryBot.create(:project)
    other_project_doc = FactoryBot.create(:public_document, created_at: 3.days.ago, projects: [other_project])

    document_filterer = Seek::Filterer.new(Document)

    # All documents
    docs = Document.all
    filtered_docs = document_filterer.filter(docs, {})
    assert_equal docs, filtered_docs

    # All documents filtered by project
    docs = Document.all
    filtered_docs = document_filterer.filter(docs, { project: [project.id.to_s] })
    assert_equal 2, filtered_docs.length
    assert_includes filtered_docs, project_doc
    assert_includes filtered_docs, old_project_doc

    # All documents filtered by multiple projects
    docs = Document.all
    filtered_docs = document_filterer.filter(docs, { project: [project.id.to_s, other_project.id.to_s] })
    assert_equal 3, filtered_docs.length
    assert_includes filtered_docs, project_doc
    assert_includes filtered_docs, old_project_doc
    assert_includes filtered_docs, other_project_doc

    # All documents filtered by project and contributor
    docs = Document.all
    filtered_docs = document_filterer.filter(docs, { project: [project.id.to_s], contributor: [project_doc.contributor.id.to_s] })
    assert_equal 1, filtered_docs.length
    assert_includes filtered_docs, project_doc

    with_config_value(:solr_enabled, false) do
      # All documents filtered by project and contributor and query (useless since solr is not enabled, but should cover some code)
      docs = Document.all
      filtered_docs = document_filterer.filter(docs, { project: [project.id.to_s],
                                                       contributor: [project_doc.contributor.id.to_s],
                                                       query: ['hello']})
      assert_equal 1, filtered_docs.length
      assert_includes filtered_docs, project_doc
    end

    # Public documents filtered by project
    docs = Document.where(id: Document.authorized_for('view').map(&:id)) # We have to do this because auth lookup is not enabled in tests :(
    filtered_docs = document_filterer.filter(docs, { project: [project.id.to_s] })
    assert_equal 1, filtered_docs.length
    assert_includes filtered_docs, old_project_doc

    # All documents filtered by created date (as ISO8601 duration)
    docs = Document.all
    filtered_docs = document_filterer.filter(docs, { created_at: ['P1Y']})
    assert_equal 2, filtered_docs.length
    assert_includes filtered_docs, project_doc
    assert_includes filtered_docs, other_project_doc

    # All documents filtered by created date (as ISO8601 date)
    docs = Document.all
    filtered_docs = document_filterer.filter(docs, { created_at: [(Date.today - 2.years).iso8601]})
    assert_equal 2, filtered_docs.length
    assert_includes filtered_docs, project_doc
    assert_includes filtered_docs, other_project_doc

    # All documents filtered by created date (as ISO8601 date range)
    docs = Document.all
    filtered_docs = document_filterer.filter(docs, { created_at: [(Date.today - 11.years).iso8601 + "/" + (Date.today - 9.years).iso8601]})
    assert_equal 1, filtered_docs.length
    assert_includes filtered_docs, old_project_doc

    # All documents filtered by created date (as multiple ISO8601 date ranges)
    docs = Document.all
    filtered_docs = document_filterer.filter(docs, { created_at: [
        (Date.today - 20.years).iso8601 + "/" + (Date.today - 19.years).iso8601,
        (Date.today - 2.days).iso8601 + "/" + (Date.today - 1.day).iso8601
    ]})
    assert_equal 0, filtered_docs.length
  end
end
