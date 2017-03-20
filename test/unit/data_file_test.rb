require 'test_helper'
require 'openbis_test_helper'

class DataFileTest < ActiveSupport::TestCase
  fixtures :all

  test 'associations' do
    datafile_owner = Factory :user
    datafile = Factory :data_file, policy: Factory(:all_sysmo_viewable_policy), contributor: datafile_owner
    assert_equal datafile_owner, datafile.contributor
    datafile.content_blob.destroy unless datafile.content_blob.nil?

    blob = Factory.create(:content_blob, original_filename: 'df.ppt', content_type: 'application/ppt', asset: datafile, asset_version: datafile.version) # content_blobs(:picture_blob)
    datafile.reload
    assert_equal blob, datafile.content_blob
  end

  test 'content blob search terms' do
    check_for_soffice
    df = Factory :data_file, content_blob: Factory(:doc_content_blob, original_filename: 'word.doc')
    assert_equal ['This is a ms word doc format', 'doc', 'word.doc'], df.content_blob_search_terms.sort

    df = Factory :xlsx_spreadsheet_datafile
    assert_includes df.content_blob_search_terms, 'mild stress'
  end

  test 'event association' do
    User.with_current_user Factory(:user) do
      datafile = Factory :data_file, contributor: User.current_user
      event = Factory :event, contributor: User.current_user
      datafile.events << event
      assert datafile.valid?
      assert datafile.save
      assert_equal 1, datafile.events.count
    end
  end

  test 'assay association' do
    User.with_current_user Factory(:user) do
      datafile = Factory :data_file, policy: Factory(:all_sysmo_viewable_policy)
      assay = assays(:modelling_assay_with_data_and_relationship)
      relationship = relationship_types(:validation_data)
      assay_asset = assay_assets(:metabolomics_assay_asset1)
      assert_not_equal assay_asset.asset, datafile
      assert_not_equal assay_asset.assay, assay
      assay_asset.asset = datafile
      assay_asset.assay = assay
      assay_asset.relationship_type = relationship
      assay_asset.save!
      assay_asset.reload

      assert assay_asset.valid?
      assert_equal assay_asset.asset, datafile
      assert_equal assay_asset.assay, assay
      assert_equal assay_asset.relationship_type, relationship
    end
  end

  test 'sort by updated_at' do
    assert_equal DataFile.all.sort_by { |df| df.updated_at.to_i * -1 }, DataFile.all
  end

  test 'validation' do
    asset = DataFile.new title: 'fred', projects: [projects(:sysmo_project)], policy: Factory(:private_policy)
    assert asset.valid?

    asset = DataFile.new projects: [projects(:sysmo_project)], policy: Factory(:private_policy)
    assert !asset.valid?

    # VL only:allow no projects
    as_virtualliver do
      asset = DataFile.new title: 'fred', policy: Factory(:private_policy)
      assert asset.valid?

      asset = DataFile.new title: 'fred', projects: [], policy: Factory(:private_policy)
      assert asset.valid?
    end
  end

  test 'version created on save' do
    User.current_user = Factory(:user)
    df = DataFile.new(title: 'testing versions', projects: [Factory(:project)], policy: Factory(:private_policy))
    assert df.valid?
    df.save!
    df = DataFile.find(df.id)
    assert_equal 1, df.version

    assert_not_nil df.find_version(1)
    assert_equal df.find_version(1), df.latest_version
    assert_equal df.contributor, df.latest_version.contributor
  end

  test 'projects' do
    df = data_files(:sysmo_data_file)
    p = projects(:sysmo_project)
    assert_equal [p], df.projects
    assert_equal [p], df.latest_version.projects
  end

  test 'policy defaults to system default' do
    with_config_value 'default_all_visitors_access_type', Policy::ACCESSIBLE do
      df_hash = Factory.attributes_for(:data_file)
      df_hash[:policy] = nil
      df = DataFile.new(df_hash)
      df.save!
      df.reload
      assert_not_nil df.policy
      assert_equal Policy::ACCESSIBLE, df.policy.access_type
      assert df.policy.permissions.empty?
    end
  end

  test 'data_file with no contributor' do
    df = data_files(:data_file_with_no_contributor)
    assert_nil df.contributor
  end

  test 'versions destroyed as dependent' do
    df = data_files(:sysmo_data_file)
    User.current_user = df.contributor
    assert_equal 1, df.versions.size, 'There should be 1 version of this DataFile'
    assert_difference(['DataFile.count', 'DataFile::Version.count'], -1) do
      df.destroy
    end
  end

  test 'managers' do
    df = data_files(:picture)
    assert_not_nil df.managers
    contributor = people(:person_for_datafile_owner)
    manager = people(:person_for_owner_of_my_first_sop)
    assert df.managers.include?(contributor)
    assert df.managers.include?(manager)
    assert !df.managers.include?(people(:person_not_associated_with_any_projects))
  end

  test 'make sure content blob is preserved after deletion' do
    df = Factory :data_file # data_files(:picture)
    User.current_user = df.contributor
    refute_nil df.content_blob, 'Must have an associated content blob for this test to work'
    cb = df.content_blob
    assert_difference('DataFile.count', -1) do
      assert_no_difference('ContentBlob.count') do
        df.destroy
      end
    end
    assert_not_nil ContentBlob.find(cb.id)
  end

  test 'is restorable after destroy' do
    df = Factory :data_file, policy: Factory(:all_sysmo_viewable_policy), title: 'is it restorable?'
    User.current_user = df.contributor
    assert_difference('DataFile.count', -1) do
      df.destroy
    end
    assert_nil DataFile.find_by_title 'is it restorable?'
    assert_difference('DataFile.count', 1) do
      disable_authorization_checks { DataFile.restore_trash!(df.id) }
    end
    assert_not_nil DataFile.find_by_title 'is it restorable?'
  end

  test 'failing to delete (due to can_not_delete) still creates trash' do
    df = Factory :data_file, policy: Factory(:private_policy), contributor: Factory(:user)
    User.with_current_user Factory(:user) do
      assert_no_difference('DataFile.count') do
        df.destroy
      end
      assert_not_nil DataFile.restore_trash(df.id)
    end
  end

  test 'test uuid generated' do
    x = data_files(:private_data_file)
    assert_nil x.attributes['uuid']
    x.save
    assert_not_nil x.attributes['uuid']
  end

  test 'title_trimmed' do
    User.with_current_user Factory(:user) do
      df = Factory :data_file, policy: Factory(:policy, access_type: Policy::EDITING) # data_files(:picture)
      df.title = ' should be trimmed'
      df.save!
      assert_equal 'should be trimmed', df.title
    end
  end

  test "uuid doesn't change" do
    x = Factory :data_file, policy: Factory(:all_sysmo_viewable_policy) # data_files(:picture)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end

  test 'can get relationship type' do
    df = data_file_versions(:picture_v1)
    assay = assays(:modelling_assay_with_data_and_relationship)
    assert_equal relationship_types(:validation_data), df.relationship_type(assay)
  end

  test 'delete checks authorization' do
    df = Factory :data_file

    User.current_user = nil
    assert !df.destroy

    User.current_user = df.contributor
    assert df.destroy
  end

  test 'update checks authorization' do
    unupdated_title = 'Unupdated Title'
    df = Factory :data_file, title: unupdated_title
    User.current_user = nil

    assert !df.update_attributes(title: 'Updated Title')
    assert_equal unupdated_title, df.reload.title
  end

  test 'to rdf' do
    df = Factory :data_file, assay_ids: [Factory(:assay, technology_type_uri: 'http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type').id, Factory(:assay).id]
    pub = Factory :publication
    Factory :relationship, subject: df, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub
    df.reload
    rdf = df.to_rdf
    assert_not_nil rdf
    # just checks it is valid rdf/xml and contains some statements for now
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 0
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject
    end
  end

  test 'fs_search_fields' do
    user = Factory :user
    User.with_current_user user do
      df = Factory :data_file, contributor: user
      sf1 = Factory :studied_factor_link, substance: Factory(:compound, name: 'sugar')
      sf2 = Factory :studied_factor_link, substance: Factory(:compound, name: 'iron')
      comp = sf2.substance
      Factory :synonym, name: 'metal', substance: comp
      Factory :mapping_link, substance: comp, mapping: Factory(:mapping, chebi_id: '12345', kegg_id: '789', sabiork_id: 111)
      studied_factor = Factory :studied_factor, studied_factor_links: [sf1, sf2], data_file: df
      assert df.fs_search_fields.include?('sugar')
      assert df.fs_search_fields.include?('metal')
      assert df.fs_search_fields.include?('iron')
      assert df.fs_search_fields.include?('concentration')
      assert df.fs_search_fields.include?('CHEBI:12345')
      assert df.fs_search_fields.include?('12345')
      assert df.fs_search_fields.include?('111')
      assert df.fs_search_fields.include?('789')
      assert_equal 8, df.fs_search_fields.count
    end
  end

  test 'fs_search_fields_with_synonym_substance' do
    user = Factory :user
    User.with_current_user user do
      df = Factory :data_file, contributor: user
      suger = Factory(:compound, name: 'sugar')
      iron = Factory(:compound, name: 'iron')
      metal = Factory :synonym, name: 'metal', substance: iron
      Factory :mapping_link, substance: iron, mapping: Factory(:mapping, chebi_id: '12345', kegg_id: '789', sabiork_id: 111)

      sf1 = Factory :studied_factor_link, substance: suger
      sf2 = Factory :studied_factor_link, substance: metal

      Factory :studied_factor, studied_factor_links: [sf1, sf2], data_file: df
      assert df.fs_search_fields.include?('sugar')
      assert df.fs_search_fields.include?('metal')
      assert df.fs_search_fields.include?('iron')
      assert df.fs_search_fields.include?('concentration')
      assert df.fs_search_fields.include?('CHEBI:12345')
      assert df.fs_search_fields.include?('12345')
      assert df.fs_search_fields.include?('111')
      assert df.fs_search_fields.include?('789')
      assert_equal 8, df.fs_search_fields.count
    end
  end

  test 'cache_remote_content' do
    user = Factory :user
    User.with_current_user(user) do
      mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://mockedlocation.com/picture.png'

      data_file = Factory :data_file, content_blob: ContentBlob.new(url: 'http://mockedlocation.com/picture.png', original_filename: 'picture.png')

      data_file.save!

      refute data_file.content_blob.file_exists?

      data_file.cache_remote_content_blob

      assert data_file.content_blob.file_exists?
    end
  end

  test 'sample template?' do
    Factory(:string_sample_attribute_type, title: 'String')

    data_file = Factory :data_file, content_blob: Factory(:sample_type_populated_template_content_blob), policy: Factory(:public_policy)
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    sample_type = SampleType.new title: 'from template', uploaded_template: true, project_ids: [Factory(:project).id]
    sample_type.content_blob = Factory(:sample_type_template_content_blob)
    sample_type.build_attributes_from_template
    disable_authorization_checks { sample_type.save! }

    assert data_file.sample_template?
    assert_includes data_file.possible_sample_types, sample_type

    data_file = Factory :data_file, content_blob: Factory(:small_test_spreadsheet_content_blob), policy: Factory(:public_policy)
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types
  end

  test 'factory test' do
    # sanity check that the updated factories work whilst fixing them, no harm leaving this test here
    df = Factory(:rightfield_annotated_datafile)
    blob = df.content_blob
    assert blob.file_exists?
    assert_equal 'simple_populated_rightfield.xls', blob.original_filename
    assert_equal 'application/excel', blob.content_type
  end

  test 'spreadsheet annotation search fields' do
    df = Factory(:data_file)
    cr = Factory(:cell_range, worksheet: Factory(:worksheet, content_blob: df.content_blob))

    Annotation.create(source: Factory(:user),
                      annotatable: cr,
                      attribute_name: 'annotation',
                      value: 'fish')

    df.reload
    refute_empty df.content_blob.worksheets
    fields = df.spreadsheet_annotation_search_fields
    assert_equal ['fish'], fields
  end

  test 'openbis?' do
    stub_request(:head, 'http://www.abc.com').to_return(
      headers: { content_length: 500, content_type: 'text/plain' }, status: 200)

    refute Factory(:data_file).openbis?
    refute Factory(:data_file, content_blob: Factory(:url_content_blob)).openbis?
    assert Factory(:data_file, content_blob: Factory(:url_content_blob, url: 'openbis:1:dataset:2222')).openbis?
  end

  test 'build from openbis' do
    mock_openbis_calls
    User.with_current_user(Factory(:person).user) do
      permission_project = Factory(:project)
      endpoint = Factory(:openbis_endpoint, policy: Factory(:private_policy, permissions: [Factory(:permission, contributor: permission_project)]))
      assert_equal 1, endpoint.policy.permissions.count
      df = DataFile.build_from_openbis(endpoint, '20160210130454955-23')
      refute_nil df
      assert df.openbis?
      assert_equal "openbis:#{endpoint.id}:dataset:20160210130454955-23", df.content_blob.url
      refute_equal df.policy, endpoint.policy
      assert_equal endpoint.policy.access_type, df.policy.access_type
      assert_equal 1, df.policy.permissions.length
      permission = df.policy.permissions.first
      assert_equal permission_project, permission.contributor
      assert_equal Policy::NO_ACCESS, permission.access_type
    end
  end

  test 'openbis download restricted' do
    df = openbis_linked_data_file
    assert df.content_blob.openbis_dataset.size < 600.kilobytes
    assert df.content_blob.openbis_dataset.size > 100.kilobytes

    with_config_value :openbis_download_limit,100.kilobytes do
      assert df.openbis_size_download_restricted?
      assert df.download_disabled?
    end

    with_config_value :openbis_download_limit,600.kilobytes do
      refute df.openbis_size_download_restricted?
      refute df.download_disabled?
    end
  end
end
