require 'test_helper'

class SamplesHelperTest < ActionView::TestCase
  test 'seek sample attribute display' do
    sample = Factory(:sample, policy: Factory(:public_policy))
    assert sample.can_view?
    display = seek_sample_attribute_display(sample.id)
    tag = HTML::Document.new(display).root.children.first
    assert_equal 'a', tag.name
    assert_equal "/samples/#{sample.id}", tag['href']
    assert_equal sample.title, tag.children.first.content

    # private sample
    sample = Factory(:sample, policy: Factory(:private_policy))
    refute sample.can_view?
    display = seek_sample_attribute_display(sample.id)
    tag = HTML::Document.new(display).root.children.first
    assert_equal 'span', tag.name
    assert_equal 'none_text', tag['class']
    assert_equal 'Hidden', tag.children.first.content

    # doesn't exist
    display = seek_sample_attribute_display(999_999)
    tag = HTML::Document.new(display).root.children.first
    assert_equal 'span', tag.name
    assert_equal 'none_text', tag['class']
    assert_equal 'Not found', tag.children.first.content
  end
end
