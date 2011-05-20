require 'test_helper'

class ExperimentalConditionsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

=begin
test "should not get edit option for downloadable only sop" do
    sop=sops(:downloadable_sop)
    sop.save
    get :index, {:sop_id => sop.id, :version => sop.version}
    assert_select 'img[title="Start editing"]',:count=>0
    assert_select 'div[id="edit_on"]',:count=>0
    assert_select 'div[id="edit_off"]',:count=>0
  end

  test "should get edit option for editable sop" do
    sop=sops(:editable_sop)
    sop.save
    get :index, {:sop_id => sop.id, :version => sop.version}
    assert_select 'img[title="Start editing"]',:count=>1
    assert_select 'div[id="edit_on"]',:count=>1
    assert_select 'div[id="edit_off"]',:count=>1
  end

  test "should get edit option for owners downloadable sop" do
    login_as(:owner_of_my_first_sop)
    sop=sops(:downloadable_sop)
    sop.save
    get :index, {:sop_id => sop.id, :version => sop.version}
    assert_select 'img[title="Start editing"]',:count=>1
    assert_select 'div[id="edit_on"]',:count=>1
    assert_select 'div[id="edit_off"]',:count=>1
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

=end
end
