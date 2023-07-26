require 'test_helper'

class SampleControlledVocabsControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  test 'show' do
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    get :show, params: { id: cv }
    assert_response :success
    assert_select 'table' do
      assert_select 'tbody tr', count: 4
      assert_select 'tr>td', text: 'Bramley', count: 1
      assert_select 'tr>td', text: 'Orange', count: 0
    end
  end

  test 'show for ontology' do
    cv = FactoryBot.create(:ontology_sample_controlled_vocab)
    get :show, params: { id: cv }
    assert_response :success
    assert_select 'table' do
      assert_select 'tbody tr', count: 3
      assert_select 'tbody tr' do
        assert_select 'td', text: 'Parent', count: 1
        assert_select 'td', text: 'Father', count: 1
        assert_select 'td', text: 'Mother', count: 1
        assert_select 'td', text: 'Fred', count: 0
        assert_select 'td', text: 'http://ontology.org/#parent', count: 3
        assert_select 'td', text: 'http://ontology.org/#mother', count: 1
        assert_select 'td', text: 'http://ontology.org/#father', count: 1
      end
    end
  end

  test 'login required for new' do
    get :new
    assert_response :redirect
    assert flash[:error]
  end

  test 'project required for new' do
    login_as(FactoryBot.create(:person_not_in_project))
    get :new
    assert_response :redirect
    assert flash[:error]
  end

  test 'project admin required for new if configured' do
    login_as(FactoryBot.create(:person))
    with_config_value :project_admin_sample_type_restriction, false do
      get :new
      assert_response :success
      refute flash[:error]
    end
    with_config_value :project_admin_sample_type_restriction, true do
      get :new
      assert_response :redirect
      assert flash[:error]
    end
  end

  test 'new' do
    login_as(FactoryBot.create(:project_administrator))
    assert_response :success
  end

  test 'create' do
    login_as(FactoryBot.create(:project_administrator))
    assert_difference('SampleControlledVocab.count') do
      assert_difference('SampleControlledVocabTerm.count', 2) do
        post :create, params: { sample_controlled_vocab: { title: 'fish', description: 'About fish',
                                                 sample_controlled_vocab_terms_attributes: {
                                                   '0' => { label: 'goldfish', _destroy: '0' },
                                                   '1' => { label: 'guppy', _destroy: '0' }
                                                 }
                    } }
      end
    end
    assert cv = assigns(:sample_controlled_vocab)
    assert_redirected_to sample_controlled_vocab_path(cv)
    assert_equal 'fish', cv.title
    assert_equal 'About fish', cv.description
    assert_equal 2, cv.sample_controlled_vocab_terms.count
    assert_equal %w(goldfish guppy), cv.labels
  end

  test 'login required for create' do
    assert_no_difference('SampleControlledVocab.count') do
      assert_no_difference('SampleControlledVocabTerm.count') do
        post :create, params: { sample_controlled_vocab: { title: 'fish', description: 'About fish',
                                                 sample_controlled_vocab_terms_attributes: {
                                                   '0' => { label: 'goldfish', _destroy: '0' },
                                                   '1' => { label: 'guppy', _destroy: '0' }
                                                 }
                    } }
      end
    end
    assert_response :redirect
    assert flash[:error]
  end

  test 'project required for create' do
    login_as(FactoryBot.create(:person_not_in_project))
    assert_no_difference('SampleControlledVocab.count') do
      assert_no_difference('SampleControlledVocabTerm.count', 2) do
        post :create, params: { sample_controlled_vocab: { title: 'fish', description: 'About fish',
                                                 sample_controlled_vocab_terms_attributes: {
                                                   '0' => { label: 'goldfish', _destroy: '0' },
                                                   '1' => { label: 'guppy', _destroy: '0' }
                                                 }
                    } }
      end
    end
    assert_response :redirect
    assert flash[:error]
  end

  test 'update' do
    login_as(FactoryBot.create(:admin))
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    term_ids = cv.sample_controlled_vocab_terms.collect(&:id)
    assert_no_difference('SampleControlledVocab.count') do
      assert_no_difference('SampleControlledVocabTerm.count') do
        put :update, params: { id: cv, sample_controlled_vocab: { title: 'the apples', description: 'About apples',
                                                        sample_controlled_vocab_terms_attributes: {
                                                          '0' => { label: 'Granny Smith', _destroy: '0', id: term_ids[0] },
                                                          '1' => { _destroy: '1', id: term_ids[1] },
                                                          '2' => { label: 'Bramley', _destroy: '0', id: term_ids[2] },
                                                          '3' => { label: 'Cox', _destroy: '0', id: term_ids[3] },
                                                          '4' => { label: 'Jazz', _destroy: '0' }
                                                        }
                    } }
      end
    end
    assert cv = assigns(:sample_controlled_vocab)
    assert_redirected_to sample_controlled_vocab_path(cv)
    assert_equal 'the apples', cv.title
    assert_equal 'About apples', cv.description
    assert_equal 4, cv.sample_controlled_vocab_terms.count
    assert_equal ['Granny Smith', 'Bramley', 'Cox', 'Jazz'], cv.labels
  end

  test 'login required for update' do
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    term_ids = cv.sample_controlled_vocab_terms.collect(&:id)
    assert_no_difference('SampleControlledVocab.count') do
      assert_no_difference('SampleControlledVocabTerm.count') do
        put :update, params: { id: cv, sample_controlled_vocab: { title: 'the apples', description: 'About apples',
                                                        sample_controlled_vocab_terms_attributes: {
                                                          '0' => { label: 'Granny Smith', _destroy: '0', id: term_ids[0] },
                                                          '1' => { _destroy: '1', id: term_ids[1] },
                                                          '2' => { label: 'Bramley', _destroy: '0', id: term_ids[2] },
                                                          '3' => { label: 'Cox', _destroy: '0', id: term_ids[3] },
                                                          '4' => { label: 'Jazz', _destroy: '0' }
                                                        }
                   } }
      end
    end
    assert_response :redirect
  end

  test 'edit' do
    login_as(FactoryBot.create(:project_administrator))
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    get :edit, params: { id: cv.id }
    assert_response :success
  end

  test 'login required for edit' do
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    get :edit, params: { id: cv.id }
    assert_response :redirect
  end

  test 'index' do
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    get :index
    assert_response :success
  end

  test 'destroy' do
    login_as(FactoryBot.create(:admin))
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    assert_difference('SampleControlledVocab.count', -1) do
      assert_difference('SampleControlledVocabTerm.count', -4) do
        delete :destroy, params: { id: cv }
      end
    end
  end

  test 'need login to destroy' do
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    assert_no_difference('SampleControlledVocab.count') do
      assert_no_difference('SampleControlledVocabTerm.count') do
        delete :destroy, params: { id: cv }
      end
    end
    assert_response :redirect
  end

  test 'need to be project member to destroy' do
    login_as(FactoryBot.create(:user))
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    assert_no_difference('SampleControlledVocab.count') do
      assert_no_difference('SampleControlledVocabTerm.count') do
        delete :destroy, params: { id: cv }
      end
    end
    assert_response :redirect
  end

  test 'cannot access when disabled' do
    person = FactoryBot.create(:person)
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    login_as(person.user)
    with_config_value :samples_enabled, false do
      get :show, params: { id: cv.id }
      assert_redirected_to :root
      refute_nil flash[:error]

      clear_flash(:error)

      get :index
      assert_redirected_to :root
      refute_nil flash[:error]

      clear_flash(:error)

      get :new
      assert_redirected_to :root
      refute_nil flash[:error]
    end
  end

  test 'edit ontology based cv should have non editable terms' do
    person = FactoryBot.create(:person)
    login_as(person)
    cv = FactoryBot.create(:ontology_sample_controlled_vocab)
    assert cv.ontology_based?
    get :edit, params:{id: cv.id}
    assert_response :success

    assert_select 'table#new-terms' do
      assert_select 'tr.sample-cv-term input[type=text]', count:cv.sample_controlled_vocab_terms.length * 3 do |input|
        assert input.attr('readonly').present?
      end
    end

    assert_select('a#add-term') do |button|
      assert button.attr('disabled').present?
    end

  end

  test 'edit simple, non ontology cv should have editable terms' do
    person = FactoryBot.create(:person)
    login_as(person)
    cv = FactoryBot.create(:apples_sample_controlled_vocab)
    refute cv.ontology_based?
    get :edit, params:{id: cv.id}
    assert_response :success

    assert_select 'table#new-terms' do
      assert_select 'tr.sample-cv-term input[type=text]', count:cv.sample_controlled_vocab_terms.length * 3 do |input|
        assert input.attr('readonly').nil?
      end
    end

    assert_select('a#add-term') do |button|
      assert button.attr('disabled').nil?
    end
  end

  test 'fetch ols terms with root term included' do
    person = FactoryBot.create(:person)
    login_as(person)
    VCR.use_cassette('ols/fetch_obo_cell_projection') do
      get :fetch_ols_terms, params: { source_ontology_id: 'ro',
                                      root_uri: 'http://purl.obolibrary.org/obo/GO_0042995',
                                      include_root_term: '1' }, format: :json

      assert_response :success
      res = JSON.parse(response.body)
      assert_equal 4, res.length
      iris = res.map { |term| term['iri'] }
      assert_includes iris, 'http://purl.obolibrary.org/obo/GO_0043005'
      assert_includes iris, 'http://purl.obolibrary.org/obo/GO_0042995'
    end
  end

  test 'fetch ols terms without root term included' do
    person = FactoryBot.create(:person)
    login_as(person)
    VCR.use_cassette('ols/fetch_obo_cell_projection') do
      get :fetch_ols_terms, params: { source_ontology_id: 'ro',
                                      root_uri: 'http://purl.obolibrary.org/obo/GO_0042995' }, format: :json

      assert_response :success
      res = JSON.parse(response.body)
      assert_equal 3, res.length
      iris = res.map { |term| term['iri'] }
      refute_includes iris, 'http://purl.obolibrary.org/obo/GO_0042995'
      assert_includes iris, 'http://purl.obolibrary.org/obo/GO_0043005'
    end
  end

  test 'fetch ols terms with wrong URI' do
    person = FactoryBot.create(:person)
    login_as(person)
    VCR.use_cassette('ols/fetch_obo_bad_term') do
      get :fetch_ols_terms, params: { source_ontology_id: 'ro',
                                      root_uri: 'http://purl.obolibrary.org/obo/banana',
                                      include_root_term: '1' }, format: :json

      assert_response :unprocessable_entity
      res = JSON.parse(response.body)
      assert_equal '404 Not Found', res.dig('errors', 0, 'details')
    end
  end

  test 'can access typeahead with samples disabled' do
    person = FactoryBot.create(:person)
    login_as(person)
    scv = FactoryBot.create(:topics_controlled_vocab)
    with_config_value(:samples_enabled, false) do
      get :typeahead, params: { format: :json, q: 'sam', scv_id:scv.id }
      assert_response :success
      res = JSON.parse(response.body)['results']
      assert_equal 1, res.length
      assert_equal 'Sample collections', res.first['text']
    end
  end
end
