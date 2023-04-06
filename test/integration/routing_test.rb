require 'test_helper'

# tests related to general routes, that are not tied to a particular controller
class RoutingTest < ActionDispatch::IntegrationTest

  test 'related items routes' do
    # searchable_types covers all creatable types, plus some others that can be displayed and my have related items
    Seek::Util.searchable_types.each do |type|
      type.related_type_methods.each_key do |related_type|
        controller = related_type.tableize
        parent = type.name.tableize
        parent_key = "#{parent.singularize}_id".to_sym

        path = "#{parent}/2/#{controller}"

        assert_routing path, controller: controller, action: 'index', parent_key => '2'
      end
    end
  end

end