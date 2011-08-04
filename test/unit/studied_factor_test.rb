require 'test_helper'

class StudiedFactorTest < ActiveSupport::TestCase
  fixtures :all
  include StudiedFactorsHelper

  test 'should create FS with the concentration of the compound' do
    User.with_current_user  users(:aaron) do
      measured_item = measured_items(:concentration)
      unit = units(:gram)
      compound = compounds(:compound_glucose)
      data_file = data_files(:editable_data_file)
      fs = StudiedFactor.new(:data_file => data_file, :data_file_version => data_file.latest_version, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :substance => compound)
      assert fs.save, "should create the new factor studied with the concentration of the compound "
    end
  end

  test 'should not create FS with the concentration of no substance' do
    User.with_current_user  users(:aaron) do
      measured_item = measured_items(:concentration)
      unit = units(:gram)
      data_file = data_files(:editable_data_file)
      fs = StudiedFactor.new(:data_file => data_file, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :substance => nil)
      assert !fs.save, "shouldn't create factor studied with concentration of no substance"
    end
  end

  test 'should create FS with the none concentration item and no substance' do
    User.with_current_user  users(:aaron) do
      measured_item = measured_items(:time)
      unit = units(:second)
      data_file = data_files(:editable_data_file)
      fs = StudiedFactor.new(:data_file => data_file, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :substance => nil)
      assert fs.save, "should create factor studied  of the none concentration item and no substance"
    end
  end

  test "should create FS with the concentration of the compound's synonym" do
    User.with_current_user  users(:aaron) do
      measured_item = measured_items(:concentration)
      unit = units(:gram)
      synonym = synonyms(:glucose_synonym)
      data_file = data_files(:editable_data_file)
      fs = StudiedFactor.new(:data_file => data_file, :measured_item => measured_item, :start_value => 1, :end_value => 10, :unit => unit, :substance => synonym)
      assert fs.save, "should create the new factor studied with the concentration of the compound's synonym "
    end
  end

  test 'should list the existing FSes of the project the datafile belongs to, filtured by can_view' do
    user = Factory(:user)
    data_file = Factory(:data_file, :contributor => user)
    #create bunch of data_files and FSes which belong to the same project and the datafiles can be viewed
    i=0
    while i < 10  do
      d = Factory(:data_file, :projects => [data_file.projects.first], :policy => Factory(:all_sysmo_viewable_policy))
      Factory(:studied_factor, :data_file => d, :start_value => i)
      i +=1
    end

    #create bunch of data_files and FSes which belong to the same project and the datafiles can not be viewed
    i=0
    while i < 10  do
      d = Factory(:data_file, :projects => [Factory(:project),data_file.projects.first])
      Factory(:studied_factor, :data_file => d, :start_value => i)
      i +=1
    end

    User.with_current_user  user do
        assert data_file.can_edit?
        fses = fses_or_ecs_of_project data_file, 'studied_factors'
        assert_equal fses.count, 10
        fses.each do |fs|
          assert fs.data_file.can_view?
          assert !(fs.data_file.project_ids & data_file.project_ids).empty?
        end
    end
  end

  test 'should list the unique FS , based on the set (measured_item, unit, start_value, end_value, sd, substance)' do
    fs_array = []
    d = Factory(:data_file)
    #create bunch of FSes which are different
    i=0
    number_of_different_fses = 10
    number_of_the_same_fses = 5
    while i < number_of_different_fses  do
      fs_array.push Factory(:studied_factor, :data_file => d, :start_value => i)
      i +=1
    end
    #create bunch of FSes which are the same based on the set (measured_item, unit, start_value, end_value, sd, substance)
    compound = Factory(:compound, :name => 'glucose')
    measured_item = Factory(:measured_item)
    unit = Factory(:unit)
    j=0
    while j < number_of_the_same_fses  do
      fs_array.push Factory(:studied_factor, :substance => compound, :measured_item => measured_item, :unit => unit)
      j +=1
    end
    assert_equal fs_array.count, i+j
    uniq_fs_array = uniq_fs_or_ec fs_array
    assert_equal uniq_fs_array.count, i+1
  end

end
