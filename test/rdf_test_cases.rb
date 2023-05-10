module RdfTestCases
  extend ActiveSupport::Testing::Declarative # Allows `test 'bla' do` definitions

  test 'get rdf' do
    object = rdf_test_object

    # this strange bit of code forces the model to be reloaded from the database after being created by FactoryBot.
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

  test 'response code for not accessible rdf' do
    if model.respond_to?(:authorization_supported?) && model.authorization_supported?
      logout
      get :show, params: { id: private_rdf_test_object, format: 'rdf' }
      assert_response :forbidden
    end
  end

  test 'response code for not available rdf' do
    get :show, params: { id: (model.maximum(:id) || 0) + 100, format: 'rdf' }
    assert_response :not_found
  end

  private

  def model
    model_name.constantize
  end

  def model_name
    self.class.name.split('Controller').first.singularize
  end

  def rdf_test_object
    object = FactoryBot.create(model_name.underscore)
    login_as(object.contributor) if object.respond_to?(:contributor)
    object
  end

  def private_rdf_test_object
    FactoryBot.create(model_name.underscore, policy: FactoryBot.create(:private_policy))
  end

  def invoke_rdf_get(object)
    get :show, params: { id: object, format: 'rdf' }
  end

  def expected_rdf_resource_uri(object)
    Seek::Util.routes.polymorphic_url(object)
  end
end
