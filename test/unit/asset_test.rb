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

    User.current_user = Factory(:person_not_in_project).user
    refute DataFile.can_create?
    refute Model.can_create?
    refute Sop.can_create?
    refute Presentation.can_create?
    refute Publication.can_create?
    refute Investigation.can_create?
    refute Study.can_create?
    refute Assay.can_create?

    User.current_user = Factory(:person).user
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
    d = Factory(:xlsx_spreadsheet_datafile, policy: Factory(:public_policy))

    d.save_as_new_version
    Factory(:xlsx_content_blob, asset: d, asset_version: d.version)
    d.reload
    assert_equal 2, d.version
    assert_equal 2, d.versions.size
    assert !d.versions[0].latest_version?
    assert d.versions[1].latest_version?
  end

  test 'just used' do
    model = Factory :model
    t = 1.day.ago
    assert_not_equal t.to_i, model.last_used_at.to_i
    travel_to(t) do
      model.just_used
    end
    assert_equal t.to_i, model.last_used_at.to_i
  end

  test 'assay type titles' do
    df = Factory :data_file
    assay = Factory :experimental_assay
    assay2 = Factory :modelling_assay
    assay3 = Factory :modelling_assay, assay_type_uri: 'http://jermontology.org/ontology/JERMOntology#Cell_cycle'

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
    m = Factory :model
    assert_equal [], m.assay_type_titles
  end

  test 'contains_downloadable_items?' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage.com', 'Content-Type' => 'text/html'
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html", 'http://webpage2.com', 'Content-Type' => 'text/html'

    df = Factory :data_file
    assert df.contains_downloadable_items?
    assert df.latest_version.contains_downloadable_items?

    df = Factory :data_file, content_blob: Factory(:content_blob, url: 'http://webpage.com', external_link: true)
    assert !df.contains_downloadable_items?
    assert !df.latest_version.contains_downloadable_items?

    Factory.define(:model_with_urls, parent: :model) do |f|
      f.after_create do |model|
        model.content_blobs = [
          Factory.create(:content_blob, url: 'http://webpage.com', asset: model, asset_version: model.version, external_link: true),
          Factory.create(:content_blob, url: 'http://webpage2.com', asset: model, asset_version: model.version, external_link: true)
        ]
      end
    end

    model = Factory :model_with_urls
    assert !model.contains_downloadable_items?
    assert !model.latest_version.contains_downloadable_items?

    model = Factory :teusink_model
    assert model.contains_downloadable_items?
    assert model.latest_version.contains_downloadable_items?

    Factory.define(:model_with_urls_and_files, parent: :model) do |f|
      f.after_create do |model|
        model.content_blobs = [
          Factory.create(:content_blob, url: 'http://webpage.com', asset: model, asset_version: model.version, external_link: true),
          Factory.create(:cronwright_model_content_blob, asset: model, asset_version: model.version)
        ]
      end
    end

    model = Factory :model_with_urls_and_files
    assert model.contains_downloadable_items?
    assert model.latest_version.contains_downloadable_items?

    df = DataFile.new
    assert !df.contains_downloadable_items?

    model = Model.new
    assert !model.contains_downloadable_items?

    # test for versions
    model = Factory :teusink_model

    disable_authorization_checks do
      model.save_as_new_version
      model.reload
      model.content_blobs = [Factory.create(:content_blob, url: 'http://webpage.com', asset: model, asset_version: model.version, external_link: true)]
      model.save!
      model.reload
    end

    assert_equal(2, model.versions.count)
    assert model.find_version(1).contains_downloadable_items?
    assert !model.find_version(2).contains_downloadable_items?
  end

  test 'tech type titles' do
    df = Factory :data_file
    assay = Factory :experimental_assay, technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Binding'
    assay2 = Factory :experimental_assay, technology_type_uri: 'http://jermontology.org/ontology/JERMOntology#Imaging'
    assay3 = Factory :modelling_assay

    disable_authorization_checks do
      assay.associate(df)
      assay2.associate(df)
      assay3.associate(df)
      assay.reload
      assay2.reload
      df.reload
    end

    assert_equal %w(Binding Imaging), df.technology_type_titles.sort
    m = Factory :model
    assert_equal [], m.technology_type_titles
  end

  test 'managers' do
    person = Factory(:person)
    person2 = Factory(:person, first_name: 'fred', last_name: 'bloggs')
    user = Factory(:user)
    sop = Factory(:sop, contributor: person)
    assert_equal 1, sop.managers.count
    assert sop.managers.include?(person)

    df = Factory(:data_file, contributor: user.person)
    assert_equal 1, df.managers.count
    assert df.managers.include?(user.person)

    policy = Factory(:private_policy)
    policy.permissions << Factory(:permission, contributor: user.person, access_type: Policy::MANAGING, policy: policy)
    policy.permissions << Factory(:permission, contributor: person, access_type: Policy::EDITING, policy: policy)
    assay = Factory(:assay, policy: policy, contributor: person2)
    assert_equal 2, assay.managers.count
    assert assay.managers.include?(user.person)
    assert assay.managers.include?(person2)
  end

  test 'tags as text array' do
    model = Factory :model
    u = Factory :user
    Factory :tag, annotatable: model, source: u, value: 'aaa'
    Factory :tag, annotatable: model, source: u, value: 'bbb'
    Factory :tag, annotatable: model, source: u, value: 'ddd'
    Factory :tag, annotatable: model, source: u, value: 'ccc'
    assert_equal %w(aaa bbb ccc ddd), model.annotations_as_text_array.sort

    p = Factory :person
    Factory :expertise, annotatable: p, source: u, value: 'java'
    Factory :tool, annotatable: p, source: u, value: 'trowel'
    assert_equal %w(java trowel), p.annotations_as_text_array.sort
  end

  test 'related people' do
    df = Factory :data_file
    sop = Factory :sop
    model = Factory :model
    presentation = Factory :presentation
    publication = Factory :publication
    df.creators = [Factory(:person), Factory(:person)]
    sop.creators = [Factory(:person), Factory(:person)]
    model.creators = [Factory(:person), Factory(:person)]
    presentation.creators = [Factory(:person), Factory(:person)]
    publication.creators = [Factory(:person), Factory(:person)]

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

    assert Factory(:model).supports_doi?
    assert Factory(:data_file).supports_doi?
    refute Factory(:presentation).supports_doi?
    refute Factory(:publication).supports_doi?
  end

  test 'can_mint_doi?' do
    df = Factory(:data_file, policy: Factory(:public_policy))
    assert df.can_manage?
    assert !df.find_version(1).has_doi?
    assert df.find_version(1).can_mint_doi?

    with_config_value(:doi_minting_enabled, false) do
      assert !df.find_version(1).can_mint_doi?
    end

    df.policy = Factory(:public_policy)
    df.doi = 'test_doi'
    disable_authorization_checks { df.save }
    assert !df.find_version(1).can_mint_doi?
  end

  test 'has_doi?' do
    df = Factory :data_file
    assert !df.find_version(1).has_doi?
    assert !df.has_doi?
    df.doi = 'test_doi'
    disable_authorization_checks { df.save }
    assert df.find_version(1).has_doi?
    assert df.has_doi?
  end

  test 'is_doi_time_locked?' do
    df = Factory(:data_file)
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
    df = Factory :data_file
    new_version = Factory :data_file_version, data_file: df
    assert_equal 2, df.version
    assert !df.has_doi?

    new_version.doi = 'test_doi'
    disable_authorization_checks { new_version.save }
    assert df.reload.has_doi?
  end

  test 'should not be able to delete after doi' do
    User.current_user = Factory(:user)
    df = Factory :data_file, contributor: User.current_user.person
    assert df.can_delete?

    df.doi = 'test.doi'
    new_version = Factory :data_file_version, data_file: df
    new_version.doi = 'test.doi'
    df.save!
    new_version.save!
    df.reload
    refute df.can_delete?
  end

  test 'generated doi' do
    df = Factory :data_file
    model = Factory :model
    with_config_value :doi_prefix, 'xxx' do
      with_config_value :doi_suffix, 'yyy' do
        assert_equal "xxx/yyy.datafile.#{df.id}.1", df.find_version(1).suggested_doi
        assert_equal "xxx/yyy.model.#{model.id}.1", model.find_version(1).suggested_doi
      end
    end
  end

  test 'doi indentifier' do
    df = Factory :data_file
    assert_nil df.latest_version.doi_identifier
    disable_authorization_checks do
      df.latest_version.update_attribute(:doi,'10.x.x.x/1')
    end
    assert_equal 'https://doi.org/10.x.x.x/1',df.latest_version.doi_identifier
  end

  test 'doi identifiers' do
    df = Factory :data_file
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
    assert Factory(:model).respond_to?(:doi_identifiers)
    assert Factory(:sop).respond_to?(:doi_identifiers)
  end

  test 'has deleted contributor?' do
    assets = [:data_file,:sop, :model, :presentation,:document, :event, :data_file_version,:sop_version, :model_version, :presentation_version,:document_version]
    assets.each do |asset_type|
      item = Factory(asset_type,deleted_contributor:'Person:99')
      item.update_column(:contributor_id,nil)
      item2 = Factory(asset_type)
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
      item = Factory(asset_type,deleted_contributor:'Person:99')
      item.update_column(:contributor_id,nil)
      item2 = Factory(asset_type)
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
    User.with_current_user(Factory(:user)) do
      assets.each do |asset_key|
        item = Factory(asset_key, contributor:User.current_user.person)
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
    User.with_current_user(Factory(:user)) do
      assets.each do |asset_key|
        item = Factory(asset_key, contributor:User.current_user.person)
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
    project1 = Factory(:project)
    project2 = Factory(:project)

    df = Factory(:data_file, policy:Factory(:public_policy))
    assert df.projects_accessible?(project1)

    assay = Factory(:assay, policy:Factory(:public_policy))
    assert assay.projects_accessible?(project1)

    df = Factory(:data_file, policy:Factory(:private_policy, permissions:[Factory(:permission, access_type:Policy::VISIBLE,contributor:project1)]))
    refute df.projects_accessible?(project1)

    assay = Factory(:assay, policy:Factory(:private_policy, permissions:[Factory(:permission, access_type:Policy::VISIBLE,contributor:project1)]))
    assert assay.projects_accessible?(project1)
    refute assay.projects_accessible?(project2)

    df = Factory(:data_file, policy:Factory(:private_policy, permissions:[Factory(:permission, access_type:Policy::ACCESSIBLE,contributor:project1)]))
    assert df.projects_accessible?(project1)
    refute df.projects_accessible?(project2)

    df = Factory(:data_file, policy:Factory(:private_policy, permissions:[Factory(:permission, access_type:Policy::EDITING,contributor:project1)]))
    assert df.projects_accessible?(project1)
    refute df.projects_accessible?(project2)

    df = Factory(:data_file, policy:Factory(:private_policy, permissions:[Factory(:permission, access_type:Policy::MANAGING,contributor:project1)]))
    assert df.projects_accessible?(project1)
    refute df.projects_accessible?(project2)
    refute df.projects_accessible?([project1,project2])

    df.policy.permissions.create(contributor:project2, access_type:Policy::ACCESSIBLE)
    assert df.projects_accessible?(project2)
    assert df.projects_accessible?([project1,project2])
    refute refute df.projects_accessible?([project1,project2, Factory(:project)])
  end

  test 'update_timestamps with new version' do
    contributor = Factory(:person)
    User.with_current_user(contributor.user) do
      df = Factory(:data_file, contributor:contributor)
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

end
