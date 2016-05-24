require 'test_helper'


class ModelTest < ActiveSupport::TestCase
  fixtures :all    

  test "assocations" do
    model=models(:teusink)
    jws_env=recommended_model_environments(:jws)

    assert_equal jws_env,model.recommended_environment

    assert_equal "Teusink",model.title

    blob=content_blobs(:teusink_blob)
    assert_equal 1,model.content_blobs.size
    assert_equal blob,model.content_blobs.first
  end

  test "model contents for search" do
    model = Factory :teusink_model
    contents = model.model_contents_for_search

    assert contents.include?("KmPYKPEP")
    assert contents.include?("F16P")
  end

  test "model file format forces SBML format" do
    model = Factory(:teusink_model,:model_format=>nil)
    assert model.contains_sbml?
    assert_equal ModelFormat.sbml.first,model.model_format
    other_format = Factory(:model_format)
    model = Factory(:teusink_model,:model_format=>other_format)
    refute_nil model.model_format
    assert_equal other_format,model.model_format

    model = Factory(:teusink_jws_model,:model_format=>nil)
    assert_nil model.model_format

  end

  test "to_rdf" do
    User.with_current_user Factory(:user) do
      object = Factory :model, :assay_ids=>[Factory(:assay).id], :policy=>Factory(:public_policy)
      assert object.contains_sbml?
      pub = Factory :publication
      Factory :relationship,:subject=>object,:predicate=>Relationship::RELATED_TO_PUBLICATION,:other_object=>pub
      object.reload
      rdf = object.to_rdf
      RDF::Reader.for(:rdfxml).new(rdf) do |reader|
        assert reader.statements.count > 1
        assert_equal RDF::URI.new("http://localhost:3000/models/#{object.id}"), reader.statements.first.subject
      end
    end
  end

  test "content blob search terms" do
    check_for_soffice
    m = Factory :teusink_model
    m.content_blobs << Factory.create(:doc_content_blob,:original_filename=>"word.doc",:asset=>m,:asset_version=>m.version)
    m.reload

    assert_equal ["This is a ms word doc format", "doc","teusink.xml", "word.doc","xml"],m.content_blob_search_terms.sort
  end

  test "type detection" do
    model = Factory :teusink_model
    assert model.contains_sbml?
    assert model.is_jws_supported?
    assert !model.contains_jws_dat?

    model = Factory :teusink_jws_model
    assert !model.contains_sbml?
    assert model.is_jws_supported?
    assert model.contains_jws_dat?

    model = Factory :non_sbml_xml_model
    assert !model.contains_sbml?
    assert !model.is_jws_supported?
    assert !model.contains_jws_dat?

    #should also be able to handle versions
    model = models(:teusink).latest_version
    assert model.contains_sbml?
    assert model.is_jws_supported?
    assert !model.contains_jws_dat?

    model = Factory(:teusink_jws_model).latest_version
    assert !model.contains_sbml?
    assert model.is_jws_supported?
    assert model.contains_jws_dat?

    model = Factory(:teusink_model).latest_version
    assert model.contains_sbml?
    assert model.is_jws_supported?
    assert !model.contains_jws_dat?

    model = Factory(:non_sbml_xml_model).latest_version
    assert !model.contains_sbml?
    assert !model.is_jws_supported?
    assert !model.contains_jws_dat?
  end

  test "assay association" do
    model = models(:teusink)
    assay = assays(:modelling_assay_with_data_and_relationship)
    assay_asset = assay_assets(:metabolomics_assay_asset1)
    assert_not_equal assay_asset.asset, model
    assert_not_equal assay_asset.assay, assay
    assay_asset.asset = model
    assay_asset.assay = assay
    User.with_current_user(model.contributor){assay_asset.save!}
    assay_asset.reload
    assert assay_asset.valid?
    assert_equal assay_asset.asset, model
    assert_equal assay_asset.assay, assay

  end

  test "sort by updated_at" do
    assert_equal Model.all.sort_by { |m| m.updated_at.to_i * -1 }, Model.all
  end

  test "validation" do
    asset=Model.new :title=>"fred",:projects=>[projects(:sysmo_project)], :policy => Factory(:private_policy)
    assert asset.valid?

    asset=Model.new :projects=>[projects(:sysmo_project)], :policy => Factory(:private_policy)
    assert !asset.valid?

    #VL only: allow no projects
    asset=Model.new :title=>"fred", :policy => Factory(:private_policy)
    assert asset.valid?
  end

  test "is asset?" do
    assert Model.is_asset?
    assert models(:teusink).is_asset?
    
    assert model_versions(:teusink_v1).is_asset?
  end

  test "avatar_key" do
    assert_equal "model_avatar",models(:teusink).avatar_key
    assert_equal "model_avatar",model_versions(:teusink_v1).avatar_key
  end

  test "authorization supported?" do
    assert Model.authorization_supported?
    assert models(:teusink).authorization_supported?
    assert model_versions(:teusink_v1).authorization_supported?
  end
  
  test "projects" do
    model=models(:teusink)
    p=projects(:sysmo_project)
    assert_equal [p],model.projects
    assert_equal [p],model.latest_version.projects
  end

  test "cache_remote_content" do
    mock_remote_file "#{Rails.root}/test/fixtures/files/Teusink.xml","http://mockedlocation.com/teusink.xml"

    model = Factory.build :model
    model.content_blobs.build(:data=>nil,:url=>"http://mockedlocation.com/teusink.xml",
    :original_filename=>"teusink.xml")
    model.save!
    assert_equal 1,model.content_blobs.size
    assert !model.content_blobs.first.file_exists?

    model.cache_remote_content_blob

    assert model.content_blobs.first.file_exists?

  end

  def test_defaults_to_private_policy
    model=Model.new Factory.attributes_for(:model, :policy => nil)
    model.save!
    model.reload
    assert_not_nil model.policy
    assert_equal Policy::PRIVATE, model.policy.sharing_scope
    assert_equal Policy::NO_ACCESS, model.policy.access_type
    assert_equal false,model.policy.use_whitelist
    assert_equal false,model.policy.use_blacklist
    assert model.policy.permissions.empty?
  end
  
  def test_defaults_to_blank_policy_for_vln
    with_config_value "is_virtualliver",true do
      model=Model.new Factory.attributes_for(:model, :policy => nil)
      assert !model.valid?
      assert !model.policy.valid?
      assert_blank model.policy.sharing_scope
      assert_blank model.policy.access_type
      assert_equal false,model.policy.use_whitelist
      assert_equal false,model.policy.use_blacklist
      assert_blank model.policy.permissions
    end

  end

  test "creators through asset" do
    p1 = Factory(:person)
    p2 = Factory(:person)
    model=Factory(:teusink_model,:creators=>[p1,p2])
    assert_not_nil model.creators
    assert_equal 2,model.creators.size
    assert model.creators.include?(p1)
    assert model.creators.include?(p2)
    
  end
  
  test "titled trimmed" do
    model=Factory :model
    User.with_current_user model.contributor do
      model.title=" space"
      model.save!
      assert_equal "space",model.title
    end

  end

  test "model with no contributor" do
    model=models(:model_with_no_contributor)
    assert_nil model.contributor
  end

  test "versions destroyed as dependent" do
    model=models(:teusink)
    User.with_current_user model.contributor do
      assert_equal 2,model.versions.size,"There should be 2 versions of this Model"
      assert_difference("Model.count",-1) do
        assert_difference("Model::Version.count",-2) do
          model.destroy
        end
      end
    end

  end

  test "make sure content blob is preserved after deletion" do
    model = Factory :model
    User.with_current_user  model.contributor do
      assert_equal 1, model.content_blobs.size,"Must have an associated content blob for this test to work"
      assert_not_nil model.content_blobs.first,"Must have an associated content blob for this test to work"
      cb=model.content_blobs.first
      assert_difference("Model.count",-1) do
        assert_no_difference("ContentBlob.count") do
          model.destroy
        end
      end
      assert_not_nil ContentBlob.find(cb.id)
    end
  end

  test "is restorable after destroy" do
    model = Factory :model, :policy  => Factory(:all_sysmo_viewable_policy), :title => 'is it restorable?'
    User.with_current_user model.contributor do
      assert_difference("Model.count",-1) do
        model.destroy
      end
    end
    assert_nil Model.find_by_title 'is it restorable?'
    assert_difference("Model.count",1) do
      disable_authorization_checks {Model.restore_trash!(model.id)}
    end
    assert_not_nil Model.find_by_title 'is it restorable?'
  end


  test 'failing to delete due to can_delete still creates trash' do
    user = Factory :user
    contributor = Factory :person
    model = Factory :model, :policy => Factory(:private_policy),:contributor=>contributor
    User.with_current_user user do
      assert !model.can_delete?
      assert_no_difference("Model.count") do
        model.destroy
      end
    end

    assert_not_nil Model.restore_trash(model.id)
  end
  
  test "test uuid generated" do
    x = models(:teusink)
    assert_nil x.attributes["uuid"]
    x.save
    assert_not_nil x.attributes["uuid"]
  end

  test "uuid doesn't change" do
    x = models(:teusink)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
end
