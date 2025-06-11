require 'test_helper'

class IndexPagesTest < ActionDispatch::IntegrationTest

  test 'test list items with deleted contributor' do
    types = Person::RELATED_RESOURCE_TYPES
    types.collect do |type|
      factory_name = if type == 'Strain'
                       type.underscore
                     else
                       "max_#{type.underscore}"
                     end
      item = FactoryBot.create(factory_name.to_sym, deleted_contributor: 'Person:1',
                                                    policy: FactoryBot.create(:public_policy))
      item.update_column(:contributor_id, nil)

      assert item.can_view?
      refute_nil item.deleted_contributor
      assert_nil item.contributor

      with_config_value(:isa_json_compliance_enabled, true) do
        get polymorphic_path([item.class])
      end

      assert_response :success

      assert_select '.list_items_container' do
        assert_select '.list_item', minimum: 1
        assert_select '.list_item_title a[href=?]', polymorphic_path(item)
      end
    end
  end
end
