require 'test_helper'

class CitationsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper
  include MockHelper

  test 'can get various citation styles' do
    doi_citation_mock
    doi = '10.5072/test'

    get :fetch, params: { doi: doi, style: 'the-lancet', format: :js }, xhr: true
    assert_response :success
    assert @response.body.include?('Bacall F') # No comma

    get :fetch, params: { doi: doi, style: 'bibtex', format: :js }, xhr: true
    assert_response :success
    assert @response.body.include?('author={Bacall, Finn and')
  end
end
