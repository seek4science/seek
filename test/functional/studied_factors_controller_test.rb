require 'test_helper'

class StudiedFactorsControllerTest < ActionController::TestCase

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test "can only go to factors studied if the user can edit the data file" do
    df=data_files(:editable_data_file)
    df.save
    get :index,{:data_file_id=>df.id, :version => df.version}
    assert_response :success

    df=data_files(:downloadable_data_file)
    df.save
    get :index,{:data_file_id=>df.id, :version => df.version}
    assert_not_nil flash[:error]

  end

  test 'should create the factor studied with the concentration of the compound' do
    df=data_files(:editable_data_file)
    mi = measured_items(:concentration)
    unit = units(:gram)
    fs = {:measured_item_id => mi.id, :start_value => 1, :end_value => 10, :unit => unit}
    substance_name = 'iron'
    sabiork_id = "100"
    chebi_id = 'CHEBI:57904'
    kegg_id = 'C05235'
    synonyms = ['iron_a', 'iron_b']

    post :create, :studied_factor => fs, :data_file_id => df.id, :version => df.version, :substance_autocompleter_unrecognized_items => [substance_name],
         :sabiork_id => sabiork_id, :chebi_id => chebi_id, :kegg_id => kegg_id, :synonyms => synonyms

    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert fs.valid?
    assert_equal fs.measured_item, mi
    substance = fs.substances.first
    assert_equal substance.name, substance_name
    assert_equal substance.mappings.first.sabiork_id, sabiork_id
    assert_equal substance.mappings.first.chebi_id, chebi_id
    assert_equal substance.mappings.first.kegg_id, kegg_id
    assert_equal substance.synonyms.count, 2
    assert_equal substance.synonyms.first.name, synonyms.first
    assert_equal substance.synonyms[1].name, synonyms[1]
  end

  test "should create factor studied with the none concentration item and no substance" do
    data_file=data_files(:editable_data_file)
    mi = measured_items(:time)
    unit = units(:gram)
    fs = {:measured_item_id => mi.id, :start_value => 1, :end_value => 10, :unit => unit}
    post :create, :studied_factor => fs, :data_file_id => data_file.id, :version => data_file.version
    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert fs.valid?
    assert_equal fs.measured_item, mi
  end

  test 'should not create the factor studied with the concentration of no substance' do
    df=data_files(:editable_data_file)
    mi = measured_items(:concentration)
    unit = units(:gram)
    fs = {:measured_item_id => mi.id, :start_value => 1, :end_value => 10, :unit => unit}
    post :create, :studied_factor => fs, :data_file_id => df.id, :version => df.version
    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert !fs.valid?
  end

  test "should create the factor studied with the concentration of the compound chosen from autocomplete" do
    df=data_files(:editable_data_file)
    mi = measured_items(:concentration)
    cp = compounds(:compound_glucose)
    unit = units(:gram)
    fs = {:measured_item_id => mi.id, :start_value => 1, :end_value => 10, :unit => unit}
    post :create, :studied_factor => fs, :data_file_id => df.id, :version => df.version, :substance_autocompleter_selected_ids => ["#{cp.id.to_s},Compound"]
    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert fs.valid?
    assert_equal fs.measured_item, mi
    assert_equal fs.substances.first, cp
  end

  test "should create the factor studied with the concentration of the compound's synonym" do
    df=data_files(:editable_data_file)
    mi = measured_items(:concentration)
    syn = synonyms(:glucose_synonym)
    unit = units(:gram)
    fs = {:measured_item_id => mi.id, :start_value => 1, :end_value => 10, :unit => unit}
    post :create, :studied_factor => fs, :data_file_id => df.id, :version => df.version, :substance_autocompleter_selected_ids => ["#{syn.id.to_s},Synonym"]
    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert fs.valid?
    assert_equal fs.measured_item, mi
    assert_equal fs.substances.first, syn
  end

  test 'should update the factor studied of concentration to time' do
    fs = studied_factors(:studied_factor_concentration_glucose)
    assert_not_nil fs
    assert_equal fs.measured_item, measured_items(:concentration)
    assert_equal fs.substances.first, compounds(:compound_glucose)

    mi = measured_items(:time)
    put :update, :id => fs.id, :data_file_id => fs.data_file.id, :studied_factor => {:measured_item_id => mi.id}
    fs_updated = assigns(:studied_factor)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.measured_item, mi
    assert fs_updated.substances.blank?
  end

  test 'should update the factor studied of time to concentration' do
    fs = studied_factors(:studied_factor_time)
    assert_not_nil fs
    assert_equal fs.measured_item, measured_items(:time)
    assert fs.substances.blank?

    mi = measured_items(:concentration)
    cp = compounds(:compound_glucose)
    put :update, :id => fs.id, :data_file_id => fs.data_file.id, :studied_factor => {:measured_item_id => mi.id},  "#{fs.id}_substance_autocompleter_selected_ids" => ["#{cp.id.to_s},Compound"]
    fs_updated = assigns(:studied_factor)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.measured_item, mi
    assert_equal fs_updated.substances.first, cp
  end

  test 'should update the factor studied of time to pressure' do
    fs = studied_factors(:studied_factor_time)
    assert_not_nil fs
    assert_equal fs.measured_item, measured_items(:time)
    assert fs.substances.blank?

    mi = measured_items(:pressure)
    put :update, :id => fs.id, :data_file_id => fs.data_file.id, :studied_factor => {:measured_item_id => mi.id}
    fs_updated = assigns(:studied_factor)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.measured_item, mi
    assert fs_updated.substances.blank?
  end

  test 'should update the factor studied of concentration of glucose to concentration of glycine' do
    fs = studied_factors(:studied_factor_concentration_glucose)
    assert_not_nil fs
    assert_equal fs.measured_item, measured_items(:concentration)
    assert_equal fs.substances.first, compounds(:compound_glucose)

    cp = compounds(:compound_glycine)
    put :update, :id => fs.id, :data_file_id => fs.data_file.id, :studied_factor => {}, "#{fs.id}_substance_autocompleter_selected_ids" => ["#{cp.id.to_s},Compound"]
    fs_updated = assigns(:studied_factor)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.measured_item, measured_items(:concentration)
    assert_equal fs_updated.substances.count, 1
    assert_equal fs_updated.substances.first, cp
  end

  test 'should update start_value, end_value, standard_deviation of the factor studied' do
    fs = studied_factors(:studied_factor_time)
    assert_not_nil fs

    put :update, :id => fs.id, :data_file_id => fs.data_file.id, :studied_factor => {:start_value => 10.02, :end_value => 50, :standard_deviation => 0.6}
    fs_updated = assigns(:studied_factor)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.start_value, 10.02
    assert_equal fs_updated.end_value, 50
    assert_equal fs_updated.standard_deviation, 0.6
  end

  test "should not create factor studied which has fields containing the comma in the decimal number" do
    data_file=data_files(:editable_data_file)
    mi = measured_items(:time)
    unit = units(:gram)
    fs = {:measured_item_id => mi.id, :start_value => "1,5" , :end_value => 10, :unit => unit}
    post :create, :studied_factor => fs, :data_file_id => data_file.id, :version => data_file.version
    fs = assigns(:studied_factor)
    assert_nil fs
  end

  test 'should not update factor studied which has fields containing the comma in the decimal number' do
    fs = studied_factors(:studied_factor_time)
    assert_not_nil fs

    put :update, :id => fs.id, :data_file_id => fs.data_file.id, :studied_factor => {:start_value => "10,02", :end_value => 50, :standard_deviation => 0.6}
    fs_updated = assigns(:studied_factor)
    assert_nil fs_updated
  end

  test 'should create FSes from the existing FSes' do
    fs_array = []
    user = Factory(:user)
    login_as(user)
    d = Factory(:data_file, :contributor => user)
    assert_equal d.studied_factors.count, 0
    #create bunch of FSes which are different
    i=0
    while i < 3  do
      fs_array.push Factory(:studied_factor, :start_value => i)
      i +=1
    end
    post :create_from_existing, :data_file_id => d.id, :version => d.latest_version, "checkbox_#{fs_array.first.id}" => fs_array.first.id, "checkbox_#{fs_array[1].id}" => fs_array[1].id, "checkbox_#{fs_array[2].id}" => fs_array[2].id
    d.reload
    assert_equal d.studied_factors.count, 3
    d.studied_factors.each do |fs|
      assert_not_nil fs.studied_factor_links
      assert_equal fs.substances, fs_array.first.substances
    end
  end
end
