require 'test_helper'

class StudyTest < ActiveSupport::TestCase
  
  fixtures :all

  test "associations" do
    study=studies(:metabolomics_study)
    assert_equal "A Metabolomics Study",study.title

    assert_not_nil study.assays
    assert_equal 1,study.assays.size
    assert !study.investigation.projects.empty?

    assert study.assays.include?(assays(:metabolomics_assay))
    
    assert_equal projects(:sysmo_project),study.investigation.projects.first
    assert_equal projects(:sysmo_project),study.projects.first
    
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Metabolomics",study.assays.first.assay_type_uri

  end

  test "to_rdf" do
    object = Factory :study, :description=>"My famous study", :assays=>[Factory(:assay),Factory(:assay)]
    rdf = object.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/studies/#{object.id}"), reader.statements.first.subject
    end
  end

  test "sort by updated_at" do
    assert_equal Study.all.sort_by { |s| s.updated_at.to_i * -1 }, Study.all
  end

  #only authorized people can delete a study, and a study must have no assays
  test "can delete" do
    project_member = Factory :person
    study = Factory :study, :contributor => Factory(:person), :investigation => Factory(:investigation, :projects => project_member.projects)
    assert !study.can_delete?(Factory(:user))
    assert !study.can_delete?(project_member.user)
    assert study.can_delete?(study.contributor.user)

    study=Factory :study, :contributor => Factory(:person), :assays => [Factory(:assay)]
    assert !study.can_delete?(study.contributor)
  end

  test "publications through assays" do
    assay1 = Factory :assay
    assay2 = Factory :assay

    pub1 = Factory :publication, :title=>"pub 1"
    pub2 = Factory :publication, :title=>"pub 2"
    pub3 = Factory :publication, :title=>"pub 3"
    Factory :relationship, :subject=>assay1, :predicate=>Relationship::RELATED_TO_PUBLICATION,:other_object=>pub1
    Factory :relationship, :subject=>assay1, :predicate=>Relationship::RELATED_TO_PUBLICATION,:other_object=>pub2

    Factory :relationship, :subject=>assay2, :predicate=>Relationship::RELATED_TO_PUBLICATION,:other_object=>pub2
    Factory :relationship, :subject=>assay2, :predicate=>Relationship::RELATED_TO_PUBLICATION,:other_object=>pub3

    study = Factory(:study,:assays=>[assay1,assay2])

    assay1.reload
    assay2.reload
    assert_equal 2,assay1.publications.size
    assert_equal 2,assay2.publications.size


    assert_equal 2,study.assays.size
    assert_equal 3,study.related_publications.size
    assert_equal [pub1,pub2,pub3],study.related_publications.sort_by(&:id)
  end

  test "sops through assays" do
    study=studies(:metabolomics_study)
    assert_equal 2,study.related_sops.size
    assert study.related_sops.include?(sops(:my_first_sop))
    assert study.related_sops.include?(sops(:sop_with_fully_public_policy))
    
    #study with 2 assays that have overlapping sops. Checks that the sops aren't dupliced.
    study=studies(:study_with_overlapping_assay_sops)
    assert_equal 3,study.related_sops.size
    assert study.related_sops.include?(sops(:my_first_sop))
    assert study.related_sops.include?(sops(:sop_with_fully_public_policy))
    assert study.related_sops.include?(sops(:sop_for_test_with_workgroups))
  end

  test "person responisble" do
    study=studies(:metabolomics_study)
    assert_equal people(:person_without_group),study.person_responsible
  end

  test "project from investigation" do
    study=studies(:metabolomics_study)
    assert_equal projects(:sysmo_project), study.projects.first
    assert_not_nil study.projects.first.title
  end

  test "title trimmed" do
    s=Factory(:study, :title=>" title")
    assert_equal("title",s.title)
  end
  

  test "validation" do
    s=Study.new(:title=>"title",:investigation=>investigations(:metabolomics_investigation), :policy => Factory(:private_policy))
    assert s.valid?

    s.title=nil
    assert !s.valid?
    s.title
    assert !s.valid?

    s=Study.new(:title=>"title",:investigation=>investigations(:metabolomics_investigation))
    s.investigation=nil
    assert !s.valid?

  end

  test "study with 1 assay" do
    study=studies(:study_with_assay_with_public_private_sops_and_datafile)
    assert_equal 1,study.assays.size,"This study must have only one assay - do not modify its fixture"
  end
  
  test "test uuid generated" do
    s = studies(:metabolomics_study)
    assert_nil s.attributes["uuid"]
    s.save
    assert_not_nil s.attributes["uuid"]
  end 
  
  test "uuid doesn't change" do
    x = studies(:metabolomics_study)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end

  test 'assets' do
    assay_assets = [Factory(:assay_asset),Factory(:assay_asset)]
    data_files = assay_assets.collect{|aa| aa.asset}
    study = Factory(:experimental_assay,:assay_assets=>assay_assets).study
    assert_equal data_files.sort,study.assets.sort
  end

end
