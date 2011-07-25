require 'test_helper'

class ExperimentalConditionTest < ActiveSupport::TestCase
  fixtures :all
  include StudiedFactorsHelper

  test 'should create experimental condition with the concentration of the compound' do
    User.with_current_user  users(:aaron) do
      measured_item = measured_items(:concentration)
      unit = units(:gram)
      compound = compounds(:compound_glucose)
      sop = sops(:editable_sop)
      ec = ExperimentalCondition.new(:sop => sop, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :substance => compound)
      assert ec.save, "should create the new experimental condition with the concentration of the compound "
    end
  end

  test 'should not create experimental condition with the concentration of no substance' do
    User.with_current_user  users(:aaron) do
      measured_item = measured_items(:concentration)
      unit = units(:gram)
      sop = sops(:editable_sop)
      ec = ExperimentalCondition.new(:sop => sop, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :substance => nil)
      assert !ec.save, "shouldn't create experimental condition with concentration of no substance"
    end
  end

  test 'should create experimental condition with the none concentration item and no substance' do
    User.with_current_user  users(:aaron) do
      measured_item = measured_items(:time)
      unit = units(:second)
      sop = sops(:editable_sop)
      ec = ExperimentalCondition.new(:sop => sop, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :substance => nil)
      assert ec.save, "should create experimental condition  of the none concentration item and no substance"
    end
  end

  test "should create experimental condition with the concentration of the compound's synonym" do
    User.with_current_user  users(:aaron) do
      measured_item = measured_items(:concentration)
      unit = units(:gram)
      synonym = synonyms(:glucose_synonym)
      sop = sops(:editable_sop)
      ec= ExperimentalCondition.new(:sop => sop, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :substance => synonym)
      assert ec.save, "should create the new experimental condition with the concentration of the compound's synonym "
    end
  end

  test 'should list the existing ECes of the project the sop belongs to, filtered by can_view' do
    user = Factory(:user)
    sop = Factory(:sop, :contributor => user)
    #create bunch of sops and ECs which belong to the same project and the sops can be viewed
    i=0
    while i < 10  do
      s = Factory(:sop, :project => sop.project, :policy => Factory(:all_sysmo_viewable_policy))
      Factory(:experimental_condition, :sop => s, :start_value => i)
      i +=1
    end

    #create bunch of sops and ECs which belong to the same project and the sops can not be viewed
    i=0
    while i < 10  do
      s = Factory(:sop, :project => sop.project)
      Factory(:experimental_condition, :sop => s, :start_value => i)
      i +=1
    end

    User.with_current_user  user do
        assert sop.can_edit?
        ecs = fses_or_ecs_of_project sop, 'experimental_conditions'
        assert_equal ecs.count, 10
        ecs.each do |ec|
          assert ec.sop.can_view?
          assert_equal ec.sop.project_id,sop.project_id
        end
    end
  end

  test 'should list the unique EC , based on the set (measured_item, unit, start_value, end_value, substance)' do
    ec_array = []
    s = Factory(:sop)
    #create bunch of FSes which are different
    i=0
    number_of_different_ecs = 10
    number_of_the_same_ecs = 5
    while i < number_of_different_ecs  do
      ec_array.push Factory(:experimental_condition, :sop => s, :start_value => i)
      i +=1
    end
    #create bunch of FSes which are the same based on the set (measured_item, unit, start_value, end_value, substance)
    compound = Factory(:compound, :name => 'glucose')
    measured_item = Factory(:measured_item)
    unit = Factory(:unit)
    j=0
    while j < number_of_the_same_ecs  do
      ec_array.push Factory(:experimental_condition, :substance => compound, :measured_item => measured_item, :unit => unit)
      j +=1
    end
    assert_equal ec_array.count, i+j
    uniq_fs_array = uniq_fs_or_ec ec_array
    assert_equal uniq_fs_array.count, i+1
  end

  test "should create the association has_many compounds , through experimental_condition_links table" do
    User.with_current_user  users(:aaron) do
      compound1 = Compound.new(:name => 'water')
      compound2 = Compound.new(:name => 'glucose')
      ec = ExperimentalCondition.new(:sop => sops(:editable_sop), :sop_version => 1, :measured_item => measured_items(:concentration), :unit => units(:gram), :start_value => 1, :end_value => 10)
      ec_link1 = ExperimentalConditionLink.new(:substance => compound1, :experimental_condition => ec)
      ec_link2 = ExperimentalConditionLink.new(:substance => compound2, :experimental_condition => ec)
      assert ec.save!
      assert compound1.save!
      assert compound2.save!
      assert ec_link1.save!
      assert ec_link2.save!
      assert_equal ec.experimental_condition_links.count, 2
      assert_equal ec.experimental_condition_links.first.substance, compound1
      assert_equal ec.experimental_condition_links[1].substance, compound2
    end
  end
end
