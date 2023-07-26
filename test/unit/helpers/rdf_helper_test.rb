require 'test_helper'


class RdfHelperTest < ActionView::TestCase

  test 'schema_ld_script_block' do
    @person = FactoryBot.create(:person)
    @investigation = FactoryBot.create(:investigation)

    # blank for not supported
    @controller = InvestigationsController.new
    @controller.action_name='show'
    assert schema_ld_script_block.blank?

    @controller = PeopleController.new
    @controller.action_name='new'
    assert schema_ld_script_block.blank?

    # none ActiveRecord resource, e.g. for search (this imitates the behaviour)
    @search = ActiveSupport::SafeBuffer.new('fish')
    @controller = SearchController.new
    @controller.action_name='show'
    assert schema_ld_script_block.blank?

    # now some actual content
    @controller = PeopleController.new
    @controller.action_name='show'
    block = schema_ld_script_block
    refute block.blank?


    frag = Nokogiri::HTML::DocumentFragment.parse(block)
    script = frag.children.first
    assert_equal 'script', script.name
    assert_equal 'application/ld+json', script.attributes['type'].content
    
    json = JSON.parse(frag.children.first.children.first.content)

    # TODO: check JSON LD
  end
end
