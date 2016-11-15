require 'test_helper'

class SampleControlledVocabsControllerTest < ActionController::TestCase

  include AuthenticatedTestHelper

  def setup
    # create a dummy user, to prevent the first becoming an admin
    person = Factory(:person)
  end

  test 'show' do
    cv = Factory(:apples_sample_controlled_vocab)
    get :show, id: cv
    assert_response :success
    assert_select 'ul>li', text: 'Bramley', count: 1
    assert_select 'ul>li', text: 'Orange', count: 0
  end

  test 'login required for new' do
    get :new
    assert_response :redirect
    assert flash[:error]
  end

  test 'project required for new' do
    login_as(Factory(:person_not_in_project))
    get :new
    assert_response :redirect
    assert flash[:error]
  end

  test 'project admin required for new if configured' do
    login_as(Factory(:person))
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
    login_as(Factory(:project_administrator))
    assert_response :success
  end

  test 'create' do
    login_as(Factory(:project_administrator))
    assert_difference('SampleControlledVocab.count') do
      assert_difference('SampleControlledVocabTerm.count', 2) do
        post :create, sample_controlled_vocab: { title: 'fish', description: 'About fish',
                                                 sample_controlled_vocab_terms_attributes: {
                                                   '0' => { label: 'goldfish', _destroy: '0' },
                                                   '1' => { label: 'guppy', _destroy: '0' }
                                                 }
                    }
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
        post :create, sample_controlled_vocab: { title: 'fish', description: 'About fish',
                                                 sample_controlled_vocab_terms_attributes: {
                                                   '0' => { label: 'goldfish', _destroy: '0' },
                                                   '1' => { label: 'guppy', _destroy: '0' }
                                                 }
                    }
      end
    end
    assert_response :redirect
    assert flash[:error]
  end

  test 'project required for create' do
    login_as(Factory(:person_not_in_project))
    assert_no_difference('SampleControlledVocab.count') do
      assert_no_difference('SampleControlledVocabTerm.count', 2) do
        post :create, sample_controlled_vocab: { title: 'fish', description: 'About fish',
                                                 sample_controlled_vocab_terms_attributes: {
                                                   '0' => { label: 'goldfish', _destroy: '0' },
                                                   '1' => { label: 'guppy', _destroy: '0' }
                                                 }
                    }
      end
    end
    assert_response :redirect
    assert flash[:error]
  end

  test 'update' do
    login_as(Factory(:project_administrator))
    cv = Factory(:apples_sample_controlled_vocab)
    term_ids = cv.sample_controlled_vocab_terms.collect(&:id)
    assert_no_difference('SampleControlledVocab.count') do
      assert_no_difference('SampleControlledVocabTerm.count') do
        put :update, id: cv, sample_controlled_vocab: { title: 'the apples', description: 'About apples',
                                                        sample_controlled_vocab_terms_attributes: {
                                                          '0' => { label: 'Granny Smith', _destroy: '0', id: term_ids[0] },
                                                          '1' => { _destroy: '1', id: term_ids[1] },
                                                          '2' => { label: 'Bramley', _destroy: '0', id: term_ids[2] },
                                                          '3' => { label: 'Cox', _destroy: '0', id: term_ids[3] },
                                                          '4' => { label: 'Jazz', _destroy: '0' }
                                                        }
                    }
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
    cv = Factory(:apples_sample_controlled_vocab)
    term_ids = cv.sample_controlled_vocab_terms.collect(&:id)
    assert_no_difference('SampleControlledVocab.count') do
      assert_no_difference('SampleControlledVocabTerm.count') do
        put :update, id: cv, sample_controlled_vocab: { title: 'the apples', description: 'About apples',
                                                        sample_controlled_vocab_terms_attributes: {
                                                          '0' => { label: 'Granny Smith', _destroy: '0', id: term_ids[0] },
                                                          '1' => { _destroy: '1', id: term_ids[1] },
                                                          '2' => { label: 'Bramley', _destroy: '0', id: term_ids[2] },
                                                          '3' => { label: 'Cox', _destroy: '0', id: term_ids[3] },
                                                          '4' => { label: 'Jazz', _destroy: '0' }
                                                        }
                   }
      end
    end
    assert_response :redirect
  end

  test 'edit' do
    login_as(Factory(:project_administrator))
    cv = Factory(:apples_sample_controlled_vocab)
    get :edit, id: cv.id
    assert_response :success
  end

  test 'login required for edit' do
    cv = Factory(:apples_sample_controlled_vocab)
    get :edit, id: cv.id
    assert_response :redirect
  end

  test 'index' do
    cv = Factory(:apples_sample_controlled_vocab)
    get :index
    assert_response :success
  end

  test 'destroy' do
    login_as(Factory(:project_administrator))
    cv = Factory(:apples_sample_controlled_vocab)
    assert_difference('SampleControlledVocab.count', -1) do
      assert_difference('SampleControlledVocabTerm.count', -4) do
        delete :destroy, id: cv
      end
    end
  end

  test 'need login to destroy' do
    cv = Factory(:apples_sample_controlled_vocab)
    assert_no_difference('SampleControlledVocab.count') do
      assert_no_difference('SampleControlledVocabTerm.count') do
        delete :destroy, id: cv
      end
    end
    assert_response :redirect
  end

  test 'cannot access when disabled' do
    person = Factory(:person)
    cv = Factory(:apples_sample_controlled_vocab)
    login_as(person.user)
    with_config_value :samples_enabled,false do

      get :show, id: cv.id
      assert_redirected_to :root
      refute_nil flash[:error]

      flash[:error]=nil

      get :index
      assert_redirected_to :root
      refute_nil flash[:error]

      flash[:error]=nil

      get :new
      assert_redirected_to :root
      refute_nil flash[:error]

    end

  end
end
