
module RdfTestCases
  def test_get_rdf
    object = rest_api_test_object

    # this strange bit of code forces the model to be reloaded from the database after being created by FactoryGirl.
    # this is to (possibly) avoid a variation in the updated_at timestamps. It means the comparison is always against what
    # in the in the database, rather than between that created in memory and that in the database.
    object = object.class.find(object.id)

    expected_resource_uri = expected_rdf_resource_uri(object)

    assert object.can_view?
    assert object.respond_to?(:to_rdf)
    invoke_rdf_get(object)
    assert_response :success
    rdf = @response.body

    assert_equal object.to_rdf, rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 0
      assert_equal RDF::URI.new(expected_resource_uri), reader.statements.first.subject
      reader.rewind
      reader.each_statement do |statement|
        assert statement.valid?, "RDF contained an invalid statement - #{statement}"
      end
    end
  end

  def invoke_rdf_get(object)
    get :show, params: { id: object, format: 'rdf' }
  end

  def expected_rdf_resource_uri(object)
    eval("#{object.class.name.underscore}_url(object,:host=>'localhost',:port=>'3000')")
  end

  def test_response_code_for_not_accessible_rdf
    clz = @controller.controller_model
    if clz.respond_to?(:authorization_supported?) && clz.authorization_supported?
      itemname = @controller.controller_name.singularize.underscore
      item = Factory itemname.to_sym, policy: Factory(:private_policy)

      logout
      get :show, params: { id: item.id, format: 'rdf' }
      assert_response :forbidden
    end
  end

  def test_response_code_for_not_available_rdf
    clz = @controller.controller_model
    id = 9999
    id += 1 until clz.find_by_id(id).nil?

    logout
    get :show, params: { id: id, format: 'rdf' }
    assert_response :not_found
  end
end
