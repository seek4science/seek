require 'test_helper'

class FilterTest < ActiveSupport::TestCase
  test 'apply filter' do
    tag_filter = Seek::Filterer::FILTERS[:tag]

    abc_doc = Factory(:document)
    abc_doc.annotate_with('abctag', 'tag', abc_doc.contributor)
    disable_authorization_checks { abc_doc.save! }
    abc = TextValue.where(text: 'abctag').first.id
    xyz_doc = Factory(:document)
    xyz_doc.annotate_with('xyztag', 'tag', xyz_doc.contributor)
    disable_authorization_checks { xyz_doc.save! }
    xyz = TextValue.where(text: 'xyztag').first.id

    docs = Document.all

    assert_equal [abc_doc.id], tag_filter.apply(docs, [abc]).to_a.map(&:id)
    assert_equal [xyz_doc.id], tag_filter.apply(docs, [xyz]).to_a.map(&:id)

    docs = tag_filter.apply(docs, [abc, xyz])
    assert_equal 2, docs.size
    assert_includes docs, abc_doc
    assert_includes docs, xyz_doc
  end

  test 'apply search filter' do
    assert true
  end

  test 'apply date filter' do
    assert true
  end

  test 'apply year filter' do
    assert true
  end

  test 'get filter options' do
    assert true
  end

  test 'get search filter options' do
    assert true
  end

  test 'get date filter options' do
    assert true
  end

  test 'get year filter options' do
    assert true
  end
end
