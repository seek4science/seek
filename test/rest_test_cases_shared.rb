
# frozen_string_literal: true

# methods that are shared between the JSON and XML test rest cases
module RestTestCasesShared
  def response_code_for_not_available(format)
    clz = @controller.controller_name.classify.constantize
    id = 9999
    id += 1 until clz.find_by_id(id).nil?

    url_opts = rest_show_url_options.merge(id: id, format: format)

    logout

    get :show, url_opts
    assert_response :not_found
  end

  def response_code_for_not_accessible(format)
    clz = @controller.controller_name.classify.constantize
    if clz.respond_to?(:authorization_supported?) && clz.authorization_supported?
      itemname = @controller.controller_name.singularize.underscore
      item = Factory itemname.to_sym, policy: Factory(:private_policy)
      url_opts = rest_show_url_options.merge(id: item.id, format: format)
      logout

      get :show, url_opts
      assert_response :forbidden
    end
  end

  def rest_show_url_options(_object = rest_api_test_object)
    {}
  end
end
