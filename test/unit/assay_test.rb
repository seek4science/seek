require 'test_helper'
require 'tmpdir'

class AssayTest < ActiveSupport::TestCase
  fixtures :all


  test "shouldnt edit the assay" do
    non_admin = Factory :user
    assert !non_admin.person.is_admin?
    assay = assays(:modelling_assay_with_data_and_relationship)
    assert_equal false, assay.can_edit?(non_admin)
  end

  test "sops association" do
    assay=assays(:metabolomics_assay)
    assert_equal 2,assay.sops.size
    assert assay.sops.include?(sops(:my_first_sop).versions.first)
    assert assay.sops.include?(sops(:sop_with_fully_public_policy).versions.first)
  end

  test "to_rdf" do
    assay = Factory :experimental_assay
    Factory :assay_organism, :assay=>assay, :organism=>Factory(:organism)
    pub = Factory :publication
    Factory :relationship, :subject=>assay, :predicate=>Relationship::RELATED_TO_PUBLICATION,:other_object=>pub
    Factory :assay_asset, :assay=>assay
    assay.reload
    assert_equal 1,assay.assets.size
    rdf = assay.to_rdf
    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      assert reader.statements.count > 1
      assert_equal RDF::URI.new("http://localhost:3000/assays/#{assay.id}"), reader.statements.first.subject
    end

    #try modelling, with tech type nil
    assay = Factory :modelling_assay, :organisms => [Factory(:organism)], :technology_type_uri => nil
    rdf = assay.to_rdf

    # assay with suggested assay/technology types
    suggested_assay_type = Factory(:suggested_assay_type)
    suggested_tech_type = Factory(:suggested_technology_type)
    assay = Factory :experimental_assay, :suggested_assay_type => suggested_assay_type, :suggested_technology_type => suggested_tech_type
    rdf = assay.to_rdf

    RDF::Reader.for(:rdfxml).new(rdf) do |reader|
      reader.statements.map(&:object).include? suggested_assay_type.ontology_uri
      reader.statements.map(&:object).include? suggested_tech_type.ontology_uri
    end
  end

  test "is_asset?" do
    assert !Assay.is_asset?
    assert !assays(:metabolomics_assay).is_asset?
  end

  test "sort by updated_at" do
    assert_equal Assay.find(:all).sort_by { |a| a.updated_at.to_i * -1 }, Assay.find(:all)
  end

  test "authorization supported?" do
    assert Assay.authorization_supported?
    assert assays(:metabolomics_assay).authorization_supported?
  end

  test "avatar_key" do
    assert_equal "assay_experimental_avatar",assays(:metabolomics_assay).avatar_key
    assert_equal "assay_modelling_avatar",assays(:modelling_assay_with_data_and_relationship).avatar_key
  end

  test "is_modelling" do
    assay=assays(:metabolomics_assay)
    User.current_user = assay.contributor.user
    assert !assay.is_modelling?
    assay.assay_class=assay_classes(:modelling_assay_class)
    assay.samples = []
    assay.save!
    assert assay.is_modelling?
  end
  
  test "title_trimmed" do
    User.with_current_user Factory(:user) do
      assay=Factory :assay,
                    :contributor => User.current_user.person,
                    :title => " test"
      assay.save!
      assert_equal "test",assay.title
    end
  end

  test "is_experimental" do
    assay=assays(:metabolomics_assay)
    User.current_user = assay.contributor.user
    assert assay.is_experimental?
    assay.assay_class=assay_classes(:modelling_assay_class)
    assay.samples = []
    assay.save!
    assert !assay.is_experimental?
  end

  test "related investigation" do
    assay=assays(:metabolomics_assay)
    assert_not_nil assay.investigation
    assert_equal investigations(:metabolomics_investigation),assay.investigation
  end

  test "related project" do
    assay=assays(:metabolomics_assay)
    assert !assay.projects.empty?
    assert assay.projects.include?(projects(:sysmo_project))
  end


  test "validation" do
    User.with_current_user Factory(:user) do
      assay=new_valid_assay

      assert assay.valid?


      assay.title=""
      assert !assay.valid?

      assay.title=nil
      assert !assay.valid?

      assay.title=assays(:metabolomics_assay).title
      assert assay.valid? #can have duplicate titles

      assay.title="test"
      assay.assay_type_uri=nil
      assert assay.valid?
      refute_nil assay.assay_type_uri, "uri should have been set to default in before_validation"

      assay.assay_type_uri="http://www.mygrid.org.uk/ontology/JERMOntology#Metabolomics"

      assert assay.valid?

      assay.study=nil
      assert !assay.valid?
      assay.study=studies(:metabolomics_study)

      assay.technology_type_uri=nil
      assert assay.valid?
      refute_nil assay.technology_type_uri, "uri should have been set to default in before_validation"

      assay.owner=nil
      assert !assay.valid?

      assay.owner=people(:person_for_model_owner)

      #an modelling assay can be valid without a technology type, sample or organism
      assay.assay_class=assay_classes(:modelling_assay_class)
      assay.technology_type_uri=nil
      assay.samples = []
      assert assay.valid?
    #an experimental assay can be invalid without a sample nor a organism
    assay.assay_class=assay_classes(:experimental_assay_class)
    assay.technology_type_uri=nil
    assay.organisms = []
    assay.samples = []


    as_not_virtualliver do
       assert assay.valid?
    end

    assay.assay_organisms = [Factory(:assay_organism)]
    assert assay.valid?
    assay.assay_organisms = []
    assay.samples = [Factory(:sample)]
    assert assay.valid?

     assay.assay_organisms = [Factory(:assay_organism)]
     assay.samples = [Factory(:sample)]
     assert assay.valid?

    end
  end

  test "associated publication" do
    assert_equal 1, assays(:assay_with_a_publication).related_publications.size
  end

  test "can delete?" do
    user = User.current_user = Factory(:user)
    assert Factory(:assay, :contributor => user.person).can_delete?

    assay = Factory(:assay, :contributor => user.person)
    assay.relate Factory(:data_file, :contributor => user)
    assert !assay.can_delete?

    assay = Factory(:assay, :contributor => user.person)
    assay.relate Factory(:sop, :contributor => user)
    assert !assay.can_delete?

    assay = Factory(:assay, :contributor => user.person)
    assay.relate Factory(:model, :contributor => user)
    assert !assay.can_delete?

    pal = Factory :pal
    #create an assay with projects = to the projects for which the pal is a pal
    assay = Factory(:assay,
                    :study => Factory(:study,
                                      :investigation => Factory(:investigation,
                                                                :projects => pal.projects)))
    assert !assay.can_delete?(pal.user)
    
    assert !assays(:assay_with_a_publication).can_delete?(users(:model_owner))
  end

  test "assets" do
    assay=assays(:metabolomics_assay)
    assert_equal 3,assay.assets.size,"should be 2 sops and 1 data file"
  end

  test "sops" do
    assay=assays(:metabolomics_assay)
    assert_equal 2,assay.sops.size
    assert assay.sops.include?(sops(:my_first_sop).find_version(1))
    assert assay.sops.include?(sops(:sop_with_fully_public_policy).find_version(1))
  end

  test "data_files" do
    assay=assays(:metabolomics_assay)
    assert_equal 1,assay.data_files.size
    assert assay.data_files.include?(data_files(:picture).find_version(1))
  end
  
  test "can relate data files" do
    assay = assays(:metabolomics_assay)
    User.with_current_user assay.contributor.user do
      assert_difference("Assay.find_by_id(assay.id).data_files.count") do
        assay.relate(data_files(:viewable_data_file), relationship_types(:test_data))
      end
    end
  end
  
  test "relate new version of sop" do
    User.with_current_user Factory(:user) do
      assay=Factory :assay, :contributor => User.current_user.person
      assay.save!
      sop=sops(:sop_with_all_sysmo_users_policy)
      assert_difference("Assay.find_by_id(assay.id).sops.count", 1) do
        assert_difference("AssayAsset.count", 1) do
          assay.relate(sop)
        end
      end
      assay.reload
      assert_equal 1, assay.assay_assets.size
      assert_equal sop.version, assay.assay_assets.first.versioned_asset.version

      User.current_user = sop.contributor
      sop.save_as_new_version

      assert_no_difference("Assay.find_by_id(assay.id).sops.count") do
        assert_no_difference("AssayAsset.count") do
          assay.relate(sop)
        end
      end

      assay.reload
      assert_equal 1, assay.assay_assets.size
      assert_equal sop.version, assay.assay_assets.first.versioned_asset.version
    end
  end

  test "organisms association" do
    assay=assays(:metabolomics_assay)
    assert_equal 2,assay.assay_organisms.count
    assert_equal 2,assay.organisms.count
    assert assay.organisms.include?(organisms(:yeast))
    assert assay.organisms.include?(organisms(:Saccharomyces_cerevisiae))
  end

  test "associate organism" do
    assay=assays(:metabolomics_assay)
    User.current_user = assay.contributor
    organism=organisms(:yeast)
    #test with numeric ID
    assert_difference("AssayOrganism.count") do
      assay.associate_organism(organism.id)
    end

    #with String ID
    assert_no_difference("AssayOrganism.count") do
      assay.associate_organism(organism.id.to_s)
    end

    #with Organism object
    assert_no_difference("AssayOrganism.count") do
      assay.associate_organism(organism)
    end

    #with a culture growth
    assay.assay_organisms.clear
    assay.save!
    cg=culture_growth_types(:batch)
    assert_difference("AssayOrganism.count") do
      assay.associate_organism(organism,nil,cg)
    end
    assay.reload
    assert_equal cg,assay.assay_organisms.first.culture_growth_type

  end

  test "disassociating organisms removes AssayOrganism" do
    assay=assays(:metabolomics_assay)
    User.current_user = assay.contributor
    assert_equal 2,assay.assay_organisms.count
    assert_difference("AssayOrganism.count",-2) do
      assay.assay_organisms.clear
      assay.save!
    end
    
  end

  test "associate organism with strain" do
    assay=Factory(:assay)
    organism=Factory(:organism)
    strain=Factory(:strain, :organism=>organism)

    assert_equal organism,strain.organism
    assert_equal strain,organism.strains.find(strain.id)

    assert_equal 0,assay.assay_organisms.count,"This test relies on this assay having no organisms"

    assert_difference("AssayOrganism.count") do
      assert_no_difference("Strain.count") do
        disable_authorization_checks{assay.associate_organism(organism,strain.id)}
      end
    end

    assay.reload
    assert_include assay.strains,strain
    assert_include assay.organisms,organism

    assert_no_difference("AssayOrganism.count") do
      assert_no_difference("Strain.count") do
        disable_authorization_checks{assay.associate_organism(organism,strain.id)}
      end
    end

    organism = Factory(:organism)
    strain = Factory(:strain, :organism=>organism)
    culture_growth = Factory(:culture_growth_type)

    assert_difference("AssayOrganism.count") do
      assert_no_difference("Strain.count") do
        disable_authorization_checks{assay.associate_organism(organism,strain.id,culture_growth)}
      end
    end

    assay.reload
    assert_include assay.strains,strain
    assert_include assay.organisms,organism
    ao = assay.assay_organisms.find{|ao| ao.strain==strain}
    assert_equal culture_growth,ao.culture_growth_type

  end

  test "test uuid generated" do
    a = assays(:metabolomics_assay)
    assert_nil a.attributes["uuid"]
    a.save
    assert_not_nil a.attributes["uuid"]
  end 

  test "uuid doesn't change" do
    x = assays(:metabolomics_assay)
    x.save
    uuid = x.attributes["uuid"]
    x.save
    assert_equal x.uuid, uuid
  end
  
  def new_valid_assay
    Assay.new(:title=>"test",
      :assay_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Metabolomics",
      :technology_type_uri=>"http://www.mygrid.org.uk/ontology/JERMOntology#Gas_chromatography",
      :study => studies(:metabolomics_study),
      :owner => people(:person_for_model_owner),
      :assay_class => assay_classes(:experimental_assay_class),
      :samples => [Factory(:sample)],
      :policy => Factory(:private_policy)
    )
  end

  test "related models" do
    model_assay = Factory :modelling_assay,:model_master_ids => [Factory(:model).id]
    exp_assay = Factory :experimental_assay,:model_master_ids => [Factory(:model).id]
    assert_equal model_assay.model_masters, model_assay.related_models
    assert_not_equal exp_assay.model_masters,exp_assay.related_models
    assert_equal [], exp_assay.related_models
  end

  test "contributing_user" do
      assay = Factory :assay
      assert assay.contributor
      assert_equal assay.contributor.user, assay.contributing_user
  end

  test "assay type label from ontology or suggested assay type" do

    assay = Factory(:experimental_assay,assay_type_uri:"http://www.mygrid.org.uk/ontology/JERMOntology#Catabolic_response")
    assert_equal "Catabolic response",assay.assay_type_label

    assay = Factory(:modelling_assay,assay_type_uri:"http://www.mygrid.org.uk/ontology/JERMOntology#Genome_scale")
    assert_equal "Genome scale",assay.assay_type_label


    suggested_at = Factory(:suggested_assay_type, :label => "new fluxomics")
    assay = Factory(:experimental_assay, :suggested_assay_type => suggested_at)
    assert_equal "new fluxomics", assay.assay_type_label

    suggested_ma = Factory(:suggested_modelling_analysis_type, :label => "new metabolism")
    assay = Factory(:experimental_assay, :suggested_assay_type => suggested_ma)
    assert_equal "new metabolism", assay.assay_type_label

  end

  test "technology type label from ontology or suggested technology type" do
    assay = Factory(:experimental_assay,technology_type_uri:"http://www.mygrid.org.uk/ontology/JERMOntology#Binding")
    assert_equal "Binding",assay.technology_type_label

    suggested_tt = Factory(:suggested_technology_type, :label => "new technology type")
    assay = Factory(:experimental_assay, :suggested_technology_type => suggested_tt)
    assert_equal "new technology type", assay.technology_type_label
  end

  test "default assay and tech type" do
    assay = Factory(:experimental_assay)
    assay.assay_type_uri=nil
    assay.technology_type_uri=nil
    assay.save!
    assert_equal Seek::Ontologies::AssayTypeReader.instance.default_parent_class_uri.to_s,assay.assay_type_uri
    assert_equal Seek::Ontologies::TechnologyTypeReader.instance.default_parent_class_uri.to_s,assay.technology_type_uri

    assay = Factory(:modelling_assay)
    assay.assay_type_uri=nil
    assay.technology_type_uri=nil
    assay.save!
    assert_equal Seek::Ontologies::ModellingAnalysisTypeReader.instance.default_parent_class_uri.to_s,assay.assay_type_uri
    assert_nil assay.technology_type_uri
  end

  test "assay type reader" do
    exp_assay = Factory(:experimental_assay)
    mod_assay = Factory(:modelling_assay)
    assert_equal Seek::Ontologies::AssayTypeReader,exp_assay.assay_type_reader.class
    assert_equal Seek::Ontologies::ModellingAnalysisTypeReader,mod_assay.assay_type_reader.class
  end

  test "valid assay type uri" do
    assay = Factory(:experimental_assay)
    assert assay.valid_assay_type_uri?
    assay.assay_type_uri="http://fish.com/onto#fish"
    assert !assay.valid_assay_type_uri?

    #modelling uri should also be invalid
    assay.assay_type_uri = Seek::Ontologies::ModellingAnalysisTypeReader.instance.default_parent_class_uri.to_s
    assert !assay.valid_assay_type_uri?
  end

  test "valid technology type uri" do
    mod_assay = Factory(:modelling_assay)
    exp_assay = Factory(:experimental_assay)
    assert mod_assay.valid_technology_type_uri?
    mod_assay.technology_type_uri = Seek::Ontologies::TechnologyTypeReader.instance.default_parent_class_uri.to_s
    #for a modelling assay, even if it is set it is invalid
    assert !mod_assay.valid_technology_type_uri?

    assert exp_assay.valid_technology_type_uri?
    exp_assay.technology_type_uri = "http://fish.com/onto#fish"
    assert !exp_assay.valid_technology_type_uri?
  end

  test "destroy" do
    a = Factory(:assay,:study=>Factory(:study))
    refute_nil a.study
    refute_empty a.projects
    assert_difference("Assay.count",-1) do
      assert_no_difference("Study.count") do
        disable_authorization_checks do
          a.destroy
        end
      end
    end

  end

  test "converts assay and tech suggested type uri" do
    assay_type = Factory(:suggested_assay_type,:label=>"fishy",:ontology_uri=>"fish:2")
    tech_type = Factory(:suggested_technology_type,:label=>"carroty",:ontology_uri=>"carrot:3")
    assay = Factory(:experimental_assay)
    assay.assay_type_uri = assay_type.uri
    assay.technology_type_uri = tech_type.uri
    assert_equal assay_type, assay.suggested_assay_type
    assert_equal "fishy", assay.assay_type_label
    assert_equal "fish:2",assay.assay_type_uri

    assert_equal tech_type, assay.suggested_technology_type
    assert_equal "carroty", assay.technology_type_label
    assert_equal "carrot:3",assay.technology_type_uri
  end

end
