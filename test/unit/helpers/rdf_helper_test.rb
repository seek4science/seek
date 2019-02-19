require 'test_helper'

class RdfHelperTest < ActionView::TestCase

  test 'schema_ld_script_block' do
    @person = Factory(:person)
    @investigation = Factory(:investigation)

    # blank for not supported
    @controller = InvestigationsController.new
    assert schema_ld_script_block.blank?

    # now some actual content
    @controller = PeopleController.new
    block = schema_ld_script_block
    refute block.blank?

    doc = HTML::Document.new(block)
    script = doc.root.children.first
    assert_equal 'script',script.name
    assert_equal 'application/ld+json',script.attributes['type']

    json = JSON.parse(doc.root.children.first.children.first.content)

    # TODO: check JSON LD



  end

end