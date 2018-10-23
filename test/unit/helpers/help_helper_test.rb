require 'test_helper'

class HelpHelperTest < ActionView::TestCase
  test 'help link' do
    link = help_link :investigation_checksum
    tag = Nokogiri::HTML::DocumentFragment.parse(link).children.first
    assert_equal 'https://docs.seek4science.org/tech/investigation-checksum.html', tag['href']
    assert_equal '_blank', tag['target']
    assert_equal 'help', tag.children.first.content

    link = help_link :investigation_checksum, link_text: 'chicken soup'
    tag = Nokogiri::HTML::DocumentFragment.parse(link).children.first
    assert_equal 'https://docs.seek4science.org/tech/investigation-checksum.html', tag['href']
    assert_equal '_blank', tag['target']
    assert_equal 'chicken soup', tag.children.first.content
  end

  test 'url only' do
    link = help_link :investigation_checksum, url_only: true
    assert_equal 'https://docs.seek4science.org/tech/investigation-checksum.html', link
  end

  test 'include icon' do
    link = help_link :investigation_checksum, include_icon: true
    tag = Nokogiri::HTML::DocumentFragment.parse(link).children.first
    assert_equal 2,tag.children.count
    assert_equal 'help_icon',tag.children.first['class']
    assert_equal 'help', tag.children[1].content

    link = help_link :investigation_checksum, include_icon: false
    tag = Nokogiri::HTML::DocumentFragment.parse(link).children.first
    assert_equal 1,tag.children.count
    assert_equal 'help', tag.children.first.content

    link = help_link :investigation_checksum
    tag = Nokogiri::HTML::DocumentFragment.parse(link).children.first
    assert_equal 1,tag.children.count
    assert_equal 'help', tag.children.first.content
  end
end
