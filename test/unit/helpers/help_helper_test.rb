require 'test_helper'

class HelpHelperTest < ActionView::TestCase
  test 'help link' do
    link = help_link :investigation_checksum
    tag = HTML::Document.new(link).root.children.first
    assert_equal 'http://docs.seek4science.org/tech/investigation-checksum.html', tag['href']
    assert_equal '_blank', tag['target']
    assert_equal 'help', tag.children.first.content

    link = help_link :investigation_checksum, link_text: 'chicken soup'
    tag = HTML::Document.new(link).root.children.first
    assert_equal 'http://docs.seek4science.org/tech/investigation-checksum.html', tag['href']
    assert_equal '_blank', tag['target']
    assert_equal 'chicken soup', tag.children.first.content
  end

  test 'url only' do
    link = help_link :investigation_checksum, url_only: true
    assert_equal 'http://docs.seek4science.org/tech/investigation-checksum.html', link
  end
end
