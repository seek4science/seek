require 'test_helper'

class DataFileTest < ActiveSupport::TestCase

  fixtures :all

  test "associations" do
    datafile_owner = Factory :user
    datafile=Factory :data_file,:policy => Factory(:all_sysmo_viewable_policy),:contributor=> datafile_owner
    assert_equal datafile_owner,datafile.contributor
    unless datafile.content_blob.nil?
      datafile.content_blob.destroy
    end

    blob=Factory.create(:content_blob,:original_filename=>"df.ppt", :content_type=>"application/ppt",:asset => datafile,:asset_version=>datafile.version)#content_blobs(:picture_blob)
    datafile.reload
    assert_equal blob,datafile.content_blob
  end

  test "content blob search terms" do
    check_for_soffice
    df = Factory :data_file, :content_blob=>Factory(:doc_content_blob,:original_filename=>"word.doc")
    assert_equal ["This is a ms word doc format","word.doc"],df.content_blob_search_terms.sort

    df = Factory :xlsx_spreadsheet_datafile
    assert_includes df.content_blob_search_terms,"mild stress"
  end

  # test "spreadsheet contents for search" do
  #   df = Factory :rightfield_datafile
  #
  #   data = df.spreadsheet_contents_for_search
  #   assert !data.empty?,"Content should not be empty"
  #   assert data.include?("design type")
  #   assert data.include?("methodological design"), "content should be humanized"
  #   assert data.include?("MethodologicalDesign"),"should also preserve original form before humanizing"
  #   assert data.include?("absolute")
  #   assert !data.include?("ontology"),"Shouldn't include content from hidden sheets"
  #   assert !data.include?("relative"),"Shouldn't include content from hidden sheets"
  #
  #   assert !data.include?("44.0"),"Should not include numbers"
  #   assert !data.include?("1.0"),"Should not include numbers"
  #   assert !data.include?("1.7"),"Should not include numbers"
  #
  #   assert !data.include?(44),"Should not include numbers"
  #   assert !data.include?(1),"Should not include numbers"
  #   assert !data.include?(1.7),"Should not include numbers"
  #
  #   assert !data.include?("seek id"),"Should not include blacklisted text"
  #
  #   df = data_files(:picture)
  #   assert_equal [],df.spreadsheet_contents_for_search
  # end


  test "event association" do
    User.with_current_user Factory(:user) do
      datafile = Factory :data_file, :contributor => User.current_user
      event = Factory :event, :contributor => User.current_user
      datafile.events << event
      assert datafile.valid?
      assert datafile.save
      assert_equal 1, datafile.events.count
    end
  end

  test "assay association" do
    User.with_current_user Factory(:user) do
      datafile = Factory :data_file,:policy => Factory(:all_sysmo_viewable_policy)
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

  test "sort by updated_at" do
    assert_equal DataFile.find(:all).sort_by { |df| df.updated_at.to_i * -1 }, DataFile.find(:all)
  end

  test "validation" do
    asset=DataFile.new :title=>"fred",:projects=>[projects(:sysmo_project)], :policy => Factory(:private_policy)
    assert asset.valid?

    asset=DataFile.new :projects=>[projects(:sysmo_project)], :policy => Factory(:private_policy)
    assert !asset.valid?

    #VL only:allow no projects
    asset=DataFile.new :title=>"fred", :policy => Factory(:private_policy)
    assert asset.valid?


    asset = DataFile.new :title => "fred", :projects => [], :policy => Factory(:private_policy)
    assert asset.valid?
  end

  test "version created on save" do
    User.current_user = Factory(:user)
    df = DataFile.new(:title=>"testing versions",:projects=>[Factory(:project)],:policy => Factory(:private_policy))
    assert_equal true,  df.valid?
    df.save!
    df = DataFile.find(df.id)
    assert_equal 1, df.version

    assert_not_nil df.find_version(1)
    assert_equal df.find_version(1),df.latest_version
    assert_equal df.contributor,df.latest_version.contributor
  end

  def test_avatar_key

    assert_nil data_files(:picture).avatar_key
    assert data_files(:picture).use_mime_type_for_avatar?

    assert_nil data_file_versions(:picture_v1).avatar_key
    assert data_file_versions(:picture_v1).use_mime_type_for_avatar?
  end

  test "projects" do
    df=data_files(:sysmo_data_file)
    p=projects(:sysmo_project)
    assert_equal [p],df.projects
    assert_equal [p],df.latest_version.projects
  end

  def test_defaults_to_private_policy
    df_hash = Factory.attributes_for(:data_file)
    df_hash[:policy] = nil
    df=DataFile.new(df_hash)
    df.save!
    df.reload
    assert_not_nil df.policy
    assert_equal Policy::PRIVATE, df.policy.sharing_scope
    assert_equal Policy::NO_ACCESS, df.policy.access_type
    assert_equal false,df.policy.use_whitelist
    assert_equal false,df.policy.use_blacklist
    assert df.policy.permissions.empty?
  end

  def test_defaults_to_blank_policy_for_vln
    with_config_value "is_virtualliver",true do
      df_hash = Factory.attributes_for(:data_file)
      df_hash[:policy] = nil
      df=DataFile.new(df_hash)

      assert !df.valid?
      assert !df.policy.valid?
      assert_blank df.policy.sharing_scope
      assert_blank df.policy.access_type
      assert_equal false,df.policy.use_whitelist
      assert_equal false,df.policy.use_blacklist
      assert_blank df.policy.permissions
    end
  end

  test "data_file with no contributor" do
    df=data_files(:data_file_with_no_contributor)
    assert_nil df.contributor
  end

  test "versions destroyed as dependent" do
    df=data_files(:sysmo_data_file)
    User.current_user = df.contributor
    assert_equal 1,df.versions.size,"There should be 1 version of this DataFile"
    assert_difference(["DataFile.count","DataFile::Version.count"],-1) do
      df.destroy
    end
  end

  test "managers" do
    df= data_files(:picture)
    assert_not_nil df.managers
    contributor= people(:person_for_datafile_owner)
    manager=people(:person_for_owner_of_my_first_sop)
    assert df.managers.include?(contributor)
    assert df.managers.include?(manager)
    assert !df.managers.include?(people(:person_not_associated_with_any_projects))
  end

  test "make sure content blob is preserved after deletion" do
    df = Factory :data_file #data_files(:picture)
    User.current_user = df.contributor
    assert_not_nil df.content_blob,"Must have an associated content blob for this test to work"
    cb=df.content_blob
    assert_difference("DataFile.count",-1) do
      assert_no_difference("ContentBlob.count") do
        df.destroy
      end
    end
    assert_not_nil ContentBlob.find(cb.id)
  end

  test "is restorable after destroy" do
    df = Factory :data_file,:policy => Factory(:all_sysmo_viewable_policy), :title => 'is it restorable?'
    User.current_user = df.contributor
    assert_difference("DataFile.count",-1) do
      df.destroy
    end
    assert_nil DataFile.find_by_title 'is it restorable?'
    assert_difference("DataFile.count",1) do
      disable_authorization_checks {DataFile.restore_trash!(df.id)}
    end
    assert_not_nil DataFile.find_by_title 'is it restorable?'
  end

  test 'failing to delete (due to can_not_delete) still creates trash' do
    df = Factory :data_file, :policy => Factory(:private_policy), :contributor => Factory(:user)
    User.with_current_user Factory(:user) do
      assert_no_difference("DataFile.count") do
        df.destroy
      end
      assert_not_nil DataFile.restore_trash(df.id)
    end
  end

  test "test uuid generated" do
    x = data_files(:private_data_file)
    assert_nil x.attributes["uuid"]
    x.save
    assert_not_nil x.attributes["uuid"]
  end

  test "title_trimmed" do
    User.with_current_user Factory(:user) do
      df= Factory :data_file ,:policy=>Factory(:policy,:sharing_scope=>Policy::ALL_SYSMO_USERS,:access_type=>Policy::EDITING) #data_files(:picture)
      df.title=" should be trimmed"
      df.save!
      assert_equal "should be trimmed",df.title
    end
  end

  test "uuid doesn't change" do
    x = Factory :data_file,:policy => Factory(:all_sysmo_viewable_policy)#data_files(:picture)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end

  test "can get relationship type" do
    df = data_file_versions(:picture_v1)
    assay = assays(:modelling_assay_with_data_and_relationship)
    assert_equal relationship_types(:validation_data), df.relationship_type(assay)
  end

  test "delete checks authorization" do
    df = Factory :data_file

    User.current_user = nil
    assert !df.destroy

    User.current_user = df.contributor
    assert df.destroy
  end

  test 'update checks authorization' do
    unupdated_title = "Unupdated Title"
    df = Factory :data_file, :title => unupdated_title
    User.current_user = nil

    assert !df.update_attributes(:title => "Updated Title")
    assert_equal unupdated_title, df.reload.title
  end

  test "to rdf" do
    df=Factory :data_file, :assay_ids=>[Factory(:assay,:technology_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type").id,Factory(:assay).id]
    pub = Factory :publication
    Factory :relationship, :subject => df, :predicate => Relationship::RELATED_TO_PUBLICATION, :other_object => pub
    df.reload
    rdf = df.to_rdf
    assert_not_nil rdf
    #just checks it is valid rdf/xml and contains some statements for now
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 0
      assert_equal RDF::URI.new("http://localhost:3000/data_files/#{df.id}"), reader.statements.first.subject

    end
  end

  test "convert to presentation" do
      user = Factory :user
      attribution_df = Factory :data_file
      User.with_current_user(user) {
        data_file = Factory :data_file,:contributor=>user,:version=>2,
                            :assay_ids=>[Factory(:modelling_assay).id,Factory(:experimental_assay).id]
        Factory :content_blob,:asset=>data_file
        Factory :attribution,:subject=>data_file,:other_object=>attribution_df
        Factory :relationship,:subject=>data_file,:other_object=>Factory(:publication),:predicate=>Relationship::RELATED_TO_PUBLICATION
        data_file.creators = [Factory(:person),Factory(:person)]
        #tag
        Factory :annotation,:attribute_name=>"tag",:annotatable=> data_file,:attribute_id => AnnotationAttribute.create(:name=>"tag").id
        data_file.events = [Factory(:event)]
        data_file.scales = [Factory(:scale)]
        data_file.save!

        data_file.reload

        #I want to compare data_file.creators & assays to data_file_converted.creators & assays later. If I don't load data_file.creators & assays now,
        #then it will try to load them when I do the comparison. Since that will be [] after I've updated the database from converting.
        #to avoid this, I will preload creators & assays (which are through_associations) now.
        through_associations_to_test_later = [:creators, :assays]
        through_associations_to_test_later.each {|a| data_file.send(a).send(:load_target)}

        #tags ans scales stored in annotations
        data_file_tag_text_array = data_file.annotations.with_attribute_name("tag").include_values.collect{|a| a.value.text}
        data_file_scales =  data_file.scales.sort.map(&:text)
        presentation = Factory.build :presentation,:contributor=>user

        data_file_converted = data_file.to_presentation
        data_file_converted = data_file_converted.reload


        assert_equal presentation.class.name, data_file_converted.class.name
        assert_equal presentation.attributes.keys.sort!, data_file_converted.attributes.keys.sort!

        #data_file.reload
        #data file still has some associations that are assigned to data_file_converted, as it is NOT reloaded
        assert_equal data_file.version, data_file_converted.version
        assert_equal data_file.policy.sharing_scope, data_file_converted.policy.sharing_scope
        assert_equal data_file.policy.access_type, data_file_converted.policy.access_type
        assert_equal data_file.policy.use_whitelist, data_file_converted.policy.use_whitelist
        assert_equal data_file.policy.use_blacklist, data_file_converted.policy.use_blacklist
        assert_equal data_file.policy.permissions, data_file_converted.policy.permissions
        assert data_file.policy.id != data_file_converted.policy.id
        assert_equal data_file.content_blob, data_file_converted.content_blob

        assert_equal data_file.subscriptions.map(&:person_id).sort, data_file_converted.subscriptions(&:person_id).sort
        assert_equal data_file.projects,data_file_converted.projects
        assert_equal data_file.attributions , data_file_converted.attributions
        assert_equal data_file.related_publications, data_file_converted.related_publications
        assert_equal data_file.creators.sort, data_file_converted.creators.sort
        assert_equal data_file_tag_text_array, data_file_converted.annotations.with_attribute_name("tag").include_values.collect{|a| a.value.text}
        assert_equal data_file.project_ids.sort,data_file_converted.project_ids.sort
        assert_equal data_file.assays.sort,data_file_converted.assays.sort
        assert_equal data_file.event_ids.sort, data_file_converted.event_ids.sort
        assert_equal data_file_scales, data_file_converted.scales.sort.map(&:text)

      }
    end
  test "convert to presentation when linked to project folder" do
    user = Factory :user
    project = user.person.projects.first
    User.with_current_user(user) do
      project_folder = Factory :project_folder,:project=>project
      data_file = Factory :data_file,:contributor=>user, :projects=>[project]
      pfa=ProjectFolderAsset.create :asset=>data_file,:project_folder=>project_folder

      data_file.reload
      assert_equal [project_folder],data_file.folders
      presentation = Factory.build :presentation,:contributor=>user
      data_file_converted = data_file.to_presentation

      data_file_converted.save!
      assert_equal [project_folder],data_file_converted.folders
    end
  end

  test 'should convert tag from datafile to presentation' do
      user = Factory :user
      User.with_current_user(user) {
        data_file = Factory :data_file,:contributor=>user
        Factory :tag,:annotatable=>data_file,:source=>user,:value=>"fish"

        assert_equal 1, data_file.annotations.count
        assert_equal 0, data_file.annotations.first.versions.count
        assert 'fish', data_file.annotations.first.value.text

        data_file_converted = data_file.to_presentation
        data_file_converted.reload
        data_file.reload

        assert_equal [], data_file.annotations
        assert_equal [], Annotation::Version.find(:all, :conditions => ['annotatable_type=? and annotatable_id=?', 'DataFile', data_file.id])
        assert_equal 1, data_file_converted.annotations.count
        assert_equal 0, data_file_converted.annotations.first.versions.count
        assert 'fish', data_file_converted.annotations.first.value.text
      }
  end

  test 'should not convert other annotation types but tag from datafile to presentation' do
      user = Factory :user
      User.with_current_user(user) {
        data_file = Factory :data_file,:contributor=>user
       tag =  Factory :tag,:annotatable=>data_file,:source=>user,:value=>"fish"
       annotation =  Factory :annotation, :annotatable => data_file, :source=>user,:value=>"cat"

        assert_equal 2, data_file.annotations.count
        assert_equal 0, data_file.annotations.first.versions.count
        assert_equal 0, data_file.annotations.last.versions.count
        assert data_file.annotations.collect(&:value).collect(&:text).include?('fish')
        assert data_file.annotations.collect(&:value).collect(&:text).include?('cat')

        data_file_converted = data_file.to_presentation
        data_file_converted.reload
        data_file.reload

        assert_equal [annotation], data_file.annotations
        assert_equal [tag], data_file_converted.annotations
        assert_equal [], Annotation::Version.find(:all, :conditions => ['annotatable_type=? and annotatable_id=?', 'DataFile', data_file.id])
        assert_equal 1, data_file_converted.annotations.count
        assert_equal 0, data_file_converted.annotations.first.versions.count
        assert 'fish', data_file_converted.annotations.first.value.text
      }
  end

  test "fs_search_fields" do
    user = Factory :user
    User.with_current_user user do
      df = Factory :data_file,:contributor=>user
      sf1 = Factory :studied_factor_link,:substance=>Factory(:compound,:name=>"sugar")
      sf2 = Factory :studied_factor_link,:substance=>Factory(:compound,:name=>"iron")
      comp=sf2.substance
      Factory :synonym,:name=>"metal",:substance=>comp
      Factory :mapping_link,:substance=>comp,:mapping=>Factory(:mapping,:chebi_id=>"12345",:kegg_id=>"789",:sabiork_id=>111)
      studied_factor = Factory :studied_factor,:studied_factor_links=>[sf1,sf2],:data_file=>df
      assert df.fs_search_fields.include?("sugar")
      assert df.fs_search_fields.include?("metal")
      assert df.fs_search_fields.include?("iron")
      assert df.fs_search_fields.include?("concentration")
      assert df.fs_search_fields.include?("CHEBI:12345")
      assert df.fs_search_fields.include?("12345")
      assert df.fs_search_fields.include?("111")
      assert df.fs_search_fields.include?("789")
      assert_equal 8,df.fs_search_fields.count
    end
  end

  test "fs_search_fields_with_synonym_substance" do
    user = Factory :user
    User.with_current_user user do
      df = Factory :data_file,:contributor=>user
      suger = Factory(:compound,:name=>"sugar")
      iron = Factory(:compound,:name=>"iron")
      metal = Factory :synonym,:name=>"metal",:substance=>iron
      Factory :mapping_link,:substance=>iron,:mapping=>Factory(:mapping,:chebi_id=>"12345",:kegg_id=>"789",:sabiork_id=>111)

      sf1 = Factory :studied_factor_link,:substance=>suger
      sf2 = Factory :studied_factor_link, :substance=>metal

      Factory :studied_factor,:studied_factor_links=>[sf1,sf2],:data_file=>df
      assert df.fs_search_fields.include?("sugar")
      assert df.fs_search_fields.include?("metal")
      assert df.fs_search_fields.include?("iron")
      assert df.fs_search_fields.include?("concentration")
      assert df.fs_search_fields.include?("CHEBI:12345")
      assert df.fs_search_fields.include?("12345")
      assert df.fs_search_fields.include?("111")
      assert df.fs_search_fields.include?("789")
      assert_equal 8,df.fs_search_fields.count
    end
  end

  test "get treatments" do
      user = Factory :user
      User.with_current_user user do
        data=File.new("#{Rails.root}/test/fixtures/files/treatments-normal-case.xls","rb").read
        df = Factory :data_file,:contributor=>user,:content_blob=>Factory(:content_blob,:data=>data,:content_type=>"application/excel")
        assert_not_nil df.spreadsheet_xml
        assert_not_nil df.treatments
        assert_equal 2,df.treatments.values.keys.count
        assert_equal ["Dilution_rate","pH"],df.treatments.values.keys.sort

        data=File.new("#{Rails.root}/test/fixtures/files/file_picture.png","rb").read
        df = Factory :data_file,:contributor=>user,:content_blob=>Factory(:content_blob,:data=>data)
        assert_not_nil df.treatments
        assert_equal 0,df.treatments.values.keys.count
      end
  end

  test "cache_remote_content" do
    user = Factory :user
    User.with_current_user(user) do
      mock_remote_file "#{Rails.root}/test/fixtures/files/file_picture.png", "http://mockedlocation.com/picture.png"

      data_file = Factory :data_file, :content_blob => ContentBlob.new(:url => "http://mockedlocation.com/picture.png", :original_filename => "picture.png")

      data_file.save!

      assert !data_file.content_blob.file_exists?

      data_file.cache_remote_content_blob

      assert data_file.content_blob.file_exists?
    end
  end



=begin
  test "populate samples database with parser" do
    user = Factory :user
    User.with_current_user user do
      #clean sample database
      disable_authorization_checks do
        Unit.destroy_all
        Treatment.destroy_all
        Sample.destroy_all
        Specimen.destroy_all
        DataFile.destroy_all
        DataFile::Version.destroy_all
        AssayAsset.destroy_all
        Assay.destroy_all
        Study.destroy_all
        Investigation.destroy_all
      end

       #create creator in the database
      creator = Factory :person, :first_name => "Tester", :last_name => "SEEK", :email => "SEEK.tester@test.com"
      Factory :user, :person_id => creator.id

      filepath =  "#{Rails.root}/test/fixtures/files/parser/jenage-excel_template.xlsm"
      filename =  "jenage-excel_template"
      content_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

      data_file, assay, bio_samples = data_file_with_sample_parser filepath,filename,content_type
      assert data_file.is_excel?
      assert data_file.is_extractable_spreadsheet?
      assert_not_nil bio_samples
      assert_not_nil assay
      assert_equal true, data_file.assays.include?(assay)
      assay.samples.each{|s|assert_equal true, Sample.all.include?(s)}
      assert_equal false, bio_samples.instance_values["specimen_names"].blank?
      assert_equal false, bio_samples.instance_values["treatments"].blank?
      assert_equal false, bio_samples.instance_values["rna_extractions"].blank?
      assert_equal true, bio_samples.instance_values["sequencing"].blank?

      #test data file with empty cells which return nil in the parsed xml
      filepath =  "#{Rails.root}/test/fixtures/files/parser/error.xlsx"
      filename =  "error"
      content_type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"

      data_file, assay, bio_samples = data_file_with_sample_parser filepath,filename,content_type
      assert data_file.is_excel?
      assert data_file.is_extractable_spreadsheet?
      assert_not_nil bio_samples
      assert_not_nil assay
      assert_equal true, data_file.assays.include?(assay)
      assay.samples.each{|s|assert_equal true, Sample.all.include?(s)}
      assert_equal false, bio_samples.instance_values["specimen_names"].blank?
      assert_equal false, bio_samples.instance_values["treatments"].blank?
      assert_equal false, bio_samples.instance_values["rna_extractions"].blank?
      assert_equal true, bio_samples.instance_values["sequencing"].blank?

    end
  end
=end

  private

  def data_file_with_sample_parser filepath,filename,content_type
      user = User.current_user
      data=File.new("#{filepath}","rb").read
      df = Factory :data_file,:contributor=>user,:content_blob=>Factory(:content_blob,:data=>data,:content_type=>content_type,:original_filename=>filename)
      xml = df.spreadsheet_xml
      doc = LibXML::XML::Parser.string(xml).parse
      doc.root.namespaces.default_prefix = "ss"
      template_sheet = doc.find_first("//ss:sheet[@name='IDF']")

      bio_samples =  df.bio_samples_population

      assay_type_title = bio_samples.send :hunt_for_horizontal_field_value ,template_sheet, "Experiment Class"
      study_title = bio_samples.send :hunt_for_horizontal_field_value ,template_sheet, "Experiment Description"

      study = Study.find_by_title_and_contributor_id study_title, user.id
      assay_title = filename
      assay_class = AssayClass.find_by_title("Experimental Assay")
      assay_type = AssayType.find_by_title(assay_type_title)
      assay = Assay.all.detect{|a|a.title == assay_title and a.study_id == study.id and a.assay_class_id == assay_class.try(:id) and a.assay_type == assay_type and a.owner_id == user.person.id}


      return df, assay, bio_samples
  end

end
