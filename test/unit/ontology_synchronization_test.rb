require 'test_helper'

class OntologySynchronizationTest < ActiveSupport::TestCase

  def teardown
    Rails.cache.clear
    Seek::Ontologies::TechnologyTypeReader.instance.reset
    Seek::Ontologies::AssayTypeReader.instance.reset
  end

  test "suggested assay types found" do
    top = Factory :suggested_assay_type, :label=>"top_at", :ontology_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics"
    child1 = Factory :suggested_assay_type,:label=>"child1_at", :parent => top, :ontology_uri=>nil
    child2 = Factory :suggested_assay_type,:label=>"child2_at", :parent => child1, :ontology_uri=>nil

    assay = Factory(:experimental_assay,:suggested_assay_type=>child1,:assay_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics")
    assay.save!
    assay.reload

    refute_includes top.children,child2

    assert_equal child1,assay.suggested_assay_type
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Fluxomics",assay.assay_type_uri
    with_config_value :assay_type_ontology_file,"file:#{Rails.root}/test/fixtures/files/JERM-sync-test.rdf" do
      Rails.cache.clear
      Seek::Ontologies::AssayTypeReader.instance.reset
      assert_difference("SuggestedAssayType.count",-1) do
        Seek::Ontologies::Synchronize.new.synchronize_assay_types
      end


      assay.reload
      top.reload
      child2.reload


      assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Amplification",assay.assay_type_uri
      assert_nil assay.suggested_assay_type
      assert_equal "child1_at",assay.assay_type_label

      assert_includes top.children,child2
    end
  end

  test "suggested technology types found" do
    top = Factory :suggested_technology_type, :label=>"top_at", :ontology_uri => "http://www.mygrid.org.uk/ontology/JERMOntology#FRAP"
    child1 = Factory :suggested_technology_type,:label=>"child1_tech", :parent => top, :ontology_uri=>nil
    child2 = Factory :suggested_technology_type,:label=>"child2_tech", :parent => child1, :ontology_uri=>nil

    assay = Factory(:experimental_assay,:suggested_technology_type=>child1,:technology_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#FRAP")
    assay.save!
    assay.reload

    refute_includes top.children,child2

    assert_equal child1,assay.suggested_technology_type
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#FRAP",assay.technology_type_uri
    with_config_value :technology_type_ontology_file,"file:#{Rails.root}/test/fixtures/files/JERM-sync-test.rdf" do
      Rails.cache.clear
      Seek::Ontologies::TechnologyTypeReader.instance.reset
      assert_difference("SuggestedTechnologyType.count",-1) do
        Seek::Ontologies::Synchronize.new.synchronize_technology_types
      end

      assay.reload
      top.reload
      child2.reload

      assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#FACS",assay.technology_type_uri
      assert_nil assay.suggested_technology_type
      assert_equal "child1_tech",assay.technology_type_label

      assert_includes top.children,child2
    end
  end

  test "reverts to default uri if removed" do
    assay = Factory(:experimental_assay,:assay_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Cell_size",:technology_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#HPLC")

    with_config_value :technology_type_ontology_file,"file:#{Rails.root}/test/fixtures/files/JERM-sync-test.rdf" do
      with_config_value :assay_type_ontology_file,"file:#{Rails.root}/test/fixtures/files/JERM-sync-test.rdf" do
        Rails.cache.clear
        Seek::Ontologies::TechnologyTypeReader.instance.reset
        Seek::Ontologies::AssayTypeReader.instance.reset
        Seek::Ontologies::Synchronize.new.synchronize_technology_types
        Seek::Ontologies::Synchronize.new.synchronize_assay_types
      end
    end

    assay.reload
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Experimental_assay_type",assay.assay_type_uri
    assert_equal "http://www.mygrid.org.uk/ontology/JERMOntology#Technology_type",assay.technology_type_uri
  end

end