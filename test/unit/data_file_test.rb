require 'test_helper'
require 'openbis_test_helper'

class DataFileTest < ActiveSupport::TestCase
  fixtures :all

  test 'associations' do
    datafile_owner = FactoryBot.create :user
    datafile = FactoryBot.create :data_file, policy: FactoryBot.create(:all_sysmo_viewable_policy), contributor: datafile_owner.person
    assert_equal datafile_owner.person, datafile.contributor
    datafile.content_blob.destroy unless datafile.content_blob.nil?

    blob = FactoryBot.create(:content_blob, original_filename: 'df.ppt', content_type: 'application/ppt', asset: datafile, asset_version: datafile.version) # content_blobs(:picture_blob)
    datafile.reload
    assert_equal blob, datafile.content_blob
  end

  test 'content blob search terms' do
    df = FactoryBot.create :data_file, content_blob: FactoryBot.create(:doc_content_blob, original_filename: 'word.doc')
    assert_equal ['This is a ms word doc format', 'doc', 'word.doc'], df.content_blob_search_terms.sort

    df = FactoryBot.create :xlsx_spreadsheet_datafile
    assert_includes df.content_blob_search_terms, 'mild stress on ageing in a multispecies approach Experiment Transcripto'
  end

  test 'event association' do
    User.with_current_user FactoryBot.create(:user) do
      datafile = FactoryBot.create :data_file, contributor: User.current_user.person
      event = FactoryBot.create :event, contributor: User.current_user.person
      datafile.events << event
      assert datafile.valid?
      assert datafile.save
      assert_equal 1, datafile.events.count
    end
  end

  test 'assay association' do
    person = FactoryBot.create(:person)
    User.with_current_user person.user do
      datafile = FactoryBot.create :data_file, contributor:person
      assay = FactoryBot.create :assay, contributor:person
      relationship = relationship_types(:validation_data)
      assay_asset = AssayAsset.new
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

  test 'validation' do
    asset = DataFile.new title: 'fred', projects: [projects(:sysmo_project)], policy: FactoryBot.create(:private_policy)
    assert asset.valid?

    asset = DataFile.new projects: [projects(:sysmo_project)], policy: FactoryBot.create(:private_policy)
    refute asset.valid?

  end

  test 'version created on save' do
    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      df = FactoryBot.build(:data_file,title: 'testing versions', policy: FactoryBot.create(:private_policy), contributor: person)
      assert df.valid?
      refute df.persisted?
      df.save!
      df = DataFile.find(df.id)
      assert_equal 1, df.version

      assert_not_nil df.find_version(1)
      assert_equal df.find_version(1), df.latest_version
      assert_equal df.contributor, df.latest_version.contributor
    end
  end

  test 'projects' do
    df = data_files(:sysmo_data_file)
    p = projects(:sysmo_project)
    assert_equal [p], df.projects
    assert_equal [p], df.latest_version.projects
  end

  test 'policy defaults to system default' do
    with_config_value 'default_all_visitors_access_type', Policy::NO_ACCESS do
      df = FactoryBot.build(:data_file)
      refute df.persisted?
      df.save!
      df.reload
      refute_nil df.policy
      assert_equal Policy::NO_ACCESS, df.policy.access_type
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
    df = FactoryBot.create :data_file # data_files(:picture)
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

  test 'test uuid generated' do
    x = data_files(:private_data_file)
    assert_nil x.attributes['uuid']
    x.save
    assert_not_nil x.attributes['uuid']
  end

  test 'title_trimmed' do
    User.with_current_user FactoryBot.create(:user) do
      df = FactoryBot.create :data_file, policy: FactoryBot.create(:policy, access_type: Policy::EDITING) # data_files(:picture)
      df.title = ' should be trimmed'
      df.save!
      assert_equal 'should be trimmed', df.title
    end
  end

  test "uuid doesn't change" do
    x = FactoryBot.create :data_file, policy: FactoryBot.create(:all_sysmo_viewable_policy) # data_files(:picture)
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
    df = FactoryBot.create :data_file

    User.current_user = nil
    assert !df.destroy

    User.current_user = df.contributor
    assert df.destroy
  end

  test 'update checks authorization' do
    unupdated_title = 'Unupdated Title'
    df = FactoryBot.create :data_file, title: unupdated_title
    User.current_user = nil

    assert !df.update(title: 'Updated Title')
    assert_equal unupdated_title, df.reload.title
  end

  test 'to rdf' do
    df = FactoryBot.create :data_file, assay_ids: [FactoryBot.create(:assay, technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Technology_type').id, FactoryBot.create(:assay).id]
    pub = FactoryBot.create :publication
    FactoryBot.create :relationship, subject: df, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub
    df.reload
    rdf = df.to_rdf
    assert_not_nil rdf
    # just checks it is valid rdf/xml and contains some statements for now
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 0
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject
    end
  end

  test 'cache_remote_content' do
    user = FactoryBot.create :user
    User.with_current_user(user) do
      mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", 'http://mockedlocation.com/picture.png'

      data_file = FactoryBot.create :data_file, contributor:user.person, content_blob: ContentBlob.new(url: 'http://mockedlocation.com/picture.png', original_filename: 'picture.png')

      data_file.save!

      refute data_file.content_blob.file_exists?

      data_file.cache_remote_content_blob

      assert data_file.content_blob.file_exists?
    end
  end

  test 'sample template?' do
    create_sample_attribute_type

    person = FactoryBot.create(:person)

    User.with_current_user(person.user) do
      data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:sample_type_populated_template_content_blob), policy: FactoryBot.create(:public_policy)
      refute data_file.sample_template?
      assert_empty data_file.possible_sample_types

      sample_type = SampleType.new title: 'from template', uploaded_template: true, project_ids: [person.projects.first.id], contributor: person
      sample_type.content_blob = FactoryBot.create(:sample_type_template_content_blob)
      sample_type.build_attributes_from_template
      disable_authorization_checks { sample_type.save! }

      assert data_file.sample_template?
      assert_includes data_file.possible_sample_types, sample_type

      #doesn't match
      data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:small_test_spreadsheet_content_blob), policy: FactoryBot.create(:public_policy)
      refute data_file.sample_template?
      assert_empty data_file.possible_sample_types

    end
  end

  test 'possible sample type ignore hidden' do
    create_sample_attribute_type

    person = FactoryBot.create(:person)

    data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:sample_type_populated_template_content_blob), policy: FactoryBot.create(:public_policy)
    refute data_file.sample_template?
    assert_empty data_file.possible_sample_types

    #visible
    sample_type1 = SampleType.new title: 'visible', uploaded_template: true, project_ids: person.projects.collect(&:id), contributor: person
    sample_type1.content_blob = FactoryBot.create(:sample_type_template_content_blob)
    sample_type1.build_attributes_from_template
    disable_authorization_checks { sample_type1.save! }

    #hidden
    person2 = FactoryBot.create(:person)
    sample_type2 = SampleType.new title: 'hidden', uploaded_template: true, project_ids:person2.projects.collect(&:id), contributor: person2
    sample_type2.content_blob = FactoryBot.create(:sample_type_template_content_blob)
    sample_type2.build_attributes_from_template
    disable_authorization_checks { sample_type2.save! }

    User.with_current_user(person.user) do
      assert sample_type1.can_view?
      refute sample_type2.can_view?

      possible = data_file.possible_sample_types
      refute_empty possible
      assert_includes possible,sample_type1
      refute_includes possible,sample_type2
    end
  end

  test 'factory test' do
    # sanity check that the updated factories work whilst fixing them, no harm leaving this test here
    df = FactoryBot.create(:rightfield_annotated_datafile)
    blob = df.content_blob
    assert blob.file_exists?
    assert_equal 'simple_populated_rightfield.xls', blob.original_filename
    assert_equal 'application/vnd.ms-excel', blob.content_type
  end

  test 'openbis?' do
    mock_openbis_calls
    User.with_current_user(FactoryBot.create(:user)) do
      stub_request(:head, 'http://www.abc.com').to_return(
          headers: { content_length: 500, content_type: 'text/plain' }, status: 200
      )

      refute FactoryBot.create(:data_file).openbis?
      refute FactoryBot.create(:data_file, content_blob: FactoryBot.create(:url_content_blob)).openbis?

      # old openbis integration entry
      refute FactoryBot.create(:data_file, content_blob: FactoryBot.create(:url_content_blob, url: 'openbis:1:dataset:2222')).openbis?
      assert openbis_linked_data_file.openbis?
    end
  end

  test 'openbis_dataset' do
    mock_openbis_calls
    User.with_current_user(FactoryBot.create(:user)) do
      assert_nil FactoryBot.create(:data_file).openbis_dataset
      ds = openbis_linked_data_file.openbis_dataset

      assert ds
      assert ds.is_a? Seek::Openbis::Dataset
      assert ds.perm_id
    end
  end

  # DataFile no longers knows how to create openbis, it is other way arround
  #   test 'build from openbis' do
  #     mock_openbis_calls
  #     User.with_current_user(FactoryBot.create(:person).user) do
  #       permission_project = FactoryBot.create(:project)
  #       endpoint = FactoryBot.create(:openbis_endpoint,
  # policy: FactoryBot.create(:private_policy, permissions: [FactoryBot.create(:permission, contributor: permission_project)]))
  #       assert_equal 1, endpoint.policy.permissions.count
  #       df = DataFile.build_from_openbis(endpoint, '20160210130454955-23')
  #       refute_nil df
  #       assert df.openbis?
  #       assert_equal "openbis:#{endpoint.id}:dataset:20160210130454955-23", df.content_blob.url
  #       refute_equal df.policy, endpoint.policy
  #       assert_equal endpoint.policy.access_type, df.policy.access_type
  #       assert_equal 1, df.policy.permissions.length
  #       permission = df.policy.permissions.first
  #       assert_equal permission_project, permission.contributor
  #       assert_equal Policy::NO_ACCESS, permission.access_type
  #     end
  #   end
  #
  #   test 'build from openbis_dataset' do
  #     mock_openbis_calls
  #     User.with_current_user(FactoryBot.create(:person).user) do
  #       permission_project = FactoryBot.create(:project)
  #       endpoint = FactoryBot.create(:openbis_endpoint, policy: FactoryBot.create(:private_policy, permissions: [FactoryBot.create(:permission, contributor: permission_project)]))
  #       assert_equal 1, endpoint.policy.permissions.count
  #       dataset = Seek::Openbis::Dataset.new(endpoint, '20160210130454955-23')
  #       df = DataFile.build_from_openbis_dataset(dataset)
  #       refute_nil df
  #       assert df.openbis?
  #       assert_equal "openbis:#{endpoint.id}:dataset:20160210130454955-23", df.content_blob.url
  #       refute_equal df.policy, endpoint.policy
  #       assert_equal endpoint.policy.access_type, df.policy.access_type
  #       assert_equal 1, df.policy.permissions.length
  #       permission = df.policy.permissions.first
  #       assert_equal permission_project, permission.contributor
  #       assert_equal Policy::NO_ACCESS, permission.access_type
  #     end
  #   end

  test 'openbis download restricted' do
    mock_openbis_calls
    User.with_current_user(FactoryBot.create(:user)) do
      df = openbis_linked_data_file
      assert df.external_asset.content.size < 600.kilobytes
      assert df.external_asset.content.size > 100.kilobytes

      with_config_value :openbis_download_limit, 100.kilobytes do
        assert df.openbis_size_download_restricted?
        assert df.download_disabled?
      end

      with_config_value :openbis_download_limit, 600.kilobytes do
        refute df.openbis_size_download_restricted?
        refute df.download_disabled?
      end
    end
  end

  test 'simulation data?' do
    df = FactoryBot.create(:data_file, simulation_data: true)
    df2 = FactoryBot.create(:data_file)

    assert df.simulation_data?
    refute df2.simulation_data?

    assert_includes DataFile.simulation_data, df
    refute_includes DataFile.simulation_data, df2
  end

  test 'can copy assay associations' do
    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      df = FactoryBot.create(:data_file, contributor:person)

      aa1 = FactoryBot.create(:assay_asset, direction: AssayAsset::Direction::INCOMING,
                    asset: df, assay:FactoryBot.create(:assay, contributor:person))
      aa2 = FactoryBot.create(:assay_asset, direction: AssayAsset::Direction::OUTGOING,
                    asset: df, assay:FactoryBot.create(:assay, contributor:person))

      s1 = FactoryBot.create(:sample, originating_data_file: df, contributor:person)
      s2 = FactoryBot.create(:sample, originating_data_file: df, contributor:person)

      assert_equal 2, df.extracted_samples.count

      assert_difference('AssayAsset.count', 4) do # samples * assay_assets
        df.copy_assay_associations(df.extracted_samples)
      end

      assert_equal df.assays.sort, s1.assays.sort
      assert_equal df.assays.sort, s2.assays.sort

      assert_equal aa1.direction, s1.assay_assets.where(assay_id: aa1.assay_id).first.direction
      assert_equal aa2.direction, s1.assay_assets.where(assay_id: aa2.assay_id).first.direction
    end
  end

  test 'extract_samples without confirm shouldnt trigger gatekeeper check' do
    gate_keeper = FactoryBot.create(:asset_gatekeeper)

    FactoryBot.create(:string_sample_attribute_type)
    sample_type = SampleType.new title: 'from template', project_ids: [gate_keeper.projects.first.id],
                                 content_blob: FactoryBot.create(:sample_type_template_content_blob), contributor: FactoryBot.create(:person)
    sample_type.build_attributes_from_template
    disable_authorization_checks { sample_type.save! }

    data_file = FactoryBot.create :data_file, content_blob: FactoryBot.create(:sample_type_populated_template_content_blob),
                        policy: FactoryBot.create(:public_policy), contributor: gate_keeper
    refute_empty data_file.extract_samples(sample_type, false, false)
  end

  test 'can copy assay associations for selected assays' do
    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      df = FactoryBot.create(:data_file,contributor:person)
      aa1 = FactoryBot.create(:assay_asset, direction: AssayAsset::Direction::INCOMING,
                    asset: df,  assay:FactoryBot.create(:assay, contributor:person))
      aa2 = FactoryBot.create(:assay_asset, direction: AssayAsset::Direction::OUTGOING,
                    asset: df,  assay:FactoryBot.create(:assay, contributor:person))

      s1 = FactoryBot.create(:sample, originating_data_file: df,contributor:person)
      s2 = FactoryBot.create(:sample, originating_data_file: df,contributor:person)

      assert_equal 2, df.extracted_samples.count

      assert_difference('AssayAsset.count', 2) do
        df.copy_assay_associations(df.extracted_samples, [aa1.assay])
      end

      assert_equal [aa1.assay], s1.assays
      assert_equal [aa1.assay], s2.assays

      assert_equal aa1.direction, s1.assay_assets.where(assay_id: aa1.assay_id).first.direction
    end
  end

  test 'can copy assay associations for selected assay IDs' do
    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      df = FactoryBot.create(:data_file,contributor:person)
      aa1 = FactoryBot.create(:assay_asset, direction: AssayAsset::Direction::INCOMING,
                    asset: df, assay:FactoryBot.create(:assay, contributor:person))
      aa2 = FactoryBot.create(:assay_asset, direction: AssayAsset::Direction::OUTGOING,
                    asset: df, assay:FactoryBot.create(:assay, contributor:person))

      s1 = FactoryBot.create(:sample, originating_data_file: df, contributor:person)
      s2 = FactoryBot.create(:sample, originating_data_file: df, contributor:person)

      assert_equal 2, df.extracted_samples.count

      assert_difference('AssayAsset.count', 2) do
        df.copy_assay_associations(df.extracted_samples, [aa1.assay_id])
      end

      assert_equal [aa1.assay], s1.assays
      assert_equal [aa1.assay], s2.assays

      assert_equal aa1.direction, s1.assay_assets.where(assay_id: aa1.assay_id).first.direction
    end
  end

  test 'ontology cv annotation properties'do
    data_file = FactoryBot.create(:data_file)

    assert data_file.supports_controlled_vocab_annotations?
    refute data_file.supports_controlled_vocab_annotations?(:topics)
    refute data_file.supports_controlled_vocab_annotations?(:operations)
    assert data_file.supports_controlled_vocab_annotations?(:data_formats)
    assert data_file.supports_controlled_vocab_annotations?(:data_types)

    refute data_file.respond_to?(:topic_annotations)
    refute data_file.respond_to?(:operation_annotations)
    assert data_file.respond_to?(:data_format_annotations)
    assert data_file.respond_to?(:data_type_annotations)
  end
end
