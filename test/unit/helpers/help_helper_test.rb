require 'test_helper'

class HelpHelperTest < ActionView::TestCase
  include ApplicationHelper

  test 'help link' do
    link = help_link :investigation_checksum
    tag = Nokogiri::HTML::DocumentFragment.parse(link).children.first
    assert_equal 'https://docs.seek4science.org/tech/investigation-checksum.html', tag['href']
    assert_equal '_blank', tag['target']
    assert_equal 'Help', tag.children.first.content

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
    assert_equal 'Help', tag.children[1].content

    link = help_link :investigation_checksum, include_icon: false
    tag = Nokogiri::HTML::DocumentFragment.parse(link).children.first
    assert_equal 1,tag.children.count
    assert_equal 'Help', tag.children.first.content

    link = help_link :investigation_checksum
    tag = Nokogiri::HTML::DocumentFragment.parse(link).children.first
    assert_equal 1,tag.children.count
    assert_equal 'Help', tag.children.first.content
  end

  test 'help icon' do
    link = index_and_new_help_icon 'collection'
    tag = Nokogiri::HTML::DocumentFragment.parse(link).children.first
    
    assert_equal 'https://docs.seek4science.org/help/user-guide/collections.html', tag['href']
    assert_equal '_blank', tag['target']
    assert_equal t("info_text.collection"), tag['data-tooltip']
    assert_equal 'What is a Collection?', tag.children[1].content
  end

  test 'help icon indefinite article do adapt' do
    link = index_and_new_help_icon 'assay'
    tag = Nokogiri::HTML::DocumentFragment.parse(link).children.first

    assert_equal 'What is an Assay?', tag.children[1].content
  end

  test 'what is help icon with text' do
    link = what_is_help_icon_with_link 'Collection', 'chicken soup'
    tag = Nokogiri::HTML::DocumentFragment.parse(link).children.first

    assert_equal 'https://docs.seek4science.org/help/user-guide/collections.html', tag['href']
    assert_equal '_blank', tag['target']
    assert_equal 'What is a Collection?', tag.children[1].content
    assert_equal 'chicken soup', tag['data-tooltip']
  end

  test 'help icon no key' do
    span_tag = index_and_new_help_icon 'not_an_entity'
    tag = Nokogiri::HTML::DocumentFragment.parse(span_tag).children.first
    assert_nil tag
  end

end
