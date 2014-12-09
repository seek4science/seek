require 'test_helper'
require 'time_test_helper'

class AssetTest < ActiveSupport::TestCase
  fixtures :all
  include ApplicationHelper

  test "default contributor or nil" do
    User.current_user = users(:owner_of_my_first_sop)
    model = Model.new(Factory.attributes_for(:model).tap{|h|h[:contributor] = nil; h[:policy] = Factory(:private_policy)})
    assert_equal users(:owner_of_my_first_sop),model.contributor
    model.contributor = nil
    model.save!
    assert_equal nil,model.contributor
    model = Model.find(model.id)
    assert_equal nil,model.contributor
  end

  test "latest version?" do
    d = Factory(:xlsx_spreadsheet_datafile, :policy => Factory(:public_policy))

    d.save_as_new_version
    Factory(:xlsx_content_blob, :asset => d, :asset_version => d.version)
    d.reload
    assert_equal 2,d.version
    assert_equal 2,d.versions.size
    assert !d.versions[0].latest_version?
    assert d.versions[1].latest_version?
  end

  test "just used" do
    model = Factory :model
    t = 1.day.ago
    assert_not_equal t.to_s,model.last_used_at.to_s
    pretend_now_is(t) do
      model.just_used
    end
    assert_equal t.to_s,model.last_used_at.to_s

  end

  test "assay type titles" do
    df = Factory :data_file
    assay = Factory :experimental_assay
    assay2 = Factory :modelling_assay
    assay3 = Factory :modelling_assay,:assay_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Cell_cycle"
    assay4 = Factory :modelling_assay,:assay_type_uri=>"http://some-made-up-uri-not-resolvable-from-ontology.org/types#to_force_nil_label"

    disable_authorization_checks do
      assay.relate(df)
      assay2.relate(df)
      assay.reload
      assay2.reload
      assay3.relate(df)
      assay3.reload
      assay4.relate(df)
      assay4.reload
      df.reload
    end

    assert_equal ["Cell cycle", "Experimental assay type", "Model analysis type"],df.assay_type_titles.sort
    m=Factory :model
    assert_equal [],m.assay_type_titles

  end

  test "contains_downloadable_items?" do

    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html","http://webpage.com",{'Content-Type' => 'text/html'}
    mock_remote_file "#{Rails.root}/test/fixtures/files/html_file.html","http://webpage2.com",{'Content-Type' => 'text/html'}

    df = Factory :data_file
    assert df.contains_downloadable_items?
    assert df.latest_version.contains_downloadable_items?

    df = Factory :data_file,:content_blob=>Factory(:content_blob,:url=>"http://webpage.com", :external_link => true)
    assert !df.contains_downloadable_items?
    assert !df.latest_version.contains_downloadable_items?

    Factory.define(:model_with_urls,:parent=>:model) do |f|
      f.after_create do |model|
        model.content_blobs = [
            Factory.create(:content_blob, :url=>"http://webpage.com", :asset => model,:asset_version=>model.version, :external_link => true),
            Factory.create(:content_blob, :url=>"http://webpage2.com", :asset => model,:asset_version=>model.version, :external_link => true)
        ]
      end
    end

    model = Factory :model_with_urls
    assert !model.contains_downloadable_items?
    assert !model.latest_version.contains_downloadable_items?

    model = Factory :teusink_model
    assert model.contains_downloadable_items?
    assert model.latest_version.contains_downloadable_items?

    Factory.define(:model_with_urls_and_files,:parent=>:model) do |f|
      f.after_create do |model|
        model.content_blobs = [
            Factory.create(:content_blob, :url=>"http://webpage.com", :asset => model,:asset_version=>model.version, :external_link => true),
            Factory.create(:cronwright_model_content_blob, :asset => model,:asset_version=>model.version)
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

    #test for versions
    model = Factory :teusink_model

    disable_authorization_checks do
      model.save_as_new_version
      model.reload
      model.content_blobs=[Factory.create(:content_blob, :url=>"http://webpage.com",:asset => model,:asset_version=>model.version,:external_link=>true)]
      model.save!
      model.reload
    end

    assert_equal(2,model.versions.count)
    assert model.find_version(1).contains_downloadable_items?
    assert !model.find_version(2).contains_downloadable_items?

  end

  test "tech type titles" do
    df = Factory :data_file
    assay = Factory :experimental_assay,:technology_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Binding"
    assay2 = Factory :experimental_assay,:technology_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Imaging"
    assay3 = Factory :modelling_assay


    disable_authorization_checks do
      assay.relate(df)
      assay2.relate(df)
      assay3.relate(df)
      assay.reload
      assay2.reload
      df.reload
    end

    assert_equal ["Binding","Imaging"],df.technology_type_titles.sort
    m=Factory :model
    assert_equal [],m.technology_type_titles

  end

  test "managers" do
    person=Factory(:person)
    person2=Factory(:person,:first_name=>"fred",:last_name=>"bloggs")
    user=Factory(:user)
    sop=Factory(:sop,:contributor=>person)
    assert_equal 1,sop.managers.count
    assert sop.managers.include?(person)

    df=Factory(:data_file,:contributor=>user)
    assert_equal 1,df.managers.count
    assert df.managers.include?(user.person)

    policy=Factory(:private_policy)
    policy.permissions << Factory(:permission, :contributor => user, :access_type => Policy::MANAGING, :policy => policy)
    policy.permissions << Factory(:permission, :contributor => person, :access_type => Policy::EDITING, :policy => policy)
    assay=Factory(:assay,:policy=>policy,:contributor=>person2)
    assert_equal 2,assay.managers.count
    assert assay.managers.include?(user.person)
    assert assay.managers.include?(person2)

    #this is liable to change when Project contributors are handled
    p1=Factory(:project)
    p2=Factory(:project)
    policy=Factory(:private_policy)
    policy.permissions << Factory(:permission, :contributor => p1, :access_type => Policy::MANAGING, :policy => policy)
    model=Factory(:model,:policy=>policy,:contributor=>p2)
    assert model.managers.empty?
  end

  test "tags as text array" do
    model = Factory :model
    u = Factory :user
    Factory :tag,:annotatable=>model,:source=>u,:value=>"aaa"
    Factory :tag,:annotatable=>model,:source=>u,:value=>"bbb"
    Factory :tag,:annotatable=>model,:source=>u,:value=>"ddd"
    Factory :tag,:annotatable=>model,:source=>u,:value=>"ccc"
    assert_equal ["aaa","bbb","ccc","ddd"],model.annotations_as_text_array.sort

    p = Factory :person
    Factory :expertise,:annotatable=>p,:source=>u,:value=>"java"
    Factory :tool,:annotatable=>p,:source=>u,:value=>"trowel"
    assert_equal ["java","trowel"],p.annotations_as_text_array.sort
  end

  test "related people" do
    df = Factory :data_file
    sop = Factory :sop
    model = Factory :model
    presentation = Factory :presentation
    publication = Factory :publication
    df.creators = [Factory(:person),Factory(:person)]
    sop.creators = [Factory(:person),Factory(:person)]
    model.creators = [Factory(:person),Factory(:person)]
    presentation.creators = [Factory(:person),Factory(:person)]
    publication.creators = [Factory(:person),Factory(:person)]

    assert_equal df.creators,df.related_people
    assert_equal sop.creators,sop.related_people
    assert_equal model.creators,model.related_people
    assert_equal presentation.creators,presentation.related_people
    assert_equal publication.creators,publication.related_people
  end

  test "supports_doi?" do
    assert Model.supports_doi?
    assert DataFile.supports_doi?
    assert Sop.supports_doi?
    assert Workflow.supports_doi?

    refute Assay.supports_doi?
    refute Presentation.supports_doi?

    assert Factory(:model).supports_doi?
    assert Factory(:data_file).supports_doi?
    refute Factory(:presentation).supports_doi?
  end

  test "is_doiable?" do
    df = Factory(:data_file, :policy => Factory(:public_policy))
    assert df.can_manage?
    assert !df.is_doi_minted?(1)
    assert df.is_doiable?(1)

    df.policy = Factory(:private_policy)
    disable_authorization_checks{ df.save }
    assert !df.is_doiable?(1)

    df.policy = Factory(:public_policy)
    df.doi = 'test_doi'
    disable_authorization_checks{ df.save }
    assert !df.is_doiable?(1)
  end

  test "is_doi_minted?" do
    df = Factory :data_file
    assert !df.is_doi_minted?(1)
    df.doi = 'test_doi'
    disable_authorization_checks{ df.save }
    assert df.is_doi_minted?(1)
  end

  test 'is_doi_time_locked?' do
    df = Factory :data_file
    with_config_value :time_lock_doi_for, 7 do
      assert df.is_doi_time_locked?
    end
    with_config_value :time_lock_doi_for, nil do
      refute df.is_doi_time_locked?
    end

    df.created_at = 8.days.ago
    disable_authorization_checks{ df.save}
    with_config_value :time_lock_doi_for, 7 do
      refute df.is_doi_time_locked?
    end

    with_config_value :time_lock_doi_for, "7" do
      refute df.is_doi_time_locked?
    end

    with_config_value :time_lock_doi_for, nil do
      refute df.is_doi_time_locked?
    end
  end

  test 'is_any_doi_minted?' do
    df = Factory :data_file
    new_version = Factory :data_file_version, :data_file => df
    assert_equal 2, df.version
    assert !df.is_any_doi_minted?

    new_version.doi = 'test_doi'
    disable_authorization_checks{ new_version.save }
    assert df.reload.is_any_doi_minted?
  end

  test "should not be able to delete after doi" do
    User.current_user = Factory(:user)
    df = Factory :data_file,:contributor=>User.current_user.person
    assert df.can_delete?

    df.doi="test.doi"
    new_version = Factory :data_file_version, :data_file => df
    new_version.doi="test.doi"
    df.save!
    new_version.save!
    df.reload
    refute df.can_delete?
  end

  test "generated doi" do
    df = Factory :data_file
    model = Factory :model
    with_config_value :doi_prefix,"xxx" do
      with_config_value :doi_suffix,"yyy" do
        assert_equal "xxx/yyy.datafile.#{df.id}",df.generated_doi
        assert_equal "xxx/yyy.datafile.#{df.id}.1",df.generated_doi(1)
        assert_equal "xxx/yyy.model.#{model.id}.1",model.generated_doi(1)
      end
    end
  end

end
