require 'test_helper'

class ExperimentalConditionsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end


  test "can only go to the experimental condition if the user can edit the sop" do
    sop=sops(:editable_sop)
    sop.save
    get :index,{:sop_id=>sop.id, :version => sop.version}
    assert_response :success

    sop=sops(:downloadable_sop)
    sop.save
    get :index,{:sop_id=>sop.id, :version => sop.version}
    assert_not_nil flash[:error]

  end

  test 'should create the experimental condition with the concentration of the compound' do
    sop=sops(:editable_sop)
    mi = measured_items(:concentration)
    cp = compounds(:compound_glucose)
    unit = units(:gram)
    ec = {:measured_item_id => mi.id, :start_value => 1, :end_value => 10, :unit => unit}
    post :create, :experimental_condition => ec, :sop_id => sop.id, :version => sop.version, :substance_autocompleter_unrecognized_items => ["iron"]
    ec = assigns(:experimental_condition)
    assert_not_nil ec
    assert ec.valid?
    assert_equal ec.measured_item, mi
  end

  test 'should not create the experimental condition with the concentration of no substance' do
    sop=sops(:editable_sop)
    mi = measured_items(:concentration)
    unit = units(:gram)
    ec = {:measured_item_id => mi.id, :start_value => 1, :end_value => 10, :unit => unit}
    post :create, :experimental_condition => ec, :sop_id => sop.id, :version => sop.version, :substance_autocompleter_unrecognized_items => nil
    ec = assigns(:experimental_condition)
    assert_not_nil ec
    assert !ec.valid?
  end

  test "should create experimental condition with the none concentration item and no substance" do
    sop=sops(:editable_sop)
    mi = measured_items(:time)
    unit = units(:gram)
    ec = {:measured_item_id => mi.id, :start_value => 1, :end_value => 10, :unit => unit}
    post :create, :experimental_condition => ec, :sop_id => sop.id, :version => sop.version
    ec = assigns(:experimental_condition)
    assert_not_nil ec
    assert ec.valid?
    assert_equal ec.measured_item, mi
  end

  test "should create the experimental condition with the concentration of the compound chosen from autocomplete" do
    sop=sops(:editable_sop)
    mi = measured_items(:concentration)
    cp = compounds(:compound_glucose)
    unit = units(:gram)
    ec = {:measured_item_id => mi.id, :start_value => 1, :end_value => 10, :unit => unit}
    post :create, :experimental_condition => ec, :sop_id => sop.id, :version => sop.version, :substance_autocompleter_selected_ids => ["#{cp.id.to_s},Compound"]
    ec = assigns(:experimental_condition)
    assert_not_nil ec
    assert ec.valid?
    assert_equal ec.measured_item, mi
  end

  test "should create the experimental condition with the concentration of the compound's synonym" do
    sop=sops(:editable_sop)
    mi = measured_items(:concentration)
    syn = synonyms(:glucose_synonym)
    unit = units(:gram)
    ec = {:measured_item_id => mi.id, :start_value => 1, :end_value => 10, :unit => unit}
    post :create, :experimental_condition => ec, :sop_id => sop.id, :version => sop.version, :substance_autocompleter_selected_ids => ["#{syn.id.to_s},Synonym"]
    ec = assigns(:experimental_condition)
    assert_not_nil ec
    assert ec.valid?
    assert_equal ec.measured_item, mi
  end

  test 'should update the experimental condition of concentration to time' do
    ec = experimental_conditions(:experimental_condition_concentration_glucose)
    assert_not_nil ec
    assert_equal ec.measured_item, measured_items(:concentration)
    assert_equal ec.substance, compounds(:compound_glucose)

    mi = measured_items(:time)
    put :update, :id => ec.id, :sop_id => ec.sop.id, :experimental_condition => {:measured_item_id => mi.id},  "#{ec.id}_substance_autocompleter_selected_ids" => nil
    fs_updated = assigns(:experimental_condition)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.measured_item, mi
    assert_equal fs_updated.substance, nil
  end

  test 'should update the experimental condition of time to concentration' do
    ec = experimental_conditions(:experimental_condition_time)
    assert_not_nil ec
    assert_equal ec.measured_item, measured_items(:time)
    assert_equal ec.substance, nil

    mi = measured_items(:concentration)
    cp = compounds(:compound_glucose)
    put :update, :id => ec.id, :sop_id => ec.sop.id, :experimental_condition => {:measured_item_id => mi.id},  "#{ec.id}_substance_autocompleter_selected_ids" => ["#{cp.id.to_s},Compound"]
    fs_updated = assigns(:experimental_condition)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.measured_item, mi
    assert_equal fs_updated.substance, cp
  end

  test 'should update the experimental condition of time to pressure' do
    ec = experimental_conditions(:experimental_condition_time)
    assert_not_nil ec
    assert_equal ec.measured_item, measured_items(:time)
    assert_equal ec.substance, nil

    mi = measured_items(:pressure)
    put :update, :id => ec.id, :sop_id => ec.sop.id, :experimental_condition => {:measured_item_id => mi.id}
    fs_updated = assigns(:experimental_condition)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.measured_item, mi
    assert_equal fs_updated.substance, nil
  end

  test 'should update the experimental condition of concentration of glucose to concentration of glycine' do
    ec = experimental_conditions(:experimental_condition_concentration_glucose)
    assert_not_nil ec
    assert_equal ec.measured_item, measured_items(:concentration)
    assert_equal ec.substance, compounds(:compound_glucose)

    cp = compounds(:compound_glycine)
    put :update, :id => ec.id, :sop_id => ec.sop.id, :experimental_condition => {}, "#{ec.id}_substance_autocompleter_selected_ids" => ["#{cp.id.to_s},Compound"]
    fs_updated = assigns(:experimental_condition)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.measured_item, measured_items(:concentration)
    assert_equal fs_updated.substance, cp
  end

  test 'should update start_value, end_value of the experimental condition' do
    ec = experimental_conditions(:experimental_condition_time)
    assert_not_nil ec

    put :update, :id => ec.id, :sop_id => ec.sop.id, :experimental_condition => {:start_value => 10.02, :end_value => 50}
    fs_updated = assigns(:experimental_condition)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.start_value, 10.02
    assert_equal fs_updated.end_value, 50
  end

end
