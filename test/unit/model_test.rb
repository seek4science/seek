require 'test_helper'

class ModelTest < ActiveSupport::TestCase
  fixtures :all

  test 'assocations' do
    model = models(:teusink)
    jws_env = recommended_model_environments(:jws)

    assert_equal jws_env, model.recommended_environment

    assert_equal 'Teusink', model.title

    blob = content_blobs(:teusink_blob)
    assert_equal 1, model.content_blobs.size
    assert_equal blob, model.content_blobs.first
  end

  test 'model contents for search' do
    model = FactoryBot.create :teusink_model
    contents = model.model_contents_for_search

    assert contents.include?('KmPYKPEP')
    assert contents.include?('F16P')
  end

  test 'model file format forces SBML format' do
    model = FactoryBot.create(:teusink_model, model_format: nil)
    assert model.contains_sbml?
    assert_equal ModelFormat.sbml.first, model.model_format
    other_format = FactoryBot.create(:model_format)
    model = FactoryBot.create(:teusink_model, model_format: other_format)
    refute_nil model.model_format
    assert_equal other_format, model.model_format

    model = FactoryBot.create(:teusink_jws_model, model_format: nil)
    assert_nil model.model_format
  end

  test 'to_rdf' do
    User.with_current_user FactoryBot.create(:user) do
      object = FactoryBot.create :model, assay_ids: [FactoryBot.create(:assay, contributor:User.current_user.person).id], policy: FactoryBot.create(:public_policy)
      assert object.contains_sbml?
      pub = FactoryBot.create :publication
      FactoryBot.create :relationship, subject: object, predicate: Relationship::RELATED_TO_PUBLICATION, other_object: pub
      object.reload
      rdf = object.to_rdf
      RDF::Reader.for(:rdfxml).new(rdf) do |reader|
        assert reader.statements.count > 1
        assert_equal RDF::URI.new("http://localhost:3000/models/#{object.id}"), reader.statements.first.subject
      end
    end
  end

  test 'content blob search terms' do
    m = FactoryBot.create :teusink_model
    m.content_blobs << FactoryBot.create(:doc_content_blob, original_filename: 'word.doc', asset: m, asset_version: m.version)
    m.reload

    terms = m.content_blob_search_terms
    assert_includes terms, 'This is a ms word doc format'
    assert_includes terms, 'doc'
    assert_includes terms, 'teusink.xml'
    assert_includes terms, 'word.doc'
    assert_includes terms, 'xml'
  end

  test 'type detection' do
    model = FactoryBot.create :teusink_model
    assert model.contains_sbml?
    assert model.is_jws_supported?
    assert !model.contains_jws_dat?

    model = FactoryBot.create :teusink_jws_model
    assert !model.contains_sbml?
    assert model.is_jws_supported?
    assert model.contains_jws_dat?

    model = FactoryBot.create :non_sbml_xml_model
    assert !model.contains_sbml?
    assert !model.is_jws_supported?
    assert !model.contains_jws_dat?

    model = FactoryBot.create(:teusink_jws_model).latest_version
    assert !model.contains_sbml?
    assert model.is_jws_supported?
    assert model.contains_jws_dat?

    model = FactoryBot.create(:teusink_model).latest_version
    assert model.contains_sbml?
    assert model.is_jws_supported?
    assert !model.contains_jws_dat?

    model = FactoryBot.create(:non_sbml_xml_model).latest_version
    assert !model.contains_sbml?
    assert !model.is_jws_supported?
    assert !model.contains_jws_dat?

    # should also be able to handle new versions
    model = FactoryBot.create(:non_sbml_xml_model)
    assert !model.contains_sbml?
    assert !model.is_jws_supported?

    disable_authorization_checks {
      assert model.save_as_new_version
      model.content_blobs = [FactoryBot.create(:teusink_model_content_blob, asset: model, asset_version: model.version)]
      model.save
    }
    model.reload
    assert_equal 2,model.version
    assert model.contains_sbml?
    assert model.is_jws_supported?
    assert !model.contains_jws_dat?

  end

  test 'assay association' do
    person = FactoryBot.create(:person)
    User.with_current_user(person.user) do
      model = FactoryBot.create(:model, contributor:person)
      assay = FactoryBot.create(:assay, contributor:person)
      assay_asset = AssayAsset.new
      assert_not_equal assay_asset.asset, model
      assert_not_equal assay_asset.assay, assay
      assay_asset.asset = model
      assay_asset.assay = assay
      assay_asset.save!
      assay_asset.reload
      assert assay_asset.valid?
      assert_equal assay_asset.asset, model
      assert_equal assay_asset.assay, assay
    end

  end

  test 'validation' do
    asset = Model.new title: 'fred', projects: [projects(:sysmo_project)], policy: FactoryBot.create(:private_policy)
    assert asset.valid?

    asset = Model.new projects: [projects(:sysmo_project)], policy: FactoryBot.create(:private_policy)
    assert !asset.valid?

  end

  test 'is asset?' do
    assert Model.is_asset?
    assert models(:teusink).is_asset?

    assert model_versions(:teusink_v1).is_asset?
  end

  test 'avatar_key' do
    assert_equal 'model_avatar', models(:teusink).avatar_key
    assert_equal 'model_avatar', model_versions(:teusink_v1).avatar_key
  end

  test 'authorization supported?' do
    assert Model.authorization_supported?
    assert models(:teusink).authorization_supported?
    assert model_versions(:teusink_v1).authorization_supported?
  end

  test 'projects' do
    model = models(:teusink)
    p = projects(:sysmo_project)
    assert_equal [p], model.projects
    assert_equal [p], model.latest_version.projects
  end

  test 'cache_remote_content' do
    mock_remote_file "#{Rails.root}/test/fixtures/files/Teusink.xml", 'http://mockedlocation.com/teusink.xml'

    model = FactoryBot.build :model
    model.content_blobs.build(data: nil, url: 'http://mockedlocation.com/teusink.xml',
                              original_filename: 'teusink.xml')
    model.save!
    assert_equal 1, model.content_blobs.size
    assert !model.content_blobs.first.file_exists?

    model.cache_remote_content_blob

    assert model.content_blobs.first.file_exists?
  end

  test 'policy defaults to system default' do
    with_config_value 'default_all_visitors_access_type', Policy::NO_ACCESS do
      model = FactoryBot.build(:model)
      refute model.persisted?
      model.save!
      model.reload
      assert_not_nil model.policy
      assert_equal Policy::NO_ACCESS, model.policy.access_type
      assert model.policy.permissions.empty?
    end
  end

  test 'creators through asset' do
    p1 = FactoryBot.create(:person)
    p2 = FactoryBot.create(:person)
    model = FactoryBot.create(:teusink_model, creators: [p1, p2])
    assert_not_nil model.creators
    assert_equal 2, model.creators.size
    assert model.creators.include?(p1)
    assert model.creators.include?(p2)
  end

  test 'titled trimmed' do
    model = FactoryBot.create :model
    User.with_current_user model.contributor do
      model.title = ' space'
      model.save!
      assert_equal 'space', model.title
    end
  end

  test 'model with no contributor' do
    model = models(:model_with_no_contributor)
    assert_nil model.contributor
  end

  test 'versions destroyed as dependent' do
    model = models(:teusink)
    User.with_current_user model.contributor.user do
      assert_equal 2, model.versions.size, 'There should be 2 versions of this Model'
      assert_difference('Model.count', -1) do
        assert_difference('Model::Version.count', -2) do
          model.destroy
        end
      end
    end
  end

  test 'make sure content blob is preserved after deletion' do
    model = FactoryBot.create :model
    User.with_current_user model.contributor do
      assert_equal 1, model.content_blobs.size, 'Must have an associated content blob for this test to work'
      assert_not_nil model.content_blobs.first, 'Must have an associated content blob for this test to work'
      cb = model.content_blobs.first
      assert_difference('Model.count', -1) do
        assert_no_difference('ContentBlob.count') do
          model.destroy
        end
      end
      assert_not_nil ContentBlob.find(cb.id)
    end
  end

  test 'test uuid generated' do
    x = models(:teusink)
    assert_nil x.attributes['uuid']
    x.save
    assert_not_nil x.attributes['uuid']
  end

  test "uuid doesn't change" do
    x = models(:teusink)
    x.save
    uuid = x.attributes['uuid']
    x.save
    assert_equal x.uuid, uuid
  end
end
