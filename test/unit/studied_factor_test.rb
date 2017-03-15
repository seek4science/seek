require 'test_helper'

class StudiedFactorTest < ActiveSupport::TestCase
  fixtures :all
  include SubstancesHelper

  test 'should not create FS with the concentration of no substance' do
    User.with_current_user users(:aaron) do
      measured_item = measured_items(:concentration)
      unit = units(:gram)
      data_file = data_files(:editable_data_file)
      fs = StudiedFactor.new(data_file: data_file, measured_item: measured_item, start_value: 1, end_value: 10, unit: unit)
      assert !fs.save, "shouldn't create factor studied with concentration of no substance"
    end
  end

  test 'should create FS with the none concentration item and no substance' do
    User.with_current_user users(:aaron) do
      measured_item = measured_items(:time)
      unit = units(:second)
      data_file = data_files(:editable_data_file)
      fs = StudiedFactor.new(data_file: data_file, measured_item: measured_item, start_value: 1, end_value: 10, unit: unit)
      assert fs.save, 'should create factor studied  of the none concentration item and no substance'
    end
  end

  test "should create FS with the concentration of the compound's synonym" do
    User.with_current_user users(:aaron) do
      measured_item = measured_items(:concentration)
      unit = units(:gram)
      synonym = synonyms(:glucose_synonym)
      data_file = data_files(:editable_data_file)
      fs = StudiedFactor.new(data_file: data_file, measured_item: measured_item, start_value: 1, end_value: 10, unit: unit)
      fs_link = StudiedFactorLink.new(substance: synonym)
      fs.studied_factor_links = [fs_link]
      assert fs.save!, "should create the new factor studied with the concentration of the compound's synonym "
    end
  end

  test 'should list the existing FSes of the project the datafile belongs to filtered by can_view' do
    user = Factory(:user)
    other_user = Factory :user
    data_file = Factory(:data_file, contributor: user)
    n = 2
    # create bunch of data_files and FSes which belong to the same project and the datafiles can be viewed
    (0...n).to_a.each do |i|
      d = Factory(:data_file, projects: [data_file.projects.first], policy: Factory(:all_sysmo_viewable_policy), contributor: other_user)
      Factory(:studied_factor, data_file: d, start_value: i)
    end

    # create bunch of data_files and FSes which belong to the same project and the datafiles can not be viewed
    (0...n).to_a.each do |i|
      d = Factory(:data_file, projects: [Factory(:project), data_file.projects.first], contributor: other_user)
      Factory(:studied_factor, data_file: d, start_value: i)
    end

    User.with_current_user user do
      assert data_file.can_edit?
      fses = fses_or_ecs_of_project data_file, 'studied_factors'
      assert_equal n, fses.count
      fses.each do |fs|
        assert fs.data_file.can_view?
        assert !(fs.data_file.project_ids & data_file.project_ids).empty?
      end
    end
  end

  test 'should list the unique FS , based on the set (measured_item, unit, start_value, end_value, sd, substance)' do
    fs_array = []
    d = Factory(:data_file)
    # create bunch of FSes which are different

    number_of_different_fses = 2
    number_of_the_same_fses = 2
    (0...number_of_different_fses).to_a.each do |i|
      fs_array.push Factory(:studied_factor, data_file: d, start_value: i)
    end
    # create bunch of FSes which are the same based on the set (measured_item, unit, start_value, end_value, sd, substance)
    compound = Factory(:compound, name: 'glucose')
    measured_item = Factory(:measured_item)
    unit = Factory(:unit)
    (0...number_of_the_same_fses).to_a.each do
      studied_factor_link = Factory(:studied_factor_link, substance: compound)
      fs = Factory(:studied_factor, measured_item: measured_item, unit: unit, data_file: d)
      fs.studied_factor_links = [studied_factor_link]
      fs_array.push fs
    end
    assert_equal fs_array.count, 4
    uniq_fs_array = uniq_fs_or_ec fs_array
    assert_equal uniq_fs_array.count, 3
  end

  test 'should create the factor_studied and the association has_many compounds , through studied_factor_links table' do
    User.with_current_user users(:aaron) do
      compound1 = Compound.new(name: 'water')
      compound2 = Compound.new(name: 'glucose')
      fs = StudiedFactor.new(data_file: data_files(:editable_data_file), data_file_version: 1, measured_item: measured_items(:concentration), unit: units(:gram), start_value: 1, end_value: 10, standard_deviation: 1)
      fs_link1 = StudiedFactorLink.new(substance: compound1)
      fs_link2 = StudiedFactorLink.new(substance: compound2)
      fs.studied_factor_links = [fs_link1, fs_link2]
      assert fs.save!
      assert_equal fs.studied_factor_links.count, 2
      assert_equal fs.studied_factor_links.first.substance, compound1
      assert_equal fs.studied_factor_links[1].substance, compound2
      assert_equal 2, fs.substances.count
      assert fs.substances.include? compound1
      assert fs.substances.include? compound2
    end
  end
end
