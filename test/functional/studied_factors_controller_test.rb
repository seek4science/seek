require 'test_helper'

class StudiedFactorsControllerTest < ActionController::TestCase
  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:quentin)
  end

  test 'routes' do
    assert_generates '/data_files/1/studied_factors', controller: 'studied_factors', action: 'index', data_file_id: '1'
  end

  test 'can only go to factors studied if the user can edit the data file' do
    df = data_files(:editable_data_file)
    df.save
    get :index, data_file_id: df.id, version: df.version
    assert_response :success

    df = data_files(:downloadable_data_file)
    df.save
    get :index, data_file_id: df.id, version: df.version
    assert_not_nil flash[:error]
  end

  test 'should create the factor studied with the concentration of the compound' do
    mock_sabio_rk
    df = data_files(:editable_data_file)
    mi = measured_items(:concentration)
    unit = units(:gram)
    fs = { measured_item_id: mi.id, start_value: 1, end_value: 10, unit_id: unit.id }
    compound_name = 'CTP'
    compound_annotation = Seek::SabiorkWebservices.new.get_compound_annotation(compound_name)

    post :create, studied_factor: fs, data_file_id: df.id, version: df.version, substance_list: compound_name

    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert fs.valid?
    assert_equal fs.measured_item, mi
    substance = fs.studied_factor_links.first.substance
    assert_equal substance.name, compound_annotation['recommended_name']
    mappings = substance.mapping_links.map(&:mapping)
    kegg_ids = []
    chebi_ids = []
    mappings.each do |m|
      assert_equal m.sabiork_id, compound_annotation['sabiork_id'].to_i
      kegg_ids.push m.kegg_id if !kegg_ids.include?(m.kegg_id) && !m.kegg_id.blank?
      chebi_ids.push m.chebi_id if !chebi_ids.include?(m.chebi_id) && !m.chebi_id.blank?
    end
    assert_equal kegg_ids.sort, compound_annotation['kegg_ids'].sort
    assert_equal chebi_ids.sort, compound_annotation['chebi_ids'].sort

    synonyms = substance.synonyms.map(&:name)
    assert_equal synonyms.sort, compound_annotation['synonyms'].sort
  end

  test 'should create factor studied with the none concentration item and no substance' do
    data_file = data_files(:editable_data_file)
    mi = measured_items(:time)
    unit = units(:gram)
    fs = { measured_item_id: mi.id, start_value: 1, end_value: 10, unit_id: unit.id }
    post :create, studied_factor: fs, data_file_id: data_file.id, version: data_file.version
    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert fs.valid?
    assert_equal fs.measured_item, mi
  end

  test 'should not create the factor studied with the concentration of no substance' do
    df = data_files(:editable_data_file)
    mi = measured_items(:concentration)
    unit = units(:gram)
    fs = { measured_item_id: mi.id, start_value: 1, end_value: 10, unit_id: unit.id }
    post :create, studied_factor: fs, data_file_id: df.id, version: df.version
    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert !fs.valid?
  end

  test 'should create the factor studied with the concentration of the compound chosen from autocomplete' do
    df = data_files(:editable_data_file)
    mi = measured_items(:concentration)
    cp = compounds(:compound_glucose)
    unit = units(:gram)
    fs = { measured_item_id: mi.id, start_value: 1, end_value: 10, unit_id: unit.id }
    post :create, studied_factor: fs, data_file_id: df.id, version: df.version, substance_list: cp.name
    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert fs.valid?
    assert_equal fs.measured_item, mi
    assert_equal fs.studied_factor_links.first.substance, cp
  end

  test "should create the factor studied with the concentration of the compound's synonym" do
    df = data_files(:editable_data_file)
    mi = measured_items(:concentration)
    syn = synonyms(:glucose_synonym)
    unit = units(:gram)
    fs = { measured_item_id: mi.id, start_value: 1, end_value: 10, unit_id: unit.id }
    post :create, studied_factor: fs, data_file_id: df.id, version: df.version, substance_list: syn.name
    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert fs.valid?
    assert_equal fs.measured_item, mi
    assert_equal fs.studied_factor_links.first.substance, syn
  end

  test 'should update the factor studied of concentration to time' do
    fs = studied_factors(:studied_factor_concentration_glucose)
    assert_not_nil fs
    assert_equal fs.measured_item, measured_items(:concentration)
    assert_equal fs.studied_factor_links.first.substance, compounds(:compound_glucose)

    mi = measured_items(:time)
    put :update, id: fs.id, data_file_id: fs.data_file.id, studied_factor: { measured_item_id: mi.id }
    fs_updated = assigns(:studied_factor)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.measured_item, mi
    assert fs_updated.studied_factor_links.blank?
  end

  test 'should update the factor studied of time to concentration' do
    fs = studied_factors(:studied_factor_time)
    assert_not_nil fs
    assert_equal fs.measured_item, measured_items(:time)
    assert fs.studied_factor_links.blank?

    mi = measured_items(:concentration)
    cp = compounds(:compound_glucose)
    put :update, id: fs.id, data_file_id: fs.data_file.id, studied_factor: { measured_item_id: mi.id }, substance_list: cp.name
    fs_updated = assigns(:studied_factor)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.measured_item, mi
    assert_equal fs_updated.studied_factor_links.first.substance, cp
  end

  test 'should update the factor studied of time to pressure' do
    fs = studied_factors(:studied_factor_time)
    assert_not_nil fs
    assert_equal fs.measured_item, measured_items(:time)
    assert fs.studied_factor_links.blank?

    mi = measured_items(:pressure)
    put :update, id: fs.id, data_file_id: fs.data_file.id, studied_factor: { measured_item_id: mi.id }
    fs_updated = assigns(:studied_factor)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.measured_item, mi
    assert fs_updated.studied_factor_links.blank?
  end

  test 'should update the factor studied of concentration of glucose to concentration of glycine' do
    fs = studied_factors(:studied_factor_concentration_glucose)
    assert_not_nil fs
    assert_equal fs.measured_item, measured_items(:concentration)
    assert_equal fs.studied_factor_links.first.substance, compounds(:compound_glucose)

    cp = compounds(:compound_glycine)
    put :update, id: fs.id, data_file_id: fs.data_file.id, studied_factor: { start_value: fs.start_value },
        substance_list: cp.name
    fs_updated = assigns(:studied_factor)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.measured_item, measured_items(:concentration)
    assert_equal fs_updated.studied_factor_links.count, 1
    assert_equal fs_updated.studied_factor_links.first.substance, cp
  end

  test 'should update start_value, end_value, standard_deviation of the factor studied' do
    fs = studied_factors(:studied_factor_time)
    assert_not_nil fs

    put :update, id: fs.id, data_file_id: fs.data_file.id, studied_factor: { start_value: 10.02, end_value: 50, standard_deviation: 0.6 }
    fs_updated = assigns(:studied_factor)
    assert_not_nil fs_updated
    assert fs_updated.valid?
    assert_equal fs_updated.start_value, 10.02
    assert_equal fs_updated.end_value, 50
    assert_equal fs_updated.standard_deviation, 0.6
  end

  test 'should not create factor studied which has fields containing the comma in the decimal number' do
    data_file = data_files(:editable_data_file)
    mi = measured_items(:time)
    unit = units(:gram)
    fs = { measured_item_id: mi.id, start_value: '1,5', end_value: 10, unit_id: unit.id }
    post :create, studied_factor: fs, data_file_id: data_file.id, version: data_file.version
    fs = assigns(:studied_factor)
    assert_nil fs
  end

  test 'should not update factor studied which has fields containing the comma in the decimal number' do
    fs = studied_factors(:studied_factor_time)
    assert_not_nil fs

    put :update, id: fs.id, data_file_id: fs.data_file.id, studied_factor: { start_value: '10,02', end_value: 50, standard_deviation: 0.6 }
    fs_updated = assigns(:studied_factor)
    assert_nil fs_updated
  end

  test 'should create FSes from the existing FSes' do
    fs_array = []
    user = Factory(:user)
    login_as(user)
    d = Factory(:data_file, contributor: user)
    assert_equal d.studied_factors.count, 0
    # create bunch of FSes which are different
    i = 0
    while i < 3
      fs_array.push Factory(:studied_factor, start_value: i)
      i += 1
    end

    assert d.can_manage?

    post :create_from_existing, :data_file_id => d.id, :version => d.latest_version.version, "checkbox_#{fs_array.first.id}" => fs_array.first.id, "checkbox_#{fs_array[1].id}" => fs_array[1].id, "checkbox_#{fs_array[2].id}" => fs_array[2].id
    assert_response :success

    d.reload
    assert_equal d.studied_factors.count, 3
    # test substances
    substances_of_new_fses = []
    d.studied_factors.each do |fs|
      assert_not_nil fs.studied_factor_links
      substances_of_new_fses.push fs.studied_factor_links.first.substance
    end
    substances_of_existing_fses = []
    fs_array.each do |fs|
      substances_of_existing_fses.push fs.studied_factor_links.first.substance
    end
    assert_equal substances_of_existing_fses.sort { |a, b| a.id <=> b.id }, substances_of_new_fses.sort { |a, b| a.id <=> b.id }
  end

  test 'should destroy FS' do
    fs = studied_factors(:studied_factor_concentration_glucose)
    assert_not_nil fs
    assert_equal fs.measured_item, measured_items(:concentration)
    assert_equal fs.studied_factor_links.first.substance, compounds(:compound_glucose)

    delete :destroy, id: fs.id, data_file_id: data_files(:editable_data_file).id

    assert_nil StudiedFactor.find_by_id(fs.id)
    fs.studied_factor_links.each do |sfl|
      assert_nil StudiedFactorLink.find_by_id(sfl.id)
    end
  end

  test 'should create factor studied with growth medium item' do
    data_file = data_files(:editable_data_file)
    mi = measured_items(:growth_medium)
    fs = { measured_item_id: mi.id }
    post :create, studied_factor: fs, data_file_id: data_file.id, version: data_file.version, annotation: { annotation_attribute: 'description', value: 'test value' }
    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert fs.valid?
    assert_equal fs.measured_item, mi
    assert_equal 'test value', fs.annotations_with_attribute('description').first.value.text
  end

  test 'should update factor studied with another description of growth medium item' do
    fs = studied_factors(:studied_factor_growth_medium)
    assert_equal measured_items(:growth_medium), fs.measured_item
    assert_equal 'one value', fs.annotations_with_attribute('description').first.value.text

    put :update, id: fs.id, data_file_id: fs.data_file.id,
        annotation: { annotation_attribute: 'description', value: 'update value' }, studied_factor: { start_value: fs.start_value }
    fs = assigns(:studied_factor)
    assert_not_nil fs
    assert fs.valid?
    assert_equal measured_items(:growth_medium), fs.measured_item
    assert_equal 'update value', fs.annotations_with_attribute('description').first.value.text
  end

  test 'breadcrumb for factors studied' do
    df = data_files(:editable_data_file)
    assert df.can_edit?
    get :index, data_file_id: df.id, version: df.version
    assert_response :success
    assert_select 'div.breadcrumbs', text: /Home #{I18n.t('data_file').pluralize} Index #{df.title} Factors studied Index/, count: 1 do
      assert_select 'a[href=?]', root_path, count: 1
      assert_select 'a[href=?]', data_files_url, count: 1
      assert_select 'a[href=?]', data_file_url(df)
    end
  end

  def mock_sabio_rk
    body = %(<Compound>
  <sabioID>1286</sabioID>
  <KEGGIDs>
    <kegg>C00063</kegg>
  </KEGGIDs>
  <ChebiIDs>
    <chebi>17677</chebi>
    <chebi>37563</chebi>
  </ChebiIDs>
  <Names>
    <name type='Name'>Cytidine triphosphate</name>
    <name type='Name'>Cytidine 5'-triphosphate</name>
    <name type='Recommended'>CTP</name>
  </Names>
</Compound>)
    stub_request(:get, 'http://sabiork.h-its.org/sabioRestWebServices/compounds?compoundName=CTP')
      .with(headers: { 'Accept' => '*/*; q=0.5, application/xml', 'Accept-Encoding' => 'gzip, deflate', 'User-Agent' => 'Ruby' })
      .to_return(status: 200, body: body, headers: {})
  end
end
