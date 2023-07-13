require 'test_helper'

class AssetTest < ActiveSupport::TestCase

  fixtures :all
  include ApplicationHelper

  test 'can create' do
    refute DataFile.can_create?
    refute Model.can_create?
    refute Sop.can_create?
    refute Presentation.can_create?
    refute Publication.can_create?
    refute Investigation.can_create?
    refute Study.can_create?
    refute Assay.can_create?

    User.current_user = FactoryBot.create(:person_not_in_project).user
    refute DataFile.can_create?
    refute Model.can_create?
    refute Sop.can_create?
    refute Presentation.can_create?
    refute Publication.can_create?
    refute Investigation.can_create?
    refute Study.can_create?
    refute Assay.can_create?

    User.current_user = FactoryBot.create(:person).user
    assert DataFile.can_create?
    assert Model.can_create?
    assert Sop.can_create?
    assert Presentation.can_create?
    assert Publication.can_create?
    assert Investigation.can_create?
    assert Study.can_create?
    assert Assay.can_create?
  end

  test 'latest version?' do
    d = FactoryBot.create(:xlsx_spreadsheet_datafile, policy: FactoryBot.create(:public_policy))

    d.save_as_new_version
    FactoryBot.create(:xlsx_content_blob, asset: d, asset_version: d.version)
    d.reload
    assert_equal 2, d.version
    assert_equal 2, d.versions.size
    assert !d.versions[0].latest_version?
    assert d.versions[1].latest_version?
  end

  test 'assay type titles' do
    df = FactoryBot.create :data_file
    assay = FactoryBot.create :experimental_assay
    assay2 = FactoryBot.create :modelling_assay
    assay3 = FactoryBot.create :modelling_assay, assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Cell_cycle'

    disable_authorization_checks do
      assay.associate(df)
      assay2.associate(df)
      assay.reload
      assay2.reload
      assay3.associate(df)
      assay3.reload
      df.reload
    end

    assert_equal ['Cell cycle', 'Experimental assay type', 'Model analysis type'], df.assay_type_titles.sort
    m = FactoryBot.create :model
    assert_equal [], m.assay_type_titles
  end

  test 'contains_downloadable_items?' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage.com', 'Content-Type' => 'text/html'
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage2.com', 'Content-Type' => 'text/html'

    df = FactoryBot.create :data_file
    assert df.contains_downloadable_items?
    assert df.latest_version.contains_downloadable_items?

    df = FactoryBot.create :data_file, content_blob: FactoryBot.create(:content_blob, url: 'http://webpage.com', external_link: true)
    assert !df.contains_downloadable_items?
    assert !df.latest_version.contains_downloadable_items?

    model = FactoryBot.create :model_with_urls
    assert !model.contains_downloadable_items?
    assert !model.latest_version.contains_downloadable_items?

    model = FactoryBot.create :teusink_model
    assert model.contains_downloadable_items?
    assert model.latest_version.contains_downloadable_items?

    model = FactoryBot.create :model_with_urls_and_files
    assert model.contains_downloadable_items?
    assert model.latest_version.contains_downloadable_items?

    df = DataFile.new
    assert !df.contains_downloadable_items?

    model = Model.new
    assert !model.contains_downloadable_items?

    # test for versions
    model = FactoryBot.create :teusink_model

    disable_authorization_checks do
      model.save_as_new_version
      model.reload
      model.content_blobs = [FactoryBot.create(:content_blob, url: 'http://webpage.com', asset: model, asset_version: model.version, external_link: true)]
      model.save!
      model.reload
    end

    assert_equal(2, model.versions.count)
    assert model.find_version(1).contains_downloadable_items?
    assert !model.find_version(2).contains_downloadable_items?
  end

  test 'supports_spreadsheet_explore?' do
    assert FactoryBot.create(:data_file).supports_spreadsheet_explore?
    assert FactoryBot.create(:document).supports_spreadsheet_explore?
    assert FactoryBot.create(:sop).supports_spreadsheet_explore?
    assert FactoryBot.create(:file_template).supports_spreadsheet_explore?
    refute FactoryBot.create(:model).supports_spreadsheet_explore?
    refute FactoryBot.create(:presentation).supports_spreadsheet_explore?
    refute FactoryBot.create(:placeholder).supports_spreadsheet_explore?
    refute FactoryBot.create(:workflow).supports_spreadsheet_explore?
    refute FactoryBot.create(:publication).supports_spreadsheet_explore?
    refute FactoryBot.create(:collection).supports_spreadsheet_explore?
    refute FactoryBot.create(:sample).supports_spreadsheet_explore?
    refute FactoryBot.create(:template).supports_spreadsheet_explore?
  end

  test 'tech type titles' do
    df = FactoryBot.create :data_file
    assay = FactoryBot.create :experimental_assay, technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    assay2 = FactoryBot.create :experimental_assay, technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Imaging'
    assay3 = FactoryBot.create :modelling_assay

    disable_authorization_checks do
      assay.associate(df)
      assay2.associate(df)
      assay3.associate(df)
      assay.reload
      assay2.reload
      df.reload
    end

    assert_equal %w(Binding Imaging), df.technology_type_titles.sort
    m = FactoryBot.create :model
    assert_equal [], m.technology_type_titles
  end

  test 'managers' do
    person = FactoryBot.create(:person)
    person2 = FactoryBot.create(:person, first_name: 'fred', last_name: 'bloggs')
    user = FactoryBot.create(:user)
    sop = FactoryBot.create(:sop, contributor: person)
    assert_equal 1, sop.managers.count
    assert sop.managers.include?(person)

    df = FactoryBot.create(:data_file, contributor: user.person)
    assert_equal 1, df.managers.count
    assert df.managers.include?(user.person)

    policy = FactoryBot.create(:private_policy)
    policy.permissions << FactoryBot.create(:permission, contributor: user.person, access_type: Policy::MANAGING, policy: policy)
    policy.permissions << FactoryBot.create(:permission, contributor: person, access_type: Policy::EDITING, policy: policy)
    assay = FactoryBot.create(:assay, policy: policy, contributor: person2)
    assert_equal 2, assay.managers.count
    assert assay.managers.include?(user.person)
    assert assay.managers.include?(person2)
  end

  test 'tags as text array' do
    model = FactoryBot.create :model
    u = FactoryBot.create :user
    FactoryBot.create :tag, annotatable: model, source: u, value: 'aaa'
    FactoryBot.create :tag, annotatable: model, source: u, value: 'bbb'
    FactoryBot.create :tag, annotatable: model, source: u, value: 'ddd'
    FactoryBot.create :tag, annotatable: model, source: u, value: 'ccc'
    assert_equal %w(aaa bbb ccc ddd), model.annotations_as_text_array.sort

    p = FactoryBot.create :person
    FactoryBot.create :expertise, annotatable: p, source: u, value: 'java'
    FactoryBot.create :tool, annotatable: p, source: u, value: 'trowel'
    assert_equal %w(java trowel), p.annotations_as_text_array.sort
  end

  test 'related people' do
    df = FactoryBot.create :data_file
    sop = FactoryBot.create :sop
    model = FactoryBot.create :model
    presentation = FactoryBot.create :presentation
    publication = FactoryBot.create :publication
    df.creators = [FactoryBot.create(:person), FactoryBot.create(:person)]
    sop.creators = [FactoryBot.create(:person), FactoryBot.create(:person)]
    model.creators = [FactoryBot.create(:person), FactoryBot.create(:person)]
    presentation.creators = [FactoryBot.create(:person), FactoryBot.create(:person)]
    publication.creators = [FactoryBot.create(:person), FactoryBot.create(:person)]

    assert_equal (df.creators | [df.contributor]).sort, df.related_people.sort
    assert_equal (sop.creators | [sop.contributor]).sort, sop.related_people.sort
    assert_equal (model.creators | [model.contributor]).sort, model.related_people.sort
    assert_equal (presentation.creators | [presentation.contributor]).sort, presentation.related_people.sort
    assert_equal (publication.creators | [publication.contributor]).sort, publication.related_people.sort
  end

  test 'supports_doi?' do
    assert Model.supports_doi?
    assert DataFile.supports_doi?
    assert Sop.supports_doi?

    assert Investigation.supports_doi?
    assert Study.supports_doi?
    assert Assay.supports_doi?

    refute Presentation.supports_doi?
    refute Publication.supports_doi?

    assert FactoryBot.create(:model).supports_doi?
    assert FactoryBot.create(:data_file).supports_doi?
    refute FactoryBot.create(:presentation).supports_doi?
    refute FactoryBot.create(:publication).supports_doi?
  end

  test 'can_mint_doi?' do
    df = FactoryBot.create(:data_file, policy: FactoryBot.create(:public_policy))
    assert df.can_manage?
    assert !df.find_version(1).has_doi?
    assert df.find_version(1).can_mint_doi?

    with_config_value(:doi_minting_enabled, false) do
      assert !df.find_version(1).can_mint_doi?
    end

    df.policy = FactoryBot.create(:public_policy)
    df.find_version(1).update_column(:doi, 'test_doi')
    assert !df.find_version(1).can_mint_doi?
  end

  test 'has_doi?' do
    df = FactoryBot.create :data_file
    assert !df.find_version(1).has_doi?
    assert !df.has_doi?
    df.find_version(1).update_column(:doi, 'test_doi')
    assert df.find_version(1).has_doi?
    assert df.has_doi?
  end

  test 'is_doi_time_locked?' do
    df = FactoryBot.create(:data_file)
    dfv = df.latest_version
    with_config_value :time_lock_doi_for, 7 do
      assert dfv.doi_time_locked?
    end
    with_config_value :time_lock_doi_for, nil do
      refute dfv.doi_time_locked?
    end

    dfv.created_at = 8.days.ago
    disable_authorization_checks { dfv.save }
    with_config_value :time_lock_doi_for, 7 do
      refute dfv.doi_time_locked?
    end

    with_config_value :time_lock_doi_for, '7' do
      refute dfv.doi_time_locked?
    end

    with_config_value :time_lock_doi_for, nil do
      refute dfv.doi_time_locked?
    end
  end

  test 'has_doi??' do
    df = FactoryBot.create :data_file
    new_version = FactoryBot.create :data_file_version, data_file: df
    assert_equal 2, df.version
    assert !df.has_doi?

    new_version.doi = 'test_doi'
    disable_authorization_checks { new_version.save }
    assert df.reload.has_doi?
  end

  test 'should not be able to delete after doi' do
    User.current_user = FactoryBot.create(:user)
    df = FactoryBot.create :data_file, contributor: User.current_user.person
    assert df.can_delete?

    df.doi = 'test.doi'
    new_version = FactoryBot.create :data_file_version, data_file: df
    new_version.doi = 'test.doi'
    df.save!
    new_version.save!
    df.reload
    refute df.can_delete?
  end

  test 'generated doi' do
    df = FactoryBot.create :data_file
    model = FactoryBot.create :model
    with_config_value :doi_prefix, 'xxx' do
      with_config_value :doi_suffix, 'yyy' do
        assert_equal "xxx/yyy.datafile.#{df.id}.1", df.find_version(1).suggested_doi
        assert_equal "xxx/yyy.model.#{model.id}.1", model.find_version(1).suggested_doi
      end
    end
  end

  test 'doi indentifier' do
    df = FactoryBot.create :data_file
    assert_nil df.latest_version.doi_identifier
    disable_authorization_checks do
      df.latest_version.update_attribute(:doi,'10.x.x.x/1')
    end
    assert_equal 'https://doi.org/10.x.x.x/1',df.latest_version.doi_identifier
  end

  test 'doi identifiers' do
    df = FactoryBot.create :data_file
    assert_empty df.doi_identifiers

    disable_authorization_checks do
      df.latest_version.update_attribute(:doi,'10.x.x.x/1')
      df.save_as_new_version
      df.save_as_new_version
      df.reload
      df.latest_version.update_attribute(:doi,'10.x.x.x/2')
    end

    assert_equal 3,df.versions.count

    assert_equal ['https://doi.org/10.x.x.x/1','https://doi.org/10.x.x.x/2'].sort,df.doi_identifiers

    #just check others respond to method
    assert FactoryBot.create(:model).respond_to?(:doi_identifiers)
    assert FactoryBot.create(:sop).respond_to?(:doi_identifiers)
  end

  test 'has deleted contributor?' do
    assets = [:data_file,:sop, :model, :presentation,:document, :event, :data_file_version,:sop_version, :model_version, :presentation_version,:document_version]
    assets.each do |asset_type|
      item = FactoryBot.create(asset_type,deleted_contributor:'Person:99')
      item.update_column(:contributor_id,nil)
      item2 = FactoryBot.create(asset_type)
      item2.update_column(:contributor_id,nil)

      assert_nil item.contributor
      assert_nil item2.contributor
      refute_nil item.deleted_contributor
      assert_nil item2.deleted_contributor

      assert item.has_deleted_contributor?
      refute item2.has_deleted_contributor?
    end

  end

  test 'has jerm contributor?' do
    assets = [:data_file,:sop, :model, :presentation, :event, :data_file_version,:sop_version, :model_version, :presentation_version,:document_version]
    assets.each do |asset_type|
      item = FactoryBot.create(asset_type,deleted_contributor:'Person:99')
      item.update_column(:contributor_id,nil)
      item2 = FactoryBot.create(asset_type)
      item2.update_column(:contributor_id,nil)

      assert_nil item.contributor
      assert_nil item2.contributor
      refute_nil item.deleted_contributor
      assert_nil item2.deleted_contributor

      refute item.has_jerm_contributor?
      assert item2.has_jerm_contributor?
    end
  end

  test 'validate title lengths' do
    long_title = ('a' * 256).freeze
    ok_title = ('a' * 255).freeze
    assert long_title.length > 255
    assert_equal 255, ok_title.length
    assets = %i[data_file sop model presentation document event assay investigation study]
    User.with_current_user(FactoryBot.create(:user)) do
      assets.each do |asset_key|
        item = FactoryBot.create(asset_key, contributor:User.current_user.person)
        assert item.valid?, "#{asset_key} should be valid"
        item.title = long_title
        refute item.valid?, "#{asset_key} should be not be valid with too long title length"
        item.title=ok_title
        assert item.valid?, "#{asset_key} should be valid with max title length"
        item.save!
      end
    end
  end

  test 'validate description lengths' do
    long_desc = ('a' * 65536).freeze
    ok_desc = ('a' * 65535).freeze
    assert long_desc.length > 65535
    assert_equal 65535, ok_desc.length
    assets = %i[data_file sop model presentation document event assay investigation study]
    User.with_current_user(FactoryBot.create(:user)) do
      assets.each do |asset_key|
        item = FactoryBot.create(asset_key, contributor:User.current_user.person)
        assert item.valid?, "#{asset_key} should be valid"
        item.description = long_desc
        refute item.valid?, "#{asset_key} should be not be valid with too long description length"
        item.description=ok_desc
        assert item.valid?, "#{asset_key} should be valid with max description length"
        item.save!
      end
    end
  end

  test 'projects_accessible?' do
    project1 = FactoryBot.create(:project)
    project2 = FactoryBot.create(:project)

    df = FactoryBot.create(:data_file, policy:FactoryBot.create(:public_policy))
    assert df.projects_accessible?(project1)

    assay = FactoryBot.create(:assay, policy:FactoryBot.create(:public_policy))
    assert assay.projects_accessible?(project1)

    df = FactoryBot.create(:data_file, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission, access_type:Policy::VISIBLE,contributor:project1)]))
    refute df.projects_accessible?(project1)

    assay = FactoryBot.create(:assay, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission, access_type:Policy::VISIBLE,contributor:project1)]))
    assert assay.projects_accessible?(project1)
    refute assay.projects_accessible?(project2)

    df = FactoryBot.create(:data_file, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission, access_type:Policy::ACCESSIBLE,contributor:project1)]))
    assert df.projects_accessible?(project1)
    refute df.projects_accessible?(project2)

    df = FactoryBot.create(:data_file, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission, access_type:Policy::EDITING,contributor:project1)]))
    assert df.projects_accessible?(project1)
    refute df.projects_accessible?(project2)

    df = FactoryBot.create(:data_file, policy:FactoryBot.create(:private_policy, permissions:[FactoryBot.create(:permission, access_type:Policy::MANAGING,contributor:project1)]))
    assert df.projects_accessible?(project1)
    refute df.projects_accessible?(project2)
    refute df.projects_accessible?([project1,project2])

    df.policy.permissions.create(contributor:project2, access_type:Policy::ACCESSIBLE)
    assert df.projects_accessible?(project2)
    assert df.projects_accessible?([project1,project2])
    refute df.projects_accessible?([project1,project2, FactoryBot.create(:project)])
  end

  test 'update_timestamps with new version' do
    contributor = FactoryBot.create(:person)
    User.with_current_user(contributor.user) do
      df = FactoryBot.create(:data_file, contributor:contributor)
      t = DateTime.now + 5.days
      travel_to(t) do
        df.save_as_new_version
        assert_equal 2,df.version
        version = df.latest_version
        assert_in_delta t,DateTime.parse(version.updated_at.to_s),0.1.second
        assert_in_delta t,DateTime.parse(df.updated_at.to_s),0.1.second
      end
    end

  end

  test 'filter by project unique' do
    projects = [FactoryBot.create(:project),FactoryBot.create(:project)]
    investigation = FactoryBot.create(:investigation,projects:projects)
    other_investigation = FactoryBot.create(:investigation)

    assert_equal [investigation],Investigation.filter_by_projects(projects)

    #check it's an relation and not just turned into an array
    assert ActiveRecord::Relation,Investigation.filter_by_projects(projects).is_a?(ActiveRecord::Relation)
  end

  test 'cache key includes version' do
    df = FactoryBot.create(:data_file)

    # check it hasn't be overridden
    assert_nil df.method(:cache_key).super_method

    assert_equal df.cache_key_with_version, df.cache_key
    refute ActiveRecord::Base.cache_versioning
  end

  test 'last updated by' do
    assets = %i[data_file sop model presentation document event assay investigation study]
    assets.each do |asset_key|
      person1 = FactoryBot.create(:person)
      person2 = FactoryBot.create(:person)
      User.with_current_user(person1.user) do
        asset = FactoryBot.create(asset_key, contributor: person1)
        FactoryBot.create :activity_log, activity_loggable: asset, action: 'create', created_at: 15.minute.ago, culprit: person1
        assert_nil asset.updated_last_by
        FactoryBot.create :activity_log, activity_loggable: asset, action: 'update', created_at: 10.minute.ago, culprit: person1
        assert_equal person1, asset.updated_last_by
        FactoryBot.create :activity_log, activity_loggable: asset, action: 'update', created_at: 5.minute.ago, culprit: person1.user
        assert_equal person1, asset.updated_last_by
        FactoryBot.create :activity_log, activity_loggable: asset, action: 'update', created_at: 1.minute.ago, culprit: person2
        assert_equal person2, asset.updated_last_by
        person2.delete
        assert_nil asset.updated_last_by
      end
    end
  end
end
